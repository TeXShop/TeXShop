//
//  MainWindow.m
//  TeXShop
//
//  Originally part of MyDocument. Broken out by dirk on Tue Jan 09 2001.
//

#import <AppKit/AppKit.h>
#import "MainWindow.h"
#import "MyDocument.h" // for the definition of isTeX (move this to a separate file!!)

@implementation MainWindow : NSWindow

- (void)makeKeyAndOrderFront:(id)sender;
{
   if ([myDocument imageType] == isTeX)
        [super makeKeyAndOrderFront: sender];
}

@end
