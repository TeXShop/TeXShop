#import "TeXTextView.h"

static BOOL isValidTeXCommandChar(NSInteger c)
{
	if ((c >= 'A') && (c <= 'Z'))
		return YES;
	else if ((c >= 'a') && (c <= 'z'))
		return YES;
	else if (c == '@')
		return YES;
	else
		return NO;
}

@implementation TeXTextView (Colorize)
- (void)colorizeText:(BOOL)colorize
{
	NSLayoutManager *layoutManager;
	NSString		*textString;
	NSUInteger		length;
	NSRange			colorRange;
	NSUInteger		location;
	NSInteger				theChar;
	NSUInteger		aLineStart;
	NSUInteger		aLineEnd;
	NSUInteger		end;
	
	CGFloat r,g,b;
	NSColor* color;
	NSDictionary	*commandColorAttribute;
	NSDictionary	*commentColorAttribute;
	NSDictionary	*markerColorAttribute;
	

	if (![[NSFileManager defaultManager] fileExistsAtPath:texshopPlistPath]) return;
	
	NSDictionary *texshopSettings = [NSDictionary dictionaryWithContentsOfFile:texshopPlistPath];
	if(texshopSettings && ![[texshopSettings objectForKey:@"SyntaxColoringEnabled"] boolValue]) return;

	color = [NSColor textColor];
	
	r = [[texshopSettings objectForKey:@"commandred"] floatValue];
	g = [[texshopSettings objectForKey:@"commandgreen"] floatValue];
	b = [[texshopSettings objectForKey:@"commandblue"] floatValue];
	if(colorize) color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
	commandColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];
	
	r = [[texshopSettings objectForKey:@"commentred"] floatValue];
	g = [[texshopSettings objectForKey:@"commentgreen"] floatValue];
	b = [[texshopSettings objectForKey:@"commentblue"] floatValue];
	if(colorize) color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
	commentColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];
	
	r = [[texshopSettings objectForKey:@"markerred"] floatValue];
	g = [[texshopSettings objectForKey:@"markergreen"] floatValue];
	b = [[texshopSettings objectForKey:@"markerblue"] floatValue];
	if(colorize) color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
	markerColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];
	
	
	// Fetch the underlying layout manager and string.
	layoutManager = [self layoutManager];
	textString = [self string];
	length = [textString length];
	
	NSRange range = NSMakeRange(0, length);
	
	
	// We only perform coloring for full lines here, so extend the given range to full lines.
	// Note that aLineStart is the start of *a* line, but not necessarily the same line
	// for which aLineEnd marks the end! We may span many lines.
	[textString getLineStart:&aLineStart end:&aLineEnd contentsEnd:nil forRange:range];
	
	
	
	// We reset the color of all chars in the given range to the regular color; later, we'll
	// then only recolor anything which is supposed to have another color.
	colorRange.location = aLineStart;
	colorRange.length = aLineEnd - aLineStart;
	// WARNING!! The following line has been commented out to restore changing the text color
	// June 27, 2008; Koch; I don't understand the previous warning; the line below fixes cases when removing a comment leaves text red
	[layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:colorRange];
	
	// Now we iterate over the whole text and perform the actual recoloring.
	location = aLineStart;
	while (location < aLineEnd) {
		theChar = [textString characterAtIndex: location];
		
		if ((theChar == '{') || (theChar == '}') || (theChar == '$')) {
			// The three special characters { } $ get an extra color.
			colorRange.location = location;
			colorRange.length = 1;
			[layoutManager addTemporaryAttributes:markerColorAttribute forCharacterRange:colorRange];
			location++;
		} else if (theChar == '%') {
			// Comments are started by %. Everything after that on the same line is a comment.
			colorRange.location = location;
			colorRange.length = 1;
			[textString getLineStart:nil end:nil contentsEnd:&end forRange:colorRange];
			colorRange.length = (end - location);
			[layoutManager addTemporaryAttributes:commentColorAttribute forCharacterRange:colorRange];
			location = end;
		} else if (theChar == texChar) {
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
			
			[layoutManager addTemporaryAttributes:commandColorAttribute forCharacterRange:colorRange];
		} else
			location++;
	}
}

