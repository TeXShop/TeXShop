//
//  Preferences.m
//  TeXShop
//
//  Created by dirk on Thu Dec 07 2000.
//

#import "Preferences.h"
#import "globals.h"

#define SUD [NSUserDefaults standardUserDefaults]

@implementation Preferences
/*"
Format of the original prefs file:

_{#position #value}
_{0 version number}
_{1 textView's font}
_{2 pdfView's slider value}
_{3-6 textWindow's frame}
_{7-10 pdfWindow's frame}
_{11 TeX command}
_{12 LaTeX command}
_{13 display method (Apple or GS)}
_{14 GS color}
_{15 preferred TeX command} 
"*/

static id _sharedInstance = nil;

/*" This class is implemented as singleton, i.e. there is only one single instance in the runtime. This is the designated accessor method to get the shared instance of the Preferences class.
"*/
+ (id)sharedInstance
{
	if (_sharedInstance == nil)
	{
		_sharedInstance = [[Preferences alloc] init];
	}
	return _sharedInstance;
}

- (id)init 
{
    if (_sharedInstance != nil) 
	{
        [super dealloc];
        return _sharedInstance;
    }
	_sharedInstance = self;
	_undoManager = [[NSUndoManager alloc] init];
	
	// register for changes in the user defaults
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsChanged:)     name:NSUserDefaultsDidChangeNotification object:nil];
	
	return self;
}

- (void)dealloc
{
	[_undoManager release];
	[super dealloc];
}

//------------------------------------------------------------------------------
// target/action methods
//------------------------------------------------------------------------------
/*" Connected to the "Preferences..." menu item in Application's main menu. 

Loads the .nib file if necessary, fills all the controls with the values from the user defaults and makes the window visible.
"*/
- (IBAction)showPreferences:sender
{
	if (_prefsWindow == nil)
	{		
		// we need to load the nib
		if ([NSBundle loadNibNamed:@"Preferences" owner:self] == NO)
		{
			NSRunAlertPanel(@"Error", @"Could not load Preferences.nib", @"shit happens", nil, nil);
		}

		// is this the first time we run TeXShop? Then we have to register some
		// factoy defaults
		if ([SUD stringForKey:TexCommandKey] == nil)
		{
			[self registerFactoryDefaults];
		}
		
		// fill in all the values here since the window will be brought up for the first time
		[self updateControlsFromUserDefaults:SUD];
	}
	
	// prepare undo manager: forget all the old undo information and begin a new group.
	[_undoManager removeAllActions];
	[_undoManager beginUndoGrouping];
	
	[_prefsWindow makeKeyAndOrderFront:self];
}

/*" This method is connected to the "Font for Source" Matrix.

A tag of 0 means don't change the font, a tag of 1 means save the font.
"*/
- (IBAction)fontForSourceChanged:sender
{
	// register the undo message, then change the value
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:SaveDocumentFontKey] forKey:SaveDocumentFontKey];
	
	// (BOOL)YES == 1 and (BOOL)NO == 0
	// this means that we can use the tag of the selected cell directly as boolean value	
	[SUD setBool:[[sender selectedCell] tag] forKey:SaveDocumentFontKey];
}

/*" This method is connected to the "PDF Magnification" Matrix.

A tag of 0 means don't change the magnification, a tag of 1 to save the setting.
"*/
- (IBAction)pdfMagnificationChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:SavePdfMagKey] forKey:SavePdfMagKey];
	
	// (BOOL)YES == 1 and (BOOL)NO == 0
	// this means that we can use the tag of the selected cell directly as boolean value
	[SUD setBool:[[sender selectedCell] tag] forKey:SavePdfMagKey];
}

/*" This method is connected to the "Source Window Position" Matrix.

A tag of 0 means don't save the window position, a tag of 1 to save the setting. This should only flag the request to save the position, the actual saving of position and size can be left to [NSWindow setAutoSaveFrameName].
"*/
- (IBAction)sourceWindowPosChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:SaveDocumentWindowPosKey] forKey:SaveDocumentWindowPosKey];

	// (BOOL)YES == 1 and (BOOL)NO == 0
	// this means that we can use the tag of the selected cell directly as boolean value
	[SUD setBool:[[sender selectedCell] tag] forKey:SaveDocumentWindowPosKey];
}

