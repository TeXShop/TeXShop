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
    rotationAmount = 0;
    largeMagnify = NO;
    
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
    int		pagenumber;
    NSRect	myBounds, myVisible, newVisible;


    if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
        
    if (myRep != nil) {
            
        if ([SUD boolForKey:NoScrollEnabledKey]) {
            pagenumber = [myRep currentPage];
            if (pagenumber > 0) {
                pagenumber--;
                [currentPage setIntValue: (pagenumber + 1)];
                [myRep setCurrentPage: pagenumber];
                [currentPage display];
                [self display];
                }
            }
        
        else {
            myBounds = [self bounds];
            myVisible = [self visibleRect];
            newVisible = myVisible;
            newVisible.origin.y = myVisible.origin.y + myVisible.size.height;
            if (newVisible.origin.y > (myBounds.size.height - myVisible.size.height)) 
                newVisible.origin.y = (myBounds.size.height - myVisible.size.height);
            if (! [self scrollRectToVisible:newVisible]) {
                pagenumber = [myRep currentPage];
                if (pagenumber > 0) {
                    pagenumber--;
                    [currentPage setIntValue: (pagenumber + 1)];
                    [myRep setCurrentPage: pagenumber];
                    [currentPage display];
                    newVisible = myVisible;
                    newVisible.origin.y = 0;
                    [self scrollRectToVisible:newVisible];
                        // [self display];
                    }
                }
            [self display];
            }
        }
}

- (void) firstPage: sender
{	
    int		pagenumber;

    if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
        
    if (myRep != nil) {
            
            pagenumber = 0;
            [currentPage setIntValue: (pagenumber + 1)];
            [myRep setCurrentPage: pagenumber];
            [currentPage display];
            [self display];
            }
}


- (void) up: sender
{	
    NSRect	myBounds, myVisible, newVisible;

    if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
        
    if (myRep != nil) {
            
            myBounds = [self bounds];
            myVisible = [self visibleRect];
            newVisible = myVisible;
            // newVisible.origin.y = myVisible.origin.y + myVisible.size.height;
            newVisible.origin.y = myVisible.origin.y + 20;
            if (newVisible.origin.y > (myBounds.size.height - myVisible.size.height)) 
                newVisible.origin.y = (myBounds.size.height - myVisible.size.height);
            [self scrollRectToVisible:newVisible];
            [self display];
            }
}

- (void) top: sender
{	
    NSRect	myBounds, myVisible, newVisible;

    if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
        
    if (myRep != nil) {
            
            myBounds = [self bounds];
            myVisible = [self visibleRect];
            newVisible = myVisible;
            newVisible.origin.y = (myBounds.size.height - myVisible.size.height);
            [self scrollRectToVisible:newVisible];
            [self display];
            }
}



- (void) nextPage: sender;
{	
    int		pagenumber;
    NSRect	myBounds, myVisible, newVisible;

    if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
        
    if (myRep != nil) {
            
        if ([SUD boolForKey:NoScrollEnabledKey]) {
            pagenumber = [myRep currentPage];
            if (pagenumber < ([myRep pageCount]) - 1) {
                pagenumber++;
                [currentPage setIntValue: (pagenumber + 1)];
                [myRep setCurrentPage: pagenumber];
                [currentPage display];
                [self display];
                }
            } 
        
        else {
            myBounds = [self bounds];
            myVisible = [self visibleRect];
            newVisible = myVisible;
            newVisible.origin.y = myVisible.origin.y - myVisible.size.height;
            if (newVisible.origin.y < 0) newVisible.origin.y = 0;
            if (! [self scrollRectToVisible:newVisible]) {
                pagenumber = [myRep currentPage];
                if (pagenumber < ([myRep pageCount]) - 1) {
                    pagenumber++;
                    [currentPage setIntValue: (pagenumber + 1)];
                    [myRep setCurrentPage: pagenumber];
                    [currentPage display];
                    newVisible = myVisible;
                    newVisible.origin.y = (myBounds.size.height - myVisible.size.height);
                    [self scrollRectToVisible:newVisible];
                    }
                }
            [self display];
            }
        }
}

- (void) lastPage: sender;
{	
    int		pagenumber;

    if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
        
    if (myRep != nil) {
            
            pagenumber = [myRep pageCount] - 1;
            [currentPage setIntValue: (pagenumber + 1)];
            [myRep setCurrentPage: pagenumber];
            [currentPage display];
            [self display];
            } 
}


