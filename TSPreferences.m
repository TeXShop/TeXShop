//
//  Preferences.m
//  TeXShop
//
//  Created by dirk on Thu Dec 07 2000.
//

#import "TSPreferences.h"
#import "TSWindowManager.h"
#import "globals.h"
#import "extras.h"
#import "MyWindow.h"
#import "MyView.h"
#import "MyDocument.h"

#define SUD [NSUserDefaults standardUserDefaults]

@implementation TSPreferences
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
//------------------------------------------------------------------------------
+ (id)sharedInstance
//------------------------------------------------------------------------------
{
	if (_sharedInstance == nil)
	{
		_sharedInstance = [[TSPreferences alloc] init];
	}
	return _sharedInstance;
}

//------------------------------------------------------------------------------
- (id)init 
//------------------------------------------------------------------------------
{
    if (_sharedInstance != nil) 
	{
        [super dealloc];
        return _sharedInstance;
    }
	_sharedInstance = self;
	_undoManager = [[NSUndoManager alloc] init];
    // setup the default font here so it's defined when we run for the first time.
    _documentFont = [NSFont userFontOfSize:12.0];
	
	// register for changes in the user defaults
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsChanged:)     name:NSUserDefaultsDidChangeNotification object:nil];
	
	return self;
}

//------------------------------------------------------------------------------
- (void)dealloc
//------------------------------------------------------------------------------
{
	[_undoManager release];
	[super dealloc];
}

//==============================================================================
// target/action methods
//==============================================================================
/*" Connected to the "Preferences..." menu item in Application's main menu. 

Loads the .nib file if necessary, fills all the controls with the values from the user defaults and makes the window visible.
"*/
//------------------------------------------------------------------------------
- (IBAction)showPreferences:sender
//------------------------------------------------------------------------------
{
	if (_prefsWindow == nil)
	{		
		// we need to load the nib
		if ([NSBundle loadNibNamed:@"Preferences" owner:self] == NO)
		{
			NSRunAlertPanel(@"Error", @"Could not load Preferences.nib", @"shit happens", nil, nil);
		}

		// fill in all the values here since the window will be brought up for the first time
		/* koch: I moved this command two lines below, so it will ALWAYS be called
                    when showing preferences: [self updateControlsFromUserDefaults:SUD]; */
	}
	
        [self updateControlsFromUserDefaults:SUD];
        /* the next command causes windows to remember their font in case it is changed, and then
        the change is cancelled */
        [[NSNotificationCenter defaultCenter] postNotificationName:DocumentFontRememberNotification object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:MagnificationRememberNotification object:self];
        fontTouched = NO; 
        syntaxColorTouched = NO;
        magnificationTouched = NO;
        oldSyntaxColor = [SUD boolForKey:SyntaxColoringEnabledKey];
	// prepare undo manager: forget all the old undo information and begin a new group.
	[_undoManager removeAllActions];
	[_undoManager beginUndoGrouping];
	
	[_prefsWindow makeKeyAndOrderFront:self];
}

//==============================================================================
// Document pane
//==============================================================================
/*" This method is connected to the 'Set...' button on the 'Document' pane.

Clicking this button will bring up the font panel.
"*/ 
//------------------------------------------------------------------------------
- (IBAction)changeDocumentFont:sender;
//------------------------------------------------------------------------------
{
    // become first responder so we will see the envents that NSFontManager sends
    // up the repsonder chain
    [_prefsWindow makeFirstResponder:_prefsWindow];
    [[NSFontManager sharedFontManager] setSelectedFont:_documentFont isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

/*" This method is sent down the responder chain by the font manager when changing fonts in the font panel. Since this class is delegate of the Window, we will receive this method and we can reflect the changes in the textField accordingly.
"*/
//------------------------------------------------------------------------------
- (void)changeFont:(id)fontManager
//------------------------------------------------------------------------------
{
    NSData	*fontData;
        
    _documentFont = [fontManager convertFont:_documentFont];
    fontTouched = YES;

	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD objectForKey:DocumentFontKey] forKey:DocumentFontKey];

    [self updateDocumentFontTextField];
    
    // update the userDefaults
    fontData = [NSArchiver archivedDataWithRootObject:_documentFont];
    [SUD setObject:fontData forKey:DocumentFontKey];
    [SUD setBool:YES forKey:SaveDocumentFontKey];
    
    // post a notification so all open documents can change their font
    [[NSNotificationCenter defaultCenter] postNotificationName:DocumentFontChangedNotification object:self];
}

