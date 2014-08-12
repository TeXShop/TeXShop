/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2005 Richard
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * $Id: MyPDFKitViewGesture 261 2014-07-05 20:10:11Z richard_koch $
 *
 * Parts of this code are taken from Apple's example PDFKitViewer.
 *
 */
 
#import "MyPDFKitView.h"
#import "globals.h"
#import "OverView.h"



@implementation MyPDFKitView (Gesture)


/* Explanation: In Single Window or Double Window mode, TeXShop doesn't interact
 well with TrackPad Gestures. A gesture will change the page, but not with a lot of
 feedback. 
 
 But Apple's Preview behaves beautifully. A gesture pulls down the next page part
 way. If it is pulled down enough, it slides into place. Otherwise it slides back up.
 This only happens if the full page is showing. Otherwise there are (possibly invisible)
 scroll bars and the gestures scrolls around the single page.
 
 Unfortunately, PDFKit does not expose this feature for third party programs.
 
 This source is an attempt to implement it. The gesture does indeed produce
 "beginGesture" and "endGesture" calls, but then some other part of PDFKit captures
 the gesture and thus intermediate touches do not reach this code. I attempted
 to override NSScrollView and NSClipView and [self documentView] without success,
 so I don't know where those gesture commands are going.
 
 This code remains "just in case".
 */


/*
- (void)beginGestureWithEvent:(NSEvent *)event
{
    PDFDisplayMode  displayMode;
    NSRect          aRect;
    NSSet           *myTouches;
    
    aRect.origin.x = 300;
    aRect.origin.y = 300;
    aRect.size.height = 200;
    aRect.size.width = 200;
    
     displayMode = [self displayMode];
    if ((displayMode != kPDFDisplaySinglePage) && (displayMode != kPDFDisplayTwoUp)) {
        [super beginGestureWithEvent:event];
        return;
    }
    
    
  //   NSLog(@"now here");
   //  NSView *theView = [[self window] contentView];
  //   NSView *theView = [[[[self superview] superview] superview] superview];
  //  NSLog(@"%@", [theView class]);
    
    [self wantsForwardedScrollEventsForAxis:NSEventGestureAxisVertical];
    
    OverView *theOverView = [[OverView alloc] initWithFrame: [[self documentView] frame] ] ;
    [self setOverView: theOverView];
    [[self documentView] addSubview: [self overView]];
    [[self overView] setDrawRubberBand: YES];
    [[self overView] setSelectionRect: aRect];
    // [[self overView] displayRect: [[self documentView] visibleRect]];
    [[self overView] setNeedsDisplayInRect:[[self documentView] visibleRect]];
     self.waiting = YES;
   
    [NSEvent stopPeriodicEvents];
     [self wantsForwardedScrollEventsForAxis:NSEventGestureAxisVertical];
    [NSEvent startPeriodicEventsAfterDelay: 0 withPeriod: 0.2];

    
//    [super beginGestureWithEvent:event];
}
    
- (void)touchesBeganWithEvent:(NSEvent *)event
{
    
    NSLog(@"touches");
    
    if (! self.waiting)
        [super touchesMovedWithEvent:event];
    else
        NSLog(@"that was a touch move");
}


- (void)endGestureWithEvent:(NSEvent *)event
{
    PDFDisplayMode  displayMode;
    
    displayMode = [self displayMode];
    if ((displayMode != kPDFDisplaySinglePage) && (displayMode != kPDFDisplayTwoUp)) {
        [super endGestureWithEvent:event];
        return;
    }
    
    NSLog(@"also here");
    
    self.waiting = NO;
//  [NSEvent stopPeriodicEvents];
    OverView *theOverView = [self overView];
    if (theOverView) {
        [theOverView removeFromSuperview];
        [self setOverView: nil];
    }
//    [self nextPage: self];
//    [super beginGestureWithEvent:event];
    
}
*/


@end