- (void)resetHighlight:(id)sender
{
	[self colorizeText:YES];
}

- (void)showIndicator:(NSString*)range
{
	[self showFindIndicatorForRange:NSRangeFromString(range)];
}

- (void)resetBackgroundColor:(id)sender
{
	[[self layoutManager] removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, [[self textStorage] length])];
}

- (void)highlightContent:(NSString*)range
{
    NSColor *color;
	NSDictionary *texshopSettings = [NSDictionary dictionaryWithContentsOfFile:texshopPlistPath];
    if (texshopSettings) {
        CGFloat r, g, b;
        r = [[texshopSettings objectForKey:@"highlightContentRed"] floatValue];
        g = [[texshopSettings objectForKey:@"highlightContentGreen"] floatValue];
        b = [[texshopSettings objectForKey:@"highlightContentBlue"] floatValue];
        color = [NSColor colorWithDeviceRed:r green:g blue:b alpha:1];
    }else{
        color = [NSColor colorWithDeviceRed:1 green:1 blue:0.5 alpha:1];
    }
    
	[[self layoutManager] addTemporaryAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
												   color,
												   NSBackgroundColorAttributeName, nil ]
							   forCharacterRange:NSRangeFromString(range)];
}

- (void)setBackgroundColorOfTextView:(NSColor*)color
{
	[self setBackgroundColor:color];
}

- (void)resetBackgroundColorOfTextView:(NSColor*)color
{
	[self setBackgroundColor:color];
	coloringNow = NO;
}

