//
//  TSPreferences.h
//  TeXShop
//
//  Created by dirk on Thu Dec 07 2000.
//

#import <AppKit/AppKit.h>

@interface TSPreferences : NSObject 
{
	IBOutlet NSWindow	*_prefsWindow;			/*" connected to the window "*/
	IBOutlet NSTextField	*_documentFontTextField;	/*" connected to "Document Font" "*/
	IBOutlet NSMatrix	*_sourceWindowPosMatrix;	/*" connected to "Source Window Position" "*/
        IBOutlet NSButton	*_docWindowPosButton;		/* connect to set current position button */

        IBOutlet NSButton	*_syntaxColorButton;		/*" connected to "Syntax Coloring" "*/
        IBOutlet NSButton	*_parensMatchButton;		/*" connected to "Parens Matching "*/
        IBOutlet NSButton	*_spellCheckButton;		/*" connected to "SpellChecking "*/
        IBOutlet NSButton	*_autoCompleteButton;		/*" connected to "Auto Completion "*/
        IBOutlet NSButton	*_openEmptyButton;		/*" open empty document on start "*/
        IBOutlet NSButton	*_externalEditorButton;		/*" use external editor "*/
        IBOutlet NSPopUpButton	*_defaultEncodeMatrix;		/*" text encoding "*/
	IBOutlet NSMatrix	*_pdfWindowPosMatrix;		/*" connected to "PDF Window Position" "*/
        IBOutlet NSButton	*_pdfWindowPosButton;		/* connected to current position button */

        IBOutlet NSTextField	*_magTextField;			/*" connected to magnification text field "*/
        IBOutlet NSButton	*_scrollButton;			/*" connected to scroll button "*/ 
	IBOutlet NSTextField	*_texCommandTextField;		/*" connected to "TeX program" "*/
	IBOutlet NSTextField	*_latexCommandTextField;	/*" connected to "Latex program" "*/
        IBOutlet NSTextField	*_texGSCommandTextField;	/*" connected to "Tex + GS" "*/
        IBOutlet NSTextField	*_latexGSCommandTextField;	/*" connected to "Latex + GS" "*/
        IBOutlet NSButton	*_savePSButton;			/*" connect to save postscript "*/
        IBOutlet NSTextField	*_tetexBinPathField;		/*" connected to tetex bin path "*/
        IBOutlet NSTextField	*_gsBinPathField;		/*" connected to tetex bin path "*/
        IBOutlet NSTextField	*_texScriptCommandTextField;	/*" connected to "Personal Tex" "*/
        IBOutlet NSTextField	*_latexScriptCommandTextField; /*" connected to Personal Latex" "*/	
        IBOutlet NSMatrix	*_defaultScriptMatrix;		/*" connected to "Default Script" "*/
	IBOutlet NSMatrix	*_defaultCommandMatrix;		/*" connected to "Default Program" "*/
        IBOutlet NSMatrix	*_consoleMatrix;		/*" connected to "Show Console" "*/
        IBOutlet NSTextField	*_tabsTextField;		/*" connected to tab size text field "*/
        IBOutlet NSButton	*_saveRelatedButton;		/*" connected to Save Related Files "*/
	
	NSUndoManager		*_undoManager;			/*" used for discarding all changes when the cancel button was pressed "*/
        NSFont			*_documentFont;			/*" used to track the font that the user has selected for the document window "*/
        BOOL			fontTouched;			/*" if user fiddled with fonts and then cancelled,
                                                                    we restore the old one "*/
        BOOL			syntaxColorTouched;		/*" if user fiddled with syntax and then cancelled,
                                                                    we restore the old one "*/
        BOOL			oldSyntaxColor;			/*" value when preferences shown "*/
        BOOL			autoCompleteTouched;
        BOOL			oldAutoComplete;
        BOOL			magnificationTouched;
        BOOL			externalEditorTouched;
// added by mitsu --(G) EncodingSupport
        BOOL			encodingTouched;
// end addition
}

+ (id)sharedInstance;

//------------------------------------------------------------------------------
// target/action methods
//------------------------------------------------------------------------------
- (IBAction)showPreferences:sender;

- (IBAction)changeDocumentFont:sender;
- (IBAction)sourceWindowPosChanged:sender;
- (IBAction)currentDocumentWindowPosDefault:sender;
- (IBAction)syntaxColorPressed:sender;
- (IBAction)parensMatchPressed:sender;
- (IBAction)spellCheckPressed:sender;
- (IBAction)autoCompletePressed:sender;
- (IBAction)emptyButtonPressed:sender;
- (IBAction)externalEditorButtonPressed:sender;
- (IBAction)encodingChanged:sender;
- (IBAction)tabsChanged:sender;


- (IBAction)pdfWindowPosChanged:sender;
- (IBAction)currentPdfWindowPosDefault:sender;
- (IBAction)magChanged:sender;
- (IBAction)scrollPressed:sender;

- (IBAction)texProgramChanged:sender;
- (IBAction)latexProgramChanged:sender;
- (IBAction)texGSProgramChanged:sender;
- (IBAction)latexGSProgramChanged:sender;
- (IBAction)savePSPressed:sender;
- (IBAction)tetexBinPathChanged:sender;
- (IBAction)gsBinPathChanged:sender;
- (IBAction)texScriptProgramChanged:sender;
- (IBAction)latexScriptProgramChanged:sender;
- (IBAction)defaultScriptChanged:sender;
- (IBAction)defaultProgramChanged:sender;
- (IBAction)consoleBehaviorChanged:sender;
- (IBAction)saveRelatedButtonPressed:sender;

- (IBAction)okButtonPressed:sender;
- (IBAction)cancelButtonPressed:sender;

//------------------------------------------------------------------------------
// API used by other TeXShop classes
//------------------------------------------------------------------------------
- (NSArray *)allTemplateNames;
- (void)registerFactoryDefaults;

//------------------------------------------------------------------------------
// private API
//------------------------------------------------------------------------------
- (void)updateControlsFromUserDefaults:(NSUserDefaults *)defaults;
- (void)updateDocumentFontTextField;

@end
