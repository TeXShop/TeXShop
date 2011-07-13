/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2005 Richard Koch
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * $Id: TSMacroOutlineController.m 159 2006-05-24 23:45:37Z fingolfin $
 *
 * Created by Mitsuhiro Shishikura on Wed Dec 18 2002.
 * This code was derived from Apple Sample code DrangNDropOutlineView
 *
 */

#import "TSMacroOutlineController.h"

#import "TSMacroMenuController.h"
#import "TSMacroTreeNode.h"
#import "TSEncodingSupport.h"
#import "Globals.h"

// ================================================================
// Constants
// ================================================================

#define DragDropSimplePboardType 	@"MyCustomOutlineViewPboardType"

#define COLUMNID_NAME	@"Name"
#define COLUMNID_KEY	@"Key"

#define NEW_ITEM_NAME	@"New Item"
#define NEW_SUBMENU_NAME	@"Submenu"

#define allowOnDropOnGroup 		YES
#define allowOnDropOnLeaf		NO
#define allowBetweenDrop		YES
#define onlyAcceptDropOnRoot	NO
#define autoSort 				NO


// ================================================================
// Method implimentations
// ================================================================

@implementation TSMacroOutlineController

static TSMacroOutlineController *_sharedOutlineViewController = nil;

+ (TSMacroOutlineController *)sharedInstance
{
	if (_sharedOutlineViewController == nil)
		_sharedOutlineViewController = [[[TSMacroOutlineController alloc] init] autorelease];
	return _sharedOutlineViewController;
}

- (id)init
{
	if (_sharedOutlineViewController)
		[super dealloc];
	else {
		_sharedOutlineViewController = [super init];
		rootOfTree = nil; //[[TSMacroTreeNode alloc] init];
		draggedNodes = nil;
	}
	return _sharedOutlineViewController;
}

- (void)dealloc
{
	if (rootOfTree)
		[rootOfTree release];
	if (draggedNodes)
		[draggedNodes release];
	[super dealloc];
	_sharedOutlineViewController = nil;
}

- (void)awakeFromNib
{
	NSTableColumn *tableColumn = nil;
	ImageAndTextCell *imageAndTextCell = nil;

	// Insert custom cell types into the table view, the standard one does text only.
	// We want one column to have text and images, and one to have check boxes.
	tableColumn = [outlineView tableColumnWithIdentifier: COLUMNID_NAME];
	imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable: YES];
	[tableColumn setDataCell:imageAndTextCell];

	// Register to get only our custom type.
	[outlineView registerForDraggedTypes:[NSArray arrayWithObjects: DragDropSimplePboardType, NSStringPboardType, nil]];
}


// ================================================================
//  Managing the tree root
// ================================================================

- (void)setRootOfTree: (TSMacroTreeNode *)newRootOfTree
{
	[newRootOfTree retain];
	[rootOfTree release];
	rootOfTree = newRootOfTree;
	draggedNodes = nil;
	[outlineView reloadData];
}

- (TSMacroTreeNode *)rootOfTree
{
	return rootOfTree;
}

// ================================================================
//  NSOutlineView related methods.
// ================================================================

- (NSArray*)draggedNodes
{
	return draggedNodes;
}

- (NSArray *)selectedNodes
{
	return [outlineView allSelectedItems];
}

- (void)addNewItem: (id)sender
{
	[self addNewDataToSelection: [TSMacroTreeNode nodeWithName: NEW_ITEM_NAME content: nil key: nil]];
}

- (void)addSubmenu: (id)sender
{
	[self addNewDataToSelection: [TSMacroTreeNode submenuNodeWithName: NEW_SUBMENU_NAME]];
}

- (void)addSeparator: (id)sender
{
	[self addNewDataToSelection: [TSMacroTreeNode separatorNode]];
}

- (void)addNewDataToSelection:(TSMacroTreeNode *)newChild
{
	NSIndexSet		*myIndexSet;
	NSInteger childIndex = 0, newRow = 0;
	NSArray *selectedNodes = [self selectedNodes];
	TSMacroTreeNode *selectedNode = ([selectedNodes count] ? [selectedNodes lastObject] : rootOfTree);
	TSMacroTreeNode *parentNode = nil;
	
	if ([selectedNode isGroup]) {
		parentNode = selectedNode;
		childIndex = [parentNode numberOfChildren]; // it was 0;
		[outlineView expandItem: selectedNode];
	} else {
		parentNode = [selectedNode nodeParent];
		childIndex = [parentNode indexOfChildIdenticalTo:selectedNode] + 1;
	}
	
	[parentNode insertChild: newChild atIndex: childIndex];
	[outlineView reloadData];
	
	newRow = [outlineView rowForItem: newChild];
	if (newRow >= 0) {
		myIndexSet = [NSIndexSet indexSetWithIndex: newRow];
		// [outlineView selectRow: newRow byExtendingSelection: NO]; // deprecated, so
		[outlineView selectRowIndexes: myIndexSet byExtendingSelection: NO];
		}
	
#ifdef TSMacroOutlineViewAddedItemNotification
	// notify that item was added -- custom notification
	[[NSNotificationCenter defaultCenter] postNotificationName: TSMacroOutlineViewAddedItemNotification
														object: outlineView];
#endif
}

