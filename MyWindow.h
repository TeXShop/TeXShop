//
//  MyWindow.h
//  TeXShop
//
//  Originally part of MyDocument. Broken out by dirk on Tue Jan 09 2001.
//

#import <AppKit/NSWindow.h>

@class MyDocument;

@interface MyWindow : NSWindow 
{
    MyDocument	*myDocument;
    BOOL	firstClose;
}
   
- (void) printDocument: sender;
- (void) printSource: sender;
- (void) doTex: sender;
- (void) doLatex: sender;
- (void) doBibtex: sender;
- (void) doIndex: sender;
- (void) previousPage: sender;
- (void) nextPage: sender;
- (void) doError: sender;
- (void) orderOut: sender;
- (void) sendEvent:(NSEvent *)theEvent;
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
- (MyDocument *)document;
@end
