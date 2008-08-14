/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2007 Richard Koch
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
 * $Id: TSPreferences.m 254 2007-06-03 21:09:25Z fingolfin $
 *
 * Created by dirk on Thu Dec 07 2000.
 *
 */

#import "UseMitsu.h"

#import "TSPreferences.h"
#import "TSWindowManager.h"
#import "TSEncodingSupport.h"
#import "globals.h"
#import "TSPreviewWindow.h"
#import "TSAppDelegate.h" // mitsu 1.29 (O)
#import "TSDocument.h"

//#import "MyPDFView.h" // mitsu 1.29 (O)


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
+ (id)sharedInstance
{
	if (_sharedInstance == nil)
	{
		_sharedInstance = [[TSPreferences alloc] init];
	}
	return _sharedInstance;
}

- (id)init
{
	if (_sharedInstance != nil) {
		[super dealloc];
		return _sharedInstance;
	}
	_sharedInstance = self;
	_undoManager = [[NSUndoManager alloc] init];
	// setup the default font here so it's defined when we run for the first time.
	_documentFont = [NSFont userFontOfSize:12.0];

	// register for changes in the user defaults
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];

	return self;
}

- (void)dealloc
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
- (IBAction)showPreferences:sender
{
	if (_prefsWindow == nil) {
		// we need to load the nib
		if ([NSBundle loadNibNamed:@"Preferences" owner:self] == NO) {
			NSRunAlertPanel(@"Error", @"Could not load Preferences.nib", @"shit happens", nil, nil);
		}

		// fill in all the values here since the window will be brought up for the first time
		/* koch: I moved this command two lines below, so it will ALWAYS be called
		when showing preferences: [self updateControlsFromUserDefaults:SUD]; */
	}

	[SUD synchronize];

	[self updateControlsFromUserDefaults:SUD];
	/* the next command causes windows to remember their font in case it is changed, and then
	the change is cancelled */
	[[NSNotificationCenter defaultCenter] postNotificationName:DocumentFontRememberNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:MagnificationRememberNotification object:self];
	fontTouched = NO;
	externalEditorTouched = NO;
	syntaxColorTouched = NO;
	oldSyntaxColor = [SUD boolForKey:SyntaxColoringEnabledKey];
	autoCompleteTouched = NO;
	bibDeskCompleteTouched = NO;
	oldAutoComplete = [SUD boolForKey:AutoCompleteEnabledKey];
	oldBibDeskComplete = [SUD boolForKey:BibDeskCompletionKey];
	magnificationTouched = NO;
	// added by mitsu --(G) TSEncodingSupport
	encodingTouched = NO;
	// end addition
	// prepare undo manager: forget all the old undo information and begin a new group.
	[_undoManager removeAllActions];
	[_undoManager beginUndoGrouping];

	[_prefsWindow makeKeyAndOrderFront:self];
}

//==============================================================================
// Entire panel
//==============================================================================
/*" This method is connected to the 'Set Defaults' menu


"*/

//-----------------------------------
- (void)undoDefaultPrefs:(NSDictionary *)oldDefaults;
//-----------------------------------
{
	[SUD setPersistentDomain:oldDefaults forName:@"TeXShop"];
	[SUD synchronize];
	[self updateControlsFromUserDefaults:SUD];
}


- (IBAction)setDefaults:sender
{

	NSString *fileName;
	NSDictionary *factoryDefaults, *oldDefaults;

	oldDefaults = [SUD dictionaryRepresentation];
	[_undoManager registerUndoWithTarget:self selector:@selector(undoDefaultPrefs:) object:oldDefaults];

	// register defaults
	switch ([sender tag]) {
		case 1: fileName = [[NSBundle mainBundle] pathForResource:@"FactoryDefaults" ofType:@"plist"]; break;
		case 2: fileName = [[NSBundle mainBundle] pathForResource:@"Defaults_pTeX_sjis" ofType:@"plist"]; break;
		case 3: fileName = [[NSBundle mainBundle] pathForResource:@"Defaults_pTeX_euc" ofType:@"plist"]; break;
			/*
			 case 2: fileName = [[NSBundle mainBundle] pathForResource:@"Defaults_pTeX_Inoue" ofType:@"plist"]; break;
			 case 3: fileName = [[NSBundle mainBundle] pathForResource:@"Defaults_pTeX_Kiriki" ofType:@"plist"]; break;
			 case 4: fileName = [[NSBundle mainBundle] pathForResource:@"Defaults_pTeX_Ogawa" ofType:@"plist"]; break;
				 */
		default: fileName = [[NSBundle mainBundle] pathForResource:@"FactoryDefaults" ofType:@"plist"]; break;
	}
	NSParameterAssert(fileName != nil);
	factoryDefaults = [[NSString stringWithContentsOfFile:fileName] propertyList];

	[SUD setPersistentDomain:factoryDefaults forName:@"TeXShop"];
	[SUD synchronize]; /* added by Koch Feb 19, 2001 to fix pref bug when no defaults present */

	// also register the default font. _documentFont was set in -init, dump it here to
	// the user defaults
	[SUD setObject:[NSArchiver archivedDataWithRootObject:_documentFont] forKey:DocumentFontKey];
	[SUD synchronize];

	[self updateControlsFromUserDefaults:SUD];
}


