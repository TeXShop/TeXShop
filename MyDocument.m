// MyDocument.m

// Created by dick in July, 2000.

#import <AppKit/AppKit.h>
#import "MyDocument.h"
#import "PrintView.h"
#import "MyView.h"
#import "TSPreferences.h"
#import "TSWindowManager.h"
#import "extras.h"
#import "globals.h"

#define SUD [NSUserDefaults standardUserDefaults]

@implementation MyDocument : NSDocument

//-----------------------------------------------------------------------------
- (id)init
//-----------------------------------------------------------------------------
{
    [super init];
    
    errorNumber = 0;
    whichError = 0;
    makeError = NO;
    colorStart = 0; 
    colorEnd = 0; 
    returnline = NO; 
    tagLine = NO;
    fileIsTex = YES;
    
    return self;
}

//-----------------------------------------------------------------------------
- (void)dealloc 
//-----------------------------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (syntaxColoringTimer != nil) 
    {
        [syntaxColoringTimer invalidate];
        [syntaxColoringTimer release];
    }
    if (tagTimer != nil) 
    {
        [tagTimer invalidate];
        [tagTimer release];
    }
    [super dealloc];
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
    
    imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
    if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) {
        aRep = [[NSPDFImageRep imageRepWithContentsOfFile: imagePath] retain];
        printView = [[PrintView alloc] initWithRep: aRep];
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
    

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{    
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
    [self registerForNotifications];    
	[self setupFromPreferencesUsingWindowController:aController];

    [pdfView setDocument: self]; /* This was commented out!! Don't do it; needed by Ghostscript; Dick */
    [textView setDelegate: self];
    [pdfView resetMagnification]; 
    
    fileExtension = [[self fileName] pathExtension];
    if (( ! [fileExtension isEqualToString: @"tex"]) && ( ! [fileExtension isEqualToString: @"TEX"]) &&
        ([[NSFileManager defaultManager] fileExistsAtPath: [self fileName]]))
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
                return;
                }
        }
 /* end of images */
            
    if (aString != nil) 
    {	
        [textView setString: aString];
        length = [aString length];
        [self setupTags];
        
        if (([SUD boolForKey:SyntaxColoringEnabledKey]) && (fileIsTex)) 
        {
            colorLocation = 0;
             /*
            [self fixColor:0 :length];
            */
            syntaxColoringTimer = [[NSTimer scheduledTimerWithTimeInterval: .02 target:self selector:@selector(fixColor1:) userInfo:nil repeats:YES] retain];
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
    
    if ([SUD integerForKey:DefaultCommandKey] == DefaultCommandTeX)
        [typesetButton setTitle: @"Tex"];
    else
        [typesetButton setTitle: @"Latex"];
    
    projectPath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"texshop"];
    if ([[NSFileManager defaultManager] fileExistsAtPath: projectPath]) {
        nameString = [NSString stringWithContentsOfFile: projectPath];
        imagePath = [[nameString stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
        }
    else
        imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
    if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) {
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
            }
        }
}

//-----------------------------------------------------------------------------
- (void)registerForNotifications
//-----------------------------------------------------------------------------
/*" This method registers all notifications that are necessary to work properly together with the other AppKit and TeXShop objects.
"*/
{
    // register for notifications when the document window becomes key so we can remember which window was
    // the frontmost. This is needed for the preferences.
    [[NSNotificationCenter defaultCenter] addObserver:[TSWindowManager sharedInstance] selector:@selector(documentWindowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:textWindow];
    [[NSNotificationCenter defaultCenter] addObserver:[TSWindowManager sharedInstance] selector:@selector(documentWindowWillClose:) name:NSWindowWillCloseNotification object:textWindow];

    // register for notifications when the pdf window becomes key so we can remember which window was the frontmost.
    [[NSNotificationCenter defaultCenter] addObserver:[TSWindowManager sharedInstance] selector:@selector(pdfWindowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:pdfWindow];
    [[NSNotificationCenter defaultCenter] addObserver:[TSWindowManager sharedInstance] selector:@selector(pdfWindowWillClose:) name:NSWindowWillCloseNotification object:pdfWindow];
    
    // register for notification when the document font changes in preferences
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setDocumentFontFromPreferences:) name:DocumentFontChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(revertDocumentFont:) name:DocumentFontRevertNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rememberFont:) name:DocumentFontRememberNotification object:nil];
    
    // register for notification when the syntax coloring changes in preferences
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reColor:) name:DocumentSyntaxColorNotification object:nil];
    
    // notifications for pdftex and pdflatex
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkATaskStatus:) 
        name:NSTaskDidTerminateNotification object:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkPrefClose:) 
        name:NSWindowWillCloseNotification object:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeTexOutput:)
        name:NSFileHandleReadCompletionNotification object:nil];
}

