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
 * $Id: TSMacroEditor.h 108 2006-02-10 13:50:25Z fingolfin $
 *
 * Created by Mitsuhiro Shishikura on Fri Dec 20 2002.
 *
 */

#import <Cocoa/Cocoa.h>

#import "TSMacroTreeNode.h"

@interface TSMacroEditor : NSObject
{
	IBOutlet id outlineController;
	IBOutlet id outlineView;
	IBOutlet id window;

	IBOutlet NSButton *saveButton;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSButton *testButton;
	IBOutlet NSButton *newItemButton;
	IBOutlet NSButton *submenuButton;
	IBOutlet NSButton *separatorButton;
	IBOutlet NSButton *deleteButton;
	IBOutlet NSButton *duplicateButton;

	IBOutlet NSTextField *nameField;
	IBOutlet NSTextView *contentTextView;
	IBOutlet NSTextField *keyField;
	IBOutlet NSButton *shiftCheckBox;
	IBOutlet NSButton *optionCheckBox;
	IBOutlet NSButton *controlCheckBox;

	TSMacroTreeNode *previousItem;	// record previously selected item
	BOOL dataTouched;
	BOOL nameTouched;
	BOOL contentTouched;
	BOOL keyTouched;
}

+ (id)sharedInstance;

- (IBAction)openMacroEditor: (id)sender;
- (void)loadUI;

- (IBAction)savePressed:(id)sender;
- (IBAction)cancelPressed:(id)sender;
- (IBAction)doMacroTest:(id)sender;

- (IBAction)nameFieldAction:(id)sender;
- (IBAction)textDidChange:(id)sender;	// to receive notification from contentTextView
- (IBAction)keyFieldAction:(id)sender;
- (IBAction)modifiersAction:(id)sender;
- (IBAction)outlineAction:(id)sender;

- (void)outlineViewSelectionChanged: (NSNotification *)note;
- (void)outlineViewItemsChanged: (NSNotification *)note;
- (void)reflectChangesInEditor: (BOOL)forceUpdate;

- (void)saveMacrosSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)saveNodes: (id)nodes toFile: (NSString *)filePath;
- (void)saveSelection: (id)sender;
- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void)readDictionaryToMacroEditor: (id)sender;
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;

@end