//==============================================================================
// Document pane
//==============================================================================
/*" This method is connected to the 'Set...' button on the 'Document' pane.

Clicking this button will bring up the font panel.
"*/
- (IBAction)changeDocumentFont:sender
{
	// become first responder so we will see the envents that NSFontManager sends
	// up the repsonder chain
	[_prefsWindow makeFirstResponder:_prefsWindow];
	[[NSFontManager sharedFontManager] setSelectedFont:_documentFont isMultiple:NO];
	[[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

/*" This method is sent down the responder chain by the font manager when changing fonts in the font panel. Since this class is delegate of the Window, we will receive this method and we can reflect the changes in the textField accordingly.
"*/
- (void)changeFont:(id)fontManager
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
- (IBAction)sourceWindowPosChanged:sender
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
- (IBAction)currentDocumentWindowPosDefault:sender
{
	NSWindow	*activeWindow;

	activeWindow = [[TSWindowManager sharedInstance] activeTextWindow];

	if (activeWindow != nil) {
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

/*" Set Find Panel"*/
- (IBAction)findPanelChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:UseOgreKitKey] forKey:UseOgreKitKey];

	if ([[sender selectedCell] tag] == 0)
		[SUD setBool:NO forKey:UseOgreKitKey];
	else
		[SUD setBool:YES forKey:UseOgreKitKey];
}


/*" Make Empty Document on Startup "*/
- (IBAction)emptyButtonPressed:sender
{
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:MakeEmptyDocumentKey] forKey:MakeEmptyDocumentKey];

	[SUD setBool:[sender state] forKey:MakeEmptyDocumentKey];
}

/*" Configure for External Editor "*/
- (IBAction)externalEditorButtonPressed:sender
{
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:UseExternalEditorKey] forKey:UseExternalEditorKey];

	[SUD setBool:[sender state] forKey:UseExternalEditorKey];
	 // post a notification so the system will learn about this change
	[[NSNotificationCenter defaultCenter] postNotificationName:ExternalEditorNotification object:self];
	externalEditorTouched = YES;
}


/*" Change Encoding "*/
- (IBAction)encodingChanged:sender
{
	NSString	*oldValue, *value;
	NSStringEncoding	theCode;

	oldValue = [SUD stringForKey:EncodingKey];
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD stringForKey:EncodingKey] forKey:EncodingKey];

	theCode = [[sender selectedCell] tag];
	value = [[TSEncodingSupport sharedInstance] keyForStringEncoding: theCode];
	[SUD setObject:value forKey:EncodingKey];

	// added by mitsu --(G) TSEncodingSupport
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EncodingChangedNotification" object:self];
	encodingTouched = YES;
	NSWindow	*activeWindow = [[TSWindowManager sharedInstance] activeTextWindow];

	if ((activeWindow != nil) && (! [value isEqualToString:oldValue]))
		NSBeginCriticalAlertSheet(nil, nil, nil, nil,
					_prefsWindow, self, nil, NULL, nil,
					NSLocalizedString(@"Currently open files retain their old encoding.", @"Currently open files retain their old encoding."));
// end addition

}

/*" Change tab size "*/
- (IBAction)tabsChanged:sender
{
	int		value;

	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD stringForKey:tabsKey] forKey:tabsKey];

	value = [_tabsTextField intValue];
	if (value < 2) {
		value = 2;
		[_tabsTextField setIntValue:2];
	} else if (value > 50) {
		value = 50;
		[_tabsTextField setIntValue:50];
	}

	[SUD setInteger:value forKey:tabsKey];
}




/*" This method is connected to the 'syntax coloring' checkbox.
"*/
- (IBAction)syntaxColorPressed:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:SyntaxColoringEnabledKey] forKey:SyntaxColoringEnabledKey];

	[SUD setBool:[[sender selectedCell] state] forKey:SyntaxColoringEnabledKey];
	syntaxColorTouched = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:DocumentSyntaxColorNotification object:self];
}

/*" This method is connected to the 'select on activate' checkbox.
"*/
- (IBAction)selectActivatePressed:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:AcceptFirstMouseKey] forKey:AcceptFirstMouseKey];

	[SUD setBool:[[sender selectedCell] state] forKey:AcceptFirstMouseKey];
}


/*" This method is connected to the 'parens matching' checkbox.
"*/
- (IBAction)parensMatchPressed:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:ParensMatchingEnabledKey] forKey:ParensMatchingEnabledKey];

	[SUD setBool:[[sender selectedCell] state] forKey:ParensMatchingEnabledKey];
}

/*" This method is connected to the 'spell checking' checkbox.
"*/
- (IBAction)spellCheckPressed:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:SpellCheckEnabledKey] forKey:SpellCheckEnabledKey];

	[SUD setBool:[[sender selectedCell] state] forKey:SpellCheckEnabledKey];
}

