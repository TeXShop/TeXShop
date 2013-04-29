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
 * $Id: TSMacroEditor.m 108 2006-02-10 13:50:25Z fingolfin $
 *
 * Created by Mitsuhiro Shishikura on Fri Dec 20 2002.
 *
 */

#import "TSMacroEditor.h"

#import "TSMacroOutlineController.h"
#import "TSMacroMenuController.h"
#import "TSTextView.h"
#import "TSEncodingSupport.h"
#import "globals.h"


@implementation TSMacroEditor

static id sharedMacroEditor = nil;
static TSFilterMode savedFilter = kNoFilterMode;

+ (id)sharedInstance
{
	if (sharedMacroEditor == nil)
		sharedMacroEditor = [[TSMacroEditor alloc] init];
	return sharedMacroEditor;
}

- (id)init
{
	if (sharedMacroEditor)
		[super dealloc];
	else {
		sharedMacroEditor = [super init];
		previousItem = nil;
	}
	return sharedMacroEditor;
}

- (void)dealloc
{
	if (self != sharedMacroEditor)
		[super dealloc];	// Don't free our shared instance
}

- (void)awakeFromNib
{
}


- (IBAction)openMacroEditor: (id)sender
{
	if (!outlineView) {
		// load TSMacroEditor window
		[self loadUI];
		// load tree from macroDictionary
		TSMacroTreeNode *newRoot = [TSMacroTreeNode nodeFromDictionary:
							[[TSMacroMenuController sharedInstance] macroDictionary]];
		savedFilter = g_shouldFilter;

		// register for ntification
		[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(outlineViewSelectionChanged:)
					name: NSOutlineViewSelectionDidChangeNotification object: outlineView];
		[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(outlineViewItemsChanged:)
					name: TSMacroOutlineViewAddedItemNotification object: outlineView];
		[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(outlineViewItemsChanged:)
					name: TSMacroOutlineViewRemovedItemNotification object: outlineView];
		[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(outlineViewItemsChanged:)
					name: TSMacroOutlineViewAcceptedDropNotification object: outlineView];
		// set up variables
		[outlineController setRootOfTree: newRoot]; // one can use [outlineView dataSource] instead
		previousItem = nil;
		dataTouched = NO;
		nameTouched = NO;
		contentTouched = NO;
		keyTouched = NO;
		// set up menu items
		NSMenu *macroMenu = [[[NSApp mainMenu] itemWithTitle:
					NSLocalizedString(@"Macros", @"Macros")] submenu];
		id item = [macroMenu itemWithTitle:
						NSLocalizedString(@"Open Macro Editor...", @"Open Macro Editor...")];
		if (item)
		{
			[item setTitle: NSLocalizedString(@"Close Macro Editor", @"Close Macro Editor")];
			[item setTarget: window];
			[item setAction: @selector(performClose:)];
		}
		item = [macroMenu insertItemWithTitle:
					NSLocalizedString(@"Add macros from file...", @"Add macros from file...")
					action: @selector(readDictionaryToMacroEditor:) keyEquivalent:@"" atIndex: 1];
		[item setTarget: self];
		item = [macroMenu insertItemWithTitle:
					NSLocalizedString(@"Save selection to file...", @"Save selection to file...")
					action: @selector(saveSelection:) keyEquivalent:@"" atIndex: 2];
		[item setTarget: self];
	}
	[window makeKeyAndOrderFront: nil];
}

- (void)loadUI
{
	if (!outlineView) {
		if (![NSBundle loadNibNamed:@"MacroEditor" owner:self]) {
			// TODO: Show an error dialog to the user here
			NSLog(@"Failed to load MacroEditor.nib");
			NSBeep();
			return;
		}
		// set up window and UI elements
		// [window setDelegate: self];	// not necessary if it is connected in IB

		[outlineView setTarget: self];
		[outlineView setDoubleAction: @selector(doMacroTest:)];
		// custom text view
		NSScrollView *scrollView = [contentTextView enclosingScrollView];
		NSSize contentSize = [scrollView contentSize];
		contentTextView = [[TSTextView alloc] initWithFrame:
						NSMakeRect(0, 0, contentSize.width, contentSize.height)];
		[contentTextView setAutoresizingMask: NSViewWidthSizable];
		[[contentTextView textContainer] setWidthTracksTextView:YES];
		[contentTextView setDelegate:self];
		[contentTextView setAllowsUndo:YES];
		[contentTextView setRichText:NO];
		[contentTextView setUsesFontPanel:YES];
		[contentTextView setFont:[NSFont userFontOfSize:12.0]];
		[scrollView setDocumentView:contentTextView];
		[contentTextView release];
		// text fields
		[nameField setDelegate: [TSEncodingSupport sharedInstance]];
		[keyField setDelegate: [TSEncodingSupport sharedInstance]];
		// set up properties for UI
		[nameField setEditable: NO];
		[contentTextView setEditable: NO];
		[keyField setEditable: NO];
		[shiftCheckBox setState: NSOffState];
		[shiftCheckBox setEnabled: NO];
		[optionCheckBox setState: NSOffState];
		[optionCheckBox setEnabled: NO];
		[controlCheckBox setState: NSOffState];
		[controlCheckBox setEnabled: NO];
		[testButton setEnabled: NO];
		[deleteButton setEnabled: NO];
		[duplicateButton setEnabled: NO];
	}
}


