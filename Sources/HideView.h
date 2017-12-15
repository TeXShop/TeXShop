//
//  OverView.h
//  TeXShop
//
//  Created by Richard Koch on 12/9/2017.
//  Copyright (c) 2017 Richard Koch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>




@interface HideView : NSView
{
    NSRect          sizeRect;
}

@property (retain) NSImage *originalImage;

- (void) setSizeRect: (NSRect)theRect;


@end
