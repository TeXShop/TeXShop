//
//  TSAppDelegate.m
//  TeXShop
//
//  Created by dirk on Tue Jan 23 2001.g
//

#import "UseMitsu.h"

#import <Foundation/Foundation.h>
#import "TSAppDelegate.h"
#import "TSPreferences.h"
#import "globals.h"
#import "TSWindowManager.h"
#import "MacroMenuController.h"
#import "MyDocumentController.h"
#import "EncodingSupport.h"
#import "OgreKit/OgreTextFinder.h"
#import "TextFinder.h"

#ifdef MITSU_PDF
// mitsu 1.29 (O)
#import "MyPDFView.h"
// extern int imageCopyType; // already in globals.h
// end mitsu 1.29
#endif

#define SUD [NSUserDefaults standardUserDefaults]

/*" This class is registered as the delegate of the TeXShop NSApplication object. We do various stuff here, e.g. registering factory defaults, dealing with keyboard shortcuts etc.
"*/
@implementation TSAppDelegate

- (id)init
{
    return [super init];
}

- (void)testForIntel;
{
    
// if the processor is intel and the path variable preference is /usr/local/tetex/bin/powerpc-apple-darwin-current, then
// change that preference permanently to /usr/local/tetex/bin/i386-apple-darwin-current

    NSString *binPath = [SUD stringForKey:TetexBinPathKey];
    if (! [binPath isEqualToString:@"/usr/local/teTeX/bin/powerpc-apple-darwin-current"])
	return;
	
// now test /usr/bin/uname -p; if this is Intel then make the change

    unameTask = [[NSTask alloc] init];
    NSString *enginePath = [[NSBundle mainBundle] pathForResource:@"unamewrap" ofType:nil];
    unamePipe = [[NSPipe pipe] retain];
    unameHandle = [unamePipe fileHandleForReading];
    [unameTask setStandardOutput: unamePipe];
    if ((enginePath != nil) && ([[NSFileManager defaultManager] fileExistsAtPath: enginePath])) {
        [unameTask setLaunchPath:enginePath];
        [unameTask launch];
	[unameTask waitUntilExit];
	int status = [unameTask terminationStatus];
	if (status == 0) {
	    NSData *theData = [unameHandle readDataToEndOfFile];
	    char * myData = [theData bytes];
	    if (([theData length] >= 4) && (myData[0] == 'i') && (myData[1] == '3') && (myData[2] == '8') && (myData[3] == '6')) {
		NSString *newBinPath = [NSString stringWithString: @"/usr/local/teTeX/bin/i386-apple-darwin-current"];
		[SUD setObject: newBinPath forKey:TetexBinPathKey];
		[SUD synchronize];
		}
	    }
	}

    if (unamePipe) {
	[unamePipe release];
	unamePipe = nil;
	}
    if (unameTask) {
	[unameTask release];
        unameTask = nil;
	}
}


- (void)setForPreview: (BOOL)value;
{
    forPreview = value;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    NSString *fileName;
    NSMutableString *path;
    NSDictionary *factoryDefaults;
//	OgreTextFinder *theFinder;
    id *theFinder;
	long	MacVersion;
	
    // documentsHaveLoaded = NO;

    
    macroType = LatexEngine;
    
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
    // if this is the first time the app is used, register a set of defaults to make sure
    // that the app is useable.
    if (([[NSUserDefaults standardUserDefaults] boolForKey:TSHasBeenUsedKey] == NO) ||
        ([[NSUserDefaults standardUserDefaults] objectForKey:TetexBinPathKey] == nil)) {
        [[TSPreferences sharedInstance] registerFactoryDefaults];
    }
    
    else {
	// register defaults
	fileName = [[NSBundle mainBundle] pathForResource:@"FactoryDefaults" ofType:@"plist"];
	NSParameterAssert(fileName != nil);
	factoryDefaults = [[NSString stringWithContentsOfFile:fileName] propertyList];
        [SUD registerDefaults:factoryDefaults];
    }
    
    // get copy of environment and add the preferences paths
    TSEnvironment = [[NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]] retain];
    path = [NSMutableString stringWithString: [TSEnvironment objectForKey:@"PATH"]];
    [path appendString:@":"];
    [path appendString:[SUD stringForKey:TetexBinPathKey]];
    [path appendString:@":"];
    [path appendString:[SUD stringForKey:GSBinPathKey]];
    [TSEnvironment setObject: path forKey: @"PATH"];
    NSString *editPath = [[NSBundle mainBundle] pathForResource:@"TEXTEDIT" ofType:nil inDirectory:@"TEXTEDIT.app/Contents/MacOS"];
    // NSLog(editPath);
    NSString *newEditPath = [editPath stringByAppendingString:@" %%s %%d"];
    // NSLog(newEditPath);
    // NSString *newEditPath = [editPath stringByAppendingString:@" %s %d"];
    // NSString *newEditPath = @" \%s \%d";
    // NSLog(newEditPath);
    [TSEnvironment setObject: newEditPath forKey:@"TEXEDIT"];

// Set up ~/Library/TeXShop; must come before dealing with EncodingSupport and MacoMenuController below    
    [self configureTemplates]; // this call must come first because it creates the TeXShop folder if it does not yet exist
    [self configureScripts];
    [self configureBin];
    [self configureEngine];
    [self configureMenuShortcutsFolder];
    [self configureAutoCompletion];
    [self configureLatexPanel];
    [self configureMatrixPanel];  //Matrix addition by Jonas
    [self configureMacro];
    [self prepareConfiguration: CommandCompletionPathKey]; // mitsu 1.29 (P)
    
// Finish configuration of various pieces
    [[MacroMenuController sharedInstance] loadMacros];
    [self finishAutoCompletionConfigure];
    [self finishMenuKeyEquivalentsConfigure];
    [self configureExternalEditor];
    
     if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"]) 
        texChar = 165;		// yen
    else
        texChar = 0x005c;	// backslash

