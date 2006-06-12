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
 * $Id: TSTextView.m 197 2006-05-29 21:19:33Z fingolfin $
 *
 */

#import "TSTextView.h"

// added by mitsu --(A) g_texChar filtering
#import "TSEncodingSupport.h"
#import "globals.h"
#import "TSDocument.h" // mitsu 1.29 (T2-4)
#import "TSWindowManager.h" // mitsu 1.29 (T2)
#import "TSEncodingSupport.h"
#import "TSPreferences.h"
#import "TSMacroMenuController.h" // zenitani 1.33
#import <OgreKit/OgreKit.h>


// end addition

@implementation TSTextView

#pragma mark =====pdfSync=====
- (void)doSync:(NSEvent *)theEvent
{
	int             line;
	NSString        *text;
	BOOL            found;
	unsigned        start, end, irrelevant, stringlength, theIndex;
	NSRange         myRange;
	NSPoint         screenPosition;
	NSString        *theSource;

	// find the line number
	screenPosition = [NSEvent  mouseLocation];
	theIndex = [self characterIndexForPoint: screenPosition];
	[_document setCharacterIndex: theIndex];
	text = [[_document textView] string];
	stringlength = [text length];
	myRange.location = 0;
	myRange.length = 1;
	line = 0;
	found = NO;
	while ((! found) && (myRange.location < stringlength)) {
		[text getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
		if (end >= theIndex)
			found = YES;
		myRange.location = end;
		line++;
	}
	if (!found)
		return;
	[_document setPdfSyncLine:line];

	// see if there is a root file; if so, call the root file's doPreviewSync
	// code with the filename of this file and this line number
	// see if there is a %SourceDoc file; if so, call the root file's doPreviewSync
	// code with the filename of this file and this line number
	// otherwise call this document's doPreviewSync with nil for filename and
	// this line number

	 theSource = [[_document textView] string];
	 if (theSource == nil)
		return;
	 if ([_document checkMasterFile:theSource forTask:RootForPdfSync])
			return;
	 if ([_document checkRootFile_forTask:RootForPdfSync])
			return;

	 [_document doPreviewSyncWithFilename:nil andLine:line andCharacterIndex: theIndex andTextView: [_document textView]];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSMutableDictionary	*mySelectedTextAttributes;

	if ([theEvent modifierFlags] & NSAlternateKeyMask)
		_alternateDown = YES;
	else
		_alternateDown = NO;
	
	// koch; Dec 13, 2003
	
	// Trigger PDF sync when a click occurs while cmd is pressed (and alt is not pressed).
	if (!([theEvent modifierFlags] & NSAlternateKeyMask) && ([theEvent modifierFlags] & NSCommandKeyMask)) {
		[self doSync: theEvent];
		return;
	}

	// Reset the special 'yellow' selection (which is used by PDF sync).
	if ([_document textSelectionYellow]) {
		[_document setTextSelectionYellow: NO];
		mySelectedTextAttributes = [NSMutableDictionary dictionaryWithDictionary: [[_document textView] selectedTextAttributes]];
		[mySelectedTextAttributes setObject:[NSColor colorWithCatalogName: @"System" colorName: @"selectedTextBackgroundColor"]  forKey:@"NSBackgroundColor"];
		[[_document textView] setSelectedTextAttributes: mySelectedTextAttributes];
	}
	[super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	_alternateDown = NO;
	[super mouseUp:theEvent];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	// return YES;
	return [SUD boolForKey:AcceptFirstMouseKey];
}

#pragma mark =====others=====

// drag & drop support --- added by zenitani, Feb 13, 2003
- (unsigned int) dragOperationForDraggingInfo : (id <NSDraggingInfo>) sender
{
	NSPasteboard *pb = [sender draggingPasteboard];
	NSString *type = [pb availableTypeFromArray:
		[NSArray arrayWithObjects: NSStringPboardType, NSFilenamesPboardType, nil] ];
	if( type && [_document fileIsTex] ) {
		if( [type isEqualToString:NSStringPboardType] ||
			[type isEqualToString:NSFilenamesPboardType] ){
			NSPoint location = [self convertPoint:[sender draggingLocation] fromView:nil];
			NSLayoutManager *layoutManager = [self layoutManager];
			NSTextContainer *textContainer = [self textContainer];
			float tmp;
			int glyphIndex = [layoutManager glyphIndexForPoint:location
				inTextContainer:textContainer fractionOfDistanceThroughGlyph:&tmp];
			int characterIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
			NSRange selRange = [self selectedRange];
			// moves cursor's position if necessary
			if(( selRange.location != characterIndex ) || ( selRange.length != 0 )){
				[self setSelectedRange: NSMakeRange( characterIndex, 0 ) ];
			}
			return NSDragOperationGeneric;
		}
	}
	return NSDragOperationNone;
}

- (unsigned int) draggingEntered : (id <NSDraggingInfo>) sender
{
	return [self dragOperationForDraggingInfo:sender];
}
- (unsigned int) draggingUpdated : (id <NSDraggingInfo>) sender
{
	return [self dragOperationForDraggingInfo:sender];
}

- (void) draggingExited : (id <NSDraggingInfo>) sender
{
	return;
}

- (BOOL) prepareForDragOperation : (id <NSDraggingInfo>) sender
{
	return YES;
}
- (BOOL) performDragOperation : (id <NSDraggingInfo>) sender
{
   // return YES;    this fix, by Koch on May 1, 2005, seems required in Tiger when dragging text from one spot to another
   return [super performDragOperation: sender];
}


// zenitani 1.33 begin
- (void) concludeDragOperation : (id <NSDraggingInfo>) sender {

	NSPasteboard *pb = [ sender draggingPasteboard ];
	NSString *type = [ pb availableTypeFromArray:
		[NSArray arrayWithObjects: NSStringPboardType, NSFilenamesPboardType, nil]];

	if ([type isEqualToString:NSFilenamesPboardType]) {
		NSArray *ar = [pb propertyListForType:NSFilenamesPboardType];
		unsigned cnt = [ar count];
		if (cnt == 0)
			return;
		NSString *thisFile = [_document fileName];
		unsigned i;
		for (i = 0; i < cnt; i++) {
			// NSString *filePath = [ar objectAtIndex:i];
			NSString *tempPath = [ar objectAtIndex:i];
			NSString *filePath = [self resolveAlias:tempPath];
			NSString *fileName = [filePath lastPathComponent];
			NSString *baseName = [fileName stringByDeletingPathExtension];
			NSString *fileExt  = [[fileName pathExtension] lowercaseString];
			NSString *relPath  = [[TSPreferences sharedInstance] relativePath: filePath fromFile: thisFile ];
			NSString *insertString;
			NSMutableString *tmpString;

			// zenitani 1.33(2) begin
			// If the dropped file is a PDF, pass it on to readSourceFromEquationEditorPDF.
			NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
			if ([fileExt isEqualToString: @"pdf"] &&
				((sourceDragMask & NSDragOperationLink) || (sourceDragMask & NSDragOperationGeneric)) ){
				insertString = [self readSourceFromEquationEditorPDF: filePath];
				if (insertString != nil) {
					[_document insertSpecial: insertString
														undoKey: NSLocalizedString(@"Drag && Drop", @"Drag && Drop")];
					return;
				}
			}
			// zenitani 1.33(2) end

			// zenitani 1.33(0)
			NSRange myRange = [filePath rangeOfString: @" " options: NSLiteralSearch];
			if( myRange.location != NSNotFound ){
				NSBeginAlertSheet(@"Do not use spaces in file names.",
									nil,nil,nil,[self window],nil,nil,nil,nil,
									@"Path Name: %@",filePath);
									return;
			}

			insertString = [self getDragnDropMacroString: fileExt];

			// Koch fix for missing methods
			if ( insertString == nil ) {
				if ( [fileExt  isEqualToString: @"cls"] ) insertString = @"\\documentclass{%n}\n";
				else if ( [fileExt  isEqualToString: @"sty"] ) insertString = @"\\usepackage{%n}\n";
				else if ( [fileExt  isEqualToString: @"bib"] ) insertString = @"\\bibliography{%n}\n";
				else if ( [fileExt  isEqualToString: @"bst"] ) insertString = @"\\bibliographystyle{%n}\n";
				else if (( [fileExt  isEqualToString: @"pdf"] ) ||
						( [fileExt isEqualToString: @"jpeg"] ) || ( [fileExt isEqualToString: @"jpg"] ) ||
						( [fileExt isEqualToString: @"tiff"] ) || ( [fileExt isEqualToString: @"tif"] ) ||
						( [fileExt isEqualToString: @"eps"] ) || ( [fileExt isEqualToString: @"ps"] ))
							insertString = @"\\includegraphics[]{%r}\n";
				}
			// end of Koch fix

			if( insertString == nil )    insertString = [self getDragnDropMacroString: @"*"];
			if( insertString == nil )    insertString = @"\\input{%r}\n";

			tmpString = [NSMutableString stringWithString: insertString];
			[tmpString replaceOccurrencesOfString: @"%F" withString: filePath options: 0 range: NSMakeRange(0, [tmpString length])];
			[tmpString replaceOccurrencesOfString: @"%f" withString: fileName options: 0 range: NSMakeRange(0, [tmpString length])];
			[tmpString replaceOccurrencesOfString: @"%n" withString: baseName options: 0 range: NSMakeRange(0, [tmpString length])];
			[tmpString replaceOccurrencesOfString: @"%e" withString: fileExt options: 0 range: NSMakeRange(0, [tmpString length])];
			[tmpString replaceOccurrencesOfString: @"%r" withString: relPath options: 0 range: NSMakeRange(0, [tmpString length])];
			[_document insertSpecial: tmpString
						undoKey: NSLocalizedString(@"Drag && Drop", @"Drag && Drop")];
//            [[TSMacroMenuController sharedInstance] doMacro: tmpString];
//            [self insertText:tmpString];
			return;
		}
		[self display];
	} else {
		[super concludeDragOperation:sender];
	}
}

/* Koch: this method comes from ADC Reference Library/Cocoa/LowLevelFileManagement */
- (NSString *)resolveAlias: (NSString *)path
{
	NSString *resolvedPath = nil;
	CFURLRef url;

	url = CFURLCreateWithFileSystemPath(NULL /*allocator*/, (CFStringRef)path,
						 kCFURLPOSIXPathStyle, NO /*isDirectory*/);
	if(url != NULL) {
		FSRef fsRef;
		if(CFURLGetFSRef(url, &fsRef)) {
			Boolean targetIsFolder, wasAliased;
			if (FSResolveAliasFile (&fsRef, true /*resolveAliasChains*/,
				&targetIsFolder, &wasAliased) == noErr && wasAliased) {
					CFURLRef resolvedUrl = CFURLCreateFromFSRef(NULL, &fsRef);
					if(resolvedUrl != NULL) {
						resolvedPath = (NSString*)CFURLCopyFileSystemPath(resolvedUrl, kCFURLPOSIXPathStyle);
						CFRelease(resolvedUrl);
						}
					}
				}
			CFRelease(url);
			}
	if(resolvedPath==nil)
		resolvedPath = [[NSString alloc] initWithString:path];
	return resolvedPath;
}

- (NSString *)getDragnDropMacroString: (NSString *)fileNameExtension
{
	NSDictionary *dict1, *dict2;
	NSEnumerator *enum1, *enum2;
	NSArray     *array1, *array2;
	NSString    *nameStr, *targetStr, *contentStr;
	NSDictionary *macroDict = [[TSMacroMenuController sharedInstance] macroDictionary];
	if( macroDict == nil ) return nil;

	targetStr = [NSString stringWithFormat: @".%@", fileNameExtension ];
	array1 = [macroDict objectForKey: SUBMENU_KEY];
	enum1 = [array1 objectEnumerator];

	while ((dict1 = (NSDictionary *)[enum1 nextObject])) {
		nameStr = [dict1 objectForKey: NAME_KEY];
		if( [nameStr isEqualToString: @"Drag & Drop"] ){
			array2 = [dict1 objectForKey: SUBMENU_KEY];
			if( array2 )
			{
				enum2 = [array2 objectEnumerator];
				while ((dict2 = (NSDictionary *)[enum2 nextObject])) {
					nameStr = [dict2 objectForKey: NAME_KEY];
					if( [nameStr isEqualToString: targetStr] )
					{
						contentStr = [dict2 objectForKey: CONTENT_KEY];
						if (contentStr)
							return contentStr;
					}
				}
			}
		}
	}
	return nil;
}
// zenitani 1.33 end

// zenitani 1.33(2) begin
- (NSString *)readSourceFromEquationEditorPDF:(NSString *)filePath
{
	NSDictionary *fileAttr;
	NSNumber    *fileSize;
	NSString    *fileContent;
	unsigned    fileLength;
	NSMutableString *equationString;
	NSData      *fileData;
	NSRange myRange, searchRange;

	// check filesize. (< 1MB)
	fileAttr = [[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:YES];
	fileSize = [fileAttr objectForKey:NSFileSize];
	if(! ( fileSize && [fileSize intValue] < 1024 * 1024 ) ){  return nil; }

	// Encoding tag is fixed to 0 (Mac OS Roman). At least it doesn't work when it is 5 (DOSJapanese; Shift JIS).
	fileData = [NSData dataWithContentsOfFile:filePath];
	fileContent = [[[NSString alloc] initWithData:fileData encoding:NSMacOSRomanStringEncoding] autorelease];
	if( fileContent == nil ) return nil;

	fileLength = [fileContent length];
	myRange = [fileContent rangeOfString: @"/Subject (ESannot" options: NSLiteralSearch];
	if(( myRange.location == NSNotFound ) || ( myRange.location + myRange.length > fileLength - 10 ))  return nil;

	searchRange.location = myRange.location + myRange.length;
	searchRange.length   = fileLength - searchRange.location;
	myRange = [fileContent rangeOfString: @"ESannotend" options: NSLiteralSearch range: searchRange ];
	if( myRange.location == NSNotFound )  return nil;

	searchRange.length   = myRange.location - searchRange.location;
	equationString = [NSMutableString stringWithString: [fileContent substringWithRange: searchRange]];
	[equationString replaceOccurrencesOfString: @"ESslash" withString: @"\\" options: 0 range: NSMakeRange(0, [equationString length])];
	[equationString replaceOccurrencesOfString: @"ESleftbrack" withString: @"{" options: 0 range: NSMakeRange(0, [equationString length])];
	[equationString replaceOccurrencesOfString: @"ESrightbrack" withString: @"}" options: 0 range: NSMakeRange(0, [equationString length])];
	[equationString replaceOccurrencesOfString: @"ESdollar" withString: @"$" options: 0 range: NSMakeRange(0, [equationString length])];
	[equationString appendString: @"\n"];
	return equationString;
}
// zenitani 1.33(2) end

// The new two routines just insure that the cursor does not change when the option key is
// pressed. This paves the way for a serious change in the third routine. If the option key
// is down during a double click over a bracket, the bracket is chosen. If it is not down
// during a double click, the text between the bracket and its matching pair is selected.
// This is exactly the behavior of XCode.

- (void)flagsChanged:(NSEvent *)theEvent
{
	if (!([theEvent modifierFlags] & NSAlternateKeyMask))
		[super flagsChanged:theEvent];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	if (!([theEvent modifierFlags] & NSAlternateKeyMask))
		[super mouseMoved:theEvent];
}

// New version by David Reitter selects beginning backslash with words as in "\int"
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
{
	NSRange	replacementRange = { 0, 0 };
	NSString	*textString;
	int		length, i, j;
	BOOL	done;
	int		leftpar, rightpar, nestingLevel, uchar;

	textString = [self string];
	if (textString == nil)
		return replacementRange;

	replacementRange = [super selectionRangeForProposedRange: proposedSelRange granularity: granularity];

	// Extend word selection to cover an initial backslash (TeX command)
	if (granularity == NSSelectByWord)
	{
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
	if ((uchar == '}') || (uchar == ')') || (uchar == ']')) {
		j = i;
		rightpar = uchar;
		if (rightpar == '}')
			leftpar = '{';
		else if (rightpar == ')')
			leftpar = '(';
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
	else if ((uchar == '{') || (uchar == '(') || (uchar == '[')) {
		j = i;
		leftpar = uchar;
		if (leftpar == '{')
			rightpar = '}';
		else if (leftpar == '(')
			rightpar = ')';
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
	// AutoCompletion
	// Code added by Greg Landweber for auto-completions of '^', '_', etc.
	// First, avoid completing \^, \_, \"
	if ([aString length] == 1 &&  [_document isDoAutoCompleteEnabled]) {
		if ([aString characterAtIndex:0] >= 128 ||
			[self selectedRange].location == 0 ||
			[[self string] characterAtIndex:[self selectedRange].location - 1 ] != g_texChar )
		{
			NSString *completionString = [g_autocompletionDictionary objectForKey:aString];
			if ( completionString &&
				(!g_shouldFilter || [aString characterAtIndex:0] != YEN)) // avoid completing yen
			{
				[_document insertSpecialNonStandard:completionString
						undoKey: NSLocalizedString(@"Autocompletion", @"Autocompletion")];
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

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
	NSMutableString *newString;

	BOOL returnValue = [super writeSelectionToPasteboard:pboard type:type];
	if (returnValue && [type isEqualToString: NSStringPboardType]) {
		if ((g_shouldFilter == kMacJapaneseFilterMode) && [SUD boolForKey:@"ConvertToBackslash"]) {
			newString = filterYenToBackslash([pboard stringForType: NSStringPboardType]);
			returnValue = [pboard setString: newString forType: NSStringPboardType];
		} else if ((g_shouldFilter == kOtherJapaneseFilterMode) && [SUD boolForKey:@"ConvertToYen"]) {
			newString = filterBackslashToYen([pboard stringForType: NSStringPboardType]);
			returnValue = [pboard setString: newString forType: NSStringPboardType];
		}
	}
	return returnValue;
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
	if (g_shouldFilter && [type isEqualToString: NSStringPboardType]) {
		NSString *string = [pboard stringForType: NSStringPboardType];
		if (string) {
		// mitsu 1.29 (T1)-- in order to enable "Undo Paste"
			// Filtering for Japanese
			if (g_shouldFilter == kMacJapaneseFilterMode)
				string = filterBackslashToYen(string);
			else if (g_shouldFilter == kOtherJapaneseFilterMode)
				string = filterYenToBackslash(string);

			// zenitani 1.35 (A) -- normalizing newline character for regular expression
			if ([SUD boolForKey:ConvertLFKey]) {
				string = [OGRegularExpression replaceNewlineCharactersInString:string
						withCharacter:OgreLfNewlineCharacter];
			}

			// Replace the text--imitate what happens in ordinary editing
			NSRange	selectedRange = [self selectedRange];
			if ([self shouldChangeTextInRange:selectedRange replacementString:string]) {
				[self replaceCharactersInRange:selectedRange withString:string];
				[self didChangeText];
			}
			// by returning YES, "Undo Paste" menu item will be set up by system
			return YES;
		}
		else
			return NO;
	}
	return [super readSelectionFromPasteboard: pboard type: type];
}

// end addition

// mitsu 1.29 (T2-4)

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame: frameRect];
	[ self registerForDraggedTypes:
			[NSArray arrayWithObjects: NSStringPboardType, NSFilenamesPboardType, nil] ];
	_document = nil;
	return self;
}

- (void)setDocument: (TSDocument *)doc
{
	_document = doc;
}

// Command Completion!!

// mitsu 1.29 (P)

// Trap "keyDown:" for command completion:
// most of command completion function is concentrated here.
// two types of completions are activated on escape or g_commandCompletionChar:
// (1) ordinary: staring from the insertion point search backward for word boundary,
// which are defined by space, tab, linefeed, period, comma, colon, semicolon, {. }, (, ),
// and TeX character.  the string up to the boundary (TeX character and "{" are inclusive
// and others are not) is compared with the completion list.  the line whose beginning
// matches with the string will be inserted.  further escape(g_commandCompletionChar)
// will cycle through the candidates.  it cycles backward with shift key.
// special treatments: in the candiate,
//     #RET# will be replaced by linefeed (new line)
//     #INS# will be removed and the insertion point will be placed there
//     if there is ":=", the string after it (the first one) will be inserted
// (2) LaTeX special: if the insertion point is right after "\begin{...}"
// where ... contains no word boundary characters, then "\end{...}" together with
// linefeeds is completed, and the insertion point will be placed after "\begin{...}".
// these two types can be combined:  if after type (1) completion the situation matches
// with type (2) then the next candidate will be type (2).
// you only need to supply g_commandCompletionChar(unichar) and g_commandCompletionList
// (a string which starts and ends with line feeds).
// so the code can be reused in other applications???
- (void)keyDown:(NSEvent *)theEvent
{
	// FIXME: Using static variables like this is *EVIL*
	// It will simply not work correctly when using more than one window/view (which we frequently do)!
	// TODO: Convert all of these static stack variables to member variables.
	
	static BOOL wasCompleted = NO; // was completed on last keyDown
	static BOOL latexSpecial = NO; // was last time LaTeX Special?  \begin{...}
	static NSString *originalString = nil; // string before completion, starts at replaceLocation
	static NSString *currentString = nil; // completed string
	static unsigned replaceLocation = NSNotFound; // completion started here
	static unsigned int completionListLocation = 0; // location to start search in the list
	static unsigned textLocation = NSNotFound; // location of insertion point
	BOOL foundCandidate;
	NSString *textString, *foundString, *latexString = 0;
	NSMutableString *newString;
	unsigned selectedLocation, currentLength, from, to;
	NSRange foundRange, searchRange, spaceRange, insRange, replaceRange;
	NSCharacterSet *charSet;
	unichar c;

	if ([[theEvent characters] isEqualToString: g_commandCompletionChar] &&
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
						[NSString stringWithFormat: @"\n \t.,;;{}()%C", g_texChar]]; //should be global?
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
						[NSString stringWithFormat: @"\n \t.,;;{}()%C", g_texChar]];
			foundRange = [textString rangeOfCharacterFromSet:charSet
						options:NSBackwardsSearch range:NSMakeRange(0,selectedLocation)];
			if (foundRange.location != NSNotFound) {
				if (foundRange.location + 1 == selectedLocation)
					return; // no string to match
				c = [textString characterAtIndex: foundRange.location];
				if (c == g_texChar || c == '{') // special characters
					replaceLocation = foundRange.location; // include these characters for search
				else
					replaceLocation = foundRange.location + 1;
			} else {
				if (selectedLocation == 0)
					return; // no string to match
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
					if (insRange.location != NSNotFound)
						[newString replaceCharactersInRange:insRange withString:@""];
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
									g_texChar, latexString];
				insRange.location = 0;
				completionListLocation = NSNotFound; // just to remember that it wasn't completed
			} else {
				// reuse the current string
				newString = [NSMutableString stringWithFormat: @"%@\n%Cend%@\n",
									currentString, g_texChar, latexString];
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
			if (_document)
				[_document registerUndoWithString:originalString location:replaceLocation
					length:[newString length]
					key:NSLocalizedString(@"Completion", @"Completion")];
			//[self registerUndoWithString:originalString location:replaceLocation
			//		length:[newString length]
			//		key:NSLocalizedString(@"Completion", @"Completion")];
			// clean up
			if (_document) {
				from = replaceLocation;
				to = from + [newString length];
				[_document fixColor:from :to];
				[_document setupTags];
			}
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
			[self setSelectedRange: NSMakeRange(textLocation,0)];
		} else { // candidate was not found
			[originalString release];
			originalString = currentString = nil;
			wasCompleted = NO;
		}
		return;
	} else if (wasCompleted) { // we are not doing the completion
		[originalString release];
		[currentString release];
		originalString = currentString = nil;
		wasCompleted = NO;
	}

	[super keyDown: theEvent];
}

- (void)registerForCommandCompletion: (id)sender
{
	NSString		*initialWord, *aWord, *completionPath, *backupPath;
	NSData 			*myData;

	if (!g_commandCompletionList)
		return;

	// get the word(s) to register
	initialWord = [[self string] substringWithRange: [self selectedRange]];
	aWord = [initialWord stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];

	// add to the list-- it will be ideal if one can check redundancy
	[g_commandCompletionList deleteCharactersInRange:NSMakeRange(0,1)]; // remove first LF
	[g_commandCompletionList appendString: aWord];
	if ([g_commandCompletionList characterAtIndex: [g_commandCompletionList length]-1] != '\n')
		[g_commandCompletionList appendString: @"\n"];

	completionPath = [CommandCompletionPath stringByStandardizingPath];
	// back up old list
	backupPath = [completionPath stringByDeletingPathExtension];
	backupPath = [backupPath stringByAppendingString:@"~"];
	backupPath = [backupPath stringByAppendingPathExtension:@"txt"];
	NS_DURING
		[[NSFileManager defaultManager] removeFileAtPath:backupPath handler:nil];
		[[NSFileManager defaultManager] copyPath:completionPath toPath:backupPath handler:nil];
	NS_HANDLER
	NS_ENDHANDLER
	// save the new list to file
	//myData = [g_commandCompletionList dataUsingEncoding: NSUTF8StringEncoding]; // not used

	myData = [g_commandCompletionList dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];

	NS_DURING
		[myData writeToFile:completionPath atomically:YES];
	NS_HANDLER
	NS_ENDHANDLER

	[g_commandCompletionList insertString: @"\n" atIndex: 0];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{

	if ([anItem action] == @selector(registerForCommandCompletion:))
		return (g_canRegisterCommandCompletion && ([self selectedRange].length > 0));

	return [super validateMenuItem: anItem];
}

#pragma mark ========Ruler==========

//mfwitten@mit.edu: delegate methods for rulers"
- (void)rulerView: (NSRulerView*)aRulerView didMoveMarker: (NSRulerMarker*)aMarker
{
    NSRange selectedRange = [self selectedRange];
    id representedObject = [aMarker representedObject];
    
	if ([representedObject isKindOfClass: [NSString class]] && [(NSString*)representedObject isEqualToString: @"NSTailIndentRulerMarkerTag"])
        [self selectAll: self];
    
    [super rulerView: aRulerView didMoveMarker: aMarker];
    [self setSelectedRange: selectedRange];
}

@end

@implementation NSTextView (TeXShop)

// Compute the range of characters visible in this text view (a range into the
// NSTextStorage of this view).
- (NSRange)visibleCharacterRange
{
	NSLayoutManager *layoutManager;
	NSRect visibleRect;
	NSRange visibleRange;

	layoutManager = [self layoutManager];
	visibleRect = [[[self enclosingScrollView] contentView] documentVisibleRect];
	visibleRange = [layoutManager glyphRangeForBoundingRect:visibleRect inTextContainer:[self textContainer]];
	visibleRange = [layoutManager characterRangeForGlyphRange:visibleRange actualGlyphRange:nil];
	
	return visibleRange;
}

@end
