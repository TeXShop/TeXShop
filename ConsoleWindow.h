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
   
- (void) doError: sender;

@end
