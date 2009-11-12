/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2005 Richard Koch
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
 * $Id: TSPreferences.h 133 2006-05-21 11:52:24Z fingolfin $
 *
 * Created by dirk on Thu Dec 07 2000.
 *
 */

#import "UseMitsu.h"

#import <AppKit/AppKit.h>

@interface TSPreferences : NSObject
{
	IBOutlet NSWindow	*_prefsWindow;			/*" connected to the window "*/
	IBOutlet NSTextField	*_documentFontTextField;	/*" connected to "Document Font" "*/
	IBOutlet NSTextField	*_consoleFontTextField;     /*" connected to "Console Font" */
	IBOutlet NSMatrix	*_sourceWindowPosMatrix;	/*" connected to "Source Window Position" "*/
	IBOutlet NSButton	*_docWindowPosButton;		/* connected to set current position button */
	IBOutlet NSMatrix       *_findMatrix;                   /* connected to Find Panel */

	IBOutlet NSButtonCell	*_syntaxColorButton;		/*" connected to "Syntax Coloring" "*/
	IBOutlet NSButtonCell   *_selectActivateButton;         /*" connected to "Select on Activate" "*/
	IBOutlet NSButtonCell	*_parensMatchButton;		/*" connected to "Parens Matching "*/
	IBOutlet NSButtonCell	*_spellCheckButton;		/*" connected to "SpellChecking "*/
	IBOutlet NSButtonCell	*_autoCompleteButton;		/*" connected to "Auto Completion "*/
	IBOutlet NSButtonCell	*_bibDeskCompleteButton;	/*" connected to BibDesk Completions "*/
	IBOutlet NSButtonCell	*_lineNumberButton;			/*" connected to Line Number "*/
	IBOutlet NSButtonCell	*_midEastButton; /*" connected to Arabic, Persian, Hebrew "*/
	IBOutlet NSButton		*_openEmptyButton;		/*" open empty document on start "*/
	IBOutlet NSButton		*_externalEditorButton;		/*" use external editor "*/
	IBOutlet NSPopUpButton	*_defaultEncodeMatrix;		/*" text encoding "*/
	IBOutlet NSMatrix	*_pdfWindowPosMatrix;		/*" connected to "PDF Window Position" "*/
	IBOutlet NSButton	*_pdfWindowPosButton;		/* connected to current position button */

	IBOutlet NSTextField	*_magTextField;			/*" connected to magnification text field "*/
	IBOutlet NSButton	*_scrollButton;			/*" connected to scroll button "*/
	IBOutlet NSTextField	*_texCommandTextField;		/*" connected to "TeX program" "*/
	IBOutlet NSTextField	*_latexCommandTextField;	/*" connected to "Latex program" "*/
	IBOutlet NSButton	*_escapeWarningButton;		/*" connected to "Shell Escape Warning" "*/
	IBOutlet NSTextField	*_texGSCommandTextField;	/*" connected to "Tex + GS" "*/
	IBOutlet NSTextField	*_latexGSCommandTextField;	/*" connected to "Latex + GS" "*/
	IBOutlet NSButton	*_savePSButton;			/*" connect to save postscript "*/
	IBOutlet NSTextField	*_tetexBinPathField;		/*" connected to tetex bin path "*/
	IBOutlet NSTextField	*_gsBinPathField;		/*" connected to tetex bin path "*/
	IBOutlet NSTextField	*_texScriptCommandTextField;	/*" connected to "Personal Tex" "*/
	IBOutlet NSTextField	*_latexScriptCommandTextField; /*" connected to Personal Latex" "*/
	IBOutlet NSMatrix	*_defaultScriptMatrix;		/*" connected to "Default Script" "*/
	IBOutlet NSMatrix       *_defaultMetaPostMatrix;        /*" connected to "MetaPost" "*/
	IBOutlet NSMatrix       *_defaultBibtexMatrix;          /*" connected to "Bibtex" "*/
	IBOutlet NSMatrix	*_syncMatrix;			/*" connected to "Sync Method" "*/
	IBOutlet NSMatrix	*_defaultCommandMatrix;		/*" connected to "Default Program" "*/
	IBOutlet NSTextField    *_engineTextField;
	IBOutlet NSMatrix       *_distillerMatrix;              /*" connected to "Distiller" "*/
	IBOutlet NSMatrix	*_consoleMatrix;		/*" connected to "Show Console" "*/
	IBOutlet NSFormCell	*_tabsTextField;		/*" connected to tab size text field "*/
	IBOutlet NSButton	*_saveRelatedButton;		/*" connected to Save Related Files "*/
	IBOutlet NSButton       *_autoPDFButton;
	IBOutlet NSButton       *_ptexUtfOutputButton;          // zenitani 1.35 (C)
	IBOutlet NSColorWell	*_sourceBackgroundColorWell;
	IBOutlet NSColorWell	*_previewBackgroundColorWell;
	IBOutlet NSColorWell	*_consoleBackgroundColorWell;
	IBOutlet NSColorWell	*_consoleForegroundColorWell;
	IBOutlet NSTabView		*_tabView;
	IBOutlet NSMatrix		*_consoleResizeMatrix;

