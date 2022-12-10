/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2005 Richard Koch
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * $Id: TSDocument-Syntax.m 262 2007-08-17 01:33:24Z richard_koch $
 *
 */

#import "UseMitsu.h"

#import "TSDocument.h"
#import "TSTextView.h"
#import "globals.h"


static BOOL isValidTeXCommandChar(NSInteger c);

static BOOL isValidTeXCommandChar(NSInteger c)
{
	if ((c >= 'A') && (c <= 'Z'))
		return YES;
	else if ((c >= 'a') && (c <= 'z'))
		return YES;
	else if (c == '@' && [SUD boolForKey:MakeatletterEnabledKey]) // added by Terada
		return YES; // added by Terada
    else if (((c == '@') || (c == '_') || (c == ':')) && [SUD boolForKey:expl3SyntaxColoringKey])
        return YES;
	else
		return NO;
}

/*
 * Syntax highlighting for TSDocument is implemented in the following code.
 * The general approach is this: We color ranges of text by using temporary
 * attributes of the layout manager(s) associated to our text view(s).
 * This is a lot faster than using plain text attributes (for example, regular
 * attributes cause the layout to be invalidated when they are changed,
 * which leads to a major slow down).
 * The core of this is in method colorizeText:range: which parses the text
 * applies syntax coloring to everything in the given range.
 *
 * For efficiency, we only actively colorize text which is visible. We colorize
 * in response to textDidChange:, to catch text typed by the user.
 * We also track changes to the text view (resizing, scrolling) and re-color
 * the visible text when any of those events occurs via colorizeVisibleAreaInTextView:.
 *
 * TODO: Consider moving the whole syntax coloring code to a separate class.
 */
@implementation TSDocument (SyntaxHighlighting)


// Colorize ("perform syntax highlighting") all the characters in the given range.
// Can only recolor full lines, so the given range will be extended accordingly before the
// coloring takes place.

// This routine contains a very important bug fix. If a very large document is loaded, the
// system immediately returns after the command which inserts text, and then text is added on
// a thread. As this text is added, the document resizes, and each resize calls the syntax
// coloring routine. The result is that the visible region is syntax colored over and over
// again. If the user tries to edit during this time, the rotating cursor appears, and eventually
// the program crashes.
//

// bypass [...], leaving "theLocation" pointing to the next element, and appropriately syntax coloring brackets
- (void)bypassBracketUsing: (NSLayoutManager *) layoutManager atLocation: (NSUInteger *)theLocation andLineEnd: (NSUInteger) aLineEnd
                      with: (NSString *) textString
{
    NSInteger       count;
    NSRange         charRange;
    BOOL            notDone;
    NSInteger       theChar;
   
    count = 1;
    charRange.location = *theLocation;
    charRange.length = 1;
    [layoutManager addTemporaryAttributes:self.markerColorAttribute forCharacterRange:charRange];
    (*theLocation)++;
    notDone = YES;
    while ((*theLocation < aLineEnd) && (notDone)) {
    theChar = [textString characterAtIndex: *theLocation];
    if (theChar == '[')
        count++;
    if (theChar == ']')
        count--;
    if (count == 0) {
        notDone = NO;
        charRange.location = *theLocation;
        charRange.length = 1;
        [layoutManager addTemporaryAttributes:self.markerColorAttribute forCharacterRange:charRange];
        }
    (*theLocation)++;
    }
}
    
