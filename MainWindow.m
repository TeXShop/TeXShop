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
   if (([myDocument imageType] == isTeX) || ([myDocument imageType] == isOther))
        [super makeKeyAndOrderFront: sender];
}

- (void)sendEvent:(NSEvent *)theEvent
{
    if (([theEvent type] == NSKeyDown) && ([theEvent modifierFlags] & NSControlKeyMask))
    if ([[theEvent charactersIgnoringModifiers] isEqualToString:@"1"]) {
            if (([myDocument imageType] == isTeX) && ([myDocument myTeXRep] != nil))
                [[myDocument pdfWindow] makeKeyAndOrderFront: self];
            return;
            }
    [super sendEvent: theEvent];
}

- (void) doChooseMethod: sender;
{
    [myDocument doChooseMethod: sender];
}

@end