	NSUndoManager		*_undoManager;			/*" used for discarding all changes when the cancel button was pressed "*/
	NSFont			*_documentFont;			/*" used to track the font that the user has selected for the document window "*/
	NSFont			*_consoleFont;			/*" used to track the font that the user has selected for the console window "*/
	BOOL			fontTouched;			/*" if user fiddled with fonts and then cancelled,
																we restore the old one "*/
	BOOL			consoleFontTouched;
	BOOL			consoleBackgroundColorTouched;
	BOOL			consoleForegroundColorTouched;
	BOOL			sourceBackgroundColorTouched;
	BOOL			previewBackgroundColorTouched;
	BOOL			syntaxColorTouched;		/*" if user fiddled with syntax and then cancelled,
																we restore the old one "*/
	BOOL			oldSyntaxColor;			/*" value when preferences shown "*/
	BOOL			autoCompleteTouched;
	BOOL			bibDeskCompleteTouched;
	BOOL			oldAutoComplete;
	BOOL			oldBibDeskComplete;
	BOOL			magnificationTouched;
	BOOL			externalEditorTouched;
	BOOL			encodingTouched;

	IBOutlet NSPopUpButton	*_pageStylePopup;// mitsu 1.29 (O) /*" connected to page style popup button "*/
	IBOutlet NSMatrix       *_firstPageMatrix;// /*" radio buttons for first page left or right in multipage display "*/
	IBOutlet NSPopUpButton	*_resizeOptionPopup;// mitsu 1.29 (O) /*" connected to resize option popup button "*/
	IBOutlet NSPopUpButton	*_imageCopyTypePopup;// mitsu 1.29 (O) /*" connected to image copy type popup button "*/
	IBOutlet NSPopUpButton	*_mouseModePopup;// mitsu 1.29 (O) /*" connected to default mouse mode popup button "*/
	IBOutlet NSButton	*_colorMapButton;// mitsu 1.29 (O)
	IBOutlet NSColorWell	*_copyForeColorWell;// mitsu 1.29 (O)
	IBOutlet NSColorWell	*_copyBackColorWell;// mitsu 1.29 (O)
	IBOutlet NSPopUpButton	*_colorParam1Popup;// mitsu 1.29 (O)
	IBOutlet NSMatrix		*_afterTypesettingMatrix;
}

+ (id)sharedInstance;

//------------------------------------------------------------------------------
// target/action methods
//------------------------------------------------------------------------------
- (IBAction)showPreferences:sender;