/*" This method is connected to the 'shell escape warning' checkbox.
"*/
- (IBAction)escapeWarningChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:WarnForShellEscapeKey] forKey:WarnForShellEscapeKey];

	[SUD setBool:[sender state] forKey:WarnForShellEscapeKey];
}


/*" This method is connected to the 'auto complete' checkbox.
"*/
- (IBAction)autoCompletePressed:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:AutoCompleteEnabledKey] forKey:AutoCompleteEnabledKey];

	[SUD setBool:[[sender selectedCell] state] forKey:AutoCompleteEnabledKey];
	autoCompleteTouched = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:DocumentAutoCompleteNotification object:self];

}

/*" This method is connected to the 'BibDesk Complete' checkbox.
"*/
- (IBAction)bibDeskCompletePressed:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:BibDeskCompletionKey] forKey:BibDeskCompletionKey];
	
	[SUD setBool:[[sender selectedCell] state] forKey:BibDeskCompletionKey];
	bibDeskCompleteTouched = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:DocumentBibDeskCompleteNotification object:self];

}





//==============================================================================
// Preview pane
//==============================================================================
/*" This method is connected to the "PDF Window Position" Matrix.

A tag of 0 means don't save the window position, a tag of 1 to save the setting. This should only flag the request to save the position, the actual saving of position and size can be left to [NSWindow setAutoSaveFrameName].
"*/
- (IBAction)pdfWindowPosChanged:sender
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
- (IBAction)currentPdfWindowPosDefault:sender
{
	NSWindow	*activeWindow;

	activeWindow = [[TSWindowManager sharedInstance] activePDFWindow];

	if (activeWindow != nil) {
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
- (IBAction)magChanged:sender
{
	// NSRunAlertPanel(@"warning", @"not yet implemented", nil, nil, nil);

	TSPreviewWindow	*activeWindow;
	double	mag, magnification;

	activeWindow = (TSPreviewWindow *)[[TSWindowManager sharedInstance] activePDFWindow];

	// The comment below fixes a bug; magnification didn't take if no pdf window open
	//   if (activeWindow != nil)

	{
		[[_undoManager prepareWithInvocationTarget:SUD] setFloat:[SUD floatForKey:PdfMagnificationKey] 				forKey:PdfMagnificationKey];
		mag = [_magTextField doubleValue];
		if (mag < 20.0) {
			mag = 20;
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



/*" This method is connected to the 'scroll' checkbox.
"*/
- (IBAction)scrollPressed:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:NoScrollEnabledKey] forKey:NoScrollEnabledKey];

	[SUD setBool:[sender state] forKey:NoScrollEnabledKey];
}

- (IBAction)autoPDFChanged:sender
{
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:PdfRefreshKey] forKey:PdfRefreshKey];
	[SUD setBool:[sender state] forKey:PdfRefreshKey];
}

#ifdef MITSU_PDF

// mitsu 1.29 (O)
/*" This method is connected to page style popup button. "*/
- (IBAction)pageStyleChanged:sender
{
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD integerForKey:PdfPageStyleKey] forKey:PdfPageStyleKey];

	[SUD setInteger:[[sender selectedCell] tag] forKey:PdfPageStyleKey];
}

/*" This method is connect to the 'first double page' radio buttons.
"*/
- (IBAction)firstDoublePageChanged:sender
{
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD integerForKey:PdfFirstPageStyleKey] forKey:PdfFirstPageStyleKey];

	[SUD setInteger:[[sender selectedCell] tag] forKey:PdfFirstPageStyleKey];
}





/*" This method is connected to resize option popup button. "*/
- (IBAction)resizeOptionChanged:sender
{
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD integerForKey:PdfKitFitSizeKey] forKey:PdfKitFitSizeKey];

	[SUD setInteger:[[sender selectedCell] tag] forKey:PdfKitFitSizeKey];
}


/*" This method is connected to image copy type popup button. "*/
- (IBAction)imageCopyTypeChanged:sender
{
	// mitsu 1.29b
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD
integerForKey:PdfCopyTypeKey] forKey:PdfCopyTypeKey];
	// uncheck menu item Preview=>Copy Format
	NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
						NSLocalizedString(@"Preview", @"Preview")] submenu];

	NSMenu *formatMenu = [[previewMenu itemWithTitle:
						NSLocalizedString(@"Copy Format", @"Copy Format")] submenu];
	id <NSMenuItem> item = [formatMenu itemWithTag: [SUD integerForKey:PdfCopyTypeKey]];
	if (item)
		[[_undoManager prepareWithInvocationTarget:[NSApp delegate]] changeImageCopyType: item];

	item = [formatMenu itemWithTag: [[sender selectedCell] tag]];
	if (item)
		[[NSApp delegate] changeImageCopyType: item];
	// end mitsu 1.29b
}

// mitsu 1.29b
- (NSPopUpButton *)imageCopyTypePopup
{
	return _imageCopyTypePopup;
}
// end mitsu 1.29b


