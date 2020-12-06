/*
 * Name: GC_TestAppDelegate.h
 * Project: OgreKit
 *
 * Creation Date: Mar 07 2010
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2010-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>

@interface GC_TestAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
