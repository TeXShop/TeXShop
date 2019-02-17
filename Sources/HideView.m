//
//  OverView.m
//  TeXShop
//
//  Created by Richard Koch on 12/9/2017.
//  Copyright (c) 2017 Richard Koch. All rights reserved.
//


#import "HideView.h"


@implementation HideView

/*
- (void)dealloc
{
  [self.originalImage recache];
 //   self.originalImage = nil;
    if (self.originalImage)
        NSLog(@"bad");
    NSLog(@"releasing");
}
*/


- (void) setSizeRect: (NSRect)theRect
{
    sizeRect = theRect;
}




- (void)drawRect:(NSRect) theRect
{
    //   [self lockFocus];
    //    [[NSGraphicsContext currentContext] setShouldAntialias: NO];
    
        if (self.originalImage)
             [self.originalImage drawInRect: sizeRect];
    
    //   [self unlockFocus];
}


@end





