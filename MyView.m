//
//  MyView.m
//  TeXShop
//
//  Originally part of MyDocument. Broken out by dirk on Tue Jan 09 2001.
//

#import <AppKit/AppKit.h>
#import "MyView.h"
#import "MyDocument.h"
#import "globals.h"

#define SUD [NSUserDefaults standardUserDefaults]

@implementation MyView : NSView

- (void) setImageType: (int)theType;
{
    imageType = theType;
}

- (id)initWithFrame:(NSRect)frameRect
{
    id		value;
    
    value = [super initWithFrame: frameRect];
    [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(changeMagnification:) 
            name:MagnificationChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(rememberMagnification:) 
            name:MagnificationRememberNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(revertMagnification:) 
            name:MagnificationRevertNotification object:nil];
    fixScroll = NO;
    myRep = nil;
    
    return value;
}

- (void)resetMagnification;
{
    double	theMagnification;
    int		mag;
    
    theMagnification = [SUD floatForKey:PdfMagnificationKey];
    
    if (theMagnification != [self magnification]) 
        [self setMagnification: theMagnification];
    
    mag = round(theMagnification * 100.0);
    [myStepper setIntValue: mag];
}

- (void)changeMagnification:(NSNotification *)aNotification;
{
    [self resetMagnification];
}

- (void)rememberMagnification:(NSNotification *)aNotification;
{
    oldMagnification = [self magnification];
}
    
- (void) revertMagnification:(NSNotification *)aNotification;
{
    if (oldMagnification != [self magnification])
        [self setMagnification: oldMagnification];
} 

- (void)drawRect:(NSRect)aRect 
{
    if (myRep != nil) {
        if ((imageType == isTeX) || (imageType == isPDF)) {
            [totalPage setIntValue: [myRep pageCount]];
            [currentPage setIntValue: ([myRep currentPage] + 1)]; /* dirk; yes, this line is correct */
            [currentPage display];
            NSEraseRect([self bounds]);
            [myRep draw];
            }
    else if ((imageType == isTIFF) || (imageType == isJPG)) {
            [currentPage display];
            NSEraseRect([self bounds]);
            [myRep draw];
            }
        }
}

- (void) previousPage: sender
{	
    int	pagenumber;

        if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
        
        if (myRep != nil) {
            pagenumber = [myRep currentPage];
            if (pagenumber > 0) {
                pagenumber--;
                [currentPage setIntValue: (pagenumber + 1)];
                [myRep setCurrentPage: pagenumber];
                [currentPage display];
                [self display];
                }
            }
}

- (void) nextPage: sender;
{	
    int	pagenumber;

        if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;

        if (myRep != nil) {
            pagenumber = [myRep currentPage];
            if (pagenumber < ([myRep pageCount]) - 1) {
                pagenumber++;
                [currentPage setIntValue: (pagenumber + 1)];
                [myRep setCurrentPage: pagenumber];
                [currentPage display];
                [self display];
                }
            }
}

- (void) goToPage: sender;
{	int	pagenumber;

        if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) {
            [currentPage setIntValue: 1];
            [currentPage display];
            return;
            }

        if (myRep != nil) {
            pagenumber = [currentPage intValue];
            if (pagenumber < 1) pagenumber = 1;
            if (pagenumber > [myRep pageCount]) pagenumber = [myRep pageCount];
            [currentPage setIntValue: pagenumber];
            [currentPage display];
            [myRep setCurrentPage: (pagenumber - 1)];
            [self display];
            }
}

- (void) changeScale: sender;
{
    int		scale;
    double	magSize;
    
    scale = [myScale intValue];
    if (scale < 20) {
        scale = 20;
        [myScale setIntValue: scale];
        [myScale display];
        }
    if (scale > 400) {
        scale = 400;
        [myScale setIntValue: scale];
        [myScale display];
        }
    [myStepper setIntValue: scale];
    magSize = [self magnification];
    [self setMagnification: magSize];
}

- (void) doStepper: sender;
{
    [myScale setIntValue: [myStepper intValue]];
    [myScale display];
    [self changeScale: self];
}


- (double)magnification;
{
    double	magsize;
   
    magsize = [myScale intValue] / 100.0;
    return magsize;
}

- (void) setMagnification: (double)magSize;
{
    
        NSRect	myBounds, newBounds;
        int	mag;
        
        myBounds = [self bounds];
        newBounds.size.width = myBounds.size.width * (magSize);
        newBounds.size.height = myBounds.size.height * (magSize);
        [self setFrame: newBounds];
        [self setBounds: myBounds];
        mag = round(magSize * 100.0);
        /* Warning: if the next line is changed to setIntValue, the magnification
            fails! */
        [myScale setDoubleValue: mag];
        [myStepper setIntValue: mag];
        
        [[self superview] setNeedsDisplay:YES];
        [self setNeedsDisplay:YES];
        /*
        if ((imageType == isTeX) || (imageType == isPDF)) {
             [self setNeedsDisplay:YES];
             }
        else if ((imageType == isTIFF) || (imageType == isJPG))
            [self setNeedsDisplay:YES];
        */
}




- (void) setImageRep: (NSPDFImageRep *)theRep;
{
    int		pagenumber;
    NSRect	myBounds, newBounds;
    
    double	magsize;
   
    magsize = [self magnification];

    if (theRep != nil)
     
        {
        if (myRep != nil) {
            pagenumber = [myRep currentPage] + 1;
            [myRep release];
            }
        else
            pagenumber = 1;
        myRep = theRep;
        
        if ((imageType == isTeX) || (imageType == isPDF)) {   
            [totalPage setIntValue: [myRep pageCount]];
            if (pagenumber < 1) pagenumber = 1;
            if (pagenumber > [myRep pageCount]) pagenumber = [myRep pageCount];
            [currentPage setIntValue: pagenumber];
            [currentPage display];
            [myRep setCurrentPage: (pagenumber - 1)];
            myBounds = [myRep bounds];
            newBounds.size.width = myBounds.size.width * (magsize);
            newBounds.size.height = myBounds.size.height * (magsize);
            [self setFrame: newBounds];
            [self setBounds: myBounds];
            }
        else {
            [totalPage setIntValue: 1];
            [currentPage setIntValue: 1];
            [currentPage display];
            }
        
        [[self superview] setNeedsDisplay:YES];
        [self setNeedsDisplay:YES];
        }
}

- (void) printDocument: sender;
{
    [myDocument printDocument: sender];
}	

- (void) printSource: sender;
{
    [myDocument printSource: sender];
}

- (void) setDocument: (id) theDocument;
{
    myDocument = theDocument;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];       
    [super dealloc];
}


@end