// action for Save button
- (IBAction)savePressed:(id)sender
{
	NSString *pathStr, *defaultPathStr;
	
	defaultPathStr = [MacrosPath stringByStandardizingPath];
	defaultPathStr = [defaultPathStr stringByAppendingPathComponent:@"Macros_Latex"];
	defaultPathStr = [defaultPathStr stringByAppendingPathExtension:@"plist"];
	
	pathStr = [MacrosPath stringByStandardizingPath];
	switch (g_macroType) {
		case TexEngine: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Tex"]; break;
		case LatexEngine: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Latex"]; break;
		case BibtexEngine: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Bibtex"]; break;
		case IndexEngine: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Index"]; break;
		case MetapostEngine: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Metapost"]; break;
		case ContextEngine: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Context"]; break;
		default: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Latex"]; break;
	}
	pathStr = [pathStr stringByAppendingPathExtension:@"plist"];
	
	[window makeFirstResponder: window];// finish editing fields
										//[outlineView deselectAll: sender];
		[self reflectChangesInEditor: YES];
		if (dataTouched) {	// save only if data was touched
			// mitsu 1.29 (U)-- back up old macro file, so that you can recover it manually if needed
			NS_DURING
				if ([[NSFileManager defaultManager] fileExistsAtPath:pathStr]) {
					NSString *backupPath = [pathStr stringByDeletingPathExtension];
					backupPath = [backupPath stringByAppendingString:@"~"];
					backupPath = [backupPath stringByAppendingPathExtension:@"plist"];
					[[NSFileManager defaultManager] removeItemAtPath:backupPath error:NULL];
					[[NSFileManager defaultManager] copyItemAtPath:pathStr toPath:backupPath error:NULL];
				}
				NS_HANDLER
					NS_ENDHANDLER
					// end mitsu 1.29
					// save the node data to a file
					[self saveNodes: [outlineController rootOfTree] toFile: pathStr];
					// reload macros
					[[TSMacroMenuController sharedInstance] reloadMacros: self];
		}
				[window close];
}

// action for Cancel button
- (IBAction)cancelPressed:(id)sender
{
	[window close];
}

// action for Test button
- (IBAction)doMacroTest:(id)sender
{
	//[window orderOut: self];
	// In order to test an AppleScript properly, especially if it refers to the first window,
	// it may be better to hide the TSMacroEditor window on "Test".
	// On the other hand, users might think that something wrong has happened if the window
	// suddenly goes away.
	[[TSMacroMenuController sharedInstance] doMacro: [contentTextView string]];
	//[window makeKeyAndOrderFront:nil]; // get the window back
}


// action for nameField
- (IBAction)nameFieldAction:(id)sender
{
	nameTouched = YES;
	[self reflectChangesInEditor: YES];
}

// delegate method for contentTextView
- (IBAction)textDidChange:(id)sender
{
	contentTouched = YES;
}

// action for keyField
- (IBAction)keyFieldAction:(id)sender
{
	NSString *key = [keyField stringValue];
	if ([key length] > 1) {
		[keyField setStringValue: [key substringToIndex: 1]];
	}
	keyTouched = YES;
	[self reflectChangesInEditor: YES];
}

// action for Shift/Option/Control check box
- (IBAction)modifiersAction:(id)sender
{
	keyTouched = YES;
	[self reflectChangesInEditor: YES];
}

// action for outline view
- (IBAction)outlineAction:(id)sender
{
}

// a method called on "Selection changed" notification
- (void)outlineViewSelectionChanged: (NSNotification *)note
{
	[self reflectChangesInEditor: NO];
}

// a method called on "Items changed" (added/removed) notification
- (void)outlineViewItemsChanged: (NSNotification *)note
{
	dataTouched = YES;	// user may have changed the order or dropped an item
}

