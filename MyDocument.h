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
    id			tags;
    int			whichScript;		/*" 100 = pdftex, 101 = gs, 102 = personal script "*/
    int			whichEngine;		/*" 0 = tex, 1 = latex, 2 = bibtex "*/
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
    unsigned		colorStart, colorEnd;
    NSTimer		*syntaxColoringTimer;	/*" Timer that repeatedly handles syntax coloring "*/
    unsigned		colorLocation;
    NSTimer		*tagTimer;		/*" Timer that repeatedly handles tag updates "*/
    unsigned		tagLocation;
    BOOL		makeError;
    BOOL		returnline;
    SEL			tempSEL;
    NSColor		*commandColor, *commentColor, *markerColor;
}
 
- (void) doTex: sender;
- (void) doLatex: sender;
- (void) doBibtex: sender;
- (void) doIndex: sender;
- (void) doTypeset: sender;
- (void) doTemplate: sender;
- (void) doTexCommand: sender;
- (void) printSource: sender;
- (void) okForRequest: sender;
- (void) okForPrintRequest: sender;
- (void) close;
- (void) doLine: sender;
- (void) doTag: sender;
- (void) chooseProgram: sender;
- (void) saveFinished: (NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo;
- (id) pdfView;
- (void) doBibJob;
- (void) doIndexJob;
- (void) toLine: (int)line;
- (void) doChooseMethod: sender;
- (void) fixTypesetMenu;
- (void) doError: sender;
- (void) fixColor: (unsigned)from : (unsigned)to;
- (void) fixColor1: sender;
- (void) fixColorBlack: sender;
- (void) textDidChange:(NSNotification *)aNotification;
- (void) setupTags;
- (int) imageType;
- (id) pdfWindow;
- (id) textWindow;
- (NSPDFImageRep *) myTeXRep;
- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString;
- (NSRange)textView:(NSTextView *)aTextView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange;
- (void) updateChangeCount: (NSDocumentChangeType)changeType;
- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type;
- (void)convertDocument;

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






