//
//  MainWindow.h
//  TeXShop
//
//  Originally part of MyDocument. Broken out by dirk on Tue Jan 09 2001.
//

#import <AppKit/NSWindow.h>

@class MyDocument;

@interface MainWindow : NSWindow 
{
    MyDocument	*myDocument;
}

- (void)makeKeyAndOrderFront:(id)sender;
    
@end