// added by mitsu --(H) Macro menu and (G) EncodingSupport
    [[EncodingSupport sharedInstance] setupForEncoding];        // this must come after
    [[MacroMenuController sharedInstance] setupMainMacroMenu];
    [[MyDocumentController sharedDocumentController] initializeEncoding];  // so when first document is created, it has correct default
// end addition

    [self finishCommandCompletionConfigure]; // mitsu 1.29 (P) need to call after setupForEncoding

#ifdef MITSU_PDF
	// mitsu 1.29b check menu item for image format for copying and exporting
	int imageCopyType = [SUD integerForKey:PdfCopyTypeKey];
        if (!imageCopyType) 
		imageCopyType = IMAGE_TYPE_JPEG_MEDIUM; // default PdfCopyTypeKey
	NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
							NSLocalizedString(@"Preview", @"Preview")] submenu];
	NSMenuItem *item = [previewMenu itemWithTitle: 
							NSLocalizedString(@"Copy Format", @"format")];
	if (item)
	{
		NSMenu *formatMenu = [item submenu];
		item = [formatMenu itemWithTag: imageCopyType];
		if (item)
			[item setState: NSOnState];
	}
        
	[NSColor setIgnoresAlpha:NO]; // it seesm necessary to call this to activate alpha
	// end mitsu 1.29b
        
	// mitsu 1.29 drag & drop
	NSFileManager	*fileManager = [NSFileManager defaultManager];
	NSString *draggedImageFolder = [[DraggedImagePathKey stringByStandardizingPath] 
										stringByDeletingLastPathComponent];
    if (!([fileManager fileExistsAtPath: draggedImageFolder]))
    {
		NS_DURING
			[fileManager createDirectoryAtPath: draggedImageFolder attributes:nil];
		NS_HANDLER
		NS_ENDHANDLER
	}
	// end mitsu 1.29
#endif

        if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr) {
        
            if (([SUD boolForKey:ConvertLFKey]) && (MacVersion >= 0x1030) && ([SUD boolForKey:UseOgreKitKey] == TRUE)) 
                   theFinder = [OgreTextFinder sharedTextFinder];
                else
                    theFinder = [TextFinder sharedInstance];
        }
        else
            theFinder = [TextFinder sharedInstance];
	    
	[self testForIntel];

    // documentsHaveLoaded = NO;
}

// mitsu 1.29 drag & drop
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	NSString *folderPath, *filename;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	folderPath = [[DraggedImagePathKey stringByStandardizingPath] 
								stringByDeletingLastPathComponent];
	NSEnumerator *enumerator = [[fileManager directoryContentsAtPath: folderPath] 
								objectEnumerator];
	while (filename = [enumerator nextObject]) 
	{
		if ([filename characterAtIndex: 0] != '.') 
			[fileManager removeFileAtPath:[folderPath stringByAppendingPathComponent: 
								filename] handler: nil];
	}
}
// end mitsu 1.29


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return [SUD boolForKey:MakeEmptyDocumentKey];
}


/*" %{This method is not to be called from outside of this class.}

Copies %fileName to ~/Library/TeXShop/Templates. This method takes care that no files are overwritten.
"*/
//------------------------------------------------------------------------------
- (void)copyToTemplateDirectory:(NSString *)fileName
//------------------------------------------------------------------------------
{
	NSFileManager *fileManager;
	NSString *destFileName;
        BOOL result;
	
	fileManager = [NSFileManager defaultManager];
	destFileName = [NSString pathWithComponents:[NSArray arrayWithObjects:[TexTemplatePathKey stringByStandardizingPath], 
                [fileName lastPathComponent], nil]];
	
	// check if that file already exists
	if ([fileManager fileExistsAtPath:destFileName isDirectory:NULL] == NO)
            {
            NS_DURING
            // file doesn't exist -> copy it
            result = [fileManager copyPath:fileName toPath:destFileName handler:nil];
            NS_HANDLER
            ;
            NS_ENDHANDLER
            }
}

/*" %{This method is not to be called from outside of this class.}

Copies %fileName to ~/Library/TeXShop/Templates/More. This method takes care that no files are overwritten.
"*/
//------------------------------------------------------------------------------
- (void)copyToMoreDirectory:(NSString *)fileName
//------------------------------------------------------------------------------
{
	NSFileManager *fileManager;
	NSString *destFileName;
        BOOL result;
	
	fileManager = [NSFileManager defaultManager];
	destFileName = [NSString pathWithComponents:[NSArray arrayWithObjects:[TexTemplateMorePathKey stringByStandardizingPath], 
                [fileName lastPathComponent], nil]];
	
	// check if that file already exists
	if ([fileManager fileExistsAtPath:destFileName isDirectory:NULL] == NO)
            {
            NS_DURING
            // file doesn't exist -> copy it
            result = [fileManager copyPath:fileName toPath:destFileName handler:nil];
            NS_HANDLER
            ;
            NS_ENDHANDLER
            }
}


/*" %{This method is not to be called from outside of this class.}

Copies %fileName to ~/Library/TeXShop/Templates. This method takes care that no files are overwritten.
"*/
//------------------------------------------------------------------------------
- (void)copyToBinaryDirectory:(NSString *)fileName
//------------------------------------------------------------------------------
{
	NSFileManager *fileManager;
	NSString *destFileName;
        BOOL result;
	
	fileManager = [NSFileManager defaultManager];
	destFileName = [NSString pathWithComponents:[NSArray arrayWithObjects:[BinaryPathKey stringByStandardizingPath], 
                [fileName lastPathComponent], nil]];
        destFileName = [destFileName stringByDeletingPathExtension];
	
	// check if that file already exists
	if ([fileManager fileExistsAtPath:destFileName isDirectory:NULL] == NO)
            {
            NS_DURING
            // file doesn't exist -> copy it
            result = [fileManager copyPath:fileName toPath:destFileName handler:nil];
            NS_HANDLER
            ;
            NS_ENDHANDLER
            }
}

