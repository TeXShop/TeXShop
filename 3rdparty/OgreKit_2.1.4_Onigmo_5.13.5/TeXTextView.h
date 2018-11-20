#import <Cocoa/Cocoa.h>
#define	YEN			0x00a5
#define	BACKSLASH	'\\'

@interface TeXTextView : NSTextView {
	NSDictionary* highlightBracesColorDict;
	int lastCursorLocation;
	int lastStringLength;
	NSColor* originalBackgroundColor;
	BOOL coloringNow;
	NSDictionary* autocompletionDictionary;
	BOOL autoCompleting;
	NSString *g_commandCompletionChar;
	NSMutableString *g_commandCompletionList;
	NSString *texshopPlistPath;
	char texChar;
}
@end

@interface TeXTextView (Colorize)
- (void)colorizeText:(BOOL)colorize;
- (void)resetBackgroundColor:(id)sender;
@end

