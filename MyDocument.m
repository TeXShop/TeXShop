// MyDocument.m

#import "MyDocument.h"

@implementation MyDocument

 - (void) orderFrontFindPanel: sender;
 {
    [textFinder orderFrontFindPanel: sender];
 }
 
  - (void) findNext: sender;
 {
    [textFinder findNext: sender];
 }

 - (void) findPrevious: sender;
 {
    [textFinder findPrevious: sender];
 }

 - (void) enterSelection: sender;
 {
    [textFinder enterSelection: sender];
 }

 - (void) jumpToSelection: sender;
 {
    [textFinder jumpToSelection: sender];
 }



- (id) pdfView;
{
    return pdfView;
}

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    return @"MyDocument";
}

- (void)printShowingPrintPanel:(BOOL)flag 
{
    PrintView		*printView;
    NSPrintOperation	*printOperation;
    NSString		*imagePath;
    NSPDFImageRep	*aRep;
    int			result;
    
    imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingString:@".pdf"];
    if ([myFileManager fileExistsAtPath: imagePath]) {
        aRep = [[NSPDFImageRep imageRepWithContentsOfFile: imagePath] retain];
        printView = [[PrintView alloc] initWithRep: aRep andDisplayPref: myDisplayPref ];
        printOperation = [NSPrintOperation printOperationWithView:printView
            printInfo: [self printInfo]];
        [printView setPrintOperation: printOperation];
        [printOperation setShowPanels:flag];
        [printOperation runOperation];
        [printView release];
        }
    else { 
        result = [NSApp runModalForWindow: printRequestPanel];
        }
}
    

- (void)windowControllerDidLoadNib:(NSWindowController *) aController{
    
    NSString		*imagePath;
    NSString		*projectPath;
    NSString		*fileExtension;
    NSString		*nameString;
    NSRect		topLeftRect;
    NSPoint		topLeftPoint;
    NSRange		myRange;
    
    [super windowControllerDidLoadNib:aController];
    // Add any code here that need to be executed once the windowController has loaded the document's window.
    
    errorNumber = 0;
    whichError = 0;
    makeError = NO;

    fileIsTex = YES;
    myFileManager = [[NSFileManager defaultManager] retain];
    myTexEngine = nil; myLatexEngine = nil;
    [pdfView setDocument: self];
    [textView setDelegate: self];

    [self readPreferences];
    if (aString == nil) 
        ;
    else {
        [textView setString: aString];
        [aString release];
        aString = nil;
        texTask = nil;
        bibTask = nil;
        indexTask = nil;
        }
    
    myRange.location = 0;
    myRange.length = 0;
    [textView setSelectedRange: myRange];
    [textWindow setInitialFirstResponder: textView];
    [textWindow makeFirstResponder: textView];
    
    if (myProgramPref == 0)
        [typesetButton setTitle: @"Tex"];
    else
        [typesetButton setTitle: @"Latex"];
    
    if (myDisplayPref != 0) {
        [[pdfView slider] setNumberOfTickMarks: 5];
        [[pdfView slider] setAllowsTickMarkValuesOnly: YES];
        }
       
        [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(checkATaskStatus:) 
            name:NSTaskDidTerminateNotification 
            object:nil];
            
        [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(checkPrefClose:) 
            name:NSWindowWillCloseNotification 
            object:nil];
            
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(writeTexOutput:)
            name:NSFileHandleReadCompletionNotification object:nil
            ];
            
        
        fileExtension = [[self fileName] pathExtension];
        if (( ! [fileExtension isEqualToString: @"tex"]) && ( ! [fileExtension isEqualToString: @"TEX"]) &&
            ([myFileManager fileExistsAtPath: [self fileName]]))
            {
            [self setFileType: fileExtension];
            [typesetButton setEnabled: NO];
            fileIsTex = NO;
            return;
            }
        projectPath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingString:@".texshop"];
        if ([myFileManager fileExistsAtPath: projectPath]) {
            nameString = [NSString stringWithContentsOfFile: projectPath];
            imagePath = [[nameString stringByDeletingPathExtension] stringByAppendingString:@".pdf"];
            }
        else
            imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingString:@".pdf"];
        if ([myFileManager fileExistsAtPath: imagePath]) {
            texRep = [[NSPDFImageRep imageRepWithContentsOfFile: imagePath] retain]; 
            if (texRep) {
                [pdfWindow setTitle: 
                        [[[[self fileName] lastPathComponent] 
                        stringByDeletingPathExtension] stringByAppendingString:@".pdf"]];
                [pdfView setImageRep: texRep]; // this releases old one!
                topLeftRect = [texRep bounds];
                topLeftPoint.x = topLeftRect.origin.x;
                topLeftPoint.y = topLeftRect.origin.y + topLeftRect.size.height - 1;
                [pdfView scrollPoint: topLeftPoint];
                [pdfView display];
                [pdfWindow makeKeyAndOrderFront: self];
                if ([self displayPref] != 0) 
                    [pdfView drawWithGhostscript];
                  }
            }
            


    }
    
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];       
    [super dealloc];
}


- (NSData *)dataRepresentationOfType:(NSString *)aType {
    // Insert code here to write your document from the given data.
    // The following is line has been changed to fix the bug from Geoff Leyland 
    // return [[textView string] dataUsingEncoding: NSASCIIStringEncoding];
    return [[textView string] dataUsingEncoding: NSMacOSRomanStringEncoding allowLossyConversion:YES];
}


/*
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType {
   //  NSString	*myString;
    // Insert code here to read your document from the given data.  You can also choose to override 	-loadFileWrapperRepresentation:ofType: or -readFromFile:ofType: instead.
    return YES;
}
*/

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type {

    aString = [[NSString stringWithContentsOfFile:fileName] retain];
    return YES;
}


