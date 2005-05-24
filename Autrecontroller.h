//
//  Autrecontroller.h
//  test3
//
//  Created by lenglin on Sun Aug 26 2001.
//  Copyright (c) 2001 __CompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface Autrecontroller : NSWindowController {
    IBOutlet id environbuttonmatrix;
    IBOutlet id functionsbuttonmatrix;
    IBOutlet id greekbuttonmatrix;
    IBOutlet id intlbuttonmatrix;
    IBOutlet id mathbuttonmatrix;
    IBOutlet id symbolsbuttonmatrix;
    IBOutlet id typefacebuttonmatrix;
    // added by Georg Klein
    IBOutlet id custombuttonmatrix;
    NSArray *arrayCustomized;
    // end add
    NSArray *arrayFunctions1,*arrayFunctions2,*arrayEnvironments,*arrayTypeface,*arrayInternational,*arrayGreek,*arrayMath,*arraySymbols;
    NSNotificationCenter *notifcenter;
    BOOL shown; //YES if user has chosen to display panel
}

+ (id)sharedInstance;
- (IBAction)putenvironments:(id)sender;
- (IBAction)putfunctions1:(id)sender;
- (IBAction)putgreek:(id)sender;
- (IBAction)putintl:(id)sender;
- (IBAction)putmath:(id)sender;
- (IBAction)putsymbols:(id)sender;
- (IBAction)puttypeface:(id)sender;
- (void)hideWindow:(id)sender;
@end
