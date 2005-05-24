//
//  PrintBitmapView.h
//  TeXShop
//

#import <AppKit/NSView.h>

@interface PrintBitmapView : NSView 
{
    NSBitmapImageRep	*myRep;
    NSPrintOperation	*myPrintOperation;
}
    
- (PrintBitmapView *) initWithBitmapRep: (NSBitmapImageRep *) aRep;
- (void) setBitmapPrintOperation: (NSPrintOperation *)aPrintOperation;

@end
