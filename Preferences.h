//
//  Preferences.h
//  TeXShop
//
//  Created by dirk on Thu Dec 07 2000.
//

#import <AppKit/AppKit.h>

@interface Preferences : NSObject 
{
	IBOutlet NSWindow		*_prefsWindow;			/*" connected to the window "*/
	IBOutlet NSMatrix		*_fontChangeMatrix;		/*" connected to "Font for Source" "*/
	IBOutlet NSMatrix		*_pdfMagMatrix;			/*" connected to "PDF Magnification "*/
	IBOutlet NSMatrix		*_sourceWindowPosMatrix;	/*" connected to "Source Window Position" "*/
	IBOutlet NSMatrix		*_pdfWindowPosMatrix;		/*" connected to "PDF Window Position" "*/
	IBOutlet NSTextField		*_texCommandTextField;		/*" connected to "TeX program" "*/
	IBOutlet NSTextField		*_latexCommandTextField;	/*" connected to "Latex program" "*/
	IBOutlet NSMatrix		*_defaultCommandMatrix;		/*" connected to "Default Program" "*/
	IBOutlet NSMatrix		*_pdfDisplayMatrix;		/*" connected to "PDF Display" "*/
	IBOutlet NSMatrix		*_gsColorMatrix;		/*" connected to "Ghostscript colors" "*/
	
	NSUndoManager			*_undoManager;			/*" used for discarding all changes when the cancel button was pressed"*/
}

+ (id)sharedInstance;

//------------------------------------------------------------------------------
// target/action methods
//------------------------------------------------------------------------------
- (IBAction)showPreferences:sender;
- (IBAction)fontForSourceChanged:sender;
- (IBAction)pdfMagnificationChanged:sender;
- (IBAction)sourceWindowPosChanged:sender;
- (IBAction)pdfWindowPosChanged:sender;
- (IBAction)texProgramChanged:sender;
- (IBAction)latexProgramChanged:sender;
- (IBAction)defaultProgramChanged:sender;
- (IBAction)pdfDisplayChanged:sender;
- (IBAction)ghostscriptColorChanged:sender;
- (IBAction)okButtonPressed:sender;
- (IBAction)cancelButtonPressed:sender;

//------------------------------------------------------------------------------
// API used by other TeXShop classes
//------------------------------------------------------------------------------
- (NSArray *)allTemplateNames;

//------------------------------------------------------------------------------
// private API
//------------------------------------------------------------------------------
- (void)registerFactoryDefaults;
- (void)createDirectoryAtPath:(NSString *)path;
- (void)copyToTemplateDirectory:(NSString *)fileName;
- (void)updateControlsFromUserDefaults:(NSUserDefaults *)defaults;

@end
