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

// added by mitsu --(H) Macro menu; used to detect the document from a window
- (MyDocument *)document
{
	return myDocument;
}
// end addition


- (void)makeKeyAndOrderFront:(id)sender;
{
   if (
   (! [myDocument externalEditor]) &&
    (([myDocument imageType] == isTeX) || ([myDocument imageType] == isOther))
    )
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

// forsplit
- (BOOL)makeFirstResponder:(NSResponder *)aResponder
{
    BOOL	result;
    
    result = [super makeFirstResponder:aResponder];
    if (result && [[aResponder className] isEqualTo:@"MyTextView"])
        [myDocument setTextView:aResponder];
    return result;
}
// end forsplit

@end