- (void)checkATaskStatus:(NSNotification *)aNotification {

    NSString		*imagePath, *projectPath, *nameString;
    NSDictionary	*myAttributes;
    NSDate		*endDate;
    NSRect		topLeftRect;
    NSPoint		topLeftPoint;

if (([aNotification object] == bibTask) || ([aNotification object] == indexTask)) {

    if (inputPipe == [[aNotification object] standardInput]) {
    
        int status = [[aNotification object] terminationStatus];
        
        if ((status == 0) || (status == 1)) {
        
            [outputPipe release];
            [writeHandle closeFile];
            [inputPipe release];
            inputPipe = 0;
            if ([aNotification object] == bibTask)
                bibTask = nil;
            else if ([aNotification object] == indexTask)
                indexTask = nil;
            }
            
        }
    }
    
if ([aNotification object] != texTask) return;

if (inputPipe == [[aNotification object] standardInput]) {

    int status = [[aNotification object] terminationStatus];
    
     if ((status == 0) || (status == 1))  {

        projectPath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingString:@".texshop"];
        if ([myFileManager fileExistsAtPath: projectPath]) {
            nameString = [NSString stringWithContentsOfFile: projectPath];
            imagePath = [[nameString stringByDeletingPathExtension] stringByAppendingString:@".pdf"];
            }
        else
            imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingString:@".pdf"];

        if ([myFileManager fileExistsAtPath: imagePath]) {
         
            myAttributes = [myFileManager fileAttributesAtPath: imagePath traverseLink:NO];
            endDate = [myAttributes objectForKey:NSFileModificationDate];
            if ((startDate == nil) || ! [startDate isEqualToDate: endDate]) {
 
                texRep = [[NSPDFImageRep imageRepWithContentsOfFile: imagePath] retain]; 
                if (texRep) {
                    [pdfWindow setTitle: 
                        [[[[self fileName] lastPathComponent] 
                        stringByDeletingPathExtension] stringByAppendingString:@".pdf"]];
                    /* if ([self displayPref] == 0) */
                        [pdfView setImageRep: texRep];
                    if (startDate == nil) {
                        topLeftRect = [texRep bounds];
                        topLeftPoint.x = topLeftRect.origin.x;
                        topLeftPoint.y = topLeftRect.origin.y + topLeftRect.size.height - 1;
                        [pdfView scrollPoint: topLeftPoint];
                        }
                    if ([self displayPref] == 0) {
                        [pdfView display];
                        [pdfWindow makeKeyAndOrderFront: self];
                        }
                    else {
                        [pdfWindow makeKeyAndOrderFront: self];
                        [pdfView drawWithGhostscript];
                        }
                     }
                }
            }
            
        [outputPipe release];
        [writeHandle closeFile];
        [inputPipe release];
        inputPipe = 0;
        texTask = nil;
        }
    }
}

- (void) doTemplate: sender {
 
    NSString	*templateString, *nameString;
    id		theItem;
    
    theItem = [sender selectedItem];
    
    if (theItem) {
        nameString = [NSString stringWithString: @"~/Library/Preferences/TeXShop Prefs/Templates/"];
        nameString = [nameString stringByAppendingString:[theItem title]]; 
        nameString = [[nameString stringByAppendingString: @".tex"] stringByExpandingTildeInPath];
        templateString = [NSString stringWithContentsOfFile: nameString];
        if (templateString != nil) {
            [textView replaceCharactersInRange: [textView selectedRange]
                withString: templateString];
            }
        }
}

- (void) doBibJob
{
    SEL	saveFinished;
    
    errorNumber = 0;
    whichError = 0;
    makeError = NO;
    
    whichEngine = 3;
    saveFinished = @selector(saveFinished:didSave:contextInfo:);
    [self saveDocumentWithDelegate: self didSaveSelector: saveFinished contextInfo: nil];
}

- (void) doIndexJob
{
    SEL	saveFinished;
    
    errorNumber = 0;
    whichError = 0;
    makeError = NO;
    
    whichEngine = 4;
    saveFinished = @selector(saveFinished:didSave:contextInfo:);
    [self saveDocumentWithDelegate: self didSaveSelector: saveFinished contextInfo: nil];
}


- (void) doJob: (Boolean) withLatex;
{
    SEL	saveFinished;
    
    errorNumber = 0;
    whichError = 0;
    makeError = YES;
    
    if (withLatex)
        whichEngine= 1;
    else 
        whichEngine = 0;
    saveFinished = @selector(saveFinished:didSave:contextInfo:);
    [self saveDocumentWithDelegate: self didSaveSelector: saveFinished contextInfo: nil];
}

- (void) saveFinished: (NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo;
{
    NSString		*myFileName;
    NSMutableArray	*args;
    NSDictionary	*myAttributes;
    NSString		*imagePath, *project, *nameString;
    NSString		*projectPath;
    NSString		*sourcePath;
    NSString		*bibPath;
    NSString		*indexPath;
    BOOL		withLatex;

    if (whichEngine == 1)
        withLatex = YES;
    else if (whichEngine == 0)
        withLatex = NO;

    myFileName = [self fileName];
    if ([myFileName length] > 0) {
    
        if (startDate != nil) {
            [startDate release];
            startDate = nil;
            }
            
        projectPath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingString:@".texshop"];
        if ([myFileManager fileExistsAtPath: projectPath]) {
            nameString = [NSString stringWithContentsOfFile: projectPath];
            imagePath = [[nameString stringByDeletingPathExtension] stringByAppendingString:@".pdf"];
            }
        else
            imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingString:@".pdf"];

        if ([myFileManager fileExistsAtPath: imagePath]) {
            myAttributes = [myFileManager fileAttributesAtPath: imagePath traverseLink:NO];
            startDate = [[myAttributes objectForKey:NSFileModificationDate] retain];
            }
        else
            startDate = nil;
    
        args = [NSMutableArray array];
        
        outputPipe = [[NSPipe pipe] retain];
        readHandle = [outputPipe fileHandleForReading];
        [readHandle readInBackgroundAndNotify];
        
        inputPipe = [[NSPipe pipe] retain];
        writeHandle = [inputPipe fileHandleForWriting];
        
        [outputText setSelectable: YES];
        [outputText selectAll:self];
        [outputText replaceCharactersInRange: [outputText selectedRange]
            withString:@""];
        [outputText setSelectable: NO];
        [outputWindow setTitle: [[[[self fileName] lastPathComponent] stringByDeletingPathExtension] 
                stringByAppendingString:@" console"]];
        [outputWindow makeKeyAndOrderFront: self];

        project = [[[self fileName] stringByDeletingPathExtension]
            stringByAppendingString: @".texshop"];
        if ([myFileManager fileExistsAtPath: project])
            sourcePath = [NSString stringWithContentsOfFile: project];
        else
            sourcePath = myFileName;
            
        if (whichEngine < 3)
            {
            [args addObject: sourcePath];
        
            if (texTask != nil) {
                [texTask terminate];
                texTask = nil;
                }
            texTask = [[NSTask alloc] init];
            [texTask setCurrentDirectoryPath: [sourcePath  stringByDeletingLastPathComponent]];
            if (withLatex)
                [texTask setLaunchPath: myLatexEngine];
            else
                [texTask setLaunchPath: myTexEngine]; 
            [texTask setArguments:args];
            [texTask setStandardOutput: outputPipe];
            [texTask setStandardInput: inputPipe];
            [texTask launch];
            }
        else if (whichEngine == 3) {
            bibPath = [sourcePath stringByDeletingPathExtension];
            [args addObject: bibPath];
        
            if (bibTask != nil) {
                [bibTask terminate];
                bibTask = nil;
                }
            bibTask = [[NSTask alloc] init];
            [bibTask setCurrentDirectoryPath: [sourcePath  stringByDeletingLastPathComponent]];
            [bibTask setLaunchPath: @"/usr/local/bin/bibtex"];
            [bibTask setArguments:args];
            [bibTask setStandardOutput: outputPipe];
            [bibTask setStandardInput: inputPipe];
            [bibTask launch];
            }
        else if (whichEngine == 4) {
            indexPath = [sourcePath stringByDeletingPathExtension];
            [args addObject: indexPath];
        
            if (indexTask != nil) {
                [indexTask terminate];
                indexTask = nil;
                }
            indexTask = [[NSTask alloc] init];
            [indexTask setCurrentDirectoryPath: [sourcePath  stringByDeletingLastPathComponent]];
            [indexTask setLaunchPath: @"/usr/local/bin/makeindex"];
            [indexTask setArguments:args];
            [indexTask setStandardOutput: outputPipe];
            [indexTask setStandardInput: inputPipe];
            [indexTask launch];
            }

        }
}

