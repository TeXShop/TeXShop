#import "TeXLayoutManager.h"

@implementation TeXLayoutManager
- (id)init
{
	[super init];
	unichar _tabCharacter0 = 0x2023;
	unichar _tabCharacter1 = 0x25B9;
	unichar _newLineCharacter0 = 0x21B5;
	unichar _newLineCharacter1 = 0x00B6;
	unichar _fullwidthSpaceCharacter0 = 0x25A1;
	unichar _fullwidthSpaceCharacter1 = 0x25A0;
	unichar _spaceCharacter0 = 0x2423;
	unichar _spaceCharacter1 = 0x00B7;
	tabCharacters = [[NSArray arrayWithObjects:
                      [NSString stringWithCharacters:&_tabCharacter0 length:1],
                      [NSString stringWithCharacters:&_tabCharacter1 length:1],
                      nil
                      ] retain];
	newLineCharacters = [[NSArray arrayWithObjects:
                          [NSString stringWithCharacters:&_newLineCharacter0 length:1],
                          [NSString stringWithCharacters:&_newLineCharacter1 length:1],
                          nil
                          ] retain];
    fullwidthSpaceCharacters = [[NSArray arrayWithObjects:
                                 [NSString stringWithCharacters:&_fullwidthSpaceCharacter0 length:1],
                                 [NSString stringWithCharacters:&_fullwidthSpaceCharacter1 length:1],
                                 nil
                                 ] retain];
	spaceCharacters = [[NSArray arrayWithObjects:
                        [NSString stringWithCharacters:&_spaceCharacter0 length:1],
                        [NSString stringWithCharacters:&_spaceCharacter1 length:1],
                        nil
                        ] retain];
	return self;
}

- (NSPoint)pointToDrawGlyphAtIndex:(unsigned int)inGlyphIndex adjust:(NSSize)inSize
{
    NSPoint outPoint = [self locationForGlyphAtIndex:inGlyphIndex];
    NSRect theGlyphRect = [self lineFragmentRectForGlyphAtIndex:inGlyphIndex effectiveRange:NULL];
	
    outPoint.x += inSize.width;
    outPoint.y = theGlyphRect.origin.y - inSize.height;
	
    return outPoint;
}

- (void)drawGlyphsForGlyphRange:(NSRange)inGlyphRange atPoint:(NSPoint)inContainerOrigin
{
    NSString *theCompleteStr = [[self textStorage] string];
    unsigned int theLengthToRedraw = NSMaxRange(inGlyphRange);
    unsigned int theGlyphIndex, theCharIndex = 0;
    unichar theCharacter;
    NSPoint thePointToDraw;
	
	float theInsetWidth = 0.0;
	float theInsetHeight = 4.0;
	NSSize theSize = NSMakeSize(theInsetWidth, theInsetHeight);
	
    NSFont *theFont = [[self textStorage] font];
    NSColor *theColor = [NSColor orangeColor];
    NSDictionary* _attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								 theFont, NSFontAttributeName, 
								 theColor, NSForegroundColorAttributeName,  nil];

	NSDictionary* texshopSettings = [NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/TeXShop.plist"]];
	BOOL showTabCharacter, showNewLineCharacter, showFullwidthSpaceCharacter, showSpaceCharacter;
	NSString *tabCharacter, *newLineCharacter, *fullwidthSpaceCharacter, *spaceCharacter;

	if (texshopSettings) {
		showTabCharacter = [[texshopSettings objectForKey:@"ShowTabCharacter"] boolValue];
		showNewLineCharacter = [[texshopSettings objectForKey:@"ShowNewLineCharacter"] boolValue];
		showFullwidthSpaceCharacter = [[texshopSettings objectForKey:@"ShowFullwidthSpaceCharacter"] boolValue];
		showSpaceCharacter = [[texshopSettings objectForKey:@"ShowSpaceCharacter"] boolValue];
        tabCharacter = [tabCharacters objectAtIndex:[[texshopSettings objectForKey:@"TabCharacterKind"] intValue]];
        newLineCharacter = [newLineCharacters objectAtIndex:[[texshopSettings objectForKey:@"NewLineCharacterKind"] intValue]];
        fullwidthSpaceCharacter = [fullwidthSpaceCharacters objectAtIndex:[[texshopSettings objectForKey:@"FullwidthSpaceCharacterKind"] intValue]];
        spaceCharacter = [spaceCharacters objectAtIndex:[[texshopSettings objectForKey:@"SpaceCharacterKind"] intValue]];
	}else {
		showTabCharacter = YES;
		showNewLineCharacter = YES;
		showFullwidthSpaceCharacter = YES;
		showSpaceCharacter = YES;
        tabCharacter = [tabCharacters objectAtIndex:0];
        newLineCharacter = [newLineCharacters objectAtIndex:0];
        fullwidthSpaceCharacter = [fullwidthSpaceCharacters objectAtIndex:0];
        spaceCharacter = [spaceCharacters objectAtIndex:0];
	}
	
	for (theGlyphIndex = inGlyphRange.location; theGlyphIndex < theLengthToRedraw; theGlyphIndex++) {
		theCharIndex = [self characterIndexForGlyphAtIndex:theGlyphIndex];
		theCharacter = [theCompleteStr characterAtIndex:theCharIndex];
		
		if (theCharacter == '\t' && showTabCharacter) {
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[tabCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];
		} else if (theCharacter == '\n' && showNewLineCharacter) {
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[newLineCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];
		} else if (theCharacter == 0x3000 && showFullwidthSpaceCharacter) { // Fullwidth-space (JP)
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[fullwidthSpaceCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];
		} else if (theCharacter == ' ' && showSpaceCharacter) {
			thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
			[spaceCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];
		}
	}
	[super drawGlyphsForGlyphRange:inGlyphRange atPoint:inContainerOrigin];
}

@end