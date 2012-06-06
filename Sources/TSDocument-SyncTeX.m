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
 * $Id: TSDocument-SyncTeX.m 262 2008-08-15 01:33:24Z richard_koch $
 *
 */

/* WARNING: This source file has lots of "experimental routines" that are
 commented out or not called even if active. The two active routines are
 
	- (BOOL)doSyncTeXForPage: (int)pageNumber x: (float)xPosition y: (float)yPosition yOriginal: (float)yOriginalPosition
 
 and
 
    - (BOOL)doPreviewSyncTeXWithFilename:(NSString *)fileName andLine:(int)line andCharacterIndex:(unsigned int)idx andTextView:(id)aTextView;

*/

#import "TSDocument.h"
#import "TSTextView.h"
#import "globals.h"
#import "TSDocumentController.h"
#import "TSEncodingSupport.h"
#import "MyDragView.h"
#import "MyPDFKitView.h"



@implementation TSDocument (SyncTeX)

- (BOOL)checkForUniqueMatch: (NSString *)previewString withStart: (int)start andOffsetLength: (int)offset inSource: (NSString *)sourceString returnedRange: (NSRange *)foundRangeLocation multipleMatch: (BOOL *)multiple
{
	NSRange		searchRange, resultRange, newResultRange;
	int			end;
	NSString	*searchString, *clipString;
	
	if (start < 0)
		return NO;
	end = start + offset;
	if (end > [previewString length])
		return NO;
	searchRange.location = start;
	searchRange.length = offset;
	searchString = [previewString substringWithRange: searchRange];
	// NSLog(searchString);
	resultRange = [sourceString rangeOfString: searchString];
	if (resultRange.location == NSNotFound)
		return NO;
	clipString = [sourceString substringFromIndex: (resultRange.location + resultRange.length)];
	newResultRange = [clipString rangeOfString: searchString];
	if (newResultRange.location != NSNotFound) {
		*multiple = YES;
		return NO;
		}
	*foundRangeLocation = resultRange;
		return YES;
}

- (void)allocateSyncScanner
{	
	NSString		*myFileName, *mySyncTeXFileName;
	const char		*fileString;
	
	myFileName = [self fileName];
	if (! myFileName)
		return NO;
	
	mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex"];
	if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
	{ 
		mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex.gz"];
		if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
			return NO;
	}
	
	if (scanner != NULL)
		synctex_scanner_free(scanner);
	scanner = NULL;
	
	fileString = [myFileName cStringUsingEncoding:NSUTF8StringEncoding];
	scanner = synctex_scanner_new_with_output_file(fileString, NULL, 1);
	if (scanner == NULL) 
		return NO;
	else 
		return YES;
}