/*" This method is connected to default mouse mode popup button. "*/
- (IBAction)mouseModeChanged:sender
{
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD integerForKey:PdfKitMouseModeKey] forKey:PdfKitMouseModeKey];

	[SUD setInteger:[[sender selectedCell] tag] forKey:PdfKitMouseModeKey];
}

/*" This method is connected to default mouse mode popup button. "*/
- (IBAction)colorMapChanged:sender
{
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD integerForKey:PdfColorMapKey] forKey:PdfColorMapKey];

	[SUD setBool:([sender state]==NSOnState) forKey:PdfColorMapKey];
}

/*" This method is connected to default mouse mode popup button. "*/
- (IBAction)copyForeColorChanged:sender
{
	[[_undoManager prepareWithInvocationTarget:SUD] setFloat:[SUD floatForKey:PdfFore_RKey] forKey:PdfFore_RKey];
	[[_undoManager prepareWithInvocationTarget:SUD] setFloat:[SUD floatForKey:PdfFore_GKey] forKey:PdfFore_GKey];
	[[_undoManager prepareWithInvocationTarget:SUD] setFloat:[SUD floatForKey:PdfFore_BKey] forKey:PdfFore_BKey];
	[[_undoManager prepareWithInvocationTarget:SUD] setFloat:[SUD floatForKey:PdfFore_AKey] forKey:PdfFore_AKey];

	NSColor *aColor = [[sender color] colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	[SUD setFloat:[aColor redComponent] forKey:PdfFore_RKey];
	[SUD setFloat:[aColor greenComponent] forKey:PdfFore_GKey];
	[SUD setFloat:[aColor blueComponent] forKey:PdfFore_BKey];
	[SUD setFloat:[aColor alphaComponent] forKey:PdfFore_AKey];
}

/*" This method is connected to default mouse mode popup button. "*/
- (IBAction)copyBackColorChanged:sender
{
	[[_undoManager prepareWithInvocationTarget:SUD] setFloat:[SUD floatForKey:PdfBack_RKey] forKey:PdfBack_RKey];
	[[_undoManager prepareWithInvocationTarget:SUD] setFloat:[SUD floatForKey:PdfBack_GKey] forKey:PdfBack_GKey];
	[[_undoManager prepareWithInvocationTarget:SUD] setFloat:[SUD floatForKey:PdfBack_BKey] forKey:PdfBack_BKey];
	[[_undoManager prepareWithInvocationTarget:SUD] setFloat:[SUD floatForKey:PdfBack_AKey] forKey:PdfBack_AKey];

	NSColor *aColor = [[sender color] colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	[SUD setFloat:[aColor redComponent] forKey:PdfBack_RKey];
	[SUD setFloat:[aColor greenComponent] forKey:PdfBack_GKey];
	[SUD setFloat:[aColor blueComponent] forKey:PdfBack_BKey];
	[SUD setFloat:[aColor alphaComponent] forKey:PdfBack_AKey];
}

- (IBAction)colorParam1Changed:sender
{
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD integerForKey:PdfColorParam1Key] forKey:PdfColorParam1Key];

	[SUD setInteger:[[sender selectedCell] tag] forKey:PdfColorParam1Key];
}

// end mitsu 1.29
#endif


//==============================================================================
/*" This method is connected to the textField that holds the tetex bin path.
"*/
- (IBAction)tetexBinPathChanged:sender
{
	// register the undo messages first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD objectForKey:TetexBinPath] 				forKey:TetexBinPath];

	[SUD setObject:[_tetexBinPathField stringValue] forKey:TetexBinPath];
}

//==============================================================================
/*" This method is connected to the textField that holds the gs bin path.
"*/
- (IBAction)gsBinPathChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD objectForKey:GSBinPath] 				forKey:GSBinPath];

	[SUD setObject:[_gsBinPathField stringValue] forKey:GSBinPath];
}

//==============================================================================
// TeX pane
//==============================================================================
/*" This method is connected to the textField that holds the TeX command. It is located on the TeX pane.
"*/
- (IBAction)texProgramChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD objectForKey:TexCommandKey] forKey:TexCommandKey];

	[SUD setObject:[_texCommandTextField stringValue] forKey:TexCommandKey];
}

/*" This method is connected to the textField that holds the LaTeX command. It is located on the TeX pane.
"*/
- (IBAction)latexProgramChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD objectForKey:LatexCommandKey] forKey:LatexCommandKey];

	[SUD setObject:[_latexCommandTextField stringValue] forKey:LatexCommandKey];
}

/*" This method is connected to the textField that holds the tex + ghostscript command. It is located on the TeX pane.
"*/
- (IBAction)texGSProgramChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD objectForKey:TexGSCommandKey] forKey:TexGSCommandKey];

	[SUD setObject:[_texGSCommandTextField stringValue] forKey:TexGSCommandKey];
}

/*" This method is connected to the textField that holds the latextex + ghostscript command. It is located on the TeX pane.
"*/
- (IBAction)latexGSProgramChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD objectForKey:LatexGSCommandKey] forKey:LatexGSCommandKey];

	[SUD setObject:[_latexGSCommandTextField stringValue] forKey:LatexGSCommandKey];
}