/*" This method is connected to the "Source Window Position" Matrix.

This method will be called when the matrix changes. Target 0 means 'all windows start at a fixed position', target 1 means 'remember window position'.
"*/
//------------------------------------------------------------------------------
- (IBAction)sourceWindowPosChanged:sender
//------------------------------------------------------------------------------
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD integerForKey:DocumentWindowPosModeKey] forKey:DocumentWindowPosModeKey];

	[SUD setInteger:[[sender selectedCell] tag] forKey:DocumentWindowPosModeKey];
         if ([[sender selectedCell] tag] == 0)
            [_docWindowPosButton setEnabled: YES];
        else
            [_docWindowPosButton setEnabled: NO];
}

/*" This method is connected to the 'use current pos as default' button on the 'Document' pane.
"*/
//------------------------------------------------------------------------------
- (IBAction)currentDocumentWindowPosDefault:sender;
//------------------------------------------------------------------------------
{
    NSWindow	*activeWindow;
    
    activeWindow = [[TSWindowManager sharedInstance] activeDocumentWindow];

    if (activeWindow != nil)
    {
        [[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD stringForKey:DocumentWindowFixedPosKey] forKey:DocumentWindowFixedPosKey];
        [SUD setObject:[activeWindow stringWithSavedFrame] forKey:DocumentWindowFixedPosKey];
    
        // just in case: the radio button must be checked as well.
        /* koch: the code below is harmless but probably unnecessary since the button can only
            be pressed if the radio button is in the fixed position mode */
        [[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD integerForKey:DocumentWindowPosModeKey] forKey:DocumentWindowPosModeKey];
        [SUD setInteger:DocumentWindowPosFixed forKey:DocumentWindowPosModeKey];
        [_sourceWindowPosMatrix selectCellWithTag:DocumentWindowPosFixed];
    }
}

/*" This method is connected to the 'syntax coloring' checkbox. 
"*/
//------------------------------------------------------------------------------
- (IBAction)syntaxColorPressed:sender;
//------------------------------------------------------------------------------
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:SyntaxColoringEnabledKey] forKey:SyntaxColoringEnabledKey];

    [SUD setBool:[sender state] forKey:SyntaxColoringEnabledKey];
    syntaxColorTouched = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:DocumentSyntaxColorNotification object:self];
}

/*" This method is connected to the 'parens matching' checkbox.
"*/
//------------------------------------------------------------------------------
- (IBAction)parensMatchPressed:sender;
//------------------------------------------------------------------------------
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:ParensMatchingEnabledKey] forKey:ParensMatchingEnabledKey];

    [SUD setBool:[sender state] forKey:ParensMatchingEnabledKey];
}

//==============================================================================
// Preview pane
//==============================================================================
/*" This method is connected to the "PDF Window Position" Matrix.

A tag of 0 means don't save the window position, a tag of 1 to save the setting. This should only flag the request to save the position, the actual saving of position and size can be left to [NSWindow setAutoSaveFrameName].
"*/
//------------------------------------------------------------------------------
- (IBAction)pdfWindowPosChanged:sender
//------------------------------------------------------------------------------
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:PdfWindowPosModeKey] forKey:PdfWindowPosModeKey];

	[SUD setInteger:[[sender selectedCell] tag] forKey:PdfWindowPosModeKey];
        /* koch: button enabled only if appropriate */
        if ([[sender selectedCell] tag] == 0)
            [_pdfWindowPosButton setEnabled: YES];
        else
            [_pdfWindowPosButton setEnabled: NO];

}

/*" This method is connected to the 'use current pos as default' button.
"*/
//------------------------------------------------------------------------------
- (IBAction)currentPdfWindowPosDefault:sender;
//------------------------------------------------------------------------------
{
    NSWindow	*activeWindow;
    
    activeWindow = [[TSWindowManager sharedInstance] activePdfWindow];

    if (activeWindow != nil)
    {
        [[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD stringForKey:PdfWindowFixedPosKey] forKey:PdfWindowFixedPosKey];
        [SUD setObject:[activeWindow stringWithSavedFrame] forKey:PdfWindowFixedPosKey];
    
        // just in case: the radio button must be checked as well.
        [[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD integerForKey:PdfWindowPosModeKey] forKey:PdfWindowPosModeKey];
        [SUD setInteger:DocumentWindowPosFixed forKey:PdfWindowPosModeKey];
        [_sourceWindowPosMatrix selectCellWithTag:PdfWindowPosFixed];
    }
}