- (void)textViewDidChangeSelection:(NSNotification *)inNotification
{
	NSLayoutManager* layoutManager = [self layoutManager];

	// Notification の処理で色づけの変更を行うと，delete を押したときにバグるので，performSelector で別途呼び出して処理する
	[self performSelector:@selector(resetBackgroundColor:) 
			   withObject:nil afterDelay:0]; // 既存の背景色の消去
	
	[self resetHighlight:nil];

	NSDictionary *texshopSettings = [NSDictionary dictionaryWithContentsOfFile:texshopPlistPath];
    if (texshopSettings) {
        CGFloat r, g, b;
        r = [[texshopSettings objectForKey:@"highlightBracesRed"] floatValue];
        g = [[texshopSettings objectForKey:@"highlightBracesGreen"] floatValue];
        b = [[texshopSettings objectForKey:@"highlightBracesBlue"] floatValue];
        highlightBracesColorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSColor colorWithDeviceRed:r green:g blue:b alpha:1], NSForegroundColorAttributeName, nil ];
    }else{
        highlightBracesColorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSColor magentaColor], NSForegroundColorAttributeName, nil ];
    }
	unichar k_braceCharList[] = {0x0028, 0x0029, 0x005B, 0x005D, 0x007B, 0x007D, 0x003C, 0x003E}; // == ()[]{}<>
    
	NSString *theString = [[self textStorage] string];
    NSInteger theStringLength = [theString length];
    if (theStringLength == 0) { return; }
    NSRange theSelectedRange = [self selectedRange];
    NSInteger theLocation = theSelectedRange.location;
    NSInteger theDifference = theLocation - lastCursorLocation;
    lastCursorLocation = theLocation;

	if (theStringLength - lastStringLength == -1) {
		lastStringLength = theStringLength;
		return;
	}
	lastStringLength = theStringLength;
	
    if (theDifference != 1 && theDifference != -1) { // != 1 の方だけだと，キャレットを後方移動した場合にのみ強調表示させる
        return; // If the difference is more than one, they've moved the cursor with the mouse or it has been moved by resetSelectedRange below and we shouldn't check for matching braces then
    }
    
    if (theDifference == 1) { // Check if the cursor has moved forward
        theLocation--;
    }
	
    if (theLocation == theStringLength) {
        return;
    }
	NSInteger originalLocation = theLocation;

	BOOL checkBrace, checkBracket, checkSquareBracket, checkParen;
	
	if (texshopSettings) {
		checkBrace = [[texshopSettings objectForKey:@"CheckBraceEnabled"] boolValue];
		checkBracket = [[texshopSettings objectForKey:@"CheckBracketEnabled"] boolValue];
		checkSquareBracket = [[texshopSettings objectForKey:@"CheckSquareBracketEnabled"] boolValue];
		checkParen = [[texshopSettings objectForKey:@"CheckParenEnabled"] boolValue];
	}else {
		checkBrace = YES;
		checkBracket = NO;
		checkSquareBracket = YES;
		checkParen = YES;
	}

	
    unichar theUnichar = [theString characterAtIndex:theLocation];
	BOOL notCS = (((theLocation > 0) ? [theString characterAtIndex:theLocation-1] : 0) != texChar);
    unichar theCurChar, theBraceChar;
	NSInteger inc;
    if (theUnichar == ')' && checkParen && notCS) {
        theBraceChar = k_braceCharList[0];
		inc = -1;
    } else if (theUnichar == '(' && checkParen && notCS) {
        theBraceChar = k_braceCharList[1];
		inc = 1;
    } else if (theUnichar == ']' && checkSquareBracket && notCS) {
        theBraceChar = k_braceCharList[2];
		inc = -1;
    } else if (theUnichar == '[' && checkSquareBracket && notCS) {
        theBraceChar = k_braceCharList[3];
		inc = 1;
    } else if (theUnichar == '}' && checkBrace && notCS) {
        theBraceChar = k_braceCharList[4];
		inc = -1;
    } else if (theUnichar == '{' && checkBrace && notCS) {
        theBraceChar = k_braceCharList[5];
		inc = 1;
    } else if (theUnichar == '>' && checkBracket && notCS) {
        theBraceChar = k_braceCharList[6];
		inc = -1;
    } else if (theUnichar == '<' && checkBracket && notCS) {
        theBraceChar = k_braceCharList[7];
		inc = 1;
    } else {
        return;
    }
    NSUInteger theSkipMatchingBrace = 0;
    theCurChar = theUnichar;
	
    while ((theLocation += inc) >= 0 && (theLocation < theStringLength)) {
        theUnichar = [theString characterAtIndex:theLocation];
		notCS = (((theLocation > 0) ? [theString characterAtIndex:theLocation-1] : 0) != texChar);
        if (theUnichar == theBraceChar && notCS) {
            if (!theSkipMatchingBrace) {
				// 一瞬選択する方式での強調表示
				/*
				 [self setSelectedRange: NSMakeRange(theLocation, 1)
				 affinity: NSSelectByCharacter stillSelecting: YES];
				 [self display];
				 NSDate* myDate = [NSDate date];
				 while ([myDate timeIntervalSinceNow] > - 0.075);
				 [self setSelectedRange: theSelectedRange];
				 */
				
				// 色づけ方式での強調表示
				[layoutManager addTemporaryAttributes:highlightBracesColorDict 
									forCharacterRange:NSMakeRange(theLocation, 1)];
				[layoutManager addTemporaryAttributes:highlightBracesColorDict 
									forCharacterRange:NSMakeRange(originalLocation, 1)];
				[self display];

				if (!texshopSettings || [[texshopSettings objectForKey:@"HighlightContentEnabled"] boolValue]) {
					[self performSelector:@selector(highlightContent:) 
							   withObject:NSStringFromRange(NSMakeRange(MIN(originalLocation, theLocation), ABS(originalLocation - theLocation)+1)) afterDelay:0];
				}
				if ((!texshopSettings || [[texshopSettings objectForKey:@"ShowIndicatorForMoveEnabled"] boolValue]) && !autoCompleting) {
					[self performSelector:@selector(showIndicator:) 
							   withObject:NSStringFromRange(NSMakeRange(theLocation, 1)) 
							   afterDelay:0];
				}
				
				if (!texshopSettings || [[texshopSettings objectForKey:@"AlwaysHighlightEnabled"] boolValue]) {
					[self performSelector:@selector(resetHighlight:) 
							   withObject:NSStringFromRange(NSMakeRange(theLocation, 1)) afterDelay:0.30];
				}
				
                return;
            } else {
                theSkipMatchingBrace += inc;
            }
        } else if (theUnichar == theCurChar && notCS) {
            theSkipMatchingBrace -= inc;
        }
    }
	// 対応する開始括弧がなかったときの処理
    if(!texshopSettings || [[texshopSettings objectForKey:@"BeepEnabled"] boolValue]) NSBeep();
	if((!texshopSettings || [[texshopSettings objectForKey:@"FlashBackgroundEnabled"] boolValue]) && !coloringNow) {
		originalBackgroundColor = [self backgroundColor];
		[self performSelector:@selector(setBackgroundColorOfTextView:) 
				   withObject:[NSColor colorWithDeviceRed:1 green:0.95 blue:1 alpha:1]
				   afterDelay:0];
		coloringNow = YES;
		[self performSelector:@selector(resetBackgroundColorOfTextView:) 
				   withObject:originalBackgroundColor afterDelay:0.20];
	}}

