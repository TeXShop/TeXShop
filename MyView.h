//
//  MyView.h
//  TeXShop
//
//  Originally part of My Document. Broken out dirk on Tue Jan 09 2001.
//

#import <AppKit/NSView.h>

@class MyDocument;

@interface MyView : NSView 
{
    id			currentPage;
    id			totalPage;
    id			myScale;
    int			imageType;
    double		oldMagnification;
    BOOL		fixScroll;
    NSPDFImageRep	*myRep;
    MyDocument		*myDocument;
}

- (void) setImageType: (int)theType;    
- (void) previousPage: sender;
- (void) nextPage: sender;
- (void) goToPage: sender;
- (void) setImageRep: (NSPDFImageRep *)theRep;
- (void) changeScale: sender;
- (double) magnification;
- (void) setMagnification: (double) magSize;
- (void) resetMagnification;
- (void) printDocument: sender;
- (void) setDocument: (id) theDocument;
@end
