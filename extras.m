// created by koch, November 2000

#import <Foundation/Foundation.h>
#import "extras.h"

BOOL isText(long aChar)
{
    if (((aChar >= 0x0041) && (aChar <= 0x005a)) ||
        ((aChar >= 0x0061) && (aChar <= 0x007a)))
    { 
        return TRUE;
    }
    else
    {
        return FALSE;
    }
}

NSString *StringFromBool(BOOL tmp)
{
    return (tmp == YES) ? @"YES" : @"NO";
}

BOOL BoolFromString(NSString *tmp)
{
    tmp = [tmp lowercaseString];
    return ([tmp isEqualToString:@"yes"]) ? YES : NO;
}