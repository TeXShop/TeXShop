//
//  TSWindowManager.h
//  TeXShop
//
//  Created by dirk on Sat Feb 17 2001.
//

#import <AppKit/AppKit.h>

@interface TSWindowManager : NSObject 
{
    NSWindow		*_activeDocumentWindow;
    NSWindow 		*_activePdfWindow;
}

+ (id)sharedInstance;

- (NSWindow *)activeDocumentWindow;
- (NSWindow *)activePdfWindow;

// added by mitsu --(J+) check mark in "Typeset" menu
- (void)checkProgramMenuItem: (int)programID checked: (BOOL)flag;
// end addition

@end
