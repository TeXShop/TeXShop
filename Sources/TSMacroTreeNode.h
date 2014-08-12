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
 * $Id: TSMacroTreeNode.h 159 2006-05-24 23:45:37Z fingolfin $
 *
 * Created by Mitsuhiro Shishikura on Wed Dec 18 2002.
 * This code was derived from Apple Sample code DrangNDropOutlineView
 *
 */

#import <Cocoa/Cocoa.h>

#define NAME_KEY		@"name"
#define CONTENT_KEY 	@"content"
#define SUBMENU_KEY 	@"submenu"
#define KEYEQUIV_KEY 	@"key"

#define PARENT_KEY 		@"parent"
#define CHILDREN_KEY 	@"submenu"
#define ICON_KEY 		@"icon"

#define SEPARATOR 		@"Separator"


@interface TSMacroTreeNode : NSObject {
// basic tree parameters
	TSMacroTreeNode *_nodeParent;
	NSMutableArray *_nodeChildren;
// specific to this implementation
	NSString *_name;
	NSString *_content;
	NSString *_key;
}

@property (retain) TSMacroTreeNode *nodeParent;
@property (retain) NSMutableArray *nodeChildren;
@property (retain) NSString       *name;
@property (retain) NSString       *content;
@property (retain) NSString       *key;

@property (retain) NSString      *realName;
@property (retain) NSString      *realContent;
@property (retain) NSString      *realKey;

- (id)initWithParent:(TSMacroTreeNode*)parent children:(NSArray*)children;

// basic tree structure from Apple Sample code DragNDropOutlineView/TreeNode
// - (void)setNodeParent:(TSMacroTreeNode*)parent;
// - (TSMacroTreeNode*)nodeParent;
- (BOOL)isAlive;	// usually an item is alive if and only if it has nodeParent except forthe root of tree

- (void)addChild:(TSMacroTreeNode*)child;
- (void)addChildren:(NSArray*)children;
- (void)insertChild:(TSMacroTreeNode*)child atIndex:(NSInteger)idx;
- (void)insertChildren:(NSArray*)children atIndex:(NSInteger)idx;
- (void)removeChild:(TSMacroTreeNode*)child;
- (void)removeFromParent;

- (NSInteger)indexOfChild:(TSMacroTreeNode*)child;
- (NSInteger)indexOfChildIdenticalTo:(TSMacroTreeNode*)child;

- (NSInteger)numberOfChildren;
- (NSArray*)children;
- (TSMacroTreeNode*)firstChild;
- (TSMacroTreeNode*)lastChild;
- (TSMacroTreeNode*)childAtIndex:(NSInteger)idx;

- (BOOL)isDescendantOfNode:(TSMacroTreeNode*)node;
	// returns YES if 'node' is an ancestor.
- (BOOL)isDescendantOfNodeInArray:(NSArray*)nodes;
	// returns YES if any 'node' in the array 'nodes' is an ancestor of ours.
- (void)recursiveSortChildren;

+ (NSArray *)minimumNodeCoverFromNodesInArray: (NSArray *)allNodes;
	// Returns the minimum nodes from 'allNodes' required to cover the nodes in 'allNodes'.
	// This methods returns an array containing nodes from 'allNodes' such that no node in
	// the returned array has an ancestor in the returned array.

- (NSComparisonResult)compare:(TSMacroTreeNode*)node;

///////////////////////////////////////////////////////////////////////
// modified from DragNDropOutlineView/SimpleTreeNode

+ (id)nodeWithName:(NSString*)name content:(NSString*)content key:(NSString*)key;
+ (id)submenuNodeWithName: (NSString*)name;
+ (id)separatorNode;

// getting and setting properties
// - (NSString*)name;
// - (void)setName: (NSString*)name;

// - (NSString*)content;
// - (void)setContent:(NSString*)aContent;

// - (NSString*)key;
// - (void)setKey:(NSString*)key;

- (BOOL)isLeaf;
- (BOOL)isGroup;
- (BOOL)isExpandable;
- (BOOL)isEditable;
- (BOOL)isStandardItem; // not Group, not Separator
- (BOOL)isSeparator;

- (void) examine;

- (TSMacroTreeNode *)duplicateNode;
+ (NSArray *)duplicateNodeArray: (NSArray *)srcNodeArray;

// building tree from dictionary
+ (id)nodeFromDictionary: (NSDictionary*)dict;
+ (NSArray *)nodeArrayFromPropertyList: (id)propertyList;
- (void)appendNodesFromPropertyList: (id)propertyList;

// building dictionary from tree
- (NSMutableDictionary*)makeDictionary;

@end

// ================================================================
// NSArray_Extensions.
// ================================================================

@interface NSArray (MyExtensions)
- (BOOL)containsObjectIdenticalTo: (id)object;
@end

@interface NSMutableArray (MyExtensions)
- (void) insertObjectsFromArray:(NSArray *)array atIndex:(NSInteger)idx;
@end


// For debugging --to watch init, retain, release and dealloc of nodes, activate the following line
//#define DEBUG_TREE

#define PRINT(str1, str2) (printf("%s: %s\n", (str1)?[str1 cStringUsingEncoding: NSASCIIstringEncoding]:nil, (str2)?[str2 cStringUsingEncoding: NSASCIIStringEncoding]:nil))

// #warning 64BIT: Check formatting arguments
#define _PRINT_NODE_INFO(str, node, ptr) (printf("[%p] %s(%d): %s\n", (ptr), (str)?[str cStringUsingEncoding: NSASCIIStringEncoding]:nil, [node retainCount], ([node name])?[[node name] cStringUsingEncoding: NSASCIIStringEncoding]:"(no name)"))
#define NODE_INFO(str, node) (_PRINT_NODE_INFO(str, node, node))
#define NODE_INFO_PLUS(str, node) (_PRINT_NODE_INFO(str, node, node+1))
#define NODE_INFO_MINUS(str, node) (_PRINT_NODE_INFO(str, node, node-1))
