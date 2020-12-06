#import "TeXTextView.h"

static NSString* placeholderString = @"•";
static NSString* startcommentString = @"•‹";
static NSString* endcommentString = @"›";

@implementation TeXTextView (CommandCompletion)
- (IBAction) doNextBullet: (id)sender // modified by (HS)
{
    NSRange tempRange, forwardRange, markerRange, commentRange;
    NSString *text;
	
    text = [self string];
    tempRange = [self selectedRange];
    tempRange.location += tempRange.length; // move the range to after the selection (a la Find) to avoid re-finding (HS)
    //set up a search range from here to eof
    forwardRange.length = [text length] - tempRange.location;
    forwardRange.location = tempRange.location;
    markerRange = [text rangeOfString:placeholderString options:NSLiteralSearch range:forwardRange];
    //if marker found - set commentRange there and look for end of comment
    if (markerRange.location != NSNotFound){ // marker found
		commentRange.location = markerRange.location;
		commentRange.length = [text length] - commentRange.location;
		commentRange = [text rangeOfString:startcommentString options:NSLiteralSearch range:commentRange];
		if ((commentRange.location != NSNotFound) && (commentRange.location == markerRange.location)){
			// found comment start right after marker --- there is a comment
			commentRange.location = markerRange.location;
			commentRange.length = [text length] - markerRange.location;
			commentRange = [text rangeOfString:endcommentString options:NSLiteralSearch range:commentRange];
			if (commentRange.location != NSNotFound){
				markerRange.length = commentRange.location - markerRange.location + commentRange.length;
			}
		}
		[self setSelectedRange:markerRange];
		[self scrollRangeToVisible:markerRange];
    }
    else NSBeep();
	//NSLog(@"Next • hit");
}

- (IBAction) doPreviousBullet: (id)sender // modified by (HS)
{
    NSRange tempRange, backwardRange, markerRange, commentRange;
    NSString *text;
	
    text = [self string];
    tempRange = [self selectedRange];
    //set up a search range from string start to beginning of selection
    backwardRange.length = tempRange.location;
    backwardRange.location = 0;
    markerRange = [text rangeOfString:placeholderString options:NSBackwardsSearch range:backwardRange];
    //if marker found - set commentRange there and look for end of comment
    if (markerRange.location != NSNotFound){ // marker found
		commentRange.location = markerRange.location;
		commentRange.length = [text length] - commentRange.location;
		commentRange = [text rangeOfString:startcommentString options:NSLiteralSearch range:commentRange];
		if ((commentRange.location != NSNotFound) && (commentRange.location == markerRange.location)){
			// found comment start right after marker --- there is a comment
			commentRange.location = markerRange.location;
			commentRange.length = [text length] - markerRange.location;
			commentRange = [text rangeOfString:endcommentString options:NSLiteralSearch range:commentRange];
			if (commentRange.location != NSNotFound){
				markerRange.length = commentRange.location - markerRange.location + commentRange.length;
			}
		}
		[self setSelectedRange:markerRange];
		[self scrollRangeToVisible:markerRange];
    }
    else NSBeep();
	//NSLog(@"Next • hit");
}

- (void)registerUndoWithString:(NSString *)oldString location:(unsigned)oldLocation
						length: (unsigned)newLength key:(NSString *)key
{
	NSUndoManager	*myManager;
	NSMutableDictionary	*myDictionary;
	NSNumber		*theLocation, *theLength;
	
	// Create & register an undo action
	myManager = [self undoManager];
	myDictionary = [NSMutableDictionary dictionaryWithCapacity: 4];
	theLocation = [NSNumber numberWithUnsignedInt: oldLocation];
	theLength = [NSNumber numberWithUnsignedInt: newLength];
	[myDictionary setObject: oldString forKey: @"oldString"];
	[myDictionary setObject: theLocation forKey: @"oldLocation"];
	[myDictionary setObject: theLength forKey: @"oldLength"];
	[myDictionary setObject: key forKey: @"undoKey"];
	[myManager registerUndoWithTarget:self selector:@selector(undoSpecial:) object: myDictionary];
	[myManager setActionName:key];
}


