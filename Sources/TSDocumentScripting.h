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
 * $Id: TSDocumentScripting.h 159 2006-05-24 23:45:37Z fingolfin $
 *
 * Created by Anton Leuski on Sun Feb 03 2002.
 *
 */

#import <Cocoa/Cocoa.h>
#import "TSDocument.h"
#import "TSAppDelegate.h"

// 	MySelection is a fake class. It does not do anything by itself but passes
//	information between AppleScript and TSDocument
//
//	Right now it handels
//		- offset		the offset of the selection in the text
//		- length		the length of the selection
//		- content		returned/set as string as there are still bugs with
//						the Text suite. When there are fixed it should
//						return a NSTextStorage object, or even better serve as a reference
//						to the selected part of the text -- it should not store the actual text itself.
@interface MySelection : NSObject {
	TSDocument*		mDocument;
}
- (id)initWithMyDocument:(TSDocument *)doc;
- (NSUInteger)offset;
- (NSUInteger)length;
- (void)setOffset:(NSUInteger)off;
- (void)setLength:(NSUInteger)len;
- (NSString*)content;
- (void)setContent:(NSString*)ts;
@end

//	AppleScript support for TSDocument. It works for the TeXShop suite now.
//	Support for Core suite and Text suite is not complete.
@interface TSDocument (ScriptingSupport)

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
- (id)handleRefreshPDFBackgroundCommand:(NSScriptCommand*)command;
- (id)handleTaskDoneCommand:(NSScriptCommand*)command;
@end

// Scripting support for TSAppDelegate
@interface NSApplication (ScriptingSupport)

- (NSArray *)orderedDocuments;
- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key;
- (void)insertInOrderedDocuments:(TSDocument *)doc atIndex:(NSInteger)idx;
- (id)handleOpenForExternalEditorCommand:(NSScriptCommand*)command;
@end

