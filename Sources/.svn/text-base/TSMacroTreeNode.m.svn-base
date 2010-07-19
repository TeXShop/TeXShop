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
 * $Id$
 *
 * Created by Mitsuhiro Shishikura on Wed Dec 18 2002.
 * This code was derived from Apple Sample code DrangNDropOutlineView
 *
 */

#import "TSMacroTreeNode.h"


@implementation TSMacroTreeNode

// ================================================================
// Basic initialization and deallocation
// ================================================================

- (id)initWithParent:(TSMacroTreeNode*)parent children:(NSArray*)children
{
	// NOTE: children will be nil for a  non-group item.
	
	if ((self = [super init])) {
		_nodeParent = parent;
		_nodeChildren = [children mutableCopy];

		_name = nil;
		_content = nil;
		_key = nil;
	}
	return self;
}

- (void)dealloc {
#ifdef DEBUG_TREE
	NODE_INFO(@"dealloc", self);
#endif
	[_nodeChildren release];
	[_name release];
	[_content release];
	[_key release];

	[super dealloc];
}

#ifdef DEBUG_TREE
- (id)retain
{
	NODE_INFO_PLUS(@"  retained", self);
	return [super retain];
}

- (void)release
{
	NODE_INFO_MINUS(@"  released", self);
	[super release];
}
#endif

// ================================================================
// Methods used to manage a node and its children.
// ================================================================

- (void)setNodeParent:(TSMacroTreeNode*)parent
{
	_nodeParent = parent;
}

- (TSMacroTreeNode*)nodeParent
{
	return _nodeParent;
}

- (BOOL)isAlive	// usually an item is alive if and only if it has nodeParent except forthe root of tree
{
	return (_nodeParent != nil);
}

- (void)addChild:(TSMacroTreeNode*)child
{
	if (!child)
		return;
	if (!_nodeChildren)
		_nodeChildren = [[NSMutableArray alloc] init];
	[_nodeChildren addObject: child];
	[child setNodeParent: self];
}

- (void)addChildren:(NSArray*)children
{
	if (!_nodeChildren)
		_nodeChildren = [[NSMutableArray alloc] init];
	[_nodeChildren addObjectsFromArray: children];
	[children makeObjectsPerformSelector:@selector(setNodeParent:) withObject:self];
}

- (void)insertChild:(TSMacroTreeNode*)child atIndex:(int)idx
{
	if (!_nodeChildren)
		_nodeChildren = [[NSMutableArray alloc] init];
	[_nodeChildren insertObject:child atIndex:idx];
	[child setNodeParent: self];
}

- (void)insertChildren:(NSArray*)children atIndex:(int)idx
{
	if (!_nodeChildren)
		_nodeChildren = [[NSMutableArray alloc] init];
	[_nodeChildren insertObjectsFromArray: children atIndex: idx];
	[children makeObjectsPerformSelector:@selector(setNodeParent:) withObject:self];
}

- (void)removeChildrenIdenticalTo:(NSArray*)children
{
	if (!children || !_nodeChildren)
		return;
	TSMacroTreeNode *child;
	NSEnumerator *childEnumerator = [children objectEnumerator];
	[children makeObjectsPerformSelector:@selector(setNodeParent:) withObject:nil];
	while ((child=[childEnumerator nextObject])) {
		[_nodeChildren removeObjectIdenticalTo:child];
	}
}

- (void)removeChild:(TSMacroTreeNode*)child
{
	int idx = [self indexOfChild: child];
	if (idx!=NSNotFound) {
		[self removeChildrenIdenticalTo: [NSArray arrayWithObject: [self childAtIndex:idx]]];
	}
}

- (void)removeFromParent
{
	if ([self nodeParent])
		[[self nodeParent] removeChild: self];
}

- (int)indexOfChild:(TSMacroTreeNode*)child
{
	if (_nodeChildren)
		return [_nodeChildren indexOfObject: child];
	else
		return NSNotFound;
}

- (int)indexOfChildIdenticalTo:(TSMacroTreeNode*)child
{
	if (_nodeChildren)
		return [_nodeChildren indexOfObjectIdenticalTo: child];
	else
		return NSNotFound;
}

- (int)numberOfChildren
{
	return [_nodeChildren count];
}

- (NSArray*)children
{
	if (_nodeChildren)
		return [NSArray arrayWithArray: _nodeChildren];
	else
		return [NSArray array];
}

- (TSMacroTreeNode*)firstChild
{
	return [_nodeChildren objectAtIndex:0];
}

- (TSMacroTreeNode*)lastChild
{
	return [_nodeChildren lastObject];
}

- (TSMacroTreeNode*)childAtIndex:(int)idx
{
	return [_nodeChildren objectAtIndex:idx];
}