// Notice the code below to avoid recoloring when the file is first opened!
- (void)colorizeText:(NSTextView *)aTextView range:(NSRange)range
{
    NSLayoutManager *layoutManager;
    NSString        *textString;
    NSUInteger        length;
    NSRange            colorRange, charRange;
    NSUInteger        location;
    NSInteger        theChar;
    NSUInteger        aLineStart;
    NSUInteger        aLineEnd;
    NSUInteger        end;
    NSInteger       count;
    BOOL            colorIndexDifferently;
    BOOL            colorFootnoteDifferently;
    NSTimeInterval    theTime;
    BOOL            TurnOffCommandSpellChecking;
    BOOL            TurnOffCommentSpellChecking;
    BOOL            TurnOffParameterSpellChecking;
    BOOL            ListHasWordsWhoseParametersShouldBeChecked;
    NSString        *commandString;
    NSRange         specialRange;
    BOOL            allDone;
    
    
    TurnOffCommandSpellChecking = [SUD boolForKey:TurnOffCommandSpellCheckKey];
    TurnOffCommentSpellChecking = [SUD boolForKey:TurnOffCommentSpellCheckKey];
    TurnOffParameterSpellChecking = [SUD boolForKey:TurnOffParameterSpellCheckKey];
    ListHasWordsWhoseParametersShouldBeChecked = [SUD boolForKey:ExceptionListExcludesParametersKey];
    
    
    if (isLoading) {
        if (firstTime == YES) {
            colorTime = [[NSDate date] timeIntervalSince1970];
            firstTime = NO;
            // secondTime = YES;
        }
        else {
            theTime = [[NSDate date] timeIntervalSince1970];
            
            // secondTime = NO;
            // NSLog([NSString stringWithFormat:@"%f", theTime]);
            // NSLog([NSString stringWithFormat:@"%f",colorTime]);
            if ((theTime - colorTime) < 1.0) {
                colorTime = theTime;
                if (! [SUD boolForKey: ColorImmediatelyKey] )
                    return;
            }
            else {
                isLoading = NO;
                [self doUpdate:self];
                // NSLog(@"it ended");
            }
        }
    }
    
    
    /*
     
     Experiments show that TSDocument routines can be called in the following order
     
     close
     colorizeText
     dealloc
     
     Thus colorizeText can be called after close but before dealloc. By the time it is
     called, some of the pieces of the document, including the toolbar, have been deallocated.
     
     This is why the code below does not itself look at the indexColorBox to get its state.
     
     */
    
    // The next line may not be necessary, but seems to produce a smoother result. Koch/2022
    // Actually, it causes a crash bug is a large number of blank lines are deleted and both syntax coloring and active line coloring are on. Koch, July 1, 2022
    
    // [self cursorMoved:[self textView]];

    
    colorIndexDifferently =  [self indexColorState];
    colorFootnoteDifferently = [SUD boolForKey: SyntaxColorFootnoteKey];
    
   
    // Fetch the underlying layout manager and string.
    layoutManager = [aTextView layoutManager];
    textString = [aTextView string];
    length = [textString length];
    
    // Clip the given range (call it paranoia, if you like :-).
    if (range.location >= length)
        return;
    if (range.location + range.length > length && ![SUD boolForKey:AlwaysHighlightEnabledKey]) // modified by Terada
        //    if (range.location + range.length > length)
        range.length = length - range.location;
    
    // We only perform coloring for full lines here, so extend the given range to full lines.
    // Note that aLineStart is the start of *a* line, but not necessarily the same line
    // for which aLineEnd marks the end! We may span many lines.
    [textString getLineStart:&aLineStart end:&aLineEnd contentsEnd:nil forRange:range];
    
    
    // Handle Persian, Arabic, and Hebrew Justification
    
    NSRange            lineRange, selectedLineRange, middleEastRange, testRange;
    NSCharacterSet    *middleEastSet;
    NSUInteger        start, theend;
    NSString        *theLine;
    
    if ([SUD boolForKey: RightJustifyKey]) {
        // Arabic and Persian range is 0600 - 06FF; Hebrew range is 0590 - 05FF
        middleEastRange.location = 0x0590;
        middleEastRange.length = 0x016F;
        middleEastSet = [NSCharacterSet characterSetWithRange: middleEastRange];
        
        lineRange.location = aLineStart;
        lineRange.length = 1;
        while (lineRange.location < aLineEnd) {
            [textString getLineStart: &start end: &theend contentsEnd: nil forRange: lineRange];
            lineRange.location = theend;
            selectedLineRange.location = start;
            selectedLineRange.length = theend - start;
            if ( ! [SUD boolForKey: RightJustifyIfAnyKey] ) {
                // a line must START with Persian, etc., to be right justified; later must have Persian in first three letters
                if (selectedLineRange.length >= 3)
                    selectedLineRange.length = 3;
            }
            theLine = [textString substringWithRange:selectedLineRange];
            testRange = [theLine rangeOfCharacterFromSet: middleEastSet];
            if (testRange.location == NSNotFound)
                [aTextView setAlignment: NSLeftTextAlignment range: selectedLineRange];
            else
                [aTextView setAlignment: NSRightTextAlignment range: selectedLineRange];
        }
    }
    
    
    
    // We reset the color of all chars in the given range to the regular color; later, we'll
    // then only recolor anything which is supposed to have another color.
    colorRange.location = aLineStart;
    colorRange.length = aLineEnd - aLineStart;
    
    /* September 4, 2018: Below is a dialog I don't understand. I don't understand why
     the first author commented out my line of code below, or why I put it back, or why
     Toudykov's code made it unnecessary!
     
     All I know is that when color support was completely rewritten for Mojave, removing a comment did not
     change the color of the ordinary text which followed from the comment color back to the ordinary text
     color. Then I reactivated my code, which fixed the problem, and then commented out
     Toudykov's code, which changed nothing. So we are back where we started. */
    
    
    // WARNING!! The following line has been commented out to restore changing the text color
    
    
    // June 27, 2008; Koch; I don't understand the previous warning; the line below fixes cases when removing a comment leaves text red
    // Sept 3, 2011; the Toudykov patch below makes this unnecessary
    [layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:colorRange];
    
    // the following line is deactivaeed active-line-colors are used because it caused them to to be removed when scrolling on May, 2022
    
    // HERE-RED
   if (( ! self.syntaxcolorEntry) && ( ![SUD boolForKey:AlwaysHighlightEnabledKey]))
      [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:colorRange];
    
    // the next line was added by Daniel Toundykov to allow changing the foreground and background source colors
    // [layoutManager addTemporaryAttributes:self.regularColorAttribute forCharacterRange:colorRange];
    /* End of this strange section.
     */
    
    
    // Now we iterate over the whole text and perform the actual recoloring.
    location = aLineStart;
    while (location < aLineEnd) {
        theChar = [textString characterAtIndex: location];
        
        if ((self.fileIsXML) && (theChar == '<'))
            [self syntaxColorXML: &location from: aLineStart to: aLineEnd using: textString with: layoutManager];
        
        else if ((self.fileIsXML) && (theChar == '&'))
             [self syntaxColorLimitedXML: &location and: aLineEnd using: textString with: layoutManager];
        
        else if ((theChar == '{') || (theChar == '}') || (theChar == '[') || (theChar == ']') || (theChar == '&') || (theChar == '$')) {
            // The six special characters { } [ ] & $ get an extra color.
            colorRange.location = location;
            colorRange.length = 1;
            [layoutManager addTemporaryAttributes:self.markerColorAttribute forCharacterRange:colorRange];
            location++;
        } else if (theChar == '%') {
            // Comments are started by %. Everything after that on the same line is a comment.
            colorRange.location = location;
            colorRange.length = 1;
            [textString getLineStart:nil end:nil contentsEnd:&end forRange:colorRange];
            colorRange.length = (end - location);
            [layoutManager addTemporaryAttributes:self.commentColorAttribute forCharacterRange:colorRange];
            location = end;
            // NDS - disable spell check for the range. Since comments aren't typeset this seems to make sense.
            if (TurnOffCommentSpellChecking)
                [aTextView setSpellingState:0 range:colorRange];
        }
        else if (theChar == g_texChar) {
            // A backslash (or a yen): a new TeX command starts here.
            // There are two cases: Either a sequence of letters A-Za-z follow, and we color all of them.
            // Or a single non-alpha character follows. Then we color that, too, but nothing else.
            colorRange.location = location;
            colorRange.length = 1;
            location++;
            if ((location < aLineEnd) && (!isValidTeXCommandChar([textString characterAtIndex: location]))) {
                location++;
                colorRange.length = location - colorRange.location;
                //    commandString = [textString substringWithRange: colorRange];
            } else {
                while ((location < aLineEnd) && (isValidTeXCommandChar([textString characterAtIndex: location]))) {
                    location++;
                    colorRange.length = location - colorRange.location;
                }
            }
            commandString = [textString substringWithRange: colorRange];
            [layoutManager addTemporaryAttributes:self.commandColorAttribute forCharacterRange:colorRange];
            if (TurnOffCommandSpellChecking)
                [aTextView setSpellingState:0 range:colorRange];
            
            
            
            if ((colorFootnoteDifferently) &&
                (([commandString isEqualToString: @"\\footnote"]) ||
                 ([commandString isEqualToString: @"\\autocite"]) ||
                //  ([commandString isEqualToString: @"\\cite"]) ||
                 ([commandString hasPrefix: @"\\cite"]) ||
                 ([commandString hasPrefix: @"\\Cite"]) ||
                 ([commandString isEqualToString: @"\\footcite"]))) {
             
                
                while ((location < aLineEnd) && ([textString characterAtIndex:location] == '['))
                    [self bypassBracketUsing: layoutManager atLocation: &location andLineEnd: aLineEnd with: textString];
                        
                if ((location < aLineEnd) && ([textString characterAtIndex:location] == '{'))
                        {
                        count = 1;
                        charRange.location = location;
                        charRange.length = 1;
                        [layoutManager addTemporaryAttributes:self.markerColorAttribute forCharacterRange:charRange];
                        location++;
                        colorRange.location = location;
                        BOOL notDone = YES;
                        while ((location < aLineEnd) && (notDone)) {
                            theChar = [textString characterAtIndex: location];
                            if (theChar == '{')
                                count++;
                            if (theChar == '}')
                                count--;
                            if (count == 0) {
                                notDone = NO;
                                allDone = YES;
                                colorRange.length = location - colorRange.location;
                                [layoutManager addTemporaryAttributes:self.footnoteColorAttribute forCharacterRange:colorRange];
                                charRange.location = location;
                                charRange.length = 1;
                                [layoutManager addTemporaryAttributes:self.markerColorAttribute forCharacterRange:charRange];
                            }
                            location++;
                        }
                    }
                }
            
            if ((colorIndexDifferently) &&
                // esindex below is a Spanish indexing command
                (([commandString isEqualToString: @"\\index"]) ||
                 ([commandString isEqualToString: @"\\esindex"]))) {
                    
                    while ((location < aLineEnd) && ([textString characterAtIndex:location] == '['))
                        [self bypassBracketUsing: layoutManager atLocation: &location andLineEnd: aLineEnd with: textString];
                    
                    if ((location < aLineEnd) && ([textString characterAtIndex:location] == '{'))
                    {
                        count = 1;
                        charRange.location = location;
                        charRange.length = 1;
                        [layoutManager addTemporaryAttributes:self.markerColorAttribute forCharacterRange:charRange];
                        location++;
                        colorRange.location = location;
                        BOOL notDone = YES;
                        while ((location < aLineEnd) && (notDone)) {
                            theChar = [textString characterAtIndex: location];
                            if (theChar == '{')
                                count++;
                            if (theChar == '}')
                                count--;
                            if (count == 0) {
                                notDone = NO;
                                allDone = YES;
                                colorRange.length = location - colorRange.location;
                                [layoutManager addTemporaryAttributes:self.indexColorAttribute forCharacterRange:colorRange];
                                charRange.location = location;
                                charRange.length = 1;
                                [layoutManager addTemporaryAttributes:self.markerColorAttribute forCharacterRange:charRange];
                            }
                            location++;
                        }
                    }
                }
            
            
      
            
            // Next comes a big decision. We can automatically  remove the first two parameters, either
            //    optional or required or both. In that case, there is a built-in list of commands to skip
            //    while doing this. This list can be extended by a hidden preference.
            
            //  OR
            
            //  We can conditionally remove the first two parameters, either optional or required or both.
            // In this ase, there is a built-in list of commands which we do this with. This list can be
            //    extended by a hidden preference.
            
            
            
            // Below the top works!
            
            else   if (
                       (( TurnOffParameterSpellChecking) && (ListHasWordsWhoseParametersShouldBeChecked) && (! [commandsToSpellCheck containsObject: commandString] ) &&
                        (! [userCommandsToSpellCheck containsObject: commandString] ))
                       ||
                       (( TurnOffParameterSpellChecking) && ( ! ListHasWordsWhoseParametersShouldBeChecked) && (( [commandsNotToSpellCheck containsObject: commandString] ) ||
                                                                                                                ( [userCommandsNotToSpellCheck containsObject: commandString]) ))
                       )
                
            {
                int square = 0;
                int curly = 0;
                BOOL notYetDone = YES;
                NSRange spellRange = colorRange;
                NSUInteger spellLocation = location;
                NSUInteger spellLength = spellRange.length;
                while ((spellLocation < aLineEnd) && (notYetDone)) {
                    theChar = [textString characterAtIndex: spellLocation];
                    if ((theChar == '{') || (theChar == '}') || (theChar == '[') || (theChar == ']') || (theChar == '&') || (theChar == '$')) {
                        // The six special characters { } [ ] & $ get an extra color.
                        specialRange.location = spellLocation;
                        specialRange.length = 1;
                        [layoutManager addTemporaryAttributes:self.markerColorAttribute forCharacterRange:specialRange];
                    }
                    
                    spellLocation++;
                    spellLength++;
                    if (theChar == '[')
                        square++;
                    if (theChar == ']')
                        square--;
                    if (theChar == '{')
                        curly++;
                    if (theChar == '}')
                        curly--;
                    if ((square == 0) && (curly == 0))
                    {
                        notYetDone = NO;
                        spellRange.length = spellLength;
                    }
                }
                
                square = 0;
                notYetDone = YES;
                spellLocation = location++;
                
                while ((spellLocation < aLineEnd) && (notYetDone)) {
                    theChar = [textString characterAtIndex: spellLocation];
                    if ((theChar == '{') || (theChar == '}') || (theChar == '[') || (theChar == ']') || (theChar == '&') || (theChar == '$')) {
                        // The six special characters { } [ ] & $ get an extra color.
                        specialRange.location = spellLocation;
                        specialRange.length = 1;
                        [layoutManager addTemporaryAttributes:self.markerColorAttribute forCharacterRange:specialRange];
                    }
                    
                    spellLocation++;
                    spellLength++;
                    if (theChar == '[')
                        square++;
                    if (theChar == ']')
                        square--;
                    if (theChar == '{')
                        curly++;
                    if (theChar == '}')
                        curly--;
                    if ((square == 0) && (curly == 0))
                    {
                        notYetDone = NO;
                        spellRange.length = spellLength;
                    }
                }
                
                [aTextView setSpellingState:0 range:spellRange];
            }
            
            
        }
        else location++;
    }
    
    // Now we color the background of the active line
    [self doEntryLineAndCursorColoring: (NSTextView *)aTextView];
 
    /*
    float           r, g, b;
    NSColor         *color;
    NSRange         mySelectedLineRange, currentLineRange, cursorRange;
    NSUInteger      startl, endl, theEnd;
    NSDictionary    *emphasizeAttribute;
    NSDictionary    *cursorAttribute;
    
    if (self.syntaxcolorEntry)
    {
        
        
        //    r = 0.9;
        //    g = 0.99;
        //    b = 0.99;
        
        //    color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
        //    emphasizeAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSBackgroundColorAttributeName, nil];
        
        mySelectedLineRange = [aTextView selectedRange];
        [textString getLineStart:&startl end:&endl contentsEnd:&theEnd forRange:mySelectedLineRange];
        currentLineRange.location = startl;
        currentLineRange.length = theEnd - startl;
        if (! self.blockCursor)
            [layoutManager addTemporaryAttributes:self.EntryColorAttribute forCharacterRange:currentLineRange];
        
        else
            
        {
            NSColor *cursorColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:BlockCursorRKey]
                green: [SUD floatForKey:BlockCursorGKey] blue: [SUD floatForKey:BlockCursorBKey] alpha:1.0];
            cursorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys: cursorColor, NSBackgroundColorAttributeName, nil];
            cursorRange = [aTextView selectedRange];
            if (cursorRange.length == 0)
            {
                cursorRange.length = 2;
                cursorRange.location = cursorRange.location - 2;
                if (cursorRange.location < startl)
                {
                    cursorRange.location = cursorRange.location + 1;
                    cursorRange.length = cursorRange.length - 1;
                }
                if (cursorRange.location < startl)
                {
                    cursorRange.location = cursorRange.location + 1;
                    cursorRange.length = cursorRange.length - 1;
                }
                [layoutManager addTemporaryAttributes:cursorAttribute forCharacterRange:cursorRange];
            }
        }
     
    }
 */
    
    // END OF ADDITION
 
    
    
    // finally, syntax color comments in XML
    if (self.fileIsXML)
         [self syntaxColorXMLCommentsfrom: aLineStart to: aLineEnd using: textString with: layoutManager];
    // we syntax color comments in xml separately at the end; do from aLineStart to aLineEnd
    // first search backward from aLineStart to find first "<~--" and "-->". If the first exists
    // and was LAST, then we are still in a comment. So find first "-->". If one does not exist
    // synctax color all as comment. Otherwise plow through pairs. When finally "<~-" is found
    // if "-->" does not exist, then color rest, else up to it
}