- (void)addNewDataArrayToSelection:(NSArray *)newChildren
{
	NSInteger childIndex = 0; //, newRow = 0;
	NSArray *selectedNodes = [self selectedNodes];
	TSMacroTreeNode *selectedNode;
	TSMacroTreeNode *parentNode = nil;

	if ([selectedNodes count] == 0) {
		parentNode = rootOfTree;
		childIndex = [rootOfTree numberOfChildren];
	} else {
		selectedNode = [selectedNodes lastObject];
		parentNode = [selectedNode nodeParent];
		childIndex = [parentNode indexOfChildIdenticalTo:selectedNode] + 1;
	}

	[parentNode insertChildren: newChildren atIndex: childIndex];
	[outlineView reloadData];

	[outlineView selectItems: newChildren byExtendingSelection: NO];

#ifdef TSMacroOutlineViewAddedItemNotification
	// notify that item was added -- custom notification
	[[NSNotificationCenter defaultCenter] postNotificationName: TSMacroOutlineViewAddedItemNotification
					object: outlineView];
#endif
}

- (void)deleteSelection: (id)sender
{
	NSArray *selection = [self selectedNodes];
	if ([selection count] == 0)
		return;

	// Tell all of the selected nodes to remove themselves from the model.
	[selection makeObjectsPerformSelector: @selector(removeFromParent)];
	[outlineView deselectAll:nil];
	[outlineView reloadData];

#ifdef TSMacroOutlineViewRemovedItemNotification
	// notify that item was deleted -- custom notification
	[[NSNotificationCenter defaultCenter] postNotificationName: TSMacroOutlineViewRemovedItemNotification
					object: outlineView];
#endif
}

- (void)duplicateSelection: (id)sender
{
	NSArray *selection = [self selectedNodes];
	if ([selection count] == 0)
		return;
	[self addNewDataArrayToSelection: [TSMacroTreeNode duplicateNodeArray: selection]];
}

- (void)selectAll: (id)sender
{
	[outlineView selectAll: sender];
}

- (void)sortData: (id)sender
{
	NSArray *itemsToSelect = [self selectedNodes];
	[rootOfTree recursiveSortChildren];
	[outlineView reloadData];
	[outlineView selectItems: itemsToSelect byExtendingSelection: NO];
}


// ================================================================
//  NSOutlineView data source methods. (The required ones)
// ================================================================
//  Need Interface Builder connection:
//		NSOutlineView.dataSource -> Instance of this class (or file's owner)

// Required methods.
- (id)outlineView:(NSOutlineView *)olv child:(NSInteger)idx ofItem:(id)item
{
	return [(item)?((TSMacroTreeNode*)item):rootOfTree childAtIndex:idx];
}

- (BOOL)outlineView:(NSOutlineView *)olv isItemExpandable:(id)item
{
	return [(TSMacroTreeNode*)item isExpandable];
}

- (NSInteger)outlineView:(NSOutlineView *)olv numberOfChildrenOfItem:(id)item
{
	return [(item)?((TSMacroTreeNode*)item):rootOfTree numberOfChildren];
}

- (id)outlineView:(NSOutlineView *)olv objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	id objectValue = nil;
	// The return value from this method is used to configure the state of the items cell via setObjectValue:

#ifdef DEBUG_TREE
	NODE_INFO(@"ObjValue", item);
#endif

	if([[tableColumn identifier] isEqualToString: COLUMNID_NAME]) {
		if ([(TSMacroTreeNode*)item isSeparator])
			objectValue = @"";
		else {
			objectValue = [(TSMacroTreeNode*)item name];
		}
	} else if([[tableColumn identifier] isEqualToString: COLUMNID_KEY]) {
		objectValue = getMenuItemString([(TSMacroTreeNode*)item key]);
	}
	return objectValue;
}