- (BOOL)isDescendantOfNode:(TSMacroTreeNode*)node
{	// returns YES if 'node' is an ancestor.
	// Walk up the tree, to see if any of our ancestors is 'node'.
	TSMacroTreeNode *parent = self;
	while (parent) {
		if (parent == node)
			return YES;
		parent = [parent nodeParent];
	}
	return NO;
}

- (BOOL)isDescendantOfNodeInArray:(NSArray*)nodes
{	// returns YES if any 'node' in the array 'nodes' is an ancestor of ours.
	// For each node in nodes, if node is an ancestor return YES.  If none is an
	// ancestor, return NO.
	NSEnumerator *nodeEnum = [nodes objectEnumerator];
	TSMacroTreeNode *node = nil;
	while((node=[nodeEnum nextObject])) {
		if([self isDescendantOfNode:node]) return YES;
	}
	return NO;
}

- (void)recursiveSortChildren
{
	[_nodeChildren sortUsingSelector:@selector(compare:)];
	[_nodeChildren makeObjectsPerformSelector: @selector(recursiveSortChildren)];
}

- (NSString*)description
{	// Return something that will be useful for debugging.
	return [NSString stringWithFormat: @"{%@}", self];
}

// Returns the minimum nodes from 'allNodes' required to cover the nodes in 'allNodes'.
// This methods returns an array containing nodes from 'allNodes' such that no node in
// the returned array has an ancestor in the returned array.

// There are better ways to compute this, but this implementation should be efficient for our app.
+ (NSArray *) minimumNodeCoverFromNodesInArray: (NSArray *)allNodes
{
	NSMutableArray *minimumCover = [NSMutableArray array];
	NSMutableArray *nodeQueue = [NSMutableArray arrayWithArray:allNodes];
	TSMacroTreeNode *node = nil;
	while ([nodeQueue count]) {
		node = [nodeQueue objectAtIndex:0];
		[nodeQueue removeObjectAtIndex:0];
		while ( [node nodeParent] && [nodeQueue containsObjectIdenticalTo:[node nodeParent]] ) {
			[nodeQueue removeObjectIdenticalTo: node];
			node = [node nodeParent];
		}
		if (![node isDescendantOfNodeInArray: minimumCover]) [minimumCover addObject: node];
		[nodeQueue removeObjectIdenticalTo: node];
	}
	return minimumCover;
}

- (NSComparisonResult)compare:(TSMacroTreeNode*)node
{	// Return anything, it is expected this will be overridden by subclasses.
	// For instance, SimpleTree compares names!	//NSOrderedAscending
	return [[self name] compare: [node name]];
}

// ================================================================
// Method specific for this implementation
// ================================================================

+ (id)nodeWithName: (NSString*)aName content: (NSString*)aContent key: (NSString*)keyEquiv
{
	TSMacroTreeNode *node = [[[TSMacroTreeNode alloc] initWithParent: nil children: nil] autorelease];
	[node setName: (aName)?aName:@""];
	if (aContent)
		[node setContent: aContent];
	if (keyEquiv)
		[node setKey: keyEquiv];
#ifdef DEBUG_TREE
	PRINT(@"StdNode created", aName);
#endif
	return node;
}

+ (id)submenuNodeWithName: (NSString*)aName
{
	NSMutableArray *children = [[NSMutableArray alloc] init];
	TSMacroTreeNode *node = [[[TSMacroTreeNode alloc] initWithParent: nil children: children] autorelease];
	[node setName: (aName)?aName:@""];
#ifdef DEBUG_TREE
	PRINT(@"SubmenuNode created", aName);
#endif
	return node;
}

+ (id)separatorNode
{
	TSMacroTreeNode *node = [[[TSMacroTreeNode alloc] initWithParent: nil children: nil] autorelease];
	[node setName: SEPARATOR];
#ifdef DEBUG_TREE
	PRINT(@"SeparatorNode created", SEPARATOR);
#endif
	return node;
}


// getting and setting properties

- (NSString*)name
{
	return _name ? _name : @"";
}

- (void)setName: (NSString*)aName
{
	[aName retain];
	[_name release];
	_name = aName;
}


- (NSString*)content
{
	return _content ? _content : @"";
}

- (void)setContent:(NSString*)aContent
{
	[aContent retain];
	[_content release];
	_content = aContent;
}


- (NSString*)key
{
	return _key ? _key : @"";
}

- (void)setKey: (NSString*)aKey
{
	[aKey retain];
	[_key release];
	_key = aKey;
}


- (BOOL)isLeaf
{
	return (_nodeChildren == nil);
}

- (BOOL)isGroup
{
	return (_nodeChildren != nil);
}


- (BOOL)isExpandable
{
	return (_nodeChildren != nil);
}