/*" This method is connected to the 'save postscript' checkbox.
"*/
- (IBAction)savePSPressed:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:SavePSEnabledKey] forKey:SavePSEnabledKey];

	[SUD setBool:[sender state] forKey:SavePSEnabledKey];
}




/*" This method is connected to the textField that holds the tex script command. It is located on the TeX pane.
"*/
- (IBAction)texScriptProgramChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD objectForKey:TexScriptCommandKey] forKey:TexScriptCommandKey];

	[SUD setObject:[_texScriptCommandTextField stringValue] forKey:TexScriptCommandKey];
}

/*" This method is connected to the textField that holds the latex script command. It is located on the TeX pane.
"*/
- (IBAction)latexScriptProgramChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD objectForKey:LatexScriptCommandKey] forKey:LatexScriptCommandKey];

	[SUD setObject:[_latexScriptCommandTextField stringValue] forKey:LatexScriptCommandKey];
}



/*" This method is connected to the "Default Program" matrix on the TeX pane.

A tag of 0 means use TeX, a tag of 1 means use LaTeX.
"*/
- (IBAction)defaultProgramChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD integerForKey:DefaultCommandKey] forKey:DefaultCommandKey];

	// since the default program values map identically to the tags of the NSButtonCells,
	// we can use the tag directly here.
	[SUD setInteger:[[sender selectedCell] tag] forKey:DefaultCommandKey];
	if ([[sender selectedCell] tag] == 3) {
		[_engineTextField setEnabled: YES];
		[_engineTextField setEditable: YES];
		[_engineTextField setSelectable: YES];
		[_engineTextField selectText:self];
	}
	else
		[_engineTextField setEnabled: NO];
}

- (IBAction)setEngine:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setObject:[SUD stringForKey:DefaultEngineKey] forKey:DefaultEngineKey];

	// since the default program values map identically to the tags of the NSButtonCells,
	// we can use the tag directly here.
	[SUD setObject:[sender stringValue] forKey:DefaultEngineKey];
}

/*" This method is connected to the "Default Script" matrix on the TeX pane.

A tag of 100 means use pdftex, a tag of 101 means use tex + ghostscript, a tag of 102 means use
person script. See also: DefaultTypesetMode.

"*/
- (IBAction)defaultScriptChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD boolForKey:DefaultScriptKey] forKey:DefaultScriptKey];

	// since the default program values map identically to the tags of the NSButtonCells,
	// we can use the tag directly here.
	[SUD setInteger:[[sender selectedCell] tag] forKey:DefaultScriptKey];
}

- (IBAction)syncChanged: sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD integerForKey:SyncMethodKey] forKey:SyncMethodKey];

	// since the default program values map identically to the tags of the NSButtonCells,
	// we can use the tag directly here.
	[SUD setInteger:[[sender selectedCell] tag] forKey:SyncMethodKey];
}

- (IBAction)defaultMetaPostChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD integerForKey:MetaPostCommandKey] forKey:MetaPostCommandKey];

	[SUD setInteger:[[sender selectedCell] tag] forKey:MetaPostCommandKey];
}

- (IBAction)defaultBibtexChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD integerForKey:BibtexCommandKey] forKey:BibtexCommandKey];

	[SUD setInteger:[[sender selectedCell] tag] forKey:BibtexCommandKey];
}

- (IBAction)distillerChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD integerForKey:DistillerCommandKey] forKey:DistillerCommandKey];

	[SUD setInteger:[[sender selectedCell] tag] forKey:DistillerCommandKey];
}

// zenitani 1.35 (C)
- (IBAction)ptexUtfOutputPressed:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:[SUD boolForKey:ptexUtfOutputEnabledKey] forKey:ptexUtfOutputEnabledKey];

	[SUD setBool:[sender state] forKey:ptexUtfOutputEnabledKey];

	// zenitani 2.10 (A) UTF-8 + utf.sty situation
	[[TSEncodingSupport sharedInstance] setupForEncoding];
}



/*" This method is connected to the "Console" matrix on the TeX pane.

A tag of 0 means "always", a tag of 1 means "when errors occur".
"*/
- (IBAction)consoleBehaviorChanged:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD boolForKey:ConsoleBehaviorKey] forKey:ConsoleBehaviorKey];

	// since the default program values map identically to the tags of the NSButtonCells,
	// we can use the tag directly here.
	[SUD setInteger:[[sender selectedCell] tag] forKey:ConsoleBehaviorKey];
}

/*" This method is connected to the "After Typesetting" matrix on the Preference pane.
A tag of 0 means "Activate Preview"; a tag of 1 means "Continue Editing".
"*/
- (IBAction)afterTypesettingChanged:sender;
{
	BOOL	oldValue, newValue;
	int		tagValue;
	
	oldValue = [SUD boolForKey:BringPdfFrontOnTypesetKey];
	tagValue = [[sender selectedCell] tag];
	if (tagValue == 0)
		newValue = YES;
	else
		newValue = NO;
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setBool:oldValue forKey:BringPdfFrontOnTypesetKey];

	[SUD setBool:newValue forKey:BringPdfFrontOnTypesetKey];
}