/*" %{This method is not to be called from outside of this class.}

Copies %fileName to ~/Library/TeXShop/Engines. This method takes care that no files are overwritten.
"*/
//------------------------------------------------------------------------------
- (void)copyToEngineDirectory:(NSString *)fileName
//------------------------------------------------------------------------------
{
	NSFileManager *fileManager;
	NSString *destFileName;
        BOOL result;
	
	fileManager = [NSFileManager defaultManager];
	destFileName = [NSString pathWithComponents:[NSArray arrayWithObjects:[EnginePathKey stringByStandardizingPath], 
                [fileName lastPathComponent], nil]];
        // destFileName = [destFileName stringByDeletingPathExtension];
	
	// check if that file already exists
	if ([fileManager fileExistsAtPath:destFileName isDirectory:NULL] == NO)
            {
            NS_DURING
            // file doesn't exist -> copy it
            result = [fileManager copyPath:fileName toPath:destFileName handler:nil];
            NS_HANDLER
            ;
            NS_ENDHANDLER
            }
}



// ------------- these routines create ~/Library/TeXShop and folders and files if necessary ----------

- (void)configureTemplates
{
    	NSArray 	*templates;
	NSEnumerator 	*templateEnum;
        NSString 	*fileName;
        NSString        *morePath;
        NSFileManager	*fileManager;
        BOOL		result;
        NSString	*reason;
        
        fileManager = [NSFileManager defaultManager];

    // The code below was written by Sarah Chambers
     // if preferences folder doesn't exist already...
     
    // First create TeXShop directory if it does not exist
    if (!([fileManager fileExistsAtPath: [[TexTemplatePathKey stringByStandardizingPath] stringByDeletingLastPathComponent]]))
    {
        // create the necessary directories
            NS_DURING
            {
            // create ~/Library/TeXShop
                result = [fileManager createDirectoryAtPath:[[TexTemplatePathKey stringByStandardizingPath] 
                stringByDeletingLastPathComponent]  attributes:nil];
            }
            NS_HANDLER
                result = NO;
                reason = [localException reason];
            NS_ENDHANDLER
            if (!result) {
                NSRunAlertPanel(@"Error", reason, @"Couldn't create TeXShop Folder", nil, nil);
                return;
                }
    }
    
    
    // Next create Templates folder
    if (!([fileManager fileExistsAtPath: [TexTemplatePathKey stringByStandardizingPath]]))
        {
        // create the necessary directories
            NS_DURING
                // create ~/Library/TeXShop/Templates
                result = [fileManager createDirectoryAtPath:[TexTemplatePathKey stringByStandardizingPath] attributes:nil];
            NS_HANDLER
            	result = NO;
                reason = [localException reason];
            NS_ENDHANDLER
            if (!result) {
                NSRunAlertPanel(@"Error", reason, @"Couldn't create Templates Folder", nil, nil);
                return;
                }
        // fill in our templates
            templates = [NSBundle pathsForResourcesOfType:@".tex" inDirectory:[[NSBundle mainBundle] resourcePath]];
            templateEnum = [templates objectEnumerator];
            while (fileName = [templateEnum nextObject])
            {
                    [self copyToTemplateDirectory:fileName ];
            }
            
        // create the subdirectory "More"
            NS_DURING
                // create ~/Library/TeXShop/Templates/More
                morePath = [TexTemplatePathKey stringByAppendingString:@"/More"];
                result = [fileManager createDirectoryAtPath:[morePath stringByStandardizingPath] attributes:nil];
            NS_HANDLER
            	result = NO;
                reason = [localException reason];
            NS_ENDHANDLER
            if (!result) {
                NSRunAlertPanel(@"Error", reason, @"Couldn't create Templates/More Folder", nil, nil);
                return;
                }
        // fill in our templates
            templates = [NSBundle pathsForResourcesOfType:@"tex" 
                inDirectory:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/More"]];
            templateEnum = [templates objectEnumerator];
            while (fileName = [templateEnum nextObject])
            {
                    [self copyToMoreDirectory:fileName ];
            }

        }


// end of changes

}

- (void)configureScripts
{
        NSString 	*fileName, *scriptPath;
        NSFileManager	*fileManager;
        BOOL		result;
        NSString	*reason;
        
        fileManager = [NSFileManager defaultManager];

    // The code below is copied from Sarah Chambers' code
    
     // if Scripts folder doesn't exist already...
    if (!([fileManager fileExistsAtPath: [ScriptsPathKey stringByStandardizingPath]]))
        {
    
        // create the necessary directories
            NS_DURING
                // create ~/Library/TeXShop/Templates
                result = [fileManager createDirectoryAtPath:[ScriptsPathKey stringByStandardizingPath] attributes:nil];
            NS_HANDLER
                result = NO;
                reason = [localException reason];
            NS_ENDHANDLER
                if (!result) {
                    NSRunAlertPanel(@"Error", reason, @"Couldn't Create Scripts Folder", nil, nil);
                    return;
                    }
            }
    
    // now see if setname.scpt is inside; if not, copy it from the program folder
    scriptPath = [ScriptsPathKey stringByStandardizingPath];
    scriptPath = [scriptPath stringByAppendingPathComponent:@"setname"];
    scriptPath = [scriptPath stringByAppendingPathExtension:@"scpt"];
    if (! [fileManager fileExistsAtPath: scriptPath]) {
        NS_DURING
            {
            result = NO;
            fileName = [[NSBundle mainBundle] pathForResource:@"setname" ofType:@"scpt"];
            if (fileName) {
                result = [fileManager copyPath:fileName toPath:scriptPath handler:nil];
                }
            }
        NS_HANDLER
            result = NO;
            reason = [localException reason];
        NS_ENDHANDLER
            if (!result) {
                NSRunAlertPanel(@"Error", reason, @"Couldn't Create setname.scpt", nil, nil);
                return;
                }
        }

}

- (void)configureBin
{
        NSString 	*fileName;
        NSFileManager	*fileManager;
        BOOL		result;
        NSString	*reason;
        NSArray 	*binaries;
	NSEnumerator 	*binaryEnum;
        
        fileManager = [NSFileManager defaultManager];

    // The code below is copied from Sarah Chambers' code
    
     // if Binary folder doesn't exist already...
    if (!([fileManager fileExistsAtPath: [BinaryPathKey stringByStandardizingPath]]))
        {
    
        // create the necessary directories
            NS_DURING
                // create ~/Library/TeXShop/Templates
                result = [fileManager createDirectoryAtPath:[BinaryPathKey stringByStandardizingPath] attributes:nil];
            NS_HANDLER
                result = NO;
                reason = [localException reason];
            NS_ENDHANDLER
                if (!result) {
                    NSRunAlertPanel(@"Error", reason, @"Couldn't Create Binary Folder", nil, nil);
                    return;
                    }
                    
            // fill in our binaries
            binaries = [NSBundle pathsForResourcesOfType:@"bxx" inDirectory:[[NSBundle mainBundle] resourcePath]];
            binaryEnum = [binaries objectEnumerator];
            while (fileName = [binaryEnum nextObject])
                {
                    [self copyToBinaryDirectory:fileName ];
                }

            }
}
 
- (void)configureEngine
{
        NSString 	*fileName;
        NSFileManager	*fileManager;
        BOOL		result;
        NSString	*reason;
        NSArray 	*engines;
	NSEnumerator 	*enginesEnum;
        
        fileManager = [NSFileManager defaultManager];

    // The code below is copied from Sarah Chambers' code
    
     // if Binary folder doesn't exist already...
    if (!([fileManager fileExistsAtPath: [EnginePathKey stringByStandardizingPath]]))
        {
    
        // create the necessary directories
            NS_DURING
                // create ~/Library/TeXShop/Templates
                result = [fileManager createDirectoryAtPath:[EnginePathKey stringByStandardizingPath] attributes:nil];
            NS_HANDLER
                result = NO;
                reason = [localException reason];
            NS_ENDHANDLER
                if (!result) {
                    NSRunAlertPanel(@"Error", reason, @"Couldn't Create Engine Folder", nil, nil);
                    return;
                    }
                    
            // fill in our binaries
            engines = [NSBundle pathsForResourcesOfType:@"engine" inDirectory:[[NSBundle mainBundle] resourcePath]];
            enginesEnum = [engines objectEnumerator];
            while (fileName = [enginesEnum nextObject])
                {
                    [self copyToEngineDirectory:fileName ];
                }

            }
}


- (void)configureAutoCompletion
{
        NSString 	*fileName, *autoCompletionPath;
        NSFileManager	*fileManager;
        BOOL		result;
        NSString	*reason;
        
        fileManager = [NSFileManager defaultManager];

    // The code below is copied from Sarah Chambers' code
    
     // if Keyboard folder doesn't exist already...
    if (!([fileManager fileExistsAtPath: [AutoCompletionPathKey stringByStandardizingPath]]))
        {
    
        // create the necessary directories
            NS_DURING
                // create ~/Library/TeXShop/Templates
                result = [fileManager createDirectoryAtPath:[AutoCompletionPathKey stringByStandardizingPath] attributes:nil];
            NS_HANDLER
                result = NO;
                reason = [localException reason];
            NS_ENDHANDLER
                if (!result) {
                    NSRunAlertPanel(@"Error", reason, @"Couldn't Create Keyboard Folder", nil, nil);
                    return;
                    }
            }
    
    // now see if autocompletion.plist is inside; if not, copy it from the program folder
    autoCompletionPath = [AutoCompletionPathKey stringByStandardizingPath];
    autoCompletionPath = [autoCompletionPath stringByAppendingPathComponent:@"autocompletion"];
    autoCompletionPath = [autoCompletionPath stringByAppendingPathExtension:@"plist"];
    if (! [fileManager fileExistsAtPath: autoCompletionPath]) {
        NS_DURING
            {
            result = NO;
            fileName = [[NSBundle mainBundle] pathForResource:@"autocompletion" ofType:@"plist"];
            if (fileName) {
                result = [fileManager copyPath:fileName toPath:autoCompletionPath handler:nil];
                }
            }
        NS_HANDLER
            result = NO;
            reason = [localException reason];
        NS_ENDHANDLER
            if (!result) {
                NSRunAlertPanel(@"Error", reason, @"Couldn't Create AutoCompleteion plist", nil, nil);
                return;
                }
        }
}

- (void)configureLatexPanel
{
        NSString 	*fileName, *completionPath;
        NSFileManager	*fileManager;
        BOOL		result;
        NSString	*reason;
        
        fileManager = [NSFileManager defaultManager];

    // The code below is copied from Sarah Chambers' code
    
     // if Keyboard folder doesn't exist already...
    if (!([fileManager fileExistsAtPath: [LatexPanelPathKey stringByStandardizingPath]]))
    {
    
        // create the necessary directories
            NS_DURING
                // create ~/Library/TeXShop/Templates
                result = [fileManager createDirectoryAtPath:[LatexPanelPathKey stringByStandardizingPath] attributes:nil];
            NS_HANDLER
                result = NO;
                reason = [localException reason];
            NS_ENDHANDLER
                if (!result) {
                    NSRunAlertPanel(@"Error", reason, @"Couldn't Create Latex Panel Folder", nil, nil);
                    return;
                    }
    }
    
    // now see if autocompletion.plist is inside; if not, copy it from the program folder
    completionPath = [LatexPanelPathKey stringByStandardizingPath];
    completionPath = [completionPath stringByAppendingPathComponent:@"completion"];
    completionPath = [completionPath stringByAppendingPathExtension:@"plist"];
    if (! [fileManager fileExistsAtPath: completionPath]) {
        NS_DURING
            {
            result = NO;
            fileName = [[NSBundle mainBundle] pathForResource:@"completion" ofType:@"plist"];
            if (fileName) 
                result = [fileManager copyPath:fileName toPath:completionPath handler:nil];
            }
        NS_HANDLER
            result = NO;
            reason = [localException reason];
        NS_ENDHANDLER
            if (!result) {
                NSRunAlertPanel(@"Error", reason, @"Couldn't Create Latex Panel plist", nil, nil);
                return;
                }
        }
}

- (void)configureMatrixPanel
{
    NSString 	*fileName, *matrixPath;
    NSFileManager	*fileManager;
    BOOL		result;
    NSString	*reason;
    
    fileManager = [NSFileManager defaultManager];
    
    // The code below is copied from Sarah Chambers' code
    
    // if Keyboard folder doesn't exist already...
    if (!([fileManager fileExistsAtPath: [MatrixPanelPathKey stringByStandardizingPath]]))
    {
        
        // create the necessary directories
        NS_DURING
            // create ~/Library/TeXShop/Templates
            result = [fileManager createDirectoryAtPath:[MatrixPanelPathKey stringByStandardizingPath] attributes:nil];
        NS_HANDLER
            result = NO;
            reason = [localException reason];
        NS_ENDHANDLER
        if (!result) {
            NSRunAlertPanel(@"Error", reason, @"Couldn't Create Matrix Panel Folder", nil, nil);
            return;
        }
    }
    
    // now see if matrixpanel.plist is inside; if not, copy it from the program folder
    matrixPath = [MatrixPanelPathKey stringByStandardizingPath];
    matrixPath = [matrixPath stringByAppendingPathComponent:@"matrixpanel_1"];
    matrixPath = [matrixPath stringByAppendingPathExtension:@"plist"];
    if (! [fileManager fileExistsAtPath: matrixPath]) {
        NS_DURING
        {
            result = NO;
            fileName = [[NSBundle mainBundle] pathForResource:@"matrixpanel_1" ofType:@"plist"];
            if (fileName) 
                result = [fileManager copyPath:fileName toPath:matrixPath handler:nil];
        }
        NS_HANDLER
            result = NO;
            reason = [localException reason];
        NS_ENDHANDLER
        if (!result) {
            NSRunAlertPanel(@"Error", reason, @"Couldn't Create Matrix Panel plist", nil, nil);
            return;
        }
    }
}


- (void)configureMenuShortcutsFolder;
{
        NSString 	*fileName, *keyEquivalentsPath;
        NSFileManager	*fileManager;
        BOOL		result;
        NSString	*reason;
        
        fileManager = [NSFileManager defaultManager];

    // The code below is copied from Sarah Chambers' code
    
     // if Keyboard folder doesn't exist already...
    if (!([fileManager fileExistsAtPath: [MenuShortcutsPathKey stringByStandardizingPath]]))
    {
    
        // create the necessary directories
            NS_DURING
                // create ~/Library/TeXShop/Templates
                result = [fileManager createDirectoryAtPath:[MenuShortcutsPathKey stringByStandardizingPath] attributes:nil];
            NS_HANDLER
                result = NO;
                reason = [localException reason];
            NS_ENDHANDLER
                if (!result) {
                    NSRunAlertPanel(@"Error", reason, @"Couldn't Create Menu Folder", nil, nil);
                    return;
                    }
    }
    
    // now see if autocompletion.plist is inside; if not, copy it from the program folder
    keyEquivalentsPath = [MenuShortcutsPathKey stringByStandardizingPath];
    keyEquivalentsPath = [keyEquivalentsPath stringByAppendingPathComponent:@"KeyEquivalents"];
    keyEquivalentsPath = [keyEquivalentsPath stringByAppendingPathExtension:@"plist"];
   if (! [fileManager fileExistsAtPath: keyEquivalentsPath]) {
        NS_DURING
            {
            result = NO;
            fileName = [[NSBundle mainBundle] pathForResource:@"KeyEquivalents" ofType:@"plist"];
            if (fileName) 
                result = [fileManager copyPath:fileName toPath:keyEquivalentsPath handler:nil];
            }
        NS_HANDLER
            result = NO;
            reason = [localException reason];
        NS_ENDHANDLER
            if (!result) {
                NSRunAlertPanel(@"Error", reason, @"Couldn't Create KeyEquivalents plist", nil, nil);
                return;
                }
        }
}


- (void)configureMacro
{
        NSString 	*fileName, *macrosPath;
        NSFileManager	*fileManager;
        BOOL		result;
        NSString	*reason;
        
        fileManager = [NSFileManager defaultManager];

    // The code below is copied from Sarah Chambers' code
    
     // if Keyboard folder doesn't exist already...
    if (!([fileManager fileExistsAtPath: [MacrosPathKey stringByStandardizingPath]]))
    {
    
        // create the necessary directories
            NS_DURING
                // create ~/Library/TeXShop/Templates
                result = [fileManager createDirectoryAtPath:[MacrosPathKey stringByStandardizingPath] attributes:nil];
            NS_HANDLER
                result = NO;
                reason = [localException reason];
            NS_ENDHANDLER
                if (!result) {
                    NSRunAlertPanel(@"Error", reason, @"Couldn't Create Macros Folder", nil, nil);
                    return;
                    }
    }
    
    // now see if autocompletion.plist is inside; if not, copy it from the program folder
    macrosPath = [MacrosPathKey stringByStandardizingPath];
    macrosPath = [macrosPath stringByAppendingPathComponent:@"Macros_Latex"];
    macrosPath = [macrosPath stringByAppendingPathExtension:@"plist"];
    if (! [fileManager fileExistsAtPath: macrosPath]) {
        NS_DURING
            {
            result = NO;
            fileName = [[NSBundle mainBundle] pathForResource:@"Macros_Latex" ofType:@"plist"];
            if (fileName) 
                result = [fileManager copyPath:fileName toPath:macrosPath handler:nil];
            }
        NS_HANDLER
            result = NO;
            reason = [localException reason];
        NS_ENDHANDLER
            if (!result) {
                NSRunAlertPanel(@"Error", reason, @"Couldn't Create Macros_Latex plist", nil, nil);
                return;
                }
        }
    macrosPath = [MacrosPathKey stringByStandardizingPath];
    macrosPath = [macrosPath stringByAppendingPathComponent:@"Macros_Context"];
    macrosPath = [macrosPath stringByAppendingPathExtension:@"plist"];
    if (! [fileManager fileExistsAtPath: macrosPath]) {
        NS_DURING
            {
            result = NO;
            fileName = [[NSBundle mainBundle] pathForResource:@"Macros_Context" ofType:@"plist"];
            if (fileName) 
                result = [fileManager copyPath:fileName toPath:macrosPath handler:nil];
            }
        NS_HANDLER
            result = NO;
            reason = [localException reason];
        NS_ENDHANDLER
            if (!result) {
                NSRunAlertPanel(@"Error", reason, @"Couldn't Create Macros_Context plist", nil, nil);
                return;
                }
        }
}

// mitsu 1.29 (P) --this can be used universally, make sure to give full path to the file
- (void)prepareConfiguration: (NSString *)filePath
{
	NSString 	*completionPath, *folderPath, *fileName, *extension, *bundlePath, *reason;
	NSFileManager	*fileManager;
	BOOL		result;
        
	completionPath = [filePath stringByStandardizingPath];
	folderPath = [completionPath stringByDeletingLastPathComponent];
	fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
	extension = [filePath pathExtension];
	
	fileManager = [NSFileManager defaultManager];
    if (!([fileManager fileExistsAtPath: folderPath]))
    {
        // create the necessary directories
		NS_DURING
			result = [fileManager createDirectoryAtPath: folderPath attributes:nil];
		NS_HANDLER
			result = NO;
			reason = [localException reason];
		NS_ENDHANDLER
		if (!result) 
		{
			NSRunAlertPanel(@"Error", reason, 
				[NSString stringWithFormat: @"Couldn't Create folder:\n%@", folderPath], nil, nil);
			return;
		}
    }
    // now see if the file is inside; if not, copy it from the program folder
    if (! [fileManager fileExistsAtPath: completionPath]) 
	{
        NS_DURING
            result = NO;
			bundlePath = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
            if (bundlePath) 
                result = [fileManager copyPath:bundlePath toPath:completionPath handler:nil];
        NS_HANDLER
            result = NO;
            reason = [localException reason];
        NS_ENDHANDLER
		if (!result) 
		{
			NSRunAlertPanel(@"Error", reason, 
				[NSString stringWithFormat: @"Couldn't Create file:\n%@", filePath], nil, nil);
			return;
		}
	}
}
// end mitsu 1.29


// ------------ end of folder and file creation routines  ---------------------

    // Added by Greg Landweber to load the autocompletion dictionary
    // This code is modified from the code to load the LaTeX panel
- (void) finishAutoCompletionConfigure 
{
    NSString	*autocompletionPath;
    
    autocompletionPath = [AutoCompletionPathKey stringByStandardizingPath];
    autocompletionPath = [autocompletionPath stringByAppendingPathComponent:@"autocompletion"];
    autocompletionPath = [autocompletionPath stringByAppendingPathExtension:@"plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath: autocompletionPath]) 
	autocompletionDictionary=[NSDictionary dictionaryWithContentsOfFile:autocompletionPath];
    else
	autocompletionDictionary=[NSDictionary dictionaryWithContentsOfFile:
	 [[NSBundle mainBundle] pathForResource:@"autocompletion" ofType:@"plist"]];
    [autocompletionDictionary retain];
    // end of code added by Greg Landweber
}


// This is further menuKey configuration assuming folder already created
- (void)finishMenuKeyEquivalentsConfigure
{
    NSString		*shortcutsPath, *theChar;
    NSDictionary	*shortcutsDictionary, *menuDictionary;
    NSEnumerator	*mainMenuEnumerator, *menuItemsEnumerator, *subMenuItemsEnumerator;
    NSMenu		*mainMenu, *theMenu, *subMenu;
    NSMenuItem		*theMenuItem;
    id			key, key1, key2, object;
    unsigned int	mask;
    int			value;
    
     // The code below is copied from Sarah Chambers' code
    
    shortcutsPath = [MenuShortcutsPathKey stringByStandardizingPath];
    shortcutsPath = [shortcutsPath stringByAppendingPathComponent:@"KeyEquivalents"];
    shortcutsPath = [shortcutsPath stringByAppendingPathExtension:@"plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath: shortcutsPath]) 
        shortcutsDictionary=[NSDictionary dictionaryWithContentsOfFile:shortcutsPath];
    else
    	return;
    mainMenu = [NSApp mainMenu];
    mainMenuEnumerator = [shortcutsDictionary keyEnumerator];
    while ((key = [mainMenuEnumerator nextObject])) {
        menuDictionary = [shortcutsDictionary objectForKey: key];
        value = [key intValue];
        if (value == 0)
            theMenu = [[mainMenu itemWithTitle: key] submenu];
        else
            theMenu = [[mainMenu itemAtIndex: (value - 1)] submenu];
        
        if (theMenu && menuDictionary) {
            menuItemsEnumerator = [menuDictionary keyEnumerator];
            while ((key1 = [menuItemsEnumerator nextObject])) {
                value = [key1 intValue];
                if (value == 0)
                    theMenuItem = [theMenu itemWithTitle: key1];
                else
                    theMenuItem = [theMenu itemAtIndex: (value - 1)];
                object = [menuDictionary objectForKey: key1];
                if (([object isKindOfClass: [NSDictionary class]]) && ([theMenuItem hasSubmenu])) {
                    subMenu = [theMenuItem submenu];
                    subMenuItemsEnumerator = [object keyEnumerator];
                    while ((key2 = [subMenuItemsEnumerator nextObject])) {
                        value = [key2 intValue];
                        if (value == 0)
                            theMenuItem = [subMenu itemWithTitle: key2];
                        else
                            theMenuItem = [subMenu itemAtIndex: (value - 1)];
                        object = [object objectForKey: key2];
                        if ([object isKindOfClass: [NSArray class]])
                            {
                            theChar = [object objectAtIndex: 0];
                            mask = NSCommandKeyMask;
                            if ([[object objectAtIndex: 1] boolValue])
                                mask = (mask | NSAlternateKeyMask);
                            if ([[object objectAtIndex: 2] boolValue])
                                mask = (mask | NSControlKeyMask);
                            [theMenuItem setKeyEquivalent: theChar];
                            [theMenuItem setKeyEquivalentModifierMask: mask];
                            }
                        }
                    }
                else if ([object isKindOfClass: [NSArray class]]) 
                    { 
                    theChar = [object objectAtIndex: 0];
                    mask = (NSCommandKeyMask | NSFunctionKeyMask);
                    if ([[object objectAtIndex: 1] boolValue])
                        mask = (mask | NSAlternateKeyMask);
                    if ([[object objectAtIndex: 2] boolValue])
                  	mask = (mask | NSControlKeyMask);
                    [theMenuItem setKeyEquivalent: theChar];
                    [theMenuItem setKeyEquivalentModifierMask: mask];
                    }
                }
            }
        }

}

// mitsu 1.29 (P)
- (void) finishCommandCompletionConfigure 
{
    NSString            *completionPath;
    NSData              *myData;
    
	unichar esc = 0x001B; // configure the key in Preferences?
	if (!commandCompletionChar)
		commandCompletionChar = [[NSString stringWithCharacters: &esc length: 1] retain];
	
	if (commandCompletionList)
		[commandCompletionList release];
	commandCompletionList = nil;
	canRegisterCommandCompletion = NO;
    completionPath = [CommandCompletionPathKey stringByStandardizingPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath: completionPath]) 
		myData = [NSData dataWithContentsOfFile:completionPath];
    else
		myData = [NSData dataWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource:@"CommandCompletion" ofType:@"txt"]];
	if (!myData)
		return;
    
       int i = [[EncodingSupport sharedInstance] tagForEncoding:@"UTF-8 Unicode"];
       NSStringEncoding myEncoding = [[EncodingSupport sharedInstance] stringEncodingForTag: i];
       commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: myEncoding];
       if (! commandCompletionList) {
            i = [[EncodingSupport sharedInstance] tagForEncodingPreference];
            myEncoding = [[EncodingSupport sharedInstance] stringEncodingForTag: i];
            commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: myEncoding];
            }
		
	if (!commandCompletionList)
		return;
	[commandCompletionList insertString: @"\n" atIndex: 0];	
	if ([commandCompletionList characterAtIndex: [commandCompletionList length]-1] != '\n')
		[commandCompletionList appendString: @"\n"];
	canRegisterCommandCompletion = YES;
}
// end mitsu 1.29


