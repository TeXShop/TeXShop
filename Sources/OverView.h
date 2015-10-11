//
//  OverView.h
//  TeXShop
//
//  Created by Richard Koch on 6/8/13.
//  Copyright (c) 2013 Richard Koch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>




@interface OverView : NSView
{
    NSRect          theSelectionRect;
    NSRect          magnifiedRect;
    BOOL            drawRubberBand;
    BOOL            drawMagnifiedRect;
    BOOL            drawMagnifiedImage;
}

@property (retain) NSImage *magnifiedImage;

// - (void) dealloc;
- (void) setDrawRubberBand: (BOOL)value;
- (void) setDrawMagnifiedRect: (BOOL)value;
- (void) setSelectionRect: (NSRect) theRect;
- (void) setMagnifiedRect: (NSRect) theRect;
- (void) setDrawMagnifiedImage: (BOOL)value;


@end