/*" This method is connected to the "Console" matrix on the TeX pane.

A tag of 0 means "always", a tag of 1 means "when errors occur".
"*/
- (IBAction)saveRelatedButtonPressed:sender
{
	// register the undo message first
	[[_undoManager prepareWithInvocationTarget:SUD] setInteger:[SUD boolForKey:SaveRelatedKey] forKey:SaveRelatedKey];

	// since the default program values map identically to the tags of the NSButtonCells,
	// we can use the tag directly here.
	[SUD setBool:[sender state] forKey:SaveRelatedKey];
}


//==============================================================================
// other target/action methods
//==============================================================================
/*" This method is connected to the OK button.
"*/
- (IBAction)okButtonPressed:sender
{
	// save everything to the user defaults


 /* WARNING: the next seven commands were added by koch on March 17.
		They are needed because the TextBox fields do not send a command
		until the return key is pressed. But pressing the return key also
		closes preferences. Users will instead modify the text and then
		click elsewhere to modify other preferences, only to discover that
		these preferences weren't changed. A user sent email asking how to
		activate pdfelatex in the old TeXShop, so I tried it on
		the new program and couldn't! */
// See mitsu change below instead
//        [self tabsChanged: self];
//        [self texProgramChanged: self];
//        [self latexProgramChanged: self];
//        [self texGSProgramChanged: self];
//        [self latexGSProgramChanged: self];
//        [self texScriptProgramChanged: self];
//        [self latexScriptProgramChanged: self];

// added by mitsu --(M) Path Settings on "okButtonPressed:" in TSPreferences
// This is a simpler way to reflect changes in the controls
	[_prefsWindow makeFirstResponder: _prefsWindow];
// end addition

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
	/* koch: undo font changes */
	if (externalEditorTouched)
		[[NSNotificationCenter defaultCenter] postNotificationName:ExternalEditorNotification object:self];
	if (fontTouched)
		[[NSNotificationCenter defaultCenter] postNotificationName:DocumentFontRevertNotification object:self];
	if (magnificationTouched)
		[[NSNotificationCenter defaultCenter] postNotificationName:MagnificationRevertNotification object:self];
	/* below we must reset a preference because it will not be undone in time */
	if (syntaxColorTouched) {
		[SUD setBool:oldSyntaxColor forKey:SyntaxColoringEnabledKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:DocumentSyntaxColorNotification object:self];
	}
	if (autoCompleteTouched) {
		[SUD setBool:oldAutoComplete forKey:AutoCompleteEnabledKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:DocumentAutoCompleteNotification object:self];
	}
	if (bibDeskCompleteTouched) {
		[SUD setBool:oldBibDeskComplete forKey:BibDeskCompletionKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:DocumentBibDeskCompleteNotification object:self];
	}
	// added by mitsu --(G) TSEncodingSupport
	if (encodingTouched) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"EncodingChangedNotification" object: self ];
	}
	// end addition

	// The user defaults have changed. Force update of the user interface.
	/* koch: The code below doesn't take because the undo manager doesn't actually
		undo here. It calls undo during the next event loop. So the code below is called too soon.
		I called it again when the preference panel is shown. */
	//    [self updateControlsFromUserDefaults:SUD];
}

//==============================================================================
// notification methods
//==============================================================================
/*" This method will be called whenever the user defaults change. We simply update the state of the prefences window and all of its controls. This may sound like the "brute force" method (in fact it is) but since the UserDefaults aren't likely to change from outside of this class we'll ignore that for now.
"*/
- (void)userDefaultsChanged:(NSNotification *)notification
{
	// only update the window's controls when the window is not visible.
	// If the window is visible the user edits it directly with the mouse.
	if ([_prefsWindow isVisible] == NO) {
		[self updateControlsFromUserDefaults:[notification object]];
	}
}

//==============================================================================
// API used by other TeXShop classes
//==============================================================================

/*" This method returns a relative path name of 'path', based on fromFile: file. If the second argument 'file' is nil, it will return an absolute path of 'path'. Added by zenitani, Feb 13, 2003. "*/
- (NSString *)relativePath: (NSString *)path fromFile: (NSString *)file
{
	NSArray *a, *b;
	NSString *rpath = @"", *astr, *bstr;

	a = [[ file stringByDeletingLastPathComponent ] pathComponents ];
	b = [ path pathComponents ];
	unsigned ai = [a count], bi = [b count], i, j;
	if( ai == 0 ) return path;
	for( i=0; ((i<ai)&&(i<bi)); i++ ){
		astr = [a objectAtIndex: i];
		bstr = [b objectAtIndex: i];
		if( [astr compare: bstr] != NSOrderedSame )  break;
	}
//    NSLog( @"%d %d %d", ai, bi, i );
	for( j=0; j<(ai-i); j++ ){
		rpath = [rpath stringByAppendingString: @"../"];
//        NSLog( @"%@\n", rpath );
	}
	for( j=i; j<bi-1; j++ ){
		rpath = [rpath stringByAppendingFormat: @"%@/", [b objectAtIndex: j]];
//        NSLog( @"%@\n", rpath );
	}
	rpath = [rpath stringByAppendingFormat: @"%@", [b objectAtIndex: (bi-1)]];
	return rpath;
}


