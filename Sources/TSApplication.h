//
//  TSApplication.h
//  
//
//  Created by Richard Koch on 7/10/11.
//  Copyright 2011 University of Oregon. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface TSApplication : NSApplication

- (void)terminate:(id)sender;
- (void)sendEvent:(NSEvent *)anEvent;
- (IBAction)GotoLibraryTeXShop: (id)sender;
- (void)sendEvent:(NSEvent *)event;

@end
