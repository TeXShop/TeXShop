// MyDocument.m

// Created by koch in July, 2000.

#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import "MyDocument.h"
#import "PrintView.h"
#import "PrintBitmapView.h"
#import "MyView.h"
#import "TSPreferences.h"
#import "TSWindowManager.h"
#import "extras.h"
#import "globals.h"
#import "Autrecontroller.h"
#import "MyDocumentToolbar.h"
#import "TSAppDelegate.h"

#define SUD [NSUserDefaults standardUserDefaults]
#define Mcomment 1
#define Muncomment 2
#define Mindent 3
#define Munindent 4

// #define COLORTIME  0
// #define COLORLENGTH 5000

#define COLORTIME  .02
#define COLORLENGTH 500000


/* Code by Anton Leuski */
static NSArray*	kTaggedTeXSections = nil;
static NSArray*	kTaggedTagSections = nil;

@implementation MyDocument : NSDocument

/* Code by Anton Leuski */
//-----------------------------------------------------------------------------
+ (void)initialize
//-----------------------------------------------------------------------------
{
	if (!kTaggedTeXSections) {
		kTaggedTeXSections = [[NSArray alloc] initWithObjects:@"\\chapter",
					@"\\section",
					@"\\subsection",
					@"\\subsubsection",
					nil];
					
		kTaggedTagSections = [[NSArray alloc] initWithObjects:@"chapter: ",
					@"section: ",
					@"subsection: ",
					@"subsubsection: ",
					nil];
	}
}



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
    texRep = nil;
    fileIsTex = YES;
    mSelection = nil;
    
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
    [commentColor release];
    [commandColor release];
    [markerColor release];
    [mSelection release];
    
/* toolbar stuff */
    [typesetButton release];
    [programButton release];
    [typesetButtonEE release];
    [programButtonEE release];
    [tags release];
    [popupButton release];
    [previousButton release];
    [nextButton release];
    [gotopageOutlet release];
    [magnificationOutlet release];
    
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
    id			printView;
    NSPrintOperation	*printOperation;
    NSString		*imagePath, *projectPath, *nameString;
    id			aRep;
    int			result;
    
    projectPath = [[[self fileName] stringByDeletingPathExtension] 	stringByAppendingPathExtension:@"texshop"];
    if (myImageType == isTeX) {
        if ([[NSFileManager defaultManager] fileExistsAtPath: projectPath]) {
            NSString *projectRoot = [NSString stringWithContentsOfFile: projectPath];
            if ([projectRoot isAbsolutePath]) {
                nameString = [NSString stringWithString:projectRoot];
            }
            else {
                nameString = [[self fileName] stringByDeletingLastPathComponent];
                nameString = [[nameString stringByAppendingString:@"/"] 
                    stringByAppendingString: [NSString stringWithContentsOfFile: projectPath]];
                nameString = [nameString stringByStandardizingPath];
            }
            imagePath = [[nameString stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
        }
        else
            imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
    }
    else if (myImageType == isPDF)
        imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
    else if ((myImageType == isJPG) || (myImageType == isTIFF))
        imagePath = [self fileName];
    else
        imagePath = [self fileName];

    aRep = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) {
        if ((myImageType == isTeX) || (myImageType == isPDF))
            aRep = [[NSPDFImageRep imageRepWithContentsOfFile: imagePath] retain];
        else if (myImageType == isJPG)
            aRep = [[NSImageRep imageRepWithContentsOfFile: imagePath] retain];
        else if (myImageType == isTIFF)
            aRep = [[NSImageRep imageRepWithContentsOfFile: imagePath] retain];
        else
            return;
        if (aRep == nil) return;
        if ((myImageType == isJPG) || (myImageType == isTIFF)) 
            printView = [[PrintBitmapView alloc] initWithBitmapRep: aRep];
        else
            printView = [[PrintView alloc] initWithRep: aRep];
        printOperation = [NSPrintOperation printOperationWithView:printView
            printInfo: [self printInfo]];
        if ((myImageType == isJPG) || (myImageType == isTIFF))
            [printView setBitmapPrintOperation: printOperation]; 
        else
            [printView setPrintOperation: printOperation];
        [printOperation setShowPanels:flag];
        [printOperation runOperation];
        [printView release];
	}
    else if (myImageType == isTeX)
        result = [NSApp runModalForWindow: printRequestPanel];
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
    NSString		*theFileName;
    float		r, g, b;
    int			defaultcommand;
/*
    NSCharacterSet	*mySet;
    NSScanner		*myScanner;
    NSString		*resultNumber;
    NSString		*finalName;
*/
    
    [super windowControllerDidLoadNib:aController];
    
    externalEditor = [[[NSApplication sharedApplication] delegate] forPreview];
    theFileName = [self fileName];
    [self setupToolbar];
    
    r = [SUD floatForKey:commandredKey];
    g = [SUD floatForKey:commandgreenKey];
    b = [SUD floatForKey:commandblueKey];
    commandColor = [[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0] retain];
    r = [SUD floatForKey:commentredKey];
    g = [SUD floatForKey:commentgreenKey];
    b = [SUD floatForKey:commentblueKey];
    commentColor = [[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0] retain];
    r = [SUD floatForKey:markerredKey];
    g = [SUD floatForKey:markergreenKey];
    b = [SUD floatForKey:markerblueKey];
    markerColor = [[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0] retain];
    
    if (! documentsHaveLoaded) {
        documentsHaveLoaded = YES;
        if ((theFileName == nil) && (! [SUD boolForKey:MakeEmptyDocumentKey]))
            {
                myImageType = isJPG;
                return;
            }
         }

/* when opening an empty document, must open the source editor */         
    if ((theFileName == nil) && (externalEditor))
        externalEditor = NO;
 
    /* this code is an attempt to make "untitled-1" be a name without spaces,
        but it does not work */
    /*
    if ([self fileName] == nil) {
        mySet = [NSCharacterSet decimalDigitCharacterSet];
        myScanner = [NSScanner scannerWithString:[self displayName]];
        [myScanner scanUpToCharactersFromSet:mySet intoString:nil];
        if ([myScanner scanCharactersFromSet:mySet intoString:&resultNumber]) {
            finalName = [[NSLocalizedString(@"Untitled-", @"Untitled-") 		stringByAppendingString:resultNumber]
                stringByAppendingString:@".tex"];
           [self setLastComponentOfFileName: finalName ];
            }
        }
    */
    
        
    [self registerForNotifications];    
	[self setupFromPreferencesUsingWindowController:aController];

    [pdfView setDocument: self]; /* This was commented out!! Don't do it; needed by Ghostscript; Dick */
    [textView setDelegate: self];
    [pdfView resetMagnification]; 
    
   
    whichScript = [SUD integerForKey:DefaultScriptKey];
    [self fixTypesetMenu];
    
    myImageType = isTeX;
    fileExtension = [[self fileName] pathExtension];
    if (( ! [fileExtension isEqualToString: @"tex"]) && ( ! [fileExtension isEqualToString: @"TEX"])
     && ( ! [fileExtension isEqualToString: @"dtx"]) && ( ! [fileExtension isEqualToString: @"ins"])
     && ( ! [fileExtension isEqualToString: @"sty"]) && ( ! [fileExtension isEqualToString: @"cls"])
        && ( ! [fileExtension isEqualToString: @""]) && ( ! [fileExtension isEqualToString: @"mp"]) 
        && ([[NSFileManager defaultManager] fileExistsAtPath: [self fileName]]))
    {
        [self setFileType: fileExtension];
        [typesetButton setEnabled: NO];
        [typesetButtonEE setEnabled: NO];
        myImageType = isOther;
        fileIsTex = NO;
    }
            
/* handle images */
    [pdfView setImageType: myImageType];
        
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
            [previousButton setEnabled:NO];
            [nextButton setEnabled:NO];
            }
        else if (([fileExtension isEqualToString: @"tiff"]) ||
                ([fileExtension isEqualToString: @"tif"])) {
            imageFound = YES;
            texRep = [[NSBitmapImageRep imageRepWithContentsOfFile: imagePath] retain];
            [pdfWindow setTitle: [[self fileName] lastPathComponent]]; 
            myImageType = isTIFF;
            [previousButton setEnabled:NO];
            [nextButton setEnabled:NO];
            }
        else if (([fileExtension isEqualToString: @"dvi"]) || 
                ([fileExtension isEqualToString: @"ps"]) ||
                ([fileExtension isEqualToString:@"eps"]))
            {
                myImageType = isPDF;
                [pdfView setImageType: myImageType];
                [self convertDocument];
                return;
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
                if (texRep != nil) 
                    [pdfView display];
                [pdfWindow makeKeyAndOrderFront: self];
                return;
                }
        }
 /* end of images */
 if (externalEditor) {
    [self setHasUndoManager: NO];  // so reporting no changes does not lead to error messages
    texTask = nil;
    bibTask = nil;
    indexTask = nil;
    }
  else if (aString != nil) 
    {	
        [textView setString: aString];
        length = [aString length];
        [self setupTags];
        
        if (([SUD boolForKey:SyntaxColoringEnabledKey]) && (fileIsTex)) 
        {
            colorLocation = 0;
            [self fixColor:0 :length];
           // syntaxColoringTimer = [[NSTimer scheduledTimerWithTimeInterval: COLORTIME target:self selector:@selector(fixColor1:) userInfo:nil repeats:YES] retain];
        }

        [aString release];
        aString = nil;
        texTask = nil;
        bibTask = nil;
        indexTask = nil;
    }
    
  if (! externalEditor) {
    myRange.location = 0;
    myRange.length = 0;
    [textView setSelectedRange: myRange];
    [textView setContinuousSpellCheckingEnabled:[SUD boolForKey:SpellCheckEnabledKey]];
    [textWindow setInitialFirstResponder: textView];
    [textWindow makeFirstResponder: textView];
    }
    
    if (!fileIsTex) 
        return;
       
    defaultcommand = [SUD integerForKey:DefaultCommandKey];
    switch (defaultcommand) {
        case DefaultCommandTeX: [typesetButton setTitle: @"TeX"]; 
                                [typesetButtonEE setTitle: @"TeX"];
                                break;
        case DefaultCommandLaTeX:   [typesetButton setTitle: @"LaTeX"]; 
                                    [typesetButtonEE setTitle: @"LaTeX"];
                                    break;
        case DefaultCommandConTEXt: [typesetButton setTitle: @"ConTeXt"]; 
                                    [typesetButtonEE setTitle: @"ConTeXt"];
                                    break;
        }
    
    projectPath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"texshop"];
    if ([[NSFileManager defaultManager] fileExistsAtPath: projectPath]) {
        NSString *projectRoot = [NSString stringWithContentsOfFile: projectPath];
        if ([projectRoot isAbsolutePath]) {
            nameString = [NSString stringWithString:projectRoot];
        }
        else {
            nameString = [[self fileName] stringByDeletingLastPathComponent];
            nameString = [[nameString stringByAppendingString:@"/"] 
                stringByAppendingString: [NSString stringWithContentsOfFile: projectPath]];
            nameString = [nameString stringByStandardizingPath];
        }
        imagePath = [[nameString stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
        }
    else
        imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
    if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) {
        texRep = [[NSPDFImageRep imageRepWithContentsOfFile: imagePath] retain]; 
        if (texRep) {
            /* [pdfWindow setTitle: 
                    [[[[self fileName] lastPathComponent] 
                    stringByDeletingPathExtension] stringByAppendingString:@".pdf"]]; */
            [pdfWindow setTitle: [imagePath lastPathComponent]];
            [pdfView setImageRep: texRep]; // this releases old one!
            topLeftRect = [texRep bounds];
            topLeftPoint.x = topLeftRect.origin.x;
            topLeftPoint.y = topLeftRect.origin.y + topLeftRect.size.height - 1;
            [pdfView scrollPoint: topLeftPoint];
            [pdfView display];
            [pdfWindow makeKeyAndOrderFront: self];
            }
        }
    else if (externalEditor) {
            [pdfWindow setTitle: [imagePath lastPathComponent]];
            [pdfWindow makeKeyAndOrderFront: self];
        }
}