- (void)configureExternalEditor
{
    NSString	*menuTitle;
    
    forPreview =  [SUD boolForKey:UseExternalEditorKey];
    if (forPreview)
        menuTitle = NSLocalizedString(@"Open for Editing...", @"Open for Editing...");
    else
        menuTitle = NSLocalizedString(@"Open for Preview...", @"Open for Preview...");
    [[[[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"File", @"File")] submenu] 
        itemWithTag:110] setTitle:menuTitle];
}

- (IBAction)openForPreview:(id)sender
{
    int				i;
    NSArray			*myArray, *fileArray;
    NSDocumentController	*myController;
    BOOL			externalEditor;
    NSOpenPanel			*myPanel;
    
    externalEditor = [SUD boolForKey:UseExternalEditorKey];
    myController = [NSDocumentController sharedDocumentController];
    myPanel = [NSOpenPanel openPanel];
    
    if (externalEditor)
        forPreview = NO;
    else
        forPreview = YES;
        
/* This code restricts files to tex files */
    myArray = [[NSArray alloc] initWithObjects:@"tex",
                                        @"TEX",
                                        @"txt",
                                        @"TXT",
                                        @"bib",
                                        @"mp",
                                        @"ins",
                                        @"dtx",
                                        @"mf",
					nil];
    i = [myController runModalOpenPanel: myPanel forTypes: myArray];
    fileArray = [myPanel filenames];
    if (fileArray) {
        for(i = 0; i < [fileArray count]; ++i) {
            NSString*  myName = [fileArray objectAtIndex:i];
            [myController openDocumentWithContentsOfFile: myName display: YES];
            }
        }

    if (externalEditor)
        forPreview = YES;
    else
        forPreview = NO;
}



