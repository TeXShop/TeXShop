//
//  Matrixcontroller.h
//
//  Created by Jonas Zimmermann on Fri Nov 28 2003.
//  Copyright (c) 2001 __CompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface Matrixcontroller : NSWindowController
{
    IBOutlet id brselcl;
    IBOutlet id brselop;
    IBOutlet id brtfcl;
    IBOutlet id brtfop;
    IBOutlet id hslider;
    IBOutlet id matmod;
    IBOutlet id matrixmatrix;
    IBOutlet id vslider;
    BOOL shown; //YES if user has chosen to display panel
    
    NSArray *arrayMatrix;
    NSNotificationCenter *notifcenter;

}
+ (id)sharedInstance;

- (IBAction)putmatrix:(id)sender;
- (IBAction)setmatrix:(id)sender;
- (void)hideWindow:(id)sender;

@end
