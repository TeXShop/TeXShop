//
//  PrintBitmapView.m
//  TeXShop
//

#import <AppKit/AppKit.h>
#import "PrintBitmapView.h"

@implementation PrintBitmapView : NSView

- (PrintBitmapView *) initWithBitmapRep: (NSBitmapImageRep *) aRep;
{
    id		value;
    int		h, v;
    NSSize	theSize;
    NSRect	bounds;
    
    myRep = aRep;
    h = [myRep pixelsHigh]; v = [myRep pixelsWide];
    theSize = [myRep size];
    bounds.origin.x = 0; bounds.origin.y = 0;
    bounds.size = theSize;
    value = [super initWithFrame: bounds];
    return self;
}

- (void)drawRect:(NSRect)aRect 
{
    NSEraseRect([self bounds]);
    if (myRep != nil) {
        [myRep draw];
        }
}


- (BOOL)isVerticallyCentered;
{
    return YES;
}

- (BOOL)isHorizontallyCentered;
{
    return YES;
}


- (void)dealloc {
    [myRep release];
    [super dealloc];
}

- (void) setBitmapPrintOperation: (NSPrintOperation *)aPrintOperation;
{
    myPrintOperation = aPrintOperation;
}

@end
