//
//  MyAppDelegate.m
//  Test
//
//  Created by Richard Koch on Sun Nov 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "MyAppDelegate.h"
#import "Globals.h"


@implementation MyAppDelegate
-(void) init;
{
    [super init];
    [NSApp setDelegate: self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (myPath == nil) [NSApp terminate:self];
    scriptPath = [NSString stringWithCString: myPath]; 
    if ([[NSFileManager defaultManager] fileExistsAtPath: scriptPath]) {
        NSString *scriptString = [NSString stringWithContentsOfFile: scriptPath];
        
        NSAppleScript *aScript = [[NSAppleScript alloc] initWithSource: scriptString];
        NSDictionary *errorInfo;
        NSAppleEventDescriptor *returnValue = [aScript executeAndReturnError: &errorInfo];
        if (returnValue) // successful?
            {	// show the result only if the return value is a text
                if ([returnValue descriptorType] == kAETextSuite)	//kAETextSuite='TEXT'
                    NSRunAlertPanel(@"AppleScript Result", [returnValue stringValue], nil, nil, nil);
            }
        else
            {	// show error message
                NSRunAlertPanel(@"AppleScript Error", 
                        [errorInfo objectForKey: NSAppleScriptErrorMessage], nil, nil, nil);
            }
        [aScript release];
	}
    [NSApp terminate:self];
}


@end