- (BOOL)isEditable
{
	return NO;
}

- (BOOL)isStandardItem // not Group, not Separator
{
	return ((_nodeChildren == nil) && ![_name isEqualToString: SEPARATOR]);
}

- (BOOL)isSeparator
{
	return ((_nodeChildren == nil) && [_name isEqualToString: SEPARATOR]);
}


// for debug
- (void) examine
{
	NODE_INFO(@"examine", self);

	NSArray *children = [self children];
	if (children) {
		NSEnumerator *enumerator = [children objectEnumerator];
		id node;
		while ((node = [enumerator nextObject])) {
			[node examine];
			//[node release];
		}
	}
	//[children release];
}


- (TSMacroTreeNode *)duplicateNode
{
	TSMacroTreeNode *newNode = [[[TSMacroTreeNode alloc] initWithParent: nil
						children: (_nodeChildren)?[NSArray array]:nil] autorelease];
	[newNode setName: [self name]];
	if ([self content])
		[newNode setContent: [self content]];
	//if ([self key])
	//	[newNode setKey: [self key]];	// do not copy key
	if (_nodeChildren) {
		NSEnumerator *enumerator = [_nodeChildren objectEnumerator];
		TSMacroTreeNode *srcChild, *newChild;
		while ((srcChild = [enumerator nextObject])) {
			newChild = [srcChild duplicateNode];
			if (newChild)
				[newNode addChild: newChild];
		}
	}
	return newNode;
}

+ (NSArray *)duplicateNodeArray: (NSArray *)srcNodeArray
{
	NSArray *tempArray;
	NSMutableArray *newArray = [NSMutableArray array];
	tempArray = [TSMacroTreeNode minimumNodeCoverFromNodesInArray: srcNodeArray];
	NSEnumerator *enumerator = [tempArray objectEnumerator];
	TSMacroTreeNode *node;
	while ((node = [enumerator nextObject])) {
		[newArray addObject: [node duplicateNode]];
	}
	return newArray;
}


// ================================================================
// Building tree from dictionary.
// ================================================================

+ (id)nodeFromDictionary: (NSDictionary*)dict
{
	TSMacroTreeNode *node, *child;
	NSString *aName, *aContent, *keyEquiv;
	NSArray *srcChildren;
	NSDictionary *srcChild;

	aName = [dict objectForKey: NAME_KEY];
	if (aName == nil)
		return nil;
	node = [[[TSMacroTreeNode alloc]  initWithParent: nil children: nil] autorelease];
#ifdef DEBUG_TREE
	NODE_INFO(@"DictNode created", node);
#endif
	[node setName: aName];
	aContent = [dict objectForKey: CONTENT_KEY];
	if (aContent)
		[node setContent: aContent];
	keyEquiv = [dict objectForKey: KEYEQUIV_KEY];
	if (keyEquiv)
		[node setKey: keyEquiv];
	srcChildren = [dict objectForKey: CHILDREN_KEY];
	if ([srcChildren isKindOfClass:[NSArray class]]) {
		NSEnumerator *enumerator = [srcChildren objectEnumerator];
		while ((srcChild = (NSDictionary *)[enumerator nextObject])) {
			child = [TSMacroTreeNode nodeFromDictionary: srcChild];
			if (child)
			[node addChild: child];
		}
	}
#ifdef DEBUG_TREE
	NODE_INFO(@"DictNode ready", node);
#endif
	return node;
}


+ (NSArray *)nodeArrayFromPropertyList: (id)propertyList
{
	NSMutableArray *nodeArray;
	NSArray *dictArray = nil;
	NSEnumerator *enumerator, *keyEnum;
	id obj, obj2, theKey;
	TSMacroTreeNode *node, *submenu;
	
	nodeArray = [NSMutableArray array];
	if ([propertyList isKindOfClass: [NSDictionary class]]) {
		obj = [propertyList objectForKey: NAME_KEY];
		if (obj && [obj isKindOfClass: [NSString class]] &&
			[obj isEqualToString: @"ROOT"]) {
			obj2 = [propertyList objectForKey: CHILDREN_KEY];
			if (obj2 && [obj2 isKindOfClass: [NSArray class]])
				dictArray = obj2;
		}
	} else if ([propertyList isKindOfClass: [NSArray class]])
		dictArray = propertyList;
	if (dictArray) {
		enumerator = [dictArray objectEnumerator];
		while ((obj = [enumerator nextObject])) {
			if ([obj isKindOfClass: [NSDictionary class]]) {
				node = [TSMacroTreeNode nodeFromDictionary: obj];
				if (node)
					[nodeArray addObject: node];
			}
		}
	} else if ([propertyList isKindOfClass: [NSDictionary class]]) {
		// LaTeX Panel style dictionary
		keyEnum = [propertyList keyEnumerator];
		while ((theKey = [keyEnum nextObject])) {
			if ([theKey isKindOfClass: [NSString class]] &&
				((dictArray = [propertyList objectForKey: theKey])) &&
				[dictArray isKindOfClass: [NSArray class]]) {
				submenu = [TSMacroTreeNode submenuNodeWithName: theKey];
				[nodeArray addObject: submenu];
				enumerator = [dictArray objectEnumerator];
				while ((obj = [enumerator nextObject])) {
					if ([obj isKindOfClass: [NSString class]]) {
						NSMutableString *nameStr = [[obj substringToIndex:MIN([obj length], 50)] mutableCopy];
						[nameStr replaceOccurrencesOfString: @"\n" withString: @""
													options: 0 range: NSMakeRange(0, [nameStr length])];
						node = [TSMacroTreeNode nodeWithName: nameStr content: obj key: @""];
						[nameStr release];
						[submenu addChild: node];
					}
				}
			}
		}
	}
	return nodeArray;
}

