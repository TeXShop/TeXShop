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
}

- (IBAction)displayLatexPanel:(id)sender;
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
- (void)dealloc;
@end
