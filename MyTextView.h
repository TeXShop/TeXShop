/* MyTextView */

#import <Cocoa/Cocoa.h>

@interface MyTextView : NSTextView
{
    NSDocument *document; 
}

- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity;

// mitsu 1.29 (T2-4) added
- (void)setDocument: (NSDocument *)doc;
- (void)registerForCommandCompletion: (id)sender;
// end mitsu 1.29

@end
