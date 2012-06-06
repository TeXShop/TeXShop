/*
 TSLayoutManager.m
 Created by Terada on Feb 2011.
 
 ------------
 TSLayoutManager is based on CotEditor - CELayoutManager (written by nakamuxu – http://www.aynimac.com/)
 CotEditor Copyright (c) 2004-2007 nakamuxu, All rights reserved.
 CotEditor is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html
 arranged by Terada, Feb 2011.
 -------------------------------------------------

 ------------
 CELayoutManager is based on Smultron - SMLLayoutManager (written by Peter Borg – http://smultron.sourceforge.net)
 Smultron Copyright (c) 2004 Peter Borg, All rights reserved.
 Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html
 arranged by nakamuxu, Jan 2005.
 -------------------------------------------------
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 
 
 =================================================
*/

#import "globals.h"
#import "TSLayoutManager.h"

@implementation TSLayoutManager
- (id)init
{
	[super init];
	unichar _tabCharacter0 = 0x2023;
	unichar _tabCharacter1 = 0x25B9;
//	unichar _tabCharacter2 = 0x21E5;
//	unichar _tabCharacter3 = 0x00AC;
	unichar _newLineCharacter0 = 0x21B5;
	unichar _newLineCharacter1 = 0x00B6;
//	unichar _newLineCharacter2 = 0x21A9;
//	unichar _newLineCharacter3 = 0x23CE;
	unichar _fullwidthSpaceCharacter0 = 0x25A1;
	unichar _fullwidthSpaceCharacter1 = 0x25A0;
//	unichar _fullwidthSpaceCharacter2 = 0x2022;
//	unichar _fullwidthSpaceCharacter3 = 0x22A0;
	unichar _spaceCharacter0 = 0x2423;
	unichar _spaceCharacter1 = 0x00B7;
//	unichar _spaceCharacter2 = 0x02D0;
//	unichar _spaceCharacter3 = 0x00B0;
	tabCharacters = [[NSArray arrayWithObjects:
					 [NSString stringWithCharacters:&_tabCharacter0 length:1],
					 [NSString stringWithCharacters:&_tabCharacter1 length:1],
//					 [NSString stringWithCharacters:&_tabCharacter2 length:1],
//					 [NSString stringWithCharacters:&_tabCharacter3 length:1],
					 nil
					 ] retain];
	newLineCharacters = [[NSArray arrayWithObjects:
					 [NSString stringWithCharacters:&_newLineCharacter0 length:1],
					 [NSString stringWithCharacters:&_newLineCharacter1 length:1],
//					 [NSString stringWithCharacters:&_newLineCharacter2 length:1],
//					 [NSString stringWithCharacters:&_newLineCharacter3 length:1],
					 nil
					 ] retain];
    fullwidthSpaceCharacters = [[NSArray arrayWithObjects:
								[NSString stringWithCharacters:&_fullwidthSpaceCharacter0 length:1],
								[NSString stringWithCharacters:&_fullwidthSpaceCharacter1 length:1],
//								[NSString stringWithCharacters:&_fullwidthSpaceCharacter2 length:1],
//								[NSString stringWithCharacters:&_fullwidthSpaceCharacter3 length:1],
								nil
								] retain];
	spaceCharacters = [[NSArray arrayWithObjects:
					   [NSString stringWithCharacters:&_spaceCharacter0 length:1],
					   [NSString stringWithCharacters:&_spaceCharacter1 length:1],
//					   [NSString stringWithCharacters:&_spaceCharacter2 length:1],
//					   [NSString stringWithCharacters:&_spaceCharacter3 length:1],
					   nil
					   ] retain];
	return self;
}

- (void)setInvisibleCharactersEnabled:(BOOL)enabled
{
	invisibleCharactersShowing = enabled;
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
	
	float r, g, b;
	r = [SUD floatForKey: invisibleCharRedKey];
	g = [SUD floatForKey: invisibleCharGreenKey];
	b = [SUD floatForKey: invisibleCharBlueKey];
	NSColor *theColor = [NSColor colorWithDeviceRed:r green:g blue:b alpha:1];
    // NSColor *theColor = [NSColor orangeColor];
	
    NSDictionary* _attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								 theFont, NSFontAttributeName, 
								 theColor, NSForegroundColorAttributeName,  nil];

	BOOL showTabCharacter = (invisibleCharactersShowing && [SUD boolForKey:showTabCharacterKey]);
	BOOL showNewLineCharacter = (invisibleCharactersShowing && [SUD boolForKey:showNewLineCharacterKey]);
	BOOL showFullwidthSpaceCharacter = (invisibleCharactersShowing && [SUD boolForKey:showFullwidthSpaceCharacterKey]);
	BOOL showSpaceCharacter = (invisibleCharactersShowing && [SUD boolForKey:showSpaceCharacterKey]);

	NSString *tabCharacter = [tabCharacters objectAtIndex:[SUD integerForKey:TabCharacterKindKey]];
    NSString *newLineCharacter = [newLineCharacters objectAtIndex:[SUD integerForKey:NewLineCharacterKindKey]];
    NSString *fullwidthSpaceCharacter = [fullwidthSpaceCharacters objectAtIndex:[SUD integerForKey:FullwidthSpaceCharacterKindKey]];
    NSString *spaceCharacter = [spaceCharacters objectAtIndex:[SUD integerForKey:SpaceCharacterKindKey]];
	
	for (theGlyphIndex = inGlyphRange.location; theGlyphIndex < theLengthToRedraw; theGlyphIndex++) {
		theCharIndex = [self characterIndexForGlyphAtIndex:theGlyphIndex];
		theCharacter = [theCompleteStr characterAtIndex:theCharIndex];
		
		if (theCharacter == '\t' && showTabCharacter ) {
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