- (BOOL)forPreview
{
    return forPreview;
}

- (IBAction)displayLatexPanel:(id)sender
{
    if ([[sender title] isEqualToString:NSLocalizedString(@"LaTeX Panel...", @"LaTeX Panel...")]) {
        [[Autrecontroller sharedInstance] showWindow:self];
        [sender setTitle:NSLocalizedString(@"Close LaTeX Panel", @"Close LaTeX Panel")];
        }
    else {
        [[Autrecontroller sharedInstance] hideWindow:self];
        [sender setTitle:NSLocalizedString(@"LaTeX Panel...", @"LaTeX Panel...")];
        }
}

// begin MatrixPanel Addition by Jonas 1.32 Nov 28 03
- (IBAction)displayMatrixPanel:(id)sender
{
    if ([[sender title] isEqualToString:NSLocalizedString(@"Matrix Panel...", @"Matrix Panel...")]) {
        [[Matrixcontroller sharedInstance] showWindow:self];
        [sender setTitle:NSLocalizedString(@"Close Matrix Panel", @"Close Matrix Panel")];
    }
    else {
        [[Matrixcontroller sharedInstance] hideWindow:self];
        [sender setTitle:NSLocalizedString(@"Matrix Panel...", @"Matrix Panel...")];
    }
}
// end MatrixPanel Addition by Jonas 1.32 Nov 28 03


- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
{
    id		documentWindow;
    
    if ([anItem action] == @selector(displayLatexPanel:)) {
        documentWindow = [[TSWindowManager sharedInstance] activeDocumentWindow];
        if (documentWindow == nil)
            return NO;
        else if ([documentWindow isKeyWindow])
            return YES;
        else
            return NO;
        }
     else if ([anItem action] == @selector(displayMatrixPanel:)) {
        documentWindow = [[TSWindowManager sharedInstance] activeDocumentWindow];
        if (documentWindow == nil)
            return NO;
        else if ([documentWindow isKeyWindow])
            return YES;
        else
            return NO;
    }
    else 
        return YES;
}

/*
- (void)showConfiguration:(id)sender
{
    NSString	*configFilePath;
    
    configFilePath = [[NSBundle mainBundle] pathForResource:@"Configuration" ofType:@"rtf"];
   [[NSWorkspace sharedWorkspace] openFile:configFilePath  withApplication:@"TextEdit"];
}

- (void)showMacrosHelp:(id)sender
{
    NSString	*configFilePath;
    
    configFilePath = [[NSBundle mainBundle] pathForResource:@"MacrosHelp" ofType:@"rtf"];
   [[NSWorkspace sharedWorkspace] openFile:configFilePath  withApplication:@"TextEdit"];
}
*/

