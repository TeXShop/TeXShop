//
//  TSAppDelegate.m
//  TeXShop
//
//  Created by dirk on Tue Jan 23 2001.
//


#import <Foundation/Foundation.h>
#import "TSAppDelegate.h"
#import "TSPreferences.h"
#import "globals.h"

/*" This class is registered as the delegate of the TeXShop NSApplication object. We do various stuff here, e.g. registering factory defaults, dealing with keyboard shortcuts etc.
"*/
@implementation TSAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    // if this is the first time the app is used, register a set of defaults to make sure
    // that the app is useable.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:TSHasBeenUsedKey] == NO)
    {
        [[TSPreferences sharedInstance] registerFactoryDefaults];
    }
}

@end
