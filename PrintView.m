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
    // mitsu change; in Japan, dvipdfmx creates pdf files with nonzero origin
    // value = [super initWithFrame: [myRep bounds]];
    value = [super initWithFrame: NSMakeRect(0, 0, [myRep bounds].size.width, [myRep bounds].size.height)];
    // end
    return self;
}

- (void)drawRect:(NSRect)aRect 
{
//    NSEraseRect([self bounds]);
    NSRect  myRect;
    
    myRect = [self bounds];
    NSPrintInfo *pi = [[NSPrintOperation currentOperation] printInfo];
    float scale = [[[pi dictionary] objectForKey:NSPrintScalingFactor]
                    floatValue];
    myRect.size.height = myRect.size.height * scale;
    myRect.size.width = myRect.size.width * scale;
    
    if (myRep != nil) {
//        [myRep draw];
          [myRep drawInRect: myRect];
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
    // mitsu; see above
    // aRect = [myRep bounds];
    aRect.origin.x = 0; aRect.origin.y = 0;
    aRect.size = [myRep bounds].size;
    
    NSPrintInfo *pi = [[NSPrintOperation currentOperation] printInfo];
    float scale = [[[pi dictionary] objectForKey:NSPrintScalingFactor]
                    floatValue];
    aRect.size.height = aRect.size.height * scale;
    aRect.size.width = aRect.size.width * scale;
    
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
