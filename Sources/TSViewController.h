/* TSViewController */

#import <Cocoa/Cocoa.h>
#import "TSDocument.h"
#import	"MyPDFKitView.h"

@interface TSViewController : NSObject
{
	TSDocument		*myDocument;
	MyPDFKitView	*myPDFKitView;
	MyPDFKitView	*myPDFKitView2;
	MyPDFKitView	*activeView;
	TSPreviewWindow	*previewWindow;
}
- (void)changeMouseMode: sender;
// - (void)activate: sender;

@end