- (BOOL)doSyncTeXForPage: (int)pageNumber x: (float)xPosition y: (float)yPosition yOriginal: (float)yOriginalPosition
{
	NSString		*myFileName, *mySyncTeXFileName;
	const char		*fileString;
//	const char		*syncTeXFileName;
//	NSString		*syncTeXName;
	const char		*theFoundFileName;
	NSString 		*foundFileName;
	int				line;
	BOOL			gotSomething;
	NSString 		*newFile;
	NSError			*myError;
	
	int				length, theIndex;
	NSPoint			viewPosition;
	NSRange			correctedFoundRange;
	NSString		*sourceLineString;
	NSRange			myLineRange;
	BOOL			foundMatch, matchMultiple;
	int				matchStart, matchLength, i, matchAdjust, newLocation;
	NSRange			matchRange;
	

	
	
	myFileName = [self fileName];
	if (! myFileName)
		return NO;
	
	mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex"];
	if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
	{ 
		mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex.gz"];
		if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
			return NO;
	}
	
// BEGINNING OF PARSE SYNCTEX INFO CODE
	
	if (scanner == NULL)		
		return NO;
	else {
		
		// NSLog(@"OK, got scanner")
		//	syncTeXFileName = synctex_scanner_get_synctex(scanner);
		//	syncTeXName = [NSString stringWithCString: syncTeXFileName encoding:NSUTF8StringEncoding];
		//	NSLog(syncTeXName);
		
		gotSomething = NO;
		if (synctex_edit_query(scanner, pageNumber, xPosition, yPosition) > 0) {
			gotSomething = YES;
			synctex_node_t node;
			while ((node = synctex_next_result(scanner)) != NULL) {
				theFoundFileName = synctex_scanner_get_name(scanner, synctex_node_tag(node));
				foundFileName = [NSString stringWithCString: theFoundFileName encoding:NSUTF8StringEncoding];
				line = synctex_node_line(node);
				
				// NSLog(foundFileName);
				// NSLog(@"got all the way");
				
				//NSNumber *myNumber = [NSNumber numberWithInt:line];
				// NSLog([myNumber stringValue]);
				
				break; // FIXME: use more nodes?
			}
			if (! gotSomething)
				return NO;
		}
		
//		synctex_scanner_free(scanner);
//		scanner = NULL;

// END OF PARSING; NOW USE THE INFORMATION
		
		// foundFileName could be a full path, or just relative to the source directory
		
		if ([foundFileName isAbsolutePath])
			newFile = [foundFileName stringByStandardizingPath];
		else
			{
				newFile = [[[[self fileName] stringByDeletingLastPathComponent] stringByAppendingPathComponent: foundFileName] stringByStandardizingPath];
			}

		// NSLog(newFile);
		
		id newURL = [NSURL fileURLWithPath: newFile];
		TSDocument *newDocument = [[TSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:newURL display:YES error: &myError];
		
		if (newDocument == nil)
			return NO;
		TSTextView *myTextView = [newDocument textView];
		NSWindow *myTextWindow = [newDocument textWindow];
		[newDocument setTextSelectionYellow: YES];
		
// Now try to refine the selection
// ------------------------------------------
		
		viewPosition.x = xPosition;
		viewPosition.y = yOriginalPosition;
		PDFDocument *pdfDocument = [[self pdfKitView] document];
		PDFPage *thePage = [pdfDocument pageAtIndex: (pageNumber - 1)]; 
		NSString *fullText = [thePage string];
		length = [fullText length];
		theIndex = [thePage characterIndexAtPoint:viewPosition];
		
		myLineRange = [newDocument lineRange: line];
		sourceLineString = [[myTextView string] substringWithRange: myLineRange];
		
		// NSLog(fullText);
		// NSLog(sourceLineString);
		
		// Strategy: Find a five character range centered at the character in question. Try to find a unique match. If there is no match, slide right one character and try again. 
		// Do this twenty times. If no match, go back to the start and slide left twenty times, trying to find a match. Do this twenty times. Any time there is a unique
		// match, declare victory and adjust for the slide.
		// If there were matches, but no unique match, repeat with a seven character range, and then a nine character range.
		
		foundMatch = NO;
		matchLength = 5;
		matchAdjust = 2;
		matchStart = theIndex - matchAdjust - 1;
		matchMultiple = NO;
		
		i = 0;
		while ((i < 20) && (! foundMatch)) {
			matchStart++;
			i++;
			foundMatch = [self checkForUniqueMatch: fullText withStart: matchStart andOffsetLength: matchLength inSource: sourceLineString returnedRange: &matchRange multipleMatch: &matchMultiple];
		}
		
		matchStart = theIndex - matchAdjust;
		i = 0;
		while ((i < 20) && (! foundMatch)) {
			matchStart--;
			i++;
			foundMatch = [self checkForUniqueMatch: fullText withStart: matchStart andOffsetLength: matchLength inSource: sourceLineString returnedRange: &matchRange multipleMatch: &matchMultiple];
		}
		
		
		
		if (matchMultiple) {
			
			matchLength = 7;
			matchAdjust = 3;
			matchStart = theIndex - matchAdjust - 1;
			matchMultiple = NO;
			
			i = 0;
			while ((i < 20) && (! foundMatch)) {
				matchStart++;
				i++;
				foundMatch = [self checkForUniqueMatch: fullText withStart: matchStart andOffsetLength: matchLength inSource: sourceLineString returnedRange: &matchRange multipleMatch: &matchMultiple];
			}
			
			matchStart = theIndex - matchAdjust;
			i = 0;
			while ((i < 20) && (! foundMatch)) {
				matchStart--;
				i++;
				foundMatch = [self checkForUniqueMatch: fullText withStart: matchStart andOffsetLength: matchLength inSource: sourceLineString returnedRange: &matchRange multipleMatch: &matchMultiple];
			}
		}
		
		if (matchMultiple) {
			
			matchLength = 9;
			matchAdjust = 4;
			matchStart = theIndex - matchAdjust - 1;
			matchMultiple = NO;
			
			i = 0;
			while ((i < 20) && (! foundMatch)) {
				matchStart++;
				i++;
				foundMatch = [self checkForUniqueMatch: fullText withStart: matchStart andOffsetLength: matchLength inSource: sourceLineString returnedRange: &matchRange multipleMatch: &matchMultiple];
			}
			
			matchStart = theIndex - matchAdjust;
			i = 0;
			while ((i < 20) && (! foundMatch)) {
				matchStart--;
				i++;
				foundMatch = [self checkForUniqueMatch: fullText withStart: matchStart andOffsetLength: matchLength inSource: sourceLineString returnedRange: &matchRange multipleMatch: &matchMultiple];
			}
		}
		
		if (foundMatch) {
			matchAdjust = theIndex - (matchStart + matchAdjust);
			newLocation = matchRange.location + matchAdjust - 3;
			if (newLocation < 0)
				newLocation = 0;
			correctedFoundRange.location = myLineRange.location + newLocation;
			correctedFoundRange.length = 7;
			
			if ((correctedFoundRange.location + correctedFoundRange.length) > (myLineRange.location + myLineRange.length)) {
				if ([sourceLineString length] > 7) 
					correctedFoundRange.location = myLineRange.location + myLineRange.length - 7;
				else 
					foundMatch = NO;
			}
			
		}
		
// End of refinement 
// ---------------------------------------------------
		
		NSDictionary *mySelectedAttributes = [myTextView selectedTextAttributes];
		NSMutableDictionary *newSelectedAttributes = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes];
		[newSelectedAttributes setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
		// FIXME: use temporary attributes instead of abusing the text selection
		[myTextView setSelectedTextAttributes: newSelectedAttributes];
		
				if (foundMatch) {
					[myTextView setSelectedRange: correctedFoundRange];
					[myTextView scrollRangeToVisible: correctedFoundRange];
					}
				else
					[newDocument toLine: line];
		
		[myTextWindow makeKeyAndOrderFront:self];
		
		return YES;
		
	}
	
	
	
	
	return YES;
	
}

/* This was the main routine for pdf --> source until switching to Jerome Lauren's Internal Code to
 parse the synctex.gz file */

/*


 - (BOOL)doSyncTeXForPage: (int)pageNumber x: (float)xPosition y: (float)yPosition yOriginal: (float)yOriginalPosition
{

	NSDate          *myDate;
	NSString		*enginePath;
	NSString		*inputString;
	NSString		*pageString;
	NSString		*xString;
	NSString		*yString;
	NSString		*fileString;
	NSNumber		*pdfPageNumber, *xNumber, *yNumber;
	NSMutableArray	*args;
	NSRange			range1, range2, range3, range4, range5;
	unsigned		startIndex, lineEndIndex, contentsEndIndex;
	NSString		*sourceFile, *lineString;
	int				lineNumber;
	int				length, theIndex;
	NSPoint			viewPosition;
	NSRange			correctedFoundRange;
	NSString		*sourceLineString;
	NSRange			myLineRange;
	NSError			*myError;
	NSString		*newFile;
	BOOL			foundMatch, matchMultiple;
	int				matchStart, matchLength, i, matchAdjust, newLocation;
	NSRange			matchRange;
	NSString		*myFileName, *mySyncTeXFileName, *mySyncTeX;

	myFileName = [self fileName];
	if (! myFileName)
		return NO;
	mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex"];
	if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
		{ 
		mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex.gz"];
		if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
			return NO;
		}
	mySyncTeX = [[SUD stringForKey:TetexBinPath] stringByAppendingPathComponent: @"synctex"];
	if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeX])
		{
		return NO;
		} 


	if (synctexTask != nil) {
		[synctexTask terminate];
		myDate = [NSDate date];
		while (([synctexTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
		[synctexTask release];
		[synctexPipe release];
		synctexTask = nil;
		synctexPipe = nil;
		}

	synctexTask = [[NSTask alloc] init];
	[synctexTask setCurrentDirectoryPath: [[self fileName] stringByDeletingLastPathComponent]];
	synctexPipe = [[NSPipe pipe] retain];
	synctexHandle = [synctexPipe fileHandleForReading];
	[synctexTask setStandardOutput: synctexPipe];
	enginePath = [[NSBundle mainBundle] pathForResource:@"synctexwrap" ofType:nil];
	[synctexTask setLaunchPath:enginePath];
	args = [NSMutableArray array];
	
	pdfPageNumber = [NSNumber numberWithInt: pageNumber];
	xNumber = [NSNumber numberWithFloat: xPosition];
	yNumber = [NSNumber numberWithFloat: yPosition];
	
	pageString = [pdfPageNumber stringValue];
	xString = [xNumber stringValue];
	yString = [yNumber stringValue];
	fileString = [self fileName];
	
	inputString = [[[[[[pageString stringByAppendingString:@":"] stringByAppendingString: xString] stringByAppendingString:@":"] stringByAppendingString: yString] stringByAppendingString:@":"] stringByAppendingString: fileString]; 
	
	NSString *binPath = [[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath];
	[args addObject: binPath];
	[args addObject: inputString];
	
	[synctexTask setArguments:args];
	[synctexTask launch];
	
	NSData *myData = [synctexHandle readDataToEndOfFile];
	
	NSString *content;
	content = [[[NSString alloc] initWithData:myData encoding:_encoding] autorelease];
	if (!content) {
		_badEncoding = _encoding;
		showBadEncodingDialog = YES;
		content = [[[NSString alloc] initWithData:myData encoding:NSMacOSRomanStringEncoding] autorelease];
	}
	
	NSString *outputString = [[NSString alloc] initWithData: myData encoding: NSUTF8StringEncoding];
	if (!outputString)
		outputString = [[NSString alloc] initWithData: myData encoding: NSASCIIStringEncoding];
	
	if (synctexTask != nil) {
		[synctexTask terminate];
		myDate = [NSDate date];
		while (([synctexTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
		[synctexTask release];
		[synctexPipe release];
		synctexTask = nil;
		synctexPipe = nil;
		}
		
	
	// NSLog(outputString);
	
	range1 =  [outputString rangeOfString:@"SyncTeX result begin"];
	if (range1.location == NSNotFound)
		return NO;
		
	outputString = [outputString substringFromIndex: (range1.location + 20)];
	
	range2 = [outputString rangeOfString:@"Input:"];
	if (range2.location == NSNotFound)
		return NO;
	[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range2];
	range3.location = startIndex + 6;
	range3.length = lineEndIndex - startIndex - 6;
	sourceFile = [outputString substringWithRange: range3];
	
	outputString = [outputString substringFromIndex: lineEndIndex];
	
	range4 = [outputString rangeOfString:@"Line:"];
	if (range4.location == NSNotFound)
		return NO;
	[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range4];
	range5.location = startIndex + 5;
	range5.length = lineEndIndex - startIndex - 5;
	lineString = [outputString substringWithRange: range5];
	lineNumber = [lineString intValue];	
	

	// NSLog(sourceFile);
	// NSLog(lineString);
	
	newFile = [[self fileName] stringByDeletingLastPathComponent];
	newFile = [newFile stringByAppendingPathComponent:sourceFile];
	// newFile = [newFile stringByDeletingPathExtension];
	newFile = [newFile stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	// NSLog(newFile);

	
	id newURL = [NSURL fileURLWithPath: newFile];
	TSDocument *newDocument = [[TSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:newURL display:YES error: &myError];
	
	if (newDocument == nil)
		return NO;
	TSTextView *myTextView = [newDocument textView];
	NSWindow *myTextWindow = [newDocument textWindow];
	[newDocument setTextSelectionYellow: YES];
	
// *******************

	viewPosition.x = xPosition;
	viewPosition.y = yOriginalPosition;
	PDFDocument *pdfDocument = [[self pdfKitView] document];
	PDFPage *thePage = [pdfDocument pageAtIndex: (pageNumber - 1)]; 
	NSString *fullText = [thePage string];
	length = [fullText length];
	theIndex = [thePage characterIndexAtPoint:viewPosition];
	
	myLineRange = [newDocument lineRange: lineNumber];
	sourceLineString = [[myTextView string] substringWithRange: myLineRange];	

// Strategy: Find a five character range centered at the character in question. Try to find a unique match. If there is no match, slide right one character and try again. 
// Do this twenty times. If no match, go back to the start and slide left twenty times, trying to find a match. Do this twenty times. Any time there is a unique
// match, declare victory and adjust for the slide.
// If there were matches, but no unique match, repeat with a seven character range, and then a nine character range.

	foundMatch = NO;
	matchLength = 5;
	matchAdjust = 2;
	matchStart = theIndex - matchAdjust - 1;
	matchMultiple = NO;
	
	i = 0;
	while ((i < 20) && (! foundMatch)) {
		matchStart++;
		i++;
		foundMatch = [self checkForUniqueMatch: fullText withStart: matchStart andOffsetLength: matchLength inSource: sourceLineString returnedRange: &matchRange multipleMatch: &matchMultiple];
		}
		
	matchStart = theIndex - matchAdjust;
	i = 0;
	while ((i < 20) && (! foundMatch)) {
		matchStart--;
		i++;
		foundMatch = [self checkForUniqueMatch: fullText withStart: matchStart andOffsetLength: matchLength inSource: sourceLineString returnedRange: &matchRange multipleMatch: &matchMultiple];
		}
	
	
	
	if (matchMultiple) {
	
		matchLength = 7;
		matchAdjust = 3;
		matchStart = theIndex - matchAdjust - 1;
		matchMultiple = NO;
	
		i = 0;
		while ((i < 20) && (! foundMatch)) {
			matchStart++;
			i++;
			foundMatch = [self checkForUniqueMatch: fullText withStart: matchStart andOffsetLength: matchLength inSource: sourceLineString returnedRange: &matchRange multipleMatch: &matchMultiple];
			}
		
		matchStart = theIndex - matchAdjust;
		i = 0;
		while ((i < 20) && (! foundMatch)) {
			matchStart--;
			i++;
			foundMatch = [self checkForUniqueMatch: fullText withStart: matchStart andOffsetLength: matchLength inSource: sourceLineString returnedRange: &matchRange multipleMatch: &matchMultiple];
			}
		}
		
	if (matchMultiple) {
	
		matchLength = 9;
		matchAdjust = 4;
		matchStart = theIndex - matchAdjust - 1;
		matchMultiple = NO;
	
		i = 0;
		while ((i < 20) && (! foundMatch)) {
			matchStart++;
			i++;
			foundMatch = [self checkForUniqueMatch: fullText withStart: matchStart andOffsetLength: matchLength inSource: sourceLineString returnedRange: &matchRange multipleMatch: &matchMultiple];
			}
		
		matchStart = theIndex - matchAdjust;
		i = 0;
		while ((i < 20) && (! foundMatch)) {
			matchStart--;
			i++;
			foundMatch = [self checkForUniqueMatch: fullText withStart: matchStart andOffsetLength: matchLength inSource: sourceLineString returnedRange: &matchRange multipleMatch: &matchMultiple];
			}
		}
		
	if (foundMatch) {
		matchAdjust = theIndex - (matchStart + matchAdjust);
		newLocation = matchRange.location + matchAdjust - 3;
		if (newLocation < 0)
			newLocation = 0;
		correctedFoundRange.location = myLineRange.location + newLocation;
		correctedFoundRange.length = 7;
		
		if ((correctedFoundRange.location + correctedFoundRange.length) > (myLineRange.location + myLineRange.length)) {
			if ([lineString length] > 7) 
				correctedFoundRange.location = myLineRange.location + myLineRange.length - 7;
			else 
				foundMatch = NO;
			}
	
		}
		

// *******************
	

	NSDictionary *mySelectedAttributes = [myTextView selectedTextAttributes];
	NSMutableDictionary *newSelectedAttributes = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes];
	[newSelectedAttributes setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
	// FIXME: use temporary attributes instead of abusing the text selection
	[myTextView setSelectedTextAttributes: newSelectedAttributes];

	if (foundMatch) {
		[myTextView setSelectedRange: correctedFoundRange];
		[myTextView scrollRangeToVisible: correctedFoundRange];
		}
	else
		[newDocument toLine: lineNumber];
		
	[myTextWindow makeKeyAndOrderFront:self];

	return YES;

}
 
*/

/* The code below is an experimental version of new code to handle pdfsync. It is messy, with various experiments half done.
 The code calls the system synctex to analyze the sync file, and first checks to see if it is the old 2008 synctex or the new
 2009 synctex. This is important because the two versions give different results. 
 
 The code is complicated because it must handle both versions. In addition, this code experiments with embedding the synctex
 file in TeXShop rather than calling the experimental version. I only have modified code for Intel, so another problem is that
 the code has to see if the Intel version which returns "Magnification" is called, or the PowerPC code which doesn't.
 
 For now, doPreviewSyncTeXWithFilename is called rather than this code.
*/

- (BOOL)doPreviewSyncTeXWithFilenameNew:(NSString *)fileName andLine:(int)line andCharacterIndex:(unsigned int)idx andTextView:(id)aTextView;
{
	NSDate          *myDate;
	NSString		*enginePath;
	NSString		*mainSourceString;
	NSString		*inputString;
	NSString		*pdfPreviewString;
	NSString		*lineString, *pieceText;
	NSString		*indexString;
	NSString		*fileString;
	NSNumber		*lineNumber, *indexNumber;
	NSMutableArray	*args;
	NSRange			myRange;
	NSRange			range1, range2;
	NSString		*paramString;
	int				pageNumber[200];
	float			hNumber[200], vNumber[200], WNumber[200], HNumber[200], xNumber[200], yNumber[200];
	NSString		*theText[200];
	NSString		*boxText[200];
	NSRange			theRanges[200];
	BOOL			firstPage[200];
	BOOL			secondPage[200];
	NSRect			boxRect[200];
	int				initialFirstPage;
	int				initialSecondPage;
	int				boxNumber;
	float			Param;
	unsigned		startIndex, lineEndIndex, contentsEndIndex;
	NSRect			myOval;
	PDFPage			*thePage;
	int				i;
	NSString		*pageString;
	NSPoint			aPoint;
	int				theNumber, theLocation;
	NSRange			theRange;
	NSRange			myLineRange, myPieceRange, myTranslatedPieceRange;
	NSString		*sourceLineString, *searchString;
	TSDocument		*newDocument;
	int				searchIndex;
	PDFSelection	*theSelection, *anotherSelection;
	NSRect			anotherRect, pageSize;
	NSString		*myFileName, *mySyncTeXFileName, *mySyncTeX;
	float			magnification;
	int				xoffset, yoffset;
	BOOL			oldVersion;
	NSString		*tempString;
	PDFSelection	*tempSelection;
	int				mainPageNumber;
	float			left, middle;
	int				k;
		
	// return NO;  // temporarily use Search synchronization
		
// FIRST GET SYNCTEX DATA

	
	
	myFileName = [self fileName];
	if (! myFileName)
		return NO;
	mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex"];
	if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
		{ 
		mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex.gz"];
		if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
			return NO;
		}
	mySyncTeX = [[SUD stringForKey:TetexBinPath] stringByAppendingPathComponent: @"synctex"];
	if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeX])
		{
		return NO;
		} 

	
	/* First, get the synctex information */
	

	
	if (synctexTask != nil) {
		[synctexTask terminate];
		myDate = [NSDate date];
		while (([synctexTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
		[synctexTask release];
		[synctexPipe release];
		synctexTask = nil;
		synctexPipe = nil;
		}


	synctexTask = [[NSTask alloc] init];
	mainSourceString = [self fileName]; // note: this will be the root document when the doPeviewSyncTeXWithFilename is called
	[synctexTask setCurrentDirectoryPath: [mainSourceString stringByDeletingLastPathComponent]];
	synctexPipe = [[NSPipe pipe] retain];
	synctexHandle = [synctexPipe fileHandleForReading];
	[synctexTask setStandardOutput: synctexPipe];
	enginePath = [[NSBundle mainBundle] pathForResource:@"synctex" ofType:nil];
	// enginePath = [[NSBundle mainBundle] pathForResource:@"synctexviewwrap" ofType:nil];
	[synctexTask setLaunchPath:enginePath];
	
/*
	args = [NSMutableArray array];
	
	lineNumber = [NSNumber numberWithInt: line];
	indexNumber = [NSNumber numberWithInt: idx];
	
	lineString = [lineNumber stringValue];
	indexString = [indexNumber stringValue];
	if (fileName == nil)
		fileString = [[self fileName] lastPathComponent];
	else {
		NSString *initialPart = [[[self fileName] stringByStandardizingPath] stringByDeletingLastPathComponent]; //get root complete path, minus root name
		initialPart = [initialPart stringByAppendingString:@"/"];
		myRange = [fileName rangeOfString: initialPart options:NSCaseInsensitiveSearch]; //see if this forms the first part of the source file's path
		if ((myRange.location == 0) && (myRange.length <= [fileName length])) {
			fileString = [fileName substringFromIndex: myRange.length]; //and remove it, so we have a relative path from root
			}
		else
			return NO;
		}
		
	pdfPreviewString = [[mainSourceString stringByDeletingPathExtension] stringByAppendingPathExtension: @"pdf"]; 
	
	inputString = [[[[lineString stringByAppendingString:@":"] stringByAppendingString: indexString] stringByAppendingString:@":"] stringByAppendingString: fileString]; 
	
	NSString *binPath = [[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath];
	// NSString *binPath = [[NSBundle mainBundle] pathForResource:@"synctex" ofType:nil];
	[args addObject: binPath];
	[args addObject: inputString];
	[args addObject: pdfPreviewString];
 */
 

/*
	synctexTask = [[NSTask alloc] init];
	mainSourceString = [self fileName]; // note: this will be the root document when the doPeviewSyncTeXWithFilename is called
	[synctexTask setCurrentDirectoryPath: [mainSourceString stringByDeletingLastPathComponent]];
	synctexPipe = [[NSPipe pipe] retain];
	synctexHandle = [synctexPipe fileHandleForReading];
	[synctexTask setStandardOutput: synctexPipe];
	enginePath = [[NSBundle mainBundle] pathForResource:@"synctex" ofType:nil];
	[synctexTask setLaunchPath:enginePath];
*/
	args = [NSMutableArray array];
	
	[args addObject: @"view"];
	[args addObject: @"-i"];
	
	
	
	lineNumber = [NSNumber numberWithInt: line];
	indexNumber = [NSNumber numberWithInt: idx];
	
	lineString = [lineNumber stringValue];
	indexString = [indexNumber stringValue];
	if (fileName == nil)
		fileString = [[self fileName] lastPathComponent];
	else {
		NSString *initialPart = [[[self fileName] stringByStandardizingPath] stringByDeletingLastPathComponent]; //get root complete path, minus root name
		initialPart = [initialPart stringByAppendingString:@"/"];
		myRange = [fileName rangeOfString: initialPart options:NSCaseInsensitiveSearch]; //see if this forms the first part of the source file's path
		if ((myRange.location == 0) && (myRange.length <= [fileName length])) {
			fileString = [fileName substringFromIndex: myRange.length]; //and remove it, so we have a relative path from root
		}
		else
			return NO;
	}
	
	pdfPreviewString = [[mainSourceString stringByDeletingPathExtension] stringByAppendingPathExtension: @"pdf"]; 
	
	inputString = [[[[lineString stringByAppendingString:@":"] stringByAppendingString: indexString] stringByAppendingString:@":"] stringByAppendingString: fileString]; 
	
	[args addObject: inputString];
	[args addObject: @"-o"];
	[args addObject: pdfPreviewString];
	
	 
	
	
	[synctexTask setArguments:args];
	[synctexTask launch];
	
	NSData *myData = [synctexHandle readDataToEndOfFile];
	NSString *outputString = [[NSString alloc] initWithData: myData encoding: NSASCIIStringEncoding];
	
	if (synctexTask != nil) {
		[synctexTask terminate];
		myDate = [NSDate date];
		while (([synctexTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
		[synctexTask release];
		[synctexPipe release];
		synctexTask = nil;
		synctexPipe = nil;
		}

	// NSLog(outputString);
	
	
	
	/* Next, digest this information */
	
	range1 = [outputString rangeOfString:@"This is SyncTeX command line utility, version 1.0"];
	if (range1.location != NSNotFound)
		oldVersion = YES;
	else
		oldVersion = NO;
	
	range1 =  [outputString rangeOfString:@"SyncTeX result begin"];
	if (range1.location == NSNotFound)
		return NO;
	outputString = [outputString substringFromIndex: (range1.location + 20)];
	
	range1 = [outputString rangeOfString: @"Magnification:"];
	if (range1.location == NSNotFound) {
		
		magnification = 1;
		xoffset = 0;
		yoffset = 0;
	}
	
	else {
			

	// range1 = [outputString rangeOfString: @"Magnification:"];
	// if (range1.location == NSNotFound)
	// 	return NO;
		
		NSLog(@"yes, here");
	[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
	range2.location = startIndex + 14;
	range2.length = lineEndIndex - startIndex - 14;
	paramString = [outputString substringWithRange: range2];
	magnification = [paramString floatValue];
	magnification = magnification / .000015;
	// NSLog(paramString);
	outputString = [outputString substringFromIndex: lineEndIndex];
	
	range1 = [outputString rangeOfString:@"XOffset:"];
	if (range1.location == NSNotFound)
		return NO;
	[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
	range2.location = startIndex + 8;
	range2.length = lineEndIndex - startIndex - 8;
	paramString = [outputString substringWithRange: range2];
	// NSLog(paramString);
	xoffset = [paramString intValue];
	outputString = [outputString substringFromIndex: lineEndIndex];
	
	range1 = [outputString rangeOfString:@"YOffset:"];
	if (range1.location == NSNotFound)
		return NO;
	[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
	range2.location = startIndex + 8;
	range2.length = lineEndIndex - startIndex - 8;
	paramString = [outputString substringWithRange: range2];
	// NSLog(paramString);
	yoffset = [paramString intValue];
	outputString = [outputString substringFromIndex: lineEndIndex];
	xoffset = xoffset * 65536;
	yoffset = yoffset * 65536;
	// NSLog([NSString stringWithFormat:@"xoffset %d", xoffset]);

	}
	


	
//	magnification = 1;
//	xoffset = 0;
//	yoffset = 0;
		
	
	
/*
 
	
*/

// NOW DIGEST THE BOX DATA FROM SYNCTEX
	
	boxNumber = 0;
	
	while (boxNumber < 200) {
	
		range1 = [outputString rangeOfString:@"Page:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 5;
		range2.length = lineEndIndex - startIndex - 5;
		paramString = [outputString substringWithRange: range2];
		pageNumber[boxNumber] = [paramString intValue];
		if (boxNumber == 0) {
				initialFirstPage = pageNumber[boxNumber];
				initialSecondPage = initialFirstPage;
				}
		if (pageNumber[boxNumber] == initialFirstPage)
			firstPage[boxNumber] = YES;
		else { 
			firstPage[boxNumber] = NO;
			if (initialSecondPage == initialFirstPage) 
				initialSecondPage = pageNumber[boxNumber];
			if (pageNumber[boxNumber] == initialSecondPage)
				secondPage[boxNumber] = YES;
			else
				secondPage[boxNumber] = NO;
			}
		
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"x:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		////
		xNumber[boxNumber] = [paramString intValue] * magnification + xoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"y:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		////
		yNumber[boxNumber] = [paramString intValue] * magnification  + yoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"h:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		////
		hNumber[boxNumber] = [paramString intValue] * magnification  + xoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"v:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		////
		vNumber[boxNumber] = [paramString intValue] * magnification  + yoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"W:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		WNumber[boxNumber] = [paramString intValue] * magnification;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"H:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		HNumber[boxNumber] = [paramString intValue] * magnification;	
		outputString = [outputString substringFromIndex: lineEndIndex];

		boxNumber++;
	}
	
	if (boxNumber == 0)
		return NO;
	
	
	
	
	/*
	
	i = 0;
	
		thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[i] - 1)];
		pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
		myOval.size.height = HNumber[i] + 10; myOval.size.width = WNumber[i] + 10;
		myOval.origin.x = hNumber[i] - 5; myOval.origin.y = pageSize.size.height - vNumber[i] - 5;
	
		[(MyPDFKitView *)[pdfKitWindow activeView] setIndexForMark: (pageNumber[i] - 1)];
		[(MyPDFKitView *)[pdfKitWindow activeView] setBoundsForMark: myOval];
		[(MyPDFKitView *)[pdfKitWindow activeView] setDrawMark: YES];
		[[pdfKitWindow activeView] goToPage: thePage];
		[[pdfKitWindow activeView] display];
	
			
		return YES;

	*/	
		
		
		
	
	/* Next, get the text inside these various boxes and under the "index point" */
	
// NOW GET THE TEXT IN EACH BOX	
		
	i = 0;
	
	// for each box, get the text inside the box
	
	while (i < boxNumber) {
		thePage = [[[pdfKitWindow activeView] document] pageAtIndex: (pageNumber[i] - 1)];
		pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
		
		
		if (oldVersion) {
			Param = 65536;
			aPoint.x = xNumber[i]/Param;
			aPoint.y = pageSize.size.height - yNumber[i]/Param;
			}
		else {
			aPoint.x = xNumber[i]; // in version 1.2
			aPoint.y = pageSize.size.height - yNumber[i]; // in version 1.2
		}
		
		// if (oldVersion) 
		{
		
			theNumber = [thePage characterIndexAtPoint:aPoint];
			pageString = [thePage string];
			theLocation = theNumber - 2;
			if (theLocation < 0)
				theLocation = 0;
			theRange.location = theLocation;
			if ((theLocation + 5) < [pageString length])
					theRange.length = 5;
				else
					theRange.length = [pageString length] - theLocation;

			theRanges[i] = theRange;
			theText[i] = [pageString substringWithRange:theRange];
			// NSLog(theText[i]);
			
		}
		
		if ( ! oldVersion) {
			myOval.size.height = HNumber[i] + 10; myOval.size.width = WNumber[i] + 10;
			myOval.origin.x = hNumber[i] - 5; myOval.origin.y = pageSize.size.height - vNumber[i] - 5;
			tempSelection = [thePage selectionForRect: myOval];
			boxRect[i] = [tempSelection boundsForPage: thePage];
			tempString = [tempSelection string];
			boxText[i] = tempString;
		}
		i++;
		}
		
		
	/* Next get the text where the mouse was clicked and see if that text is inside one of these boxes.
	   If so, declare victory. */

// GET TEXT WHERE MOUSE WAS CLICKED
	   
		
	if (fileName == nil)
		newDocument = self;
	else {
		id newURL = [NSURL fileURLWithPath: fileName];
		newDocument = [[TSDocumentController sharedDocumentController] documentForURL:newURL];
		}
	if (newDocument == nil)
		return NO;
	myLineRange = [newDocument lineRange: line];
	sourceLineString = [[aTextView string] substringWithRange: myLineRange];
	// NSLog(sourceLineString);
	
// IN OLD METHOD, FIND BOX TEXT IN SOURCE LINE TEXT
	
	searchIndex = idx - myLineRange.location;
	
	i = 0;
	if (oldVersion) {
		while (i < boxNumber) {
			theRange = [sourceLineString rangeOfString: theText[i]];
			if ((theRange.location != NSNotFound) && (theRange.location <= (searchIndex + 5)) && (searchIndex < (theRange.location + theRange.length + 5))) {
		
				// theRange = [sourceLineString rangeOfString: pieceText];
				// if (theRange.location != NSNotFound) {
			
			thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[i] - 1)];
			theSelection = [thePage selectionForRange: theRanges[i]];
			myOval = [theSelection boundsForPage:thePage];
			pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
			Param = 65536;
			[(MyPDFKitView *)[pdfKitWindow activeView] setIndexForMark: (pageNumber[i] - 1)];
			[(MyPDFKitView *)[pdfKitWindow activeView] setBoundsForMark: myOval];
			[(MyPDFKitView *)[pdfKitWindow activeView] setDrawMark: YES];
			[[pdfKitWindow activeView] goToPage: thePage];
			[[pdfKitWindow activeView] setCurrentSelection: theSelection];
			[[pdfKitWindow activeView] scrollSelectionToVisible:self];
			[[pdfKitWindow activeView] setCurrentSelection: nil];
			[[pdfKitWindow activeView] display];
			[pdfKitWindow makeKeyAndOrderFront:self]; 

			return YES;
			}
			i++;
			}
		}
	
// NOW THE NEW METHOD
	
	i = 0;
	
/* Explanation: Take the source code for the line, and the character in this line. Go back 5 characters and forward 5 characters. 
 Then search through the text for all boxes until this is found. If found, declare success, and choose an appropriate portion of the box.
 If no success, back up 5 characters and try again. Repeat as often as characters remain. If no success, repeat, going forward 5 characters.
*/
	
	if (! oldVersion ) {
		
		myPieceRange.location = idx - myLineRange.location - 5;
		if (myPieceRange.location < 0)
			myPieceRange.location = 0;
		myPieceRange.length = 10;
		if ((myPieceRange.length + myPieceRange.location) >= [sourceLineString length])
			myPieceRange.length = [sourceLineString length] - myPieceRange.location;
		myTranslatedPieceRange = myPieceRange;
		k = 0;
		
		do {
		
		pieceText = [sourceLineString substringWithRange: myTranslatedPieceRange];
		// NSLog(pieceText);
		
		i = 0;
		while ((i < boxNumber) && (boxText[i] != nil))  {
			theRange = [boxText[i] rangeOfString: pieceText];
			if (theRange.location != NSNotFound) {
				left = theRange.location + (myPieceRange.location - myTranslatedPieceRange.location); 
				left = left / [boxText[i] length]; 
				}
			if ((theRange.location != NSNotFound) && (left < 0.9)) {
				
				/* now get proportion of totale box length to left, and in middle */
				middle = theRange.length;
				middle = middle / [boxText[i] length];
				
				thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[i] - 1)];
				theSelection = [thePage selectionForRange: theRanges[i]];
				
				/*
				myOval.size.height = HNumber[i] + 10; myOval.size.width = WNumber[i] + 10;
				
				myOval.origin.x = hNumber[i] - 5 + (myOval.size.width) * left; myOval.origin.y = pageSize.size.height - vNumber[i] - 5;
				myOval.size.width = myOval.size.width * middle;
				*/
				myOval.size.height = boxRect[i].size.height;
				myOval.size.width = boxRect[i].size.width;
				myOval.origin.x = boxRect[i].origin.x + myOval.size.width * left;
				myOval.origin.y = boxRect[i].origin.y;
				myOval.size.width = myOval.size.width * middle;

				pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
				[(MyPDFKitView *)[pdfKitWindow activeView] setIndexForMark: (pageNumber[i] - 1)];
				[(MyPDFKitView *)[pdfKitWindow activeView] setBoundsForMark: myOval];
				[(MyPDFKitView *)[pdfKitWindow activeView] setDrawMark: YES];
				[[pdfKitWindow activeView] goToPage: thePage];
				[[pdfKitWindow activeView] setCurrentSelection: theSelection];
				[[pdfKitWindow activeView] scrollSelectionToVisible:self];
				[[pdfKitWindow activeView] setCurrentSelection: nil];
				[[pdfKitWindow activeView] display];
				[pdfKitWindow makeKeyAndOrderFront:self]; 
				
				return YES;
				}
			i++;
			}
			
			if (myTranslatedPieceRange.location > 5)
				myTranslatedPieceRange.location = myTranslatedPieceRange.location - 5;
			else
				myTranslatedPieceRange.location = 0;
			k++;
		}
		while ((myTranslatedPieceRange.location > 0) && (k < 3));
		
			
	myTranslatedPieceRange = myPieceRange;
	myTranslatedPieceRange.location = myTranslatedPieceRange.location + 5;
		while ( (myTranslatedPieceRange.location + myTranslatedPieceRange.length) < [sourceLineString length])
		
		{
		pieceText = [sourceLineString substringWithRange: myTranslatedPieceRange];
		// NSLog(pieceText);
		
		k = 0;
		i = 0;
			while ((i < boxNumber) && (boxText[i] != nil) && (k < 2)) {
			theRange = [boxText[i] rangeOfString: pieceText];
			if (theRange.location != NSNotFound) {
				left = theRange.location + (myPieceRange.location - myTranslatedPieceRange.location); 
				left = left / [boxText[i] length];
				}
			if ((theRange.location != NSNotFound) && (left < 0.9)) {
				
				// now get proportion of totale box length to left, and in middle 
				middle = theRange.length;
				middle = middle / [boxText[i] length];
				
				
				thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[i] - 1)];
				theSelection = [thePage selectionForRange: theRanges[i]];
				
				/*
				myOval.size.height = HNumber[i] + 10; myOval.size.width = WNumber[i] + 10;
				
				myOval.origin.x = hNumber[i] - 5 + (myOval.size.width) * left; myOval.origin.y = pageSize.size.height - vNumber[i] - 5;
				myOval.size.width = myOval.size.width * middle;
				*/
				myOval.size.height = boxRect[i].size.height;
				myOval.size.width = boxRect[i].size.width;
				myOval.origin.x = boxRect[i].origin.x + myOval.size.width * left;
				myOval.origin.y = boxRect[i].origin.y;
				myOval.size.width = myOval.size.width * middle;
				
				pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
				[(MyPDFKitView *)[pdfKitWindow activeView] setIndexForMark: (pageNumber[i] - 1)];
				[(MyPDFKitView *)[pdfKitWindow activeView] setBoundsForMark: myOval];
				[(MyPDFKitView *)[pdfKitWindow activeView] setDrawMark: YES];
				[[pdfKitWindow activeView] goToPage: thePage];
				[[pdfKitWindow activeView] setCurrentSelection: theSelection];
				[[pdfKitWindow activeView] scrollSelectionToVisible:self];
				[[pdfKitWindow activeView] setCurrentSelection: nil];
				[[pdfKitWindow activeView] display];
				[pdfKitWindow makeKeyAndOrderFront:self]; 
				
				return YES;
				
			}
			i++;
		}
		
		myTranslatedPieceRange.location = myTranslatedPieceRange.location + 5;
		k++;
	}
		

 }
				
	



/*
	if (! oldVersion) {
	
			if (! oldVersion) {
				myPieceRange.location = idx - myLineRange.location - 5;
				if (myPieceRange.location < 0)
					myPieceRange.location = 0;
				myPieceRange.length = 10;
				if ((myPieceRange.length + myPieceRange.location) > [sourceLineString length])
					myPieceRange.length = [sourceLineString length] - myPieceRange.location;
				pieceText = [sourceLineString substringWithRange: myPieceRange];
				NSLog(pieceText);
			}
			
			
			while (i < boxNumber) {
				// theRange = [sourceLineString rangeOfString: theText[i]];
				// if ((theRange.location != NSNotFound) && (theRange.location <= (searchIndex + 5)) && (searchIndex < (theRange.location + theRange.length + 5))) {
					
				theRange = [sourceLineString rangeOfString: pieceText];
				if (theRange.location != NSNotFound) {
					
					thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[i] - 1)];
					theSelection = [thePage selectionForRange: theRanges[i]];
					myOval = [theSelection boundsForPage:thePage];
					pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
					Param = 65536;
					[(MyPDFKitView *)[pdfKitWindow activeView] setIndexForMark: (pageNumber[i] - 1)];
					[(MyPDFKitView *)[pdfKitWindow activeView] setBoundsForMark: myOval];
					[(MyPDFKitView *)[pdfKitWindow activeView] setDrawMark: YES];
					[[pdfKitWindow activeView] goToPage: thePage];
					[[pdfKitWindow activeView] setCurrentSelection: theSelection];
					[[pdfKitWindow activeView] scrollSelectionToVisible:self];
					[[pdfKitWindow activeView] setCurrentSelection: nil];
					[[pdfKitWindow activeView] display];
					[pdfKitWindow makeKeyAndOrderFront:self]; 
					
					return YES;
				}
				i++;
			}
		}
 
 */
			
		
		
		
	/* In case of failure, guess the full box where the text occurs. */
	
	if (oldVersion) 
		Param = 65536;
	else
		Param = 1;
	
	mainPageNumber = 0;
	if ((boxNumber > 1) && ( ! firstPage[1]))
		mainPageNumber = 1;
	thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[mainPageNumber] - 1)];
		pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];

	myOval.size.height = HNumber[mainPageNumber] / Param + 10; myOval.size.width = WNumber[mainPageNumber]/ Param + 10;
	myOval.origin.x = hNumber[mainPageNumber] / Param - 5; myOval.origin.y = pageSize.size.height - vNumber[mainPageNumber]/ Param - 5;

	theSelection = [thePage selectionForRange: theRanges[mainPageNumber]];
	i = mainPageNumber + 1;
	while (i < boxNumber) {
		if ( ((mainPageNumber == 0) && firstPage[i]) || ((mainPageNumber == 1) && secondPage[i]) ) {
			anotherRect.size.height = HNumber[i] / Param + 10; anotherRect.size.width = WNumber[i]/ Param + 10;
			anotherRect.origin.x = hNumber[i] / Param - 5; anotherRect.origin.y = pageSize.size.height - vNumber[i]/ Param - 5;
			if (NSIntersectsRect(myOval, anotherRect))
				myOval = NSUnionRect(myOval, anotherRect);
			}
		i++;
		}
	
	if (mainPageNumber == 0)
		[(MyPDFKitView *)[pdfKitWindow activeView] setIndexForMark: (initialFirstPage - 1)];
	else
		[(MyPDFKitView *)[pdfKitWindow activeView] setIndexForMark: (initialSecondPage - 1)];
	[(MyPDFKitView *)[pdfKitWindow activeView] setBoundsForMark: myOval];
	[(MyPDFKitView *)[pdfKitWindow activeView] setDrawMark: YES];
	[[pdfKitWindow activeView] goToPage: thePage];
	
	[[pdfKitWindow activeView] goToPage: thePage];
	[[pdfKitWindow activeView] setCurrentSelection: theSelection];

	[[pdfKitWindow activeView] scrollSelectionToVisible:self];
	[[pdfKitWindow activeView] setCurrentSelection: nil];
	[[pdfKitWindow activeView] display];
	
	[pdfKitWindow makeKeyAndOrderFront:self];

	return YES;
	
/* 
	// This section, commented out, provides a fascinating illustration of the output of synctex. When syncing from source to preview, 
	// synctex outputs a series of rectangles, from four or five to thirty or more. The code below draws each of these rectangles,
	// one after the other. The rectangles flash by fairly rapidly, but it is  possible to get a feeling for their information and
	// how typesetting produces them one by one.


	i = 0;
	while (i < boxNumber) {
		
	thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[i] - 1)];
	pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
	
		Param = 65536; 
	myOval.size.height = HNumber[i] / Param + 10; myOval.size.width = WNumber[i]/ Param + 10;
	myOval.origin.x = hNumber[i] / Param - 5; myOval.origin.y = pageSize.size.height - vNumber[i]/ Param - 5;
	
	[myPDFKitView setIndexForMark: (pageNumber[i] - 1)];
	[myPDFKitView setBoundsForMark: myOval];
	[myPDFKitView setDrawMark: YES];
	[myPDFKitView goToPage: thePage];
	[pdfWindow display];
	
	i++;
	}

*/

	return YES;
			
}

