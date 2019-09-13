//
//  MyPDFKitView-Magnification.m
//  TeXShop
//
//  Created by Richard Koch on 10/11/15.
//
//

#import "MyPDFKitView.h"

#define NSAppKitVersionNumber10_10_Max 1349

@implementation MyPDFKitView (Magnification)


- (void)doMagnifyingGlass:(NSEvent *)theEvent level: (NSInteger)level
{
    
    // Use new Magnifying Glass Routine on Lion, Mountain Lion, and Mavericks. It works in all these places
    // and the old routine has problems in all of these places.
    
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7)
        //        [self doMagnifyingGlassML: theEvent level:level] ;
        return;
    
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_10_Max)
    {
        [self doMagnifyingGlassMavericks: theEvent level:level] ;
        return;
    }
    
    [self doMagnifyingGlassElCapitanNew: theEvent level:level] ;
    return;
    
}



// Routine for Mavericks
// -------------------------------------------------------------------------

- (void)doMagnifyingGlassMavericks:(NSEvent *)theEvent level: (NSInteger)level
{
    NSPoint mouseLocWindow, mouseLocView, mouseLocDocumentView;
    NSRect magRectWindow, tempRect;
    BOOL cursorVisible;
    CGFloat magWidth = 0.0, magHeight = 0.0, magOffsetX = 0.0, magOffsetY = 0.0;
    NSInteger originalLevel, currentLevel = 0.0;
    CGFloat magScale = 2.5; // 4.0
    
    NSData          *thePDFData;
    NSPDFImageRep   *thePDFImageRep;
    NSImage         *theImage;
    NSRect          theOriginalRect;
    
    
    cursorVisible = YES;
    originalLevel = level+[theEvent clickCount];
    
    OverView *theOverView = [[OverView alloc] initWithFrame: [[self documentView] frame] ];
    [self setOverView: theOverView];
    [[self documentView] addSubview: [self overView]];
    
    tempRect = [[self documentView] visibleRect];
    thePDFData = [[self documentView] dataWithPDFInsideRect:[[self documentView] visibleRect]];
    
    thePDFImageRep = [NSPDFImageRep imageRepWithData: thePDFData];
    theImage = [[NSImage alloc] initWithData: thePDFData];
    
    [[self overView] setMagnifiedImage: theImage];
    
    
    do {
        
        if ([theEvent type]==NSLeftMouseDragged || [theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) {
            
            // set up the size and magScale
            if ([theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) {
                currentLevel = originalLevel+(([theEvent modifierFlags] & NSAlternateKeyMask)?1:0);
                if (currentLevel <= 1) {
                    magWidth = 150; magHeight = 100;
                    magOffsetX = magWidth/2; magOffsetY = magHeight/2;
                } else if (currentLevel == 2) {
                    magWidth = 380; magHeight = 250;
                    magOffsetX = magWidth/2; magOffsetY = magHeight/2;
                } else {
                    magWidth = 1800; magHeight = 1500;
                    magOffsetX = magWidth / 2; magOffsetY = magHeight / 2;
                }
            }
            
            // get Mouse location and check if it is with the view's rect
            
            if (!([theEvent type]==NSFlagsChanged)) {
                mouseLocWindow = [theEvent locationInWindow];
                mouseLocView = [self convertPoint: mouseLocWindow fromView:nil];
                mouseLocDocumentView = [[self documentView] convertPoint: mouseLocWindow fromView:nil];
            }
            // check if the mouse is in the rect
            
            if([self mouse:mouseLocView inRect:[self visibleRect]]) {
                if (cursorVisible) {
                    [NSCursor hide];
                    cursorVisible = NO;
                }
				            
                magRectWindow = NSMakeRect(mouseLocDocumentView.x-magOffsetX, mouseLocDocumentView.y-magOffsetY,
                                           magWidth, magHeight);
                theOriginalRect = NSMakeRect(mouseLocDocumentView.x - tempRect.origin.x - magOffsetX / magScale,
                                             mouseLocDocumentView.y - tempRect.origin.y - magOffsetY / magScale,
                                             magWidth / magScale, magHeight / magScale);
                
                
                [[self overView] setDrawRubberBand: NO];
                [[self overView] setDrawMagnifiedRect: NO];
                [[self overView] setDrawMagnifiedImage: YES];
                [[self overView] setSelectionRect: magRectWindow];
                [[self overView] setMagnifiedRect: theOriginalRect];
                [[self overView] setNeedsDisplayInRect: [[self documentView] visibleRect]];
                
                
            } else { // mouse is not in the rect
                // show cursor
                if (!cursorVisible) {
                    [NSCursor unhide];
                    cursorVisible = YES;
                }
            }
            
        } else if ([theEvent type] == NSLeftMouseUp) {
            break;
        }
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseDownMask | NSLeftMouseUpMask |
                    NSLeftMouseDraggedMask | NSFlagsChangedMask];
    } while (YES);
    
    if (theOverView) {
        [theOverView removeFromSuperview];
        [self setOverView: nil];
    }
    
    [NSCursor unhide];
    [self flagsChanged: theEvent]; // update cursor
    
}


// Routine for El Capitan
- (void)doMagnifyingGlassElCapitanNew:(NSEvent *)theEvent level: (NSInteger)level
{
    
    NSPoint mouseLocWindow, mouseLocView, mouseLocDocumentView;
    NSRect magRectWindow, tempRect, theOriginalRect, thePageOriginalRect;
    BOOL cursorVisible;
    CGFloat magWidth = 0.0, magHeight = 0.0, magOffsetX = 0.0, magOffsetY = 0.0;
    NSInteger originalLevel, currentLevel = 0.0;
    CGFloat magScale = 2.5; // 4.0
    magScale = 1.5;
    NSPoint pageLowerLeft, viewLowerLeft;
    
    tempRect = [[self documentView] visibleRect];
    cursorVisible = YES;
    originalLevel = level+[theEvent clickCount];
    
    OverView *theOverView = [[OverView alloc] initWithFrame: [[self documentView] frame] ];
    [self setOverView: theOverView];
    [[self documentView] addSubview: [self overView]];
    
    NSPoint myLocation = [[self window] mouseLocationOutsideOfEventStream];
    myLocation = [self convertPoint: myLocation fromView:nil];
    PDFPage *myPage = [self pageForPoint: myLocation nearest:YES];
    NSData	*myData = [myPage dataRepresentation];
    NSImage *myImageNew = [[NSImage alloc] initWithData: myData];
    pageLowerLeft.x = 0; pageLowerLeft.y = 0;
    viewLowerLeft = [self convertPoint:pageLowerLeft fromPage: myPage];
    // NSLog(@"Page LowerLeft %f and %f", viewLowerLeft.x, viewLowerLeft.y);
    
    
    do {
        
        if ([theEvent type]==NSLeftMouseDragged || [theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) {
            
            // set up the size and magScale
            if ([theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) {
                currentLevel = originalLevel; // +(([theEvent modifierFlags] & NSAlternateKeyMask)?1:0);
                if (currentLevel <= 1) {
                    magWidth = 150; magHeight = 100;
                    magOffsetX = magWidth/2; magOffsetY = magHeight/2;
                } else if (currentLevel == 2) {
                    magWidth = 380; magHeight = 250;
                    magOffsetX = magWidth/2; magOffsetY = magHeight/2;
                } else {
                    magWidth = 1800; magHeight = 1500;
                    magOffsetX = magWidth / 2; magOffsetY = magHeight / 2;
                }
            }
            
            if (!([theEvent modifierFlags] & NSShiftKeyMask)) {
                if ([theEvent modifierFlags] & NSCommandKeyMask)
                    magScale = 2.0; 	// x4
                else if ([theEvent modifierFlags] & NSAlternateKeyMask)
                    magScale = 2.5; // x1.5
                else if ([theEvent modifierFlags] & NSControlKeyMask)
                    magScale = 3.0; // x1.5
                else
                    magScale = 1.5; 	// x2.5
            } else { // shrink the image with shift key -- can be very slow
                if ([theEvent modifierFlags] & NSCommandKeyMask)
                    magScale = 1.0; 	// x4
                else if ([theEvent modifierFlags] & NSAlternateKeyMask)
                    magScale = .66666; // x1.5
                else if ([theEvent modifierFlags] & NSControlKeyMask)
                    magScale = .50000; // x1.5
                else
                    magScale = 1.5; 	// x2.5
            }

            
            // get Mouse location and check if it is with the view's rect
            
            if (!([theEvent type]==NSFlagsChanged)) {
                mouseLocWindow = [theEvent locationInWindow];
                mouseLocView = [self convertPoint: mouseLocWindow fromView:nil];
                mouseLocDocumentView = [[self documentView] convertPoint: mouseLocWindow fromView:nil];
            }
            // check if the mouse is in the rect
            
            if([self mouse:mouseLocView inRect:[self visibleRect]]) {
                if (cursorVisible) {
                    [NSCursor hide];
                    cursorVisible = NO;
                }
                
                magRectWindow = NSMakeRect(mouseLocDocumentView.x-magOffsetX, mouseLocDocumentView.y-magOffsetY,
                                           magWidth, magHeight);
                /*
                 theOriginalRect = NSMakeRect(mouseLocDocumentView.x - tempRect.origin.x  - magOffsetX / magScale,
                 mouseLocDocumentView.y - tempRect.origin.y  - magOffsetY / magScale,
                 magWidth / magScale, magHeight / magScale);
                 */
                theOriginalRect.origin.x = mouseLocView.x  - magOffsetX / magScale; theOriginalRect.origin.y = mouseLocView.y - magOffsetY / magScale;
                theOriginalRect.size.width = magWidth / magScale; theOriginalRect.size.height = magHeight / magScale;
                
                thePageOriginalRect = [self convertRect: theOriginalRect toPage: myPage];
                
                
                [[self overView] setDrawRubberBand: NO];
                [[self overView] setDrawMagnifiedRect: NO];
                [[self overView] setDrawMagnifiedImage: YES];
                [[self overView] setSelectionRect: magRectWindow];
                [[self overView] setMagnifiedRect: thePageOriginalRect];
                [[self overView] setMagnifiedImage: myImageNew];
                [[self overView] setNeedsDisplayInRect: [[self documentView] visibleRect]];
                
                
            } else { // mouse is not in the rect
                // show cursor
                if (!cursorVisible) {
                    [NSCursor unhide];
                    cursorVisible = YES;
                }
            }
            
        } else if ([theEvent type] == NSLeftMouseUp) {
            break;
        }
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
                    NSLeftMouseDraggedMask | NSFlagsChangedMask];
    } while (YES);
    
    if (theOverView) {
        [theOverView removeFromSuperview];
        [self setOverView: nil];
    }
    
    [NSCursor unhide];
    [self flagsChanged: theEvent]; // update cursor
    
}



// Routine for Mountain Lion and lower; now obsolete and never called
// -------------------------------------------------------------------------

- (void)doMagnifyingGlassML:(NSEvent *)theEvent level: (NSInteger)level
{
    NSPoint mouseLocWindow, mouseLocView, mouseLocDocumentView;
    NSRect oldBounds, newBounds, magRectWindow, magRectView;
    BOOL postNote, cursorVisible;
    CGFloat magWidth = 0.0, magHeight = 0.0, magOffsetX = 0.0, magOffsetY = 0.0;
    NSInteger originalLevel, currentLevel = 0.0;
    CGFloat magScale = 0.0; 	//0.4	// you may want to change this
    
    postNote = [[self documentView] postsBoundsChangedNotifications];
    [[self documentView] setPostsBoundsChangedNotifications: NO];
    
    oldBounds = [[self documentView] bounds];
    cursorVisible = YES;
    originalLevel = level+[theEvent clickCount];
    
    //[self cleanupMarquee: NO];
    rect = NSMakeRect(0, 0, 1, 1); // [[self window] discardCachedImage]; // make sure not use the cached image
    
    [[self window] disableFlushWindow];
    
    do {
        
        if ([theEvent type]==NSLeftMouseDragged || [theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) {
            
            // [[self window] disableFlushWindow];
            
            // set up the size and magScale
            if ([theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) {
                currentLevel = originalLevel+(([theEvent modifierFlags] & NSAlternateKeyMask)?1:0);
                if (currentLevel <= 1) {
                    magWidth = 150; magHeight = 100;
                    magOffsetX = magWidth/2; magOffsetY = magHeight/2;
                } else if (currentLevel == 2) {
                    magWidth = 380; magHeight = 250;
                    magOffsetX = magWidth/2; magOffsetY = magHeight/2;
                } else { // currentLevel >= 3 // need to cache the image
                    [self updateBackground: rect]; // [[self window] restoreCachedImage];
                    // [[self window] cacheImageInRect:[self convertRect:[self visibleRect] toView: nil]];
                    rect = [self visibleRect];
                }
                if (!([theEvent modifierFlags] & NSShiftKeyMask)) {
                    if ([theEvent modifierFlags] & NSCommandKeyMask)
                        magScale = 0.25; 	// x4
                    else if ([theEvent modifierFlags] & NSControlKeyMask)
                        magScale = 0.66666; // x1.5
                    else
                        magScale = 0.4; 	// x2.5
                } else { // shrink the image with shift key -- can be very slow
                    if ([theEvent modifierFlags] & NSCommandKeyMask)
                        magScale = 4.0; 	// /4
                    else if ([theEvent modifierFlags] & NSControlKeyMask)
                        magScale = 1.5; 	// /1.5
                    else
                        magScale = 2.5; 	// /2.5
                }
            }
            // get Mouse location and check if it is with the view's rect
            
            if (!([theEvent type]==NSFlagsChanged))
                mouseLocWindow = [theEvent locationInWindow];
            mouseLocView = [self convertPoint: mouseLocWindow fromView:nil];
            mouseLocDocumentView = [[self documentView] convertPoint: mouseLocWindow fromView:nil];
            // check if the mouse is in the rect
            
            if([self mouse:mouseLocView inRect:[self visibleRect]]) {
                if (cursorVisible) {
                    [NSCursor hide];
                    cursorVisible = NO;
                }
                // define rect for magnification in window coordinate
                if (currentLevel >= 3) { // mitsu 1.29 (S5) set magRectWindow here
                    magRectWindow = [self convertRect:[self visibleRect] toView:nil];
                    rect = [self visibleRect];
                } else { // currentLevel <= 2
                    magRectWindow = NSMakeRect(mouseLocWindow.x-magOffsetX, mouseLocWindow.y-magOffsetY,
                                               magWidth, magHeight);
                    // restore the cached image in order to clear the rect
                    [self updateBackground:rect]; // [[self window] restoreCachedImage];
                    // [[self window] cacheImageInRect:
                    //	NSIntersectionRect(NSInsetRect(magRectWindow, -2, -2),
                    //					   [[self superview] convertRect:[[self superview] bounds]
                    //
                    rect = NSIntersectionRect(NSInsetRect(magRectWindow, -2, -2), [[self superview] convertRect:[[self superview] bounds]  toView:nil]); // mitsu 1.29b
                    rect = [self convertRect: rect fromView: nil];
                }
                // draw marquee
                if (self.selRectTimer)
                    [self updateMarquee: nil];
                
                // resize bounds around mouseLocView
                newBounds = NSMakeRect(mouseLocDocumentView.x+magScale*(oldBounds.origin.x-mouseLocDocumentView.x),
                                       mouseLocDocumentView.y+magScale*(oldBounds.origin.y-mouseLocDocumentView.y),
                                       magScale*(oldBounds.size.width), magScale*(oldBounds.size.height));
                
                // mitsu 1.29 (S1) fix for rotated view
                
                [[self documentView] setBounds: newBounds];
                magRectView = NSInsetRect([self convertRect:magRectWindow fromView:nil],1,1);
                [self displayRect: magRectView]; // this flushes the buffer
                // reset bounds
                [[self documentView] setBounds: oldBounds];
                
            } else { // mouse is not in the rect
                // show cursor
                if (!cursorVisible) {
                    [NSCursor unhide];
                    cursorVisible = YES;
                }
                // restore the cached image in order to clear the rect
                // [self updateBackground: rect]; // [[self window] restoreCachedImage];
                [self updateBackground:rect];
                // autoscroll
                if (!([theEvent type]==NSFlagsChanged))
                    [self autoscroll: theEvent];
                if (currentLevel >= 3)
                    ; // [[self window] cacheImageInRect:magRectWindow];
                else
                    rect = NSMakeRect(0, 0, 1, 1); // [[self window] discardCachedImage];
            }
            
            [[self window] enableFlushWindow];
            [[self window] flushWindow];
            [[self window] disableFlushWindow];
            
        } else if ([theEvent type] == NSLeftMouseUp) {
            break;
        }
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
                    NSLeftMouseDraggedMask | NSFlagsChangedMask];
    } while (YES);
    
    [[self window] enableFlushWindow];
    
    
    [self updateBackground:rect]; // [[self window] restoreCachedImage];
    // [[self window] flushWindow];
    [NSCursor unhide];
    [[self documentView] setPostsBoundsChangedNotifications: postNote];
    [self flagsChanged: theEvent]; // update cursor
    // recache the image around marquee for quicker response
    oldVisibleRect.size.width = 0;
    [self cleanupMarquee: NO];
    [self recacheMarquee];
    // The line below was added to clean up marks in gray border
    // QUESTIONABLE_BUG_FIX
    [[self window] display];
    
}
// end Magnifying Glass
//
// End of special routines for Mountain Lion and below
// -----------------------------------------------------------------




@end
