// ================================================================================
//  MyDocumentScripting.h
// ================================================================================
//	TeXShop
//
//  Created by Anton Leuski on Sun Feb 03 2002.
//  Copyright (c) 2002 Anton Leuski. 
//
//	This source is distributed under the terms of GNU Public License (GPL) 
//	see www.gnu.org for more info
//
// ================================================================================

#import <Cocoa/Cocoa.h>
#import "MyDocument.h"
#import "TSAppDelegate.h"

// 	MySelection is a fake class. It does not do anything by itself but passes
//	information between AppleScript and MyDocument
//
//	Right now it handels 
//		- offset		the offset of the selection in the text
//		- length		the length of the selection
//		- content		returned/set as string as there are still bugs with
//						the Text suite. When there are fixed it should
//						return a NSTextStorage object, or even better serve as a reference
//						to the selected part of the text -- it should not store the actual text itself.
@interface MySelection : NSObject {
	MyDocument*		mDocument;
}
- (id)initWithDocument:(MyDocument*)doc;
- (unsigned)offset;
- (unsigned)length;
- (void)setOffset:(unsigned)off;
- (void)setLength:(unsigned)len;
- (NSString*)content;
- (void)setContent:(NSString*)ts;
@end

//	AppleScript support for MyDocument. It works for the TeXShop suite now.
//	Support for Core suite and Text suite is not complete.
@interface MyDocument (ScriptingSupport)

- (NSTextStorage *)textStorage;
- (NSTextView *)firstTextView;
- (NSWindow *)window;
- (NSLayoutManager *)layoutManager;
- (MySelection*)selection;
- (void)setSelection:(id)ts;
- (NSScriptObjectSpecifier *)objectSpecifier;
- (void)setTextStorage:(id)ts;
- (id)coerceValueForTextStorage:(id)value;
- (id)handleSearchCommand:(NSScriptCommand*)command;
- (id)handleLatexCommand:(NSScriptCommand*)command;
- (id)handleLatexInteractiveCommand:(NSScriptCommand*)command;
- (id)handleTexCommand:(NSScriptCommand*)command;
- (id)handleTexInteractiveCommand:(NSScriptCommand*)command;
- (id)handleBibtexCommand:(NSScriptCommand*)command;
- (id)handleBibtexInteractiveCommand:(NSScriptCommand*)command;
- (id)handleContextCommand:(NSScriptCommand*)command;
- (id)handleContextInteractiveCommand:(NSScriptCommand*)command;
- (id)handleMetapostCommand:(NSScriptCommand*)command;
- (id)handleMetapostInteractiveCommand:(NSScriptCommand*)command;
- (id)handleMakeindexCommand:(NSScriptCommand*)command;
- (id)handleMakeindexInteractiveCommand:(NSScriptCommand*)command;
- (id)handleTypesetCommand:(NSScriptCommand*)command;
- (id)handleTypesetInteractiveCommand:(NSScriptCommand*)command;
- (id)handleRefreshPDFCommand:(NSScriptCommand*)command;
- (id)handleTaskDoneCommand:(NSScriptCommand*)command;
@end

// Scripting support for TSAppDelegate
@interface NSApplication (ScriptingSupport)

- (NSArray *)orderedDocuments;
- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key;
- (void)insertInOrderedDocuments:(MyDocument *)doc atIndex:(int)index;
- (id)handleOpenForExternalEditorCommand:(NSScriptCommand*)command;
@end