// Load the color definitions from the config system
- (void)setupColors
{
    /*
	CGFloat		r, g, b;
	NSColor		*color;

	//
	// Free the old text attributes
	//
	// [regularColorAttribute release];
	// [commandColorAttribute release];
	// [commentColorAttribute release];
	// [markerColorAttribute release];
	// [indexColorAttribute release];

	//
	// Setup the new ones. Note that only color and underline attributes are supported!
	//
	r = [SUD floatForKey:foreground_RKey];
	g = [SUD floatForKey:foreground_GKey];
	b = [SUD floatForKey:foreground_BKey];
	color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
	self.regularColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];

	r = [SUD floatForKey:commandredKey];
	g = [SUD floatForKey:commandgreenKey];
	b = [SUD floatForKey:commandblueKey];
	color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
	self.commandColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];

	r = [SUD floatForKey:commentredKey];
	g = [SUD floatForKey:commentgreenKey];
	b = [SUD floatForKey:commentblueKey];
	color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
	self.commentColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];

	r = [SUD floatForKey:markerredKey];
	g = [SUD floatForKey:markergreenKey];
	b = [SUD floatForKey:markerblueKey];
	color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
	self.markerColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];
	
	r = [SUD floatForKey:indexredKey];
	g = [SUD floatForKey:indexgreenKey];
	b = [SUD floatForKey:indexblueKey];
	color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
	self.indexColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];
    */
    
    [self colorizeVisibleAreaInTextView:textView1];
    [self colorizeVisibleAreaInTextView:textView2];
    
}

