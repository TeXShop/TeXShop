// ================================================================================
//  MyDocumentController.h
// ================================================================================
//	TeXShop
//
//  Created by Richard Koch on Sun Feb 16 2003.
//  Copyright (c) 2003 Richard Koch. 
//
//	This source is distributed under the terms of GNU Public License (GPL) 
//	see www.gnu.org for more info
//
// ================================================================================

#import <Cocoa/Cocoa.h>

@interface MyDocumentController : NSDocumentController
{
    id	encodingView;
    id	encodingMenu;
    int	encoding;
}    
- (IBAction)openDocument:(id)sender;
- (void)initializeEncoding;
- (int)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions;
- (int) encoding;
@end