/*" This method is connected to the "PDF Window Position" Matrix.

A tag of 0 means don't save the window position, a tag of 1 to save the setting. This should only flag the request to save the position, the actual saving of position and size can be left to [NSWindow setAutoSaveFrameName].
"*/
- (IBAction)pdfWindowPosChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:SavePdfWindowPosKey] forKey:SavePdfWindowPosKey];

	// (BOOL)YES == 1 and (BOOL)NO == 0
	// this means that we can use the tag of the selected cell directly as boolean value
	[SUD setBool:[[sender selectedCell] tag] forKey:SavePdfWindowPosKey];
}

/*" This method is connected to the textField that holds the TeX command.
"*/
- (IBAction)texProgramChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD objectForKey:TexCommandKey] forKey:TexCommandKey];

	[SUD setObject:[_texCommandTextField stringValue] forKey:TexCommandKey];
}

/*" This method is connected to the textField that holds the LaTeX command.
"*/
- (IBAction)latexProgramChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD objectForKey:LatexCommandKey] forKey:LatexCommandKey];

	[SUD setObject:[_latexCommandTextField stringValue] forKey:LatexCommandKey];
}

/*" This method is connected to the "Default Program" Matrix.

A tag of 0 means use TeX, a tag of 1 means use LaTeX.
"*/
- (IBAction)defaultProgramChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD boolForKey:DefaultCommandKey] forKey:DefaultCommandKey];

	// since the default program values map identically to the tags of the NSButtonCells,
	// we can use the tag directly here.
	[SUD setInteger:[[sender selectedCell] tag] forKey:DefaultCommandKey];
}

/*" This method is connected to the "PDF Display" Matrix.

A tag of 0 means use Apple's NSPDFImageRep, a tag of 1 means use Ghostscript.
"*/
- (IBAction)pdfDisplayChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD boolForKey:PdfDisplayMethodKey] forKey:PdfDisplayMethodKey];

	// since the default program values map identically to the tags of the NSButtonCells,
	// we can use the tag directly here.
	[SUD setInteger:[[sender selectedCell] tag] forKey:PdfDisplayMethodKey];
}

/*" This method is connected to the "Ghostscript Colors" Matrix.

_{#tag #meaning}
_{0 Grayscale}
_{1 256 Colors}
_{2 Thousands of Colors}
"*/
- (IBAction)ghostscriptColorChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD boolForKey:GsColorModeKey] forKey:GsColorModeKey];

	// since the default program values map identically to the tags of the NSButtonCells,
	// we can use the tag directly here.
	[SUD setInteger:[[sender selectedCell] tag] forKey:GsColorModeKey];
}

/*" This method is connected to the OK button. 
"*/
- (IBAction)okButtonPressed:sender
{
	// save everything to the user defaults
	[SUD synchronize];
	
	// close the window
	[_prefsWindow performClose:self];
}

/*" This method is connected to the Cancel button. 
"*/
- (IBAction)cancelButtonPressed:sender
{
	// undo everyting
	[_undoManager endUndoGrouping];
	[_undoManager undo];
	
	// close the window
	[_prefsWindow performClose:self];
}

//------------------------------------------------------------------------------
// notification methods
//------------------------------------------------------------------------------
/*" This method will be called whenever the user defaults change. We simply update the state of the prefences window and all of its controls.
"*/
- (void)userDefaultsChanged:(NSNotification *)notification
{
	// only update the window's controls when the window is not visible. 
	// If the window is visible the user edits it directly with the mouse.
	if ([_prefsWindow isVisible] == NO)
	{
		[self updateControlsFromUserDefaults:[notification object]];
	}
}

//------------------------------------------------------------------------------
// API used by other TeXShop classes
//------------------------------------------------------------------------------
/*" This method looks in ~/Library/TeXShop/Templates and returns the filenames minus the extensions of all of the templates found.
"*/
- (NSArray *)allTemplateNames
{
	NSString		*templatePath;
	NSEnumerator	*templateEnum;
	NSMutableArray	*returnArray;
	
	returnArray = [NSMutableArray array];
	
	templatePath = [TexTemplatePathKey stringByStandardizingPath];
	templateEnum = [[NSFileManager defaultManager] enumeratorAtPath:templatePath];
	while (templatePath = [templateEnum nextObject])
	{ 
		if ([[[templatePath pathExtension] lowercaseString] isEqualToString: @"tex"]) 
		{
			NSString	*title;
			
			title = [[templatePath lastPathComponent] stringByDeletingPathExtension];
			[returnArray addObject:title];
		}
	}
	return returnArray;
}