- (void) doTex: sender 
{
    [self doJob: NO];
}

- (void) doLatex: sender;
{
    [self doJob: YES];
}

- (void) doBibtex: sender;
{
    [self doBibJob];
}

- (void) doIndex: sender;
{
    [self doIndexJob];
}


- (void) doTypeset: sender;
{
    NSString	*titleString;
    
    titleString = [sender title];
    if ([titleString isEqualToString: @"Tex"]) 
        [self doTex:self];
    else if ([titleString isEqualToString: @"Latex"])
        [self doLatex: self];
    else if ([titleString isEqualToString: @"Bibtex"])
        [self doBibtex: self];
    else if ([titleString isEqualToString: @"Index"])
        [self doIndex: self];
}

- (void) writeTexOutput: (NSNotification *)aNotification;
{
    NSString		*newOutput, *numberOutput, *searchString, *tempString;
    NSData		*myData;
    NSRange		myRange, lineRange, searchRange;
    int			error;
    unsigned int	myLength;
    unsigned		start, end, irrelevant;
    
    NSFileHandle *myFileHandle = [aNotification object];
    if (myFileHandle == readHandle) {
        myData = [[aNotification userInfo] 
            objectForKey:@"NSFileHandleNotificationDataItem"];
        if ([myData length]) {
            newOutput = [[NSString alloc] initWithData: myData encoding: NSMacOSRomanStringEncoding];
            if ((makeError) && ([newOutput length] > 2) && (errorNumber < NUMBEROFERRORS)) {
                    myLength = [newOutput length];
                    searchString = [NSString stringWithString:@"l."];
                    lineRange.location = 0;
                    lineRange.length = 1;
                    while (lineRange.location < myLength) {
                            [newOutput getLineStart: &start end: &end contentsEnd: &irrelevant 
                                forRange: lineRange];
                            lineRange.location = end;
                            searchRange.location = start;
                            searchRange.length = end - start;
                            tempString = [newOutput substringWithRange: searchRange];
                            myRange = [tempString rangeOfString: searchString];
                            if ((myRange.location = 1) && (myRange.length > 0)) {
                                numberOutput = [tempString substringFromIndex:(myRange.location + 1)];
                                error = [numberOutput intValue];
                                if ((error > 0) && (errorNumber < NUMBEROFERRORS)) {
                                    errorLine[errorNumber] = error;
                                    errorNumber++;
                                    }
                                }
                            }
                     }
                    
                    
                    
            [outputText replaceCharactersInRange: [outputText selectedRange]
                withString: newOutput];
            [outputText scrollRangeToVisible: [outputText selectedRange]];
            [newOutput release];
            [readHandle readInBackgroundAndNotify];
            }
        }
}

- (void) doTexCommand: sender;
{
    NSData *myData;
    char   *lineFeedString = "\n";
    
    if (inputPipe) {
        NSString *myString = [texCommand stringValue];
        NSString *returnString = [NSString stringWithCString:lineFeedString];
        NSString *newString = [myString stringByAppendingString: returnString];
        myData = [newString dataUsingEncoding: NSMacOSRomanStringEncoding allowLossyConversion:YES];
        [writeHandle writeData: myData];
        }
}

- (void) printSource: sender;
{
   
    NSPrintOperation	*printOperation;
    NSPrintInfo		*myPrintInfo;
    
    myPrintInfo = [self printInfo];
    [myPrintInfo setHorizontalPagination: NSFitPagination];
    [myPrintInfo setVerticallyCentered:NO];

    printOperation = [NSPrintOperation printOperationWithView:textView printInfo: myPrintInfo];
    [printOperation setShowPanels:YES];
    [printOperation runOperation];

}

