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
#import "synctex_parser_old.h"



@implementation TSDocument (SyncOld)

- (BOOL)checkForUniqueMatch: (NSString *)previewString withStart: (NSInteger)start andOffsetLength: (NSInteger)offset inSource: (NSString *)sourceString returnedRange: (NSRange *)foundRangeLocation multipleMatch: (BOOL *)multiple
{
	NSRange		searchRange, resultRange, newResultRange;
	NSInteger			end;
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

- (void)allocateSyncScannerOld
{
    NSString        *myFileName, *mySyncTeXFileName;
    const char        *fileString;
    
    // myFileName = [self fileName];
    myFileName = [[self fileURL] path];
    if (! myFileName)
        return;
    
    mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex"];
    if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
    {
        mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex.gz"];
        if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
            return;
    }
    
    if (scanner != NULL)
        old_synctex_scanner_free(scanner);
    scanner = NULL;
    
    fileString = [myFileName cStringUsingEncoding:NSUTF8StringEncoding];
    scanner = old_synctex_scanner_new_with_output_file(fileString, NULL, 1);
}


- (BOOL)doSyncTeXForPageOld: (NSInteger)pageNumber x: (CGFloat)xPosition y: (CGFloat)yPosition yOriginal: (CGFloat)yOriginalPosition
{
    NSString        *myFileName, *mySyncTeXFileName;
    //const char        *fileString;
    //    const char        *syncTeXFileName;
    //    NSString        *syncTeXName;
    const char        *theFoundFileName;
    NSString         *foundFileName;
    NSInteger                line;
    BOOL            gotSomething;
    NSString         *newFile;
    NSError            *myError;
    
    NSInteger        length, theIndex;
    NSPoint            viewPosition;
    NSRange            correctedFoundRange;
    NSString        *sourceLineString;
    NSRange            myLineRange;
    BOOL            foundMatch, matchMultiple;
    NSInteger        matchStart, matchLength, i, matchAdjust, newLocation;
    NSRange            matchRange;
    TSDocument      *newDocument;
    CGFloat         myRed, myGreen, myBlue;
    NSColor         *thePossiblyYellowColor;
    // NSString        *lineString;
    
    
    line = 0;
    foundFileName = NULL;
    
    // myFileName = [self fileName];
    myFileName = [[self fileURL] path];
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
        //    syncTeXFileName = synctex_scanner_get_synctex(scanner);
        //    syncTeXName = [NSString stringWithCString: syncTeXFileName encoding:NSUTF8StringEncoding];
        //    NSLog(syncTeXName);
        
        gotSomething = NO;
        if (old_synctex_edit_query(scanner, pageNumber, xPosition, yPosition) > 0) {
            gotSomething = YES;
            synctex_node_t node;
            while ((node = old_synctex_next_result(scanner)) != NULL) {
                theFoundFileName = old_synctex_scanner_get_name(scanner, old_synctex_node_tag(node));
                
                // This line is a patch by Klaus Tichmann
                if (theFoundFileName == NULL)
                    return NO;
                foundFileName = [NSString stringWithCString: theFoundFileName encoding:NSUTF8StringEncoding];
                line = old_synctex_node_line(node);
                
                // NSLog(foundFileName);
                // NSLog(@"got all the way");
                
                //NSNumber *myNumber = [NSNumber numberWithInt:line];
                // NSLog([myNumber stringValue]);
                
                break; // FIXME: use more nodes?
            }
            if (! gotSomething)
                return NO;
        }
        
        //        old_synctex_scanner_free(scanner);
        //        scanner = NULL;
        
        // END OF PARSING; NOW USE THE INFORMATION
        
        // foundFileName could be a full path, or just relative to the source directory
        /*
         //     if (! useFullSplitWindow)
         //     {
         
         if ([foundFileName isAbsolutePath])
         newFile = [foundFileName stringByStandardizingPath];
         else
         {
         newFile = [[[[[self fileURL] path] stringByDeletingLastPathComponent] stringByAppendingPathComponent: foundFileName] stringByStandardizingPath];
         }
         
         // NSLog(newFile);
         
         id newURL = [NSURL fileURLWithPath: newFile];
         newDocument = [[TSDocumentController sharedDocumentController] documentForURL: newURL];
         if (newDocument == nil)
         return NO;
         
         if (! [newDocument useFullSplitWindow])
         newDocument = [[TSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:newURL display:YES error: &myError];
         
         if (newDocument == nil)
         return NO;
         //    }
         //     else
         //   newDocument = self;
         */
        
        if ([foundFileName isAbsolutePath])
            newFile = [foundFileName stringByStandardizingPath];
        else
        {
            newFile = [[[[[self fileURL] path] stringByDeletingLastPathComponent] stringByAppendingPathComponent: foundFileName] stringByStandardizingPath];
        }
        
        // NSLog(newFile);
        
        id newURL = [NSURL fileURLWithPath: newFile];
        
        newDocument = [[TSDocumentController sharedDocumentController] documentForURL: newURL];
        if (newDocument != self)
            newDocument = [[TSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:newURL display:YES error: &myError];
        
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
                if ([sourceLineString length] > 7) // was lineString, but that was clearly an error
                    correctedFoundRange.location = myLineRange.location + myLineRange.length - 7;
                else
                    foundMatch = NO;
            }
            
        }
        
        // End of refinement
        // ---------------------------------------------------
        
        NSDictionary *mySelectedAttributes = [myTextView selectedTextAttributes];
        NSMutableDictionary *newSelectedAttributes = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes];
        
        /*
        myRed = [SUD floatForKey: reverseSyncRedKey];
        myGreen = [SUD floatForKey: reverseSyncGreenKey];
        myBlue = [SUD floatForKey: reverseSyncBlueKey];
        thePossiblyYellowColor = [NSColor colorWithCalibratedRed:myRed green:myGreen blue:myBlue alpha:1.00];
        [newSelectedAttributes setObject: thePossiblyYellowColor forKey:@"NSBackgroundColor"];
        */
        [newSelectedAttributes setObject: ReverseSyncColor forKey:@"NSBackgroundColor"];
        
        // [newSelectedAttributes setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
        // FIXME: use temporary attributes instead of abusing the text selection
        [myTextView setSelectedTextAttributes: newSelectedAttributes];
        
        if (foundMatch) {
            [myTextView setSelectedRange: correctedFoundRange];
            [myTextView scrollRangeToVisible: correctedFoundRange];
        }
        else
            [newDocument toLine: line];
        
        if (! useFullSplitWindow)
            [myTextWindow makeKeyAndOrderFront:self];
        
        return YES;
        
    }
    
    
    
    
    return YES;
    
}


