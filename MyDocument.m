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
    unsigned		length;
    BOOL		imageFound;
    
    [super windowControllerDidLoadNib:aController];
    // Add any code here that need to be executed once the windowController has loaded the document's window.
    
    errorNumber = 0;
    whichError = 0;
    makeError = NO;
    colorStart = 0; colorEnd = 0; returnline = NO; tagLine = NO;
    colorTE = 0;
    tagTE = 0;

    fileIsTex = YES;
    myFileManager = [[NSFileManager defaultManager] retain];
    myTexEngine = nil; myLatexEngine = nil;
    [pdfView setDocument: self];
    [textView setDelegate: self];

    [self readPreferences];
    
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
            }
            
/* handle images */
    myImageType = isTeX;
    [pdfView setImageType: isTeX];
        
    if (! fileIsTex) {
        imageFound = NO;
        imagePath = [self fileName];
        
        if ([fileExtension isEqualToString: @"pdf"]) {
            imageFound = YES;
            texRep = [[NSPDFImageRep imageRepWithContentsOfFile: imagePath] retain];
            [pdfWindow setTitle: [[self fileName] lastPathComponent]]; 
            myImageType = isPDF;
            }
        else if (([fileExtension isEqualToString: @"jpg"]) || 
                ([fileExtension isEqualToString: @"jpeg"]) ||
                ([fileExtension isEqualToString: @"JPG"])) {
            imageFound = YES;
            texRep = [[NSBitmapImageRep imageRepWithContentsOfFile: imagePath] retain];
            [pdfWindow setTitle: [[self fileName] lastPathComponent]]; 
            myImageType = isJPG;
            }
        else if ([fileExtension isEqualToString: @"tiff"]) {
            imageFound = YES;
            texRep = [[NSBitmapImageRep imageRepWithContentsOfFile: imagePath] retain];
            [pdfWindow setTitle: [[self fileName] lastPathComponent]]; 
            myImageType = isTIFF;
            }
        /* gs cannot interpret eps!
        else if ([fileExtension isEqualToString: @"eps"]) {
            imageFound = YES;
            texRep = [[NSEPSImageRep imageRepWithContentsOfFile: imagePath] retain];
            [pdfWindow setTitle: [[self fileName] lastPathComponent]]; 
            myImageType = isEPS;
            }
        */
                            
        if (imageFound) {
                [pdfView setImageType: myImageType];
                [pdfView setImageRep: texRep]; // this releases old one!
                if (myImageType == isPDF) {
                    topLeftRect = [texRep bounds];
                    topLeftPoint.x = topLeftRect.origin.x;
                    topLeftPoint.y = topLeftRect.origin.y + topLeftRect.size.height - 1;
                    [pdfView scrollPoint: topLeftPoint];
                    }
                [pdfView display];
                [pdfWindow makeKeyAndOrderFront: self];
                if (myImageType == isEPS)
                    [pdfView drawWithGhostscript];
                else if (([self displayPref] != 0) && (myImageType == isPDF))
                    [pdfView drawWithGhostscript];
                return;
                }
        }
 /* end of images */
            


    if (aString == nil) 
        ;
    else {
        
        [textView setString: aString];
        length = [aString length];
        [self setupTags];
        
        if ((colorSyntax) && (fileIsTex)) {
            colorLocation = 0;
             /*
            [self fixColor:0 :length];
            */
            colorTE = [[NSTimer scheduledTimerWithTimeInterval: .02 target:self
                selector:@selector(fixColor1:)
                userInfo:nil repeats:YES] retain];
            }
            
            
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
    
    if (!fileIsTex) return;
    
    if (myProgramPref == 0)
        [typesetButton setTitle: @"Tex"];
    else
        [typesetButton setTitle: @"Latex"];
    

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
    
- (void)close{
    if (colorTE != 0) {
        [colorTE invalidate];
        [colorTE release];
        colorTE = 0;
        }
    if (tagTE != 0) {
        [tagTE invalidate];
        [tagTE release];
        tagTE = 0;
        }
    [super close];
}
    
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (colorTE != 0) {
        [colorTE invalidate];
        [colorTE release];
        colorTE = 0;
        }
    if (tagTE != 0) {
        [tagTE invalidate];
        [tagTE release];
        tagTE = 0;
        }
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

- (void) fixTemplate: (id) theDictionary;
{
    NSRange		oldRange;
    NSString		*oldString, *newString;
    NSUndoManager	*myManager;
    NSMutableDictionary	*myDictionary;
    NSNumber		*theLocation, *theLength;
    unsigned		from, to;
    
    oldRange.location = [[theDictionary objectForKey: @"oldLocation"] unsignedIntValue];
    oldRange.length = [[theDictionary objectForKey: @"oldLength"] unsignedIntValue];
    newString = [theDictionary objectForKey: @"oldString"];
    oldString = [[textView string] substringWithRange: oldRange];
    [textView replaceCharactersInRange: oldRange withString: newString];

    myManager = [textView undoManager];
    myDictionary = [NSMutableDictionary dictionaryWithCapacity: 3];
    theLocation = [NSNumber numberWithInt: oldRange.location];
    theLength = [NSNumber numberWithInt: [newString length]];
    [myDictionary setObject: oldString forKey: @"oldString"];
    [myDictionary setObject: theLocation forKey: @"oldLocation"];
    [myDictionary setObject: theLength forKey: @"oldLength"];
    [myManager registerUndoWithTarget:self selector:@selector(fixTemplate:) object: myDictionary];
    [myManager setActionName:@"Template"];
    from = oldRange.location;
    to = from + [newString length];
    [self fixColor: from :to];
    [self setupTags];

}


- (void) doTemplate: sender {
 
    NSString		*templateString, *nameString, *oldString;
    id			theItem;
    unsigned		from, to;
    NSRange		myRange;
    NSUndoManager	*myManager;
    NSMutableDictionary	*myDictionary;
    NSNumber		*theLocation, *theLength;
    
    theItem = [sender selectedItem];
    
    if (theItem) {
        nameString = [NSString stringWithString: @"~/Library/Preferences/TeXShop Prefs/Templates/"];
        nameString = [nameString stringByAppendingString:[theItem title]]; 
        nameString = [[nameString stringByAppendingString: @".tex"] stringByExpandingTildeInPath];
        templateString = [NSString stringWithContentsOfFile: nameString];
        if (templateString != nil) {
            myRange = [textView selectedRange];
            oldString = [[textView string] substringWithRange: myRange];
            [textView replaceCharactersInRange: myRange withString: templateString];
            
            myManager = [textView undoManager];
            myDictionary = [NSMutableDictionary dictionaryWithCapacity: 3];
            theLocation = [NSNumber numberWithUnsignedInt: myRange.location];
            theLength = [NSNumber numberWithUnsignedInt: [templateString length]];
            [myDictionary setObject: oldString forKey: @"oldString"];
            [myDictionary setObject: theLocation forKey: @"oldLocation"];
            [myDictionary setObject: theLength forKey: @"oldLength"];
            [myManager registerUndoWithTarget:self selector:@selector(fixTemplate:) object: myDictionary];
            [myManager setActionName:@"Template"];
    
            from = myRange.location;
            to = from + [templateString length];
            [self fixColor: from :to];
            [self setupTags];
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
            [args addObject: [sourcePath lastPathComponent]];
        
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
            [args addObject: [bibPath lastPathComponent]];
        
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
            [args addObject: [indexPath lastPathComponent]];
        
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
    BOOL		oldValue;
    int			theState;

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
    if (matchParen)
        [parenMatch setState: NSOnState];
    else
        [parenMatch setState: NSOffState];
    if (colorSyntax)
        [syntaxColor setState: NSOnState];
    else
        [syntaxColor setState: NSOffState];
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
            
        oldValue = matchParen;
        theState = [parenMatch state];
        if (theState == NSOnState)
            matchParen = YES;
        else
            matchParen = NO;
        if (matchParen != oldValue) {
            aNumber = [NSNumber numberWithBool: matchParen];
            [myArray replaceObjectAtIndex: 16 withObject: aNumber];
            }
    
        oldValue = colorSyntax;
        theState = [syntaxColor state];
        if (theState == NSOnState)
            colorSyntax = YES;
        else
            colorSyntax = NO;
        if (colorSyntax != oldValue) {
            aNumber = [NSNumber numberWithBool: colorSyntax];
            [myArray replaceObjectAtIndex: 17 withObject: aNumber];
            if (colorSyntax) {
                if (fileIsTex) {
                    if (colorTE != 0) {
                        [colorTE invalidate];
                        [colorTE release];
                        }
                    colorLocation = 0;
                    colorTE = [[NSTimer scheduledTimerWithTimeInterval: .02 target:self
                            selector:@selector(fixColor1:)
                            userInfo:nil repeats:YES] retain];
                    }
                }
            else {
                if (fileIsTex) {
                    if (colorTE != 0) {
                        [colorTE invalidate];
                        [colorTE release];
                        }
                    colorLocation = 0;
                    colorTE = [[NSTimer scheduledTimerWithTimeInterval: .02 target:self
                            selector:@selector(fixColorBlack:)
                            userInfo:nil repeats:YES] retain];
                    }
                }
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
            if (versionNumber > 1) {
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
            if (versionNumber > 3) {
                aNumber = [myArray objectAtIndex:16];
                matchParen = [aNumber boolValue];
                aNumber = [myArray objectAtIndex:17];
                colorSyntax = [aNumber boolValue];
                }
            else {
                matchParen = YES;
                colorSyntax = YES;
                }
                
        }
    if (![myFileManager fileExistsAtPath: fullString]) {
        myDisplayPref = 1;
        myColorPref = 1;
        myProgramPref = 1;
        }
    if ((![myFileManager fileExistsAtPath: fullString]) || (versionNumber < 4))
        {
            myArray = [NSMutableArray arrayWithCapacity: 18];
            aNumber = [NSNumber numberWithInt: 4];
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
            aNumber = [NSNumber numberWithBool: YES];
            [myArray insertObject: aNumber atIndex: 16];
            aNumber = [NSNumber numberWithBool: YES];
            [myArray insertObject: aNumber atIndex: 17];

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

- (void) fixTags: sender;
{   
    NSString	*text, *tagString;
    unsigned	start, end, irrelevant;
    NSRange	myRange, nameRange;
    unsigned	length, index;
    int		theChar;

    if (fileIsTex) {
        text = [textView string];
        length = [text length];
        index = tagLocation + 10000;
        myRange.location = tagLocation;
        myRange.length = 1;
        while ((myRange.location < length) && (myRange.location < index)) {
            [text getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
            myRange.location = end;
            if (start < length - 3) {
                theChar = [text characterAtIndex: start];
                if (theChar == 0x0025) {
                    theChar = [text characterAtIndex: (start + 1)];
                    if (theChar == 0x003a) {
                        nameRange.location = start + 2;
                        nameRange.length = (end - start - 2);
                        tagString = [text substringWithRange: nameRange];
                        [tags addItemWithTitle:tagString];
                        }
                     }
                }
            }
        tagLocation = myRange.location;
        if (tagLocation >= length) {
            [tagTE invalidate];
            [tagTE release];
            tagTE = 0;
            }
        }
}

- (void) doTag: sender;
{
    NSString	*text, *tagString, *title;
    unsigned	start, end, irrelevant;
    NSRange	myRange, nameRange, gotoRange;
    unsigned	length;
    int		theChar;
    BOOL	done;
    
    title = [tags titleOfSelectedItem];
    text = [textView string];
    length = [text length];
    myRange.location = 0;
    myRange.length = 1;
    done = NO;
    while ((myRange.location < length) && (!done)) {
        [text getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
        myRange.location = end;
        if (start < length - 3) {
            theChar = [text characterAtIndex: start];
            if (theChar == 0x0025) {
                theChar = [text characterAtIndex: (start + 1)];
                if (theChar == 0x003a) {
                    nameRange.location = start + 2;
                    nameRange.length = (end - start - 2);
                    tagString = [text substringWithRange: nameRange];
                    if ([title isEqualToString:tagString]) {
                        done = YES;
                        gotoRange.location = start;
                        gotoRange.length = (end - start);
                        [textView setSelectedRange: gotoRange];
                        [textView scrollRangeToVisible: gotoRange];
                        }
                    }
                }
            }
        }
}

- (void) setupTags;
{
    if (tagTE != 0) {
        [tagTE invalidate];
        [tagTE release];
        tagTE = 0;
        }
    tagLocation = 0;
    [tags removeAllItems];
    [tags addItemWithTitle:@"Tags"];
    tagTE = [[NSTimer scheduledTimerWithTimeInterval: .02 target:self
        selector:@selector(fixTags:)
        userInfo:nil repeats:YES] retain];
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

- (int) imageType;
{
    return myImageType;
}



- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    BOOL  result;
    
    result = [super validateMenuItem: anItem];
    if (fileIsTex)
        return result;
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

    else return result;
}

BOOL isText(long aChar);

- (void)textDidChange:(NSNotification *)aNotification;
{
   [self fixColor :colorStart :colorEnd];
    if (tagLine) 
        [self setupTags];
    colorStart = 0;
    colorEnd = 0;
    returnline = NO;
    tagLine = NO;
}



- (void)fixColor: (unsigned)from : (unsigned)to
{
    NSRange	colorRange;
    NSString	*textString;
    NSColor	*commentColor, *commandColor, *regularColor;
    long	length, location, final;
    unsigned	start1, end1;
    int		theChar;
    unsigned	end;
    
    if ((! colorSyntax) || (! fileIsTex)) return;
   
    commentColor = [NSColor redColor];
    commandColor = [NSColor blueColor];
    regularColor = [NSColor blackColor];
 
    textString = [textView string];
    length = [textString length];
    
    if (returnline) {
        colorRange.location = from + 1;
        colorRange.length = 0;
        }
    
    else {
    
    if (from < length)
        colorRange.location = from;
    else
        colorRange.location = 0;
        
    if (to < length)
        colorRange.length = to - colorRange.location;
    else
        colorRange.length = length;
    }

    [textString getLineStart:&start1 end:&end1 contentsEnd:&end forRange:colorRange];
    
    location = start1;
    final = end1;

    colorRange.location = start1;
    colorRange.length = end1 - start1;
    [textView setTextColor: regularColor range: colorRange];
        
    while (location < final) {
            theChar = [textString characterAtIndex: location];
            
             if (theChar == 0x0025) {
                colorRange.location = location;
                colorRange.length = 0;
                [textString getLineStart:nil end:nil contentsEnd:&end forRange:colorRange];
                colorRange.length = (end - location);
                [textView setTextColor: commentColor range: colorRange];
                colorRange.location = colorRange.location + colorRange.length - 1;
                colorRange.length = 0;
                [textView setTextColor: regularColor range: colorRange];
                location = end;
                }
                
             else if (theChar == 0x005c) {
                colorRange.location = location;
                colorRange.length = 1;
                location++;
                if ((location < final) && ([textString characterAtIndex: location] == 0x0025)) {
                    colorRange.length = location - colorRange.location;
                    location++;
                    }
                else while ((location < final) && (isText([textString characterAtIndex: location]))) {
                    location++;
                    colorRange.length = location - colorRange.location;
                    }
                [textView setTextColor: commandColor range: colorRange];
                colorRange.location = location;
                colorRange.length = 0;
                [textView setTextColor: regularColor range: colorRange];
                }

            else
                location++;
            }
        
}

- (void)fixColor1: sender;
{
    NSRange	colorRange;
    NSString	*textString;
    NSColor	*commentColor, *commandColor, *regularColor;
    long	length, limit;
    int		theChar;
    unsigned	end;

    limit = colorLocation + 5000;
    commentColor = [NSColor redColor];
    commandColor = [NSColor blueColor];
    regularColor = [NSColor blackColor];
 
    textString = [textView string];
    length = [textString length];
    
    while ((colorLocation < length) && (colorLocation < limit))  {
            theChar = [textString characterAtIndex: colorLocation];
            
            if (theChar == 0x0025) {
                colorRange.location = colorLocation;
                colorRange.length = 0;
                [textString getLineStart:nil end:nil contentsEnd:&end forRange:colorRange];
                colorRange.length = (end - colorLocation);
                [textView setTextColor: commentColor range: colorRange];
                colorRange.location = colorRange.location + colorRange.length - 1;
                colorRange.length = 0;
                [textView setTextColor: regularColor range: colorRange];
                colorLocation = end;
                }
                
            else if (theChar == 0x005c) {
                colorRange.location = colorLocation;
                colorRange.length = 1;
                colorLocation++;
                if ((colorLocation < length) && ([textString characterAtIndex: colorLocation] == 0x0025)) {
                    colorRange.length = colorLocation - colorRange.location;
                    colorLocation++;
                    }
                else while ((colorLocation < length) && (isText([textString characterAtIndex: colorLocation]))) {
                    colorLocation++;
                    colorRange.length = colorLocation - colorRange.location;
                    }
                [textView setTextColor: commandColor range: colorRange];
                colorRange.location = colorLocation;
                colorRange.length = 0;
                [textView setTextColor: regularColor range: colorRange];
                }
                
            else
                colorLocation++;
            }
            
        if (colorLocation >= length) {
            [colorTE invalidate];
            [colorTE release];
            colorTE = 0;
            }
}

- (void)fixColorBlack: sender;
{
    NSRange	colorRange;
    NSString	*textString;
    NSColor	*regularColor;
    unsigned	length, limit, start, end;

    limit = colorLocation + 5000;
    regularColor = [NSColor blackColor];
    textString = [textView string];
    length = [textString length];
    
    while ((colorLocation < length) && (colorLocation < limit))  {
            colorRange.location = colorLocation;
            colorRange.length = 0;
            [textString getLineStart:&start end:&end contentsEnd:nil forRange:colorRange];
            colorRange.length = (end - start);
            [textView setTextColor: regularColor range: colorRange];
            colorLocation = colorRange.location + colorRange.length;
            }
                
            
    if (colorLocation >= length) {
        [colorTE invalidate];
        [colorTE release];
        colorTE = 0;
        }
}



- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    NSRange	matchRange, tagRange;
    NSString	*textString;
    int		i, count, uchar, leftpar, rightpar;
    BOOL	done;
    NSDate	*myDate;
    unsigned 	start, end, end1;
    
    colorStart = affectedCharRange.location;
    colorEnd = colorStart;
    
    tagRange = [replacementString rangeOfString:@"%:"];
    if (tagRange.length != 0)
        tagLine = YES;
        
    textString = [textView string];
    [textString getLineStart:&start end:&end contentsEnd:&end1 forRange:affectedCharRange];
    tagRange.location = start;
    tagRange.length = end - start;
    matchRange = [textString rangeOfString:@"%:" options:0 range:tagRange];
    if (matchRange.length != 0)
        tagLine = YES;

    
    
    if (replacementString == nil) 
        return YES;
    else
        colorEnd = colorStart + [replacementString length];
    
    if ([replacementString length] != 1) return YES;
    rightpar = [replacementString characterAtIndex:0];
    if (rightpar == 0x000a)
        returnline = YES;
        
    if (! matchParen) return YES;
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
            /* here 'affinity' and 'stillSelecting' are necessary, else the wrong range is selected. ??*/
            [textView setSelectedRange: matchRange affinity: NSSelectByCharacter stillSelecting: YES];
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
    
    if ((rightpar == 0x007D) || (rightpar == 0x0029) || (rightpar == 0x005D)) {
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
            
    else if ((rightpar == 0x007B) || (rightpar == 0x0028) || (rightpar == 0x005B)) {
            j = i;
            leftpar = rightpar;
            if (leftpar == 0x007B) 
                rightpar = 0x007D;
            else if (leftpar == 0x0028) 
                rightpar = 0x0029;
            else 
                rightpar = 0x005D;
            count = 1;
            done = NO;
            while ((i < length) && (! done)) {
                i++;
                uchar = [textString characterAtIndex:i];
                if (uchar == leftpar)
                    count++;
                else if (uchar == rightpar)
                    count--;
                if (count == 0) {
                    done = YES;
                    replacementRange.location = j;
                    replacementRange.length = i - j + 1;
                    return replacementRange;
                    }
                }
            return newSelectedCharRange;
            }

    else return newSelectedCharRange;
}

@end

@implementation MyView

- (void) setImageType: (int)theType;
{
    imageType = theType;
}

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
        
    if (imageType == isTeX) {
        projectPath = [[[myDocument fileName] stringByDeletingPathExtension] stringByAppendingString:@".texshop"];
        if ([[myDocument fileManager] fileExistsAtPath: projectPath]) {
            nameString = [NSString stringWithContentsOfFile: projectPath];
            imagePath = [[nameString stringByDeletingPathExtension] stringByAppendingString:@".pdf"];
            }
        else
            imagePath = [[[myDocument fileName] stringByDeletingPathExtension] stringByAppendingString:@".pdf"];
        }
    else
        imagePath = [myDocument fileName];
        

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
        if ((imageType == isTeX) || (imageType == isPDF) || (imageType == isEPS)) {
            aPage = [NSString stringWithString:@"-dFirstPage="];
            if (imageType == isEPS)
                aNumber = [NSNumber numberWithInt: 1];
            else
                aNumber = [NSNumber numberWithInt:([myRep currentPage] + 1)];
            startPage = [aPage stringByAppendingString:[aNumber stringValue]];
            [args addObject: startPage];
            aPage = [NSString stringWithString:@"-dLastPage="];
            endPage = [aPage stringByAppendingString:[aNumber stringValue]];
            [args addObject: endPage];
            }
        [args addObject: imagePath];
        [gsTask setArguments:args];
        [gsTask launch];
        }
    }
}

- (void)drawRect:(NSRect)aRect 
{
    
    if (myRep != nil) {
        if ((imageType == isTeX) || (imageType == isPDF)) {
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
    else if ((imageType == isTIFF) || (imageType == isJPG)) {
            [currentPage display];
            NSEraseRect([self bounds]);
            [myRep draw];
            }
    else if (imageType == isEPS) {
            [currentPage display];
            if (gsRep != nil) {
                NSEraseRect([self bounds]);
                [gsRep draw];
                }
            }
        }
}

- (void) previousPage: sender
{	int	pagenumber;

        if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
        
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

        if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;

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

        if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) {
            [currentPage setIntValue: 1];
            [currentPage display];
            return;
            }

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
        if ((imageType == isTeX) || (imageType == isPDF)) {
            if ([myDocument displayPref] == 0)
                [[self superview] display];
            else {
                fixScroll = YES;
                [self drawWithGhostscript];
                }
            }
        else if ((imageType == isTIFF) || (imageType == isJPG))
            [[self superview] display];
        else if (imageType == isEPS) {
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
        
        if ((imageType == isTeX) || (imageType == isPDF)) {   
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
            }
        else {
            [totalPage setIntValue: 1];
            [currentPage setIntValue: 1];
            [currentPage display];
            }
        
        [[self superview] display];
        }
}

- (void) printDocument: sender;
{
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

@implementation MainWindow

- (void)makeKeyAndOrderFront:(id)sender;
{
   if ([myDocument imageType] == isTeX)
        [super makeKeyAndOrderFront: sender];
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

- (void) orderOut:sender;
{
    if ([myDocument imageType] != isTeX) {
        [myDocument close];
        }
    else
        [super orderOut: sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
{
  if ([myDocument imageType] == isTeX)
    return YES;
  else if ([[anItem title] isEqualToString:@"Tex"]) 
        return NO;
  else if ([[anItem title] isEqualToString:@"Latex"]) 
        return NO;
  else if ([[anItem title] isEqualToString:@"Bibtex"]) 
        return NO;
  else if ([[anItem title] isEqualToString:@"MakeIndex"]) 
        return NO;
  else if ([[anItem title] isEqualToString:@"Print..."]) 
        return NO;
  else
    return YES;
}


@end


@implementation ConsoleWindow

- (void) doError: sender;
{
    [myDocument doError: sender];
}


@end