- (void)dealloc
{
    [autocompletionDictionary release];
    [super dealloc];
}

/* I interprete comments from Anton Leuski as saying that this is not
necessary */
/*
- (void)dealloc
{
    [super dealloc];
}
*/

// mitsu 1.29 (P) 
- (void)openCommandCompletionList: (id)sender
{
	if ([[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:
			[CommandCompletionPathKey stringByStandardizingPath] display: YES] != nil)
		canRegisterCommandCompletion = NO;
}
// end mitsu 1.29

#ifdef MITSU_PDF
// mitsu 1.29 (O)
- (void)changeImageCopyType: (id)sender
{
	NSMenuItem *item;
	int imageCopyType = [SUD integerForKey:PdfCopyTypeKey]; // mitsu 1.29b
	
	if ([sender isKindOfClass: [NSMenuItem class]])
	{
		item = [[sender menu] itemWithTag: imageCopyType];
		if (item)
			[item setState: NSOffState];
		imageCopyType = [sender tag];
		item = [[sender menu] itemWithTag: imageCopyType];
		if (item)
			[item setState: NSOnState];
		// mitsu 1.29b
		NSPopUpButton *popup = [[TSPreferences sharedInstance] imageCopyTypePopup];
		if (popup)
		{
			int index = [popup indexOfItemWithTag: imageCopyType];
			if (index != -1)
				[popup selectItemAtIndex: index];
		}
		// end mitsu 1.29b
		// save this to User Defaults
		[SUD setInteger:imageCopyType forKey:PdfCopyTypeKey];
	}	
}
// end mitsu 1.29
#endif

- (void)ogreKitWillHackFindMenu:(OgreTextFinder*)textFinder;
{
    [textFinder setShouldHackFindMenu:[[NSUserDefaults standardUserDefaults] boolForKey:@"UseOgreKit"]];
}

// begin Update Checker Nov 05 04; Martin Kerz
- (IBAction)checkForUpdate:(id)sender
{
    NSString *currentVersion = [[[NSBundle bundleForClass:[self class]]
        infoDictionary] objectForKey:@"CFBundleVersion"];
		
	NSDictionary *texshopVersionDictionary = [NSDictionary dictionaryWithContentsOfURL:
        [NSURL URLWithString:@"http://www.uoregon.edu/~koch/texshop/texshop-current.txt"]];
		
	NSString *latestVersion = [texshopVersionDictionary valueForKey:@"TeXShop"];

    int button;
    if(latestVersion == nil){
        NSRunAlertPanel(NSLocalizedString(@"Error",
                                          @"Error"),
                        NSLocalizedString(@"There was an error checking for updates.",
                                          @"There was an error checking for updates."),
                                          @"OK", nil, nil);
        return;
    }

    if([latestVersion caseInsensitiveCompare: currentVersion] != NSOrderedDescending)
    {
        NSRunAlertPanel(NSLocalizedString(@"Your copy of TeXShop is up-to-date",
                                          @"Your copy of TeXShop is up-to-date"),
                        NSLocalizedString(@"You have the most recent version of TeXShop.",
                                          @"You have the most recent version of TeXShop."),
                                          @"OK", nil, nil);
    }
    else
    {
        button = NSRunAlertPanel(NSLocalizedString(@"New version available",
                                                       @"New version available"),
                                     [NSString stringWithFormat:
                                         NSLocalizedString(@"A new version of TeXShop is available (version %@). Would you like to download it now?",
                                                           @"A new version of TeXShop is available (version %@). Would you like to download it now?"), latestVersion],
                                     @"OK", @"Cancel", nil);
        if (button == NSOKButton) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.uoregon.edu/~koch/texshop/texshop.dmg"]];
        }
    }

}
// end update checker


@end
