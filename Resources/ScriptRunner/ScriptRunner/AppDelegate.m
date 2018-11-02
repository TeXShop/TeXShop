//
//  AppDelegate.m
//  ScriptRunner
//
//  Created by Richard Koch on 10/23/18.
//  Copyright © 2018 Richard Koch. All rights reserved.
//

#import "AppDelegate.h"
#import "Globals.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    NSString    *scriptPath;
    
    if (myPath == nil) [NSApp terminate:self];
    scriptPath = [NSString stringWithUTF8String: myPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath: scriptPath]) {
        NSString *scriptString = [NSString stringWithContentsOfFile: scriptPath encoding:NSUTF8StringEncoding error:NULL];
        
        NSAppleScript *aScript = [[NSAppleScript alloc] initWithSource: scriptString];
        NSDictionary *errorInfo;
        NSAppleEventDescriptor *returnValue = [aScript executeAndReturnError: &errorInfo];
        if (returnValue) // successful?
        {    // show the result only if the return value is a text
            if ([returnValue descriptorType] == kAETextSuite)    //kAETextSuite='TEXT'
                NSRunAlertPanel(@"AppleScript Result", [returnValue stringValue], nil, nil, nil);
        }
        else
        {    // show error message
            NSRunAlertPanel(@"AppleScript Error",
                            [errorInfo objectForKey: NSAppleScriptErrorMessage], nil, nil, nil);
        }
    }
    [NSApp terminate:self];

    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
