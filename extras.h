//
//  extras.h
//  TeXShop
//
//  Broken out by dirk on Wed Jan 10 2001.
//

#import <Foundation/Foundation.h>

#define LOGMETH NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));

BOOL isText(long aChar);

NSString *StringFromBool(BOOL tmp);
BOOL BoolFromString(NSString *tmp);
