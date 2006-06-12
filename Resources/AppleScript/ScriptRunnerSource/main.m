//
//  main.m
//  Test
//
//  Created by Richard Koch on Sun Nov 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Globals.h"

int main(int argc, const char *argv[])
{
    int i, result;
    
    if (argc > 1)
        myPath = argv[1];
    else
        myPath = nil;
    NSApplication *app = [NSApplication sharedApplication];
    [NSBundle loadNibNamed:@"MainMenu.nib" owner:app];
    // somehow, get argv to MyAppDelegate
    [NSApp run];
    return result;
}