// interation bewteen outline data and nameField/contentTextView/etc
- (void)reflectChangesInEditor: (BOOL)forceUpdate
{
	NSString *contentString;
	NSArray *selectedNodes = [outlineController selectedNodes];
	[deleteButton setEnabled: ([selectedNodes count] > 0)];
	[duplicateButton setEnabled: ([selectedNodes count] > 0)];
	
	TSMacroTreeNode *newItem = ([selectedNodes count] == 1)?[selectedNodes objectAtIndex: 0]:nil;
	if (newItem == previousItem && !forceUpdate)
		return;	// maybe item was simply dragged and dropped
	
	if (previousItem) {
		if (![previousItem isSeparator] && nameTouched) {
			[previousItem setName: [nameField stringValue]];
			dataTouched = YES;
		}
		if ([previousItem isStandardItem]) {
			if (contentTouched) {
				// note: [NSTextView string] returns currently edited string. make sure to copy it
				if (savedFilter != kMacJapaneseFilterMode)
					contentString = [NSString stringWithString: [contentTextView string]];
				else
					contentString = filterYenToBackslash([contentTextView string]);
				[previousItem setContent: contentString];
				dataTouched = YES;
			}
			if (keyTouched)
			{
				[previousItem setKey: getStringFormKeyEquivalent([keyField stringValue],
																 ([shiftCheckBox state] == NSOnState), ([optionCheckBox state] == NSOnState),
																 ([controlCheckBox state] == NSOnState))];
				dataTouched = YES;
			}
		}
		if ([previousItem isAlive])
			[outlineView reloadItem: previousItem]; //this causes a problem if the item is dead
		[previousItem release];
	}
	
	[nameField setStringValue: (newItem)?[newItem name]:@""];
	[nameField setEditable: (newItem && ![newItem isSeparator])?YES:NO];
	if (newItem && [newItem isStandardItem]) {
		contentString = [newItem content]?[newItem content]:@"";
		if (g_shouldFilter == kMacJapaneseFilterMode)
			contentString = filterBackslashToYen(contentString);
		savedFilter = g_shouldFilter;	// remember this filter option
		[contentTextView setString: contentString];
		[contentTextView setEditable: YES];
		NSString *KeyEquiv = getKeyEquivalentFromString([newItem key]);
		BOOL hasKeyEquiv = ([KeyEquiv length] > 0);
		[keyField setStringValue: (hasKeyEquiv)?(KeyEquiv):@""];
		[keyField setEditable: YES];
		NSUInteger modifier = getKeyModifierMaskFromString([newItem key]);
		[shiftCheckBox setState: (hasKeyEquiv && (modifier & NSShiftKeyMask))?NSOnState:NSOffState];
		[shiftCheckBox setEnabled: YES];
		[optionCheckBox setState: (hasKeyEquiv && (modifier & NSAlternateKeyMask))?NSOnState:NSOffState];
		[optionCheckBox setEnabled: YES];
		[controlCheckBox setState: (hasKeyEquiv && (modifier & NSControlKeyMask))?NSOnState:NSOffState];
		[controlCheckBox setEnabled: YES];
		[testButton setEnabled: YES];
	} else {
		[contentTextView setString: @""];
		[contentTextView setEditable: NO];
		[keyField setStringValue: @""];
		[keyField setEditable: NO];
		[shiftCheckBox setState: NSOffState];
		[shiftCheckBox setEnabled: NO];
		[optionCheckBox setState: NSOffState];
		[optionCheckBox setEnabled: NO];
		[controlCheckBox setState: NSOffState];
		[controlCheckBox setEnabled: NO];
		[testButton setEnabled: NO];
	}
	previousItem = (newItem)?[newItem retain]:nil;
	nameTouched = NO;
	contentTouched = NO;
	keyTouched = NO;
	//	[outlineView reloadData];// this caused a crash if a node and its child are selected and the disclosure triangle is pressed
}

// delegate method for window
- (BOOL) windowShouldClose: (id)sender
{
	if (sender == self)		// called via saveButtonPressed or cancelButtonPressed
		return YES;
	[window makeFirstResponder: window];
	[outlineView deselectAll: sender];
	if (!dataTouched)	// data was not changed
		return YES;
	else {	// close button in title bar was pressed or "Close Macro Editor" was chosen fromm menu
//		NSBeginAlertSheet(@"Warning", @"Save", @"Don't save", @"Cancel",
//				window, self,
//				@selector(saveMacrosSheetDidEnd:returnCode:contextInfo:), nil, nil,
//				@"Do you want to save macros?");
				NSBeginAlertSheet(NSLocalizedString(@"Warning", @""),
					NSLocalizedString(@"Save", @""),
					NSLocalizedString(@"Don't Save", @""),
					NSLocalizedString(@"Cancel", @""), window, self,
					@selector(saveMacrosSheetDidEnd:returnCode:contextInfo:),
					nil, nil,
					NSLocalizedString(@"Do you want to save macros?", @""));
		return NO;
	};
}

