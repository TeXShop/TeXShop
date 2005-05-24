//
//  MyTreeNode.m
//
//  Created by Mitsuhiro Shishikura on Wed Dec 18 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
//	This code was derived from Apple Sample code DrangNDropOutlineView

#import "MyTreeNode.h"


@implementation MyTreeNode

// ================================================================
// Basic initialization and deallocation
// ================================================================

- (id)initWithParent:(MyTreeNode*)parent children:(NSArray*)children 
{
    self = [super init];
    if (self==nil) 
		return nil;
    
    nodeParent = parent;
	if (children)
		nodeChildren = [[NSMutableArray arrayWithArray:children] retain];
	else
		nodeChildren = nil;
    
	name = nil;
	content = nil;
	key = nil;
    return self;
}

- (void)dealloc {
	if (nodeChildren)
		[nodeChildren release];
#ifdef DEBUG_TREE
	NODE_INFO(@"dealloc", self);
#endif
	if (name)
		[name release];
	if (content)
		[content release];
	if (key)
		[key release];
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

- (void)setNodeParent:(MyTreeNode*)parent 
{
    nodeParent = parent; 
}

- (MyTreeNode*)nodeParent 
{ 
    return nodeParent; 
}

- (BOOL)isAlive	// usually an item is alive if and only if it has nodeParent except forthe root of tree
{
	return (nodeParent != nil);
}

- (void)addChild:(MyTreeNode*)child 
{
    if (!nodeChildren)
		nodeChildren = [[NSMutableArray array] retain];
	if (!child)
		return;
	[nodeChildren addObject: child];
    [child setNodeParent: self];
}

- (void)addChildren:(NSArray*)children 
{
    if (!nodeChildren)
		nodeChildren = [[NSMutableArray array] retain];
    [nodeChildren addObjectsFromArray: children];
    [children makeObjectsPerformSelector:@selector(setNodeParent:) withObject:self];
}

- (void)insertChild:(MyTreeNode*)child atIndex:(int)index 
{
    if (!nodeChildren)
		nodeChildren = [[NSMutableArray array] retain];
	[nodeChildren insertObject:child atIndex:index];
    [child setNodeParent: self];
}

- (void)insertChildren:(NSArray*)children atIndex:(int)index 
{
    if (!nodeChildren)
		nodeChildren = [[NSMutableArray array] retain];
    [nodeChildren insertObjectsFromArray: children atIndex: index];
    [children makeObjectsPerformSelector:@selector(setNodeParent:) withObject:self];
}

- (void)_removeChildrenIdenticalTo:(NSArray*)children 
{
    if (!children || !nodeChildren)
		return;
	MyTreeNode *child;
    NSEnumerator *childEnumerator = [children objectEnumerator];
    [children makeObjectsPerformSelector:@selector(setNodeParent:) withObject:nil];
    while ((child=[childEnumerator nextObject])) {
        [nodeChildren removeObjectIdenticalTo:child];
    }
}

- (void)removeChild:(MyTreeNode*)child 
{
    int index = [self indexOfChild: child];
    if (index!=NSNotFound) {
        [self _removeChildrenIdenticalTo: [NSArray arrayWithObject: [self childAtIndex:index]]];
    }
}

- (void)removeFromParent 
{
	if ([self nodeParent])
		[[self nodeParent] removeChild: self];
}

- (int)indexOfChild:(MyTreeNode*)child 
{
	if (nodeChildren)
		return [nodeChildren indexOfObject: child];
	else
		return NSNotFound;
}

- (int)indexOfChildIdenticalTo:(MyTreeNode*)child 
{
	if (nodeChildren)
		return [nodeChildren indexOfObjectIdenticalTo: child];
	else
		return NSNotFound;
}

- (int)numberOfChildren 
{
	if (nodeChildren)
		return [nodeChildren count];
	else
		return 0;
}

- (NSArray*)children 
{
	if (nodeChildren)
		return [NSArray arrayWithArray: nodeChildren];
	else
		return [NSArray array];
}

- (MyTreeNode*)firstChild 
{
	if (nodeChildren)
		return [nodeChildren objectAtIndex:0];
	else
		return nil;
}

- (MyTreeNode*)lastChild 
{
	if (nodeChildren)
		return [nodeChildren lastObject];
	else
		return nil;
}

- (MyTreeNode*)childAtIndex:(int)index 
{
	if (nodeChildren)
		return [nodeChildren objectAtIndex:index];
	else
		return nil;
}

- (BOOL)isDescendantOfNode:(MyTreeNode*)node 
{	// returns YES if 'node' is an ancestor.
    // Walk up the tree, to see if any of our ancestors is 'node'.
    MyTreeNode *parent = self;
    while (parent) {
        if (parent==node) return YES;
        parent = [parent nodeParent];
    }
    return NO;
}

- (BOOL)isDescendantOfNodeInArray:(NSArray*)nodes 
{	// returns YES if any 'node' in the array 'nodes' is an ancestor of ours.
    // For each node in nodes, if node is an ancestor return YES.  If none is an
    // ancestor, return NO.
    NSEnumerator *nodeEnum = [nodes objectEnumerator];
    MyTreeNode *node = nil;
    while((node=[nodeEnum nextObject])) {
        if([self isDescendantOfNode:node]) return YES;
    }
    return NO;
}

- (void)recursiveSortChildren 
{
    [nodeChildren sortUsingSelector:@selector(compare:)];
    [nodeChildren makeObjectsPerformSelector: @selector(recursiveSortChildren)];
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
    MyTreeNode *node = nil;
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

- (NSComparisonResult)compare:(MyTreeNode*)node 
{	// Return anything, it is expected this will be overridden by subclasses.
    // For instance, SimpleTree compares names!	//NSOrderedAscending
    return [[self name] compare: [node name]];
}

// ================================================================
// Method specific for this implementation
// ================================================================

+ (id)nodeWithName: (NSString*)aName content: (NSString*)aContent key: (NSString*)keyEquiv
{
	MyTreeNode *node = [[[MyTreeNode alloc] initWithParent: nil children: nil] autorelease];
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
	NSMutableArray *children = [[NSMutableArray array] retain];
	MyTreeNode *node = [[[MyTreeNode alloc] initWithParent: nil children: children] autorelease];
	[node setName: (aName)?aName:@""];
#ifdef DEBUG_TREE
	PRINT(@"SubmenuNode created", aName);
#endif
	return node; 
}

+ (id)separatorNode
{
	MyTreeNode *node = [[[MyTreeNode alloc] initWithParent: nil children: nil] autorelease];
	[node setName: SEPARATOR];
#ifdef DEBUG_TREE
	PRINT(@"SeparatorNode created", SEPARATOR);
#endif
	return node;
}


// getting and setting properties

- (NSString*)name
{
	if (name)
		return name;
	else
		return @"";
}

- (void)setName: (NSString*)aName
{
    if (!name || ![name isEqualToString: aName]) 
	{
		[name release]; 
		name = [aName retain]; 
    }
}

	
- (NSString*)content
{
	if (content)
		return content;
	else
		return @"";
}

- (void)setContent:(NSString*)aContent
{
    if (!content || ![content isEqualToString: aContent]) 
	{
		[content release]; 
		content = [aContent retain]; 
    }
}


- (NSString*)key
{
	if (key)
		return key;
	else
		return @"";
}

- (void)setKey: (NSString*)aKey
{
    if (!key || ![key isEqualToString: aKey]) 
	{
		[key release]; 
		key = [aKey retain]; 
    }
}


- (BOOL)isLeaf
{
    return (nodeChildren == nil); 
}

- (BOOL)isGroup
{
    return (nodeChildren != nil); 
}


- (BOOL)isExpandable
{
    return (nodeChildren != nil);
}

- (BOOL)isEditable
{
    return NO; 
}

- (BOOL)isStandardItem // not Group, not Separator
{
	return ((nodeChildren == nil) && ![name isEqualToString: SEPARATOR]);
}

- (BOOL)isSeparator
{
	return ((nodeChildren == nil) && [name isEqualToString: SEPARATOR]);
}


// for debug
- (void) examine
{
	NODE_INFO(@"examine", self);
	//	(([[self description] length] <= 50)?[self description]:[[self description] substringToIndex: 50]));

	NSArray *children = [self children];
	if (children)
	{
		NSEnumerator *enumerator = [children objectEnumerator];
		id node;
		while (node = [enumerator nextObject])
		{
			[node examine];
			//[node release];
		}
	}
	//[children release];
}


- (MyTreeNode *)duplicateNode
{
	MyTreeNode *newNode = [[[MyTreeNode alloc]  initWithParent: nil 
						children: (nodeChildren)?[NSArray array]:nil] autorelease];
	[newNode setName: [self name]];
	if ([self content])
		[newNode setContent: [self content]];
	//if ([self key])
	//	[newNode setKey: [self key]];	// do not copy key
	if (nodeChildren)
	{
		NSEnumerator *enumerator = [nodeChildren objectEnumerator];
		MyTreeNode *srcChild, *newChild;
		while (srcChild = (MyTreeNode *)[enumerator nextObject]) 
		{
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
	tempArray = [MyTreeNode minimumNodeCoverFromNodesInArray: srcNodeArray];
	NSEnumerator *enumerator = [tempArray objectEnumerator];
	MyTreeNode *node;
	while (node = [enumerator nextObject])
	{
		[newArray addObject: [node duplicateNode]];
	}
	return newArray;
}


// ================================================================
// Building tree from dictionary.
// ================================================================

+ (id)nodeFromDictionary: (NSDictionary*)dict
{
	MyTreeNode *node, *child;
	NSString *aName, *aContent, *keyEquiv;
	NSArray *srcChildren;
	NSDictionary *srcChild;
	
	aName = [dict objectForKey: NAME_KEY];
	if (aName == nil)
		return nil;
	node = [[[MyTreeNode alloc]  initWithParent: nil children: nil] autorelease];
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
	if (srcChildren && [srcChildren isKindOfClass:[NSArray class]])
	{
		NSEnumerator *enumerator = [srcChildren objectEnumerator];
		while (srcChild = (NSDictionary *)[enumerator nextObject]) 
		{
			child = [MyTreeNode nodeFromDictionary: srcChild];
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
	NSArray *dictArray=nil;
	NSEnumerator *enumerator, *keyEnum;
	id obj, obj2, theKey;
	MyTreeNode *node, *submenu;
	
	nodeArray = [NSMutableArray array];
	if ([propertyList isKindOfClass: [NSDictionary class]])
	{
		obj = [propertyList objectForKey: NAME_KEY];
		if (obj && [obj isKindOfClass: [NSString class]] && 
			[obj isEqualToString: @"ROOT"])
		{
			obj2 = [propertyList objectForKey: CHILDREN_KEY];
			if (obj2 && [obj2 isKindOfClass: [NSArray class]])
				dictArray = obj2;
		}
	}
	else if ([propertyList isKindOfClass: [NSArray class]])
		dictArray = propertyList;
	if (dictArray)
	{
		enumerator = [dictArray objectEnumerator];
		while (obj = [enumerator nextObject])
		{
			if ([obj isKindOfClass: [NSDictionary class]])
			{
				node = [MyTreeNode nodeFromDictionary: obj];
				if (node)
					[nodeArray addObject: node];
			}
		}
	}
	else if ([propertyList isKindOfClass: [NSDictionary class]])	// LaTeX Panel style dictionary
	{
		keyEnum = [propertyList keyEnumerator];
		while (theKey = [keyEnum nextObject])
		{
			if ([theKey isKindOfClass: [NSString class]] &&
				(dictArray = [propertyList objectForKey: theKey]) && 
				[dictArray isKindOfClass: [NSArray class]])
			{
				submenu = [MyTreeNode submenuNodeWithName: theKey];
				[nodeArray addObject: submenu];
				enumerator = [dictArray objectEnumerator];
				while (obj = [enumerator nextObject])
				{
					if ([obj isKindOfClass: [NSString class]])
					{
						NSMutableString *nameStr = [NSMutableString stringWithString: 
							[(NSString *)obj substringToIndex: 
									([(NSString *)obj length]<50)?[(NSString *)obj length]:50]];
						[nameStr replaceOccurrencesOfString: @"\n" withString: @""
									options: 0 range: NSMakeRange(0, [nameStr length])];
						node = [MyTreeNode nodeWithName: nameStr content: obj key: @""];
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
	MyTreeNode *node, *submenu;
	if ([propertyList isKindOfClass: [NSDictionary class]])
	{
		obj = [propertyList objectForKey: NAME_KEY];
		if (obj && [obj isKindOfClass: [NSString class]] && 
			[obj isEqualToString: @"ROOT"])
		{
			obj2 = [propertyList objectForKey: CHILDREN_KEY];
			if (obj2 && [obj2 isKindOfClass: [NSArray class]])
				array = obj2;
		}
	}
	else if ([propertyList isKindOfClass: [NSArray class]])
		array = propertyList;
	if (array)
	{
		enumerator = [array objectEnumerator];
		while (obj = [enumerator nextObject])
		{
			if ([obj isKindOfClass: [NSDictionary class]])
			{
				node = [MyTreeNode nodeFromDictionary: obj];
				if (node)
					[self addChild: node];
			}
		}
	}
	else if ([propertyList isKindOfClass: [NSDictionary class]])	// LaTeX Panel style dictionary
	{
		keyEnum = [propertyList keyEnumerator];
		while (theKey = [keyEnum nextObject])
		{
			if ([theKey isKindOfClass: [NSString class]] &&
				(array = [propertyList objectForKey: theKey]) && 
				[array isKindOfClass: [NSArray class]])
			{
				submenu = [MyTreeNode submenuNodeWithName: theKey];
				[self addChild: submenu];
				enumerator = [array objectEnumerator];
				while (obj = [enumerator nextObject])
				{
					if ([obj isKindOfClass: [NSString class]])
					{
						NSMutableString *nameStr = [NSMutableString stringWithString: 
							[(NSString *)obj substringToIndex: 
									([(NSString *)obj length]<50)?[(NSString *)obj length]:50]];
						[nameStr replaceOccurrencesOfString: @"\n" withString: @""
									options: 0 range: NSMakeRange(0, [nameStr length])];
						node = [MyTreeNode nodeWithName: nameStr content: obj key: @""];
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
	if (name)
		[dict setObject: name forKey: NAME_KEY];
	if (content)
		[dict setObject: content forKey: CONTENT_KEY];
	if (key)
		[dict setObject: key forKey: KEYEQUIV_KEY];
	if (nodeChildren)
	{
		NSMutableArray *array = [NSMutableArray array];
		NSEnumerator *enumerator = [nodeChildren objectEnumerator];
		MyTreeNode *child;
		while (child = (MyTreeNode *)[enumerator nextObject])
		{
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
    return [self indexOfObjectIdenticalTo: obj]!=NSNotFound; 
}

@end

@implementation NSMutableArray (MyExtensions)

- (void) insertObjectsFromArray:(NSArray *)array atIndex:(int)index {
    NSObject *entry = nil;
    NSEnumerator *enumerator = [array objectEnumerator];
    while ((entry=[enumerator nextObject])) {
        [self insertObject:entry atIndex:index++];
    }
}

@end
