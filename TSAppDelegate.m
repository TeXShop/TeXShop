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

- (void)setForPreview: (BOOL)value;
{
    forPreview = value;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    NSString *fileName;
    NSMutableString *path;
    NSDictionary *factoryDefaults;
    
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

// Set up ~/Library/TeXShop; must come before dealing with EncodingSupport and MacoMenuController below    
    [self configureTemplates]; // this call must come first because it creates the TeXShop folder if it does not yet exist
    [self configureMenuShortcutsFolder];
    [self configureAutoCompletion];
    [self configureLatexPanel];
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

// ------------- these routines create ~/Library/TeXShop and folders and files if necessary ----------

- (void)configureTemplates
{
    	NSArray 	*templates;
	NSEnumerator 	*templateEnum;
        NSString 	*fileName;
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
            templates = [NSBundle pathsForResourcesOfType:@"tex" inDirectory:[[NSBundle mainBundle] resourcePath]];
            templateEnum = [templates objectEnumerator];
            while (fileName = [templateEnum nextObject])
            {
                    [self copyToTemplateDirectory:fileName ];
            }
        }


// end of changes

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
    NSString	*completionPath;
	NSData *myData;
    
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
	//commandCompletionList = [[[NSString alloc] initWithData:myData 
	//							encoding: NSUTF8StringEncoding] autorelease];
    if([[SUD stringForKey:EncodingKey] isEqualToString:@"MacOSRoman"])
        commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: NSMacOSRomanStringEncoding];
	else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"IsoLatin"])
        commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: NSISOLatin1StringEncoding];
    else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"IsoLatin2"])
        commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: NSISOLatin2StringEncoding];
	else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"])
        commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacJapanese)];
    else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"DOSJapanese"])
        commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese)];
	else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"EUC_JP"])
        commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_JP)];
	else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"JISJapanese"])
        commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP)];
    else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacKorean"])
        commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacKorean)];
    else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"UTF-8 Unicode"])
        commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: NSUTF8StringEncoding];
    else if ([[SUD stringForKey:EncodingKey] isEqualToString:@"Standard Unicode"])
        commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: NSUnicodeStringEncoding];
    else
        commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: NSMacOSRomanStringEncoding];
		
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


@end
