//
//  GlobalData.m
//  TeXShop
//
//  Created by Richard Koch on 3/20/14.
//
//

#import "GlobalData.h"

@implementation GlobalData

static GlobalData *sharedGlobalData = nil;

+ (GlobalData*)sharedGlobalData {
    if (sharedGlobalData == nil) {
        sharedGlobalData = [[super allocWithZone:NULL] init];
        
        // initialize your variables here
    }
    return sharedGlobalData;
}


@end
