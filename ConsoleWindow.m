//
//  ConsoleWindow.m
//  TeXShop
//
//  Originally part of My Document. Broken out by dirk on Tue Jan 09 2001.
//

#import <AppKit/AppKit.h>
#import "ConsoleWindow.h"
#import "MyDocument.h"

@implementation ConsoleWindow : NSWindow

- (void) doError: sender;
{
    [myDocument doError: sender];
}


@end
