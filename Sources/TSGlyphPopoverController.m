/*
 ==============================================================================
 TSGlyphPopoverController
 Created on 2014-08-24 by Yusuke Terada
 
 TSGlyphPopoverController is based on CEGlyphPopoverController.
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2014-05-01 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "TSGlyphPopoverController.h"


// variation Selectors
static const unichar  kTextSequenceChar = 0xFE0E;
static const unichar kEmojiSequenceChar = 0xFE0F;

// emoji modifiers
static const UTF32Char kType12EmojiModifierChar = 0x1F3FB; // Emoji Modifier Fitzpatrick type-1-2
static const UTF32Char kType3EmojiModifierChar = 0x1F3FC;  // Emoji Modifier Fitzpatrick type-3
static const UTF32Char kType4EmojiModifierChar = 0x1F3FD;  // Emoji Modifier Fitzpatrick type-4
static const UTF32Char kType5EmojiModifierChar = 0x1F3FE;  // Emoji Modifier Fitzpatrick type-5
static const UTF32Char kType6EmojiModifierChar = 0x1F3FF;  // Emoji Modifier Fitzpatrick type-6

//////////////////////////////////////////////////////////////////////////////
#pragma mark - subclass for private use
@interface TSGlyphPopoverUnicodesTextStorage : NSTextStorage
{
    NSMutableAttributedString *contents;
}
- (id)init;
- (id)initWithAttributedString:(NSAttributedString*)attrStr;
@end

@implementation TSGlyphPopoverUnicodesTextStorage
- (id)initWithAttributedString:(NSAttributedString*)attrStr
{
    if (self = [super init]) {
        contents = attrStr ? attrStr.mutableCopy : NSMutableAttributedString.alloc.init;
    }
    return self;
}

- (id)init
{
    return [self initWithAttributedString:nil];
}

- (NSString *)string
{
    return contents.string;
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location
                     effectiveRange:(NSRange*)range
{
    return [contents attributesAtIndex:location effectiveRange:range];
}


// customize line-break
- (NSUInteger)lineBreakBeforeIndex:(NSUInteger)index withinRange:(NSRange)aRange
{
    NSUInteger breakIndex = [super lineBreakBeforeIndex:index withinRange:aRange];
    if (breakIndex >= 2 && [self.string characterAtIndex:breakIndex] == '+'){
        return breakIndex-2;
    } else {
        return breakIndex;
    }
}
@end
#pragma mark -

//////////////////////////////////////////////////////////////////////////////

@interface TSGlyphPopoverController (){
    IBOutlet NSTextView *unicodesTextView;
}

@property (nonatomic, copy) NSString *glyph;
@property (nonatomic, copy) NSString *unicodeName;
@property (nonatomic, copy) NSString *unicode;

@end


#pragma mark -

@implementation TSGlyphPopoverController

#pragma mark Public Methods

- (instancetype)initWithCharacter:(NSString *)character
{
    BOOL singleLetter;
    NSUInteger numberOfComposedCharacters = character.numberOfComposedCharacters;
    switch (numberOfComposedCharacters) {
        case 0:
            return nil;
            break;
        case 1:
            singleLetter = YES;
            self = [super initWithNibName:@"GlyphPopoverSingle" bundle:nil];
            break;
        default:
            singleLetter = NO;
            self = [super initWithNibName:@"GlyphPopoverMulti" bundle:nil];
            break;
    }
    
    if (self) {
        if (singleLetter) {
            self.glyph = character;
        }
        
        NSUInteger length = character.length;
        
        // unicode hex
        NSString *unicode;
        NSMutableArray *unicodes = NSMutableArray.array;
        
        for (NSUInteger i = 0; i < length; i++) {
            unichar theChar = [character characterAtIndex:i];
            unichar nextChar = (length > i + 1) ? [character characterAtIndex:i + 1] : 0;
            
            if (CFStringIsSurrogateHighCharacter(theChar) && CFStringIsSurrogateLowCharacter(nextChar)) {
                UTF32Char pair = CFStringGetLongCharacterForSurrogatePair(theChar, nextChar);
                unicode = [NSString stringWithFormat:@"U+%04tX (U+%04X U+%04X)", pair, theChar, nextChar];
                i++;
            } else {
                unicode = [NSString stringWithFormat:@"U+%04X", theChar];
            }
            
            [unicodes addObject:unicode];
        }
        
        NSString *unicodeLabel = [unicodes componentsJoinedByString:@"  "];
        self.unicode = unicodeLabel;
        
        BOOL multiCodePoints = (unicodes.count > 1);
        
        NSString *variationSelectorAdditional;
        if (unicodes.count == 2) {
            unichar lastChar = [character characterAtIndex:(length - 1)];
            if (lastChar == kEmojiSequenceChar) {
                variationSelectorAdditional = @"Emoji Style";
                multiCodePoints = NO;
            } else if (lastChar == kTextSequenceChar) {
                variationSelectorAdditional = @"Text Style";
                multiCodePoints = NO;
            } else if ((lastChar >= 0x180B && lastChar <= 0x180D) ||
                       (lastChar >= 0xFE00 && lastChar <= 0xFE0D))
            {
                variationSelectorAdditional = @"Variant";
                multiCodePoints = NO;
            } else {
                unichar highSurrogate = [character characterAtIndex:(length - 2)];
                unichar lowSurrogate = [character characterAtIndex:(length - 1)];
                if (CFStringIsSurrogateHighCharacter(highSurrogate) &&
                   CFStringIsSurrogateLowCharacter(lowSurrogate))
                {
                    UTF32Char pair = CFStringGetLongCharacterForSurrogatePair(highSurrogate, lowSurrogate);
                    
                    switch (pair) {
                        case kType12EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone I-II";  // Light Skin Tone
                            multiCodePoints = NO;
                            break;
                        case kType3EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone III";  // Medium Light Skin Tone
                            multiCodePoints = NO;
                            break;
                        case kType4EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone IV";  // Medium Skin Tone
                            multiCodePoints = NO;
                            break;
                        case kType5EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone V";  // Medium Dark Skin Tone
                            multiCodePoints = NO;
                            break;
                        case kType6EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone VI";  // Dark Skin Tone
                            multiCodePoints = NO;
                            break;
                        default:
                            if (pair >= 0xE0100 && pair <= 0xE01EF) {
                                variationSelectorAdditional = @"Variant";
                                multiCodePoints = NO;
                            }
                            break;
                    }
                }
            }
        }

        
        if (multiCodePoints) {
            if (singleLetter) {
                self.unicodeName = [NSString stringWithFormat:NSLocalizedString(@"<a letter consisting of %d characters>", nil), unicodes.count];
            } else {
                // display the number of letters, words, lines
                NSInteger numberOfWords = [NSSpellChecker.sharedSpellChecker countWordsInString:character language:nil];
                if (numberOfWords == -1) {
                    numberOfWords = [NSSpellChecker.sharedSpellChecker countWordsInString:character language:@"English"];
                }
                NSUInteger numberOfLines = [character componentsSeparatedByString:@"\n"].count;
                
                self.unicodeName = [NSString stringWithFormat:NSLocalizedString(@"%d letters, %d words, %d lines", nil), numberOfComposedCharacters, numberOfWords, numberOfLines];

                // display Unicode points
                NSRect originalFrame = super.view.frame;
                CGFloat oldHeight = originalFrame.size.height;

                // replace text storage of UnicodesTextView (for customizing line-break)
                unicodesTextView.horizontallyResizable = YES;
                unicodesTextView.verticallyResizable = YES;
                NSAttributedString *aStr = [unicodesTextView.textStorage attributedSubstringFromRange:NSMakeRange(0, unicodesTextView.textStorage.length)];
                TSGlyphPopoverUnicodesTextStorage *newStorage = [TSGlyphPopoverUnicodesTextStorage.alloc initWithAttributedString:aStr];
                [unicodesTextView.layoutManager replaceTextStorage:newStorage];
                
                // extend popover height (if necessary)
                [unicodesTextView sizeToFit];
                NSRect rect = [unicodesTextView.layoutManager usedRectForTextContainer:unicodesTextView.textContainer];
                CGFloat newHeight = rect.size.height + 50;
                NSLog(@"%f", rect.size.width);
                
                newHeight = (newHeight < oldHeight) ? oldHeight : MIN(newHeight, 300); // maximal height of popover
                
                // resize
                super.view.frame = NSMakeRect(originalFrame.origin.x, originalFrame.origin.y, originalFrame.size.width, newHeight);
            }
        } else {
            // unicode character name
            NSMutableString *mutableUnicodeName = character.mutableCopy;
            CFStringTransform((__bridge CFMutableStringRef)mutableUnicodeName, NULL, CFSTR("Any-Name"), NO);
            
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{(.+?)\\}" options:0 error:nil];
            NSTextCheckingResult *firstMatch = [regex firstMatchInString:mutableUnicodeName options:0
                                                                   range:NSMakeRange(0, mutableUnicodeName.length)];
            self.unicodeName = [mutableUnicodeName substringWithRange:[firstMatch rangeAtIndex:1]];
            
            if (variationSelectorAdditional) {
                self.unicodeName = [NSString stringWithFormat:@"%@ (%@)", self.unicodeName, NSLocalizedString(variationSelectorAdditional, nil)];
            }
        }
    }
    return self;
}


// ------------------------------------------------------
/// display popover
- (void)showPopoverRelativeToRect:(NSRect)positioningRect ofView:(NSView *)parentView
// ------------------------------------------------------
{
    NSPopover *popover = NSPopover.alloc.init;
    popover.contentViewController = self;
    popover.behavior = NSPopoverBehaviorSemitransient;
    [popover showRelativeToRect:positioningRect ofView:parentView preferredEdge:NSMinYEdge];
    [parentView.window makeFirstResponder:parentView];
}

@end