- (void) doPreferences: sender;
{
    int	result;
    NSData		*myData;
    NSMutableArray	*myArray;
    NSString		*myString, *fullString;
    NSNumber		*aNumber;
    NSRect		frameRect;
    int			i;

    myPrefResult = 2;
    [fontChange selectCellWithTag: 0];
    [magChange selectCellWithTag: 0];
    [pdfWindowChange selectCellWithTag: 0];
    [pdfDisplayChange selectCellWithTag: myDisplayPref];
    [gsColor selectCellWithTag: myColorPref];
    [typesetChoice selectCellWithTag: myProgramPref];
    [sourceWindowChange selectCellWithTag: 0];
    [texEngine setStringValue: myTexEngine];
    [latexEngine setStringValue: myLatexEngine];
    result = [NSApp runModalForWindow: prefWindow];
    if (result == 0) {
        
        myString = [NSString stringWithString: @"~/Library/Preferences/TeXShop Prefs/TeXShop Preferences"];
        fullString = [myString stringByExpandingTildeInPath];
        myData = [myFileManager contentsAtPath: fullString];
        myArray = [NSUnarchiver unarchiveObjectWithData: myData];

        if ([[fontChange selectedCell] tag] == 1) {
            [myArray replaceObjectAtIndex: 1 withObject: [textView font]];
            } 
            
        if ([[magChange selectedCell] tag] == 1) { 
            aNumber = [NSNumber numberWithDouble: [[pdfView slider] doubleValue]];
            [myArray replaceObjectAtIndex: 2 withObject: aNumber];
            } 
            
        if ([[sourceWindowChange selectedCell] tag] == 1) {
            frameRect = [textWindow frame];
            aNumber = [NSNumber numberWithFloat: frameRect.origin.x];
            [myArray replaceObjectAtIndex: 3 withObject: aNumber];
             aNumber = [NSNumber numberWithFloat: frameRect.origin.y];
            [myArray replaceObjectAtIndex: 4 withObject: aNumber];
             aNumber = [NSNumber numberWithFloat: frameRect.size.width];
            [myArray replaceObjectAtIndex: 5 withObject: aNumber];
             aNumber = [NSNumber numberWithFloat: frameRect.size.height];
            [myArray replaceObjectAtIndex: 6 withObject: aNumber];
            }
             
        if ([[pdfWindowChange selectedCell] tag] == 1) {
            frameRect = [pdfWindow frame];
            aNumber = [NSNumber numberWithFloat: frameRect.origin.x];
            [myArray replaceObjectAtIndex: 7 withObject: aNumber];
             aNumber = [NSNumber numberWithFloat: frameRect.origin.y];
            [myArray replaceObjectAtIndex: 8 withObject: aNumber];
             aNumber = [NSNumber numberWithFloat: frameRect.size.width];
            [myArray replaceObjectAtIndex: 9 withObject: aNumber];
             aNumber = [NSNumber numberWithFloat: frameRect.size.height];
            [myArray replaceObjectAtIndex: 10 withObject: aNumber];
            }
            
        [myTexEngine release];
        myData = [[texEngine stringValue] dataUsingEncoding: NSMacOSRomanStringEncoding];
        myTexEngine = [[NSString alloc] initWithData: myData encoding: NSMacOSRomanStringEncoding];
        [myArray replaceObjectAtIndex: 11 withObject: myTexEngine];
        
        [myLatexEngine release];
        myData = [[latexEngine stringValue] dataUsingEncoding: NSMacOSRomanStringEncoding];
        myLatexEngine = [[NSString alloc] initWithData: myData encoding: NSMacOSRomanStringEncoding];
        [myArray replaceObjectAtIndex: 12 withObject: myLatexEngine];
        
        i = [[pdfDisplayChange selectedCell] tag];
        if (i != myDisplayPref) {
            myDisplayPref = i;
            aNumber = [NSNumber numberWithInt: myDisplayPref];
            [myArray replaceObjectAtIndex: 13 withObject: aNumber];
            if (myDisplayPref != 0) {
                [[pdfView slider] setNumberOfTickMarks: 5];
                [[pdfView slider] setAllowsTickMarkValuesOnly: YES];
                [pdfView changeSize: self];
                 }
            else {
                [[pdfView slider] setNumberOfTickMarks: 9];
                [[pdfView slider] setAllowsTickMarkValuesOnly: NO];
                }
            }

        i = [[gsColor selectedCell] tag];
        if (i != myColorPref) {
            myColorPref = i;
            aNumber = [NSNumber numberWithInt: myColorPref];
            [myArray replaceObjectAtIndex: 14 withObject: aNumber];
            }
            
        i = [[typesetChoice selectedCell] tag];
        if (i != myProgramPref) {
            myProgramPref = i;
            aNumber = [NSNumber numberWithInt: myProgramPref];
            [myArray replaceObjectAtIndex: 15 withObject: aNumber];
            }
           
        myData = [NSArchiver archivedDataWithRootObject: myArray];
        [myData writeToFile: fullString atomically: YES];

        }
}

- (void) chooseProgram: sender;
{
    id		theItem;
    int		which;
    
    theItem = [sender selectedItem];
    which = [theItem tag];
    
    switch (which) {
    
        case 0:
            [typesetButton setTitle: @"Tex"];
            break;
        
        case 1:
            [typesetButton setTitle: @"Latex"];
            break;

        
        case 2:
            [typesetButton setTitle: @"Bibtex"];
            break;
            
        case 3:
            [typesetButton setTitle: @"Index"];
            break;


        }
}

- (void) okPreferences: sender;
{
    myPrefResult = 0;
    [prefWindow close];
}

- (void) quitPreferences: sender;
{
    myPrefResult = 1;
    [prefWindow close];
}

- (void) okProject: sender;
{
    myPrefResult = 0;
    [projectPanel close];
}

- (void) quitProject: sender;
{
    myPrefResult = 1;
    [projectPanel close];
}


- (void) okForRequest: sender;
{
    myPrefResult = 0;
    [requestWindow close];
}

- (void) okForPrintRequest: sender;
{
    myPrefResult = 0;
    [printRequestPanel close];
}


- (void) okLine: sender;
{
    myPrefResult = 0;
    [linePanel close];
}

- (void) quitLine: sender;
{
    myPrefResult = 1;
    [linePanel close];
}




- (void) checkPrefClose: (NSNotification *)aNotification;
{
    int	finalResult;
    
    if (([aNotification object] == prefWindow) ||
        ([aNotification object] == projectPanel) ||
        ([aNotification object] == requestWindow) ||
        ([aNotification object] == linePanel) ||
        ([aNotification object] == printRequestPanel)) {
     
        finalResult = myPrefResult;
        if (finalResult == 2) finalResult = 0;
        [NSApp stopModalWithCode: finalResult];
        }
}

