//
//  GlobalData.h
//  TeXShop
//
//  Created by Richard Koch on 3/20/14.
//
//

#import <Foundation/Foundation.h>

@interface GlobalData : NSObject

@property (retain) NSDictionary		*g_autocompletionDictionary;
@property (retain) NSArray			*g_autocompletionKeys;  // added by Terada
@property (retain) NSString         *g_defaultLanguage;
@property (retain) NSString         *CommandCompletionPath;
@property (retain) NSString         *tempAppleScriptPath;

+ (GlobalData *)sharedGlobalData;

@end