/* A user reported that while working with an external editor, he quit TeXShop and was
asked if he wanted to save documents. When he did, the source file was replaced with an
empty file. He had used Page Setup, which marked the file as changed. The code below
insures that files opened with an external editor are never marked as changed. 
WARNING: This causes stack problems if the undo manager is enabled, so it is disabled
in other code when an external editor is being used. */

- (BOOL)isDocumentEdited
{
    if (externalEditor)
        return NO;
    else
        return [super isDocumentEdited];
}


//-----------------------------------------------------------------------------
- (void)registerForNotifications
//-----------------------------------------------------------------------------
/*" This method registers all notifications that are necessary to work properly together with the other AppKit and TeXShop objects.
"*/
{
    // register to learn when the document window becomes main so we can fix the Typeset script
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(newMainWindow:)
        name:NSWindowDidBecomeMainNotification object:nil];
        
    // register for notifications when the document window becomes key so we can remember which window was
    // the frontmost. This is needed for the preferences.
    [[NSNotificationCenter defaultCenter] addObserver:[TSWindowManager sharedInstance] selector:@selector(documentWindowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:textWindow];
    [[NSNotificationCenter defaultCenter] addObserver:[Autrecontroller sharedInstance] selector:@selector(documentWindowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:textWindow];
    [[NSNotificationCenter defaultCenter] addObserver:[TSWindowManager sharedInstance] selector:@selector(documentWindowWillClose:) name:NSWindowWillCloseNotification object:textWindow];

    // register for notifications when the pdf window becomes key so we can remember which window was the frontmost.
    [[NSNotificationCenter defaultCenter] addObserver:[TSWindowManager sharedInstance] selector:@selector(pdfWindowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:pdfWindow];
    [[NSNotificationCenter defaultCenter] addObserver:[Autrecontroller sharedInstance] selector:@selector(pdfWindowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:pdfWindow];
    [[NSNotificationCenter defaultCenter] addObserver:[TSWindowManager sharedInstance] selector:@selector(pdfWindowWillClose:) name:NSWindowWillCloseNotification object:pdfWindow];
    
    // register for notification when the document font changes in preferences
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setDocumentFontFromPreferences:) name:DocumentFontChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(revertDocumentFont:) name:DocumentFontRevertNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rememberFont:) name:DocumentFontRememberNotification object:nil];
    
    // register for notification when the syntax coloring changes in preferences
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reColor:) name:DocumentSyntaxColorNotification object:nil];
    
    // externalEditChange
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ExternalEditorChange:) name:ExternalEditorNotification object:nil];
    
    // notifications for pdftex and pdflatex
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkATaskStatus:) 
        name:NSTaskDidTerminateNotification object:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkPrefClose:) 
        name:NSWindowWillCloseNotification object:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeTexOutput:)
        name:NSFileHandleReadCompletionNotification object:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doCompletion:)
        name:@"completionpanel" object:nil];
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

- (void)ExternalEditorChange:(NSNotification *)notification
{
    [[[NSApplication sharedApplication] delegate] configureExternalEditor];
}


- (BOOL) externalEditor
{
    return (externalEditor);
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
    [pdfWindow close];
    [super close];
}


- (NSData *)dataRepresentationOfType:(NSString *)aType {
    // Insert code here to write your document from the given data.
    // The following is line has been changed to fix the bug from Geoff Leyland 
    // return [[textView string] dataUsingEncoding: NSASCIIStringEncoding];
    if([[SUD stringForKey:EncodingKey] isEqualToString:@"MacOSRoman"])
        return [[textView string] dataUsingEncoding: NSMacOSRomanStringEncoding allowLossyConversion:YES];
    else if([[SUD stringForKey:EncodingKey] isEqualToString:@"IsoLatin"])
        return [[textView string] dataUsingEncoding: NSISOLatin1StringEncoding allowLossyConversion:YES];
    else if([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"]) 
        return [[textView string] dataUsingEncoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacJapanese) allowLossyConversion:YES];
    else if([[SUD stringForKey:EncodingKey] isEqualToString:@"MacKorean"]) 
        return [[textView string] dataUsingEncoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacKorean) allowLossyConversion:YES];
    else 
         return [[textView string] dataUsingEncoding: NSMacOSRomanStringEncoding allowLossyConversion:YES];
}



- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type {

    id myData;
    
    if([[SUD stringForKey:EncodingKey] isEqualToString:@"MacOSRoman"])
        aString = [[NSString stringWithContentsOfFile:fileName] retain];
    else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"IsoLatin"]) {
        myData = [NSData dataWithContentsOfFile:fileName];
        aString = [[[NSString alloc] initWithData:myData encoding: NSISOLatin1StringEncoding] retain];
        }
     else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"]) {
        myData = [NSData dataWithContentsOfFile:fileName];
        aString = [[[NSString alloc] initWithData:myData encoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacJapanese)] retain];
        }
    else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacKorean"]) {
        myData = [NSData dataWithContentsOfFile:fileName];
        aString = [[[NSString alloc] initWithData:myData encoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacKorean)] retain];
        }
    else
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
    id			myData;
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
        
        if([[SUD stringForKey:EncodingKey] isEqualToString:@"MacOSRoman"])
            templateString = [NSString stringWithContentsOfFile:nameString];
        else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"IsoLatin"]) {
            myData = [NSData dataWithContentsOfFile:nameString];
            templateString = [[NSString alloc] initWithData:myData 
                encoding: NSISOLatin1StringEncoding];
            }
        else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"]) {
            myData = [NSData dataWithContentsOfFile:nameString];
            templateString = [[NSString alloc] initWithData:myData 
            encoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacJapanese)];         	   }
        else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacKorean"]) {
            myData = [NSData dataWithContentsOfFile:nameString];
            templateString = [[NSString alloc] initWithData:myData 
            encoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacKorean)];
            }
        else
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