// handler for "Save Macros?" sheet
- (void) saveMacrosSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	switch (returnCode) {
		case NSAlertDefaultReturn:
			[self savePressed: self];
			break;
		case NSAlertAlternateReturn:
			[self cancelPressed: self];
			break;
		default:
			break;
	}
}

// delegate method for window
- (void) windowWillClose: (NSNotification *)aNotification
{
	// clean up
	if (previousItem)
		[previousItem release];
	previousItem = nil;
	[outlineController setRootOfTree: nil]; // this release the tree structure
	outlineView = nil;
	window = nil;
	// restore menu item
	NSMenu *macroMenu = [[[NSApp mainMenu] itemWithTitle:
				NSLocalizedString(@"Macros", @"Macros")] submenu];
	id item = [macroMenu itemWithTitle:
					NSLocalizedString(@"Close Macro Editor", @"Close Macro Editor")];
	if (item) {
		[item setTitle: NSLocalizedString(@"Open Macro Editor...", @"Open Macro Editor...")];
		[item setTarget: self];
		[item setAction: @selector(openMacroEditor:)];
	}
	item = [macroMenu itemWithTitle:
				NSLocalizedString(@"Add macros from file...", @"Add macros from file...")];
	if (item)
		[macroMenu removeItem: item];
	item = [macroMenu itemWithTitle:
				NSLocalizedString(@"Save selection to file...", @"Save selection to file...")];
	if (item)
		[macroMenu removeItem: item];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

// delegate method for window
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
	NSRect outlineFrame = [[outlineView enclosingScrollView] frame];
	NSRect buttonFrame = [testButton frame];
	if ((proposedFrameSize.width < outlineFrame.size.width + 110) &&
		(buttonFrame.origin.x > outlineFrame.origin.x + 100)) {
		[testButton setFrameOrigin: NSMakePoint(outlineFrame.origin.x-3, buttonFrame.origin.y)];
	}
	if ((proposedFrameSize.width >= outlineFrame.size.width + 110) &&
		(buttonFrame.origin.x <= outlineFrame.origin.x + 100)) {
		[testButton setFrameOrigin: NSMakePoint(outlineFrame.origin.x+outlineFrame.size.width+24,
																		buttonFrame.origin.y)];
	}
	// I think there is a bug in Cocoa which requires the fix below.
	// If one make the window so narrow that the name and content fields disappear,
	// then next time they appear, they stick to the right border.
	NSRect contentBounds = [[window contentView] bounds];	// use this instead of proposedFrameSize
	NSRect fieldFrame = [nameField frame];
	if (fieldFrame.size.width > contentBounds.size.width-fieldFrame.origin.x-10 && fieldFrame.size.width > 0) {
		fieldFrame.size.width = contentBounds.size.width-fieldFrame.origin.x-10;
		[nameField setFrame:fieldFrame];
	}
	fieldFrame = [[contentTextView enclosingScrollView] frame];	// don't forget to apply it to the scroll view
	if (fieldFrame.size.width > contentBounds.size.width-fieldFrame.origin.x-10 && fieldFrame.size.width > 0) {
		fieldFrame.size.width = contentBounds.size.width-fieldFrame.origin.x-10;
		[[contentTextView enclosingScrollView] setFrame:fieldFrame];
	}
	//
	return proposedFrameSize;
}

// delegate method for window
- (void)windowDidResize:(NSNotification *)aNotification
{
	//[outlineView reloadData];
}

// delegate method for window
- (void)windowDidBecomeKey: (NSNotification *)aNotification
{
	NSString *string;
	// FIXME/TODO: Instead of using savedFilter, register for notification
	// when the encoding changes
	if (g_shouldFilter != savedFilter) { // if the encoding was changed while TSMacroEditor is open...
		if (g_shouldFilter == kMacJapaneseFilterMode) {
			string = [contentTextView string];
			string = filterBackslashToYen(string);
			[contentTextView setDelegate: nil]; // to avoid sending a message "text changed"
			[contentTextView setString: string];
			[contentTextView setDelegate: self];
		} else if(savedFilter == kMacJapaneseFilterMode) {
			string = [contentTextView string];
			string = filterYenToBackslash(string);
			[contentTextView setDelegate: nil]; // to avoid sending a message "text changed"
			[contentTextView setString: string];
			[contentTextView setDelegate: self];
		}
		savedFilter = g_shouldFilter;
	}
}

