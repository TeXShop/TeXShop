#import <Cocoa/Cocoa.h>

@interface TeXLayoutManager : NSLayoutManager {
    NSArray *tabCharacters;
    NSArray *newLineCharacters;
    NSArray *fullwidthSpaceCharacters;
    NSArray *spaceCharacters;
}
@end