- (BOOL)shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
	[super shouldChangeTextInRange:affectedCharRange replacementString:replacementString];
	
	NSRange			matchRange;
	NSString		*textString;
	NSInteger		i, j, count, uchar, leftpar, rightpar;
	
	if ([replacementString length] != 1)
		return YES;
	
	rightpar = [replacementString characterAtIndex:0];

	BOOL checkBrace, checkBracket, checkSquareBracket, checkParen;
	
	NSDictionary* texshopSettings = [NSDictionary dictionaryWithContentsOfFile:texshopPlistPath];
	if (texshopSettings) {
		checkBrace = [[texshopSettings objectForKey:@"CheckBraceEnabled"] boolValue];
		checkBracket = [[texshopSettings objectForKey:@"CheckBracketEnabled"] boolValue];
		checkSquareBracket = [[texshopSettings objectForKey:@"CheckSquareBracketEnabled"] boolValue];
		checkParen = [[texshopSettings objectForKey:@"CheckParenEnabled"] boolValue];
	}else {
		checkBrace = YES;
		checkBracket = NO;
		checkSquareBracket = YES;
		checkParen = YES;
	}	
		if (!(   ((rightpar == '}') && checkBrace)
			  || ((rightpar == ')') && checkParen)
			  || ((rightpar == '>') && checkBracket)
			  || ((rightpar == ']') && checkSquareBracket ))){
			return YES;
		}
		
		if (rightpar == '}')
			leftpar = '{';
		else if (rightpar == ')')
			leftpar = '(';
		else if (rightpar == '>')
			leftpar = '<';
		else
			leftpar = '[';
		
		textString = [self string];
		i = affectedCharRange.location;
		j = 1;
		count = 1;
		
		BOOL notCS = (((i > 0) ? [textString characterAtIndex:i-1] : 0) != texChar);
		if (!notCS) {
			return YES;
		}
		
		while ((i > 0) && (j < 5000)) {
			i--; j++;
			uchar = [textString characterAtIndex:i];
			notCS = (((i > 0) ? [textString characterAtIndex:i-1] : 0) != texChar);
			if (uchar == rightpar && notCS)
				count++;
			else if (uchar == leftpar && notCS)
				count--;
			if (count == 0) {
				matchRange.location = i;
				matchRange.length = 1;
				
				if (!texshopSettings || [[texshopSettings objectForKey:@"brieflyFlashYellowForMatch"] boolValue]){
					[self performSelector:@selector(showIndicator:) 
							   withObject:NSStringFromRange(matchRange)
							   afterDelay:0.0];
				}
				else {
					[self setSelectedRange: matchRange
									  affinity: NSSelectByCharacter stillSelecting: YES];
					
					[self display];
					NSDate *myDate = [NSDate date];
					/* Koch: Jan 26, 2001: changed -0.15 to -0.075 to speed things up */
					while ([myDate timeIntervalSinceNow] > - 0.075);
					[self setSelectedRange: affectedCharRange];
				}
				
				break;
			}
		}
	
	return YES;
}

-(void)textDidEndEditing:(NSNotification*)aNotification
{
	[self performSelector:@selector(resetBackgroundColor:) 
			   withObject:nil afterDelay:0]; // 既存の背景色の消去
	[self resetHighlight:nil];
}

@end
