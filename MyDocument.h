// MyDocument.h

// Created by koch in July, 2000.

#import <AppKit/NSDocument.h>

#define NUMBEROFERRORS	20


#define	isTeX		0
#define isOther		1
#define isPDF		2
#define isEPS		3
#define isJPG		4
#define isTIFF		5


@interface MyDocument : NSDocument 
{
    id			textView;		/*" textView displaying the current TeX source "*/
    id			pdfView;		/*" view displaying the current preview "*/
    id			textWindow;		/*" window displaying the current document "*/
    id			pdfWindow;		/*" window displaying the current pdf preview "*/
    id			outputWindow;		/*" window displaying the output of the running TeX process "*/
    id			outputText;		/*" text displaying the output of the running TeX process "*/
    NSTextField		*texCommand;		/*" connected to the command textField on the errors panel "*/
    id			popupButton;		/*" popupButton displaying all the TeX templates "*/
    id			projectPanel;
    id			projectName;
    id			requestWindow;
    id			printRequestPanel;
    id			linePanel;
    id			lineBox;
    id			typesetButton;
    id			typesetButtonEE;
    id			programButton;
    id			programButtonEE;
    id			tags;
    int			whichScript;		/*" 100 = pdftex, 101 = gs, 102 = personal script "*/
    int			whichEngine;		/*" 0 = tex, 1 = latex, 2 = context, 3 = omega, 4 = megapost, 5 = bibtex,
                                                    6 = makeindex "*/
    BOOL		tagLine;
    BOOL		typesetStart;		/*" YES if tex output "*/
    NSFileHandle	*writeHandle;
    NSFileHandle	*readHandle;
    NSPipe		*inputPipe;
    NSPipe		*outputPipe;
    NSString		*aString;		/*" holds the content of the tex document "*/
    NSTask		*texTask;
    NSTask		*bibTask;
    NSTask		*indexTask;
    NSDate		*startDate;
    NSPDFImageRep	*texRep;
    NSData		*previousFontData;	/*" holds font data in case preferences change is cancelled "*/
    int			myPrefResult;
    BOOL		fileIsTex;
    int			myImageType;
    int			errorLine[NUMBEROFERRORS];
    int			errorNumber;
    int			whichError;
    int			theScript;		/*" script currently executing; 100, 101, 102 "*/
    unsigned		colorStart, colorEnd;
    BOOL		fastColor;
    NSTimer		*syntaxColoringTimer;	/*" Timer that repeatedly handles syntax coloring "*/
    unsigned		colorLocation;
    NSTimer		*tagTimer;		/*" Timer that repeatedly handles tag updates "*/
    unsigned		tagLocation;
    BOOL		makeError;
    BOOL		returnline;
    SEL			tempSEL;
    NSColor		*commandColor, *commentColor, *markerColor;
    id			mSelection;
    id			gotopageOutlet;
    id			magnificationOutlet;
    id			previousButton;
    id			nextButton;
    BOOL		externalEditor;
}
 
- (void) doTex: sender;
- (void) doLatex: sender;
- (void) doBibtex: sender;
- (void) doMetapost: sender;
- (void) doContext: sender;
- (void) doIndex: sender;
- (void) doTypeset: sender;
- (void) doTypesetEE: sender;
- (void) doTemplate: sender;
- (void) doTexCommand: sender;
- (void) printSource: sender;
- (void) okForRequest: sender;
- (void) okForPrintRequest: sender;
- (void) close;
- (void) setProjectFile: sender;
- (void) doLine: sender;
- (void) doTag: sender;
- (void) chooseProgram: sender;
- (void) chooseProgramEE: sender;
- (void) saveFinished: (NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo;
- (id) pdfView;
- (void) doComment: sender;
- (void) doUncomment: sender;
- (void) doIndent: sender;
- (void) doUnindent: sender;
- (void) toLine: (int)line;
- (void) doChooseMethod: sender;
- (void) fixTypesetMenu;
- (void) doError: sender;
- (void) fixColor: (unsigned)from : (unsigned)to;
// - (void) fixColor1: sender;
- (void) fixColor2: (unsigned)from :(unsigned)to;
- (void) fixColorBlack: sender;
- (void) textDidChange:(NSNotification *)aNotification;
- (void) setupTags;
- (int) imageType;
- (id) pdfWindow;
- (id) textWindow;
- (id) textView;
- (BOOL) externalEditor;
- (NSPDFImageRep *) myTeXRep;
- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString;
- (NSRange)textView:(NSTextView *)aTextView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange;
- (void) updateChangeCount: (NSDocumentChangeType)changeType;
// - (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type; /* no longer used; see .m file */
- (NSDictionary *)fileAttributesToWriteToFile:(NSString *)fullDocumentPath ofType:(NSString *)documentTypeName saveOperation:(NSSaveOperationType)saveOperationType;
- (void)convertDocument;
- (BOOL)isDocumentEdited;
//-----------------------------------------------------------------------------
// Timer methods
//-----------------------------------------------------------------------------
- (void)fixTags:(NSTimer *)timer;
- (void)fixColor1:(NSTimer *)timer;

//-----------------------------------------------------------------------------
// private API
//-----------------------------------------------------------------------------
- (void)registerForNotifications;
- (void)setDocumentFontFromPreferences:(NSNotification *)notification;
- (void)setupFromPreferencesUsingWindowController:(NSWindowController *)windowController;

@end