- (void) readPreferences;
{
    BOOL			isDir, success;
    NSString			*myString, *fullString;
    NSData			*myData;
    NSMutableArray		*myArray;
    NSFont			*aFont;
    NSNumber			*aNumber;
    NSRect			frameRect;
    NSString			*file;
    NSDirectoryEnumerator	*enumerator;
    int				versionNumber = 1;
    
    myString = [NSString stringWithString: @"~/Library/Preferences/TeXShop Prefs/Templates"];
    if (! [myFileManager fileExistsAtPath:[myString stringByExpandingTildeInPath] isDirectory: &isDir]) {
    
         myString = [NSString stringWithString: @"~/Library/Preferences/TeXShop Prefs"];
         if (! [myFileManager fileExistsAtPath: [myString stringByExpandingTildeInPath]])
            success = [myFileManager createDirectoryAtPath: [myString stringByExpandingTildeInPath] attributes: nil];
         myString = [NSString stringWithString: @"~/Library/Preferences/TeXShop Prefs/Templates"]; 
         fullString = [myString stringByExpandingTildeInPath];
         success = [myFileManager createDirectoryAtPath: fullString attributes: nil];
         
         myData = [NSData dataWithContentsOfFile: [[NSBundle mainBundle]
                pathForResource: @"TexTemplate" ofType: @"tex"]];
         [myFileManager createFileAtPath: [fullString stringByAppendingString: @"/TexTemplate.tex"] contents: myData attributes: nil];
         myData = [NSData dataWithContentsOfFile: [[NSBundle mainBundle]
                 pathForResource: @"LatexTemplate" ofType: @"tex"]];
         [myFileManager createFileAtPath: [fullString stringByAppendingString: @"/LatexTemplate.tex"] contents: myData attributes: nil];
         myData = [NSData dataWithContentsOfFile: [[NSBundle mainBundle]
                 pathForResource: @"GraphicsTemplate" ofType: @"tex"]];
         [myFileManager createFileAtPath: [fullString stringByAppendingString: @"/GraphicsTemplate.tex"] contents: myData attributes: nil];
        }
        
    myString = [NSString stringWithString: @"~/Library/Preferences/TeXShop Prefs/TeXShop Preferences"];
    fullString = [myString stringByExpandingTildeInPath];
    
    if ([myFileManager fileExistsAtPath: fullString])
        {
            NSMutableArray	*myArray;
            NSRect		frameRect;
            
            myData = [myFileManager contentsAtPath: fullString];
            myArray = [NSUnarchiver unarchiveObjectWithData: myData];
            aNumber = [myArray objectAtIndex: 0];
            versionNumber = [aNumber intValue];
            aFont = [myArray objectAtIndex: 1];
            [textView setFont: aFont];
            aNumber = [myArray objectAtIndex: 2];
            [[pdfView slider] setDoubleValue: [aNumber doubleValue]];
            
            aNumber = [myArray objectAtIndex: 3];
            frameRect.origin.x = [aNumber floatValue];
            aNumber = [myArray objectAtIndex: 4];
            frameRect.origin.y = [aNumber floatValue];
            aNumber = [myArray objectAtIndex: 5];
            frameRect.size.width = [aNumber floatValue];
            aNumber = [myArray objectAtIndex: 6];
            frameRect.size.height = [aNumber floatValue];
            [textWindow setFrame: frameRect display: NO];
            
            aNumber = [myArray objectAtIndex: 7];
            frameRect.origin.x = [aNumber floatValue];
            aNumber = [myArray objectAtIndex: 8];
            frameRect.origin.y = [aNumber floatValue];
            aNumber = [myArray objectAtIndex: 9];
            frameRect.size.width = [aNumber floatValue];
            aNumber = [myArray objectAtIndex: 10];
            frameRect.size.height = [aNumber floatValue];
            [pdfWindow setFrame: frameRect display: NO];
            myTexEngine = [[myArray objectAtIndex: 11] retain];
            myLatexEngine = [[myArray objectAtIndex: 12] retain];
            if (versionNumber == 2) {
                aNumber = [myArray objectAtIndex: 13];
                myDisplayPref = [aNumber intValue];
                aNumber = [myArray objectAtIndex: 14];
                myColorPref = [aNumber intValue];
                }
            else {
                myDisplayPref = 1;
                myColorPref = 1;
                }
            if (versionNumber > 2) {
                aNumber = [myArray objectAtIndex:15];
                myProgramPref = [aNumber intValue];
                }
            else
                myProgramPref = 1;
        }
    if (![myFileManager fileExistsAtPath: fullString]) {
        myDisplayPref = 1;
        myColorPref = 1;
        myProgramPref = 1;
        }
    if ((![myFileManager fileExistsAtPath: fullString]) || (versionNumber < 3))
        {
            myArray = [NSMutableArray arrayWithCapacity: 16];
            aNumber = [NSNumber numberWithInt: 3];
            [myArray insertObject: aNumber atIndex: 0];
            aFont = [textView font];
            [myArray insertObject: aFont atIndex: 1];
            aNumber = [NSNumber numberWithDouble: [[pdfView slider] doubleValue]];
            [myArray insertObject: aNumber atIndex: 2];
            
            frameRect = [textWindow frame];
            aNumber = [NSNumber numberWithFloat: frameRect.origin.x];
            [myArray insertObject: aNumber atIndex: 3];
             aNumber = [NSNumber numberWithFloat: frameRect.origin.y];
            [myArray insertObject: aNumber atIndex: 4];
             aNumber = [NSNumber numberWithFloat: frameRect.size.width];
            [myArray insertObject: aNumber atIndex: 5];
             aNumber = [NSNumber numberWithFloat: frameRect.size.height];
            [myArray insertObject: aNumber atIndex: 6];

            frameRect = [pdfWindow frame];
            aNumber = [NSNumber numberWithFloat: frameRect.origin.x];
            [myArray insertObject: aNumber atIndex: 7];
             aNumber = [NSNumber numberWithFloat: frameRect.origin.y];
            [myArray insertObject: aNumber atIndex: 8];
             aNumber = [NSNumber numberWithFloat: frameRect.size.width];
            [myArray insertObject: aNumber atIndex: 9];
             aNumber = [NSNumber numberWithFloat: frameRect.size.height];
            [myArray insertObject: aNumber atIndex: 10];
            if (myTexEngine == nil)
                myTexEngine = [[NSString stringWithString: @"/usr/local/bin/pdftex"] retain];
            [myArray insertObject: myTexEngine atIndex: 11];
            if (myLatexEngine == nil)
                myLatexEngine = [[NSString stringWithString: @"/usr/local/bin/pdflatex"] retain];
            [myArray insertObject: myLatexEngine atIndex: 12];
            aNumber = [NSNumber numberWithInt: 1];
            [myArray insertObject: aNumber atIndex: 13];
            aNumber = [NSNumber numberWithInt: 1];
            [myArray insertObject: aNumber atIndex: 14];
            aNumber = [NSNumber numberWithInt: 1];
            [myArray insertObject: aNumber atIndex: 15];

            myData = [NSArchiver archivedDataWithRootObject: myArray];
            [myFileManager createFileAtPath: fullString contents: myData attributes: nil];
        }
        
        myString = [NSString stringWithString: @"~/Library/Preferences/TeXShop Prefs/Templates"];
    	fullString = [myString stringByExpandingTildeInPath];
	enumerator = [myFileManager enumeratorAtPath: fullString];
        while (file = [enumerator nextObject]) 
            if ([[file pathExtension] isEqualToString: @"tex"]) {
                myString = [[file lastPathComponent] stringByDeletingPathExtension];
                [popupButton addItemWithTitle: myString];
                }
}

