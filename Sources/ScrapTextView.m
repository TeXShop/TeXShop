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
 * $Id: TSTextView.m 261 2014-07-01 20:10:11Z richard_koch $
 *
 */

#import "ScrapTextView.h"
#import "globals.h"
#import "GlobalData.h"
#import <OgreKit/OgreKit.h>
#import "TSEncodingSupport.h"

@implementation ScrapTextView

- (void)awakeFromNib
{
/*
    if ([self respondsToSelector:@selector(setMathExpressionCompletionType:)])
    {   if ([SUD integerForKey:MathExpressionCompletionKey] == 0)
            [self setMathExpressionCompletionType: NSTextInputTraitTypeNo];
    }
 */
    
    if (atLeastSequoia)
    {
        if (([self respondsToSelector:@selector(setMathExpressionCompletionType:)]) &&
                    ([SUD integerForKey:MathExpressionCompletionKey] == 0))
                    
                {
                    if (@available(macOS 15.0, *))
                        [self setMathExpressionCompletionType: NSTextInputTraitTypeNo];
                }
        
        else if (([self respondsToSelector:@selector(setMathExpressionCompletionType:)]) &&
                 ([SUD integerForKey:MathExpressionCompletionKey] == 1))
                 
             {
                 if (@available(macOS 15.0, *))
                     [self setMathExpressionCompletionType: NSTextInputTraitTypeYes];
             }
     
       else if (([self respondsToSelector:@selector(setMathExpressionCompletionType:)]) &&
              ([SUD integerForKey:MathExpressionCompletionKey] == 2))
              
          {
              if (@available(macOS 15.0, *))
                  [self setMathExpressionCompletionType: NSTextInputTraitTypeDefault];
          }
    }

}

- (id)initWithFrame:(NSRect)frameRect
{

    latexSpecial = NO;
    wasCompleted = NO; // was completed on last keyDown
    replaceLocation = NSNotFound; // completion started here
	completionListLocation = 0; // location to start search in the list
	textLocation = NSNotFound; // location of insertion point

    
    return self;
}


- (void)undoSpecial:(id)theDictionary
{
	NSRange		undoRange;
	NSString	*oldString, *newString, *undoKey;
	NSUInteger	from, to;
    
	// Retrieve undo info
	undoRange.location = [[theDictionary objectForKey: @"oldLocation"] unsignedIntegerValue];
	undoRange.length = [[theDictionary objectForKey: @"oldLength"] unsignedIntegerValue];
	newString = [theDictionary objectForKey: @"oldString"];
	undoKey = [theDictionary objectForKey: @"undoKey"];
    
	if (undoRange.location+undoRange.length > [[self string] length])
		return; // something wrong happened
    
	oldString = [[self string] substringWithRange: undoRange];
    
	// Replace the text
	[self replaceCharactersInRange:undoRange withString:newString];
	[self registerUndoWithString:oldString location:undoRange.location
                          length:[newString length] key:undoKey];
    
	from = undoRange.location;
	to = from + [newString length];
//	[self fixColor:from :to];
//	[self setupTags];
}




// NSString *placeholderString = @"•", *startcommentString = @"•‹", *endcommentString = @"›";




