//
//  OutlineViewController.m
//
//  Created by Mitsuhiro Shishikura on Wed Dec 18 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
//	This code was derived from Apple Sample code DrangNDropOutlineView

#import "OutlineViewController.h"

#import "MacroMenuController.h"
#import "MyTreeNode.h"
#import "EncodingSupport.h"
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

#define SUD [NSUserDefaults standardUserDefaults]

extern int shouldFilter;

// ================================================================
// Method implimentations
// ================================================================

@implementation OutlineViewController

static OutlineViewController *sharedOutlineViewController = nil;

+ (id)sharedInstance 
{
    if (sharedOutlineViewController == nil) 
        sharedOutlineViewController = [[[OutlineViewController alloc] init] autorelease];
    return sharedOutlineViewController;
}

- (id)init 
{
    if (sharedOutlineViewController) 
        [super dealloc];
	else
	{
		sharedOutlineViewController = [super init];
		rootOfTree = nil; //[[MyTreeNode alloc] init];
		draggedNodes = nil;
	}
	return sharedOutlineViewController;
}

- (void)dealloc 
{
	if (rootOfTree)
		[rootOfTree release];
	if (draggedNodes)
		[draggedNodes release];
	[super dealloc];
	sharedOutlineViewController = nil;
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

- (void)setRootOfTree: (MyTreeNode *)newRootOfTree
{
	if (rootOfTree)
		[rootOfTree release];
	rootOfTree = (newRootOfTree)?[newRootOfTree retain]:nil;
	draggedNodes = nil;
	if (outlineView)
		[outlineView reloadData];
}

- (MyTreeNode *)rootOfTree
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
	[self addNewDataToSelection: [MyTreeNode nodeWithName: NEW_ITEM_NAME content: nil key: nil]];
}

- (void)addSubmenu: (id)sender
{
	[self addNewDataToSelection: [MyTreeNode submenuNodeWithName: NEW_SUBMENU_NAME]];
}

- (void)addSeparator: (id)sender
{
	[self addNewDataToSelection: [MyTreeNode separatorNode]];
}

- (void)addNewDataToSelection:(MyTreeNode *)newChild 
{
    int childIndex = 0, newRow = 0;
    NSArray *selectedNodes = [self selectedNodes];
//    MyTreeNode *selectedNode = ([selectedNodes count] ? [selectedNodes objectAtIndex:0] : rootOfTree); // this was changed to the following
	MyTreeNode *selectedNode = ([selectedNodes count] ? [selectedNodes lastObject] : rootOfTree);
    MyTreeNode *parentNode = nil;

	if ([selectedNode isGroup]) 
	{ 
		parentNode = selectedNode; 
		childIndex = [parentNode numberOfChildren]; // it was 0; 
		[outlineView expandItem: selectedNode];
    }
    else 
	{ 
		parentNode = [selectedNode nodeParent]; 
		childIndex = [parentNode indexOfChildIdenticalTo:selectedNode]+1; 
    }
    
    [parentNode insertChild: newChild atIndex: childIndex];
    [outlineView reloadData];
    
    newRow = [outlineView rowForItem: newChild];
    if (newRow>=0) 
		[outlineView selectRow: newRow byExtendingSelection: NO];
    if (newRow>=0) 
	{
		//if ([newChild isGroup])
		//	[outlineView editColumn:0 row:newRow withEvent:nil select:YES];	// this will make it editable
	}
	//if ([outlineView action] && [outlineView target])	// to send the action on new item
	//	[outlineView sendAction: [outlineView action] to: [outlineView target]];
	
#ifdef MyOutlineViewAddedItemNotification
	// notify that item was added -- custom notification
	[[NSNotificationCenter defaultCenter] postNotificationName: MyOutlineViewAddedItemNotification 
					object: outlineView];
#endif
}

