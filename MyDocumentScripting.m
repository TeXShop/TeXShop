// ================================================================================
//  MyDocumentScripting.m
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

#import "MyDocumentScripting.h"
#import "globals.h"

#define SUD [NSUserDefaults standardUserDefaults]

@implementation MyDocument (ScriptingSupport)

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
		mSelection = [[MySelection alloc] initWithDocument:self];
	return mSelection;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------
// We already have a textStorage() method implemented above.

/* This is the original routine; it was later replaced, as below 
- (void)setSelection:(id)ts 
{
    // ts can actually be a string or an attributed string.
	NSRange		range 		= [[self firstTextView] selectedRange];
    if ([ts isKindOfClass:[NSAttributedString class]]) {
        [[self textStorage] replaceCharactersInRange:range withAttributedString:ts];
    } else {
        [[self textStorage] replaceCharactersInRange:range withString:ts];
    }
	range.location += [(NSString*)ts length];
	range.length	= 0;
	[[self firstTextView] setSelectedRange:range];
}
*/


// New version by Stefan Walsen; November 17, 2003
/* Here is the email explaining the problem and its cause:

JŽr™me Laurens wrote:
Le 17 nov. 03, ˆ 15:00, Stefan Walsen a Žcrit :
[...]
    set (content of selection of front document) to cmdOutput
Beware, this last line breaks the undo stack and can lead to weird|dangerous 
things unless the replacement string has exactly the same length as the replaced one...

I noticed this, too. That's what I meant with the last line of my email.

To keep me from doing important stuff, I looked into TeXShop's source and found the reason for this behaviour:
TeXShop's undo manager just wasn't informed of the change in the document / selection.
*/
- (void)setSelection:(id)ts 
{
    // ts can actually be a string or an attributed string.

	NSRange		range = [[self firstTextView] selectedRange];
	NSString *oldString, *key= @"AppleEvent";
	unsigned newStringLen, from, to;

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
    unsigned theIndex = [orderedDocs indexOfObjectIdenticalTo:self];

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
	unsigned		startFrom		= [args objectForKey:@"StartOffset"] ?
											[[args objectForKey:@"StartOffset"] unsignedIntValue] :
											[[self firstTextView] selectedRange].location;
	NSString*		myText			= [[self firstTextView] string];										
											
	NSRange			result, searchRange;
	unsigned		mask = NSLiteralSearch;
	
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
		return [NSNumber numberWithUnsignedInt:0];
	} else {
		return [NSNumber numberWithUnsignedInt:(result.location+1)];
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
    int line;
    
    NSDictionary* args = [command evaluatedArguments];
    line = [[args objectForKey:@"LineNumber"] unsignedIntValue];
    [self toLine:line];
}


@end

@implementation MySelection

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (id)initWithDocument:(MyDocument*)doc
{
	mDocument = doc;
	return self;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (unsigned)offset
{	
	unsigned	x = [[mDocument firstTextView] selectedRange].location;
	return x;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (unsigned)length
{
	unsigned x = [[mDocument firstTextView] selectedRange].length;
	return x;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void)setOffset:(unsigned)off
{
	NSRange		range 		= [[mDocument firstTextView] selectedRange];
	unsigned	textLength	= [[[mDocument firstTextView] string] length];
	
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

- (void)setLength:(unsigned)len
{
	NSRange		range 		= [[mDocument firstTextView] selectedRange];
	unsigned	textLength	= [[[mDocument firstTextView] string] length];
	
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
    unsigned i, c = [orderedWindows count];
    NSMutableArray *orderedDocs = [NSMutableArray array];
    id curDelegate;
    
    for (i=0; i<c; i++) {
        curDelegate = [[orderedWindows objectAtIndex:i] delegate];
        
        if ((curDelegate != nil) && [curDelegate isKindOfClass:[MyDocument class]]) {
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

- (void)insertInOrderedDocuments:(MyDocument *)doc atIndex:(int)index {
    [doc retain];	// Keep it around...
    [[doc firstTextView] setSelectedRange:NSMakeRange(0, 0)];
//	[doc setDocumentName:nil];
//	[doc setDocumentEdited:NO];
//	[doc setPotentialSaveDirectory:[MyDocument openSavePanelDirectory]];
    [[doc window] makeKeyAndOrderFront:nil];
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (id)handleOpenForExternalEditorCommand:(NSScriptCommand*)command;
{
    NSDocumentController	*myController;
    BOOL			externalEditor;
    id                          result;
    
    NSDictionary *args = [command evaluatedArguments];
    NSString *myName = [args objectForKey:@"FileName"];
    if (!myName || [myName isEqualToString:@""])
        return [NSNumber numberWithBool:NO];
    
    externalEditor = [SUD boolForKey:UseExternalEditorKey];
    myController = [NSDocumentController sharedDocumentController];
  //  forPreview = YES;
    [[self delegate] setForPreview:YES];
        
    result = [myController openDocumentWithContentsOfFile: myName display: YES];

    if (externalEditor)
        [[self delegate] setForPreview:YES];
    else
        [[self delegate] setForPreview:NO];
        
    if (result == nil)
        return [NSNumber numberWithBool:NO];
    else
        return [NSNumber numberWithBool:YES];
}


@end


