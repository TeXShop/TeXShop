//
//  OutlineViewController.h
//
//  Created by Mitsuhiro Shishikura on Wed Dec 18 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
//	This code was derived from Apple Sample code DrangNDropOutlineView

#import <Cocoa/Cocoa.h>

// In order to use this controller, create an instance of MyOutlineView 
// which is a subclass of NSOutlineView.  
// Instantiate this class in Interface Builder and make connections 
// with the outline view as "delegate" and "dataSource".  
// Use "setRootOfTree" to assign the root node of the tree.  
// Use "nodeFromDictionary" of "MyTreeNode" to create such a node 
// from a dictionary.  

#define SEPARATOR_IMAGE @"Separator.tiff"
#define MyOutlineViewAddedItemNotification		@"MyOutlineViewAddedItem"
#define MyOutlineViewRemovedItemNotification	@"MyOutlineViewDeletedItem"
#define MyOutlineViewAcceptedDropNotification	@"MyOutlineViewAcceptedDrop"

@class MyTreeNode;

@interface OutlineViewController : NSObject 
{
    MyTreeNode	*rootOfTree;
    NSArray	 		*draggedNodes;

    IBOutlet id outlineView;
}

+ (OutlineViewController *)sharedInstance;

- (void)setRootOfTree: (MyTreeNode *)newRootOfTree;
- (MyTreeNode *)rootOfTree;
- (NSArray*)draggedNodes;
- (NSArray *)selectedNodes;

- (void)deleteSelection: (id)sender;
- (void)addNewItem: (id)sender;
- (void)addSubmenu: (id)sender;
- (void)addSeparator: (id)sender;
- (void)addNewDataToSelection:(MyTreeNode *)newChild;
- (void)addNewDataArrayToSelection:(NSArray *)newChildren; 
- (void)duplicateSelection: (id)sender;
- (void)sortData: (id)sender;

@end

@interface NSOutlineView (MyExtensions)

- (NSArray*)allSelectedItems;
- (void)selectItems:(NSArray*)items byExtendingSelection:(BOOL)extend;

@end

@interface MyOutlineView : NSOutlineView {
}
@end

@interface ImageAndTextCell : NSTextFieldCell {
@private
    NSImage	*image;
}

- (void)setImage:(NSImage *)anImage;
- (NSImage *)image;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

@end