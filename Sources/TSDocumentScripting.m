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
 * $Id: TSDocumentScripting.m 159 2006-05-24 23:45:37Z fingolfin $
 *
 * Created by Anton Leuski on Sun Feb 03 2002.
 *
 */

#import "TSDocumentScripting.h"
#import "globals.h"


@implementation TSDocument (ScriptingSupport)

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSTextStorage *)textStorage
{
	return [[self textView] textStorage];
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSTextView *)firstTextView
{
	return [self textView];
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSWindow *)window
{
	return [self textWindow];
}

//- (NSUndoManager *)undoManager
//{
//   return [[self window] undoManager];
//}

- (NSLayoutManager *)layoutManager
{
	return [[[self textStorage] layoutManagers] objectAtIndex:0];
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (MySelection*)selection
{
	if (!mSelection)
		mSelection = [[MySelection alloc] initWithMyDocument:self];
	return mSelection;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void)setSelection:(id)ts
{
	// ts can actually be a string or an attributed string.

	NSRange		range = [[self firstTextView] selectedRange];
	NSString *oldString, *key= @"AppleEvent";
	NSUInteger newStringLen, from, to;

	// Determine the current selection
	oldString = [[textView string] substringWithRange: range];

	// Insert the new text
	if ([ts isKindOfClass:[NSAttributedString class]]) {
		[[self textStorage] replaceCharactersInRange:range withAttributedString:ts];
		newStringLen = [(NSAttributedString*)ts length];
	} else {
		[[self textStorage] replaceCharactersInRange:range withString:ts];
		newStringLen = [(NSString*)ts length];
	}

	// register undo
	[self registerUndoWithString:oldString location:range.location
						length:newStringLen key:key];

	from = range.location;
	to = from + newStringLen;
	[self fixColor:from :to];
	[self setupTags];
}


// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------
// Scripting support.

- (NSScriptObjectSpecifier *)objectSpecifier {
	NSArray *orderedDocs = [NSApp valueForKey:@"orderedDocuments"];
	NSUInteger theIndex = [orderedDocs indexOfObjectIdenticalTo:self];

	if (theIndex != NSNotFound) {
		NSScriptClassDescription *desc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSApplication class]];
		return [[[NSIndexSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:desc containerSpecifier:nil key:@"orderedDocuments" index:theIndex] autorelease];
	} else {
		return nil;
	}
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------
// We already have a textStorage() method implemented above.

- (void)setTextStorage:(id)ts {
	// ts can actually be a string or an attributed string.
	if ([ts isKindOfClass:[NSAttributedString class]]) {
		[[self textStorage] replaceCharactersInRange:NSMakeRange(0, [[self textStorage] length]) withAttributedString:ts];
	} else {
		[[self textStorage] replaceCharactersInRange:NSMakeRange(0, [[self textStorage] length]) withString:ts];
	}
}


// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (id)coerceValueForTextStorage:(id)value {
	// We want to just get Strings unchanged.  We will detect this and do the right thing in setTextStorage().  We do this because, this way, we will do more reasonable things about attributes when we are receiving plain text.
	if ([value isKindOfClass:[NSString class]]) {
		return value;
	} else {
		return [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:value toClass:[NSTextStorage class]];
	}
}


// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (id)handleSearchCommand:(NSScriptCommand*)command
{
	NSDictionary*	args 			= [command evaluatedArguments];
	NSString*		text			= [args objectForKey:@"AText"];
	BOOL			caseSensitive	= [args objectForKey:@"CaseSensitive"] ?
											[[args objectForKey:@"CaseSensitive"] boolValue] : NO;
//	BOOL			wholeWord		= [args objectForKey:@"WholeWord"] ?
//											[[args objectForKey:@"WholeWord"] boolValue] : NO;
	BOOL			directionUp		= [args objectForKey:@"Direction"] ?
											[[args objectForKey:@"Direction"] boolValue] : NO;
	NSUInteger		startFrom		= [args objectForKey:@"StartOffset"] ?
											[[args objectForKey:@"StartOffset"] unsignedIntegerValue] :
											[[self firstTextView] selectedRange].location;
	NSString*		myText			= [[self firstTextView] string];

	NSRange			result, searchRange;
	NSUInteger		mask = NSLiteralSearch;

	if (!caseSensitive)
		mask |= NSCaseInsensitiveSearch;

	if (directionUp) {
		mask |= NSBackwardsSearch;
		searchRange.location	= 0;
		searchRange.length 		= startFrom;
	} else {
		searchRange.location	= startFrom;
		searchRange.length 		= [myText length] - startFrom;
	}
    

	result	= [myText rangeOfString:text options:mask range:searchRange];
	if (result.location == NSNotFound) {
		return [NSNumber numberWithUnsignedInteger:0];
 	} else {
		return [NSNumber numberWithUnsignedInteger:(result.location + 1)];
 	}
}

- (id)handleLatexCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doJobForScript:LatexEngine withError:YES runContinuously:YES];

	return nil;
}

- (id)handleLatexInteractiveCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doJobForScript:LatexEngine withError:YES runContinuously:NO];

	return nil;
}

- (id)handleTexCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doJobForScript:TexEngine withError:YES runContinuously:YES];

	return nil;
}

- (id)handleTexInteractiveCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doJobForScript:TexEngine withError:YES runContinuously:NO];

	return nil;
}

- (id)handleBibtexCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doJobForScript:BibtexEngine withError:YES runContinuously:YES];

	return nil;
}

- (id)handleBibtexInteractiveCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doJobForScript:BibtexEngine withError:YES runContinuously:NO];

	return nil;
}


- (id)handleContextCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doJobForScript:ContextEngine withError:YES runContinuously:YES];

	return nil;
}

- (id)handleContextInteractiveCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doJobForScript:ContextEngine withError:YES runContinuously:NO];

	return nil;
}

- (id)handleMetapostCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doJobForScript:MetapostEngine withError:YES runContinuously:YES];

	return nil;
}

- (id)handleMetapostInteractiveCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doJobForScript:MetapostEngine withError:YES runContinuously:NO];

	return nil;
}

- (id)handleMakeindexCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doJobForScript:IndexEngine withError:YES runContinuously:YES];

	return nil;
}

- (id)handleMakeindexInteractiveCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doJobForScript:IndexEngine withError:YES runContinuously:NO];

	return nil;
}

- (id)handleTypesetCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doTypesetForScriptContinuously:YES];

	return nil;
}

- (id)handleTypesetInteractiveCommand:(NSScriptCommand*)command
{
	taskDone = NO;
	[self doTypesetForScriptContinuously:NO];

	return nil;
}

- (id)handleRefreshPDFCommand:(NSScriptCommand*)command
{
	[self refreshPDFAndBringFront: YES];

	return nil;
}

- (id)handleRefreshPDFBackgroundCommand:(NSScriptCommand*)command
{
	[self refreshPDFAndBringFront: NO];

	return nil;
}

- (id)handleRefreshTEXTCommand:(NSScriptCommand*)command
{
	[self refreshTEXT];

	return nil;
}

- (id)handleTaskDoneCommand:(NSScriptCommand*)command
{
	NSNumber *theResult = [NSNumber numberWithBool:taskDone];
	return theResult;
}

- (id)handleGotoLineCommand:(NSScriptCommand*)command
{
	NSInteger line;

	NSDictionary* args = [command evaluatedArguments];
	line = [[args objectForKey:@"LineNumber"] unsignedIntegerValue];
	[self toLine:line];

	return nil;
}


@end

