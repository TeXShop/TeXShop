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
    id			currentPage1;
    id			totalPage;
    id			totalPage1;
    id			myScale;
    id			myScale1;
    id			myStepper;
    id			myStepper1;
    int			imageType;
    double		oldMagnification;
    double		oldWidth, oldHeight;
    BOOL		fixScroll;
    NSPDFImageRep	*myRep;
    MyDocument		*myDocument;
    int			rotationAmount;  // will be 0, 90, -90, 180
    double		theMagSize;
    BOOL		largeMagnify; // for magnifying glass
}

- (void) setImageType: (int)theType;    
- (void) previousPage: sender;
- (void) nextPage: sender;
- (void) firstPage: sender;
- (void) lastPage: sender;
- (void) goToPage: sender;
- (void) doStepper: sender;
- (void) setImageRep: (NSPDFImageRep *)theRep;
- (void) changeScale: sender;
- (double) magnification;
- (void) setMagnification: (double) magSize;
- (void) resetMagnification;
- (void) printDocument: sender;
- (void) setDocument: (id) theDocument;
- (void) rotateClockwise:sender;
- (void) rotateCounterclockwise:sender;
- (void) fixRotation;
- (void) up: sender;
- (void) down: sender;
- (void) top: sender;
- (void) bottom: sender;
@end
