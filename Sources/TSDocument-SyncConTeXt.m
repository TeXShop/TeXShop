/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2021 Richard Koch
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



@implementation TSDocument (SyncConTeXt)


- (BOOL)checkForUniqueMatchConTeXt: (NSString *)previewString withStart: (NSInteger)start andOffsetLength: (NSInteger)offset inSource: (NSString *)sourceString returnedRange: (NSRange *)foundRangeLocation multipleMatch: (BOOL *)multiple
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


- (BOOL)doSyncTeXForPageConTeXt: (NSInteger)pageNumber x: (CGFloat)xPosition y: (CGFloat)yPosition yOriginal: (CGFloat)yOriginalPosition
{
    NSString        *myFileName;
    NSString        *foundFileName;
    NSInteger       line;
    NSNumber        *myNumber;
    NSDate          *myDate;
    NSMutableArray  *args;
    NSString        *enginePath, *tetexBinPath, *alternateBinPath;
    NSInteger       tolerance;
    NSString        *rootFile, *mySyncTeXFileName;
    
     
    line = 0;
    foundFileName = NULL;
    
    myFileName = [[self fileURL] path];
    if (! myFileName)
        return NO;
    
    rootFile = [[self fileURL] path];
    if (! rootFile)
        return NO;
    mySyncTeXFileName = [[rootFile stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex"];
    if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
        return NO;

         
    if (self.backwardSyncTask != nil) {
        [self.backwardSyncTask terminate];
        myDate = [NSDate date];
        while (([self.backwardSyncTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
        self.backwardSyncTask = nil;
        self.backwardSyncTask = nil;
    }
    
    self.backwardSyncTask = [[NSTask alloc] init];
    [self.backwardSyncTask setCurrentDirectoryPath: [myFileName stringByDeletingLastPathComponent]];
    [self.backwardSyncTask setEnvironment: [self environmentForSubTask]];
    enginePath = [[NSBundle mainBundle] pathForResource:@"contextbackwardsyncwrap" ofType:nil];
    tetexBinPath = [[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath];
    alternateBinPath = [[SUD stringForKey:AltPathKey] stringByExpandingTildeInPath];
    
    /*
    set mytexexecpath = "$argv[1]"
    set pdffilename = "$argv[2]"
    set pdfpagenumber = "$argv[3]"
    set pdfxcoordinate = "$argv[4]"
    set pdfycoordinate = "$argv[5]"
    set tolerancenumber = "$argv[6]"
    */

    
    args = [NSMutableArray array];
    if (self.useAlternatePath )
        [args addObject: alternateBinPath];
    else
        [args addObject: tetexBinPath];
    [args addObject: [[[myFileName  stringByStandardizingPath] stringByDeletingPathExtension] stringByAppendingPathExtension:@"synctex"]];
    
//    NSInteger pageNumberTemp;
//    CGFloat xPositionTemp, yPositionTemp;
//    pageNumberTemp = 3;
//    xPositionTemp = 90.359;
//    yPositionTemp = 162.392;
//    toleranceTemp = 20;
    
    tolerance = 30;
    
//    NSLog(@"Page %d x %f y %f  %d", pageNumber, xPosition, yPosition, tolerance);
    
    myNumber = [NSNumber numberWithInteger: pageNumber];
    [args addObject: [myNumber stringValue]];
    myNumber = [NSNumber numberWithFloat: xPosition];
    [args addObject: [myNumber stringValue]];
    myNumber = [NSNumber numberWithFloat: yPosition];
    [args addObject: [myNumber stringValue]];
    myNumber = [NSNumber numberWithInteger: tolerance];
    [args addObject: [myNumber stringValue]];
    
    self.backwardSyncPipe = [NSPipe pipe];
    self.backwardSyncHandle = [self.backwardSyncPipe fileHandleForReading];
    [self.backwardSyncHandle waitForDataInBackgroundAndNotify];
    [self.backwardSyncTask setStandardOutput: self.backwardSyncPipe];
    if ((enginePath != nil) && ([[NSFileManager defaultManager] fileExistsAtPath: enginePath])) {
        [self.backwardSyncTask setLaunchPath:enginePath];
        [self.backwardSyncTask setArguments:args];
        [self.backwardSyncTask launch];

    } else {
        self.backwardSyncTask = nil;
    }
    

    return YES;
}
    
    
    
- (BOOL)finishBackwardContextSync
{
    NSString        *myFileName;
    NSString        *foundFileName;
    NSString        *newFile;
    NSError         *myError;
    NSRange         myLineRange;
    TSDocument      *newDocument;
    NSInteger       theLine;
    
    NSData *data = [self.backwardSyncHandle readDataToEndOfFile];
    [self.backwardSyncHandle closeFile];
    NSString *outputString = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
//    NSLog (outputString);
    
    if (! outputString)
        return NO;
    
// PARSE Output String
//    NSString *foundFileName;
//    NSInteger theLine;
    
//    foundFileName = @"\"this is wonderful\" 54";
    
    if ([outputString length] < 4)
        return NO;
    NSCharacterSet *mySet = [NSCharacterSet characterSetWithCharactersInString:@"\""];
    NSArray<NSString *> *myArray = [outputString componentsSeparatedByCharactersInSet: mySet];
    
    foundFileName = myArray[1];
     theLine = [myArray[2] integerValue];
    
    
    
    myFileName = [[self fileURL] path];
    if (! myFileName)
        return NO;
          
    if ([foundFileName isAbsolutePath])
        newFile = [foundFileName stringByStandardizingPath];
    else
        {
        newFile = [[[[[self fileURL] path] stringByDeletingLastPathComponent] stringByAppendingPathComponent: foundFileName] stringByStandardizingPath];
        }
        
    id newURL = [NSURL fileURLWithPath: newFile];
        
    newDocument = [[TSDocumentController sharedDocumentController] documentForURL: newURL];
    if (newDocument != self)
        newDocument = [[TSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:newURL display:YES error: &myError];
    if (newDocument == nil)
        return NO;
    TSTextView *myTextView = [newDocument textView];
    NSWindow *myTextWindow = [newDocument textWindow];
    [newDocument setTextSelectionYellow: YES];

    myLineRange = [newDocument lineRange: theLine];
    NSDictionary *mySelectedAttributes = [myTextView selectedTextAttributes];
    NSMutableDictionary *newSelectedAttributes = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes];
    [newSelectedAttributes setObject: ReverseSyncColor forKey:@"NSBackgroundColor"];
    // [newSelectedAttributes setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
    // FIXME: use temporary attributes instead of abusing the text selection
    [myTextView setSelectedTextAttributes: newSelectedAttributes];
    [myTextView setSelectedRange: myLineRange];
    [myTextView scrollRangeToVisible: myLineRange];
        
    if (! useFullSplitWindow)
        [myTextWindow makeKeyAndOrderFront:self];
    return YES;

}

- (BOOL)finishBackwardContextSyncExternal
{
    NSString        *myFileName;
    NSString        *foundFileName;
    NSString        *newFile;
    NSInteger       theLine;
    
    NSData *data = [self.backwardSyncHandleExternal readDataToEndOfFile];
    [self.backwardSyncHandleExternal closeFile];
    NSString *outputString = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
//    NSLog (outputString);
    
    if (! outputString)
        return NO;
    
// PARSE Output String
//    NSString *foundFileName;
//    NSInteger theLine;
    
//    foundFileName = @"\"this is wonderful\" 54";
    
    if ([outputString length] < 4)
        return NO;
    NSCharacterSet *mySet = [NSCharacterSet characterSetWithCharactersInString:@"\""];
    NSArray<NSString *> *myArray = [outputString componentsSeparatedByCharactersInSet: mySet];
    
    foundFileName = myArray[1];
     theLine = [myArray[2] integerValue];
    
    
    
    myFileName = [[self fileURL] path];
    if (! myFileName)
        return NO;
          
    if ([foundFileName isAbsolutePath])
        newFile = [foundFileName stringByStandardizingPath];
    else
        {
        newFile = [[[[[self fileURL] path] stringByDeletingLastPathComponent] stringByAppendingPathComponent: foundFileName] stringByStandardizingPath];
        }
    
 //   NSLog(@"the line is %d", theLine);
  //  NSLog(newFile);
    
    if (self.syncEditorMethod == 1)
        [self.myPDFKitView sendLineToOtherEditor: theLine forPath: newFile];
    
    else if (self.syncEditorMethod == 2)
        [self.myPDFKitView sendLineToTextMate: theLine forPath: newFile];
    
    return 0;
        
}





- (BOOL)doPreviewSyncTeXWithFilenameConTeXt:(NSString *)fileName andLine:(NSInteger)line andCharacterIndex:(NSUInteger)idx andTextView:(id)aTextView;
{
    
        NSString        *myFileName;
        NSString        *foundFileName;
        NSNumber        *myNumber;
        NSDate          *myDate;
        NSMutableArray  *args;
        NSString        *enginePath, *tetexBinPath;
        NSInteger       pageNumber;
        CGFloat         xPosition, yPosition;
        NSString        *alternateBinPath;
        NSString        *rootFile, *mySyncTeXFileName;  
    
       myFileName = [[self fileURL] path];
        if (! myFileName)
            return NO;
    
       rootFile = [[self fileURL] path];
       if (! rootFile)
            return NO;
       mySyncTeXFileName = [[rootFile stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex"];
       if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
            return NO;

         
        if (self.forwardSyncTask != nil) {
            [self.forwardSyncTask terminate];
            myDate = [NSDate date];
            while (([self.forwardSyncTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
            self.forwardSyncTask = nil;
            self.forwardSyncTask = nil;
        }
        
        self.forwardSyncTask = [[NSTask alloc] init];
        [self.forwardSyncTask setCurrentDirectoryPath: [myFileName stringByDeletingLastPathComponent]];
        [self.forwardSyncTask setEnvironment: [self environmentForSubTask]];
        enginePath = [[NSBundle mainBundle] pathForResource:@"contextforwardsyncwrap" ofType:nil];
        tetexBinPath = [[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath];
        alternateBinPath = [[SUD stringForKey:AltPathKey] stringByExpandingTildeInPath];
        

        args = [NSMutableArray array];
        if (self.useAlternatePath )
        {
            [args addObject: alternateBinPath];
    //        NSLog(alternateBinPath);
        }
        else
        {
            [args addObject: tetexBinPath];
    //        NSLog(tetexBinPath);
        }
        // [args addObject: [myFileName lastPathComponent]]; key error, should be fileName
        if (! fileName)
            [args addObject: [myFileName lastPathComponent]];
        else
            [args addObject: [fileName lastPathComponent]];
        myNumber = [NSNumber numberWithInteger: line];
        [args addObject: [myNumber stringValue]];
        [args addObject: [[[myFileName  stringByStandardizingPath] stringByDeletingPathExtension] stringByAppendingPathExtension:@"synctex"]];
        
 //   NSLog([myFileName lastPathComponent]);
 //   NSLog(@"line: %d", line);
        
  
    
        self.forwardSyncPipe = [NSPipe pipe];
        self.forwardSyncHandle = [self.forwardSyncPipe fileHandleForReading];
        [self.forwardSyncHandle waitForDataInBackgroundAndNotify];
        [self.forwardSyncTask setStandardOutput: self.forwardSyncPipe];
        if ((enginePath != nil) && ([[NSFileManager defaultManager] fileExistsAtPath: enginePath])) {
            [self.forwardSyncTask setLaunchPath:enginePath];
            [self.forwardSyncTask setArguments:args];
            [self.forwardSyncTask launch];

        } else {
            self.forwardSyncTask = nil;
        }
        

        return YES;

}


- (BOOL)finishForwardContextSync
{
    int             pageNumber[200];
    float           hNumber[200], vNumber[200], WNumber[200], HNumber[200]; //, xNumber[200], yNumber[200];
    BOOL            firstPage[200];
    int             initialFirstPage;
    int             boxNumber;
    NSRect          myOval;
    PDFPage         *thePage;
    int             i;
    PDFSelection    *theSelection;
    NSRect          pageSize;
    NSInteger       aPage;
    NSInteger       llx, lly;
    NSInteger       urx, ury;
    
 //   NSLog(@"and in the end here");

    NSData *data = [self.forwardSyncHandle readDataToEndOfFile];
    [self.forwardSyncHandle closeFile];
    NSString *outputString = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
 //  NSLog(@"Hello");
 //   NSLog (outputString);
    
    if (self.forwardSyncTask != nil) {
    [self.forwardSyncTask terminate];
    NSDate *myDate = [NSDate date];
    while (([self.forwardSyncTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
    self.forwardSyncTask = nil;
    self.forwardSyncPipe = nil;
    }
    
    if (! outputString)
        return NO;
    
    // typical output is:  page=3 llx=57 lly=92 urx=154 ury=109
    
    if ([outputString length] < 4)
        return NO;
    NSArray<NSString *> *myArray = [outputString componentsSeparatedByCharactersInSet: NSCharacterSet.whitespaceCharacterSet];
    if ([myArray count] < 5)
        return NO;
//    NSLog(myArray[0]);
//    NSLog(myArray[1]);
//    NSLog(myArray[2]);
//    NSLog(myArray[3]);
//    NSLog(myArray[4]);
    
    NSArray<NSString *> *decomposeArray;
    NSCharacterSet *decomposeSet = [NSCharacterSet characterSetWithCharactersInString:@"="];
    decomposeArray = [myArray[0] componentsSeparatedByCharactersInSet: decomposeSet];
    if ([decomposeArray count] < 2)
        return NO;
    aPage = [decomposeArray[1] integerValue];
    
    decomposeArray = [myArray[1] componentsSeparatedByCharactersInSet: decomposeSet];
    if ([decomposeArray count] < 2)
        return NO;
    llx = [decomposeArray[1] integerValue];
    
    decomposeArray = [myArray[2] componentsSeparatedByCharactersInSet: decomposeSet];
    if ([decomposeArray count] < 2)
        return NO;
    lly = [decomposeArray[1] integerValue];
    
    decomposeArray = [myArray[3] componentsSeparatedByCharactersInSet: decomposeSet];
    if ([decomposeArray count] < 2)
        return NO;
    urx = [decomposeArray[1] integerValue];
    
    decomposeArray = [myArray[4] componentsSeparatedByCharactersInSet: decomposeSet];
    if ([decomposeArray count] < 2)
        return NO;
    ury = [decomposeArray[1] integerValue];
    
//    NSLog(@"values are %d, %d, %d, %d, %d", aPage, llx, lly, urx, ury);
 
// HERE WE PASTE IN SYNC CODE
    
    // The equations below define a rectangle, with origin (hNumber, vNumber) and size (WNumber, HNumber)
    
    pageNumber[0] = aPage;
    thePage = [[self.myPDFKitView document] pageAtIndex: (pageNumber[0] - 1)];
    pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
   
    hNumber[0] = llx;
    vNumber[0] = pageSize.size.height - lly - 5.0;   //pageSize.size.height - v - height; // v;
    WNumber[0] = urx - llx;
    HNumber[0] = ury - lly;
    pageNumber[0] = aPage;
    firstPage[0] = YES;

    [(MyPDFKitView *)self.pdfKitWindow.activeView setNumberSyncRect:0];
    [(MyPDFKitView *)self.pdfKitWindow.activeView setSyncRect: 0 originX: hNumber[0] originY: vNumber[0] width: WNumber[0] height: HNumber[0]];
    
    initialFirstPage = pageNumber[0];
    
    
    myOval.size.height = HNumber[0];
    myOval.size.width = WNumber[0];
    myOval.origin.x = hNumber[0];
    myOval.origin.y = vNumber[0];

 
    if (atLeastElCapitan) {
        myOval.size.height = myOval.size.height + 40.0;
        myOval.origin.y = myOval.origin.y - 20.0;
    }
 
    
    [self.pdfKitWindow.activeView goToPage: thePage];
    [(MyPDFKitView *)self.pdfKitWindow.activeView setNumberSyncRect:1];
    [(MyPDFKitView *)self.pdfKitWindow.activeView setIndexForMark: (initialFirstPage - 1)];
    [(MyPDFKitView *)self.pdfKitWindow.activeView setBoundsForMark: myOval];
    [(MyPDFKitView *)self.pdfKitWindow.activeView setDrawMark: YES];
  
    [self.pdfKitWindow.activeView display];
    
    if (! useFullSplitWindow)
            [self.pdfKitWindow makeKeyAndOrderFront:self];
    
    return YES;
    
}
    



- (void)doPreviewSyncTeXExternalWithFilenameConTeXt:(NSString *)fileName andLine:(NSInteger)line andCharacterIndex:(NSUInteger)idx
{
    
      [self doPreviewSyncTeXWithFilenameConTeXt:fileName andLine:line andCharacterIndex:idx andTextView:NULL];
}

@end

