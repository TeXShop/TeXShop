//
//  TSColorSupport.h
//  
//
//  Created by Richard Koch on 7/26/2018.
//  Copyright 2018 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSColorSupport : NSObject {
    
}

+ (id)sharedInstance;

- (void)checkAndRestoreDefaults;
- (void)initializeColors;
- (NSMutableDictionary *) dictionaryForColorFile: (NSString *) fileTitle;
- (NSColor *)colorFromDictionary:(NSDictionary *)theDictionary andKey: (NSString *)theKey;
- (NSColor *)colorAndAlphaFromDictionary:(NSDictionary *)theDictionary andKey: (NSString *)theKey;

- (NSColor *)liteColorWithKey: (NSString *)theKey;
- (NSColor *)darkColorWithKey: (NSString *)theKey;
- (NSColor *)liteColorAndAlphaWithKey: (NSString *)theKey;
- (NSColor *)darkColorAndAlphaWithKey: (NSString *)theKey;

- (void)changeColorValueInDictionary: (NSMutableDictionary *)theDictionary forKey: (NSString *)theKey fromColorWell: (id)theWell;
- (void)setColorValueInDictionary: (NSMutableDictionary *)theDictionary forKey: (NSString *)theKey withRed: (float)red
    Green: (float)green Blue: (float)blue Alpha: (float)alpha;
@end