- (void)undoSpecial:(id)theDictionary
{
	NSRange		undoRange;
	NSString	*oldString, *newString, *undoKey;
	
	// Retrieve undo info
	undoRange.location = [[theDictionary objectForKey: @"oldLocation"] unsignedIntValue];
	undoRange.length = [[theDictionary objectForKey: @"oldLength"] unsignedIntValue];
	newString = [theDictionary objectForKey: @"oldString"];
	undoKey = [theDictionary objectForKey: @"undoKey"];
	
	if (undoRange.location+undoRange.length > [[self string] length])
		return; // something wrong happened
	
	oldString = [[self string] substringWithRange: undoRange];
	
	// Replace the text
	[self replaceCharactersInRange:undoRange withString:newString];
	[self registerUndoWithString:oldString location:undoRange.location
						  length:[newString length] key:undoKey];
	
	[self resetBackgroundColor:nil];
}

- (void)keyDown:(NSEvent *)theEvent
{
	if([self hasMarkedText]) return [super keyDown: theEvent]; // 日本語入力中はそのままイベントを通す
	
	// FIXME: Using static variables like this is *EVIL*
	// It will simply not work correctly when using more than one window/view (which we frequently do)!
	// TODO: Convert all of these static stack variables to member variables.
	
	static BOOL wasCompleted = NO; // was completed on last keyDown
	static BOOL latexSpecial = NO; // was last time LaTeX Special?  \begin{...}
	static NSString *originalString = nil; // string before completion, starts at replaceLocation
	static NSString *currentString = nil; // completed string
	static NSUInteger replaceLocation = NSNotFound; // completion started here
	static NSUInteger completionListLocation = 0; // location to start search in the list
	static NSUInteger textLocation = NSNotFound; // location of insertion point
	BOOL foundCandidate;
	NSString *textString, *foundString, *latexString = 0;
	NSMutableString *newString;
	NSUInteger selectedLocation, currentLength;
	NSRange foundRange, searchRange, spaceRange, insRange, replaceRange;
	// Start Changed by (HS) - define ins2Range, selectlength
	NSRange ins2Range;
	NSUInteger selectlength = 0;
	// End Changed by (HS) - define ins2Range, selectlength
	NSCharacterSet *charSet;
	unichar c;
	
	if (([[theEvent characters] isEqualToString: g_commandCompletionChar]  && ([theEvent modifierFlags] & NSAlternateKeyMask) != 0) ||
		([[theEvent characters] isEqualToString: @"/"]  && ([theEvent modifierFlags] & NSControlKeyMask) != 0 && ([theEvent modifierFlags] & NSShiftKeyMask) == 0))
	{
		[self doNextBullet:self];
		return;
	}
	
	else if (([[theEvent characters] isEqualToString: g_commandCompletionChar] && ([theEvent modifierFlags] & NSControlKeyMask) != 0) ||
			 ([[theEvent characters] isEqualToString: @"/"]  && ([theEvent modifierFlags] & NSControlKeyMask) != 0 && ([theEvent modifierFlags] & NSShiftKeyMask) != 0))
	{
		[self doPreviousBullet:self];
		return;
	}
	
	else if ([[theEvent characters] isEqualToString: g_commandCompletionChar] &&
			 (([theEvent modifierFlags] & NSAlternateKeyMask) == 0) &&
			 ![self hasMarkedText] && g_commandCompletionList)
		
		//  if ([[theEvent characters] isEqualToString: g_commandCompletionChar] && (![self hasMarkedText]) && g_commandCompletionList)
	{
		textString = [self string]; // this will change during operations (such as undo)
		selectedLocation = [self selectedRange].location;
		// check for LaTeX \begin{...}
		if (selectedLocation > 0 && [textString characterAtIndex: selectedLocation-1] == '}'
			&& !latexSpecial)
		{
			charSet = [NSCharacterSet characterSetWithCharactersInString:
					   [NSString stringWithFormat: @"\n \t.,;;{}()%C", texChar]]; //should be global?
			foundRange = [textString rangeOfCharacterFromSet:charSet
													 options:NSBackwardsSearch range:NSMakeRange(0,selectedLocation-1)];
			if (foundRange.location != NSNotFound  &&  foundRange.location >= 6  &&
				[textString characterAtIndex: foundRange.location-6] == texChar  &&
				[[textString substringWithRange: NSMakeRange(foundRange.location-5, 6)]
				 isEqualToString: @"begin{"])
			{
				latexSpecial = YES;
				latexString = [textString substringWithRange:
							   NSMakeRange(foundRange.location, selectedLocation-foundRange.location)];
				if (wasCompleted)
					[currentString retain]; // extend life time
			}
		}
		else
			latexSpecial = NO;
		
		// if it was completed last time, revert to the uncompleted stage
		if (wasCompleted)
		{
			currentLength = (currentString)?[currentString length]:0;
			// make sure that it was really completed last time
			// check: insertion point, string before insertion point, undo title
			if ( selectedLocation == textLocation &&
				[textString length]>= replaceLocation+currentLength && // this shouldn't be necessary
				[[textString substringWithRange:
				  NSMakeRange(replaceLocation, currentLength)]
				 isEqualToString: currentString] &&
				[[[self undoManager] undoActionName] isEqualToString:
				 NSLocalizedString(@"Completion", @"Completion")])
			{
				// revert the completion:
				// by doing this, even after showing several completion candidates
				// you can get back to the uncompleted string by one undo.
				[[self undoManager] undo];
				selectedLocation = [self selectedRange].location;
				if (selectedLocation >= replaceLocation &&
					[[textString substringWithRange:
					  NSMakeRange(replaceLocation, selectedLocation-replaceLocation)]
					 isEqualToString: originalString]) // still checking
				{
					// this is supposed to happen
					if (completionListLocation == NSNotFound)
					{	// this happens if last one was LaTeX Special without previous completion
						[originalString release];
						[currentString release];
						wasCompleted = NO;
						[super keyDown: theEvent];
						return; // no other completion is possible
					}
				} else { // this shouldn't happen
					[[self undoManager] redo];
					selectedLocation = [self selectedRange].location;
					[originalString release];
					wasCompleted = NO;
				}
			} else { // probably there were other operations such as cut/paste/Macros which changed text
				[originalString release];
				wasCompleted = NO;
			}
			[currentString release];
		}
		
		if (!wasCompleted && !latexSpecial) {
			// determine the word to complete--search for word boundary
			charSet = [NSCharacterSet characterSetWithCharactersInString:
					   [NSString stringWithFormat: @"\n \t.,;;{}()%C", texChar]];
			foundRange = [textString rangeOfCharacterFromSet:charSet
													 options:NSBackwardsSearch range:NSMakeRange(0,selectedLocation)];
			if (foundRange.location != NSNotFound) {
				if (foundRange.location + 1 == selectedLocation)
				{ [super keyDown: theEvent];
					return;} // no string to match
				c = [textString characterAtIndex: foundRange.location];
				if (c == texChar || c == '{') // special characters
					replaceLocation = foundRange.location; // include these characters for search
				else
					replaceLocation = foundRange.location + 1;
			} else {
				if (selectedLocation == 0)
				{
					[super keyDown: theEvent];
					return; // no string to match
				}
				replaceLocation = 0; // start from the beginning
			}
			originalString = [textString substringWithRange:
							  NSMakeRange(replaceLocation, selectedLocation-replaceLocation)];
			[originalString retain];
			completionListLocation = 0;
		}
		
		// try to find a completion candidate
		if (!latexSpecial) { // ordinary case -- find from the list
			while (YES) { // look for a candidate which is not equal to originalString
				if ([theEvent modifierFlags] && wasCompleted) {
					// backward
					searchRange.location = 0;
					searchRange.length = completionListLocation-1;
				} else {
					// forward
					searchRange.location = completionListLocation;
					searchRange.length = [g_commandCompletionList length] - completionListLocation;
				}
				// search the string in the completion list
				foundRange = [g_commandCompletionList rangeOfString:
							  [@"\n" stringByAppendingString: originalString]
															options: ([theEvent modifierFlags]?NSBackwardsSearch:0)
															  range: searchRange];
				
				if (foundRange.location == NSNotFound) { // a completion candidate was not found
					foundCandidate = NO;
					break;
				} else { // found a completion candidate-- create replacement string
					foundCandidate = YES;
					// get the whole line
					foundRange.location ++; // eliminate first LF
					foundRange.length--;
					foundRange = [g_commandCompletionList lineRangeForRange: foundRange];
					foundRange.length--; // eliminate last LF
					foundString = [g_commandCompletionList substringWithRange: foundRange];
					completionListLocation = foundRange.location; // remember this location
					// check if there is ":="
					spaceRange = [foundString rangeOfString: @":="
													options: 0 range: NSMakeRange(0, [foundString length])];
					if (spaceRange.location != NSNotFound) {
						spaceRange.location += 2;
						spaceRange.length = [foundString length]-spaceRange.location;
						foundString = [foundString substringWithRange: spaceRange]; //string after first space
					}
					newString = [NSMutableString stringWithString: foundString];
					// replace #RET# by linefeed -- this could be tab -> \n
					[newString replaceOccurrencesOfString: @"#RET#" withString: @"\n"
												  options: 0 range: NSMakeRange(0, [newString length])];
					// search for #INS#
					insRange = [newString rangeOfString:@"#INS#" options:0];
					// Start Changed by (HS) - find second #INS#, remove if it's there and 
					// set selection length. NOTE: selectlength inited to 0 so ok if not found.
					//if (insRange.location != NSNotFound)
					//	[newString replaceCharactersInRange:insRange withString:@""];
					if (insRange.location != NSNotFound) {
						[newString replaceCharactersInRange:insRange withString:@""];
						ins2Range = [newString rangeOfString:@"#INS#" options:0];
						if (ins2Range.location != NSNotFound) {
						    [newString replaceCharactersInRange:ins2Range withString:@""];
						    selectlength = ins2Range.location - insRange.location;
						}
					}
					// End Changed by (HS) - find second #INS# if it's there and set selection length
					// Filtering for Japanese
					//if (shouldFilter == filterMacJ)//we use current encoding, so this isn't necessary
					//	newString = filterBackslashToYen(newString);
					if (![newString isEqualToString: originalString])
						break;		// continue search if newString is equal to originalString
				}
			}
		} else { // LaTeX Special -- just add \end and copy of {...}
			foundCandidate = YES;
			if (!wasCompleted) {
				originalString = [[NSString stringWithString: @""] retain];
				replaceLocation = selectedLocation;
				newString = [NSMutableString stringWithFormat: @"\n%Cend%@\n",
							 texChar, latexString];
				insRange.location = 0;
				completionListLocation = NSNotFound; // just to remember that it wasn't completed
			} else {
				// reuse the current string
				newString = [NSMutableString stringWithFormat: @"%@\n%Cend%@\n",
							 currentString, texChar, latexString];
				insRange.location = [currentString length];
				[currentString release];
			}
		}
		
		if (foundCandidate) { // found a completion candidate
			// replace the text
			replaceRange.location = replaceLocation;
			replaceRange.length = selectedLocation-replaceLocation;
			
			[self replaceCharactersInRange:replaceRange withString: newString];
			// register undo
			[self registerUndoWithString:originalString location:replaceLocation
								  length:[newString length]
									 key:NSLocalizedString(@"Completion", @"Completion")];
			//[self registerUndoWithString:originalString location:replaceLocation
			//		length:[newString length]
			//		key:NSLocalizedString(@"Completion", @"Completion")];
			// clean up
			[self resetBackgroundColor:nil];
			currentString = [newString retain];
			wasCompleted = YES;
			// flash the new string
			[self setSelectedRange: NSMakeRange(replaceLocation, [newString length])];
			[self display];
			NSDate *myDate = [NSDate date];
			while ([myDate timeIntervalSinceNow] > - 0.050) ;
			// set the insertion point
			if (insRange.location != NSNotFound) // position of #INS#
				textLocation = replaceLocation+insRange.location;
			else
				textLocation = replaceLocation+[newString length];
			// Start changed by (HS) - set selection length as well as insertion point
			// NOTE: selectlength inited to 0 so it's already correct if we get here
			//[self setSelectedRange: NSMakeRange(textLocation,0)];
			[self setSelectedRange: NSMakeRange(textLocation,selectlength)];
			[self scrollRangeToVisible: NSMakeRange(textLocation,selectlength)]; // Force into view (7/25/06) (HS)
			// End changed by (HS) - set selection length as well as insertion point
		}
		else // candidate was not found
		{
			[originalString release];
			originalString = currentString = nil;
			if (! wasCompleted)
				[super keyDown: theEvent];
			wasCompleted = NO;
			//NSLog(@"called super");
		}
		return;
	} else if (wasCompleted) { // we are not doing the completion
		[originalString release];
		[currentString release];
		originalString = currentString = nil;
		wasCompleted = NO;
		// return; //Herb Suggested Error Here		
	}
	
	[super keyDown: theEvent];
}
@end