/*" This method will be called when no defaults were registered so far. Since this is the first time that TeXShop runs, we register a standard defaults set (from the FactoryDefaults.plist) and fill ~/Library/TeXShop/Templates with our templates.
"*/
- (void)registerFactoryDefaults
{
	NSString *fileName;
	NSDictionary *factoryDefaults;

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
}

//==============================================================================
// helpers
//==============================================================================

/*"  %{This method is not to be called from outside of this class.}

This method retrieves the application preferences from the defaults object and sets the controls in the window accordingly.
"*/
- (void)updateControlsFromUserDefaults:(NSUserDefaults *)defaults
{
	NSData	*fontData;
	double	magnification;
	int		mag, tabSize;
	int		myTag;
	BOOL	myBool;
	NSNumber    *myNumber;

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
	[_selectActivateButton setState:[defaults boolForKey:AcceptFirstMouseKey]];
	[_parensMatchButton setState:[defaults boolForKey:ParensMatchingEnabledKey]];
	[_escapeWarningButton setState:[defaults boolForKey:WarnForShellEscapeKey]];
	[_spellCheckButton setState:[defaults boolForKey:SpellCheckEnabledKey]];
	[_autoCompleteButton setState:[defaults boolForKey:AutoCompleteEnabledKey]];
	[_bibDeskCompleteButton setState:[defaults boolForKey:BibDeskCompletionKey]];
	[_autoPDFButton setState:[defaults boolForKey:PdfRefreshKey]];
	[_openEmptyButton setState:[defaults boolForKey:MakeEmptyDocumentKey]];
	[_externalEditorButton setState:[defaults boolForKey:UseExternalEditorKey]];
	[_ptexUtfOutputButton setState:[defaults boolForKey:ptexUtfOutputEnabledKey]]; // zenitani 1.35 (C)


	// Create the contents of the encoding menu on the fly & select the active encoding
	[_defaultEncodeMatrix removeAllItems];
	[[TSEncodingSupport sharedInstance] addEncodingsToMenu:[_defaultEncodeMatrix menu] withTarget:0 action:0];
	[_defaultEncodeMatrix selectItemWithTag: [[TSEncodingSupport sharedInstance] defaultEncoding]];

	if ([defaults boolForKey:UseOgreKitKey] == NO)
		[_findMatrix selectCellWithTag:0];
	else
		[_findMatrix selectCellWithTag:1];
	[_savePSButton setState:[defaults boolForKey:SavePSEnabledKey]];
	[_scrollButton setState:[defaults boolForKey:NoScrollEnabledKey]];

	[_pdfWindowPosMatrix selectCellWithTag:[defaults integerForKey:PdfWindowPosModeKey]];
	/* koch: */
	if ([defaults integerForKey:PdfWindowPosModeKey] == 0)
		[_pdfWindowPosButton setEnabled: YES];
	else
		[_pdfWindowPosButton setEnabled: NO];

	magnification = [defaults floatForKey:PdfMagnificationKey];
	mag = round(magnification * 100.0);
	myNumber = [NSNumber numberWithInt: mag];
	[_magTextField setStringValue:[myNumber stringValue]];
	//      [_magTextField setIntValue: mag];


#ifdef MITSU_PDF

	myTag = [defaults integerForKey:PdfFirstPageStyleKey];
	if (!myTag) myTag = PDF_FIRST_RIGHT;
	[_firstPageMatrix selectCellWithTag:myTag];

	// mitsu 1.29 (O)
	int itemIndex;
	myTag = [defaults integerForKey:PdfPageStyleKey];
	if (!myTag) myTag = PDF_SINGLE_PAGE_STYLE; // default PdfPageStyleKey
	itemIndex = [_pageStylePopup indexOfItemWithTag: myTag];
	if (itemIndex == -1) itemIndex = 2; // default PdfPageStyleKey
	[_pageStylePopup selectItemAtIndex: itemIndex];

	myTag = [defaults integerForKey:PdfKitFitSizeKey];
	if (!myTag) myTag = NEW_PDF_FIT_TO_WINDOW; // default PdfKitFitSizeKey
	itemIndex = [_resizeOptionPopup indexOfItemWithTag: myTag];
	if (itemIndex == -1) itemIndex = 2; // default PdfKitFitSizeKey
	[_resizeOptionPopup selectItemAtIndex: itemIndex];

	myTag = [defaults integerForKey:PdfCopyTypeKey];
	if (!myTag) myTag = IMAGE_TYPE_JPEG_MEDIUM; // default PdfCopyTypeKey
	itemIndex = [_imageCopyTypePopup indexOfItemWithTag: myTag];
	if (itemIndex == -1) itemIndex = 1; // default PdfCopyTypeKey
	[_imageCopyTypePopup selectItemAtIndex: itemIndex];

	myTag = [defaults integerForKey:PdfKitMouseModeKey];
	if (!myTag) myTag = NEW_MOUSE_MODE_SELECT_TEXT; // default PdfKitMouseModeKey
	itemIndex = [_mouseModePopup indexOfItemWithTag: myTag];
	if (itemIndex == -1) itemIndex = 1; // default PdfKitMouseModeKey
	[_mouseModePopup selectItemAtIndex: itemIndex];

	[_colorMapButton setState: [SUD boolForKey:PdfColorMapKey]?NSOnState:NSOffState];
	NSColor *aColor;
	if ([SUD stringForKey:PdfFore_RKey]) {
		aColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:PdfFore_RKey]
										   green: [SUD floatForKey:PdfFore_GKey] blue: [SUD floatForKey:PdfFore_BKey]
										   alpha: [SUD floatForKey:PdfFore_AKey]];
	}
	else
		aColor = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1];
	[_copyForeColorWell setColor: aColor];
	[_copyForeColorWell setContinuous: YES];

	if ([SUD stringForKey:PdfBack_RKey]) {
		aColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:PdfBack_RKey]
										   green: [SUD floatForKey:PdfBack_GKey] blue: [SUD floatForKey:PdfBack_BKey]
										   alpha: [SUD floatForKey:PdfBack_AKey]];
	}
	else
		aColor = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1];
	[_copyBackColorWell setColor: aColor];
	[_copyBackColorWell setContinuous: YES];

	myTag = [defaults integerForKey:PdfColorParam1Key];
	itemIndex = [_colorParam1Popup indexOfItemWithTag: myTag];
	if (itemIndex == -1) itemIndex = 2; // default idx = 2
	[_colorParam1Popup selectItemAtIndex: itemIndex];

	myTag = [defaults integerForKey:MetaPostCommandKey];
	[_defaultMetaPostMatrix selectCellWithTag: myTag];

	myTag = [defaults integerForKey:BibtexCommandKey];
	[_defaultBibtexMatrix selectCellWithTag: myTag];

	myTag = [defaults integerForKey:DistillerCommandKey];
	[_distillerMatrix selectCellWithTag: myTag];
	
	myBool = [defaults boolForKey:BringPdfFrontOnTypesetKey];
	if (myBool == YES)
		myTag = 0;
	else
		myTag = 1;
	[_afterTypesettingMatrix selectCellWithTag: myTag];
	


	// end mitsu 1.29