/* The code below is the original 2008 version. But it is modified to call "synctex" embedded in the program, rather than the a version in TeX Live.
 This is important because the 2008 and 2009 versions of synctex are different. This program uses the 2008 version. The Intel portion has been modified
 to return additional information, "Magnification", so this code tests if that additional information is present.
 
 We now experiment by calling the 2010 version of the code. For original 2008, see further below, a routine renamed with extra OLD
 */


- (BOOL)doPreviewSyncTeXWithFilenameEXPERIMENT:(NSString *)fileName andLine:(int)line andCharacterIndex:(unsigned int)idx andTextView:(id)aTextView;
{
	NSDate          *myDate;
	NSString		*enginePath;
	NSString		*mainSourceString;
	NSString		*inputString;
	NSString		*pdfPreviewString;
	NSString		*lineString;
	NSString		*indexString;
	NSString		*fileString;
	NSNumber		*lineNumber, *indexNumber;
	NSMutableArray	*args;
	NSRange			myRange;
	NSRange			range1, range2;
	NSString		*paramString;
	int				pageNumber[200];
	float			hNumber[200], vNumber[200], WNumber[200], HNumber[200], xNumber[200], yNumber[200];
	NSString		*theText[200];
	NSRange			theRanges[200];
	BOOL			firstPage[200];
	int				initialFirstPage;
	int				boxNumber;
	float			Param;
	unsigned		startIndex, lineEndIndex, contentsEndIndex;
	NSRect			myOval;
	PDFPage			*thePage;
	int				i;
	NSString		*pageString;
	NSPoint			aPoint;
	int				theNumber, theLocation;
	NSRange			theRange;
	NSRange			myLineRange;
	NSString		*sourceLineString;
	TSDocument		*newDocument;
	int				searchIndex;
	PDFSelection	*theSelection;
	NSRect			anotherRect, pageSize;
	NSString		*myFileName, *mySyncTeXFileName, *mySyncTeX;
	float			magnification;
	float			xoffset, yoffset;
	
	Param = 1.0;
	// return NO;  // temporarily use Search synchronization
	
	// THIS IS ACTIVE
	
	
	myFileName = [self fileName];
	if (! myFileName)
		return NO;
	mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex"];
	if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
	{ 
		mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex.gz"];
		if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
			return NO;
	}
	mySyncTeX = [[SUD stringForKey:TetexBinPath] stringByAppendingPathComponent: @"synctex"];
	if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeX])
	{
		return NO;
	} 
	
	
	/* First, get the synctex information */
	// GET SYNCTEX INFO	
	
	
	if (synctexTask != nil) {
		[synctexTask terminate];
		myDate = [NSDate date];
		while (([synctexTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
		[synctexTask release];
		[synctexPipe release];
		synctexTask = nil;
		synctexPipe = nil;
	}
	
	synctexTask = [[NSTask alloc] init];
	mainSourceString = [self fileName]; // note: this will be the root document when the doPeviewSyncTeXWithFilename is called
	[synctexTask setCurrentDirectoryPath: [mainSourceString stringByDeletingLastPathComponent]];
	synctexPipe = [[NSPipe pipe] retain];
	synctexHandle = [synctexPipe fileHandleForReading];
	[synctexTask setStandardOutput: synctexPipe];
	enginePath = [[NSBundle mainBundle] pathForResource:@"synctex_2010" ofType:nil];
	// enginePath = [[NSBundle mainBundle] pathForResource:@"synctexviewwrap" ofType:nil];
	[synctexTask setLaunchPath:enginePath];
	
	args = [NSMutableArray array];
	
	[args addObject: @"view"];
	[args addObject: @"-i"];
	
	
	
	lineNumber = [NSNumber numberWithInt: line];
	indexNumber = [NSNumber numberWithInt: idx];
	
	lineString = [lineNumber stringValue];
	indexString = [indexNumber stringValue];
	if (fileName == nil)
		fileString = [[self fileName] lastPathComponent];
	else {
		NSString *initialPart = [[[self fileName] stringByStandardizingPath] stringByDeletingLastPathComponent]; //get root complete path, minus root name
		initialPart = [initialPart stringByAppendingString:@"/"];
		myRange = [fileName rangeOfString: initialPart options:NSCaseInsensitiveSearch]; //see if this forms the first part of the source file's path
		if ((myRange.location == 0) && (myRange.length <= [fileName length])) {
			fileString = [fileName substringFromIndex: myRange.length]; //and remove it, so we have a relative path from root
		}
		else
			return NO;
	}
	
	pdfPreviewString = [[mainSourceString stringByDeletingPathExtension] stringByAppendingPathExtension: @"pdf"]; 
	
	inputString = [[[[lineString stringByAppendingString:@":"] stringByAppendingString: indexString] stringByAppendingString:@":"] stringByAppendingString: fileString]; 
	
	[args addObject: inputString];
	[args addObject: @"-o"];
	[args addObject: pdfPreviewString];
	
	
	
	
	[synctexTask setArguments:args];
	[synctexTask launch];
	
	
	
	
	NSData *myData = [synctexHandle readDataToEndOfFile];
	NSString *outputString = [[NSString alloc] initWithData: myData encoding: NSASCIIStringEncoding];
	
	if (synctexTask != nil) {
		[synctexTask terminate];
		myDate = [NSDate date];
		while (([synctexTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
		[synctexTask release];
		[synctexPipe release];
		synctexTask = nil;
		synctexPipe = nil;
	}
	
	NSLog(outputString);
	
	
	
	/* Next, digest this information */
	// DIGEST SYNCTEX INFO	
	
	
	range1 =  [outputString rangeOfString:@"SyncTeX result begin"];
	if (range1.location == NSNotFound)
		return NO;
	outputString = [outputString substringFromIndex: (range1.location + 20)];
	
	
	// BEGIN ADDITIONS
	range1 = [outputString rangeOfString: @"Magnification:"];
	if (range1.location == NSNotFound) {
		
		magnification = 1;
		xoffset = 0;
		yoffset = 0;
	}
	
	else {
		// range1 = [outputString rangeOfString: @"Magnification:"];
		// if (range1.location == NSNotFound)
		// 	return NO;
		
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 14;
		range2.length = lineEndIndex - startIndex - 14;
		paramString = [outputString substringWithRange: range2];
		magnification = [paramString floatValue];
		// NSLog(@"%f", magnification);
		magnification = magnification / .0000152018;
		// NSLog(paramString);
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"XOffset:"];
		if (range1.location == NSNotFound)
			return NO;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 8;
		range2.length = lineEndIndex - startIndex - 8;
		paramString = [outputString substringWithRange: range2];
		// NSLog(paramString);
		xoffset = [paramString intValue];
		// NSLog(@"%f", xoffset);
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"YOffset:"];
		if (range1.location == NSNotFound)
			return NO;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 8;
		range2.length = lineEndIndex - startIndex - 8;
		paramString = [outputString substringWithRange: range2];
		// NSLog(paramString);
		yoffset = [paramString intValue];
		// NSLog(@"%f", yoffset);
		outputString = [outputString substringFromIndex: lineEndIndex];
		xoffset = xoffset * 65536;
		yoffset = yoffset * 65536;
		// NSLog([NSString stringWithFormat:@"xoffset %d", xoffset]);
		
		// NSLog(@"yes, here");
		// NSLog(@"%f", magnification);
		// NSLog(@"%f", xoffset);
		// NSLog(@"%f", yoffset);
		// magnification = 1;
		// xoffset = 0;
		// yoffset = 0;
		
	}
	
	
	boxNumber = 0;
	
	while (boxNumber < 200) {
		
		range1 = [outputString rangeOfString:@"Page:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 5;
		range2.length = lineEndIndex - startIndex - 5;
		paramString = [outputString substringWithRange: range2];
		pageNumber[boxNumber] = [paramString intValue];
		if (boxNumber == 0)
			initialFirstPage = pageNumber[boxNumber];
		if (pageNumber[boxNumber] == initialFirstPage)
			firstPage[boxNumber] = YES;
		else
			firstPage[boxNumber] = NO;
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"x:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		xNumber[boxNumber] = [paramString floatValue]; //[paramString intValue] * magnification + xoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"y:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		yNumber[boxNumber] = [paramString floatValue]; //[paramString intValue] * magnification + yoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"h:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		hNumber[boxNumber] = [paramString floatValue];// [paramString intValue] * magnification + xoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"v:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		vNumber[boxNumber] = [paramString floatValue];//[paramString intValue] * magnification + yoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"W:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		WNumber[boxNumber] = [paramString floatValue];// [paramString intValue] * magnification;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"H:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		HNumber[boxNumber] = [paramString floatValue];// [paramString intValue] * magnification;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		boxNumber++;
	}
	
	if (boxNumber == 0)
		return NO;
	
	
	
	/* Next, get the text inside these various boxes and under the "index point" */
	
	
	
	i = 0;
	while (i < boxNumber) {
		thePage = [[[pdfKitWindow activeView] document] pageAtIndex: (pageNumber[i] - 1)];
		pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
		
		 // Param = 65536;
		aPoint.x = xNumber[i]/Param;
		// aPoint.x = xNumber[i]; in version 1.2
		aPoint.y = pageSize.size.height - yNumber[i]/Param;
		//aPoint.y = pageSize.size.height - yNumber[i]; in version 1.2
		theNumber = [thePage characterIndexAtPoint:aPoint];
		pageString = [thePage string];
		theLocation = theNumber - 2;
		if (theLocation < 0)
			theLocation = 0;
		theRange.location = theLocation;
		if ((theLocation + 5) < [pageString length])
			theRange.length = 5;
		else
			theRange.length = [pageString length] - theLocation;
		theRanges[i] = theRange;
		theText[i] = [pageString substringWithRange:theRange];
		
		i++;
	}
	
	
	/* Next get the text where the mouse was clicked and see if that text is inside one of these boxes.
	 If so, declare victory. */
	
	
	
	if (fileName == nil)
		newDocument = self;
	else {
		id newURL = [NSURL fileURLWithPath: fileName];
		newDocument = [[TSDocumentController sharedDocumentController] documentForURL:newURL];
	}
	if (newDocument == nil)
		return NO;
	myLineRange = [newDocument lineRange: line];
	sourceLineString = [[aTextView string] substringWithRange: myLineRange];
	// NSLog(sourceLineString);
	searchIndex = idx - myLineRange.location;
	
	i = 0;
	while (i < boxNumber) {
		theRange = [sourceLineString rangeOfString: theText[i]];
		if ((theRange.location != NSNotFound) && (theRange.location <= (searchIndex + 5)) && (searchIndex < (theRange.location + theRange.length + 5))) {
			
			thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[i] - 1)];
			theSelection = [thePage selectionForRange: theRanges[i]];
			myOval = [theSelection boundsForPage:thePage];
			pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
			//Param = 65536;
			[(MyPDFKitView *)[pdfKitWindow activeView] setIndexForMark: (pageNumber[i] - 1)];
			[(MyPDFKitView *)[pdfKitWindow activeView] setBoundsForMark: myOval];
			[(MyPDFKitView *)[pdfKitWindow activeView] setDrawMark: YES];
			[[pdfKitWindow activeView] goToPage: thePage];
			[[pdfKitWindow activeView] setCurrentSelection: theSelection];
			[[pdfKitWindow activeView] scrollSelectionToVisible:self];
			[[pdfKitWindow activeView] setCurrentSelection: nil];
			[[pdfKitWindow activeView] display];
			[pdfKitWindow makeKeyAndOrderFront:self]; 
			
			return YES;
		}
		i++;
	}
	
	
	
	/* In case of failure, guess the full box where the text occurs. */
	
	
	thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[0] - 1)];
	pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
	
	
	 // Param = 65536;
	myOval.size.height = HNumber[0] / Param + 10; myOval.size.width = WNumber[0]/ Param + 10;
	myOval.origin.x = hNumber[0] / Param - 5; myOval.origin.y = pageSize.size.height - vNumber[0]/ Param - 5;
	
	theSelection = [thePage selectionForRange: theRanges[0]];
	i = 1;
	while (i < boxNumber) {
		if (firstPage[i]) {
			anotherRect.size.height = HNumber[i] / Param + 10; anotherRect.size.width = WNumber[i]/ Param + 10;
			anotherRect.origin.x = hNumber[i] / Param - 5; anotherRect.origin.y = pageSize.size.height - vNumber[i]/ Param - 5;
			if (NSIntersectsRect(myOval, anotherRect))
				myOval = NSUnionRect(myOval, anotherRect);
		}
		i++;
	}
	
	[(MyPDFKitView *)[pdfKitWindow activeView] setIndexForMark: (initialFirstPage - 1)];
	[(MyPDFKitView *)[pdfKitWindow activeView] setBoundsForMark: myOval];
	[(MyPDFKitView *)[pdfKitWindow activeView] setDrawMark: YES];
	[[pdfKitWindow activeView] goToPage: thePage];
	
	[[pdfKitWindow activeView] goToPage: thePage];
	[[pdfKitWindow activeView] setCurrentSelection: theSelection];
	
	[[pdfKitWindow activeView] scrollSelectionToVisible:self];
	[[pdfKitWindow activeView] setCurrentSelection: nil];
	[[pdfKitWindow activeView] display];
	
	[pdfKitWindow makeKeyAndOrderFront:self];
	
	return YES;
	
	
	return YES;
	
}