- (void) setProjectFile: sender;
{
     int		result;
     NSString		*project, *nameString, *anotherString;
     
     if (! [self fileName]) {
        result = [NSApp runModalForWindow: requestWindow];
        }
     else {
     
        myPrefResult = 2;
        project = [[[self fileName] stringByDeletingPathExtension]
            stringByAppendingString: @".texshop"];
        if ([myFileManager fileExistsAtPath: project]) {
            nameString = [NSString stringWithContentsOfFile: project];
            [projectName setStringValue: nameString];
            }
        else
            [projectName setStringValue: [[self fileName] lastPathComponent]];
        [projectName selectText: self];
        result = [NSApp runModalForWindow: projectPanel];
        if (result == 0) {
            nameString = [projectName stringValue];
            if ([nameString isAbsolutePath])
                [nameString writeToFile: project atomically: YES];
            else {
                anotherString = [[self fileName] stringByDeletingLastPathComponent];
                anotherString = [[anotherString stringByAppendingString:@"/"] 
                        stringByAppendingString: nameString];
                nameString = [anotherString stringByStandardizingPath];
                [nameString writeToFile: project atomically: YES];
                } 
            }
    }
}

- (void) doLine: sender;
{
    int		result, line;

    myPrefResult = 2;
    result = [NSApp runModalForWindow: linePanel];
    if (result == 0) {
        line = [lineBox intValue];
        [self toLine: line];
        }
}

- (void) doError: sender;
{
   if (errorNumber > 0) {
        [textWindow makeKeyAndOrderFront: self];
        [self toLine: errorLine[whichError]];
        whichError++;
        if (whichError >= errorNumber)
            whichError = 0;
        }
}

- (void) toLine: (int) line;
{
    int		i;
    NSString	*text;
    unsigned	start, end, irrelevant;
    NSRange	myRange;

    text = [textView string];
    myRange.location = 0;
    myRange.length = 1;
    for (i = 1; i <= line; i++) {
        [text getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
        myRange.location = end;
        }
    myRange.location = start;
    myRange.length = (end - start);
    [textView setSelectedRange: myRange];
    [textView scrollRangeToVisible: myRange];
}


- (int) displayPref;
{
   return myDisplayPref;
}

- (id) fileManager;
{
    return myFileManager;
}

- (int) colorPref;
{
    return myColorPref;
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    
    if (fileIsTex)
        return YES;
    else if ([[anItem title] isEqualToString:@"Tex"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"Latex"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"Bibtex"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"MakeIndex"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"Print..."]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"Set Project Root..."]) {
        return NO;
        }

    else return YES;
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    NSRange	matchRange;
    NSString	*textString;
    int		i, count, uchar, leftpar, rightpar;
    BOOL	done;
    NSDate	*myDate;
    
    if (replacementString == nil) return YES;
    if ([replacementString length] != 1) return YES;
    
    rightpar = [replacementString characterAtIndex:0];
    if ((rightpar != 0x007D) &&  (rightpar != 0x0029) &&  (rightpar != 0x005D)) return YES;
    
    if (rightpar == 0x007D) 
        leftpar = 0x007B;
    else if (rightpar == 0x0029) 
        leftpar = 0x0028;
    else 
        leftpar = 0x005B;
        
    textString = [textView string];
    i = affectedCharRange.location;
    count = 1;
    done = NO;
    while ((i > 0) && (! done)) {
        i--;
        uchar = [textString characterAtIndex:i];
        if (uchar == rightpar)
            count++;
        else if (uchar == leftpar)
            count--;
        if (count == 0) {
            done = YES;
            matchRange.location = i;
            matchRange.length = 1;
            [textView setSelectedRange: matchRange];
            [textView display];
            myDate = [NSDate date];
            while ([myDate timeIntervalSinceNow] > - 0.15);
            [textView setSelectedRange: affectedCharRange];
            }
        }
    return YES;
}

- (NSRange)textView:(NSTextView *)aTextView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange
{
    NSRange	replacementRange;
    NSString	*textString;
    int		length, i, j;
    BOOL	done;
    int		leftpar, rightpar, count, uchar;

    if (newSelectedCharRange.length != 1) return newSelectedCharRange;
    textString = [textView string];
    if (textString == nil) return newSelectedCharRange;
    length = [textString length];
    i = newSelectedCharRange.location;
    if (i >= length) return newSelectedCharRange;
    rightpar = [textString characterAtIndex: i];
    if ((rightpar != 0x007D) && (rightpar != 0x0029) && (rightpar != 0x005D)) return newSelectedCharRange;
    
    j = i;
    if (rightpar == 0x007D) 
        leftpar = 0x007B;
    else if (rightpar == 0x0029) 
        leftpar = 0x0028;
    else 
        leftpar = 0x005B;
    count = 1;
    done = NO;
    while ((i > 0) && (! done)) {
        i--;
        uchar = [textString characterAtIndex:i];
        if (uchar == rightpar)
            count++;
        else if (uchar == leftpar)
            count--;
        if (count == 0) {
            done = YES;
            replacementRange.location = i;
            replacementRange.length = j - i + 1;
            return replacementRange;
            }
        }
        
    return newSelectedCharRange;
}

