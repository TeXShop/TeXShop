// MyDocument.h

#import <AppKit/AppKit.h>

#define NUMBEROFERRORS	20

@interface MyDocument : NSDocument {
    id			textView; 				/*" textView displaying the current TeX source "*/
    id			pdfView; 				/*" view displaying the current preview "*/
    id			textWindow; 			/*" window displaying the current document "*/
    id			pdfWindow; 				/*" window displaying the current pdf preview "*/
    id			outputWindow;
    id			outputText;
    id			popupButton;
    id			projectPanel;
    id			projectName;
    id			requestWindow;
    id			printRequestPanel;
    id			linePanel;
    id			lineBox;
    id			typesetButton;
    int			whichEngine; 			/*" 0 = tex, 1 = latex, 2 = bibtex "*/
    NSTextField		*texCommand; 		/*" connected to the command textField on the errors panel "*/
    NSPipe		*outputPipe;
    NSPipe		*inputPipe;
    NSFileHandle	*writeHandle;
    NSFileHandle	*readHandle;
    NSString		*aString; 			/*" the content of the tex document "*/
    NSTask		*texTask;
    NSTask		*bibTask;
    NSDate		*startDate;
    NSFileManager	*myFileManager;
    NSPDFImageRep	*texRep;

    int			myPrefResult;			/*" used as status flag when closing window(s) "*/
    BOOL		fileIsTex;
    int			errorLine[NUMBEROFERRORS];
    int			errorNumber;
    int			whichError;
    BOOL		makeError;
}
    
- (void) doTex: sender;
- (void) doLatex: sender;
- (void) doBibtex: sender;
- (void) doTypeset: sender;
- (void) doTemplate: sender;
- (void) doTexCommand: sender;
- (void) printSource: sender;
- (void) okForRequest: sender;
- (void) okForPrintRequest: sender;
- (void) doLine: sender;
- (void) chooseProgram: sender;
- (void) saveFinished: (NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo;
- (id) pdfView;
- (id) fileManager;
- (void) doBibJob;
- (void) toLine: (int)line;
- (void) doError: sender;
- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString;
- (NSRange)textView:(NSTextView *)aTextView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange;

- (void)setupFromPreferencesUsingWindowController:(NSWindowController *)windowController;

@end


@interface MyView : NSView {
    id			currentPage;
    id			totalPage;
    id			mySize;
    BOOL		fixScroll;
    NSPDFImageRep	*myRep;
    NSBitmapImageRep	*gsRep;
    NSTask		*gsTask;
    MyDocument		*myDocument;
    }
    
- (void) previousPage: sender;
- (void) nextPage: sender;
- (void) goToPage: sender;
- (void) setImageRep: (NSPDFImageRep *)theRep;
- (void) changeSize: sender;
- (void) printDocument: sender;
- (id) slider;
- (void) destroyGSRep;
- (void) setDocument: (id) theDocument;
- (void) drawWithGhostscript;
@end

@interface PrintView : NSView {
    NSPDFImageRep	*myRep;
    NSPrintOperation	*myPrintOperation;
    int			myDisplayPref;
    }
    
- (PrintView *) initWithRep: (NSPDFImageRep *) aRep andDisplayPref: (int) displayPref;
- (void) setPrintOperation: (NSPrintOperation *)aPrintOperation;
    
@end

@interface MyWindow : NSWindow {

    MyDocument	*myDocument;
    }
   
- (void) printDocument: sender;
- (void) printSource: sender;
- (void) doPreferences:sender;
- (void) doTex: sender;
- (void) doLatex: sender;
- (void) doBibtex: sender;
- (void) previousPage: sender;
- (void) nextPage: sender;
- (void) doError: sender;

@end

@interface ConsoleWindow : NSWindow {

    MyDocument	*myDocument;
    }
   
- (void) doError: sender;

@end