- (void) down: sender
{	
    NSRect	myBounds, myVisible, newVisible;

    if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
        
    if (myRep != nil) {
            
            myBounds = [self bounds];
            myVisible = [self visibleRect];
            newVisible = myVisible;
            // newVisible.origin.y = myVisible.origin.y - myVisible.size.height;
            newVisible.origin.y = myVisible.origin.y - 20;
            if (newVisible.origin.y < 0) newVisible.origin.y = 0;
            [self scrollRectToVisible:newVisible];
            [self display];
            }
}

- (void) bottom: sender
{	
    NSRect	myBounds, myVisible, newVisible;

    if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
        
    if (myRep != nil) {
            
            myBounds = [self bounds];
            myVisible = [self visibleRect];
            newVisible = myVisible;
            newVisible.origin.y = 0;
            [self scrollRectToVisible:newVisible];
            [self display];
            }
}



- (void) goToPage: sender;
{	int		pagenumber;
        NSRect		myBounds, myVisible, newVisible;

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
            if (![SUD boolForKey:NoScrollEnabledKey]) {
                myBounds = [self bounds];
                myVisible = [self visibleRect];
                newVisible = myVisible;
                newVisible.origin.y = (myBounds.size.height - myVisible.size.height);
                [self scrollRectToVisible:newVisible];
                }
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
    [self changeScale: self];
}


- (double)magnification;
{
    double	magsize;
   
    magsize = [myScale intValue] / 100.0;
    return magsize;
}

/* 
WARNING: The code in setMagnification, and in RotateClockwise just below, is
tricky. The setFrame and setBounds commands send notifications to other
views to reset their bounds. These notifications are acted on AFTER setMagnification
completes. If these notifications incorrectly set various sizes, it is not
possible to fix those sizes inside setMagnification.

The commands below work, and were found after various unpleasant experiments
failed. If you change the code below, be sure to test carefully!
*/
- (void) setMagnification: (double)magSize;
{
        double	mag;
        NSRect	myBounds, newBounds;
        double	tempRotationAmount;
        
        NSScrollView *enclosingScrollView = [self enclosingScrollView];
        NSView *documentView = [enclosingScrollView documentView];
        
        tempRotationAmount = rotationAmount;
        rotationAmount = 0;
        [self fixRotation];
        rotationAmount = tempRotationAmount;
      
        myBounds = [self bounds];
        newBounds.size.width = myBounds.size.width * (magSize);
        newBounds.size.height = myBounds.size.height * (magSize);
        theMagSize = magSize;
        [documentView setFrame: newBounds];
        [documentView setBounds: myBounds];
        
        [self fixRotation];
        
        mag = round(magSize * 100.0);
        /* Warning: if the next line is changed to setIntValue, the magnification
            fails! */
        [myScale setDoubleValue: mag];
        // [myStepper setIntValue: mag];

        [[self superview] setNeedsDisplay:YES];
        [[self enclosingScrollView] setNeedsDisplay:YES];
        [self setNeedsDisplay:YES];
        

}


- (void) rotateClockwise:sender
{
    rotationAmount = rotationAmount - 90;
    if (rotationAmount < -90)
        rotationAmount = 180;
    [self fixRotation];
}


- (void) rotateCounterclockwise:sender
{
    rotationAmount = rotationAmount + 90;
    if (rotationAmount > 180)
        rotationAmount = -90;
    [self fixRotation];
}


- (void) fixRotation
{
    NSPoint	aPoint;
    NSRect	newBounds, selfBounds;
    double	width, height;
    
     NSScrollView *enclosingScrollView = [self enclosingScrollView];
     NSView *documentView = [enclosingScrollView documentView];
     
     selfBounds = [self bounds];
     width = selfBounds.size.width;
     height = selfBounds.size.height;
     
     [documentView setBoundsRotation: rotationAmount];

     switch (rotationAmount) {
        case 0: aPoint.x = 0; aPoint.y = 0;
                newBounds.size.width = width * theMagSize;
                newBounds.size.height = height * theMagSize;
                break;
        case 90: aPoint.x = 0; aPoint.y = height; 
                newBounds.size.width = height * theMagSize;
                newBounds.size.height = width * theMagSize;
                break;
        case 180: aPoint.x = width; aPoint.y = height; 
                newBounds.size.width = width * theMagSize;
                newBounds.size.height = height * theMagSize;
                break;
        case -90: aPoint.x = width; aPoint.y = 0;
                newBounds.size.width = height * theMagSize;
                newBounds.size.height = width * theMagSize;
        }
    [documentView setBoundsOrigin: aPoint];
    [documentView setFrameSize: newBounds.size];
     
    [self setNeedsDisplay:YES];
    [[self superview] setNeedsDisplay:YES];
    [[self enclosingScrollView] setNeedsDisplay:YES];

}