// Optional method: needed to allow editing.
- (void)outlineView:(NSOutlineView *)olv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if([[tableColumn identifier] isEqualToString: COLUMNID_NAME]) {
		[(TSMacroTreeNode*)item setName: object];
	} else if ([[tableColumn identifier] isEqualToString: COLUMNID_KEY]) {
		[(TSMacroTreeNode*)item setKey: object];
	}

}

// ================================================================
//  NSOutlineView delegate methods.
// ================================================================
//  Need Interface Builder connection:
//		NSOutlineView.delegate -> Instance of this class (or file's owner)

- (BOOL)outlineView:(NSOutlineView *)olv shouldExpandItem:(id)item
{
	return [(TSMacroTreeNode*)item isExpandable];
}

- (BOOL)outlineView:(NSOutlineView *)olv shouldEditTableColumn: (NSTableColumn *)tableColumn item: (id)item
{
	return [(TSMacroTreeNode*)item isEditable];
}

- (void)outlineView: (NSOutlineView *)olv willDisplayCell: (NSCell *)cell forTableColumn: (NSTableColumn *)tableColumn item: (id)item
{
	if ([[tableColumn identifier] isEqualToString: COLUMNID_NAME]) {
		//if (item && [(TSMacroTreeNode*)item iconRep]) // when there is an icon
		//	[(ImageAndTextCell*)cell setImage: [(TSMacroTreeNode*)item iconRep]];
		//else
		if ([item isSeparator]) {
			[(ImageAndTextCell*)cell setImage: [NSImage imageNamed: SEPARATOR_IMAGE]];
		} else
			[(ImageAndTextCell*)cell setImage: nil];
	} else if ([[tableColumn identifier] isEqualToString: COLUMNID_KEY]) {
		// Don't do anything unusual for the kind column.
	}
}

// ================================================================
//  NSOutlineView data source methods. (dragging related)
// ================================================================
//  Need Interface Builder connection:
//		NSOutlineView.dataSource -> Instance of this class (or file's owner)

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
	draggedNodes = items; // Don't retain since this is just holding temporaral drag information, and it is only used during a drag!  We could put this in the pboard actually.

	// Provide data for our custom type, and simple NSStrings.
	[pboard declareTypes:[NSArray arrayWithObjects: DragDropSimplePboardType, NSStringPboardType, nil] owner:self];

	// the actual data doesn't matter since DragDropSimplePboardType drags aren't recognized by anyone but us!.
	[pboard setData:[NSData data] forType:DragDropSimplePboardType];

	// Put string data on the pboard... notice you candrag into TextEdit!
	NSString *draggedString = ([draggedNodes count]>0)?([[draggedNodes objectAtIndex: 0] content]):@"";
	if (!draggedString)
		draggedString = @"";	// content may be nil?
	if (g_shouldFilter == kMacJapaneseFilterMode) {
		if ([SUD boolForKey:@"ConvertToBackslash"]) // this case isn't necessary?
			draggedString = filterYenToBackslash(draggedString);
		else
			draggedString = filterBackslashToYen(draggedString);
	} else if (g_shouldFilter == kOtherJapaneseFilterMode) {
		if ([SUD boolForKey:@"ConvertToYen"])
			draggedString = filterBackslashToYen(draggedString);
		else	// this case shouldn't be necessary
			draggedString = filterYenToBackslash(draggedString);
	}
	[pboard setString: draggedString forType: NSStringPboardType];

	return YES;
}

- (NSUInteger)outlineView:(NSOutlineView*)olv validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex
{
	// This method validates whether or not the proposal is a valid one. Returns NO if the drop should not be allowed.
	TSMacroTreeNode *targetNode = item;
	BOOL targetNodeIsValid = YES;

	if (onlyAcceptDropOnRoot) {
		targetNode = nil;
		childIndex = NSOutlineViewDropOnItemIndex;
	} else {
		BOOL isOnDropTypeProposal = childIndex==NSOutlineViewDropOnItemIndex;

		// Refuse if: dropping "on" the view itself unless we have no data in the view.
		if ((targetNode==nil) && (childIndex==NSOutlineViewDropOnItemIndex) &&
								([rootOfTree numberOfChildren]!=0))
			targetNodeIsValid = NO;

		if ((targetNode==nil) && (childIndex==NSOutlineViewDropOnItemIndex) && ((allowOnDropOnLeaf)==NO))
			targetNodeIsValid = NO;

		// Refuse if: we are trying to do something which is not allowed.
		if ((targetNodeIsValid && isOnDropTypeProposal==NO && allowBetweenDrop==NO) ||
			([(TSMacroTreeNode*)targetNode isGroup] && isOnDropTypeProposal==YES && allowOnDropOnGroup==NO) ||
			([(TSMacroTreeNode*)targetNode isLeaf ] && isOnDropTypeProposal==YES && allowOnDropOnLeaf==NO))
			targetNodeIsValid = NO;

		// Check to make sure we don't allow a node to be inserted into one of its descendants!
		if (targetNodeIsValid && ([info draggingSource]==outlineView) && [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject: DragDropSimplePboardType]] != nil) {
			NSArray *_draggedNodes = [(TSMacroOutlineController *)[[info draggingSource] dataSource] draggedNodes];
			targetNodeIsValid = ![targetNode isDescendantOfNodeInArray: _draggedNodes];
		}
	}

	// Set the item and child idx in case we computed a retargeted one.
	[outlineView setDropItem:targetNode dropChildIndex:childIndex];

	return targetNodeIsValid ? NSDragOperationGeneric : NSDragOperationNone;
}