//-----------------------------------------------------------------------------
- (void)setupFromPreferencesUsingWindowController:(NSWindowController *)windowController
//-----------------------------------------------------------------------------
/*" This method reads the NSUserDefaults and restores the settings before the document will actually be displayed.
"*/
{
    // inhibit ordering of windows by windowController.
    [windowController setShouldCascadeWindows:NO];

    // restore window position for the document window
    switch ([SUD integerForKey:DocumentWindowPosModeKey])
    {
        case DocumentWindowPosSave:
            [textWindow setFrameAutosaveName:DocumentWindowNameKey];
            break;
            
        case DocumentWindowPosFixed:
            [textWindow setFrameFromString:[SUD stringForKey:DocumentWindowFixedPosKey]];
            break;
    }
    
    // restore window position for the pdf window
    switch ([SUD integerForKey:PdfWindowPosModeKey])
    {
        case PdfWindowPosSave:
            [pdfWindow setFrameAutosaveName:PdfWindowNameKey];
            break;
            
        case PdfWindowPosFixed:
            [pdfWindow setFrameFromString:[SUD stringForKey:PdfWindowFixedPosKey]];
    }
    
	// restore the font for document if desired
	if ([SUD boolForKey:SaveDocumentFontKey] == YES)
    {
        [self setDocumentFontFromPreferences:nil];
	}

	// setup the popUp with all of our template names
	[popupButton addItemsWithTitles:[[TSPreferences sharedInstance] allTemplateNames]];
}

//-----------------------------------------------------------------------------
- (void)setDocumentFontFromPreferences:(NSNotification *)notification
//-----------------------------------------------------------------------------
/*" Changes the font of %textView to the one saved in the NSUserDefaults. This method is also registered with NSNotificationCenter and a notifictaion will be send whenever the font changes in the preferences panel.
"*/
{
	NSData	*fontData;
	NSFont 	*font;
        
	fontData = [SUD objectForKey:DocumentFontKey];
	if (fontData != nil)
	{
		font = [NSUnarchiver unarchiveObjectWithData:fontData];
		[textView setFont:font];
	}
}

//-----------------------------------------------------------------------------
- (void)rememberFont:(NSNotification *)notification
//-----------------------------------------------------------------------------
/*" Called when preferences starts to save current font "*/
{
	NSFont 	*font;
        
	if (previousFontData != nil)
            [previousFontData release];
	{
		font = [textView font];
		previousFontData = [[NSArchiver archivedDataWithRootObject: font] retain];
	}
}