// do not add directly --for notification, use addNewDataArrayToSelection
- (void)appendNodesFromPropertyList: (id)propertyList
{
	NSArray *array=nil;
	NSEnumerator *enumerator, *keyEnum;
	id obj, obj2, theKey;
	TSMacroTreeNode *node, *submenu;
	if ([propertyList isKindOfClass: [NSDictionary class]]) {
		obj = [propertyList objectForKey: NAME_KEY];
		if (obj && [obj isKindOfClass: [NSString class]] &&
			[obj isEqualToString: @"ROOT"]) {
			obj2 = [propertyList objectForKey: CHILDREN_KEY];
			if (obj2 && [obj2 isKindOfClass: [NSArray class]])
				array = obj2;
		}
	} else if ([propertyList isKindOfClass: [NSArray class]]) {
		array = propertyList;
	}
	
	if (array) {
		enumerator = [array objectEnumerator];
		while ((obj = [enumerator nextObject])) {
			if ([obj isKindOfClass: [NSDictionary class]])
			{
				node = [TSMacroTreeNode nodeFromDictionary: obj];
				if (node)
					[self addChild: node];
			}
		}
	} else if ([propertyList isKindOfClass: [NSDictionary class]]) {
		// LaTeX Panel style dictionary
		keyEnum = [propertyList keyEnumerator];
		while ((theKey = [keyEnum nextObject])) {
			if ([theKey isKindOfClass: [NSString class]] &&
				(array = [propertyList objectForKey: theKey]) &&
				[array isKindOfClass: [NSArray class]]) {
				submenu = [TSMacroTreeNode submenuNodeWithName: theKey];
				[self addChild: submenu];
				enumerator = [array objectEnumerator];
				while ((obj = [enumerator nextObject])) {
					if ([obj isKindOfClass: [NSString class]]) {
						NSMutableString *nameStr = [NSMutableString stringWithString:
							[(NSString *)obj substringToIndex:
									([(NSString *)obj length]<50)?[(NSString *)obj length]:50]];
						[nameStr replaceOccurrencesOfString: @"\n" withString: @""
									options: 0 range: NSMakeRange(0, [nameStr length])];
						node = [TSMacroTreeNode nodeWithName: nameStr content: obj key: @""];
						[submenu addChild: node];
					}
				}
			}
		}
	}
}

// building dictionary from tree

- (NSMutableDictionary*)makeDictionary
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	if (_name)
		[dict setObject: _name forKey: NAME_KEY];
	if (_content)
		[dict setObject: _content forKey: CONTENT_KEY];
	if (_key)
		[dict setObject: _key forKey: KEYEQUIV_KEY];
	if (_nodeChildren) {
		NSMutableArray *array = [NSMutableArray array];
		NSEnumerator *enumerator = [_nodeChildren objectEnumerator];
		TSMacroTreeNode *child;
		while ((child = (TSMacroTreeNode *)[enumerator nextObject])) {
			NSMutableDictionary *newdict = [child makeDictionary];
			[array addObject: newdict];
		}
		[dict setObject: array forKey: CHILDREN_KEY];
	}
	return dict;
}

@end

// ================================================================
// NSArray_Extensions.
// ================================================================

@implementation NSArray (MyExtensions)

- (BOOL) containsObjectIdenticalTo: (id)obj {
	return [self indexOfObjectIdenticalTo: obj] != NSNotFound;
}

@end

@implementation NSMutableArray (MyExtensions)

- (void) insertObjectsFromArray:(NSArray *)array atIndex:(int)idx {
	NSObject *entry = nil;
	NSEnumerator *enumerator = [array objectEnumerator];
	while ((entry = [enumerator nextObject])) {
		[self insertObject:entry atIndex:idx++];
	}
}

@end