- (void)addNewDataArrayToSelection:(NSArray *)newChildren 
{
    int childIndex = 0; //, newRow = 0;
    NSArray *selectedNodes = [self selectedNodes];
//    MyTreeNode *selectedNode = ([selectedNodes count] ? [selectedNodes objectAtIndex:0] : rootOfTree); // this was changed to the following
	MyTreeNode *selectedNode;
    MyTreeNode *parentNode = nil;

	if ([selectedNodes count]==0) 
	{
		parentNode = rootOfTree;
		childIndex = [rootOfTree numberOfChildren];
	}
    else 
	{ 
		selectedNode = [selectedNodes lastObject];
		parentNode = [selectedNode nodeParent]; 
		childIndex = [parentNode indexOfChildIdenticalTo:selectedNode]+1; 
    }
    
    [parentNode insertChildren: newChildren atIndex: childIndex];
    [outlineView reloadData];
    
    [outlineView selectItems: newChildren byExtendingSelection: NO];
//    newRow = [outlineView rowForItem: [newChildren objectAtIndex: 0]];
//    if (newRow>=0) 
//	{
		//if ([newChild isGroup])
		//	[outlineView editColumn:0 row:newRow withEvent:nil select:YES];	// this will make it editable
//	}
	
#ifdef MyOutlineViewAddedItemNotification
	// notify that item was added -- custom notification
	[[NSNotificationCenter defaultCenter] postNotificationName: MyOutlineViewAddedItemNotification 
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

#ifdef MyOutlineViewRemovedItemNotification
	// notify that item was deleted -- custom notification
	[[NSNotificationCenter defaultCenter] postNotificationName: MyOutlineViewRemovedItemNotification 
					object: outlineView];
#endif
}

- (void)duplicateSelection: (id)sender
{
	NSArray *selection = [self selectedNodes];
	if ([selection count] == 0)
		return;
	[self addNewDataArrayToSelection: [MyTreeNode duplicateNodeArray: selection]];
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
- (id)outlineView:(NSOutlineView *)olv child:(int)index ofItem:(id)item 
{
    return [(item)?((MyTreeNode*)item):rootOfTree childAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)olv isItemExpandable:(id)item 
{
    return [(MyTreeNode*)item isExpandable];
}

- (int)outlineView:(NSOutlineView *)olv numberOfChildrenOfItem:(id)item 
{
    return [(item)?((MyTreeNode*)item):rootOfTree numberOfChildren];
}

- (id)outlineView:(NSOutlineView *)olv objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
    id objectValue = nil;   
    // The return value from this method is used to configure the state of the items cell via setObjectValue:

#ifdef DEBUG_TREE
	NODE_INFO(@"ObjValue", item);
#endif    
	
	if([[tableColumn identifier] isEqualToString: COLUMNID_NAME]) 
	{
		if ([(MyTreeNode*)item isSeparator])
			objectValue = @"";
		else
		{
			objectValue = [(MyTreeNode*)item name];
		}
    } 
	else if([[tableColumn identifier] isEqualToString: COLUMNID_KEY]) 
	{
		objectValue = getMenuItemString([(MyTreeNode*)item key]);
    }
    return objectValue;
}

// Optional method: needed to allow editing.
- (void)outlineView:(NSOutlineView *)olv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item  
{
    if([[tableColumn identifier] isEqualToString: COLUMNID_NAME]) 
	{
		[(MyTreeNode*)item setName: object];
    } 
	else if ([[tableColumn identifier] isEqualToString: COLUMNID_KEY]) 
	{
		[(MyTreeNode*)item setKey: object];
    }

}

// ================================================================
//  NSOutlineView delegate methods.
// ================================================================
//  Need Interface Builder connection: 
//		NSOutlineView.delegate -> Instance of this class (or file's owner)

- (BOOL)outlineView:(NSOutlineView *)olv shouldExpandItem:(id)item 
{
    return [(MyTreeNode*)item isExpandable];
}

- (BOOL)outlineView:(NSOutlineView *)olv shouldEditTableColumn: (NSTableColumn *)tableColumn item: (id)item 
{
	return [(MyTreeNode*)item isEditable];
}

- (void)outlineView: (NSOutlineView *)olv willDisplayCell: (NSCell *)cell forTableColumn: (NSTableColumn *)tableColumn item: (id)item 
{    
    if ([[tableColumn identifier] isEqualToString: COLUMNID_NAME]) 
	{
		//if (item && [(MyTreeNode*)item iconRep]) // when there is an icon
		//	[(ImageAndTextCell*)cell setImage: [(MyTreeNode*)item iconRep]];
		//else 
		if (item && [item isSeparator])
		{
			
			[(ImageAndTextCell*)cell setImage: [NSImage imageNamed: SEPARATOR_IMAGE]];
		}
		else
			[(ImageAndTextCell*)cell setImage: nil];
    } 
	else if ([[tableColumn identifier] isEqualToString: COLUMNID_KEY]) 
	{
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
	if (shouldFilter == filterMacJ) 
	{
		if ([SUD boolForKey:@"ConvertToBackslash"]) // this case isn't necessary?
			draggedString = filterYenToBackslash(draggedString);
		else
			draggedString = filterBackslashToYen(draggedString);
	}
	else if (shouldFilter == filterNSSJIS) 
	{
		if ([SUD boolForKey:@"ConvertToYen"])
			draggedString = filterBackslashToYen(draggedString);
		else	// this case shouldn't be necessary
			draggedString = filterYenToBackslash(draggedString);
	}
	[pboard setString: draggedString forType: NSStringPboardType];

    return YES;
}

- (unsigned int)outlineView:(NSOutlineView*)olv validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)childIndex 
{
    // This method validates whether or not the proposal is a valid one. Returns NO if the drop should not be allowed.
    MyTreeNode *targetNode = item;
    BOOL targetNodeIsValid = YES;

    if (onlyAcceptDropOnRoot)
	{
		targetNode = nil;
		childIndex = NSOutlineViewDropOnItemIndex;
    } 
	else 
	{
		BOOL isOnDropTypeProposal = childIndex==NSOutlineViewDropOnItemIndex;
		
		// Refuse if: dropping "on" the view itself unless we have no data in the view.
		if ((targetNode==nil) && (childIndex==NSOutlineViewDropOnItemIndex) && 
								([rootOfTree numberOfChildren]!=0)) 
			targetNodeIsValid = NO;
		
		if ((targetNode==nil) && (childIndex==NSOutlineViewDropOnItemIndex) && ((allowOnDropOnLeaf)==NO))
			targetNodeIsValid = NO;
		
		// Refuse if: we are trying to do something which is not allowed.
		if ((targetNodeIsValid && isOnDropTypeProposal==NO && allowBetweenDrop==NO) ||
			([(MyTreeNode*)targetNode isGroup] && isOnDropTypeProposal==YES && allowOnDropOnGroup==NO) ||
			([(MyTreeNode*)targetNode isLeaf ] && isOnDropTypeProposal==YES && allowOnDropOnLeaf==NO))
			targetNodeIsValid = NO;
			
		// Check to make sure we don't allow a node to be inserted into one of its descendants!
		if (targetNodeIsValid && ([info draggingSource]==outlineView) && [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject: DragDropSimplePboardType]] != nil) 
		{
			NSArray *_draggedNodes = [[[info draggingSource] dataSource] draggedNodes];
			targetNodeIsValid = ![targetNode isDescendantOfNodeInArray: _draggedNodes];
		}
    }
    
    // Set the item and child index in case we computed a retargeted one.
    [outlineView setDropItem:targetNode dropChildIndex:childIndex];
    
    return targetNodeIsValid ? NSDragOperationGeneric : NSDragOperationNone;
}

- (void)_performDropOperation:(id <NSDraggingInfo>)info onNode:(MyTreeNode*)parentNode atIndex:(int)childIndex 
{
    // Helper method to insert dropped data into the model. 
    NSPasteboard * pboard = [info draggingPasteboard];
    NSMutableArray * itemsToSelect = nil;
    
    // Do the appropriate thing depending on whether the data is DragDropSimplePboardType or NSStringPboardType.
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:DragDropSimplePboardType, nil]] != nil) 
	{
        OutlineViewController *dragDataSource = [[info draggingSource] dataSource];
        NSArray *_draggedNodes = [MyTreeNode minimumNodeCoverFromNodesInArray: [dragDataSource draggedNodes]];
        NSEnumerator *draggedNodesEnum = [_draggedNodes objectEnumerator];
        MyTreeNode *_draggedNode = nil, *_draggedNodeParent = nil;
        
	itemsToSelect = [NSMutableArray arrayWithArray:[self selectedNodes]];
	
        while ((_draggedNode = [draggedNodesEnum nextObject])) 
		{
            _draggedNodeParent = (MyTreeNode *)[_draggedNode nodeParent];
            if (parentNode==_draggedNodeParent && [parentNode indexOfChild: _draggedNode]<childIndex) 
				childIndex--;
            [_draggedNodeParent removeChild: _draggedNode];
        }
        [parentNode insertChildren: _draggedNodes atIndex: childIndex];
    } 
    else if ([pboard availableTypeFromArray:[NSArray arrayWithObject: NSStringPboardType]]) 
	{
        NSString *string = [pboard stringForType: NSStringPboardType];
		NSString *tempStr = string;
		if (shouldFilter == filterMacJ)	
			tempStr = filterBackslashToYen(string);
		else if (shouldFilter == filterNSSJIS)	
			tempStr = filterYenToBackslash(string);
		NSMutableString *nameStr = [NSMutableString stringWithString: 
							[tempStr substringToIndex: ([tempStr length]<50)?[tempStr length]:50]];
		[nameStr replaceOccurrencesOfString: @"\n" withString: @""
									options: 0 range: NSMakeRange(0, [nameStr length])];		
		if (shouldFilter)	// we only use backslashes
			string = filterYenToBackslash(string);
		MyTreeNode *newItem = [MyTreeNode nodeWithName: nameStr content: string key: nil];
		
		itemsToSelect = [NSMutableArray arrayWithObject: newItem];
		[parentNode insertChild: newItem atIndex:childIndex++];
    }

    [outlineView reloadData];
    [outlineView selectItems: itemsToSelect byExtendingSelection: NO];
}

- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)targetItem childIndex:(int)childIndex 
{
    MyTreeNode * 		parentNode = nil;
    
    // Determine the parent to insert into and the child index to insert at.
    if ([(MyTreeNode*)targetItem isLeaf]) 
	{
        parentNode = (MyTreeNode*)(childIndex==NSOutlineViewDropOnItemIndex ? [targetItem nodeParent] : targetItem);
        childIndex = (childIndex==NSOutlineViewDropOnItemIndex ? [[targetItem nodeParent] indexOfChild: targetItem]+1 : 0);
    } 
	else 
	{            
        parentNode = (targetItem)?targetItem:rootOfTree;
		childIndex = (childIndex==NSOutlineViewDropOnItemIndex?0:childIndex);
    }
    
    [self _performDropOperation:info onNode:parentNode atIndex:childIndex];
        
#ifdef MyOutlineViewAcceptedDropNotification
	// notify that item was moved or dropped -- custom notification
	[[NSNotificationCenter defaultCenter] postNotificationName: MyOutlineViewAcceptedDropNotification 
					object: outlineView];
#endif
    return YES;
}

@end


@implementation NSOutlineView (MyExtensions)

- (id)selectedItem { return [self itemAtRow: [self selectedRow]]; }

- (NSArray*)allSelectedItems {
    NSMutableArray *items = [NSMutableArray array];
    NSEnumerator *selectedRows = [self selectedRowEnumerator];
    NSNumber *selRow = nil;
    while( (selRow = [selectedRows nextObject]) ) {
        if ([self itemAtRow:[selRow intValue]]) 
            [items addObject: [self itemAtRow:[selRow intValue]]];
    }
    return items;
}

- (void)selectItems:(NSArray*)items byExtendingSelection:(BOOL)extend {
    int i;
    if (extend==NO) [self deselectAll:nil];
    for (i=0;i<[items count];i++) {
        int row = [self rowForItem:[items objectAtIndex:i]];
        if(row>=0) [self selectRow: row byExtendingSelection:YES];
    }
}

- (void)delete: (id)sender
{
	[[self delegate] deleteSelection: sender];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	if ([anItem action] == @selector(delete:))
	{
		return ([[self allSelectedItems] count] > 0);
	}
	else
		return YES;
}

@end


@implementation MyOutlineView 

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    if (isLocal) return NSDragOperationEvery;
    else return NSDragOperationCopy;
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

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
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
