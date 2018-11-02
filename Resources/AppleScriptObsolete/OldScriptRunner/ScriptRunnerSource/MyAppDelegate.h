//
//  MyAppDelegate.h
//  Test
//
//  Created by Richard Koch on Sun Nov 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MyAppDelegate : NSObject {

NSString    *scriptPath;


}
-(void) init;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

@end