- (void)performDropOperation:(id <NSDraggingInfo>)info onNode:(TSMacroTreeNode*)parentNode atIndex:(NSInteger)childIndex
{
	// Helper method to insert dropped data into the model.
	NSPasteboard * pboard = [info draggingPasteboard];
	NSMutableArray * itemsToSelect = nil;
	
	// Do the appropriate thing depending on whether the data is DragDropSimplePboardType or NSStringPboardType.
	if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:DragDropSimplePboardType, nil]] != nil) {
		TSMacroOutlineController *dragDataSource = [[info draggingSource] dataSource];
		NSArray *_draggedNodes = [TSMacroTreeNode minimumNodeCoverFromNodesInArray: [dragDataSource draggedNodes]];
		NSEnumerator *draggedNodesEnum = [_draggedNodes objectEnumerator];
		TSMacroTreeNode *_draggedNode = nil, *_draggedNodeParent = nil;
		
		itemsToSelect = [NSMutableArray arrayWithArray:[self selectedNodes]];
		
		while ((_draggedNode = [draggedNodesEnum nextObject])) {
			_draggedNodeParent = (TSMacroTreeNode *)[_draggedNode nodeParent];
			if (parentNode==_draggedNodeParent && [parentNode indexOfChild: _draggedNode]<childIndex)
				childIndex--;
			[_draggedNodeParent removeChild: _draggedNode];
		}
		[parentNode insertChildren: _draggedNodes atIndex: childIndex];
	} else if ([pboard availableTypeFromArray:[NSArray arrayWithObject: NSStringPboardType]]) {
		NSString *string = [pboard stringForType: NSStringPboardType];
		NSString *tempStr = string;
		if (g_shouldFilter == kMacJapaneseFilterMode)
			tempStr = filterBackslashToYen(string);
		else if (g_shouldFilter == kOtherJapaneseFilterMode)
			tempStr = filterYenToBackslash(string);
		NSMutableString *nameStr = [[tempStr substringToIndex: MIN([tempStr length], 50)] mutableCopy];
		[nameStr replaceOccurrencesOfString: @"\n" withString: @""
									options: 0 range: NSMakeRange(0, [nameStr length])];
		if (g_shouldFilter)	// we only use backslashes
			string = filterYenToBackslash(string);
		TSMacroTreeNode *newItem = [TSMacroTreeNode nodeWithName: nameStr content: string key: nil];
		[nameStr release];
		
		itemsToSelect = [NSMutableArray arrayWithObject: newItem];
		[parentNode insertChild: newItem atIndex:childIndex++];
	}
	
	[outlineView reloadData];
	[outlineView selectItems: itemsToSelect byExtendingSelection: NO];
}

- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)targetItem childIndex:(NSInteger)childIndex
{
	TSMacroTreeNode * 		parentNode = nil;

	// Determine the parent to insert into and the child idx to insert at.
	if ([(TSMacroTreeNode*)targetItem isLeaf]) {
		parentNode = (childIndex == NSOutlineViewDropOnItemIndex ? [targetItem nodeParent] : targetItem);
		childIndex = (childIndex == NSOutlineViewDropOnItemIndex ? [[targetItem nodeParent] indexOfChild: targetItem] + 1 : 0);
	} else {
		parentNode = (targetItem ? targetItem : rootOfTree);
		childIndex = (childIndex == NSOutlineViewDropOnItemIndex ? 0 : childIndex);
	}

	[self performDropOperation:info onNode:parentNode atIndex:childIndex];

#ifdef TSMacroOutlineViewAcceptedDropNotification
	// notify that item was moved or dropped -- custom notification
	[[NSNotificationCenter defaultCenter] postNotificationName: TSMacroOutlineViewAcceptedDropNotification
					object: outlineView];
#endif
	return YES;
}

