//
//  MyWindow.h
//  TeXShop
//
//  Originally part of MyDocument. Broken out by dirk on Tue Jan 09 2001.
//

#import "UseMitsu.h"

#import <AppKit/NSWindow.h>

@class MyDocument;

@interface MyWindow : NSWindow 
{
    MyDocument	*myDocument;
    BOOL	firstClose;

}

- (void) doTextMagnify: sender;   // for toolbar in text mode
- (void) doTextPage: sender;      // for toolbar in text mode
- (void) magnificationDidEnd:(NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (void) pagenumberDidEnd:(NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (void) printDocument: sender;
- (void) printSource: sender;
- (void) doTypeset: sender;
- (void) doTex: sender;
- (void) doLatex: sender;
- (void) doBibtex: sender;
- (void) doMetaFont: sender;
- (void) doIndex: sender;
- (void) previousPage: sender;
- (void) nextPage: sender;
- (void) firstPage: sender;
- (void) lastPage: sender;
- (void) up: sender;
- (void) down: sender;
- (void) top: sender;
- (void) bottom: sender;
- (void) doError: sender;
- (void) doChooseMethod: sender;
- (void) rotateClockwise: sender;
- (void) rotateCounterclockwise: sender;
- (void) orderOut: sender;
- (void) sendEvent:(NSEvent *)theEvent;
- (void) associatedWindow: sender;
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
- (MyDocument *)document;
#ifdef MITSU_PDF
- (void) left: sender; // mitsu 1.29 (O)
- (void) right: sender; // mitsu 1.29 (O)
- (void)changePageStyle: (id)sender; // mitsu 1.29 (O)
- (void)changePDFViewSize: (id)sender; // mitsu 1.29 (O)
- (void)saveSelectionToFile: (id)sender; // mitsu 1.29 (O)
#endif MITSU_PDF
- (void)pagenumberDidEnd:(NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (void)magnificationDidEnd:(NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
@end