- (void) doJob:(int)type withError:(BOOL)error;
{
    SEL		saveFinished;
    NSDate	*myDate;
    
    if (! fileIsTex)
        return;
    
    /* The lines of code below kill previously running tasks. This is
    necessary because otherwise the source file will be open when the
    system tries to save a new version. If the source file is open,
    NSDocument makes a backup in /tmp which is never removed. */
    
    if (texTask != nil) {
                if (theScript == 101) {
                    kill( -[texTask processIdentifier], SIGTERM);
                    }
                else
                    [texTask terminate];
                myDate = [NSDate date];
                while (([texTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
                [texTask release];
                texTask = nil;
            }
            
    if (bibTask != nil) {
                [bibTask terminate];
                myDate = [NSDate date];
                while (([bibTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
                [bibTask release];
                bibTask = nil;
            }
            
    if (indexTask != nil) {
                [indexTask terminate];
                myDate = [NSDate date];
                while (([indexTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
                [indexTask release];
                indexTask = nil;
            }
    
    errorNumber = 0;
    whichError = 0;
    makeError = error;
    
    whichEngine = type;
    if (externalEditor) {
        [self saveFinished: self didSave:YES contextInfo:nil];
        }
    else {
        saveFinished = @selector(saveFinished:didSave:contextInfo:);
        [self saveDocumentWithDelegate: self didSaveSelector: saveFinished contextInfo: nil];
        }
}


/* The default save operations clear the "document edited symbol" but
do not reset the undo stack, and then later the symbol gets out of sync.
This seems like a bug; it is fixed by the code below. RMK: 6/22/01 */

- (void) updateChangeCount: (NSDocumentChangeType)changeType;
{
    [super updateChangeCount: changeType];
    if (![self isDocumentEdited])
        [[textView undoManager] removeAllActions];
}

- (NSString *) separate: (NSString *)myEngine into:(NSMutableArray *)args;
{   
    NSArray		*myList;
    NSString		*myString, *middleString;
    int			size, i, pos;
    BOOL		programFound, inMiddle;
    NSString		*theEngine;
    NSRange		aRange;

    if (myEngine != nil) {
        myList = [myEngine componentsSeparatedByString:@" "];
        programFound = NO;
        inMiddle = NO;
        size = [myList count];
        i = 0;
        while (i < size) {
            myString = [myList objectAtIndex:i];
            if ((myString != nil) && ([myString length] > 0)) {
                if (! programFound) {
                    theEngine = myString;
                    programFound = YES;
                    }
                else if (inMiddle) {
                    middleString = [middleString stringByAppendingString:@" "];
                    middleString = [middleString stringByAppendingString:myString];
                    pos = [myString length] - 1;
                    if ([myString characterAtIndex:pos] == '"') {
                        aRange.location = 1;
                        aRange.length = [middleString length] - 2;
                        middleString = [middleString substringWithRange: aRange];
                        [args addObject: middleString];
                        inMiddle = NO;
                        }
                    }
                else if ([myString characterAtIndex:0] == '"') {
                    pos = [myString length] - 1;
                    if ([myString characterAtIndex:pos] == '"') {
                        aRange.location = 1;
                        aRange.length = [myString length] - 2;
                        myString = [myString substringWithRange: aRange];
                        [args addObject: myString];
                        }
                    else {
                        middleString = [NSString stringWithString: myString];
                        inMiddle = YES;
                        }
                    }
                else {
                    [args addObject: myString];
                    } 
                }
            i = i + 1;
            }
        if (! programFound)
            theEngine = nil;
        }
    
    return (theEngine);
}

- (void) convertDocument;
{
    NSString		*myFileName;
    NSMutableArray	*args;
    NSDictionary	*myAttributes;
    NSString		*imagePath;
    NSString		*sourcePath;
    NSString		*enginePath;
    NSString		*tetexBinPath;
    NSString		*epstopdfPath;
    
    myFileName = [self fileName];
    if ([myFileName length] > 0) {
            
        imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];

        if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) {
            myAttributes = [[NSFileManager defaultManager] fileAttributesAtPath: imagePath traverseLink:NO];
            startDate = [[myAttributes objectForKey:NSFileModificationDate] retain];
            }
        else
            startDate = nil;
    
        args = [NSMutableArray array];
        sourcePath = myFileName;
        
        texTask = [[NSTask alloc] init];
        [texTask setCurrentDirectoryPath: [sourcePath stringByDeletingLastPathComponent]];
        [texTask setEnvironment: TSEnvironment];
        
        if ([[myFileName pathExtension] isEqualToString:@"dvi"]) {
            enginePath = [SUD stringForKey:LatexGSCommandKey];
            enginePath = [self separate:enginePath into: args];
            if ([SUD boolForKey:SavePSEnabledKey])
            	[args addObject: [NSString stringWithString:@"--keep-psfile"]];
            }    
        else if ([[myFileName pathExtension] isEqualToString:@"ps"]) {
            enginePath = [[NSBundle mainBundle] pathForResource:@"ps2pdfwrap" ofType:nil];
            }
        else if  ([[myFileName pathExtension] isEqualToString:@"eps"]) {
            enginePath = [[NSBundle mainBundle] pathForResource:@"epstopdfwrap" ofType:nil];
            
            tetexBinPath = [[SUD stringForKey:TetexBinPathKey] stringByAppendingString:@"/"];
            epstopdfPath = [tetexBinPath stringByAppendingString:@"epstopdf"];
            // [args addObject: [[NSBundle mainBundle] pathForResource:@"epstopdf" ofType:nil]];
            [args addObject: epstopdfPath];
            }

        [args addObject: [sourcePath lastPathComponent]];

        if (enginePath != nil) {
            if ([enginePath characterAtIndex:0] != '/') {
                tetexBinPath = [[SUD stringForKey:TetexBinPathKey] stringByAppendingString:@"/"];
                enginePath = [tetexBinPath stringByAppendingString:enginePath];
                }
            }
        inputPipe = [[NSPipe pipe] retain];
        [texTask setStandardInput: inputPipe];
        if ((enginePath != nil) && ([[NSFileManager defaultManager] fileExistsAtPath: enginePath])) {
                [texTask setLaunchPath:enginePath];
                [texTask setArguments:args];
                [texTask launch];
        }
        else {
            [inputPipe release];
            [texTask release];
            texTask = nil;
        }
    }
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
    NSString		*myEngine;
    NSString		*enginePath;
    NSString		*tetexBinPath;
    BOOL		withLatex;
    NSArray		*myList;
    NSString		*theSource, *theKey;
    NSRange		myRange;
    unsigned int	mystart, myend;
    
    if (whichEngine == 1)
        withLatex = YES;
    else if (whichEngine == 0)
        withLatex = NO;
    theScript = whichScript;
    
if (! externalEditor) {
    theSource = [[self textView] string];
    myRange.length = 1;
    myRange.location = 0;
    [theSource getLineStart:&mystart end: &myend contentsEnd: nil forRange:myRange];
    if (myend > (mystart + 2)) {
        myRange.location = 0;
        myRange.length = myend - mystart - 1;
        theKey = [theSource substringWithRange:myRange];
        myList = [theKey componentsSeparatedByString:@" "];
        if ((theKey) && ([myList count] > 0)) 
            theKey = [myList objectAtIndex:0];
        }
    else
        theKey = nil;
        
    if ((theKey) && ([theKey isEqualToString:@"%&pdftex"])) {
        withLatex = NO;
        theScript = 100;
        }
    else if ((theKey) && ([theKey isEqualToString:@"%&pdflatex"])) {
        withLatex = YES;
        theScript = 100;
        }
    else if ((theKey) && ([theKey isEqualToString:@"%&tex"])) {
        withLatex = NO;
        theScript = 101;
        }
    else if ((theKey) && ([theKey isEqualToString:@"%&latex"])) {
        withLatex = YES;
        theScript = 101;
        }
    else if ((theKey) && ([theKey isEqualToString:@"%&personaltex"])) {
        withLatex = NO;
        theScript = 102;
        }
    else if ((theKey) && ([theKey isEqualToString:@"%&personallatex"])) {
        withLatex = YES;
        theScript = 102;
        }
    }
    
    myFileName = [self fileName];
    if ([myFileName length] > 0) {
    
        if (startDate != nil) {
            [startDate release];
            startDate = nil;
            }
            
        projectPath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"texshop"];
        if ([[NSFileManager defaultManager] fileExistsAtPath: projectPath]) {
            NSString *projectRoot = [NSString stringWithContentsOfFile: projectPath];
            if ([projectRoot isAbsolutePath]) {
                nameString = [NSString stringWithString:projectRoot];
            }
            else {
                nameString = [[self fileName] stringByDeletingLastPathComponent];
                nameString = [[nameString stringByAppendingString:@"/"] 
                    stringByAppendingString: [NSString stringWithContentsOfFile: projectPath]];
                nameString = [nameString stringByStandardizingPath];
            }
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
        [texCommand setStringValue:@""];
        [outputText setSelectable: NO];
        typesetStart = NO; 
        /* The following command produces an unwanted tex input event for reasons
            I do not understand; the event will be discarded because typesetStart = NO
            and it is received before tex output to the console occurs.
            RMK; 7/3/2001. */
        [outputWindow makeFirstResponder: texCommand];
        
        
        /* [outputWindow setTitle: [[[[self fileName] lastPathComponent] stringByDeletingPathExtension] 
                stringByAppendingString:@" console"]]; */
        [outputWindow setTitle: [[[imagePath lastPathComponent] stringByDeletingPathExtension]
            stringByAppendingString:@" console"]];
        if ([SUD boolForKey:ConsoleBehaviorKey]) {
            if (![outputWindow isVisible])
                [outputWindow orderBack: self];
            [outputWindow makeKeyWindow];
            }
        else
            [outputWindow makeKeyAndOrderFront: self];

        project = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension: @"texshop"];
        if ([[NSFileManager defaultManager] fileExistsAtPath: project]) {
            NSString *projectRoot = [NSString stringWithContentsOfFile: project];
            if ([projectRoot isAbsolutePath]) {
                sourcePath = [NSString stringWithString:projectRoot];
            }
            else {
                sourcePath = [[self fileName] stringByDeletingLastPathComponent];
                sourcePath = [[sourcePath stringByAppendingString:@"/"] 
                    stringByAppendingString: projectRoot];
                sourcePath = [sourcePath stringByStandardizingPath];
            }
        }
        else
            sourcePath = myFileName;
            
        if (whichEngine < 5)
        {
            if ((theScript == 101) && ([SUD boolForKey:SavePSEnabledKey]) 
                && (whichEngine != 2)   && (whichEngine != 4)) 
            	[args addObject: [NSString stringWithString:@"--keep-psfile"]];
                
            if (texTask != nil) {
                [texTask terminate];
                [texTask release];
                texTask = nil;
                }
            texTask = [[NSTask alloc] init];
            [texTask setCurrentDirectoryPath: [sourcePath stringByDeletingLastPathComponent]];
            [texTask setEnvironment: TSEnvironment];
            
            if (whichEngine == 2) {
                if (theScript == 100) {
                    enginePath = [[NSBundle mainBundle] pathForResource:@"contextwrap" ofType:nil];
                    [args addObject: [[SUD stringForKey:TetexBinPathKey] stringByAppendingString:@"/"]];
                    }
                else {
                    enginePath = [[NSBundle mainBundle] pathForResource:@"contextdviwrap" ofType:nil];
                    [args addObject: [[SUD stringForKey:TetexBinPathKey] stringByAppendingString:@"/"]];
                     if ((theScript == 101) && ([SUD boolForKey:SavePSEnabledKey])) 
                        [args addObject: @"yes"];
                     else
                        [args addObject: @"no"];
                   // if ([SUD boolForKey:SavePSEnabledKey]) 
                   //     [args addObject: [NSString stringWithString:@"--keep-psfile"]];
                    }
                 }
                
            else if (whichEngine == 3)
                myEngine = @"omega"; // currently this should never occur
                
            else if (whichEngine == 4)
                {
                enginePath = [[NSBundle mainBundle] pathForResource:@"metapostwrap" ofType:nil];
                [args addObject: [[SUD stringForKey:TetexBinPathKey] stringByAppendingString:@"/"]];
                 }
                
            else switch (theScript) {
            
                case 100: 
                
                    if (withLatex)
                        myEngine = [SUD stringForKey:LatexCommandKey];
                    else
                        myEngine = [SUD stringForKey:TexCommandKey];
                    break;
                
                case 101:
                
                    if (withLatex)
                        myEngine = [SUD stringForKey:LatexGSCommandKey];
                    else
                        myEngine = [SUD stringForKey:TexGSCommandKey];
                    break;
                
                case 102:
                
                    if (withLatex)
                        myEngine = [SUD stringForKey:LatexScriptCommandKey];
                    else
                        myEngine = [SUD stringForKey:TexScriptCommandKey];
                    break;
                
                }
                
            if ((whichEngine != 2) && (whichEngine != 3) && (whichEngine != 4)) {
                
            myEngine = [self separate:myEngine into:args];
                
              enginePath = nil;
              
              if ((myEngine != nil) && ([myEngine length] > 0)) {       
                if ([myEngine characterAtIndex:0] != '/') {
                    tetexBinPath = [[SUD stringForKey:TetexBinPathKey] stringByAppendingString:@"/"];
                    enginePath = [tetexBinPath stringByAppendingString:myEngine];
                     }
                else
                    enginePath = myEngine;
                }
                
            }
            
            /* Koch: Feb 20; this allows spaces everywhere in path except
            file name itself */
            [args addObject: [sourcePath lastPathComponent]];
        
            if ((enginePath != nil) && ([[NSFileManager defaultManager] fileExistsAtPath: enginePath])) {
                [texTask setLaunchPath:enginePath];
                [texTask setArguments:args];
                [texTask setStandardOutput: outputPipe];
                [texTask setStandardError: outputPipe];
                [texTask setStandardInput: inputPipe];
                [texTask launch];
            }
            else {
                [inputPipe release];
                [outputPipe release];
                [texTask release];
                texTask = nil;
            }
        }
        else if (whichEngine == 5) {
            bibPath = [sourcePath stringByDeletingPathExtension];
            /* Koch: ditto; allow spaces in path */
            [args addObject: [bibPath lastPathComponent]];
        
            if (bibTask != nil) {
                [bibTask terminate];
                [bibTask release];
                bibTask = nil;
            }
            bibTask = [[NSTask alloc] init];
            [bibTask setCurrentDirectoryPath: [sourcePath  stringByDeletingLastPathComponent]];
            [bibTask setEnvironment: TSEnvironment];
            tetexBinPath = [[SUD stringForKey:TetexBinPathKey] stringByAppendingString:@"/"];
            enginePath = [tetexBinPath stringByAppendingString:@"bibtex"];
            [bibTask setLaunchPath: enginePath];
            [bibTask setArguments:args];
            [bibTask setStandardOutput: outputPipe];
            [bibTask setStandardError: outputPipe];
            [bibTask setStandardInput: inputPipe];
            [bibTask launch];
        }
        else if (whichEngine == 6) {
            indexPath = [sourcePath stringByDeletingPathExtension];
            /* Koch: ditto, spaces in path */
            [args addObject: [indexPath lastPathComponent]];
        
            if (indexTask != nil) {
                [indexTask terminate];
                [indexTask release];
                indexTask = nil;
            }
            indexTask = [[NSTask alloc] init];
            [indexTask setCurrentDirectoryPath: [sourcePath  stringByDeletingLastPathComponent]];
            [indexTask setEnvironment: TSEnvironment];
            tetexBinPath = [[SUD stringForKey:TetexBinPathKey] stringByAppendingString:@"/"];
            enginePath = [tetexBinPath stringByAppendingString:@"makeindex"];
            [indexTask setLaunchPath: enginePath];
            [indexTask setArguments:args];
            [indexTask setStandardOutput: outputPipe];
            [indexTask setStandardError: outputPipe];
            [indexTask setStandardInput: inputPipe];
            [indexTask launch];
        }
    }
}


- (void) doTex: sender 
{
    [self doJob:0 withError:YES];
}

- (void) doLatex: sender;
{
    [self doJob:1 withError:YES];
}

- (void) doContext: sender;
{
    [self doJob:2 withError:YES];
}

- (void) doMetapost: sender;
{
    [self doJob:4 withError:YES];
}

- (void) doBibtex: sender;
{
    [self doJob:5 withError:NO];
}

- (void) doIndex: sender;
{
    [self doJob:6 withError:NO];
}

- (void) doTypesetEE: sender;
{
    [self doTypeset: sender];
}

- (void) doTypeset: sender;
{
    NSString	*titleString;
    
    titleString = [sender title];
    if ([titleString isEqualToString: @"TeX"]) 
        [self doTex:self];
    else if ([titleString isEqualToString: @"LaTeX"])
        [self doLatex: self];
    else if ([titleString isEqualToString: @"MetaPost"])
        [self doMetapost: self];
    else if ([titleString isEqualToString: @"ConTeXt"])
        [self doContext: self];
    else if ([titleString isEqualToString: @"BibTeX"])
        [self doBibtex: self];
    else if ([titleString isEqualToString: @"Index"])
        [self doIndex: self];
}

- (void) doTexCommand: sender;
{
    NSData *myData;
    NSString *command;
    
    if ((typesetStart) && (inputPipe)) {
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

- (void) chooseProgramEE: sender;
{
    [self chooseProgram: sender];
}


- (void) chooseProgram: sender;
{
    id		theItem;
    int		which;
    
    theItem = [sender selectedItem];
    which = [theItem tag];
    
    switch (which) {
    
        case 0:
            [typesetButton setTitle: @"TeX"];
            [typesetButtonEE setTitle: @"TeX"];
            break;
        
        case 1:
            [typesetButton setTitle: @"LaTeX"];
            [typesetButtonEE setTitle: @"LaTeX"];
            break;

        case 2:
            [typesetButton setTitle: @"BibTeX"];
            [typesetButtonEE setTitle: @"BibTeX"];
            break;
            
        case 3:
            [typesetButton setTitle: @"Index"];
            [typesetButtonEE setTitle: @"Index"];
            break;
            
        case 4:
            [typesetButton setTitle: @"MetaPost"];
            [typesetButtonEE setTitle: @"MetaPost"];
            break;
            
        case 5:
            [typesetButton setTitle: @"ConTeXt"];
            [typesetButtonEE setTitle: @"ConTeXt"];
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
     NSString		*project, *nameString; //, *anotherString;
     
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
//            if ([nameString isAbsolutePath])
                [nameString writeToFile: project atomically: YES];
//           else {
//                anotherString = [[self fileName] stringByDeletingLastPathComponent];
//                anotherString = [[anotherString stringByAppendingString:@"/"] 
//                        stringByAppendingString: nameString];
//                nameString = [anotherString stringByStandardizingPath];
//                [nameString writeToFile: project atomically: YES];
//                } 
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

- (void) doModify: (int)type;
{
    NSString		*text, *oldString;
    NSRange		myRange, modifyRange, tempRange, oldRange;
    unsigned		start, end, end1, changeStart, changeEnd;
    int			theChar;
    NSUndoManager	*myManager;
    NSMutableDictionary	*myDictionary;
    NSNumber		*theLocation, *theLength, *theType;

    text = [textView string];
    myRange = [textView selectedRange];
    // get old string for Undo
    [text getLineStart:&start end:&end contentsEnd:&end1 forRange:myRange];
    oldRange.location = start;
    oldRange.length = end1 - start;
    oldString = [[textView string] substringWithRange: oldRange];

    changeStart = start;
    changeEnd = start;
    end = start;
    while (end < (myRange.location + myRange.length)) {
        modifyRange.location = end;
        modifyRange.length = 0;
        [text getLineStart:&start end:&end contentsEnd:&end1 forRange:modifyRange];
        changeEnd = end1;
        if ((end1 - start) > 0)
            theChar = [text characterAtIndex: start];
        switch (type) {
        
            case Mcomment:	if ((end1 == start) || (theChar != 0x0025)) {
                                    tempRange.location = start;
                                    tempRange.length = 0;
                                    [textView replaceCharactersInRange:tempRange withString:@"%"];
                                    myRange.length++; oldRange.length++;
                                    changeEnd++;
                                    end++;
                                    }
                                break;
                                            
            case Muncomment:	if ((end1 != start) && (theChar == 0x0025)) {
                                    tempRange.location = start;
                                    tempRange.length = 1;
                                    [textView replaceCharactersInRange:tempRange withString:@""];
                                    myRange.length--; oldRange.length--;
                                    changeEnd--;
                                    end--;
                                    }
                                break;
            
            case Mindent: 	if (0 == 0) /* (end1 == start) || (theChar != 0x0025)) */ {
                                    tempRange.location = start;
                                    tempRange.length = 0;
                                    [textView replaceCharactersInRange:tempRange withString:@" "];
                                    myRange.length++; oldRange.length++;
                                    changeEnd++;
                                    end++;
                                    }
                                break;

            
            case Munindent: 	if ((end1 != start) && (theChar == 0x0020)) {
                                    tempRange.location = start;
                                    tempRange.length = 1;
                                    [textView replaceCharactersInRange:tempRange withString:@""];
                                    myRange.length--; oldRange.length--;
                                    changeEnd--;
                                    end--;
                                    }
                                break;

            }
        end++;
        }
    [self fixColor:changeStart :changeEnd];
    tempRange.location = changeStart;
    tempRange.length = (changeEnd - changeStart);
    [textView setSelectedRange: tempRange];

    myManager = [textView undoManager];
    myDictionary = [NSMutableDictionary dictionaryWithCapacity: 4];
    theLocation = [NSNumber numberWithUnsignedInt: oldRange.location];
    theLength = [NSNumber numberWithUnsignedInt: oldRange.length];
    theType = [NSNumber numberWithInt: type];
    [myDictionary setObject: oldString forKey: @"oldString"];
    [myDictionary setObject: theLocation forKey: @"oldLocation"];
    [myDictionary setObject: theLength forKey: @"oldLength"];
    [myDictionary setObject: theType forKey: @"theType"];
    [myManager registerUndoWithTarget:self selector:@selector(fixModify:) object: myDictionary];
    switch (type) {
        case Mcomment: 	[myManager setActionName:@"Comment"]; break;
        case Muncomment:[myManager setActionName:@"Uncomment"]; break;
        case Mindent:	[myManager setActionName:@"Indent"]; break;
        case Munindent:	[myManager setActionName:@"Unindent"]; break;
        }
}

- (void) doComment: sender;
{
    [self doModify:Mcomment];
}

- (void) doUncomment: sender;
{
    [self doModify:Muncomment];
}

- (void) doIndent: sender;
{
    [self doModify:Mindent];
}

- (void) doUnindent: sender;
{
    [self doModify:Munindent];
}


//-----------------------------------------------------------------------------
- (void) fixModify: (id) theDictionary;
//-----------------------------------------------------------------------------

{
    NSRange		oldRange;
    NSString		*oldString, *newString;
    NSUndoManager	*myManager;
    NSMutableDictionary	*myDictionary;
    NSNumber		*theLocation, *theLength;
    unsigned		from, to;
    int			type;
    
    oldRange.location = [[theDictionary objectForKey: @"oldLocation"] unsignedIntValue];
    oldRange.length = [[theDictionary objectForKey: @"oldLength"] unsignedIntValue];
    type = [[theDictionary objectForKey:@"theType"] intValue];
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
    [myManager registerUndoWithTarget:self selector:@selector(fixModify:) object: myDictionary];
    switch (type) {
        case Mcomment: 	[myManager setActionName:@"Comment"]; break;
        case Muncomment:[myManager setActionName:@"Uncomment"]; break;
        case Mindent:	[myManager setActionName:@"Indent"]; break;
        case Munindent:	[myManager setActionName:@"Unindent"]; break;
        }
    from = oldRange.location;
    to = from + [newString length];
    [self fixColor: from :to];
    [self setupTags];
}

- (void) doTag: sender;
{
    NSString	*text, *tagString, *title, *mainTitle;
    unsigned	start, end, irrelevant;
    NSRange	myRange, nameRange, gotoRange;
    unsigned	length;
    int		theChar;
    int		texChar;
    int		sectionIndex = -1;
    BOOL	done;
    
    title = [tags titleOfSelectedItem];
    
    /* code by Anton Leuski */
    if ([SUD boolForKey: TagSectionsKey]) { 
		unsigned  i;
		for(i = 0; i < [kTaggedTeXSections count]; ++i) {
			NSString*  tag = [kTaggedTagSections objectAtIndex:i];
			if ([title hasPrefix:tag]) {
				sectionIndex = i;
                                myRange.location = [tag length];
                                myRange.length = [title length] - myRange.location;
                                mainTitle = [title substringWithRange: myRange];
				break;
			}
		}
	}
    
    if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"]) 
        texChar = 165;
    else
        texChar = 0x005c;

        
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

            /* code by Anton Leuski */
            else if ((theChar == texChar) && (start < length - 8) && (sectionIndex >= 0)) {
			
                NSString*  tag		= [kTaggedTeXSections objectAtIndex:sectionIndex];
                nameRange.location	= start;
                nameRange.length	= [tag length];
                tagString 		= [text substringWithRange: nameRange];

                if ([tagString isEqualToString:tag]) {
				
                    nameRange.location = start + nameRange.length;
                    nameRange.length = (end - start - nameRange.length);
                    tagString = [text substringWithRange: nameRange];
					
                    if ([mainTitle isEqualToString:tagString]) {
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
    [tags addItemWithTitle:NSLocalizedString(@"Tags", @"Tags")];
    tagTimer = [[NSTimer scheduledTimerWithTimeInterval: .02 target:self selector:@selector(fixTags:) userInfo:nil repeats:YES] retain];
}

- (void) doChooseMethod: sender;
{
    [[[[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Typeset", @"Typeset")] submenu] 
        itemWithTag:100] setState:NSOffState];
    [[[[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Typeset", @"Typeset")] submenu] 
        itemWithTag:101] setState:NSOffState];
    [[[[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Typeset", @"Typeset")] submenu] 
        itemWithTag:102] setState:NSOffState];
    [sender setState:NSOnState];
    whichScript = [sender tag]; 
}

- (void) fixTypesetMenu;
{
    NSMenuItem 	*aMenu;
    int		i;
    
    for (i = 100; i <= 102; i++) {
        aMenu = [[[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Typeset", @"Typeset")] 
            submenu] itemWithTag:i]; 
        if (whichScript == i)
            [aMenu setState:NSOnState];
        else
            [aMenu setState:NSOffState];
        }
}

- (void)newMainWindow:(NSNotification *)notification
{
	id object = [notification object];
        if ((object == pdfWindow) || (object == textWindow) || (object == outputWindow))
            [self fixTypesetMenu];
}



- (void) doError: sender;
{
    if ((!externalEditor) && (fileIsTex) && (errorNumber > 0)) {
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

- (id) pdfWindow;
{
    return pdfWindow;
}

- (id) textWindow;
{
    return textWindow;
}

- (id) textView;
{
    return textView;
}


- (int) imageType;
{
    return myImageType;
}

- (NSPDFImageRep *) myTeXRep;
{
    return texRep;
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    BOOL  result;
    
    result = [super validateMenuItem: anItem];
    if (fileIsTex)
        return result;
    else if ([[anItem title] isEqualToString:NSLocalizedString(@"Save", @"Save")]) {
        if (myImageType == isOther)
            return YES;
        else
            return NO;
        }
    else if([[anItem title] isEqualToString:NSLocalizedString(@"Print Source...", @"Print Source...")]) {
        if (myImageType == isOther)
            return YES;
        else
            return NO;
        }
    else if ([[anItem title] isEqualToString:@"Plain TeX"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"LaTeX"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"BibTeX"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"MakeIndex"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"MetaPost"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"ConTeXt"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString: NSLocalizedString(@"Print...", @"Print...")]) {
        if ((myImageType == isPDF) || (myImageType == isJPG) || (myImageType == isTIFF))
            return YES;
        else
            return NO;
        }
    else if ([[anItem title] 
            isEqualToString: NSLocalizedString(@"Set Project Root...", @"Set Project Root...")]) {
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
   // [self updateChangeCount: NSChangeDone];
}

- (void)fixColor: (unsigned)from : (unsigned)to
{
    NSRange	colorRange;
    NSString	*textString;
    // NSColor	*commentColor, *commandColor, *markerColor;
    NSColor	*regularColor;
    long	length, location, final;
    unsigned	start1, end1;
    int		theChar, texChar;
    unsigned	end;
    
    if ((! [SUD boolForKey:SyntaxColoringEnabledKey]) || (! fileIsTex)) return;
    
    if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"]) 
        texChar = 165;
    else
        texChar = 0x005c;
   
    // commentColor = [NSColor redColor];
    // commandColor = [NSColor blueColor];
    // markerColor = [NSColor purpleColor];
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
        
    // NSLog(@"begin");
    while (location < final) {
            theChar = [textString characterAtIndex: location];
            
             if ((theChar == 0x007b) || (theChar == 0x007d) || (theChar == 0x0024)) {
                colorRange.location = location;
                colorRange.length = 1;
                [textView setTextColor: markerColor range: colorRange];
                colorRange.location = colorRange.location + colorRange.length - 1;
                colorRange.length = 0;
                [textView setTextColor: regularColor range: colorRange];
                location++;
                }
                
             else if (theChar == 0x0025) {
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
                
             else if (theChar == texChar) {
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
        // NSLog(@"end");
        
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


/* code by Anton Leuski */
 if ([SUD boolForKey: TagSectionsKey]) {
	
    unsigned	i;
    for(i = 0; i < [kTaggedTeXSections count]; ++i) {
        tagRange = [replacementString rangeOfString:[kTaggedTeXSections objectAtIndex:i]];
        if (tagRange.length != 0) {
            tagLine = YES;
            break;
            }
        }
            
    if (!tagLine) {

        textString = [textView string];
        [textString getLineStart:&start end:&end 
            contentsEnd:&end1 forRange:affectedCharRange];
        tagRange.location	= start;
        tagRange.length		= end - start;

        for(i = 0; i < [kTaggedTeXSections count]; ++i) {
            matchRange = [textString rangeOfString:
                [kTaggedTeXSections objectAtIndex:i] options:0 range:tagRange];
            if (matchRange.length != 0) {
                tagLine = YES;
                break;
                }
            }

        }
    }
    
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
    int		theChar, texChar;

    if (!fileIsTex) return;
     
    if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"]) 
        texChar = 165;
    else
        texChar = 0x005c;
        
    text = [textView string];
    length = [text length];
    index = tagLocation + 10000;
    myRange.location = tagLocation;
    myRange.length = 1;
    
    while ((myRange.location < length) && (myRange.location < index)) { 
        [text getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
        myRange.location = end;
        
        if ((start + 3) < end) {
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
                
                /* code by Anton Leuski */
                else if ((theChar == texChar) &&  ([SUD boolForKey: TagSectionsKey])) {
					
                    unsigned	i;
                    for(i = 0; i < [kTaggedTeXSections count]; ++i) {
                        NSString* tag = [kTaggedTeXSections objectAtIndex:i];
                        nameRange.location	= start;
                        nameRange.length	= [tag length];
                        /* change by Koch to fix tag bug in 1.16 and 1.17 */
                        if ((start + nameRange.length) < end)
                            tagString = [text substringWithRange: nameRange];
                        else
                            tagString = nil;
                        if ((tagString != nil) && ([tagString isEqualToString:tag])) {
                            nameRange.location = start + [tag length];
                            nameRange.length = (end - start - [tag length]);
                            tagString = [NSString stringWithString:
                                [kTaggedTagSections objectAtIndex:i]];
                            tagString = [tagString stringByAppendingString: 
                            [text substringWithRange: nameRange]];
                            [tags addItemWithTitle:tagString];
                            }
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

//-----------------------------------------------------------------------------
- (void)fixColor1:(NSTimer *)timer;
//-----------------------------------------------------------------------------
{
    NSRange	colorRange;
    NSString	*textString;
    NSColor	*commentColor1, *commandColor1, *markerColor1;
    NSColor	*regularColor;
    long	length, limit;
    int		theChar, texChar;
    unsigned	end;
    
// This is very slow on Jaguar. Experimentation shows that the only slow command is setTextColor
// It is FAR slower when called here than when called in fixColor!!

//    limit = colorLocation + 5000;
    limit = colorLocation + COLORLENGTH;

    if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"]) 
        texChar = 165;
    else
        texChar = 0x005c;
    
    regularColor = [NSColor blackColor];
    if ([SUD boolForKey:SyntaxColoringEnabledKey]) {
        commentColor1 = commentColor;
        commandColor1 = commandColor;
        markerColor1 = markerColor;
        }
    else {
        commentColor1 = regularColor;
        commandColor1 = regularColor;
        markerColor1 = regularColor;
        }
 
    textString = [textView string];
    length = [textString length];
    
    // NSLog(@"begin");
    while ((colorLocation < length) && (colorLocation < limit))  
    {
        theChar = [textString characterAtIndex: colorLocation];
 

        if ((theChar == 0x007b) || (theChar == 0x007d) || (theChar == 0x0024)) {
                colorRange.location = colorLocation;
                colorRange.length = 1;
                [textView setTextColor: markerColor1 range: colorRange];
                colorRange.location = colorRange.location + colorRange.length - 1;
               	colorRange.length = 0;
               	[textView setTextColor: regularColor range: colorRange];
                colorLocation++;
                }

        else 
        if (theChar == 0x0025) 
        {
            colorRange.location = colorLocation;
            colorRange.length = 0;
            [textString getLineStart:NULL end:NULL contentsEnd:&end forRange:colorRange];
            colorRange.length = (end - colorLocation);
            [textView setTextColor: commentColor1 range: colorRange];
            colorRange.location = colorRange.location + colorRange.length - 1;
            colorRange.length = 0;
            [textView setTextColor: regularColor range: colorRange];
            colorLocation = end;
        }
        else 
        
        if (theChar == texChar) 
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
            [textView setTextColor: commandColor1 range: colorRange];
             colorRange.location = colorLocation;
             colorRange.length = 0;
             [textView setTextColor: regularColor range: colorRange];
        }
    
        else 
            colorLocation++;
    }
   //  NSLog(@"end");
    
    if (colorLocation >= length) 
    {
        [syntaxColoringTimer invalidate];
        [syntaxColoringTimer release];
        syntaxColoringTimer = nil;
    }
}

// #define COLORTIME  .3
// #define COLORLENGTH 500000


/*
- (void)fixColor1:(NSTimer *)timer;
{
    NSRange	colorRange, cutRange;
    NSString	*textString;
    NSColor	*commentColor1, *commandColor1, *markerColor1;
    NSColor	*regularColor;
    long	length, limit;
    int		theChar, texChar;
    unsigned	end, currentLocation=0;
    NSMutableAttributedString *myAttribString;

    if(colorLocation==0){
        NSLog(@"start color");
        [textView setEditable:NO];
    }
    limit = colorLocation + COLORLENGTH;
    if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"])
        texChar = 165;
    else
        texChar = 0x005c;
    regularColor = [NSColor blackColor];
    if ([SUD boolForKey:SyntaxColoringEnabledKey]) {
        commentColor1 = commentColor;
        commandColor1 = commandColor;
        markerColor1 = markerColor;
    }
    else {
        commentColor1 = regularColor;
        commandColor1 = regularColor;
        markerColor1 = regularColor;
    }

    textString = [textView string];
    // je coupe un nombre de lignes avec lesquelles je vais travailler.
    cutRange=NSMakeRange(colorLocation,(limit<[textString length]?limit:[textString length])-colorLocation);
    [textString getLineStart:NULL end:NULL contentsEnd:&end forRange:cutRange];
    cutRange.length= (end>colorLocation)?end-colorLocation:0;
    colorLocation = end+1;
    colorRange=NSMakeRange(0,0);
    myAttribString = [[[NSMutableAttributedString alloc] initWithAttributedString:[textView attributedSubstringFromRange:cutRange]] autorelease];
    length = [textString length];
    while (currentLocation < cutRange.length)
        {
        theChar = [[myAttribString string] characterAtIndex: currentLocation];
        if ((theChar == 0x007b) || (theChar == 0x007d) || (theChar == 0x0024)) {
            colorRange.location = currentLocation;
            colorRange.length = 1;
            //[textView setTextColor: markerColor1 range: colorRange];
            [myAttribString setAttributes: [NSDictionary dictionaryWithObject:markerColor1 forKey:NSForegroundColorAttributeName] range:colorRange];
            //colorRange.location = colorRange.location + colorRange.length - 1;
            //colorRange.length = 0;
            //[textView setTextColor: regularColor range: colorRange];
            currentLocation++;
        }

        else if (theChar == 0x0025)
            {
            colorRange.location = currentLocation;
            colorRange.length = 0;
            [[myAttribString string] getLineStart:NULL end:NULL contentsEnd:&end forRange:colorRange];
            colorRange.length = (end - currentLocation);
            [myAttribString setAttributes: [NSDictionary dictionaryWithObject:commentColor1 forKey:NSForegroundColorAttributeName] range:colorRange];
            //colorRange.location = colorRange.location + colorRange.length - 1;
            //colorRange.length = 0;
            //[textView setTextColor: regularColor range: colorRange];
            currentLocation = end;
            }
        else if (theChar == texChar)
            {
            colorRange.location = currentLocation;
            colorRange.length = 1;
            currentLocation++;
            if ((currentLocation < cutRange.length) && ([[myAttribString string] characterAtIndex: currentLocation] == 0x0025))
                {
                colorRange.length = currentLocation - colorRange.location;
                currentLocation++;
                }
            else while ((currentLocation < cutRange.length) && (isText([[myAttribString string] characterAtIndex: currentLocation])))
                {
                currentLocation++;
                colorRange.length = currentLocation - colorRange.location;
                }
                [myAttribString setAttributes: [NSDictionary dictionaryWithObject:commandColor1 forKey:NSForegroundColorAttributeName] range:colorRange];
            //colorRange.location = colorLocation;
            //colorRange.length = 0;
            //[textView setTextColor: regularColor range: colorRange];
            }
        else
            currentLocation++;
        }// endWhile
    // je substitue...
    //NSLog(@"done while");
    [[textView textStorage] replaceCharactersInRange: cutRange withAttributedString:myAttribString];
    if (colorLocation >= length)
        {
        [syntaxColoringTimer invalidate];
        [syntaxColoringTimer release];
        syntaxColoringTimer = nil;
        NSLog(@"done color");
        [textView setEditable:YES];
        }
}
*/

//-----------------------------------------------------------------------------
- (void)reColor:(NSNotification *)notification;
//-----------------------------------------------------------------------------
{
    NSString	*textString;
    long	length;
    
    if (syntaxColoringTimer != nil) {
        [syntaxColoringTimer invalidate];
        [syntaxColoringTimer release];
        syntaxColoringTimer = nil;
        }
        
    textString = [textView string];
    length = [textString length];
    [self fixColor :0 :length];
    
    // colorLocation = 0;
    // syntaxColoringTimer = [[NSTimer scheduledTimerWithTimeInterval: COLORTIME target:self selector:@selector(fixColor1:) 	userInfo:nil repeats:YES] retain];
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
    
    [outputText setSelectable: YES];

    if (([aNotification object] == bibTask) || ([aNotification object] == indexTask)) 
    {
        if (inputPipe == [[aNotification object] standardInput]) 
        {
            [outputPipe release];
            [writeHandle closeFile];
            [inputPipe release];
            inputPipe = 0;
            if ([aNotification object] == bibTask) {
                [bibTask terminate];
                [bibTask release];
                bibTask = nil;
                }
            else if ([aNotification object] == indexTask) {
                [indexTask terminate];
                [indexTask release];
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
                NSString *projectRoot = [NSString stringWithContentsOfFile: projectPath];
                if ([projectRoot isAbsolutePath]) {
                    nameString = [NSString stringWithString:projectRoot];
                }
                else {
                    nameString = [[self fileName] stringByDeletingLastPathComponent];
                    nameString = [[nameString stringByAppendingString:@"/"] 
                        stringByAppendingString: [NSString stringWithContentsOfFile: projectPath]];
                    nameString = [nameString stringByStandardizingPath];
                }
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
                        /* [pdfWindow setTitle:[[[[self fileName] lastPathComponent] stringByDeletingPathExtension] 					stringByAppendingPathExtension:@"pdf"]]; */
                        [pdfWindow setTitle: [imagePath lastPathComponent]];
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
            [texTask terminate];
            [texTask release];
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
            if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"])
                newOutput = [[NSString alloc] initWithData: myData 
                    encoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacJapanese)];
            else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacKorean"])
                newOutput = [[NSString alloc] initWithData: myData 
                    encoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacKorean)];
            else
                newOutput = [[NSString alloc] initWithData: myData 
                    encoding: NSMacOSRomanStringEncoding];
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
                            [outputWindow makeKeyAndOrderFront: self];
                        }
                    }
                }
            }

            typesetStart = YES;
            
            [outputText replaceCharactersInRange: [outputText selectedRange] withString: newOutput];
            [outputText scrollRangeToVisible: [outputText selectedRange]];
            [newOutput release];
            [readHandle readInBackgroundAndNotify];
        }
    }
}

- (NSDictionary *)fileAttributesToWriteToFile:(NSString *)fullDocumentPath ofType:(NSString *)documentTypeName saveOperation:(NSSaveOperationType)saveOperationType
{
    NSDictionary	*myDictionary;
    NSMutableDictionary	*aDictionary;
    NSNumber		*myNumber;
    
    myDictionary = [super fileAttributesToWriteToFile: fullDocumentPath ofType: documentTypeName
                    saveOperation: saveOperationType];
    aDictionary = [NSMutableDictionary dictionaryWithDictionary: myDictionary];
    myNumber = [NSNumber numberWithLong:'TEXT'];
    [aDictionary setObject: myNumber forKey: NSFileHFSTypeCode];
    myNumber = [NSNumber numberWithLong:'TeXs'];
    [aDictionary setObject: myNumber forKey: NSFileHFSCreatorCode]; 
    return aDictionary;
}

/* Code by Nicol‡s Ojeda BŠr */
- (int) textViewCountTabs: (NSTextView *) aTextView
{
    int startLocation = [aTextView selectedRange].location - 1, tabCount = 0;

    if (startLocation < 0)
    return 0;

    while ([[aTextView string] characterAtIndex: startLocation] != '\n') {
    
        if ([[aTextView string] characterAtIndex: startLocation --] != '\t')
            tabCount = 0;
        else
            ++ tabCount;
            
        if (startLocation < 0)
            break;
    }

    return tabCount;
}

/* Code by Nicol‡s Ojeda BŠr */
- (BOOL) textView: (NSTextView *) aTextView doCommandBySelector: (SEL)
aSelector
{
    if (aSelector == @selector (insertNewline:)) {
    int n, indent = [self textViewCountTabs: textView];

    [aTextView insertNewline: self];

    for (n = 0; n < indent; ++ n)
        [aTextView insertText: @"\t"];

    return YES;
    }

    return NO;
}

//-----------------------------------------------------------------------------
- (void) fixTyping: (id) theDictionary;
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
    [myManager registerUndoWithTarget:self selector:@selector(fixTyping:) object: myDictionary];
    [myManager setActionName:@"Typing"];
    from = oldRange.location;
    to = from + [newString length];
    [self fixColor: from :to];
    [self setupTags];

}

/* New Code by Max Horn, to activate #SEL# and #INS# in Panel Strings */
- (void)doCompletion:(NSNotification *)notification
{
    NSRange			oldRange;
    NSRange			searchRange;
    NSWindow		*activeWindow;
    NSMutableString	*newString;
    NSString		*oldString;
    unsigned		from, to;
    NSUndoManager	*myManager;
    NSMutableDictionary	*myDictionary;
    NSNumber		*theLocation, *theLength;

    activeWindow = [[TSWindowManager sharedInstance] activeDocumentWindow];
    if ((activeWindow != nil) && (activeWindow == [self textWindow])) {
        // Determine the curent selection range & text
        oldRange = [textView selectedRange];
        oldString = [[textView string] substringWithRange: oldRange];

        // Fetch the replacement text
        newString = [[notification object] mutableCopy];

        // Substitute all occurances of #SEL# with the original text
        searchRange.location = 0;
        while (searchRange.location != NSNotFound) {
            searchRange.length = [newString length] - searchRange.location;
            searchRange = [newString rangeOfString:@"#SEL#" options:NSLiteralSearch range:searchRange];
            if (searchRange.location != NSNotFound) {
                [newString replaceCharactersInRange:searchRange withString:oldString];
                searchRange.location += oldRange.length;
            }
        }

        // Now search for #INS#, remember its position, and remove it. We will
        // Later position the insertion mark there. Defaults to end of string.
        searchRange = [newString rangeOfString:@"#INS#" options:NSLiteralSearch];
        if (searchRange.location != NSNotFound)
            [newString replaceCharactersInRange:searchRange withString:@""];
        
        // Insert the new text
        [textView replaceCharactersInRange:oldRange withString:newString];
        
        // Create & register an undo action
        myManager = [textView undoManager];
        myDictionary = [NSMutableDictionary dictionaryWithCapacity: 3];
        theLocation = [NSNumber numberWithUnsignedInt: oldRange.location];
        theLength = [NSNumber numberWithUnsignedInt: [newString length]];
        [myDictionary setObject: oldString forKey: @"oldString"];
        [myDictionary setObject: theLocation forKey: @"oldLocation"];
        [myDictionary setObject: theLength forKey: @"oldLength"];
        [myManager registerUndoWithTarget:self selector:@selector(fixTyping:) object: myDictionary];
        [myManager setActionName:@"Typing"];
        from = oldRange.location;
        to = from + [newString length];
        [self fixColor:from :to];
        [self setupTags];
        [newString release];

        // Place insertion mark
        if (searchRange.location != NSNotFound)
        {
            searchRange.location += oldRange.location;
            searchRange.length = 0;
            [textView setSelectedRange:searchRange];
        }
    }
}



@end