- (BOOL)doPreviewSyncTeXWithFilenameOld:(NSString *)fileName andLine:(NSInteger)line andCharacterIndex:(NSUInteger)idx andTextView:(id)aTextView;
{
    // NSDate          *myDate;
    // NSString        *enginePath;
    // NSString        *mainSourceString;
    // NSString        *inputString;
    // NSString        *pdfPreviewString;
    // NSString        *lineString;
    // NSString        *indexString;
    // NSString        *fileString;
    // NSNumber        *lineNumber, *indexNumber;
    // NSMutableArray    *args;
    // NSRange            myRange;
    // NSRange            range1, range2;
    //  NSString        *paramString;
    int                pageNumber[200];
    float            hNumber[200], vNumber[200], WNumber[200], HNumber[200]; //, xNumber[200], yNumber[200];
    // NSString        *theText[200];
    // NSRange            theRanges[200];
    BOOL            firstPage[200];
    int                initialFirstPage;
    int                boxNumber;
    // float            Param;
    // unsigned        startIndex, lineEndIndex, contentsEndIndex;
    NSRect            myOval;
    PDFPage            *thePage;
    int                i;
    // NSString        *pageString;
    // NSPoint            aPoint;
    // int                theNumber, theLocation;
    // NSRange            theRange;
    // NSRange            myLineRange;
    // NSString        *sourceLineString;
    // TSDocument        *newDocument;
    // int                searchIndex;
    PDFSelection    *theSelection;
    NSRect          pageSize;
    // NSRect            anotherRect;
    NSString        *mySyncTeXFileName; //, *mySyncTeX;
    // float            magnification;
    // float            xoffset, yoffset;
    const char        *name;
    NSString        *theName;
    NSString        *theFullName; //, *aName;
    // NSString        *pathString;
    NSString        *rootFile, *rootPath, *theFile;
    float            x, y, h, v, width, height;
    
    // THIS IS ACTIVE
    
    // rootFile = [self fileName]; // root document
    rootFile = [[self fileURL] path];
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
    
    synctex_node_t node = old_synctex_scanner_input(scanner);
    BOOL found = NO;
    while (node != NULL) {
        name = old_synctex_scanner_get_name(scanner, old_synctex_node_tag(node));
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
        node = old_synctex_node_sibling(node);
    }
    
    if (! found) {
        NSLog(@"Nope, Couldn't Find File");
        return NO;
    }
    
    boxNumber = 0;
    
    if (old_synctex_display_query(scanner, name, line, 0) > 0) {
        int page = -1;
        BOOL gotSomething = NO;
        
        
        while (((node = old_synctex_next_result(scanner)) != NULL) && (boxNumber < 200)) {
            if (page == -1) {
                page = old_synctex_node_page(node);
                thePage = [[self.myPDFKitView document] pageAtIndex: (page - 1)];
                pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
            }
            if (old_synctex_node_page(node) != page)
                continue;
            gotSomething = YES;
            // x = synctex_node_box_visible_x(node);
            // y = synctex_node_box_visible_y(node);
            x = 0; y = 0;
            h = old_synctex_node_box_visible_h(node);
            v = old_synctex_node_box_visible_v(node) - old_synctex_node_box_visible_height(node);
            width = old_synctex_node_box_visible_width(node);
            height = old_synctex_node_box_visible_height(node) + old_synctex_node_box_visible_depth(node);
            
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
    
    
    [(MyPDFKitView *)self.pdfKitWindow.activeView setNumberSyncRect:boxNumber];
    
    i = 0;
    while (i < boxNumber) {
        [(MyPDFKitView *)self.pdfKitWindow.activeView setSyncRect: i originX: hNumber[i] originY: vNumber[i] width: WNumber[i] height: HNumber[i]];
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
     //     return NO;
     
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
     thePage = [[self.pdfKitWindow.activeView document] pageAtIndex: (pageNumber[i] - 1)];
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
     
     thePage = [[self.myPDFKitView document] pageAtIndex: (pageNumber[i] - 1)];
     theSelection = [thePage selectionForRange: theRanges[i]];
     myOval = [theSelection boundsForPage:thePage];
     pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
     Param = 65536;
     [(MyPDFKitView *)self.pdfKitWindow.activeView setIndexForMark: (pageNumber[i] - 1)];
     [(MyPDFKitView *)self.pdfKitWindow.activeView setBoundsForMark: myOval];
     [(MyPDFKitView *)self.pdfKitWindow.activeView setDrawMark: YES];
     [self.pdfKitWindow.activeView goToPage: thePage];
     [self.pdfKitWindow.activeView setCurrentSelection: theSelection];
     [self.pdfKitWindow.activeView scrollSelectionToVisible:self];
     [self.pdfKitWindow.activeView setCurrentSelection: nil];
     [self.pdfKitWindow.activeView display];
     if (! useFullSplitWindow)
     [self.pdfKitWindow makeKeyAndOrderFront:self];
     
     return YES;
     }
     i++;
     }
     
     
     
     // In case of failure, guess the full box where the text occurs.
     
     */
    initialFirstPage = pageNumber[0];
    thePage = [[self.myPDFKitView document] pageAtIndex: (pageNumber[0] - 1)];
    pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
    
    
    myOval.size.height = HNumber[0];
    myOval.size.width = WNumber[0];
    myOval.origin.x = hNumber[0];
    myOval.origin.y = vNumber[0];
    
    if (atLeastElCapitan) {
        myOval.size.height = myOval.size.height + 40.0;
        myOval.origin.y = myOval.origin.y - 20.0;
    }
    
    // NSLog(@"The dimensions are %f and %f and %f and %f.", myOval.size.height, myOval.size.width, myOval.origin.x, myOval.origin.y);
    
    if ((HNumber[0] < 0.1) || (WNumber[0] <= 0.1))
        theSelection = NULL;
    else
        theSelection = [thePage selectionForRect: myOval];
    
    
    //    theSelection = [thePage selectionForRange: theRanges[0]];
    // theSelection = [thePage selectionForRect: myOval];
    i = 1;
    //    while (i < boxNumber) {
    //        if (firstPage[i]) {
    //        anotherRect.size.height = HNumber[i] / Param + 10; anotherRect.size.width = WNumber[i]/ Param + 10;
    //        anotherRect.origin.x = hNumber[i] / Param - 5; anotherRect.origin.y = pageSize.size.height - vNumber[i]/ Param - 5;
    //        if (NSIntersectsRect(myOval, anotherRect))
    //            myOval = NSUnionRect(myOval, anotherRect);
    //        }
    //        i++;
    //    }
    
    //    while (i < boxNumber) {
    //        if (firstPage[i]) {
    //        anotherRect.size.height = HNumber[i] / Param + 10; anotherRect.size.width = WNumber[i]/ Param + 10;
    //        anotherRect.origin.x = hNumber[i] / Param - 5; anotherRect.origin.y = pageSize.size.height - vNumber[i]/ Param - 5;
    //        if (NSIntersectsRect(myOval, anotherRect))
    //            myOval = NSUnionRect(myOval, anotherRect);
    //        }
    //        i++;
    //    }
    
    [(MyPDFKitView *)self.pdfKitWindow.activeView setIndexForMark: (initialFirstPage - 1)];
    [(MyPDFKitView *)self.pdfKitWindow.activeView setBoundsForMark: myOval];
    [(MyPDFKitView *)self.pdfKitWindow.activeView setDrawMark: YES];
    [self.pdfKitWindow.activeView goToPage: thePage];
    
    [self.pdfKitWindow.activeView goToPage: thePage];
    
    if (theSelection != NULL) {
        [self.pdfKitWindow.activeView setCurrentSelection: nil];
        [theSelection setColor: [NSColor yellowColor]];
        [self.pdfKitWindow.activeView setCurrentSelection: theSelection];
        [self.pdfKitWindow.activeView scrollSelectionToVisible:self];
        if (atLeastSierra)
            ;
        else
            [self.pdfKitWindow.activeView setCurrentSelection: nil];
    }
    
    [self.pdfKitWindow.activeView display];
    
    if (! useFullSplitWindow)
        [self.pdfKitWindow makeKeyAndOrderFront:self];
    
    return YES;
    
    
    return YES;
    
}





@end