- (void)mouseDown:(NSEvent *)theEvent
{
	if ([theEvent modifierFlags] & NSAlternateKeyMask)
		_alternateDown = YES;
	else
		_alternateDown = NO;
	[super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	_alternateDown = NO;
	[super mouseUp:theEvent];
}



- (void)registerUndoWithString:(NSString *)oldString location:(NSUInteger)oldLocation
                        length: (NSUInteger)newLength key:(NSString *)key
{
	NSUndoManager	*myManager;
	NSMutableDictionary	*myDictionary;
	NSNumber		*theLocation, *theLength;
    
	// Create & register an undo action
	myManager = [self undoManager];
	myDictionary = [NSMutableDictionary dictionaryWithCapacity: 4];
	theLocation = [NSNumber numberWithUnsignedInteger:oldLocation];
	theLength = [NSNumber numberWithUnsignedInteger:newLength];
	[myDictionary setObject: oldString forKey: @"oldString"];
	[myDictionary setObject: theLocation forKey: @"oldLocation"];
	[myDictionary setObject: theLength forKey: @"oldLength"];
	[myDictionary setObject: key forKey: @"undoKey"];
	[myManager registerUndoWithTarget:self selector:@selector(undoSpecial:) object: myDictionary];
	[myManager setActionName:key];
}


// to be used in AutoCompletion
- (void)insertSpecialNonStandard:(NSString *)theString undoKey:(NSString *)key
{
	NSRange		oldRange, searchRange;
	NSMutableString	*stringBuf;
	NSString *oldString, *newString;
	NSUInteger from, to;
    
	// mutably copy the replacement text
	stringBuf = [NSMutableString stringWithString: theString];
    
	// Determine the curent selection range and text
	oldRange = [self selectedRange];
	oldString = [[self string] substringWithRange: oldRange];
    
	// Substitute all occurances of #SEL# with the original text
	[stringBuf replaceOccurrencesOfString: @"#SEL#" withString: oldString
                                  options: 0 range: NSMakeRange(0, [stringBuf length])];
    
	// Now search for #INS#, remember its position, and remove it. We will
	// Later position the insertion mark there. Defaults to end of string.
	searchRange = [stringBuf rangeOfString:@"#INS#" options:NSLiteralSearch];
	if (searchRange.location != NSNotFound)
		[stringBuf replaceCharactersInRange:searchRange withString:@""];
    
	// Filtering for Japanese
	newString = [self.document filterBackslashes:stringBuf];
    
	// Insert the new text
	[self replaceCharactersInRange:oldRange withString:newString];
    
	// register undo
	[self registerUndoWithString:oldString location:oldRange.location
                          length:[newString length] key:key];
	//[textView registerUndoWithString:oldString location:oldRange.location
	//					length:[newString length] key:key];
    
	from = oldRange.location;
	to = from + [newString length];
    
	// Place insertion mark
	if (searchRange.location != NSNotFound) {
		searchRange.location += oldRange.location;
		searchRange.length = 0;
		[self setSelectedRange:searchRange];
	}
}


// New version by David Reitter selects beginning backslash with words as in "\int"
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
{
	NSRange	replacementRange = { 0, 0 };
	NSString	*textString;
	NSInteger		length, i, j;
	BOOL	done;
	NSInteger		leftpar, rightpar, nestingLevel, uchar;
    
	textString = [self string];
	if (textString == nil)
		return replacementRange;
    
	replacementRange = [super selectionRangeForProposedRange: proposedSelRange granularity: granularity];
    
	// Extend word selection to cover an initial backslash (TeX command)
	if (granularity == NSSelectByWord)
	{
        // added by Terada (from this line)
        BOOL flag;
        unichar c;
        
        
        if(replacementRange.location < [textString length]){
            c = [textString characterAtIndex:replacementRange.location];
            if((c != '{') && (c != '(') && (c != '[') && (c != '<') && (c != ' ')){  // Koch, July 19, 2013, double click on space selects space
                do {
                    if (replacementRange.location >= 1){
                        c = [textString characterAtIndex: replacementRange.location-1];
                     //   if (((c >= 'A') && (c <= 'Z')) || ((c >= 'a') && (c <= 'z')) || (c == '@' && [SUD boolForKey:MakeatletterEnabledKey])){
                        // Terada, 2/5/2024
                        //    if (((c >= 'A') && (c <= 'Z')) || ((c >= 'a') && (c <= 'z')) || (c == '@' && [SUD boolForKey:MakeatletterEnabledKey])
                        //         || (((c == '@') || (c == '_') || (c == ':')) && [SUD boolForKey:expl3SyntaxColoringKey]) ){
                        if (((c >= 'A') && (c <= 'Z')) || ((c >= 'a') && (c <= 'z')) || (c == '@' && [SUD boolForKey:MakeatletterEnabledKey])
                             || (((c == '@') || (c == '_') || (c == ':')) && self.document.useExplColor) ){
                            
                            replacementRange.location--;
                            replacementRange.length++;
                            flag = YES;
                        }else{
                            flag = NO;
                        }
                    }else{
                        flag = NO;
                    }
                } while (flag);
                
                do {
                    if (replacementRange.location + replacementRange.length  < [textString length]){
                        c = [textString characterAtIndex: replacementRange.location + replacementRange.length];
                        
                   //     if (((c >= 'A') && (c <= 'Z')) || ((c >= 'a') && (c <= 'z')) || (c == '@' && [SUD boolForKey:MakeatletterEnabledKey])){
                    // Terada, 2/5/2024
                    //    if (((c >= 'A') && (c <= 'Z')) || ((c >= 'a') && (c <= 'z')) || (c == '@' && [SUD boolForKey:MakeatletterEnabledKey])
                    //         || (((c == '@') || (c == '_') || (c == ':')) && [SUD boolForKey:expl3SyntaxColoringKey]) ){
                        if (((c >= 'A') && (c <= 'Z')) || ((c >= 'a') && (c <= 'z')) || (c == '@' && [SUD boolForKey:MakeatletterEnabledKey])
                             || (((c == '@') || (c == '_') || (c == ':')) && self.document.useExplColor) ){
                            
                            replacementRange.length++;
                            flag = YES;
                        }else{
                            flag = NO;
                        }
                    }else{
                        flag = NO;
                    }
                } while (flag);
            }
        }
		
        // added by Terada (until this line)
		
        if (replacementRange.location >= 1 && [textString characterAtIndex: replacementRange.location-1] == BACKSLASH)
		{
			replacementRange.location--;
			replacementRange.length++;
			return replacementRange;
		}
	}
    
	if ((proposedSelRange.length != 0) || (granularity != NSSelectByWord))
        return replacementRange;
	
	if (_alternateDown)
		return replacementRange;
    
	length = [textString length];
	i = proposedSelRange.location;
	if (i >= length)
		return replacementRange;
	uchar = [textString characterAtIndex: i];
    
	// If the users double clicks an opening or closing parenthesis / bracket / brace,
	// then the following code will extend the selection to the matching opposite
	// parenthesis / bracket / brace.
    
    
	if ((uchar == '}') || (uchar == ')') || (uchar == ']') || (uchar == '>')) { // modified by Terada
		j = i;
		rightpar = uchar;
		if (rightpar == '}')
			leftpar = '{';
		else if (rightpar == ')')
			leftpar = '(';
		else if (rightpar == '>') // added by Terada
			leftpar = '<'; // added by Terada
		else
			leftpar = '[';
		nestingLevel = 1;
		done = NO;
		// Try searching to the left to find a match...
		while ((i > 0) && (! done)) {
			i--;
			uchar = [textString characterAtIndex:i];
			if (uchar == rightpar)
				nestingLevel++;
			else if (uchar == leftpar)
				nestingLevel--;
			if (nestingLevel == 0) {
				done = YES;
				replacementRange.location = i;
				replacementRange.length = j - i + 1;
			}
		}
	}
	else if ((uchar == '{') || (uchar == '(') || (uchar == '[') ||  (uchar == '<') ) { // modified by Terada
		j = i;
		leftpar = uchar;
		if (leftpar == '{')
			rightpar = '}';
		else if (leftpar == '(')
			rightpar = ')';
		else if (leftpar == '<') // added by Terada
			rightpar = '>'; // added by Terada
		else
			rightpar = ']';
		nestingLevel = 1;
		done = NO;
		while ((i < (length - 1)) && (! done)) {
			i++;
			uchar = [textString characterAtIndex:i];
			if (uchar == leftpar)
				nestingLevel++;
			else if (uchar == rightpar)
				nestingLevel--;
			if (nestingLevel == 0) {
				done = YES;
				replacementRange.location = j;
				replacementRange.length = i - j + 1;
			}
		}
	}
    
	return replacementRange;
}



// added by mitsu --(A) g_texChar filtering
- (void)insertText:(id)aString
{
    
// The following is an Emoji Palette fix by Yusuke Terada
    if (![aString isKindOfClass:[NSString class]]) {
        [super insertText:aString];
        return;
    }
// End of Fix
    
	// AutoCompletion
	// Code added by Greg Landweber for auto-completions of '^', '_', etc.
	// First, avoid completing \^, \_, \"
	if ([(NSString *)aString length] == 1 &&  [self.document isDoAutoCompleteEnabled]) {
		if ([aString characterAtIndex:0] >= 128 ||
			[self selectedRange].location == 0 ||
			[[self string] characterAtIndex:[self selectedRange].location - 1 ] != g_texChar )
		{
			NSString *completionString = [[GlobalData sharedGlobalData].g_autocompletionDictionary objectForKey:aString];
			if ( completionString &&
				(!g_shouldFilter || [aString characterAtIndex:0] != YEN)) // avoid completing yen
			{
				[self.document setAutoCompleting:YES]; // added by Terada
				[self insertSpecialNonStandard:completionString
                                                undoKey: NSLocalizedString(@"Autocompletion", @"Autocompletion")];
				[self.document setAutoCompleting:NO]; // added by Terada
				return;
			}
		}
	}
	// End of code added by Greg Landweber

	NSString *newString = aString;
    
	// Filtering for Japanese
	if (g_shouldFilter == kMacJapaneseFilterMode) {
		newString = filterBackslashToYen(newString);
	} else if (g_shouldFilter == kOtherJapaneseFilterMode) {
		newString = filterYenToBackslash(newString);
	}
    
	// zenitani 1.35 (A) -- normalizing newline character for regular expression
	if ([SUD boolForKey:ConvertLFKey]) {
		newString = [OGRegularExpression replaceNewlineCharactersInString:newString
                                                            withCharacter:OgreLfNewlineCharacter];
	}
    
	[super insertText: newString];
}


- (void)keyDown:(NSEvent *)theEvent
{
	
	// FIXME: Using static variables like this is *EVIL*
	// It will simply not work correctly when using more than one window/view (which we frequently do)!
	// TODO: Convert all of these static stack variables to member variables.
	
	// static BOOL wasCompleted = NO; // was completed on last keyDown
	// static BOOL latexSpecial = NO; // was last time LaTeX Special?  \begin{...}
	// static NSString *originalString = nil; // string before completion, starts at replaceLocation
	// static NSString *currentString = nil; // completed string
	// static NSUInteger replaceLocation = NSNotFound; // completion started here
	// static NSUInteger completionListLocation = 0; // location to start search in the list
	// static NSUInteger textLocation = NSNotFound; // location of insertion point
	BOOL foundCandidate;
	NSString *textString, *foundString, *latexString = 0;
	NSMutableString *indentString = [NSMutableString stringWithString:@""]; // Alvise Trevisan; preserve tabs code
	NSMutableString *newString;
	NSUInteger selectedLocation, currentLength, from, to;
	NSRange foundRange, searchRange, spaceRange, insRange, replaceRange;
	// Start Changed by (HS) - define ins2Range, selectlength
	NSRange ins2Range;
	NSUInteger selectlength = 0;
	NSMutableString *indentRETString = [NSMutableString stringWithString:@"\n"]; // **** 2011/03/05 preserve proper indent (HS) **** Copied from Alvise Trevisan; preserve tabs code
	// End Changed by (HS) - define ins2Range, selectlength,
	NSCharacterSet *charSet;
	unichar c;
    
    unichar tab = 0x0009; // ditto
    NSString *g_commandCompletionCharTab;
    
    g_commandCompletionCharTab = [NSString stringWithCharacters: &tab length: 1];
	
	if ([[theEvent characters] isEqualToString: g_commandCompletionCharTab] &&
		( ! [[SUD stringForKey: CommandCompletionAlternateMarkShortcutKey] isEqualToString:@"NO"] ) &&
		(([theEvent modifierFlags] & NSAlternateKeyMask) != 0))
        
    {
        [self doNextBullet:self];
        return;
    }
    
	else if ([[theEvent characters] isEqualToString: g_commandCompletionCharTab] &&
             ( ! [[SUD stringForKey: CommandCompletionAlternateMarkShortcutKey] isEqualToString:@"NO"] ) &&
             (([theEvent modifierFlags] & NSControlKeyMask) != 0))
    {
        [self doPreviousBullet:self];
        return;
    }
    
	else if ([[theEvent characters] isEqualToString: g_commandCompletionCharTab] &&
             (([theEvent modifierFlags] & NSAlternateKeyMask) == 0) &&
             ![self hasMarkedText] && g_commandCompletionList)
        
        //  if ([[theEvent characters] isEqualToString: g_commandCompletionCharTab] && (![self hasMarkedText]) && g_commandCompletionList)
	{
        textString = [self string]; // this will change during operations (such as undo)
		selectedLocation = [self selectedRange].location;
		// check for LaTeX \begin{...}
		if (selectedLocation > 0 && [textString characterAtIndex: selectedLocation-1] == '}'
            && !latexSpecial)
		{
			charSet = [NSCharacterSet characterSetWithCharactersInString:
                       [NSString stringWithFormat: @"\n \t.,:;{}()%C", (unichar)g_texChar]]; //should be global?
			foundRange = [textString rangeOfCharacterFromSet:charSet
                                                     options:NSBackwardsSearch range:NSMakeRange(0,selectedLocation-1)];
			if (foundRange.location != NSNotFound  &&  foundRange.location >= 6  &&
				[textString characterAtIndex: foundRange.location-6] == g_texChar  &&
				[[textString substringWithRange: NSMakeRange(foundRange.location-5, 6)]
                 isEqualToString: @"begin{"])
			{
				latexSpecial = YES;
				latexString = [textString substringWithRange:
                               NSMakeRange(foundRange.location, selectedLocation-foundRange.location)];
				
				// Alvise Trevisan; preserve tabs code (begin addition)
				NSInteger indentSpace;
				NSInteger indentTab = [self.document textViewCountTabs:self andSpaces: &indentSpace];
				NSInteger n;
				
				for (n = 0; n < indentTab; ++ n)
					[indentString appendString:@"\t"];
				for (n = 0; n < indentSpace; ++ n)
					[indentString appendString:@" "];
				// Alvise Trevisan; preserve tabs code (end addition)
				
				// if (wasCompleted)
                //[self.currentString retain]; // extend life time
			}
		}
		else
            latexSpecial = NO;
        
		// if it was completed last time, revert to the uncompleted stage
		if (wasCompleted)
		{
 			currentLength = (self.currentString)?[self.currentString length]:0;
			// make sure that it was really completed last time
			// check: insertion point, string before insertion point, undo title
			if ( selectedLocation == textLocation &&
				[textString length]>= replaceLocation+currentLength && // this shouldn't be necessary
				[[textString substringWithRange:
                  NSMakeRange(replaceLocation, currentLength)]
                 isEqualToString: self.currentString] &&
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
                     isEqualToString: self.originalString]) // still checking
				{
					// this is supposed to happen
					if (completionListLocation == NSNotFound)
					{	// this happens if last one was LaTeX Special without previous completion
						// [self.originalString release];
						// [self.currentString release];
						wasCompleted = NO;
						[super keyDown: theEvent];
						return; // no other completion is possible
					}
				} else { // this shouldn't happen
					[[self undoManager] redo];
					selectedLocation = [self selectedRange].location;
					// [self.originalString release];
					wasCompleted = NO;
				}
			} else { // probably there were other operations such as cut/paste/Macros which changed text
				// [self.originalString release];
				wasCompleted = NO;
			}
			// [self.currentString release];
		}
        
		if (!wasCompleted && !latexSpecial) {
			// determine the word to complete--search for word boundary
			charSet = [NSCharacterSet characterSetWithCharactersInString:
                       [NSString stringWithFormat: @"\n \t.,:;{}()%C", (unichar)g_texChar]];
			foundRange = [textString rangeOfCharacterFromSet:charSet
                                                     options:NSBackwardsSearch range:NSMakeRange(0,selectedLocation)];
			if (foundRange.location != NSNotFound) {
				if (foundRange.location + 1 == selectedLocation)
				{ [super keyDown: theEvent];
					return;} // no string to match
				c = [textString characterAtIndex: foundRange.location];
				if (c == g_texChar || c == '{') // special characters
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
			self.originalString = [textString substringWithRange:
                                   NSMakeRange(replaceLocation, selectedLocation-replaceLocation)];
			// [self.originalString retain];
			completionListLocation = 0;
		}
        
		// try to find a completion candidate
		if (!latexSpecial) { // ordinary case -- find from the list
			while (YES) { // look for a candidate which is not equal to originalString
                // (HS) modification to reverse search 2014/05/11
                /* original code
                 if (([theEvent modifierFlags] & NSShiftKeyMask) && wasCompleted) {
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
                 [@"\n" stringByAppendingString: self.originalString]
                 options: (([theEvent modifierFlags] & NSShiftKeyMask)?NSBackwardsSearch:0)
                 range: searchRange];
                 */
                if (!([theEvent modifierFlags] & NSShiftKeyMask) && wasCompleted) {
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
                              [@"\n" stringByAppendingString: self.originalString]
                                                            options: (!(([theEvent modifierFlags] & NSShiftKeyMask))?NSBackwardsSearch:0)
                                                              range: searchRange];
                // End of modification to reverse search
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
					// **** 2011/03/05 preserve proper indent (HS) **** Copied from Alvise Trevisan; preserve tabs code
					NSInteger indentSpace;
					NSInteger indentTab = [self.document textViewCountTabs:self andSpaces: &indentSpace];
					NSInteger n;
					for (n = 0; n < indentTab; ++ n)
					    [indentRETString appendString:@"\t"];
					for (n = 0; n < indentSpace; ++ n)
					    [indentRETString appendString:@" "];
					[newString replaceOccurrencesOfString: @"#RET#" withString: indentRETString
                                                  options: 0 range: NSMakeRange(0, [newString length])];
					//[newString replaceOccurrencesOfString: @"#RET#" withString: @"\n"
					//			  options: 0 range: NSMakeRange(0, [newString length])];
					// **** 2011/03/05 preserve proper indent (HS) **** Copied from Alvise Trevisan; preserve tabs code
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
					if (![newString isEqualToString: self.originalString])
						break;		// continue search if newString is equal to self.originalString
				}
			}
		} else { // LaTeX Special -- just add \end and copy of {...}
			foundCandidate = YES;
			if (!wasCompleted) {
				self.originalString = @"" ;
				replaceLocation = selectedLocation;
				// newString = [NSMutableString stringWithFormat: @"\n%Cend%@\n",
				//					g_texChar, latexString];
				newString = [NSMutableString stringWithFormat: @"\n%@%Cend%@\n",
                             indentString, (unichar)g_texChar, latexString]; // Alvise Trevisan; preserve tabs code (revision of previous lines)
				insRange.location = 0;
				completionListLocation = NSNotFound; // just to remember that it wasn't completed
			} else {
				// reuse the current string
				// newString = [NSMutableString stringWithFormat: @"%@\n%Cend%@\n",
				//					currentString, g_texChar, latexString];
				newString = [NSMutableString stringWithFormat: @"%@\n%@%Cend%@\n",
                             self.currentString, indentString, (unichar)g_texChar, latexString];  // Alvise Trevisan; preserve tabs code (revision of previous lines)
				insRange.location = [self.currentString length];
				// [self.currentString release];
			}
		}
        
		if (foundCandidate) { // found a completion candidate
			// replace the text
			replaceRange.location = replaceLocation;
			replaceRange.length = selectedLocation-replaceLocation;
            
			[self replaceCharactersInRange:replaceRange withString: newString];
			// register undo
            
            
		//	if (self.document)
				[self /*self.document*/ registerUndoWithString:self.originalString location:replaceLocation
                                               length:[newString length]
                                                  key:NSLocalizedString(@"Completion", @"Completion")];
			//[self registerUndoWithString:self.originalString location:replaceLocation
			//		length:[newString length]
			//		key:NSLocalizedString(@"Completion", @"Completion")];
			// clean up
		//	if (self.document)
                {
				from = replaceLocation;
				to = from + [newString length];
				// [self.document fixColor:from :to];
				// [self.document setupTags];
			}
            
            
			self.currentString = newString;
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
			self.originalString;
			self.originalString = self.currentString = nil;
			if (! wasCompleted)
				[super keyDown: theEvent];
			wasCompleted = NO;
			//NSLog(@"called super");
		}
		return;
	} else if (wasCompleted) { // we are not doing the completion
		// [self.originalString release];
		// [self.currentString release];
		self.originalString = self.currentString = nil;
		wasCompleted = NO;
		// return; //Herb Suggested Error Here		
	}
    
	[super keyDown: theEvent];
}


