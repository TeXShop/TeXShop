//
//  TSAppDelegate.h
//  TeXShop
//
//  Created by dirk on Tue Jan 23 2001.
//

#import <Foundation/Foundation.h>
#import "Autrecontroller.h"

@interface TSAppDelegate : NSObject 
{
    BOOL	forPreview;
}

- (IBAction)openForPreview:(id)sender;
- (IBAction)displayLatexPanel:(id)sender;
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
- (BOOL)forPreview;
- (void)configureExternalEditor;
@end