// This method is invoked when the syntax highlighting preferences are changed.
// It either colorizes the whole text or removes all the coloring.
- (void)reColor:(NSNotification *)notification
{
    
  	// if ([SUD boolForKey:SyntaxColoringEnabledKey]) {
    if (self.syntaxColor) {
		[self colorizeAll];
	} else {
		NSRange theRange;

		theRange.location = 0;
		theRange.length = [self.textStorage length];
		[[textView1 layoutManager] removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:theRange];
		[[textView2 layoutManager] removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:theRange];
	}
}

// Recolor when scrolling takes place
- (void)viewBoundsDidChange:(NSNotification *)notification
{
    
	[self colorizeVisibleAreaInTextView:[[notification object] documentView]];
}

// Recolor when resizing
- (void)viewFrameDidChange:(NSNotification *)notification
{
    
   [self colorizeVisibleAreaInTextView:[notification object]];
}

// Recolor when typing / text is inserted...
- (void)textDidChange:(NSNotification *)aNotification
{
// FIXME: There's a bug (also present in stock 2.03) when working in split view mode:
// If (for example) the upper view is positioned at the start of the document; and the
// lower view is positioned at a part of the document which is e.g. in the middle of the
// document (and I am assuming here that the document is at least a couple 'windows' high).
// and you then insert (paste) text into the upper view, the lower view's content is
// being scrolled. So far so good. But if you repeatedly insert text into the upper view,
// the lower view isn't updated anymore!

//	[self colorizeAll];
	[self fixColor :colorStart :colorEnd];
	if (tagLine)
		[self setupTags];
	colorStart = 0;
	colorEnd = 0;
	tagLine = NO;
	// [self updateChangeCount: NSChangeDone];
}