/* The code below is the original 2008 version. But it is modified to call "synctex" embedded in the program, rather than the a version in TeX Live.
 This is important because the 2008 and 2009 versions of synctex are different. This program uses the 2008 version. The Intel portion has been modified
 to return additional information, "Magnification", so this code tests if that additional information is present.
*/

/*
- (BOOL)doPreviewSyncTeXWithFilename:(NSString *)fileName andLine:(int)line andCharacterIndex:(unsigned int)idx andTextView:(id)aTextView;
{
	NSDate          *myDate;
	NSString		*enginePath;
	NSString		*mainSourceString;
	NSString		*inputString;
	NSString		*pdfPreviewString;
	NSString		*lineString;
	NSString		*indexString;
	NSString		*fileString;
	NSNumber		*lineNumber, *indexNumber;
	NSMutableArray	*args;
	NSRange			myRange;
	NSRange			range1, range2;
	NSString		*paramString;
	int				pageNumber[200];
	float			hNumber[200], vNumber[200], WNumber[200], HNumber[200], xNumber[200], yNumber[200];
	NSString		*theText[200];
	NSRange			theRanges[200];
	BOOL			firstPage[200];
	int				initialFirstPage;
	int				boxNumber;
	float			Param;
	unsigned		startIndex, lineEndIndex, contentsEndIndex;
	NSRect			myOval;
	PDFPage			*thePage;
	int				i;
	NSString		*pageString;
	NSPoint			aPoint;
	int				theNumber, theLocation;
	NSRange			theRange;
	NSRange			myLineRange;
	NSString		*sourceLineString;
	TSDocument		*newDocument;
	int				searchIndex;
	PDFSelection	*theSelection;
	NSRect			anotherRect, pageSize;
	NSString		*myFileName, *mySyncTeXFileName, *mySyncTeX;
	float			magnification;
	float			xoffset, yoffset;

	
	// return NO;  // temporarily use Search synchronization
	
	// THIS IS ACTIVE

	
	myFileName = [self fileName];
	if (! myFileName)
		return NO;
	mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex"];
	if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
	{ 
		mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex.gz"];
		if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
			return NO;
	}
	mySyncTeX = [[SUD stringForKey:TetexBinPath] stringByAppendingPathComponent: @"synctex"];
	if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeX])
	{
		return NO;
	} 
	
	
	// First, get the synctex information 
// GET SYNCTEX INFO	
	
	
	if (synctexTask != nil) {
		[synctexTask terminate];
		myDate = [NSDate date];
		while (([synctexTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
		[synctexTask release];
		[synctexPipe release];
		synctexTask = nil;
		synctexPipe = nil;
	}
	
	synctexTask = [[NSTask alloc] init];
	mainSourceString = [self fileName]; // note: this will be the root document when the doPeviewSyncTeXWithFilename is called
	[synctexTask setCurrentDirectoryPath: [mainSourceString stringByDeletingLastPathComponent]];
	synctexPipe = [[NSPipe pipe] retain];
	synctexHandle = [synctexPipe fileHandleForReading];
	[synctexTask setStandardOutput: synctexPipe];
	enginePath = [[NSBundle mainBundle] pathForResource:@"synctex" ofType:nil];
	// enginePath = [[NSBundle mainBundle] pathForResource:@"synctexviewwrap" ofType:nil];
	[synctexTask setLaunchPath:enginePath];
	
	args = [NSMutableArray array];
	
	[args addObject: @"view"];
	[args addObject: @"-i"];
	
	
	
	lineNumber = [NSNumber numberWithInt: line];
	indexNumber = [NSNumber numberWithInt: idx];
	
	lineString = [lineNumber stringValue];
	indexString = [indexNumber stringValue];
	if (fileName == nil)
		fileString = [[self fileName] lastPathComponent];
	else {
		NSString *initialPart = [[[self fileName] stringByStandardizingPath] stringByDeletingLastPathComponent]; //get root complete path, minus root name
		initialPart = [initialPart stringByAppendingString:@"/"];
		myRange = [fileName rangeOfString: initialPart options:NSCaseInsensitiveSearch]; //see if this forms the first part of the source file's path
		if ((myRange.location == 0) && (myRange.length <= [fileName length])) {
			fileString = [fileName substringFromIndex: myRange.length]; //and remove it, so we have a relative path from root
		}
		else
			return NO;
	}
	
	pdfPreviewString = [[mainSourceString stringByDeletingPathExtension] stringByAppendingPathExtension: @"pdf"]; 
	
	inputString = [[[[lineString stringByAppendingString:@":"] stringByAppendingString: indexString] stringByAppendingString:@":"] stringByAppendingString: fileString]; 
	
	[args addObject: inputString];
	[args addObject: @"-o"];
	[args addObject: pdfPreviewString];
	
	
	
	
	[synctexTask setArguments:args];
	[synctexTask launch];
	
	
	
	
	NSData *myData = [synctexHandle readDataToEndOfFile];
	NSString *outputString = [[NSString alloc] initWithData: myData encoding: NSASCIIStringEncoding];
	
	if (synctexTask != nil) {
		[synctexTask terminate];
		myDate = [NSDate date];
		while (([synctexTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
		[synctexTask release];
		[synctexPipe release];
		synctexTask = nil;
		synctexPipe = nil;
	}
	
	// NSLog(outputString);
	
	
	
	// Next, digest this information 
// DIGEST SYNCTEX INFO	
	
	
	range1 =  [outputString rangeOfString:@"SyncTeX result begin"];
	if (range1.location == NSNotFound)
		return NO;
	outputString = [outputString substringFromIndex: (range1.location + 20)];
	

// BEGIN ADDITIONS
	range1 = [outputString rangeOfString: @"Magnification:"];
	if (range1.location == NSNotFound) {
		
		magnification = 1;
		xoffset = 0;
		yoffset = 0;
	}
	
	else {
		// range1 = [outputString rangeOfString: @"Magnification:"];
		// if (range1.location == NSNotFound)
		// 	return NO;
		
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 14;
		range2.length = lineEndIndex - startIndex - 14;
		paramString = [outputString substringWithRange: range2];
		magnification = [paramString floatValue];
		// NSLog(@"%f", magnification);
		magnification = magnification / .0000152018;
		// NSLog(paramString);
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"XOffset:"];
		if (range1.location == NSNotFound)
			return NO;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 8;
		range2.length = lineEndIndex - startIndex - 8;
		paramString = [outputString substringWithRange: range2];
		// NSLog(paramString);
		xoffset = [paramString intValue];
		// NSLog(@"%f", xoffset);
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"YOffset:"];
		if (range1.location == NSNotFound)
			return NO;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 8;
		range2.length = lineEndIndex - startIndex - 8;
		paramString = [outputString substringWithRange: range2];
		// NSLog(paramString);
		yoffset = [paramString intValue];
		// NSLog(@"%f", yoffset);
		outputString = [outputString substringFromIndex: lineEndIndex];
		xoffset = xoffset * 65536;
		yoffset = yoffset * 65536;
		// NSLog([NSString stringWithFormat:@"xoffset %d", xoffset]);
		
		// NSLog(@"yes, here");
		// NSLog(@"%f", magnification);
		// NSLog(@"%f", xoffset);
		// NSLog(@"%f", yoffset);
		// magnification = 1;
		// xoffset = 0;
		// yoffset = 0;
		
	}
	
	
	boxNumber = 0;
	
	while (boxNumber < 200) {
		
		range1 = [outputString rangeOfString:@"Page:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 5;
		range2.length = lineEndIndex - startIndex - 5;
		paramString = [outputString substringWithRange: range2];
		pageNumber[boxNumber] = [paramString intValue];
		if (boxNumber == 0)
			initialFirstPage = pageNumber[boxNumber];
		if (pageNumber[boxNumber] == initialFirstPage)
			firstPage[boxNumber] = YES;
		else
			firstPage[boxNumber] = NO;
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"x:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		xNumber[boxNumber] = [paramString intValue] * magnification + xoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"y:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		yNumber[boxNumber] = [paramString intValue] * magnification + yoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"h:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		hNumber[boxNumber] = [paramString intValue] * magnification + xoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"v:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		vNumber[boxNumber] = [paramString intValue] * magnification + yoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"W:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		WNumber[boxNumber] = [paramString intValue] * magnification;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"H:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		HNumber[boxNumber] = [paramString intValue] * magnification;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		boxNumber++;
	}
	
	if (boxNumber == 0)
		return NO;
	
	
	
	// Next, get the text inside these various boxes and under the "index point" 
	
	
	
	i = 0;
	while (i < boxNumber) {
		thePage = [[[pdfKitWindow activeView] document] pageAtIndex: (pageNumber[i] - 1)];
		pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
		
		Param = 65536;
		aPoint.x = xNumber[i]/Param;
		// aPoint.x = xNumber[i]; in version 1.2
		aPoint.y = pageSize.size.height - yNumber[i]/Param;
		//aPoint.y = pageSize.size.height - yNumber[i]; in version 1.2
		theNumber = [thePage characterIndexAtPoint:aPoint];
		pageString = [thePage string];
		theLocation = theNumber - 2;
		if (theLocation < 0)
			theLocation = 0;
		theRange.location = theLocation;
		if ((theLocation + 5) < [pageString length])
			theRange.length = 5;
		else
			theRange.length = [pageString length] - theLocation;
		theRanges[i] = theRange;
		theText[i] = [pageString substringWithRange:theRange];
		
		i++;
	}
	
	
	// Next get the text where the mouse was clicked and see if that text is inside one of these boxes.
	// If so, declare victory. 
	
	
	
	if (fileName == nil)
		newDocument = self;
	else {
		id newURL = [NSURL fileURLWithPath: fileName];
		newDocument = [[TSDocumentController sharedDocumentController] documentForURL:newURL];
	}
	if (newDocument == nil)
		return NO;
	myLineRange = [newDocument lineRange: line];
	sourceLineString = [[aTextView string] substringWithRange: myLineRange];
	// NSLog(sourceLineString);
	searchIndex = idx - myLineRange.location;
	
	i = 0;
	while (i < boxNumber) {
		theRange = [sourceLineString rangeOfString: theText[i]];
		if ((theRange.location != NSNotFound) && (theRange.location <= (searchIndex + 5)) && (searchIndex < (theRange.location + theRange.length + 5))) {
			
			thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[i] - 1)];
			theSelection = [thePage selectionForRange: theRanges[i]];
			myOval = [theSelection boundsForPage:thePage];
			pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
			Param = 65536;
			[(MyPDFKitView *)[pdfKitWindow activeView] setIndexForMark: (pageNumber[i] - 1)];
			[(MyPDFKitView *)[pdfKitWindow activeView] setBoundsForMark: myOval];
			[(MyPDFKitView *)[pdfKitWindow activeView] setDrawMark: YES];
			[[pdfKitWindow activeView] goToPage: thePage];
			[[pdfKitWindow activeView] setCurrentSelection: theSelection];
			[[pdfKitWindow activeView] scrollSelectionToVisible:self];
			[[pdfKitWindow activeView] setCurrentSelection: nil];
			[[pdfKitWindow activeView] display];
			[pdfKitWindow makeKeyAndOrderFront:self]; 
			
			return YES;
		}
		i++;
	}
	
	
	
	// In case of failure, guess the full box where the text occurs. 
	
	
	thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[0] - 1)];
	pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
	
	
	Param = 65536;
	myOval.size.height = HNumber[0] / Param + 10; myOval.size.width = WNumber[0]/ Param + 10;
	myOval.origin.x = hNumber[0] / Param - 5; myOval.origin.y = pageSize.size.height - vNumber[0]/ Param - 5;
	
	theSelection = [thePage selectionForRange: theRanges[0]];
	i = 1;
	while (i < boxNumber) {
		if (firstPage[i]) {
			anotherRect.size.height = HNumber[i] / Param + 10; anotherRect.size.width = WNumber[i]/ Param + 10;
			anotherRect.origin.x = hNumber[i] / Param - 5; anotherRect.origin.y = pageSize.size.height - vNumber[i]/ Param - 5;
			if (NSIntersectsRect(myOval, anotherRect))
				myOval = NSUnionRect(myOval, anotherRect);
		}
		i++;
	}
	
	[(MyPDFKitView *)[pdfKitWindow activeView] setIndexForMark: (initialFirstPage - 1)];
	[(MyPDFKitView *)[pdfKitWindow activeView] setBoundsForMark: myOval];
	[(MyPDFKitView *)[pdfKitWindow activeView] setDrawMark: YES];
	[[pdfKitWindow activeView] goToPage: thePage];
	
	[[pdfKitWindow activeView] goToPage: thePage];
	[[pdfKitWindow activeView] setCurrentSelection: theSelection];
	
	[[pdfKitWindow activeView] scrollSelectionToVisible:self];
	[[pdfKitWindow activeView] setCurrentSelection: nil];
	[[pdfKitWindow activeView] display];
	
	[pdfKitWindow makeKeyAndOrderFront:self];
	
	return YES;
	
	
	return YES;
	
}

*/

