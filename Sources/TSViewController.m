#import "TSViewController.h"

@implementation TSViewController

- (void)init
{
	[super init];
	// activeView = myPDFKitView;
}

- (void)changeMouseMode: sender
{
	[myPDFKitView changeMouseMode: sender];
	[myPDFKitView2 changeMouseMode: sender];
}

/*
- (void)activate:sender
{
	if (sender == myPDFKitView)
		activeView = myPDFKitView;
	else
		activeView = myPDFKitView2;
}
*/

@end