- (void) doNextBullet: (id)sender // modified by (HS)
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

- (void) doPreviousBullet: (id)sender // modified by (HS)
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

- (void) doNextBulletAndDelete: (id)sender // modified by (HS)
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
        // delete bullet (marker)
        tempRange.location = markerRange.location;
        tempRange.length = [placeholderString length];
        markerRange.length -= tempRange.length; // deleting the bullet so selection is shorter
        [self replaceCharactersInRange:tempRange withString:@""];
        // end delete bullet (marker)
        [self setSelectedRange:markerRange];
        [self scrollRangeToVisible:markerRange];
    }
    else NSBeep();
    //NSLog(@"Next • hit");
}

- (void) doPreviousBulletAndDelete: (id)sender // modified by (HS)
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
        // delete bullet (marker)
        tempRange.location = markerRange.location;
        tempRange.length = [placeholderString length];
        markerRange.length -= tempRange.length; // deleting the bullet so selection is shorter
        [self replaceCharactersInRange:tempRange withString:@""];
        // end delete bullet (marker)
        [self setSelectedRange:markerRange];
        [self scrollRangeToVisible:markerRange];
    }
    else NSBeep();
    //NSLog(@"Next • hit");
}

- (void) placeBullet: (id)sender // modified by (HS) to be a simple insertion (replacing the selection)
{
    NSRange		myRange;
    
    //  text = [self string];
    myRange = [self selectedRange];
    [self replaceCharactersInRange:myRange withString:placeholderString];//" •\n" puts • on previous line
    myRange.location += [placeholderString length];//= end+2;//start puts • on previous line
    myRange.length = 0;
    [self setSelectedRange: myRange];
    //NSLog(@"Place • hit");
}

- (void) placeComment: (id)sender // by (HS) to be a simple insertion (replacing the selection)
{
    NSRange		myRange;
    
    //   text = [textView string];
    myRange = [self selectedRange];
    [self replaceCharactersInRange:myRange withString:startcommentString];//" •\n" puts • on previous line
    myRange.location += [startcommentString length];//= end+2;//start puts • on previous line
    myRange.length = 0;
    [self replaceCharactersInRange:myRange withString:endcommentString];
    [self setSelectedRange: myRange];
    //NSLog(@"Place • hit");
}

// end BULLET (H. Neary) (modified by (HS))


 
@end

