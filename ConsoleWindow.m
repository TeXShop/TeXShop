//
//  ConsoleWindow.m
//  TeXShop
//
//  Originally part of My Document. Broken out by dirk on Tue Jan 09 2001.
//

#import <AppKit/AppKit.h>
#import "ConsoleWindow.h"
#import "MyDocument.h"
#import "globals.h"

#define SUD [NSUserDefaults standardUserDefaults]

@implementation ConsoleWindow : NSWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
    id  result;
    result = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];
    float alpha = [SUD floatForKey: ConsoleWindowAlphaKey];
    if (alpha < 0.999) 
         [self setAlphaValue:alpha];
    return result;
}

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
