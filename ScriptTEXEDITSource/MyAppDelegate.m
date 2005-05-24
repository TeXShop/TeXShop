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
    // if (myPath == nil) [NSApp terminate:self];
    // scriptPath = [NSString stringWithCString: myPath];
    NSLog(@"here");
    NSString *editPath = [[NSBundle mainBundle] pathForResource:@"MainMenu.nib" ofType:nil inDirectory:nil]; //@"TEXTEDIT.app/Contents/MacOS/"];
    NSLog(@"here1");
    if (editPath == nil) NSLog(@"aha");
    NSLog(editPath);
    NSLog(@"here2");
    editPath = [[[[[[[editPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]
        stringByDeletingLastPathComponent]  stringByDeletingLastPathComponent]  stringByDeletingLastPathComponent]
        stringByDeletingLastPathComponent];
    NSLog(editPath);
    [[NSWorkspace sharedWorkspace] openFile:scriptPath withApplication:editPath];

   /*
    NSString *firstLine = 
        [[NSString stringWithString:@"tell application \"TeXShop\" "]
            stringByAppendingFormat:@"\n"];
    NSString *secondLine = [NSString stringWithString:@"open POSIX file "];
    NSString *secondLine1 = [secondLine stringByAppendingString: scriptPath];
    NSString *secondLine2 = [secondLine1 stringByAppendingFormat:@"\n"];
    NSString *thirdLine = [NSString stringWithString:@"end tell"];
    NSString *scriptString = [[firstLine stringByAppendingString:secondLine2] stringByAppendingString: thirdLine];
    NSLog(scriptString);
    NSAppleScript *aScript = [[NSAppleScript alloc] initWithSource: scriptString];
    NSDictionary *errorInfo;
    NSAppleEventDescriptor *returnValue = [aScript executeAndReturnError: &errorInfo];
    [aScript release];
    */
    
    if (myLine == nil) [NSApp terminate:self];
    NSString *lineString = [NSString stringWithCString: myLine];
  // tell application "TeXShop"
  // goto document 1 line 4
  // end tell
    NSString *firstLine = 
        [[NSString stringWithString:@"tell application \"TeXShop\" "]
            stringByAppendingFormat:@"\n"];
    NSString *thirdLine = [NSString stringWithString:@"end tell"];
    NSString *secondLine = [[[NSString stringWithString:@"goto document 1 line "] stringByAppendingString: lineString]
        stringByAppendingFormat:@"\n"];
    NSString *scriptString = [[firstLine stringByAppendingString: secondLine] stringByAppendingString: thirdLine];
    // NSLog(scriptString);
    NSAppleScript *aScript = [[NSAppleScript alloc] initWithSource: scriptString];
    NSDictionary *errorInfo;
    NSAppleEventDescriptor *returnValue = [aScript executeAndReturnError: &errorInfo];
    [aScript release];
    
    /*
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
        */
        
    [NSApp terminate:self];
}


@end
