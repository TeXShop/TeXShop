#import <Cocoa/Cocoa.h>
#import "Globals.h"

int main(int argc, char *argv[])
{
    if (argc > 1)
        myPath = argv[1];
    else
        myPath = nil;
    NSApplication *app = [NSApplication sharedApplication];
    BOOL result = [NSBundle loadNibNamed:@"MainMenu.nib" owner:app];
    [NSApp run];
    return !result;
}