- (void)colorizeAll
{
  
   
  // No syntax coloring if the file is not TeX, or if it is disabled
	// if (!fileIsTex || ![SUD boolForKey:SyntaxColoringEnabledKey])
    if (!fileIsTex || !self.syntaxColor)
		return;

	// Recolor the visible area only.
	[self colorizeVisibleAreaInTextView:textView1];
	[self colorizeVisibleAreaInTextView:textView2];
}

- (void) colorizeVisibleAreaInTextView:(NSTextView *)aTextView
{

    
    // No syntax coloring if the file is not TeX, or if it is disabled
	// if (!fileIsTex || ![SUD boolForKey:SyntaxColoringEnabledKey])
     if (!fileIsTex || !self.syntaxColor)
		return;

	[self colorizeText:aTextView range:[aTextView visibleCharacterRange]];
}


// This is the main syntax coloring routine, used for everything except opening documents
- (void)fixColor: (NSUInteger)from : (NSUInteger)to
{
	NSRange			colorRange;
	NSUInteger		length;

	// No syntax coloring if the file is not TeX, or if it is disabled
	// if (!fileIsTex || ![SUD boolForKey:SyntaxColoringEnabledKey])
     if (!fileIsTex || !self.syntaxColor)
		return;

	length = [self.textStorage length];
	if (length == 0)
		return;

	// This is an attempt to be safe: we perform some clipping on the color range.
	// TODO: Consider replacing this by a NSAssert or so. It *shouldn't* happen, and if it
	// does anyway, then due to a bug in our code, which we'd like to know about so that we
	// can fix it... right?
	if (from >= length)
		from = length - 1;
	if (to > length)
		to = length;

	colorRange.location = from;
	colorRange.length = to - from;
	
	// TODO: Consider intersecting the range with the visible range ...

	// Colorize the range
    [self colorizeText:textView1 range:colorRange];
	[self colorizeText:textView2 range:colorRange];
    
}

