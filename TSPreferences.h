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

	IBOutlet NSMatrix	*_pdfWindowPosMatrix;		/*" connected to "PDF Window Position" "*/
        IBOutlet NSButton	*_pdfWindowPosButton;		/* connected to current position button */

        IBOutlet NSTextField	*_magTextField;			/*" connected to magnification text field "*/ 
	IBOutlet NSTextField	*_texCommandTextField;		/*" connected to "TeX program" "*/
	IBOutlet NSTextField	*_latexCommandTextField;	/*" connected to "Latex program" "*/
	IBOutlet NSMatrix	*_defaultCommandMatrix;		/*" connected to "Default Program" "*/
        IBOutlet NSMatrix	*_consoleMatrix;		/*" connected to "Show Console" "*/
	
	NSUndoManager		*_undoManager;			/*" used for discarding all changes when the cancel button was pressed "*/
        NSFont			*_documentFont;			/*" used to track the font that the user has selected for the document window "*/
        BOOL			fontTouched;			/*" if user fiddled with fonts and then cancelled,
                                                                    we restore the old one "*/
        BOOL			syntaxColorTouched;		/*" if user fiddled with syntax and then cancelled,
                                                                    we restore the old one "*/
        BOOL			oldSyntaxColor;			/*" value when preferences shown "*/
        BOOL			magnificationTouched;
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

- (IBAction)pdfWindowPosChanged:sender;
- (IBAction)currentPdfWindowPosDefault:sender;
- (IBAction)magChanged:sender;

- (IBAction)texProgramChanged:sender;
- (IBAction)latexProgramChanged:sender;
- (IBAction)defaultProgramChanged:sender;
- (IBAction)consoleBehaviorChanged:sender;

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
- (void)createDirectoryAtPath:(NSString *)path;
- (void)copyToTemplateDirectory:(NSString *)fileName;
- (void)updateControlsFromUserDefaults:(NSUserDefaults *)defaults;
- (void)updateDocumentFontTextField;

@end
