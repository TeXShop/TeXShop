#import <AppKit/AppKit.h>

BOOL isText(long aChar)
{
    if (	((aChar >= 0x0041) && (aChar <= 0x005a)) ||
                ((aChar >= 0x0061) && (aChar <= 0x007a))
        ) 
        return TRUE;
    else
        return FALSE;
}