//-----------------------------------------------------------------------------
- (void)revertDocumentFont:(NSNotification *)notification
//-----------------------------------------------------------------------------
/*" Changes the font of %textView to the one used before preferences called, in case the
preference change is cancelled. "*/
{
	NSFont 	*font;
        
	if (previousFontData != nil)
	{
		font = [NSUnarchiver unarchiveObjectWithData:previousFontData];
		[textView setFont:font];
	}
}

    
- (void)close
{
    if (syntaxColoringTimer != nil) 
    {
        [syntaxColoringTimer invalidate];
        [syntaxColoringTimer release];
        syntaxColoringTimer = nil;
    }
    
    if (tagTimer != nil) 
    {
        [tagTimer invalidate];
        [tagTimer release];
        tagTimer = nil;
    }
    [super close];
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

//-----------------------------------------------------------------------------
- (void) fixTemplate: (id) theDictionary;
//-----------------------------------------------------------------------------

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


//-----------------------------------------------------------------------------
- (void) doTemplate: sender 
//-----------------------------------------------------------------------------
{
    NSString		*templateString, *nameString, *oldString;
    id			theItem;
    unsigned		from, to;
    NSRange		myRange;
    NSUndoManager	*myManager;
    NSMutableDictionary	*myDictionary;
    NSNumber		*theLocation, *theLength;
    
    theItem = [sender selectedItem];
    
    if (theItem != nil) 
    {
        nameString = [TexTemplatePathKey stringByStandardizingPath];
        nameString = [nameString stringByAppendingPathComponent:[theItem title]];
        nameString = [nameString stringByAppendingPathExtension:@"tex"];
        templateString = [NSString stringWithContentsOfFile:nameString];
        if (templateString != nil) 
        {
            myRange = [textView selectedRange];
            oldString = [[textView string] substringWithRange: myRange];
            [textView replaceCharactersInRange:myRange withString:templateString];
            
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
            [self fixColor:from :to];
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
    
    // dirk test
    // [pdfWindow setNextResponder:pdfView];
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
            
        projectPath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"texshop"];
        if ([[NSFileManager defaultManager] fileExistsAtPath: projectPath]) {
            nameString = [NSString stringWithContentsOfFile: projectPath];
            imagePath = [[nameString stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
            }
        else
            imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];

        if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) {
            myAttributes = [[NSFileManager defaultManager] fileAttributesAtPath: imagePath traverseLink:NO];
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
        [outputText replaceCharactersInRange: [outputText selectedRange] withString:@""];
        [outputText setSelectable: NO];
        [outputWindow setTitle: [[[[self fileName] lastPathComponent] stringByDeletingPathExtension] 
                stringByAppendingString:@" console"]];
        [outputWindow makeKeyAndOrderFront: self];

        project = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension: @"texshop"];
        if ([[NSFileManager defaultManager] fileExistsAtPath: project])
            sourcePath = [NSString stringWithContentsOfFile: project];
        else
            sourcePath = myFileName;
            
        if (whichEngine < 3)
        {
            /* Koch: Feb 20; this allows spaces everywhere in path except
            file name itself */
            [args addObject: [sourcePath lastPathComponent]];
        
            if (texTask != nil) {
                [texTask terminate];
                texTask = nil;
                }
            texTask = [[NSTask alloc] init];
            [texTask setCurrentDirectoryPath: [sourcePath stringByDeletingLastPathComponent]];
            if (withLatex)
                [texTask setLaunchPath:[SUD stringForKey:LatexCommandKey]];
            else
                [texTask setLaunchPath: [SUD stringForKey:TexCommandKey]]; 
            [texTask setArguments:args];
            [texTask setStandardOutput: outputPipe];
            [texTask setStandardInput: inputPipe];
            [texTask launch];
            }
        else if (whichEngine == 3) {
            bibPath = [sourcePath stringByDeletingPathExtension];
            /* Koch: ditto; allow spaces in path */
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
            /* Koch: ditto, spaces in path */
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

- (void) doTexCommand: sender;
{
    NSData *myData;
    NSString *command;

    if (inputPipe) {
        command = [[texCommand stringValue] stringByAppendingString:@"\n"];
        myData = [command dataUsingEncoding: NSMacOSRomanStringEncoding allowLossyConversion:YES];
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
        if ([[NSFileManager defaultManager] fileExistsAtPath: project]) {
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
    if (tagTimer != nil) 
    {
        [tagTimer invalidate];
        [tagTimer release];
        tagTimer = nil;
    }
    tagLocation = 0;
    [tags removeAllItems];
    [tags addItemWithTitle:@"Tags"];
    tagTimer = [[NSTimer scheduledTimerWithTimeInterval: .02 target:self selector:@selector(fixTags:) userInfo:nil repeats:YES] retain];
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
    
    if ((! [SUD boolForKey:SyntaxColoringEnabledKey]) || (! fileIsTex)) return;
   
    commentColor = [NSColor redColor];
    commandColor = [NSColor blueColor];
    regularColor = [NSColor blackColor];
 
    textString = [textView string];
    if (textString == nil) return;
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
        colorRange.length = length - colorRange.location;
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
                [textString getLineStart:NULL end:NULL contentsEnd:&end forRange:colorRange];
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
            [textString getLineStart:&start end:&end contentsEnd:NULL forRange:colorRange];
            colorRange.length = (end - start);
            [textView setTextColor: regularColor range: colorRange];
            colorLocation = colorRange.location + colorRange.length;
            }
                
            
    if (colorLocation >= length) {
        [syntaxColoringTimer invalidate];
        [syntaxColoringTimer release];
        syntaxColoringTimer = nil;
        }
}



- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    NSRange	matchRange, tagRange;
    NSString	*textString;
    int		i, j, count, uchar, leftpar, rightpar;
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
        
    if (! [SUD boolForKey:ParensMatchingEnabledKey]) return YES;
    if ((rightpar != 0x007D) &&  (rightpar != 0x0029) &&  (rightpar != 0x005D)) return YES;

    if (rightpar == 0x007D) 
        leftpar = 0x007B;
    else if (rightpar == 0x0029) 
        leftpar = 0x0028;
    else 
        leftpar = 0x005B;
    
    textString = [textView string];    
    i = affectedCharRange.location;
    j = 1;
    count = 1;
    done = NO;
    /* modified Jan 26, 2001, so we don't search entire text */
    while ((i > 0) && (j < 5000) && (! done)) {
        i--; j++;
        uchar = [textString characterAtIndex:i];
        if (uchar == rightpar)
            count++;
        else if (uchar == leftpar)
            count--;
        if (count == 0) {
            done = YES;
            matchRange.location = i;
            matchRange.length = 1;
            /* koch: here 'affinity' and 'stillSelecting' are necessary,
            else the wrong range is selected. */
            [textView setSelectedRange: matchRange 
                affinity: NSSelectByCharacter stillSelecting: YES];
            [textView display];
            myDate = [NSDate date];
            /* Koch: Jan 26, 2001: changed -0.15 to -0.075 to speed things up */
            while ([myDate timeIntervalSinceNow] > - 0.075);
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

//=============================================================================
// timer methods
//=============================================================================
//-----------------------------------------------------------------------------
- (void) fixTags:(NSTimer *)timer;
//-----------------------------------------------------------------------------
{   
    NSString	*text, *tagString;
    unsigned	start, end, irrelevant;
    NSRange	myRange, nameRange;
    unsigned	length, index;
    int		theChar;

    if (fileIsTex) 
    {
        text = [textView string];
        length = [text length];
        index = tagLocation + 10000;
        myRange.location = tagLocation;
        myRange.length = 1;
        while ((myRange.location < length) && (myRange.location < index)) 
        {
            [text getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
            myRange.location = end;
            if (start < length - 3) 
            {
                theChar = [text characterAtIndex: start];
                if (theChar == 0x0025) 
                {
                    theChar = [text characterAtIndex: (start + 1)];
                    if (theChar == 0x003a) 
                    {
                        nameRange.location = start + 2;
                        nameRange.length = (end - start - 2);
                        tagString = [text substringWithRange: nameRange];
                        [tags addItemWithTitle:tagString];
                    }
                }
            }
        }
        tagLocation = myRange.location;
        if (tagLocation >= length) 
        {
            [tagTimer invalidate];
            [tagTimer release];
            tagTimer = nil;
        }
    }
}

//-----------------------------------------------------------------------------
- (void)fixColor1:(NSTimer *)timer;
//-----------------------------------------------------------------------------
{
    NSRange	colorRange;
    NSString	*textString;
    NSColor	*commentColor, *commandColor, *regularColor;
    long	length, limit;
    int		theChar;
    unsigned	end;

    limit = colorLocation + 5000;
    if ([SUD boolForKey:SyntaxColoringEnabledKey]) {
        commentColor = [NSColor redColor];
        commandColor = [NSColor blueColor];
        regularColor = [NSColor blackColor];
        }
    else {
        commentColor = [NSColor blackColor];
        commandColor = [NSColor blackColor];
        regularColor = [NSColor blackColor];
        }
 
    textString = [textView string];
    length = [textString length];
    
    while ((colorLocation < length) && (colorLocation < limit))  
    {
        theChar = [textString characterAtIndex: colorLocation];
            
        if (theChar == 0x0025) 
        {
            colorRange.location = colorLocation;
            colorRange.length = 0;
            [textString getLineStart:NULL end:NULL contentsEnd:&end forRange:colorRange];
            colorRange.length = (end - colorLocation);
            [textView setTextColor: commentColor range: colorRange];
            colorRange.location = colorRange.location + colorRange.length - 1;
            colorRange.length = 0;
            [textView setTextColor: regularColor range: colorRange];
            colorLocation = end;
        }
        else if (theChar == 0x005c) 
        {
            colorRange.location = colorLocation;
            colorRange.length = 1;
            colorLocation++;
            if ((colorLocation < length) && ([textString characterAtIndex: colorLocation] == 0x0025)) 
            {
                colorRange.length = colorLocation - colorRange.location;
                colorLocation++;
            }
            else while ((colorLocation < length) && (isText([textString characterAtIndex: colorLocation]))) 
            {
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
            
    if (colorLocation >= length) 
    {
        [syntaxColoringTimer invalidate];
        [syntaxColoringTimer release];
        syntaxColoringTimer = nil;
    }
}

//-----------------------------------------------------------------------------
- (void)reColor:(NSNotification *)notification;
//-----------------------------------------------------------------------------
{
    if (syntaxColoringTimer != nil) {
        [syntaxColoringTimer invalidate];
        [syntaxColoringTimer release];
        syntaxColoringTimer = nil;
        }
    colorLocation = 0;
    syntaxColoringTimer = [[NSTimer scheduledTimerWithTimeInterval: .02 target:self selector:@selector(fixColor1:) 	userInfo:nil repeats:YES] retain];
}

//=============================================================================
// nofification methods
//=============================================================================
- (void)checkATaskStatus:(NSNotification *)aNotification 
{
    NSString		*imagePath, *projectPath, *nameString;
    NSDictionary	*myAttributes;
    NSDate		*endDate;
    NSRect		topLeftRect;
    NSPoint		topLeftPoint;

    if (([aNotification object] == bibTask) || ([aNotification object] == indexTask)) 
    {
        if (inputPipe == [[aNotification object] standardInput]) 
        {
            int status = [[aNotification object] terminationStatus];
        
            if ((status == 0) || (status == 1)) 
            {
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
    
    if ([aNotification object] != texTask) 
        return;

    if (inputPipe == [[aNotification object] standardInput]) 
    {
        int status = [[aNotification object] terminationStatus];
    
        if ((status == 0) || (status == 1))  
        {
            projectPath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"texshop"];
            if ([[NSFileManager defaultManager] fileExistsAtPath: projectPath]) 
            {
                nameString = [NSString stringWithContentsOfFile: projectPath];
                imagePath = [[nameString stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
            }
            else
                imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];

            if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) 
            {
                myAttributes = [[NSFileManager defaultManager] fileAttributesAtPath: imagePath traverseLink:NO];
                endDate = [myAttributes objectForKey:NSFileModificationDate];
                if ((startDate == nil) || ! [startDate isEqualToDate: endDate]) 
                {
                    texRep = [[NSPDFImageRep imageRepWithContentsOfFile: imagePath] retain]; 
                    if (texRep) 
                    {
                        [pdfWindow setTitle:[[[[self fileName] lastPathComponent] stringByDeletingPathExtension] 					stringByAppendingPathExtension:@"pdf"]];
                        [pdfView setImageRep: texRep];
                        if (startDate == nil) 
                        {
                            topLeftRect = [texRep bounds];
                            topLeftPoint.x = topLeftRect.origin.x;
                            topLeftPoint.y = topLeftRect.origin.y + topLeftRect.size.height - 1;
                            [pdfView scrollPoint: topLeftPoint];
                        }
                        
                        [pdfView setNeedsDisplay:YES];
                        [pdfWindow makeKeyAndOrderFront: self];
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

- (void) checkPrefClose: (NSNotification *)aNotification
{
    int	finalResult;
    
    if (([aNotification object] == projectPanel) ||
        ([aNotification object] == requestWindow) ||
        ([aNotification object] == linePanel) ||
        ([aNotification object] == printRequestPanel)) 
    {
        finalResult = myPrefResult;
        if (finalResult == 2) finalResult = 0;
        [NSApp stopModalWithCode: finalResult];
    }
}

- (void) writeTexOutput: (NSNotification *)aNotification
{
    NSString		*newOutput, *numberOutput, *searchString, *tempString;
    NSData		*myData;
    NSRange		myRange, lineRange, searchRange;
    int			error;
    unsigned int	myLength;
    unsigned		start, end, irrelevant;
    
    NSFileHandle *myFileHandle = [aNotification object];
    if (myFileHandle == readHandle) 
    {
        myData = [[aNotification userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];
        if ([myData length]) 
        {
            newOutput = [[NSString alloc] initWithData: myData encoding: NSMacOSRomanStringEncoding];
            if ((makeError) && ([newOutput length] > 2) && (errorNumber < NUMBEROFERRORS)) 
            {
                myLength = [newOutput length];
                searchString = @"l.";
                lineRange.location = 0;
                lineRange.length = 1;
                while (lineRange.location < myLength) 
                {
                    [newOutput getLineStart: &start end: &end contentsEnd: &irrelevant forRange: lineRange];
                    lineRange.location = end;
                    searchRange.location = start;
                    searchRange.length = end - start;
                    tempString = [newOutput substringWithRange: searchRange];
                    myRange = [tempString rangeOfString: searchString];
                    if ((myRange.location = 1) && (myRange.length > 0)) 
                    {
                        numberOutput = [tempString substringFromIndex:(myRange.location + 1)];
                        error = [numberOutput intValue];
                        if ((error > 0) && (errorNumber < NUMBEROFERRORS)) 
                        {
                            errorLine[errorNumber] = error;
                            errorNumber++;
                        }
                    }
                }
            }

            [outputText replaceCharactersInRange: [outputText selectedRange] withString: newOutput];
            [outputText scrollRangeToVisible: [outputText selectedRange]];
            [newOutput release];
            [readHandle readInBackgroundAndNotify];
        }
    }
}

@end