- (BOOL)doPreviewSyncTeXWithFilename:(NSString *)fileName andLine:(int)line andCharacterIndex:(unsigned int)idx andTextView:(id)aTextView;
{
	NSDate          *myDate;
	NSString		*enginePath;
	NSString		*mainSourceString;
	NSString		*inputString;
	NSString		*pdfPreviewString;
	NSString		*lineString;
	NSString		*indexString;
	NSString		*fileString;
	NSNumber		*lineNumber, *indexNumber;
	NSMutableArray	*args;
	NSRange			myRange;
	NSRange			range1, range2;
	NSString		*paramString;
	int				pageNumber[200];
	float			hNumber[200], vNumber[200], WNumber[200], HNumber[200], xNumber[200], yNumber[200];
	NSString		*theText[200];
	NSRange			theRanges[200];
	BOOL			firstPage[200];
	int				initialFirstPage;
	int				boxNumber;
	float			Param;
	unsigned		startIndex, lineEndIndex, contentsEndIndex;
	NSRect			myOval;
	PDFPage			*thePage;
	int				i;
	NSString		*pageString;
	NSPoint			aPoint;
	int				theNumber, theLocation;
	NSRange			theRange;
	NSRange			myLineRange;
	NSString		*sourceLineString;
	TSDocument		*newDocument;
	int				searchIndex;
	PDFSelection	*theSelection;
	NSRect			anotherRect, pageSize;
	NSString		*mySyncTeXFileName, *mySyncTeX;
	float			magnification;
	float			xoffset, yoffset;
	const char		*name;
	NSString		*theName;
	NSString		*theFullName, *aName;
	NSString		*pathString;
	NSString		*rootFile, *rootPath, *theFile;
	float			x, y, h, v, width, height;
	
	
	// THIS IS ACTIVE
	
	rootFile = [self fileName]; // root document
	rootPath = [rootFile stringByDeletingLastPathComponent]; //path to root document
	
	if (fileName == NULL)
		theFile = rootFile;
	else 
		theFile = fileName; //file we want to sync; this is always a full path

	// NSLog(@"Using New Source->Output Sync");
	if (! rootFile)
		return NO;
	mySyncTeXFileName = [[rootFile stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex"];
	
	if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
	{ 
		mySyncTeXFileName = [[rootFile stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex.gz"];
		if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
			return NO;
	}
	
	if (scanner == NULL)
		return NO;
	
	synctex_node_t node = synctex_scanner_input(scanner);
	BOOL found = NO;
	while (node != NULL) {
		name = synctex_scanner_get_name(scanner, synctex_node_tag(node));
		theName = [NSString stringWithCString:name encoding: NSUTF8StringEncoding];
		theFullName = [theName stringByStandardizingPath];
		
		if ([theFile isEqualToString: theFullName]) {
			found = YES;
			break;
			}
		
		theFullName = [[rootPath stringByAppendingPathComponent: theName] stringByStandardizingPath];
		if ([theFile isEqualToString: theFullName]) {
			found = YES;
			break;
			}
		node = synctex_node_sibling(node);
	}
	
	if (! found) {
		NSLog(@"Nope, Couldn't Find File");
		return NO;
	}
	
	boxNumber = 0;
	
	if (synctex_display_query(scanner, name, line, 0) > 0) {
		int page = -1;
		BOOL gotSomething = NO;
		
		
		while (((node = synctex_next_result(scanner)) != NULL) && (boxNumber < 200)) {
			if (page == -1) {
				page = synctex_node_page(node);
				thePage = [[myPDFKitView document] pageAtIndex: (page - 1)];
				pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
				}
			if (synctex_node_page(node) != page)
				continue;
			gotSomething = YES;
			// x = synctex_node_box_visible_x(node);
			// y = synctex_node_box_visible_y(node);
			x = 0; y = 0;
			h = synctex_node_box_visible_h(node);
			v = synctex_node_box_visible_v(node) - synctex_node_box_visible_height(node);
			width = synctex_node_box_visible_width(node);
			height = synctex_node_box_visible_height(node) + synctex_node_box_visible_depth(node);
			
			myOval.size.height = HNumber[0]; 
			myOval.size.width = WNumber[0];
			myOval.origin.x = hNumber[0]; 
			myOval.origin.y = pageSize.size.height - vNumber[0] - myOval.size.height; //vNumber[0]; //pageSize.size.height - vNumber[0] - myOval.size.height;

			// The equations below define a rectangle, with origin (hNumber, vNumber) and size (WNumber, HNumber)
			
			hNumber[boxNumber] = h;
			vNumber[boxNumber] = pageSize.size.height - v - height; // v;
			WNumber[boxNumber] = width;
			HNumber[boxNumber] = height;
			pageNumber[boxNumber] = page;
			firstPage[boxNumber] = YES;
			boxNumber++;
			
		}
		
	}
	
	if (boxNumber == 0)
		return NO;
	
	[(MyPDFKitView *)[pdfKitWindow activeView] setNumberSyncRect:boxNumber];
	
	i = 0;
	while (i < boxNumber) {
		[(MyPDFKitView *)[pdfKitWindow activeView] setSyncRect: i originX: hNumber[i] originY: vNumber[i] width: WNumber[i] height: HNumber[i]]; 
		i++;
	}
	

		
		
		
/*
	// First, get the synctex information 
	// GET SYNCTEX INFO	
	
	
	if (synctexTask != nil) {
		[synctexTask terminate];
		myDate = [NSDate date];
		while (([synctexTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
		[synctexTask release];
		[synctexPipe release];
		synctexTask = nil;
		synctexPipe = nil;
	}
	
	synctexTask = [[NSTask alloc] init];
	mainSourceString = [self fileName]; // note: this will be the root document when the doPeviewSyncTeXWithFilename is called
	[synctexTask setCurrentDirectoryPath: [mainSourceString stringByDeletingLastPathComponent]];
	synctexPipe = [[NSPipe pipe] retain];
	synctexHandle = [synctexPipe fileHandleForReading];
	[synctexTask setStandardOutput: synctexPipe];
	enginePath = [[NSBundle mainBundle] pathForResource:@"synctex" ofType:nil];
	// enginePath = [[NSBundle mainBundle] pathForResource:@"synctexviewwrap" ofType:nil];
	[synctexTask setLaunchPath:enginePath];
	
	args = [NSMutableArray array];
	
	[args addObject: @"view"];
	[args addObject: @"-i"];
	
	
	
	lineNumber = [NSNumber numberWithInt: line];
	indexNumber = [NSNumber numberWithInt: idx];
	
	lineString = [lineNumber stringValue];
	indexString = [indexNumber stringValue];
	if (fileName == nil)
		fileString = [[self fileName] lastPathComponent];
	else {
		NSString *initialPart = [[[self fileName] stringByStandardizingPath] stringByDeletingLastPathComponent]; //get root complete path, minus root name
		initialPart = [initialPart stringByAppendingString:@"/"];
		myRange = [fileName rangeOfString: initialPart options:NSCaseInsensitiveSearch]; //see if this forms the first part of the source file's path
		if ((myRange.location == 0) && (myRange.length <= [fileName length])) {
			fileString = [fileName substringFromIndex: myRange.length]; //and remove it, so we have a relative path from root
		}
		else
			return NO;
	}
	
	pdfPreviewString = [[mainSourceString stringByDeletingPathExtension] stringByAppendingPathExtension: @"pdf"]; 
	
	inputString = [[[[lineString stringByAppendingString:@":"] stringByAppendingString: indexString] stringByAppendingString:@":"] stringByAppendingString: fileString]; 
	
	[args addObject: inputString];
	[args addObject: @"-o"];
	[args addObject: pdfPreviewString];
	
	
	
	
	[synctexTask setArguments:args];
	[synctexTask launch];
	
	
	
	
	NSData *myData = [synctexHandle readDataToEndOfFile];
	NSString *outputString = [[NSString alloc] initWithData: myData encoding: NSASCIIStringEncoding];
	
	if (synctexTask != nil) {
		[synctexTask terminate];
		myDate = [NSDate date];
		while (([synctexTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
		[synctexTask release];
		[synctexPipe release];
		synctexTask = nil;
		synctexPipe = nil;
	}
	
	// NSLog(outputString);
	
	
	
	// Next, digest this information 
	// DIGEST SYNCTEX INFO	
	
	
	range1 =  [outputString rangeOfString:@"SyncTeX result begin"];
	if (range1.location == NSNotFound)
		return NO;
	outputString = [outputString substringFromIndex: (range1.location + 20)];
	
	
	// BEGIN ADDITIONS
	range1 = [outputString rangeOfString: @"Magnification:"];
	if (range1.location == NSNotFound) {
		
		magnification = 1;
		xoffset = 0;
		yoffset = 0;
	}
	
	else {
		// range1 = [outputString rangeOfString: @"Magnification:"];
		// if (range1.location == NSNotFound)
		// 	return NO;
		
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 14;
		range2.length = lineEndIndex - startIndex - 14;
		paramString = [outputString substringWithRange: range2];
		magnification = [paramString floatValue];
		// NSLog(@"%f", magnification);
		magnification = magnification / .0000152018;
		// NSLog(paramString);
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"XOffset:"];
		if (range1.location == NSNotFound)
			return NO;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 8;
		range2.length = lineEndIndex - startIndex - 8;
		paramString = [outputString substringWithRange: range2];
		// NSLog(paramString);
		xoffset = [paramString intValue];
		// NSLog(@"%f", xoffset);
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"YOffset:"];
		if (range1.location == NSNotFound)
			return NO;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 8;
		range2.length = lineEndIndex - startIndex - 8;
		paramString = [outputString substringWithRange: range2];
		// NSLog(paramString);
		yoffset = [paramString intValue];
		// NSLog(@"%f", yoffset);
		outputString = [outputString substringFromIndex: lineEndIndex];
		xoffset = xoffset * 65536;
		yoffset = yoffset * 65536;
		// NSLog([NSString stringWithFormat:@"xoffset %d", xoffset]);
		
		// NSLog(@"yes, here");
		// NSLog(@"%f", magnification);
		// NSLog(@"%f", xoffset);
		// NSLog(@"%f", yoffset);
		// magnification = 1;
		// xoffset = 0;
		// yoffset = 0;
		
	}
 
 */
	
/*	
	boxNumber = 0;
	
	while (boxNumber < 200) {
		
		range1 = [outputString rangeOfString:@"Page:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 5;
		range2.length = lineEndIndex - startIndex - 5;
		paramString = [outputString substringWithRange: range2];
		pageNumber[boxNumber] = [paramString intValue];
		if (boxNumber == 0)
			initialFirstPage = pageNumber[boxNumber];
		if (pageNumber[boxNumber] == initialFirstPage)
			firstPage[boxNumber] = YES;
		else
			firstPage[boxNumber] = NO;
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"x:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		xNumber[boxNumber] = [paramString intValue] * magnification + xoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"y:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		yNumber[boxNumber] = [paramString intValue] * magnification + yoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"h:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		hNumber[boxNumber] = [paramString intValue] * magnification + xoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"v:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		vNumber[boxNumber] = [paramString intValue] * magnification + yoffset;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"W:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		WNumber[boxNumber] = [paramString intValue] * magnification;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"H:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		HNumber[boxNumber] = [paramString intValue] * magnification;	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		boxNumber++;
	}
	
	if (boxNumber == 0)
		return NO;
	
*/	
	
	// Next, get the text inside these various boxes and under the "index point" 
	
	
/*	
	i = 0;
	while (i < boxNumber) {
		thePage = [[[pdfKitWindow activeView] document] pageAtIndex: (pageNumber[i] - 1)];
		pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
		
		Param = 65536;
		aPoint.x = xNumber[i]/Param;
		// aPoint.x = xNumber[i]; in version 1.2
		aPoint.y = pageSize.size.height - yNumber[i]/Param;
		//aPoint.y = pageSize.size.height - yNumber[i]; in version 1.2
		theNumber = [thePage characterIndexAtPoint:aPoint];
		pageString = [thePage string];
		theLocation = theNumber - 2;
		if (theLocation < 0)
			theLocation = 0;
		theRange.location = theLocation;
		if ((theLocation + 5) < [pageString length])
			theRange.length = 5;
		else
			theRange.length = [pageString length] - theLocation;
		theRanges[i] = theRange;
		theText[i] = [pageString substringWithRange:theRange];
		
		i++;
	}
	
	
	// Next get the text where the mouse was clicked and see if that text is inside one of these boxes.
	// If so, declare victory. 
	
	
	
	if (fileName == nil)
		newDocument = self;
	else {
		id newURL = [NSURL fileURLWithPath: fileName];
		newDocument = [[TSDocumentController sharedDocumentController] documentForURL:newURL];
	}
	if (newDocument == nil)
		return NO;
	myLineRange = [newDocument lineRange: line];
	sourceLineString = [[aTextView string] substringWithRange: myLineRange];
	// NSLog(sourceLineString);
	searchIndex = idx - myLineRange.location;
	
	i = 0;
	while (i < boxNumber) {
		theRange = [sourceLineString rangeOfString: theText[i]];
		if ((theRange.location != NSNotFound) && (theRange.location <= (searchIndex + 5)) && (searchIndex < (theRange.location + theRange.length + 5))) {
			
			thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[i] - 1)];
			theSelection = [thePage selectionForRange: theRanges[i]];
			myOval = [theSelection boundsForPage:thePage];
			pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
			Param = 65536;
			[(MyPDFKitView *)[pdfKitWindow activeView] setIndexForMark: (pageNumber[i] - 1)];
			[(MyPDFKitView *)[pdfKitWindow activeView] setBoundsForMark: myOval];
			[(MyPDFKitView *)[pdfKitWindow activeView] setDrawMark: YES];
			[[pdfKitWindow activeView] goToPage: thePage];
			[[pdfKitWindow activeView] setCurrentSelection: theSelection];
			[[pdfKitWindow activeView] scrollSelectionToVisible:self];
			[[pdfKitWindow activeView] setCurrentSelection: nil];
			[[pdfKitWindow activeView] display];
			[pdfKitWindow makeKeyAndOrderFront:self]; 
			
			return YES;
		}
		i++;
	}
	
	
	
	// In case of failure, guess the full box where the text occurs. 
	
*/	
	initialFirstPage = pageNumber[0];
	thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[0] - 1)];
	pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
	
	
	myOval.size.height = HNumber[0]; 
	myOval.size.width = WNumber[0];
	myOval.origin.x = hNumber[0]; 
	myOval.origin.y = vNumber[0];
		
	if ((HNumber[0] < 0.1) || (WNumber[0] <= 0.1))
		theSelection = NULL;
	else 
		theSelection = [thePage selectionForRect: myOval];
	
//	theSelection = [thePage selectionForRange: theRanges[0]];
//	theSelection = [thePage selectionForRect: myOval];
	i = 1;
//	while (i < boxNumber) {
//		if (firstPage[i]) {
	//		anotherRect.size.height = HNumber[i] / Param + 10; anotherRect.size.width = WNumber[i]/ Param + 10;
	//		anotherRect.origin.x = hNumber[i] / Param - 5; anotherRect.origin.y = pageSize.size.height - vNumber[i]/ Param - 5;
	//		if (NSIntersectsRect(myOval, anotherRect))
	//			myOval = NSUnionRect(myOval, anotherRect);
//		}
//		i++;
//	}
	
	//	while (i < boxNumber) {
	//		if (firstPage[i]) {
	//		anotherRect.size.height = HNumber[i] / Param + 10; anotherRect.size.width = WNumber[i]/ Param + 10;
	//		anotherRect.origin.x = hNumber[i] / Param - 5; anotherRect.origin.y = pageSize.size.height - vNumber[i]/ Param - 5;
	//		if (NSIntersectsRect(myOval, anotherRect))
	//			myOval = NSUnionRect(myOval, anotherRect);
	//		}
	//		i++;
	//	}
	
	
	[(MyPDFKitView *)[pdfKitWindow activeView] setIndexForMark: (initialFirstPage - 1)];
	[(MyPDFKitView *)[pdfKitWindow activeView] setBoundsForMark: myOval];
	[(MyPDFKitView *)[pdfKitWindow activeView] setDrawMark: YES];
	[[pdfKitWindow activeView] goToPage: thePage];
	
	[[pdfKitWindow activeView] goToPage: thePage];
	
	if (theSelection != NULL) {
		[[pdfKitWindow activeView] setCurrentSelection: theSelection];
		[[pdfKitWindow activeView] scrollSelectionToVisible:self];
		[[pdfKitWindow activeView] setCurrentSelection: nil];
	}

	[[pdfKitWindow activeView] display];
	
	[pdfKitWindow makeKeyAndOrderFront:self];
	
	return YES;
	
	
	return YES;
	
}




@end