@implementation MySelection

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (id)initWithMyDocument:(TSDocument*)doc
{
	mDocument = doc;
	return self;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSUInteger)offset
{
	NSUInteger	x = [[mDocument firstTextView] selectedRange].location;
    
	return x;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSUInteger)length
{
	NSUInteger x = [[mDocument firstTextView] selectedRange].length;
   
	return x;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void)setOffset:(NSUInteger)off
{
	NSRange		range 		= [[mDocument firstTextView] selectedRange];
	NSUInteger	textLength	= [[[mDocument firstTextView] string] length];

	if (off > textLength)
		off = textLength;
	range.location = off;
	if ((range.location + range.length) > textLength)
		range.length = textLength - range.location;

		[[mDocument firstTextView] setSelectedRange:range];
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void)setLength:(NSUInteger)len
{
	NSRange		range 		= [[mDocument firstTextView] selectedRange];
	NSUInteger	textLength	= [[[mDocument firstTextView] string] length];

	range.length = len;
	if ((range.location + range.length) > textLength)
		range.length = textLength - range.location;

		[[mDocument firstTextView] setSelectedRange:range];
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSString*)content
{
	NSRange		range 		= [[mDocument firstTextView] selectedRange];
	if (range.length == 0)
		return [NSString string];
	return [[[mDocument firstTextView] string] substringWithRange:range];
}


// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void)setContent:(NSString*)ts
{
	[mDocument setSelection:ts];
}

/*
- (NSTextStorage*)textStorage
{
	NSRange		range 		= [[mDocument firstTextView] selectedRange];
	return [[[NSTextStorage alloc] initWithAttributedString:[[mDocument textStorage]
				attributedSubstringFromRange:range]] autorelease];
}

// We already have a textStorage() method implemented above.
- (void)setTextStorage:(id)ts
{
	[mDocument setSelection:ts];
}
*/
@end



@implementation NSApplication (ScriptingSupport)

// Scripting support.

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSArray *)orderedDocuments {
	NSArray *orderedWindows = [NSApp valueForKey:@"orderedWindows"];
	NSUInteger i, c = [orderedWindows count];
	NSMutableArray *orderedDocs = [NSMutableArray array];
	id curDelegate;

	for (i=0; i<c; i++) {
		curDelegate = [[orderedWindows objectAtIndex:i] delegate];

		if ((curDelegate != nil) && [curDelegate isKindOfClass:[TSDocument class]]) {
			[orderedDocs addObject:curDelegate];
		}
	}
	return orderedDocs;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
	return [key isEqualToString:@"orderedDocuments"];
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void)insertInOrderedDocuments:(TSDocument *)doc atIndex:(NSInteger)idx {
	[doc retain];	// Keep it around...
	[[doc firstTextView] setSelectedRange:NSMakeRange(0, 0)];
//	[doc setDocumentName:nil];
//	[doc setDocumentEdited:NO];
//	[doc setPotentialSaveDirectory:[TSDocument openSavePanelDirectory]];
	[[doc window] makeKeyAndOrderFront:nil];
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (id)handleOpenForExternalEditorCommand:(NSScriptCommand*)command
{
	NSDocumentController	*myController;
	BOOL			useExternalEditor;
	id                          result;

	NSDictionary *args = [command evaluatedArguments];
	NSString *myName = [args objectForKey:@"FileName"];
	if (!myName || [myName isEqualToString:@""])
		return [NSNumber numberWithBool:NO];

	useExternalEditor = [SUD boolForKey:UseExternalEditorKey];
	myController = [NSDocumentController sharedDocumentController];
  //  forPreview = YES;
	[(TSAppDelegate *)[self delegate] setForPreview:YES];

	result = [myController openDocumentWithContentsOfURL: [NSURL fileURLWithPath: myName] display: YES error:NULL];

	[(TSAppDelegate *)[self delegate] setForPreview:useExternalEditor];

	if (result == nil)
		return [NSNumber numberWithBool:NO];
	else
		return [NSNumber numberWithBool:YES];
}


@end


