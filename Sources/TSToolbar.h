//
//  TSToolbar.h
//  TeXShop
//
//  Created by Richard Koch on 3/27/11.
//  Copyright 2011 University of Oregon. All rights reserved.
//

// This code is a kludge to fix a crash in Lion. In that system, when a document
// opens a pdf, or tiff, or jpg, WITHOUT opening a source window, the program
// crashes when the document is closed. Notice that most documents in the Help menu
// are shown in this way, as are Preview's when TeXShop is configured for an external
// editor.
//
// The crash log shows that the crash occurs during the toolbar routine "validateVisibleItems"
// when the program tries to access toolbar items that have already been deleted. Such items are
// actually not validated immediately; instead the OS tries to be efficient by delaying the
// validation briefly.
//
// The simple kludge is to subclass the toolbar and rewrite the "visibleItems" routine.
// This routine usually calls super to find the visible items, but just before the window
// is closed, the routine is modified to always return an empty array of visible items.
// This modification only applies to the Preview Window because experiments show that the
// main document window does not create a problem.


#import <Cocoa/Cocoa.h>
#import "TSDocument.h"


@interface TSToolbar : NSToolbar {
	BOOL visibleOff;
}

- (NSArray *)visibleItems;
- (void)turnVisibleOff:(BOOL)value;

@end
