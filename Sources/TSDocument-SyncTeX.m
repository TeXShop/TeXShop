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
	NSString		*sourceLineString, *searchString;
	TSDocument		*newDocument;
	int				searchIndex;
	PDFSelection	*theSelection, *anotherSelection;
	NSRect			anotherRect, pageSize;
	NSString		*myFileName, *mySyncTeXFileName, *mySyncTeX;
		
	// return NO;  // temporarily use Search synchronization
		
	
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
	enginePath = [[NSBundle mainBundle] pathForResource:@"synctexviewwrap" ofType:nil];
	[synctexTask setLaunchPath:enginePath];
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
	[args addObject: binPath];
	[args addObject: inputString];
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
	
	

	range1 =  [outputString rangeOfString:@"SyncTeX result begin"];
	if (range1.location == NSNotFound)
		return NO;
	outputString = [outputString substringFromIndex: (range1.location + 20)];
	
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
		xNumber[boxNumber] = [paramString intValue];	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"y:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		yNumber[boxNumber] = [paramString intValue];	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"h:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		hNumber[boxNumber] = [paramString intValue];	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"v:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		vNumber[boxNumber] = [paramString intValue];	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"W:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		WNumber[boxNumber] = [paramString intValue];	
		outputString = [outputString substringFromIndex: lineEndIndex];
		
		range1 = [outputString rangeOfString:@"H:"];
		if (range1.location == NSNotFound)
			break;
		[outputString getLineStart: &startIndex   end: &lineEndIndex  contentsEnd: &contentsEndIndex  forRange: range1];
		range2.location = startIndex + 2;
		range2.length = lineEndIndex - startIndex - 2;
		paramString = [outputString substringWithRange: range2];
		HNumber[boxNumber] = [paramString intValue];	
		outputString = [outputString substringFromIndex: lineEndIndex];

		boxNumber++;
	}
	
	if (boxNumber == 0)
		return NO;
		
		
		
	/* Next, get the text inside these various boxes and under the "index point" */
	
	
		
	i = 0;
	while (i < boxNumber) {
		thePage = [[myPDFKitView document] pageAtIndex: (pageNumber[i] - 1)];
		pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];

		Param = 65536;
		aPoint.x = xNumber[i]/Param;
		aPoint.y = pageSize.size.height - yNumber[i]/Param;
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
			Param = 65536;
			[myPDFKitView setIndexForMark: (pageNumber[i] - 1)];
			[myPDFKitView setBoundsForMark: myOval];
			[myPDFKitView setDrawMark: YES];
			[myPDFKitView goToPage: thePage];
			[myPDFKitView display];

			return YES;
			}
		i++;
		}
		
		
		
	/* In case of failure, guess the full box where the text occurs. */
	
	
	
		
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
		
	[myPDFKitView setIndexForMark: (initialFirstPage - 1)];
	[myPDFKitView setBoundsForMark: myOval];
	[myPDFKitView setDrawMark: YES];
	[myPDFKitView goToPage: thePage];
	[myPDFKitView display];

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
	[myPDFKitView display];
	
	i++;
	}
*/


	return YES;
			
}



@end
