//
//  OverView.m
//  TeXShop
//
//  Created by Richard Koch on 6/8/13.
//  Copyright (c) 2013 Richard Koch. All rights reserved.
//


#import "OverView.h"

@implementation OverView

- (void) setSelectionRect: (NSRect) theRect
{
    theSelectionRect = theRect;
}

- (void) setDrawRubberBand: (BOOL)value
{
    drawRubberBand = value;
}

- (void) setDrawMagnifiedRect: (BOOL)value
{
    drawMagnifiedRect = value;
}

- (void)drawRect:(NSRect) theRect
{
    if (drawRubberBand) {
        NSBezierPath    *path;
        path = [NSBezierPath bezierPath];
        [path setLineWidth: 0.01];
        theSelectionRect.origin.y = theSelectionRect.origin.y;
        [path appendBezierPathWithRect: theSelectionRect];
    
        [self lockFocus];
        [[NSGraphicsContext currentContext] setShouldAntialias: NO];
        [[NSColor blackColor] set];
        [path stroke];
        [self unlockFocus];
    }
    else if (drawMagnifiedRect) {
        NSBezierPath    *path;
        path = [NSBezierPath bezierPath];
        [path setLineWidth: 0.01];
        theSelectionRect.origin.y = theSelectionRect.origin.y;
        [path appendBezierPathWithRect: theSelectionRect];
        
        [self lockFocus];
        [[NSGraphicsContext currentContext] setShouldAntialias: NO];
        [[NSColor redColor] set];
        [path fill];
        NSRectFill(theSelectionRect);
        [self unlockFocus];
    }
}

@end