/*" This method is connected to the magnification text field on the Preview pane'.
"*/
//------------------------------------------------------------------------------
- (IBAction)magChanged:sender;
//------------------------------------------------------------------------------
{
    // NSRunAlertPanel(@"warning", @"not yet implemented", nil, nil, nil);

    MyWindow	*activeWindow;
    double	mag, magnification;
    
    activeWindow = (MyWindow *)[[TSWindowManager sharedInstance] activePdfWindow];

    if (activeWindow != nil)
    {
        [[_undoManager prepareWithInvocationTarget:SUD] setFloat:[SUD floatForKey:PdfMagnificationKey] 				forKey:PdfMagnificationKey];
        mag = [_magTextField doubleValue];
        if (mag < 25.0) {
            mag = 25;
            [_magTextField setDoubleValue:mag];
            [_magTextField display];
            }
        else if (mag > 400.0) {
            mag = 400;
            [_magTextField setDoubleValue:mag];
            [_magTextField display];
            }
        magnification = mag / 100.0; 
        [SUD setFloat:magnification forKey:PdfMagnificationKey];
        magnificationTouched = YES;
        // post a notification so all open documents can change their magnification
        [[NSNotificationCenter defaultCenter] postNotificationName:MagnificationChangedNotification object:self];

    }

}

//==============================================================================
// TeX pane
//==============================================================================
/*" This method is connected to the textField that holds the TeX command. It is located on the TeX pane.
"*/
//------------------------------------------------------------------------------
- (IBAction)texProgramChanged:sender
//------------------------------------------------------------------------------
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD objectForKey:TexCommandKey] forKey:TexCommandKey];

	[SUD setObject:[_texCommandTextField stringValue] forKey:TexCommandKey];
}

/*" This method is connected to the textField that holds the LaTeX command. It is located on the TeX pane.
"*/
//------------------------------------------------------------------------------
- (IBAction)latexProgramChanged:sender
//------------------------------------------------------------------------------
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD objectForKey:LatexCommandKey] forKey:LatexCommandKey];

	[SUD setObject:[_latexCommandTextField stringValue] forKey:LatexCommandKey];
}

/*" This method is connected to the "Default Program" matrix on the TeX pane.

A tag of 0 means use TeX, a tag of 1 means use LaTeX.
"*/
//------------------------------------------------------------------------------
- (IBAction)defaultProgramChanged:sender
//------------------------------------------------------------------------------
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD boolForKey:DefaultCommandKey] forKey:DefaultCommandKey];

	// since the default program values map identically to the tags of the NSButtonCells,
	// we can use the tag directly here.
	[SUD setInteger:[[sender selectedCell] tag] forKey:DefaultCommandKey];
}

//==============================================================================
// other target/action methods
//==============================================================================
/*" This method is connected to the OK button. 
"*/
//------------------------------------------------------------------------------
- (IBAction)okButtonPressed:sender
//------------------------------------------------------------------------------
{
	// save everything to the user defaults
        
        /* WARNING: the next two commands were added by koch on March 17.
        They are needed because the TextBox fields do not send a command
        until the return key is pressed. But pressing the return key also
        closes preferences. Users will instead modify the text and then
        click elsewhere to modify other preferences, only to discover that
        these preferences weren't changed. A user sent email asking how to
        activate pdfelatex in the old TeXShop, so I tried it on
        the new program and couldn't! */
        
        [self texProgramChanged: self];
        [self latexProgramChanged: self];
	[SUD synchronize];	
	// close the window
	[_prefsWindow performClose:self];
}

/*" This method is connected to the Cancel button. 
"*/
//------------------------------------------------------------------------------
- (IBAction)cancelButtonPressed:sender
//------------------------------------------------------------------------------
{
	// undo everyting
	[_undoManager endUndoGrouping];
	[_undoManager undo];
	
	// close the window
	[_prefsWindow performClose:self];
        /* koch: undo font changes */
        if (fontTouched)
         [[NSNotificationCenter defaultCenter] postNotificationName:DocumentFontRevertNotification object:self];
        if (magnificationTouched)
         [[NSNotificationCenter defaultCenter] postNotificationName:MagnificationRevertNotification object:self];
        /* below we must reset a preference because it will not be undone in time */
        if (syntaxColorTouched) {
            [SUD setBool:oldSyntaxColor forKey:SyntaxColoringEnabledKey];
            [[NSNotificationCenter defaultCenter] postNotificationName:DocumentSyntaxColorNotification object:self];
            }
    // The user defaults have changed. Force update of the user interface.
    /* koch: The code below doesn't take because the undo manager doesn't actually
    undo here. It calls undo during the next event loop. So the code below is called too soon.
    I called it again when the preference panel is shown. */
    [self updateControlsFromUserDefaults:SUD];
}