// set up menu items' enable/disable
- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	if ([anItem action] == @selector(saveSelection:)) {
		return ([[outlineView allSelectedItems] count] > 0);
	} else
		return YES;
}

// save given nodes of the tree to a file
- (void)saveNodes: (id)nodes toFile: (NSString *)filePath
{
	id 	propertyList;
	NSString *pathStr, *error;
	NSData *xmlData;

	if ([nodes isKindOfClass: [TSMacroTreeNode class]]) {
		propertyList = [nodes makeDictionary];
		[propertyList setObject: @"ROOT" forKey: NAME_KEY];
	} else if ([nodes isKindOfClass: [NSArray class]]) {
		NSMutableArray *array = [NSMutableArray array];
		NSEnumerator *enumerator = [nodes objectEnumerator];
		TSMacroTreeNode *child;
		while ((child = [enumerator nextObject])) {
			[array addObject: [child makeDictionary]];
		}
		propertyList = [NSDictionary dictionaryWithObjectsAndKeys:
						@"ROOT", NAME_KEY, array, CHILDREN_KEY, nil];
	} else
		return;
	// convert to XML in UTF8 format
	NS_DURING
	error = nil;
	xmlData = [NSPropertyListSerialization dataFromPropertyList: propertyList
										format: NSPropertyListXMLFormat_v1_0
										errorDescription: &error];
	if (!xmlData)
		[NSException raise: @"XML error" format: @""];
	// finally write to file
	pathStr = [[NSString stringWithString: filePath] stringByStandardizingPath];
	[xmlData writeToFile: pathStr atomically: YES];

	NS_HANDLER
		NSRunAlertPanel(@"Error", [NSString stringWithFormat:
			@"failed to save macros to %@\n%@", filePath, error], nil, nil, nil);
				if (error) [error release]; // mitsu 1.29 (U) added
	NS_ENDHANDLER
}

// action for "save selection to file" menu item
- (void)saveSelection: (id)sender
{
	NSSavePanel *aPanel = [NSSavePanel savePanel];
    NSArray *types = [NSArray arrayWithObject:@"plist"];
	[aPanel setAllowedFileTypes:types];
    
 	[aPanel beginSheetForDirectory: nil //[MACRO_DATA_PATH stringByDeletingLastPathComponent]
				file: @"My macros" modalForWindow:window modalDelegate:self
				didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

// handler for savePanel for macros saving
- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton) {
		NS_DURING
		NSString *fileName = [sheet fileName];
		if (fileName) {
			NSArray *selectionArray = [TSMacroTreeNode minimumNodeCoverFromNodesInArray:
										[outlineView allSelectedItems]];
			[self saveNodes: selectionArray toFile: fileName];
		}
		NS_HANDLER
			NSRunAlertPanel(@"Error", @"failed to save macros to the file.", nil, nil, nil);
		NS_ENDHANDLER
	}
}

// action for "Add macros from file"
- (void)readDictionaryToMacroEditor: (id)sender
{
	NSOpenPanel *aPanel = [NSOpenPanel openPanel];
	[aPanel setCanChooseFiles: YES];
	[aPanel setCanChooseDirectories: NO];
	[aPanel setAllowsMultipleSelection: NO];
	[aPanel setResolvesAliases: YES];

	[aPanel beginSheetForDirectory: nil file: nil types: nil modalForWindow: window
		modalDelegate: self didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
		contextInfo:nil];
}

// handler for openPanel for loading macros
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo
{
	NSDictionary *newDict = nil;
	if (returnCode == NSOKButton) {
		NSArray *array = [sheet filenames];
		NS_DURING
			NSData *myData = [NSData dataWithContentsOfFile: [array objectAtIndex: 0]];
			NSString *aString = [[[NSString alloc] initWithData:myData encoding:
							NSUTF8StringEncoding] autorelease];
			if (aString)
				newDict = (NSDictionary *)[aString propertyList];
			if (newDict) {
				NSArray *newNodeArray = [TSMacroTreeNode nodeArrayFromPropertyList: newDict];
				[outlineController addNewDataArrayToSelection: newNodeArray];
			}
		NS_HANDLER
			newDict = nil;
		NS_ENDHANDLER
		if (newDict == nil)
			NSRunAlertPanel(@"Error", @"failed to read the file as a dictionary", nil, nil, nil);
	}
}



@end
