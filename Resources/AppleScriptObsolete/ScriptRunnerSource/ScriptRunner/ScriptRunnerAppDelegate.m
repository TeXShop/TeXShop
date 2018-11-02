#import "ScriptRunnerAppDelegate.h"
#import "Globals.h"

@implementation ScriptRunnerAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (myPath == nil) [NSApp terminate:self];
    scriptPath = [NSString stringWithUTF8String: myPath]; 
    if ([[NSFileManager defaultManager] fileExistsAtPath: scriptPath]) {
        NSString *scriptString = [NSString stringWithContentsOfFile: scriptPath encoding:NSUTF8StringEncoding error:NULL];
        
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