- (IBAction)changeDocumentFont:sender;
- (IBAction)changeConsoleFont:sender;
- (IBAction)sourceWindowPosChanged:sender;
- (IBAction)currentDocumentWindowPosDefault:sender;
- (IBAction)syntaxColorPressed:sender;
- (IBAction)selectActivatePressed:sender;
- (IBAction)parensMatchPressed:sender;
- (IBAction)spellCheckPressed:sender;
- (IBAction)autoCompletePressed:sender;
- (IBAction)bibDeskCompletePressed:sender;
- (IBAction)lineNumberButtonPressed:sender;
- (IBAction)midEastButtonPressed:sender;
- (IBAction)emptyButtonPressed:sender;
- (IBAction)externalEditorButtonPressed:sender;
- (IBAction)encodingChanged:sender;
- (IBAction)tabsChanged:sender;
- (IBAction)findPanelChanged:sender;


- (IBAction)pdfWindowPosChanged:sender;
- (IBAction)currentPdfWindowPosDefault:sender;
- (IBAction)magChanged:sender;
- (IBAction)scrollPressed:sender;
- (IBAction)firstDoublePageChanged:sender;

- (IBAction)texProgramChanged:sender;
- (IBAction)latexProgramChanged:sender;
- (IBAction)escapeWarningChanged:sender;
- (IBAction)texGSProgramChanged:sender;
- (IBAction)latexGSProgramChanged:sender;
- (IBAction)savePSPressed:sender;
- (IBAction)tetexBinPathChanged:sender;
- (IBAction)gsBinPathChanged:sender;
- (IBAction)texScriptProgramChanged:sender;
- (IBAction)latexScriptProgramChanged:sender;
- (IBAction)defaultScriptChanged:sender;
- (IBAction)syncChanged:sender;
- (IBAction)defaultMetaPostChanged:sender;
- (IBAction)defaultBibtexChanged:sender;
- (IBAction)distillerChanged:sender;
- (IBAction)defaultProgramChanged:sender;
- (IBAction)setEngine:sender;
- (IBAction)consoleBehaviorChanged:sender;
- (IBAction)saveRelatedButtonPressed:sender;
- (IBAction)autoPDFChanged:sender;
- (IBAction)ptexUtfOutputPressed:sender; // zenitani 1.35 (C)
- (IBAction)afterTypesettingChanged:sender;
- (IBAction)setSourceBackgroundColor:sender;
- (IBAction)setPreviewBackgroundColor:sender;
- (IBAction)setConsoleBackgroundColor:sender;
- (IBAction)setConsoleForegroundColor:sender;
- (IBAction)changeConsoleResize:sender;

#ifdef MITSU_PDF
- (IBAction)pageStyleChanged:sender; // mitsu 1.29 (O)
- (IBAction)resizeOptionChanged:sender; // mitsu 1.29 (O)
- (IBAction)imageCopyTypeChanged:sender; // mitsu 1.29 (O)
- (NSPopUpButton *)imageCopyTypePopup; // mitsu 1.29b
- (IBAction)mouseModeChanged:sender; // mitsu 1.29 (O)
- (IBAction)colorMapChanged:sender; // mitsu 1.29 (O)
- (IBAction)copyForeColorChanged:sender; // mitsu 1.29 (O)
- (IBAction)copyBackColorChanged:sender; // mitsu 1.29 (O)
- (IBAction)colorParam1Changed:sender; // mitsu 1.29 (O)
#endif

- (IBAction)okButtonPressed:sender;
- (IBAction)cancelButtonPressed:sender;
- (IBAction)setDefaults:sender;

//------------------------------------------------------------------------------
// API used by other TeXShop classes
//------------------------------------------------------------------------------
- (NSString *)relativePath: (NSString *)path fromFile: (NSString *)file; // added by zenitani, Feb 13, 2003

- (void)registerFactoryDefaults;

//------------------------------------------------------------------------------
// private API
//------------------------------------------------------------------------------
- (void)updateControlsFromUserDefaults:(NSUserDefaults *)defaults;
- (void)updateDocumentFontTextField;
- (void)updateConsoleFontTextField;

@end
