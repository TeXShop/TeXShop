/* MyTextView */

#import <Cocoa/Cocoa.h>

@interface MyTextView : NSTextView
{
}

- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity;
@end
