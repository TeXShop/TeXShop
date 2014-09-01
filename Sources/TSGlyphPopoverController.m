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
 
 © 2014 CotEditor Project
 
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


// variation Selector
static const unichar  kTextSequenceChar = 0xFE0E;
static const unichar kEmojiSequenceChar = 0xFE0F;


// subclass for private use
//////////////////////////////////////////////////////////////////////////////
@interface TSGlyphPopoverUnicodesTextStorage : NSTextStorage
{
    NSMutableAttributedString *contents;
}
- (id)init;
- (id)initWithAttributedString:(NSAttributedString *)attrStr;
@end

@implementation TSGlyphPopoverUnicodesTextStorage
- (id)initWithAttributedString:(NSAttributedString *)attrStr
{
    if (self = [super init]) {
        contents = attrStr ? [attrStr mutableCopy] :
        [[NSMutableAttributedString alloc] init];
    }
    return self;
}

- (id)init
{
    return [self initWithAttributedString:nil];
}

- (NSString *)string
{
    return [contents string];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location
                     effectiveRange:(NSRange *)range
{
    return [contents attributesAtIndex:location effectiveRange:range];
}


// customize line-break
- (NSUInteger)lineBreakBeforeIndex:(NSUInteger)index withinRange:(NSRange)aRange
{
    NSUInteger breakIndex = [super lineBreakBeforeIndex:index withinRange:aRange];
    if (breakIndex >= 2 && [[self string] characterAtIndex:breakIndex] == '+'){
        return breakIndex-2;
    }else{
        return breakIndex;
    }
}
@end
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
    NSUInteger numberOfComposedCharacters = [character numberOfComposedCharacters];
    switch(numberOfComposedCharacters){
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
        if(singleLetter)
            [self setGlyph:character];
        
        
        NSUInteger length = [character length];
        
        // unicode hex
        NSString *unicode;
        NSMutableArray *unicodes = [NSMutableArray array];
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
        [self setUnicode:unicodeLabel];
        
        BOOL multiCodePoints = ([unicodes count] > 1);
        
        // emoji variation check
        NSString *emojiStyle;
        if ([unicodes count] == 2) {
            switch ([character characterAtIndex:(length - 1)]) {
                case kEmojiSequenceChar:
                    emojiStyle = @"Emoji Style";
                    multiCodePoints = NO;
                    break;
                
                case kTextSequenceChar:
                    emojiStyle = @"Text Style";
                    multiCodePoints = NO;
                    break;
                    
                default:
                    break;
            }
        }
        
        if (multiCodePoints) {
            if(singleLetter){
                [self setUnicodeName:[NSString stringWithFormat:NSLocalizedString(@"<a letter consisting of %d characters>", @"<a letter consisting of %d characters>"), length]];
            }else{
                // display the number of letters, words, lines
                NSInteger numberOfWords = [[NSSpellChecker sharedSpellChecker] countWordsInString:character language:nil];
                if(numberOfWords == -1){
                    numberOfWords = [[NSSpellChecker sharedSpellChecker] countWordsInString:character language:@"English"];
                }
                NSUInteger numberOfLines = [[character componentsSeparatedByString:@"\n"] count];
                
                [self setUnicodeName:
                 [NSString stringWithFormat:NSLocalizedString(@"%d letters, %d words, %d lines", @"%d letters, %d words, %d lines"), numberOfComposedCharacters, numberOfWords, numberOfLines]];

                // display Unicode points
                NSRect originalFrame = [[super view] frame];
                CGFloat oldHeight = originalFrame.size.height;

                // replace text storage of UnicodesTextView (for customizing line-break)
                NSAttributedString *aStr = [unicodesTextView.textStorage attributedSubstringFromRange:NSMakeRange(0, [unicodesTextView.textStorage length])];
                TSGlyphPopoverUnicodesTextStorage *newStorage = [[TSGlyphPopoverUnicodesTextStorage alloc] initWithAttributedString:aStr];
                [unicodesTextView.layoutManager replaceTextStorage:newStorage];
                
                // extend popover height (if necessary)
                [unicodesTextView sizeToFit];
                NSRect rect = [unicodesTextView.layoutManager usedRectForTextContainer:unicodesTextView.textContainer];
                CGFloat newHeight = rect.size.height + 50;
                
                newHeight = (newHeight < oldHeight) ? oldHeight : MIN(newHeight, 300); // maximal height of popover
                
                // resize
                [[super view] setFrame:NSMakeRect(originalFrame.origin.x, originalFrame.origin.y, originalFrame.size.width, newHeight)];
            }
        } else {
            // unicode character name
            NSMutableString *mutableUnicodeName = [character mutableCopy];
            CFStringTransform((__bridge CFMutableStringRef)mutableUnicodeName, NULL, CFSTR("Any-Name"), NO);
            
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{(.+?)\\}" options:0 error:nil];
            NSTextCheckingResult *firstMatch = [regex firstMatchInString:mutableUnicodeName options:0
                                                                   range:NSMakeRange(0, [mutableUnicodeName length])];
            [self setUnicodeName:[mutableUnicodeName substringWithRange:[firstMatch rangeAtIndex:1]]];
            
            if (emojiStyle) {
                [self setUnicodeName:[NSString stringWithFormat:@"%@ (%@)", [self unicodeName],
                                      NSLocalizedString(emojiStyle, nil)]];
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
    NSPopover *popover = [[NSPopover alloc] init];
    [popover setContentViewController:self];
    [popover setBehavior:NSPopoverBehaviorSemitransient];
    [popover showRelativeToRect:positioningRect ofView:parentView preferredEdge:NSMinYEdge];
    [[parentView window] makeFirstResponder:parentView];
    
}

@end