//------------------------------------------------------------------------------
// helpers
//------------------------------------------------------------------------------
/*"  %{This method is not to be called from outside of this class.}

This method retrieves the application preferences from the defaults object and sets the controls in the window accordingly.
"*/
- (void)updateControlsFromUserDefaults:(NSUserDefaults *)defaults
{
	[_fontChangeMatrix selectCellWithTag:[defaults boolForKey:SaveDocumentFontKey]];
	[_pdfMagMatrix selectCellWithTag:[defaults boolForKey:SavePdfMagKey]];
	[_sourceWindowPosMatrix selectCellWithTag:[defaults boolForKey:SaveDocumentWindowPosKey]];
	[_pdfWindowPosMatrix selectCellWithTag:[defaults boolForKey:SavePdfWindowPosKey]];
	[_texCommandTextField setStringValue:[defaults stringForKey:TexCommandKey]];
	[_latexCommandTextField setStringValue:[defaults stringForKey:LatexCommandKey]];
	[_defaultCommandMatrix selectCellWithTag:[defaults integerForKey:DefaultCommandKey]];
	[_pdfDisplayMatrix selectCellWithTag:[defaults integerForKey:PdfDisplayMethodKey]];
	[_gsColorMatrix selectCellWithTag:[defaults integerForKey:GsColorModeKey]];
}

/*" %{This method is not to be called from outside of this class.}

This method will be called when no defaults were registered so far. Since this is the first time that TeXShop runs, we register a standard defaults set (from the FactorDefaults.plist) and fill ~/Library/TeXShop/Templates with our templates.
"*/
- (void)registerFactoryDefaults
{
	NSString *fileName;
	NSDictionary *factoryDefaults;
	NSArray *templates;
	NSEnumerator *templateEnum;
			
	// register defaults
	fileName = [[NSBundle mainBundle] pathForResource:@"FactoryDefaults" ofType:@"plist"];
	NSParameterAssert(fileName != nil);
	factoryDefaults = [[NSString stringWithContentsOfFile:fileName] propertyList];
	[SUD setPersistentDomain:factoryDefaults forName:@"TeXShop"];
	[SUD synchronize];
	
	// create the necessary directories
	NS_DURING
		// create ~/Library/TeXShop
		[self createDirectoryAtPath:[TexTemplatePathKey stringByDeletingLastPathComponent]];
		// create ~/Library/TeXShop/Templates
		[self createDirectoryAtPath:TexTemplatePathKey];
	NS_HANDLER
	{
		NSRunAlertPanel(@"Error", [localException reason], @"shit happens", nil, nil);
		return;
	}
	NS_ENDHANDLER
	// fill in our templates
	templates = [NSBundle pathsForResourcesOfType:@"tex" inDirectory:[[NSBundle mainBundle] resourcePath]];
	templateEnum = [templates objectEnumerator];
	while (fileName = [templateEnum nextObject])
	{
		[self copyToTemplateDirectory:fileName];
	}
}
	
/*" %{This method is not to be called from outside of this class.}

Creates the directory at %path making sure that %path does not already exist (which is no problem) and if it exists it is a directory (throws an exception if not).
"*/ 
- (void)createDirectoryAtPath:(NSString *)path
{
	NSFileManager *fileManager;
	BOOL directoryExists, isDirectory;
	
	fileManager = [NSFileManager defaultManager];
	path = [path stringByStandardizingPath];
	directoryExists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
	if (directoryExists == NO)
	{
		// create the dir
		if ([fileManager createDirectoryAtPath:path attributes:nil] == NO)
		{
			[NSException raise:XDirectoryCreation format:@"could not create directory '%@'!", path];
		}
	}
	else if (isDirectory == NO)
	{
		[NSException raise:XDirectoryCreation format:@"'%@' already exists and is NO directory!", path];
	}
}

/*" %{This method is not to be called from outside of this class.}

Copies %fileName to ~/Library/TeXShop/Templates. This method takes care that no files are overwritten.
"*/
- (void)copyToTemplateDirectory:(NSString *)fileName
{
	NSFileManager *fileManager;
	NSString *destFileName;
	
	fileManager = [NSFileManager defaultManager];
	destFileName = [NSString pathWithComponents:[NSArray arrayWithObjects:[TexTemplatePathKey stringByStandardizingPath], [fileName lastPathComponent], nil]];
	
	// check if that file already exists
	if ([fileManager fileExistsAtPath:destFileName isDirectory:NULL] == NO)
	{
		// file doesn't exist -> copy it
		if ([fileManager copyPath:fileName toPath:destFileName handler:nil] == NO)
		{
			NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"cound not copy '%@' to '%@'", fileName, destFileName], @"shit happens", nil, nil, nil);
		}
	}
}

- (IBAction)testTextField:sender
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

@end
