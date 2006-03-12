/* MyTextView */

#import <Cocoa/Cocoa.h>
#import "MyDocument.h"

@interface MyTextView : NSTextView
{
    MyDocument		*document;
	BOOL			alternateDown;
}

- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity;

// mitsu 1.29 (T2-4) added
- (void)setDocument: (NSDocument *)doc;
- (void)registerForCommandCompletion: (id)sender;
// end mitsu 1.29
- (NSString *)getDragnDropMacroString: (NSString *)fileExt; // zenitani 1.33
- (NSString *)readSourceFromEquationEditorPDF: (NSString *)filePath; // zenitani 1.33(2)
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
- (NSString *)resolveAlias: (NSString *)path;
@end