/*
WARNING: The code below attaches a pdf file to the pdf preview view.
There are three cases:
    a) This is the initial attachment
    b) This is a new version caused by typesetting again
    c) This is a new version caused by typesetting again and
        the bounds of the pdf file changed, perhaps because the
        user is experimenting with bounds in a slide package.
Cases b) and c) require care, because the user may have rotated and
magnified the image. The code for c) below handles this, but has
the unfortunate side effect of resetting the scrollers. Since b)
is the most common case and does not require resetting any bounds,
it is separated out for special minimal treatment to preserve
scroller position.
*/
- (void) setImageRep: (NSPDFImageRep *)theRep;
{
    int		pagenumber;
    NSRect	myBounds, newBounds;
    double	magsize;
    BOOL	modifiedRep = NO;
    double	newWidth, newHeight;
   
    NSScrollView *enclosingScrollView = [self enclosingScrollView];
    NSView *documentView = [enclosingScrollView documentView];

    magsize = [self magnification];
    theMagSize = magsize;
    [self renewGState];

    if (theRep != nil)
     
        {
        if (myRep != nil) {
            modifiedRep = YES;
            pagenumber = [myRep currentPage] + 1;
            [myRep release];
            }
        else
            pagenumber = 1;
        myRep = theRep;
        
        if ((imageType == isTeX) || (imageType == isPDF)) {
         
//            myBounds = [theRep bounds];
// mitsu change; the file dvipdfmx for Japanese users creates pdf files with nonzero origin, but the origin must
// be zero in TeXShop to draw correctly
            myBounds.origin.x = 0; myBounds.origin.y = 0;
            myBounds.size = [theRep bounds].size;
// end 
            
            newWidth = myBounds.size.width;
            newHeight = myBounds.size.height;
            [totalPage setIntValue: [myRep pageCount]];
            if (pagenumber < 1) pagenumber = 1;
            if (pagenumber > [myRep pageCount]) pagenumber = [myRep pageCount];
            [currentPage setIntValue: pagenumber];
            [currentPage display];
            [myRep setCurrentPage: (pagenumber - 1)];
            if (! modifiedRep) {
                // myBounds = [myRep bounds];
                // mitsu change
                myBounds.origin.x = 0; myBounds.origin.y = 0;
                myBounds.size = [myRep bounds].size;
                // end 

                oldWidth = myBounds.size.width;
                oldHeight = myBounds.size.height;
                newBounds.size.width = myBounds.size.width * (magsize);
                newBounds.size.height = myBounds.size.height * (magsize);
                [documentView setFrame: newBounds];
                [documentView setBounds: myBounds];
                // [self setMagnification: theMagSize];
                }
            else if ((abs(newHeight - oldHeight) > 1) || (abs(newWidth - oldWidth) > 1)) {
                oldWidth = newWidth;
                oldHeight = newHeight;
                newBounds.size.width = myBounds.size.width * (magsize);
                newBounds.size.height = myBounds.size.height * (magsize);
                [documentView setFrame: newBounds];
                [documentView setBounds: myBounds];
                [self setMagnification: theMagSize];
                }
            }
        else {
            [totalPage setIntValue: 1];
            [currentPage setIntValue: 1];
            [currentPage display];
            }
            
        [[self superview] setNeedsDisplay:YES];
        [[self enclosingScrollView] setNeedsDisplay:YES];
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

// added by mitsu --(I) Magnifying Glass
- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint mouseLocWindow, mouseLocView;
	NSRect oldBounds, newBounds, magRectWindow, magRectView, oldRect, diffRect;
	float minY, maxY;
	BOOL postNote, cursorVisible, commandDown = NO;
        
        // koch
        int	magWidth = 150;
        int	magHeight = 100;
        int	magOffsetX = magWidth/2;
        int	magOffsetY = magHeight/2;
        // end koch
	
#define magScale 	0.4	// you may want to change this

	// you may want to restrict the magnification
	//if (!([theEvent modifierFlags] & NSCommandKeyMask))
	//	return;
        
	postNote = [self postsBoundsChangedNotifications];
	[self setPostsBoundsChangedNotifications: NO];	// block the view from sending notification
	//[self lockFocus]; // the view is already focused, so it is not necessary to lock?
	
	oldBounds = [self bounds];
	oldRect.origin = [self convertPoint: [theEvent locationInWindow] fromView:nil];
	oldRect.size = NSMakeSize(0,0);
	cursorVisible = YES;
	
	do {
		if ([theEvent type]==NSLeftMouseDragged || [theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) 
                    {	
                        // koch
                         if (([theEvent modifierFlags] & NSCommandKeyMask)) {
                            if (! commandDown) {
                                largeMagnify = !largeMagnify;
                                if (largeMagnify) {
                                    magWidth = 380; magHeight = 250;}
                                else {
                                    magWidth = 150; magHeight = 100;}
                                commandDown = YES;
                            }
                        }
                        else 
                            commandDown = NO;
                        if (([theEvent modifierFlags] & NSAlternateKeyMask) && (! commandDown)) {
                            if (largeMagnify) {
                                magWidth = 150; magHeight = 100;}
                            else {
                                magWidth = 380; magHeight = 250;}
                            }
                        else {
                            if (largeMagnify) {
                                magWidth = 380; magHeight = 250;}
                            else {
                                magWidth = 150; magHeight = 100;}
                            }
                        magOffsetX = magWidth/2;
                        magOffsetY = magHeight/2;
                        // end koch
            
			// get Mouse location and check if it is with the view's rect
                        if (!([theEvent type]==NSFlagsChanged))
                            mouseLocWindow = [theEvent locationInWindow];
			mouseLocView = [self convertPoint: mouseLocWindow fromView:nil];
			// check if the mouse is in the rect
			if([self mouse:mouseLocView inRect:[self visibleRect]])
			{
				if (cursorVisible)
				{
					[NSCursor hide];
					cursorVisible = NO;
				}
				// define rect for magnification in window coordinate
				magRectWindow = NSMakeRect(mouseLocWindow.x-magOffsetX, mouseLocWindow.y-magOffsetY, 
											magWidth, magHeight);
				// resize bounds around mouseLocView
				newBounds = NSMakeRect(mouseLocView.x+magScale*(oldBounds.origin.x-mouseLocView.x), 
								mouseLocView.y+magScale*(oldBounds.origin.y-mouseLocView.y),
								magScale*(oldBounds.size.width), magScale*(oldBounds.size.height));
				[self setBounds: newBounds];
				// draw it in the rect
				magRectView = [self convertRect:magRectWindow fromView:nil];
				[self displayRect: magRectView];
				// reset bounds
				[self setBounds: oldBounds];
				magRectView = [self convertRect:magRectWindow fromView:nil];
				// clean up the trace
				diffRect.origin.x = oldRect.origin.x;
				diffRect.size.width = oldRect.size.width;
				if ((diffRect.size.height = magRectView.origin.y-oldRect.origin.y) > 0)
				{	// erase bottom
					diffRect.origin.y = oldRect.origin.y;
					[self displayRect: diffRect]; //NSIntegralRect()?
					minY = magRectView.origin.y;
				}
				else
					minY = oldRect.origin.y;
				if ((diffRect.size.height = oldRect.origin.y+oldRect.size.height
									-magRectView.origin.y-magRectView.size.height) > 0)
				{	// erase top
					diffRect.origin.y = magRectView.origin.y+magRectView.size.height;
					[self displayRect: diffRect]; //NSIntegralRect()?
					maxY = magRectView.origin.y+magRectView.size.height;
				}
				else
					maxY = oldRect.origin.y+oldRect.size.height;
				diffRect.origin.y = minY;
				diffRect.size.height = maxY-minY;
				if ((diffRect.size.width = magRectView.origin.x-oldRect.origin.x) > 0)
				{	// erase left
					diffRect.origin.x = oldRect.origin.x;
					[self displayRect: diffRect]; //NSIntegralRect()?
				}
				if ((diffRect.size.width = oldRect.origin.x+oldRect.size.width
											-magRectView.origin.x-magRectView.size.width) > 0)
				{	// erase right
					diffRect.origin.x = magRectView.origin.x+magRectView.size.width;
					[self displayRect: diffRect]; //NSIntegralRect()?
				}
				// remember the current rect
				oldRect = magRectView;
			}
			else
			{
				// mouse is not in the rect, show cursor and reset old rect
				if (!cursorVisible)
				{
					[NSCursor unhide];
					cursorVisible = YES;
				}
				[self displayRect: oldRect];
				oldRect.origin = mouseLocView;
				oldRect.size = NSMakeSize(0,0);
			}
		}
		else if ([theEvent type]==NSLeftMouseUp)
		{
			break;
		}
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
                NSLeftMouseDraggedMask | NSFlagsChangedMask];
	} while (YES);
	
	[NSCursor unhide];
	//[self unlockFocus];
	[self setPostsBoundsChangedNotifications: postNote];
	[self setNeedsDisplayInRect: oldRect];
}
// end addition



@end
