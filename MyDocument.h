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
    // forsplit
    id			textView1;
    id			textView2;
    id			scrollView2;
    id			splitView;
    NSTextStorage 	*textStorage;
    BOOL		windowIsSplit;
// endforsplit
    id			textView;		/*" textView displaying the current TeX source "*/
    id			scrollView;		/*" scrollView for textView"*/
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
    id			pagenumberPanel;
    id			magnificationPanel;
    id			openSaveBox;
    id			openSaveView;
    id			linePanel;
    id			lineBox;
    id			typesetButton;
    id			typesetButtonEE;
    id			programButton;
    id			programButtonEE;
    id			tags;
    int			encoding;		/*" using tags of encoding matrix; changing tags does not change preference "*/
    int			tempencoding;
    int			whichScript;		/*" 100 = pdftex, 101 = gs, 102 = personal script "*/
    int			whichEngine;		/*" 1 = tex, 2 = latex, 3 = bibtex, 4 = makeindex, 5 = megapost, 6 = context,
                                                    7 = metafont "*/
    id			rootDocument;
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
    NSTask		*metaFontTask;
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
    BOOL		fastColor, fastColorBackTeX;
    NSTimer		*syntaxColoringTimer;	/*" Timer that repeatedly handles syntax coloring "*/
    unsigned		colorLocation;
    NSTimer		*tagTimer;		/*" Timer that repeatedly handles tag updates "*/
    unsigned		tagLocation;
    unsigned		tagLocationLine;
    BOOL		makeError;
    BOOL		returnline;
    SEL			tempSEL;
    NSColor		*commandColor, *commentColor, *markerColor;
    id			mSelection;
    id			gotopageOutlet;
    id			magnificationOutlet;
    id			previousButton;
    id			nextButton;
    
    IBOutlet NSMatrix 	*mouseModeMatrix; // mitsu 1.29 (O)
    IBOutlet NSMenu 	*mouseModeMenu; // mitsu 1.29 (O)
    IBOutlet NSMenu 	*magnificationMenu; // mitsu 1.29 test
    
    BOOL		externalEditor;
// added by mitsu --(H) Macro menu; macroButton
    id			macroButton;		/*" pull-down list for macros "*/
    id			autoCompleteButton;
    BOOL		doAutoComplete;
    BOOL		warningGiven;
    BOOL		omitShellEscape;
    BOOL		withLatex;
// end addition

}
-(void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel;
- (void)saveToFile:(NSString *)fileName saveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo;
// forsplit
- (void) splitWindow: sender;
- (void) setTextView: (id)aView;
// endforsplit
- (id) magnificationPanel;
- (id) pagenumberPanel;
- (void) quitMagnificationPanel: sender;
- (void) quitPagenumberPanel: sender;
- (void) doTex: sender;
- (void) doLatex: sender;
- (void) doBibtex: sender;
- (void) doMetapost: sender;
- (void) doContext: sender;
- (void) doIndex: sender;
- (void) doMetaFont: sender;
- (void) doTypeset: sender;
- (void) doTypesetEE: sender;
- (void) doTemplate: sender;
- (void) doTexCommand: sender;
- (void) printSource: sender;
- (void) okForRequest: sender;
- (void) chooseEncoding: sender;
- (void) okForPrintRequest: sender;
- (void) close;
- (void) setProjectFile: sender;
- (void) doLine: sender;
- (void) doTag: sender;
- (void) chooseProgram: sender;
- (void) chooseProgramEE: sender;
- (void) saveFinished: (NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo;
- (void) completeSaveFinished;
- (id) pdfView;
- (void) doCompletion:(NSNotification *)notification;
- (void) changeAutoComplete: sender;
- (void) fixAutoMenu;
- (void) fixMacroMenu;
- (void) toLine: (int)line;
- (void) doChooseMethod: sender;
- (void) fixTypesetMenu;
- (void) doError: sender;
- (int) errorLineFor: (int)theError;
- (int) totalErrors;
- (int) textViewCountTabs: (NSTextView *) aTextView andSpaces: (int *) spaces;
- (void) fixColor: (unsigned)from : (unsigned)to;
// - (void) fixColor1: sender;
- (void) fixColor2: (unsigned)from :(unsigned)to;
- (void) textDidChange:(NSNotification *)aNotification;
- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType;
- (BOOL)keepBackupFile;
- (void) setupTags;
- (int) imageType;
- (id) pdfWindow;
- (id) textWindow;
- (id) textView;
- (void)fixUpTabs;
- (BOOL) externalEditor;
- (NSString *)displayName;
- (NSPDFImageRep *) myTeXRep;
- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString;
- (NSRange)textView:(NSTextView *)aTextView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange;
- (NSDictionary *)fileAttributesToWriteToFile:(NSString *)fullDocumentPath ofType:(NSString *)documentTypeName saveOperation:(NSSaveOperationType)saveOperationType;
- (void)convertDocument;
- (BOOL)isDocumentEdited;
- (BOOL)fileIsTex; // added by zenitani, Feb 13, 2003
//-----------------------------------------------------------------------------
// Timer methods
//-----------------------------------------------------------------------------
- (void)fixTags:(NSTimer *)timer;
// - (void)fixColor1:(NSTimer *)timer;

//-----------------------------------------------------------------------------
// Extra methods
//-----------------------------------------------------------------------------

// added by mitsu --(J) Typeset command
- (int)whichEngine;
// end addition

// mitsu 1.29
- (void)showInfo: (id)sender; // mitsu 1.29 (Q)
- (BOOL)isDoAutoCompleteEnabled; // mitsu 1.29 (T4)
- (void)insertSpecial:(NSString *)theString undoKey:(NSString *)key;
- (void)insertSpecialNonStandard:(NSString *)theString undoKey:(NSString *)key;
- (void)registerUndoWithString:(NSString *)oldString location:(unsigned)oldLocation 
	length: (unsigned)newLength key:(NSString *)key;
- (void)undoSpecial:(id)theDictionary;
- (void)doCommentOrIndent: (id)sender;
- (void)saveDocument: (id)sender;
// end mitsu 1.29



//-----------------------------------------------------------------------------
// private API
//-----------------------------------------------------------------------------
- (void)registerForNotifications;
- (void)setDocumentFontFromPreferences:(NSNotification *)notification;
- (void)setupFromPreferencesUsingWindowController:(NSWindowController *)windowController;
// added by John Nairn
- (BOOL)checkMasterFile:(NSString *)theSource forTask:(int)task;
- (BOOL) checkRootFile_forTask:(int)task;
- (void) checkFileLinks:(NSString *)theSource;
- (NSString *) readInputArg:(NSString *)fileLine atIndex:(unsigned)i
        homePath:(NSString *)home job:(NSString *)jobname;
- (NSString *) decodeFile:(NSString *)relFile homePath:(NSString *)home job:(NSString *)jobname;
- (void) makeMenuFromDirectory: (NSMenu *)menu basePath: (NSString *)basePath action:(SEL)action level:(unsigned)level; // added by S. Zenitani


@end






