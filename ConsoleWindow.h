//
//  ConsoleWindow.h
//  TeXShop
//
//  Originally part of MyDocument. Broken out by dirk on Tue Jan 09 2001.
//

#import <AppKit/NSWindow.h>

@class MyDocument;

@interface ConsoleWindow : NSWindow 
{
    MyDocument	*myDocument;
}

- (void) doChooseMethod: sender;
- (void) doError: sender;
- (MyDocument *)document;
@end