#endif

	tabSize = [defaults integerForKey: tabsKey];
	myNumber = [NSNumber numberWithInt: tabSize];
	[_tabsTextField setStringValue:[myNumber stringValue]];
	// [_tabsTextField setIntValue: tabSize];

	[_texCommandTextField setStringValue:[defaults stringForKey:TexCommandKey]];
	[_latexCommandTextField setStringValue:[defaults stringForKey:LatexCommandKey]];
	[_texGSCommandTextField setStringValue:[defaults stringForKey:TexGSCommandKey]];
	[_latexGSCommandTextField setStringValue:[defaults stringForKey:LatexGSCommandKey]];
	[_tetexBinPathField setStringValue:[defaults stringForKey:TetexBinPath]];
	[_gsBinPathField setStringValue:[defaults stringForKey:GSBinPath]];

	[_texScriptCommandTextField setStringValue:[defaults stringForKey:TexScriptCommandKey]];
	[_latexScriptCommandTextField setStringValue:[defaults stringForKey:LatexScriptCommandKey]];

	[_defaultCommandMatrix selectCellWithTag:[defaults integerForKey:DefaultCommandKey]];
	[_engineTextField setStringValue:[defaults stringForKey:DefaultEngineKey]];
	if ([defaults integerForKey:DefaultCommandKey] == 3) {
		[_engineTextField setEnabled: YES];
		[_engineTextField setEditable: YES];
		[_engineTextField setSelectable: YES];
		[_engineTextField selectText:self];
	}
	else
		[_engineTextField setEnabled: NO];

	if ([defaults integerForKey:DefaultCommandKey] == 3)
		[_engineTextField setEditable: YES];
	[_defaultScriptMatrix selectCellWithTag:[defaults integerForKey:DefaultScriptKey]];
	[_syncMatrix selectCellWithTag:[defaults integerForKey:SyncMethodKey]];
	[_consoleMatrix selectCellWithTag:[defaults integerForKey:ConsoleBehaviorKey]];
	[_saveRelatedButton setState:[defaults boolForKey:SaveRelatedKey]];
}

/*" %{This method is not to be called from outside of this class}

This method updates the textField that represents the name of the selected font in the Document pane.
"*/
- (void)updateDocumentFontTextField
{
	NSString *fontDescription;

	fontDescription = [NSString stringWithFormat:@"%@ - %2.0f", [_documentFont displayName], [_documentFont pointSize]];
	[_documentFontTextField setStringValue:fontDescription];
}

/*" %{This method is not to be called from outside of this class.} "*/


@end