@end

@implementation MyView

- (id)initWithFrame:(NSRect)frameRect
{
    id		value;
    
    value = [super initWithFrame: frameRect];
    gsRep = nil;
    [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(checkATaskStatus:) 
            name:NSTaskDidTerminateNotification 
            object:nil];
    fixScroll = NO;
    return value;
}

- (void)checkATaskStatus:(NSNotification *)aNotification {
    
    if ([aNotification object] != gsTask) return;
    gsTask = nil;

  if ([[myDocument fileManager] fileExistsAtPath: @"/tmp/texshoptemp.bmp"]) {
        if (gsRep != nil) {
            [gsRep release];
            gsRep = nil;
            }
        gsRep = [[NSBitmapImageRep imageRepWithContentsOfFile: @"/tmp/texshoptemp.bmp"] retain];
        [[myDocument fileManager] removeFileAtPath: @"/tmp/texshoptemp.bmp" handler: nil];
        if (fixScroll) {
            [[self superview] display];
            fixScroll = NO;
            }
        else
            [self display];
        }
}

- (void) drawWithGhostscript;
{
    NSString		*imagePath;
    NSMutableArray	*args;
    NSString		*gsLaunch;
    NSString		*theArgs;
    NSString		*aPage;
    NSString		*startPage;
    NSString		*endPage;
    NSString		*nameString;
    NSString		*projectPath;
    NSNumber		*aNumber;
    double		magsize, thesize;
    int			intsize, i;
    
        {
        projectPath = [[[myDocument fileName] stringByDeletingPathExtension] stringByAppendingString:@".texshop"];
        if ([[myDocument fileManager] fileExistsAtPath: projectPath]) {
            nameString = [NSString stringWithContentsOfFile: projectPath];
            imagePath = [[nameString stringByDeletingPathExtension] stringByAppendingString:@".pdf"];
            }
        else
            imagePath = [[[myDocument fileName] stringByDeletingPathExtension] stringByAppendingString:@".pdf"];
        

        if ([[myDocument fileManager] fileExistsAtPath: imagePath]) {
            args = [NSMutableArray array];
            if (gsTask != nil) {
                [gsTask terminate];
                gsTask = nil;
                }
            gsTask = [[NSTask alloc] init];
            [gsTask setCurrentDirectoryPath: [imagePath stringByDeletingLastPathComponent]];
            gsLaunch = [NSString stringWithString:@"/usr/local/bin/gs"];
            [gsTask setLaunchPath: gsLaunch];
            i = [myDocument colorPref];
            switch (i)  {
                case 0: theArgs = [NSString stringWithString:@"-sDEVICE=bmpgray"];
                        break;
                case 1:	theArgs = [NSString stringWithString:@"-sDEVICE=bmp256"];
                        break;
                case 2: theArgs = [NSString stringWithString:@"-sDEVICE=bmp16m"];
                        break;
                }
            [args addObject: theArgs];
        
            thesize = [mySize doubleValue];
            
            if (thesize < -.75)
                magsize = 38.0;
            else if (thesize < -.25)
                magsize = 52.0;
            else if (thesize < .25)
                magsize = 144.0;
            else if (thesize < .75)
                magsize = 108.0;
            else
                magsize = 144.0;
            intsize = magsize;
            aNumber = [NSNumber numberWithInt:intsize];
            aPage = [NSString stringWithString:@"-r"];
            theArgs = [aPage stringByAppendingString:[aNumber stringValue]]; 
            [args addObject: theArgs];
            theArgs = [NSString stringWithString:@"-dNOPAUSE"];
            [args addObject: theArgs];
            theArgs = [NSString stringWithString:@"-dBATCH"];
            [args addObject: theArgs];
            theArgs = [NSString stringWithString:@"-sOutputFile=/tmp/texshoptemp.bmp"];
            [args addObject: theArgs];
            aPage = [NSString stringWithString:@"-dFirstPage="];
            aNumber = [NSNumber numberWithInt:([myRep currentPage] + 1)];
            startPage = [aPage stringByAppendingString:[aNumber stringValue]];
            [args addObject: startPage];
            aPage = [NSString stringWithString:@"-dLastPage="];
            endPage = [aPage stringByAppendingString:[aNumber stringValue]];
            [args addObject: endPage];
            [args addObject: imagePath];
            [gsTask setArguments:args];
            [gsTask launch];
            }
    }
}

- (void)drawRect:(NSRect)aRect 
{
    
    if (myRep != nil) {
        [totalPage setIntValue: [myRep pageCount]];
        [currentPage setIntValue: ([myRep currentPage] + 1)]; 
        [currentPage display];
        if ([myDocument displayPref] == 0) {
            NSEraseRect([self bounds]);
            [myRep draw];
            }
        else if (gsRep != nil) {
            NSEraseRect([self bounds]);
            [gsRep draw];
            }
        }
}

- (void) previousPage: sender
{	int	pagenumber;

        if (myRep != nil) {
            pagenumber = [myRep currentPage];
            if (pagenumber > 0) {
                pagenumber--;
                [currentPage setIntValue: (pagenumber + 1)];
                [myRep setCurrentPage: pagenumber];
                [currentPage display];
                /*
                 if (gsRep != nil) {
                    [gsRep release];
                    gsRep = nil;
                    }
                */
                if ([myDocument displayPref] == 0)
                    [self display];
                else {
                    [self drawWithGhostscript];
                    }
                }
            }
}

- (void) nextPage: sender;
{	int	pagenumber;

        if (myRep != nil) {
            pagenumber = [myRep currentPage];
            if (pagenumber < ([myRep pageCount]) - 1) {
                pagenumber++;
                [currentPage setIntValue: (pagenumber + 1)];
                [myRep setCurrentPage: pagenumber];
                [currentPage display];
                /*
                if (gsRep != nil) {
                    [gsRep release];
                    gsRep = nil;
                    }
                */
                if ([myDocument displayPref] == 0)
                    [self display];
                else
                    [self drawWithGhostscript];
                }
            }
}

