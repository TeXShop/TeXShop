//
//  PrintView.m
//  TeXShop
//
//  Originally part of MyDocument. Broken out by dirk on Tue Jan 09 2001.
//

#import <AppKit/AppKit.h>
#import "PrintView.h"

@implementation PrintView : NSView

- (PrintView *) initWithRep: (NSPDFImageRep *) aRep;
{
    id		value;
    
    myRep = aRep;
    value = [super initWithFrame: [myRep bounds]];
    return self;
}

- (void)drawRect:(NSRect)aRect 
{
    NSEraseRect([self bounds]);
    if (myRep != nil) {
        [myRep draw];
        }
}


- (BOOL) knowsPageRange:(NSRangePointer)range;
{
    (*range).location = 1;
    (*range).length = [myRep pageCount];
    return YES;
}

- (BOOL)isVerticallyCentered;
{
    return YES;
}

- (BOOL)isHorizontallyCentered;
{
    return YES;
}


- (NSRect)rectForPage:(int)pageNumber;
{
    int		thePage;
    NSRect	aRect;

    thePage = pageNumber;
    if (thePage < 1) thePage = 1;
    if (thePage > [myRep pageCount]) thePage = [myRep pageCount];
    [myRep setCurrentPage: thePage - 1];
    aRect = [myRep bounds];
    return aRect;
}


- (void)dealloc {
    [myRep release];
    [super dealloc];
}

- (void) setPrintOperation: (NSPrintOperation *)aPrintOperation;
{
    myPrintOperation = aPrintOperation;
}

@end
