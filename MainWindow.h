//
//  MainWindow.h
//  TeXShop
//
//  Originally part of MyDocument. Broken out by dirk on Tue Jan 09 2001.
//

#import <AppKit/NSWindow.h>
#import "MyDocument.h"


@interface MainWindow : NSWindow 
{
    MyDocument	*myDocument;
}

// added by mitsu --(H) Macro menu; used to detect the document from a window
- (MyDocument *)document;
// end addition
- (void) doChooseMethod: sender;
- (void) makeKeyAndOrderFront:(id)sender;
- (void) becomeMainWindow;
//- (void) sendEvent:(NSEvent *)theEvent;
- (void) associatedWindow:(id)sender;
// forsplit
- (BOOL)makeFirstResponder:(NSResponder *)aResponder;
// end forsplit
@end