- (void) goToPage: sender;
{	int	pagenumber;

        if (myRep != nil) {
            pagenumber = [currentPage intValue];
            if (pagenumber < 1) pagenumber = 1;
            if (pagenumber > [myRep pageCount]) pagenumber = [myRep pageCount];
            [currentPage setIntValue: pagenumber];
            [currentPage display];
            [myRep setCurrentPage: (pagenumber - 1)];
            /*
            if (gsRep != nil) {
                    [gsRep release];
                    gsRep = nil;
                    }
            */
            if ([myDocument displayPref] == 0)
                [self display];
            else
                [self drawWithGhostscript];
            }
}

- (void) changeSize: sender;
{
    
        NSRect	myBounds, newBounds;
        double	thesize, magsize;
        
        thesize = [mySize doubleValue];
        if ([myDocument displayPref] != 0) {
            if (thesize < -.75)
                // thesize = -1;
                magsize = .5;
            else if (thesize < -.25)
                //thesize = -.5;
                magsize = .75;
            else if (thesize < .25)
                // thesize = 0;
                magsize = 1.0;
            else if (thesize < .75)
                // thesize = .5;
                magsize = 1.5;
            else
                // thesize = 1.0;
                magsize = 2.0;
           /*  [mySize setDoubleValue: thesize]; */
            }
        else
            magsize = pow(2, thesize); 

        myBounds = [self bounds];
        newBounds.size.width = myBounds.size.width * (magsize);
        newBounds.size.height = myBounds.size.height * (magsize);
        [self setFrame: newBounds];
        [self setBounds: myBounds];
        /*
        if (gsRep != nil) {
            [gsRep release];
            gsRep = nil;
            }
        */
        if ([myDocument displayPref] == 0)
            [[self superview] display];
        else {
            fixScroll = YES;
            [self drawWithGhostscript];
            }
}


- (void) setImageRep: (NSPDFImageRep *)theRep;
{
    int		pagenumber;
    NSRect	myBounds, newBounds;
    
    double	thesize;
    double	magsize;
   
    thesize = [mySize doubleValue];
    if ([myDocument displayPref] != 0) {
            if (thesize < -.75)
                 magsize = .5;
            else if (thesize < -.25)
                magsize = .75;
            else if (thesize < .25)
                magsize = 1.0;
            else if (thesize < .75)
                magsize = 1.5;
            else
                magsize = 2.0;
            }
        else
            magsize = pow(2, thesize); 

    /*
    if (gsRep != nil) {
            [gsRep release];
            gsRep = nil;
            }
    */
    if (theRep != nil)
     
        {
        if (myRep != nil) {
            pagenumber = [myRep currentPage] + 1;
            [myRep release];
            }
        else
            pagenumber = 1;
        myRep = theRep;
        [totalPage setIntValue: [myRep pageCount]];
        if (pagenumber < 1) pagenumber = 1;
        if (pagenumber > [myRep pageCount]) pagenumber = [myRep pageCount];
        [currentPage setIntValue: pagenumber];
        [currentPage display];
        [myRep setCurrentPage: (pagenumber - 1)];
        myBounds = [myRep bounds];
        newBounds.size.width = myBounds.size.width * (magsize);
        newBounds.size.height = myBounds.size.height * (magsize);
        [self setFrame: newBounds];
        [self setBounds: myBounds];
        [[self superview] display];
        }
}

- (void) printDocument: sender;
{
    /* NSLog(@"here"); */
    [myDocument printDocument: sender];
}	

- (void) printSource: sender;
{
    [myDocument printSource: sender];
}

- (void) destroyGSRep;
{
    if (gsRep != nil) {
        [gsRep release];
        gsRep = nil;
        }
}

- (id) slider;
{
    return mySize;
}

- (void) setDocument: (id) theDocument;
{
    myDocument = theDocument;
}

- (void)dealloc {
    if (gsTask != nil)
            [gsTask terminate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];       
    [super dealloc];
}



@end

@implementation PrintView

- (PrintView *) initWithRep: (NSPDFImageRep *) aRep  andDisplayPref: (int) displayPref;
{
    id		value;
    
    myRep = aRep;
    myDisplayPref = displayPref;
    value = [super initWithFrame: [myRep bounds]];
    return self;
}

- (void)drawRect:(NSRect)aRect 
{
    NSEraseRect([self bounds]);
    if (myRep != nil) {
        [myRep draw];
        }
}


- (BOOL) knowsPageRange:(NSRangePointer)range;
{
    (*range).location = 1;
    (*range).length = [myRep pageCount];
    return YES;
}

- (BOOL)isVerticallyCentered;
{
    return YES;
}

- (BOOL)isHorizontallyCentered;
{
    return YES;
}


- (NSRect)rectForPage:(int)pageNumber;
{
    int		thePage;
    NSRect	aRect;

    thePage = pageNumber;
    if (thePage < 1) thePage = 1;
    if (thePage > [myRep pageCount]) thePage = [myRep pageCount];
    [myRep setCurrentPage: thePage - 1];
    aRect = [myRep bounds];
    return aRect;
}


- (void)dealloc {
    [myRep release];
    [super dealloc];
}

- (void) setPrintOperation: (NSPrintOperation *)aPrintOperation;
{
    myPrintOperation = aPrintOperation;
}

@end

@implementation MyWindow

- (void) printDocument: sender;
{
    [myDocument printDocument: sender];
}

- (void) printSource: sender;
{
    [myDocument printSource: sender];
}

- (void) doPreferences: sender;
{
    [myDocument doPreferences: sender];
}

- (void) doTex: sender;
{
    [myDocument doTex: sender];
}

- (void) doLatex: sender;
{
    [myDocument doLatex: sender];
}

- (void) doBibtex: sender;
{
    [myDocument doBibtex: sender];
}

- (void) doIndex: sender;
{
    [myDocument doIndex: sender];
}



- (void) previousPage: sender;
{
    [[myDocument pdfView] previousPage: sender];
}

- (void) nextPage: sender;
{
    [[myDocument pdfView] nextPage: sender];
}

- (void) doError: sender;
{
    [myDocument doError: sender];
}


@end


@implementation ConsoleWindow

- (void) doError: sender;
{
    [myDocument doError: sender];
}


@end