@end


@implementation NSOutlineView (MyExtensions)

- (id)selectedItem {
	return [self itemAtRow: [self selectedRow]];
}

- (NSArray*)allSelectedItems {
	NSIndexSet *theIndexes = [self selectedRowIndexes];
	NSMutableArray *items = [NSMutableArray array];
	/* selectedRowEnumerator is deprecated
	NSEnumerator *selectedRows = [self selectedRowEnumerator];
	NSNumber *selRow = nil;
	while ((selRow = [selectedRows nextObject])) {
		if ([self itemAtRow:[selRow intValue]])
			[items addObject: [self itemAtRow:[selRow intValue]]];
	}
	*/
	NSInteger rows = [self numberOfRows];
	NSInteger i;
	for (i = 0; i < rows; i++)
		if ([theIndexes containsIndex:i]) {
			if ([self itemAtRow: i])
				[items addObject: [self itemAtRow:i]];
			}
	
	return items;
}

- (void)selectItems:(NSArray*)items byExtendingSelection:(BOOL)shouldExtend {
	NSIndexSet		*myIndexSet;
	NSInteger i;
	if (shouldExtend == NO)
		[self deselectAll:nil];
	for (i = 0; i < [items count]; i++) {
		NSInteger row = [self rowForItem:[items objectAtIndex:i]];
		if(row >= 0) {
			myIndexSet = [NSIndexSet indexSetWithIndex: row];
			// [self selectRow: row byExtendingSelection:YES]; // deprecated, so
			[self selectRowIndexes: myIndexSet byExtendingSelection:YES];
			}
	}
}

- (void)delete: (id)sender
{
	[(TSMacroOutlineController *)[self delegate] deleteSelection: sender];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	if ([anItem action] == @selector(delete:))
		return ([[self allSelectedItems] count] > 0);

	return YES;
}

@end


@implementation TSMacroOutlineView

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	if (isLocal)
		return NSDragOperationEvery;
	else
		return NSDragOperationCopy;
}

@end


@implementation ImageAndTextCell

- (void)dealloc {
	[image release];
	image = nil;
	[super dealloc];
}

- copyWithZone:(NSZone *)zone {
	ImageAndTextCell *cell = (ImageAndTextCell *)[super copyWithZone:zone];
	cell->image = [image retain];
	return cell;
}

- (void)setImage:(NSImage *)anImage {
	if (anImage != image) {
		[image release];
		image = [anImage retain];
	}
}

- (NSImage *)image {
	return image;
}

- (NSRect)imageFrameForCellFrame:(NSRect)cellFrame {
	if (image != nil) {
		NSRect imageFrame;
		imageFrame.size = [image size];
		imageFrame.origin = cellFrame.origin;
		imageFrame.origin.x += 3;
		imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
		return imageFrame;
	}
	else
		return NSZeroRect;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
	NSRect textFrame, imageFrame;
	NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
	[super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
	NSRect textFrame, imageFrame;
	NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
	[super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	if (image != nil) {
		NSSize	imageSize;
		NSRect	imageFrame;

		imageSize = [image size];
		NSDivideRect(cellFrame, &imageFrame, &cellFrame, 3 + imageSize.width, NSMinXEdge);
		if ([self drawsBackground]) {
			[[self backgroundColor] set];
			NSRectFill(imageFrame);
		}
		imageFrame.origin.x += 3;
// changed by mitsu 2002.12.02 from Apple Sample code
		imageFrame.size.height = imageSize.height;
		if (imageFrame.size.width > imageSize.width)
			imageFrame.size.width = imageSize.width;

		if ( ! [controlView isFlipped])	// I don't know why ! was necessary
			imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
		else
			imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);

		NSRect imageSrcRect;
		imageSrcRect.size = imageSize;
		imageSrcRect.origin = NSMakePoint(0,0);
		[image drawInRect: imageFrame fromRect: imageSrcRect
						operation: NSCompositeSourceOver fraction: 1.0];
// original was:
		//imageFrame.size = imageSize;

		//if ([controlView isFlipped])
		//    imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
		//else
		//    imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);

		//[image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
// change end
	}
	[super drawWithFrame:cellFrame inView:controlView];
}

- (NSSize)cellSize {
	NSSize cellSize = [super cellSize];
	//cellSize.width += (image ? [image size].width : 0) + 3;
	return cellSize;
}

@end
