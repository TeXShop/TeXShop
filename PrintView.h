//
//  PrintView.h
//  TeXShop
//
//  Originally part of MyDocument. Broken out by dirk on Tue Jan 09 2001.
//

#import <AppKit/NSView.h>

@interface PrintView : NSView 
{
    NSPDFImageRep	*myRep;
    NSPrintOperation	*myPrintOperation;
}
    
- (PrintView *) initWithRep: (NSPDFImageRep *) aRep;
- (void) setPrintOperation: (NSPrintOperation *)aPrintOperation;
- (BOOL) knowsPageRange:(NSRangePointer)range;
@end
