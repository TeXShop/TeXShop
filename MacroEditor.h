//
//  MacroEditor.h
//
//  Created by Mitsuhiro Shishikura on Fri Dec 20 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MyTreeNode.h"

@interface MacroEditor : NSObject
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
	
	MyTreeNode *previousItem;	// record previously selected item	
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
