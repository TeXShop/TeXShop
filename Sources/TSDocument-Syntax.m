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
// Notice the code below to avoid recoloring when the file is first opened!
- (void)colorizeText:(NSTextView *)aTextView range:(NSRange)range
{
	NSLayoutManager *layoutManager;
	NSString		*textString;
	NSUInteger		length;
	NSRange			colorRange;
	NSUInteger		location;
	NSInteger		theChar;
	NSUInteger		aLineStart;
	NSUInteger		aLineEnd;
	NSUInteger		end;
	BOOL			colorIndexDifferently;
	NSTimeInterval	theTime;


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
	
	colorIndexDifferently = [self indexColorState];

	
	// Fetch the underlying layout manager and string.
	layoutManager = [aTextView layoutManager];
	textString = [aTextView string];
	length = [textString length];

	// Clip the given range (call it paranoia, if you like :-).
	if (range.location >= length)
		return;
	if (range.location + range.length > length && ![SUD boolForKey:AlwaysHighlightEnabledKey]) // modified by Terada
//	if (range.location + range.length > length)
		range.length = length - range.location;
	
	// We only perform coloring for full lines here, so extend the given range to full lines.
	// Note that aLineStart is the start of *a* line, but not necessarily the same line
	// for which aLineEnd marks the end! We may span many lines.
	[textString getLineStart:&aLineStart end:&aLineEnd contentsEnd:nil forRange:range];
	
	
	// Handle Persian, Arabic, and Hebrew Justification
	
	NSRange			lineRange, selectedLineRange, middleEastRange, testRange;
	NSCharacterSet	*middleEastSet;
	NSUInteger		start, theend;
	NSString		*theLine;
	
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
    
    // the next line was added by Daniel Toundykov to allow changing the foreground and background source colors
   // [layoutManager addTemporaryAttributes:self.regularColorAttribute forCharacterRange:colorRange];
    /* End of this strange section.
     */
    
    
	// Now we iterate over the whole text and perform the actual recoloring.
	location = aLineStart;
	while (location < aLineEnd) {
		theChar = [textString characterAtIndex: location];

		if ((theChar == '{') || (theChar == '}') || (theChar == '[') || (theChar == ']') || (theChar == '$')) {
			// The five special characters { } [ ] $ get an extra color.
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
		} else if (theChar == g_texChar) {
			// A backslash (or a yen): a new TeX command starts here.
			// There are two cases: Either a sequence of letters A-Za-z follow, and we color all of them.
			// Or a single non-alpha character follows. Then we color that, too, but nothing else.
			colorRange.location = location;
			colorRange.length = 1;
			location++;
			if ((location < aLineEnd) && (!isValidTeXCommandChar([textString characterAtIndex: location]))) {
				location++;
				colorRange.length = location - colorRange.location;
			} else {
				while ((location < aLineEnd) && (isValidTeXCommandChar([textString characterAtIndex: location]))) {
					location++;
					colorRange.length = location - colorRange.location;
				}
			}
			/*
			if (colorIndexDifferently) {
				NSString *commandString = [textString substringWithRange: colorRange];
				// esindex below is a Spanish indexing command
				if (([commandString isEqualToString: @"\\index"]) || ([commandString isEqualToString: @"\\esindex"])) {
					int parens = 0;
					BOOL notDone = YES;
					while ((location < aLineEnd) && (notDone)) {
						theChar = [textString characterAtIndex: location];
						location++;
						colorRange.length = location - colorRange.location;
						if (theChar == '{') 
							parens++;
						if (theChar == '}')
							parens--;
						if (parens == 0)
							notDone = NO;
						}
					[layoutManager addTemporaryAttributes:indexColorAttribute forCharacterRange:colorRange];
					}
				*/
				/* the above code was patched by Tammo Jan Dijkema to handle optional arguments for ColorIndex
				 (this is useful when using the package index, which creates optional indices). With this patch, 
				 the command \index[notation]{foo} gets colored as expected.*/
			if (colorIndexDifferently) {
				NSString *commandString = [textString substringWithRange: colorRange];
				// esindex below is a Spanish indexing command
				if (([commandString isEqualToString: @"\\index"]) || ([commandString isEqualToString: @"\\esindex"])) {
					NSInteger parens = 0;
					BOOL optparens = NO;
					BOOL notDone = YES;
					
					// Do first step of loop manually to check for optional argument for \index
					theChar = [textString characterAtIndex: location];
					location++;
					colorRange.length = location - colorRange.location;
					if (theChar == '{')
						parens++;
					else if (theChar == '[')
						optparens = YES;
					else
						notDone = NO;
					
					while ((location < aLineEnd) && (notDone)) {
						theChar = [textString characterAtIndex: location];
						location++;
						colorRange.length = location - colorRange.location;
						if (theChar == '{')
							parens++;
						if (theChar == '}')
							parens--;
						if (parens == 0 && !optparens)
							notDone = NO;
						if (theChar == ']')
							optparens = NO;
					}
					[layoutManager addTemporaryAttributes:self.indexColorAttribute forCharacterRange:colorRange];
				}
				else
					[layoutManager addTemporaryAttributes:self.commandColorAttribute forCharacterRange:colorRange];
				}
			else
				[layoutManager addTemporaryAttributes:self.commandColorAttribute forCharacterRange:colorRange];
		} else
			location++;
	}
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


@end
