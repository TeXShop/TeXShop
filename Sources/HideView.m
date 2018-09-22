//
//  OverView.m
//  TeXShop
//
//  Created by Richard Koch on 12/9/2017.
//  Copyright (c) 2017 Richard Koch. All rights reserved.
//


#import "HideView.h"

@implementation HideView


- (void) setSizeRect: (NSRect)theRect
{
    sizeRect = theRect;
}



- (void)drawRect:(NSRect) theRect
{
   //     [self lockFocus];
        [[NSGraphicsContext currentContext] setShouldAntialias: NO];
        //  [[NSColor redColor] set];
        //  NSRectFill(sizeRect);
        [self.originalImage drawInRect: sizeRect];
    //    [self unlockFocus];
}


@end