//==============================================================================
// notification methods
//==============================================================================
/*" This method will be called whenever the user defaults change. We simply update the state of the prefences window and all of its controls. This may sound like the "brute force" method (in fact it is) but since the UserDefaults aren't likely to change from outside of this class we'll ignore that for now.
"*/
//------------------------------------------------------------------------------
- (void)userDefaultsChanged:(NSNotification *)notification
//------------------------------------------------------------------------------
{
	// only update the window's controls when the window is not visible. 
	// If the window is visible the user edits it directly with the mouse.
	if ([_prefsWindow isVisible] == NO)
	{
		[self updateControlsFromUserDefaults:[notification object]];
	}
}

//==============================================================================
// API used by other TeXShop classes
//==============================================================================
/*" This method looks in ~/Library/TeXShop/Templates and returns the filenames minus the extensions of all of the templates found.
"*/
//------------------------------------------------------------------------------
- (NSArray *)allTemplateNames
//------------------------------------------------------------------------------
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

/*" This method will be called when no defaults were registered so far. Since this is the first time that TeXShop runs, we register a standard defaults set (from the FactoryDefaults.plist) and fill ~/Library/TeXShop/Templates with our templates.
"*/
//------------------------------------------------------------------------------
- (void)registerFactoryDefaults
//------------------------------------------------------------------------------
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
	[SUD synchronize]; /* added by Koch Feb 19, 2001 to fix pref bug when no defaults present */

    // also register the default font. _documentFont was set in -init, dump it here to
    // the user defaults
    [SUD setObject:[NSArchiver archivedDataWithRootObject:_documentFont] forKey:DocumentFontKey];
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

//==============================================================================
// helpers
//==============================================================================
/*"  %{This method is not to be called from outside of this class.}

This method retrieves the application preferences from the defaults object and sets the controls in the window accordingly.
"*/
//------------------------------------------------------------------------------
- (void)updateControlsFromUserDefaults:(NSUserDefaults *)defaults
//------------------------------------------------------------------------------
{
    NSData	*fontData;
    double	magnification;
    int		mag;
	
	fontData = [defaults objectForKey:DocumentFontKey];
	if (fontData != nil)
	{
		_documentFont = [NSUnarchiver unarchiveObjectWithData:fontData];
	}
    [self updateDocumentFontTextField];
    
	[_sourceWindowPosMatrix selectCellWithTag:[defaults integerForKey:DocumentWindowPosModeKey]];
        /* koch: */
        if ([defaults integerForKey:DocumentWindowPosModeKey] == 0)
            [_docWindowPosButton setEnabled: YES];
        else
            [_docWindowPosButton setEnabled: NO];
    [_syntaxColorButton setState:[defaults boolForKey:SyntaxColoringEnabledKey]];
    [_parensMatchButton setState:[defaults boolForKey:ParensMatchingEnabledKey]];
    
	[_pdfWindowPosMatrix selectCellWithTag:[defaults integerForKey:PdfWindowPosModeKey]];
        /* koch: */
         if ([defaults integerForKey:PdfWindowPosModeKey] == 0)
            [_pdfWindowPosButton setEnabled: YES];
        else
            [_pdfWindowPosButton setEnabled: NO];
            
        magnification = [defaults floatForKey:PdfMagnificationKey];
        mag = magnification * 100.0;
        [_magTextField setIntValue: mag];

	[_texCommandTextField setStringValue:[defaults stringForKey:TexCommandKey]];
	[_latexCommandTextField setStringValue:[defaults stringForKey:LatexCommandKey]];
	[_defaultCommandMatrix selectCellWithTag:[defaults integerForKey:DefaultCommandKey]];
}

/*" %{This method is not to be called from outside of this class}

This method updates the textField that represents the name of the selected font in the Document pane.
"*/
//------------------------------------------------------------------------------
- (void)updateDocumentFontTextField
//------------------------------------------------------------------------------
{
    NSString *fontDescription;
    
    fontDescription = [NSString stringWithFormat:@"%@ - %2.0f", [_documentFont displayName], [_documentFont pointSize]];
    [_documentFontTextField setStringValue:fontDescription];
}
	
/*" %{This method is not to be called from outside of this class.}

Creates the directory at %path making sure that %path does not already exist (which is no problem) and if it exists it is a directory (throws an exception if not).
"*/ 
//------------------------------------------------------------------------------
- (void)createDirectoryAtPath:(NSString *)path
//------------------------------------------------------------------------------
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
//------------------------------------------------------------------------------
- (void)copyToTemplateDirectory:(NSString *)fileName
//------------------------------------------------------------------------------
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

@end
