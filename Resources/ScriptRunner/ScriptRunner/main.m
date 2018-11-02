//
//  main.m
//  ScriptRunner
//
//  Created by Richard Koch on 10/23/18.
//  Copyright © 2018 Richard Koch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Globals.h"

int main(int argc, const char * argv[]) {
    
    if (argc > 1)
        myPath = argv[1];
    else
        myPath = nil;

    return NSApplicationMain(argc, argv);
}
