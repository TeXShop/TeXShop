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

- (void) doChooseMethod: sender;
{
    [myDocument doChooseMethod: sender];
}

- (void) doError: sender;
{
    [myDocument doError: sender];
}

// for scripting
- (MyDocument *)document
{
	return myDocument;
}
// end addition

@end