- (void)cursorMoved: (NSTextView *)aTextView
{
    [self doEntryLineAndCursorColoring: (NSTextView *)aTextView];
    
    NSLayoutManager *layoutManager;
    NSString        *textString;
    
    float           r, g, b;
    NSColor         *color;
    NSRange         mySelectedLineRange, currentLineRange, fullRange, cursorRange;
    NSUInteger      startl, endl, theEnd;
    NSDictionary    *cursorAttribute;
    
     if (self.syntaxcolorEntry)
     {
         
    
         
         layoutManager = [aTextView layoutManager];
        textString = [aTextView string];
        
        [self removeCurrentLineColor: aTextView];
     
         [self doEntryLineAndCursorColoring: (NSTextView *)aTextView];
      /*
   //    if (self.syntaxColor)
   //         [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:[aTextVie
     //           visibleCharacterRange]];
   //     else
   //         {
   //         fullRange.location = 0;
   //         fullRange.length = [textString length];
   //         [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:fullRange];
   //         }
   
         
         mySelectedLineRange = [aTextView selectedRange];
         [textString getLineStart:&startl end:&endl contentsEnd:&theEnd forRange:mySelectedLineRange];
         currentLineRange.location = startl;
         currentLineRange.length = theEnd - startl;
         
         
       if (! self.blockCursor)
           [layoutManager addTemporaryAttributes:self.EntryColorAttribute forCharacterRange:currentLineRange];
      
    
         else
             
         {
             NSColor *cursorColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:BlockCursorRKey]
                 green: [SUD floatForKey:BlockCursorGKey] blue: [SUD floatForKey:BlockCursorBKey] alpha:1.0];
             cursorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys: cursorColor, NSBackgroundColorAttributeName, nil];
             cursorRange = [aTextView selectedRange];
             if (cursorRange.length == 0)
             {
                 cursorRange.length = 2;
                 cursorRange.location = cursorRange.location - 2;
                 if (cursorRange.location < startl)
                 {
                     cursorRange.location = cursorRange.location + 1;
                     cursorRange.length = cursorRange.length - 1;
                 }
                 if (cursorRange.location < startl)
                 {
                     cursorRange.location = cursorRange.location + 1;
                     cursorRange.length = cursorRange.length - 1;
                 }
                 [layoutManager addTemporaryAttributes:cursorAttribute forCharacterRange:cursorRange];
             }
         }
    */
    
    }
 

    
}

