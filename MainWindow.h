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

- (void) doChooseMethod: sender;
- (void) makeKeyAndOrderFront:(id)sender;
- (void) sendEvent:(NSEvent *)theEvent;

@end
