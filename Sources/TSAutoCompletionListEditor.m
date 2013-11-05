// TSAutoCompletionListEditor.m
// Created by Terada, Apr 2011

#import "globals.h"
#import "TSAutoCompletionListEditor.h"
#define AutoCompletionRowsType @"TSAutoCompletionRowsType"

@implementation TSAutoCompletionListEditor
- (IBAction)openAutoCompletionListEditor: (id)sender
{
	if(!window){
		if (![NSBundle loadNibNamed:@"AutoCompletionListEditor" owner:self]) {
			NSLog(@"Failed to load AutoCompletionListEditor.nib");
			NSBeep();
			return;
		}
		[tableView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
		[tableView registerForDraggedTypes:[NSArray arrayWithObject:AutoCompletionRowsType]];
		
		NSString *key;

		if (g_autocompletionKeys) {
			autocompletionKeys = [NSMutableArray arrayWithArray:g_autocompletionKeys];
		}else {
			autocompletionKeys = [NSMutableArray arrayWithArray:[g_autocompletionDictionary allKeys]];
		}

		autocompletionValues = [NSMutableArray arrayWithCapacity:0];
        NSArray *autocompletionKeysCopy = [NSArray arrayWithArray:autocompletionKeys];
		NSEnumerator *enumerator = [autocompletionKeysCopy objectEnumerator];
		while ((key = [enumerator nextObject])) {
			if ([[g_autocompletionDictionary allKeys] containsObject:key]){
                [autocompletionValues addObject:[g_autocompletionDictionary objectForKey:key]];
            }else{
                [autocompletionKeys removeObjectIdenticalTo:key];
            }
		}

		enumerator = [[g_autocompletionDictionary allKeys] objectEnumerator];
		while ((key = [enumerator nextObject])) {
            if (![autocompletionKeys containsObject:key]) {
                [autocompletionKeys addObject:key];
                [autocompletionValues addObject:[g_autocompletionDictionary objectForKey:key]];
            }
		}
		
		[autocompletionKeys retain];
		[autocompletionValues retain];
	}
	
	[window makeKeyAndOrderFront:nil];
}



- (IBAction)addPressed:(id)sender
{
	NSString *newKey = [newKeyField stringValue];
	if ([newKey isEqualToString:@""]) {
		NSBeep();
	}else{
		NSUInteger _index = [autocompletionKeys indexOfObject:newKey];
		if (_index != NSNotFound) {
			NSInteger result = NSRunAlertPanel(NSLocalizedString(@"Warning", @"Warning"), 
										 [NSString stringWithFormat:NSLocalizedString(@"Your current setting of %@ will be replaced. OK?", @"Your current setting of %@ will be replaced. OK?"), newKey], 
										 @"OK", NSLocalizedString(@"Cancel", @"Cancel"), nil);
			if (result == NSAlertDefaultReturn) {
				[autocompletionValues replaceObjectAtIndex:_index withObject:[newValueField stringValue]];
			}else {
				return;
			}
		}else {
			[autocompletionKeys insertObject:newKey atIndex:0];
			[autocompletionValues insertObject:[newValueField stringValue] atIndex:0];
		}

		[newKeyField setStringValue:@""];
		[newValueField setStringValue:@""];
		[newKeyField becomeFirstResponder];
		[tableView reloadData];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[autocompletionKeys	release];
	[autocompletionValues release];
	window = nil;
}


- (void)removeObjectsAtIndexes:(NSIndexSet*)indexes
{
	[autocompletionKeys removeObjectsAtIndexes:indexes];
	[autocompletionValues removeObjectsAtIndexes:indexes];
	[tableView reloadData];
}

- (IBAction)savePressed:(id)sender
{
	NSMutableDictionary *newAutoCompletionList = [NSMutableDictionary dictionaryWithCapacity:0];
	NSInteger i;
	for(i=0;i<[autocompletionKeys count];i++){
		[newAutoCompletionList setObject:[autocompletionValues objectAtIndex:i] forKey:[autocompletionKeys objectAtIndex:i]];
	}
	if (g_autocompletionDictionary) [g_autocompletionDictionary release];
	g_autocompletionDictionary = [newAutoCompletionList retain];
	if (g_autocompletionKeys) [g_autocompletionKeys release];
	g_autocompletionKeys = [autocompletionKeys retain];
	
	NSString	*filePath;
	filePath = [[[AutoCompletionPath stringByStandardizingPath] stringByAppendingPathComponent:@"autocompletion"] stringByAppendingPathExtension:@"plist"];
	[g_autocompletionDictionary writeToFile:filePath atomically:NO];

	filePath = [[[AutoCompletionPath stringByStandardizingPath] stringByAppendingPathComponent:@"autocompletionDisplayOrder"] stringByAppendingPathExtension:@"plist"];
	[g_autocompletionKeys writeToFile:filePath atomically:NO];

	[window close];
}

- (IBAction)cancelPressed:(id)sender
{
	[window close];
}

- (IBAction)removePressed:(id)sender
{
	[self removeObjectsAtIndexes:[tableView selectedRowIndexes]]; 
	[tableView selectRowIndexes:nil byExtendingSelection:NO];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView
{
	return [autocompletionKeys count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [[aTableColumn identifier] isEqualToString:@"key"] ? [autocompletionKeys objectAtIndex:rowIndex] :[autocompletionValues objectAtIndex:rowIndex];
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)object 
   forTableColumn:(NSTableColumn *)tableColumn 
			  row:(NSInteger)rowIndex;
{
	if ([[tableColumn identifier] isEqualToString:@"key"]) {
		[autocompletionKeys replaceObjectAtIndex:rowIndex withObject:object];
    }else {
		[autocompletionValues replaceObjectAtIndex:rowIndex withObject:object];
	}

}

- (void)removeDraggedOutRows
{
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	NSData *rowData = [pboard dataForType:AutoCompletionRowsType];
	NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
	[self removeObjectsAtIndexes:rowIndexes];
}

- (BOOL)tableView:(NSTableView *)aTableView
writeRowsWithIndexes:(NSIndexSet *)rowIndexes 
	 toPasteboard:(NSPasteboard *)pboard
{
	// declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObject:AutoCompletionRowsType];
	[pboard declareTypes:typesArray owner:self];
	
    // add rows array for local move
	NSData *rowIndexesArchive = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard setData:rowIndexesArchive forType:AutoCompletionRowsType];
	
    return YES;
}


- (NSDragOperation)tableView:(NSTableView*)aTableView 
				validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(NSInteger)row 
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	// Accept drop between rows. (not on a row)
    [aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	
	return NSDragOperationMove;
}

- (NSIndexSet*)moveObjectsOf:(NSMutableArray*)anArray
				 fromIndexes:(NSIndexSet*)fromIndexSet 
					 toIndex:(NSUInteger)insertIndex
{	
	// If any of the removed objects come before the insertion index,
	// we need to decrement the index appropriately
	NSUInteger adjustedInsertIndex = insertIndex - [fromIndexSet countOfIndexesInRange:(NSRange){0, insertIndex}];
	NSRange destinationRange = NSMakeRange(adjustedInsertIndex, [fromIndexSet count]);
	NSIndexSet *destinationIndexes = [NSIndexSet indexSetWithIndexesInRange:destinationRange];
	
	NSArray *objectsToMove = [anArray objectsAtIndexes:fromIndexSet];
	[anArray removeObjectsAtIndexes:fromIndexSet];	
	[anArray insertObjects:objectsToMove atIndexes:destinationIndexes];
	
	return destinationIndexes;
}

- (BOOL)tableView:(NSTableView*)aTableView
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)insertionRow
	dropOperation:(NSTableViewDropOperation)op
{
    if (insertionRow < 0)
	{
		insertionRow = 0;
	}
	// if drag source is self, it's a move unless the Option key is pressed
    if ([info draggingSource] == tableView)
	{
		NSEvent *currentEvent = [NSApp currentEvent];
		NSInteger optionKeyPressed = [currentEvent modifierFlags] & NSAlternateKeyMask;
		
		if (optionKeyPressed == 0)
		{
			NSData *rowsData = [[info draggingPasteboard] dataForType:AutoCompletionRowsType];
			NSIndexSet *indexSet = [NSKeyedUnarchiver unarchiveObjectWithData:rowsData];
			NSIndexSet *newIndexes = [self moveObjectsOf:autocompletionKeys fromIndexes:indexSet toIndex:insertionRow];
			[self moveObjectsOf:autocompletionValues fromIndexes:indexSet toIndex:insertionRow];
			[aTableView selectRowIndexes:newIndexes byExtendingSelection:NO]; // select the row which has just been moved
			[aTableView reloadData];
			return YES;
		}
    }
	
    return NO;
}

@end