- (void)removeCurrentLineColor: (NSTextView *)aTextView
{
    NSLayoutManager *layoutManager;
    NSString        *textString;
    NSRange         fullRange;
    
    layoutManager = [aTextView layoutManager];
    textString = [aTextView string];
    fullRange.location = 0;
    fullRange.length = [textString length];
    [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:fullRange];
}
    

- (void)doEntryLineAndCursorColoring: (NSTextView *)aTextView
    {
        // Now we color the background of the active line
        
        
        NSRange         mySelectedLineRange, currentLineRange, cursorRange;
        NSUInteger      startl, endl, theEnd;
        NSDictionary    *cursorAttribute;
        NSLayoutManager *layoutManager;
        NSString        *textString;
        BOOL            writeCursor;
        
        if (self.syntaxcolorEntry)
        {
            layoutManager = [aTextView layoutManager];
            textString = [aTextView string];
            
            mySelectedLineRange = [aTextView selectedRange];
            [textString getLineStart:&startl end:&endl contentsEnd:&theEnd forRange:mySelectedLineRange];
            currentLineRange.location = startl;
            currentLineRange.length = theEnd - startl;
            if (! self.blockCursor)
                [layoutManager addTemporaryAttributes:self.EntryColorAttribute forCharacterRange:currentLineRange];
            
            else
                
            {
                NSColor *cursorColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:BlockCursorRKey]
                                                                 green: [SUD floatForKey:BlockCursorGKey] blue: [SUD floatForKey:BlockCursorBKey] alpha:1.0];
                BOOL goLeft;
                BOOL goCenter;
                BOOL twoCharacters;
                if ([SUD integerForKey:BlockWidthKey] == 0)
                    twoCharacters = NO;
                else
                    twoCharacters = YES;
                if ([SUD integerForKey:BlockSideKey] == 0)
                    goLeft = YES;
                else
                    goLeft = NO;
                if ([SUD integerForKey:BlockSideKey] == 1)
                    goCenter = YES;
                else
                    goCenter = NO;
                
                cursorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys: cursorColor, NSBackgroundColorAttributeName, nil];
                cursorRange = [aTextView selectedRange];
                
                if (cursorRange.length == 0)
                {
                    if (goCenter) {
                        
                        cursorRange.length = 2;
                        cursorRange.location = cursorRange.location - 1;
                        if (cursorRange.location < startl)
                        {
                            cursorRange.location = cursorRange.location + 1;
                            cursorRange.length = cursorRange.length - 1;
                        }
                        if ((cursorRange.location) >= (theEnd - 1))
                        {
                            cursorRange.length = 1;
                        }
                        if ((cursorRange.location) >= (theEnd))
                        {
                            cursorRange.length = 0;
                        }
                         
                        [layoutManager addTemporaryAttributes:cursorAttribute forCharacterRange:cursorRange];
            
                        
                    }
                     
                    
                    else if (goLeft) {
                        if (twoCharacters)
                        {
                            
                            cursorRange.length = 2;
                            cursorRange.location = cursorRange.location - 2;
                            if (cursorRange.location < startl)
                            {
                                cursorRange.location = cursorRange.location + 1;
                                cursorRange.length = cursorRange.length - 1;
                            }
                            if (cursorRange.location < startl)
                            {
                                cursorRange.location = cursorRange.location + 1;
                                cursorRange.length = cursorRange.length - 1;
                            }
                            
                           
                            [layoutManager addTemporaryAttributes:cursorAttribute forCharacterRange:cursorRange];
                            
                        }
                        
                        else
                        {
                            cursorRange.length = 1;
                            cursorRange.location = cursorRange.location - 1;
                            if (cursorRange.location < startl)
                            {
                                cursorRange.location = cursorRange.location + 1;
                                cursorRange.length = cursorRange.length - 1;
                            }
                     
                            [layoutManager addTemporaryAttributes:cursorAttribute forCharacterRange:cursorRange];
                        }
                    }
                    else
                    {
                        if (twoCharacters)
                        {
                            writeCursor = YES;
                            cursorRange.length = 2;
                             if ((cursorRange.location + 1) >= (theEnd))
                            {
                                cursorRange.length = cursorRange.length - 1;
                            }
                            if (cursorRange.location >= theEnd)
                                writeCursor = NO;
                            if (writeCursor)
                                [layoutManager addTemporaryAttributes:cursorAttribute forCharacterRange:cursorRange];
                        }
                        else
                        {
                            writeCursor = YES;
                            cursorRange.length = 1;
                            // if ((cursorRange.location + 1) == endl)
                            if ((cursorRange.location) >= (theEnd))
                                writeCursor = NO;
                              //  cursorRange.length = 1;
                               // cursorRange.location = cursorRange.location - 1;
                             if (writeCursor)
                                [layoutManager addTemporaryAttributes:cursorAttribute forCharacterRange:cursorRange];
                        }
                    }
                    
                }
            }
        }
    }

@end
