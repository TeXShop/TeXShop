// MyDocument.h

#import <AppKit/AppKit.h>

@interface MyDocument : NSDocument {
    id			textView;
    id			pdfView;
    id			textWindow;
    id			pdfWindow;
    id			outputWindow;
    id			outputText;
    id			prefWindow;
    id			fontChange;
    id			magChange;
    id			pdfWindowChange;
    id			sourceWindowChange;
    id			popupButton;
    id			projectPanel;
    id			projectName;
    id			requestWindow;
    id			printRequestPanel;
    id			linePanel;
    id			lineBox;
    id			texEngine;
    id			latexEngine;
    id			textFinder;
    NSString		*myTexEngine;
    NSString		*myLatexEngine;
    NSTextField		*texCommand;
    NSPipe		*outputPipe;
    NSPipe		*inputPipe;
    NSFileHandle	*writeHandle;
    NSFileHandle	*readHandle;
    NSString		*aString;
    NSTask		*texTask;
    NSDate		*startDate;
    NSFileManager	*myFileManager;
    NSPDFImageRep	*texRep;
    int			myPrefResult;
    }
    
- (void) doTex: sender;
- (void) doLatex: sender;
- (void) doTemplate: sender;
- (void) doTexCommand: sender;
- (void) printSource: sender;
- (void) doPreferences: sender;
- (void) quitPreferences: sender;
- (void) okPreferences: sender;
- (void) okForRequest: sender;
- (void) okForPrintRequest: sender;
- (void) readPreferences;
- (void) doLine: sender;
- (id) pdfView;
@end


@interface MyView : NSView {
    id			currentPage;
    id			totalPage;
    id			mySize;
    NSPDFImageRep	*myRep;
    MyDocument		*myDocument;
    }
    
- (void) previousPage: sender;
- (void) nextPage: sender;
- (void) goToPage: sender;
- (void) setImageRep: (NSPDFImageRep *)theRep;
- (void) changeSize: sender;
- (void) printDocument: sender;
- (id) slider;
@end

@interface PrintView : NSView {
    NSPDFImageRep	*myRep;
    NSPrintOperation	*myPrintOperation;

    
    }
    
- (PrintView *) initWithRep: (NSPDFImageRep *) aRep;
- (void) setPrintOperation: (NSPrintOperation *)aPrintOperation;
    
@end

@interface MyWindow : NSWindow {

    MyDocument	*myDocument;
    }
   
- (void) printDocument: sender;
- (void) printSource: sender;
- (void) doPreferences: sender;
- (void) doTex: sender;
- (void) doLatex: sender;
- (void) previousPage: sender;
- (void) nextPage: sender;

@end
