/*
 * Name: GC_TestAppDelegate.m
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

#import "GC_TestAppDelegate.h"

@implementation GC_TestAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"GC Test - start");
    
    OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:@"a"];
    
    NSAutoreleasePool    *pool = [[NSAutoreleasePool alloc] init];
    int count = 0;
    int i;
    for (i = 0; i < 1000000000; i++) {
        NSEnumerator  *matcher = [regex matchEnumeratorInString:@"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"];
        OGRegularExpressionMatch  *match;
        while ((match = [matcher nextObject]) != nil) {
            count++;
        }
        
        if (i % 1000 == 0) {
            [pool release];
            pool = [[NSAutoreleasePool alloc] init];
        }
    }
    [pool release];
    
	NSLog(@"GC Test - end");
}

@end
