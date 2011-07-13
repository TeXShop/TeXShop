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
 * $Id: TextFinder.m 108 2006-02-10 13:50:25Z fingolfin $
 *
 * This code was derived from Apple Sample code TextEdit
 *
 */

#import "TextFinder.h"
// added by mitsu --(A) g_texChar filtering and (G) TSEncodingSupport
#import "TSEncodingSupport.h"
// end addition

NSString *FindStringChangedNotification = @"Find Selection Changed Notification";

@implementation TextFinder

static id sharedFindObject = nil;

+ (id)sharedInstance {
	if (!sharedFindObject) {
		[[self allocWithZone:[[NSApplication sharedApplication] zone]] init];
	}
	return sharedFindObject;
}

- (id)init {
	if (sharedFindObject) {
		[super dealloc];
		return sharedFindObject;
	}

	if (!(self = [super init])) return nil;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidActivate:) name:NSApplicationDidBecomeActiveNotification object:[NSApplication sharedApplication]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addWillDeactivate:) name:NSApplicationWillResignActiveNotification object:[NSApplication sharedApplication]];

	[self setFindString:@""];
	[self loadFindStringFromPasteboard];

	sharedFindObject = self;
	return self;
}

- (void)appDidActivate:(NSNotification *)notification {
	[self loadFindStringFromPasteboard];
}

- (void)addWillDeactivate:(NSNotification *)notification {
	[self loadFindStringToPasteboard];
}

- (void)loadFindStringFromPasteboard {
	NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
	if ([[pasteboard types] containsObject:NSStringPboardType]) {
		NSString *string = [pasteboard stringForType:NSStringPboardType];
		if (string && [string length]) {
			[self setFindString:string];
			findStringChangedSinceLastPasteboardUpdate = NO;
		}
	}
}

- (void)loadFindStringToPasteboard {
	NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
	if (findStringChangedSinceLastPasteboardUpdate) {
		[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
		[pasteboard setString:[self findString] forType:NSStringPboardType];
	findStringChangedSinceLastPasteboardUpdate = NO;
	}
}


- (void)loadUI {
	if (!findTextField) {
		if (![NSBundle loadNibNamed:@"FindPanel" owner:self])  {
			NSLog(@"Failed to load FindPanel.nib");
			NSBeep();
			return;
		}
	if (self == sharedFindObject) [[findTextField window] setFrameAutosaveName:@"Find"];
// added by mitsu --(A) g_texChar filtering
		[findTextField setDelegate: [TSEncodingSupport sharedInstance]];
		[replaceTextField setDelegate: [TSEncodingSupport sharedInstance]];
// end addition

	}
	[findTextField setStringValue:[self findString]];
}

- (void)dealloc {
	if (self != sharedFindObject) {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[findString release];
		[super dealloc];
	}
}

- (NSString *)findString {
	return findString;
}

- (void)setFindString:(NSString *)string {
	if ([string isEqualToString:findString]) return;
	[findString autorelease];
	findString = [string copyWithZone:[self zone]];
	if (findTextField) {
		[findTextField setStringValue:string];
		[findTextField selectText:nil];
	}
	findStringChangedSinceLastPasteboardUpdate = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:FindStringChangedNotification object:findString];
}

- (NSTextView *)textObjectToSearchIn {
	id obj = [[NSApp mainWindow] firstResponder];
	return (obj && [obj isKindOfClass:[NSTextView class]]) ? obj : nil;
}

- (NSPanel *)findPanel {
	if (!findTextField) [self loadUI];
	return (NSPanel *)[findTextField window];
}

/* The primitive for finding; this ends up setting the status field (and beeping if necessary)...
*/
- (BOOL)find:(BOOL)direction {
	NSTextView *text = [self textObjectToSearchIn];
	lastFindWasSuccessful = NO;
	if (text) {
		NSString *textContents = [text string];
		NSUInteger textLength;
		if (textContents && (textLength = [textContents length])) {
			NSRange range;
			NSUInteger options = 0;
		if (direction == Backward) options |= NSBackwardsSearch;
			if ([ignoreCaseButton state]) options |= NSCaseInsensitiveSearch;
			range = [textContents findString:[self findString] selectedRange:[text selectedRange] options:options wrap:YES];
			if (range.length) {
				[text setSelectedRange:range];
				[text scrollRangeToVisible:range];
				lastFindWasSuccessful = YES;
			}
		}
	}
	if (!lastFindWasSuccessful) {
		NSBeep();
		[statusField setStringValue:NSLocalizedStringFromTable(@"Not found", @"FindPanel", @"Status displayed in find panel when the find string is not found.")];
	} else {
		[statusField setStringValue:@""];
	}
	return lastFindWasSuccessful;
}

- (void)orderFrontFindPanel:(id)sender {
	NSPanel *panel = [self findPanel];
	[findTextField selectText:nil];
	[panel makeKeyAndOrderFront:nil];
}

/**** Action methods for gadgets in the find panel; these should all end up setting or clearing the status field ****/

- (void)findNextAndOrderFindPanelOut:(id)sender {
	[findNextButton performClick:nil];
	if (lastFindWasSuccessful) {
		[[self findPanel] orderOut:sender];
	} else {
	[findTextField selectText:nil];
	}
}

- (void)findNext:(id)sender {
	if (findTextField) [self setFindString:[findTextField stringValue]];	/* findTextField should be set */
	(void)[self find:Forward];
}

- (void)findPrevious:(id)sender {
	if (findTextField) [self setFindString:[findTextField stringValue]];	/* findTextField should be set */
	(void)[self find:Backward];
}

- (void)replace:(id)sender {
	NSTextView *text = [self textObjectToSearchIn];
	if (text && [text shouldChangeTextInRange:[text selectedRange] replacementString:[replaceTextField stringValue]]) {
		[[text textStorage] replaceCharactersInRange:[text selectedRange] withString:[replaceTextField stringValue]];
		[text didChangeText];
	} else {
		NSBeep();
	}
	[statusField setStringValue:@""];
}

- (void)replaceAndFind:(id)sender {
	[self replace:sender];
	[self findNext:sender];
}

#define ReplaceAllScopeEntireFile 42
#define ReplaceAllScopeSelection 43

/* The replaceAll: code is somewhat complex, and more complex than it used to be in DR1.  The main reason for this is to support undo. To play along with the undo mechanism in the text object, this method goes through the shouldChangeTextInRange:replacementString: mechanism. In order to do that, it precomputes the section of the string that is being updated. An alternative would be for this guy to handle the undo for the replaceAll: operation itself, and register the appropriate changes. However, this is simpler...

Turns out this approach of building the new string and inserting it at the appropriate place in the actual text storage also has an added benefit performance; it avoids copying the contents of the string around on every replace, which is significant in large files with many replacements. Of course there is the added cost of the temporary replacement string, but we try to compute that as tightly as possible beforehand to reduce the memory requirements.
*/
- (void)replaceAll:(id)sender {
	NSTextView *text = [self textObjectToSearchIn];
	if (!text) {
		NSBeep();
	} else {
		NSTextStorage *textStorage = [text textStorage];
		NSString *textContents = [text string];
		BOOL entireFile = replaceAllScopeMatrix ? ([replaceAllScopeMatrix selectedTag] == ReplaceAllScopeEntireFile) : YES;
		NSRange replaceRange = entireFile ? NSMakeRange(0, [textStorage length]) : [text selectedRange];
		NSUInteger searchOption = ([ignoreCaseButton state] ? NSCaseInsensitiveSearch : 0);
		NSUInteger replaced = 0;
		NSRange firstOccurence;

		if (findTextField) [self setFindString:[findTextField stringValue]];

		// Find the first occurence of the string being replaced; if not found, we're done!
		firstOccurence = [textContents rangeOfString:[self findString] options:searchOption range:replaceRange];
		if (firstOccurence.length > 0) {
		NSAutoreleasePool *pool;
		NSString *targetString = [self findString];
		NSString *replaceString = [replaceTextField stringValue];
			NSMutableAttributedString *temp;	/* This is the temporary work string in which we will do the replacements... */
			NSRange rangeInOriginalString;	/* Range in the original string where we do the searches */

		// Find the last occurence of the string and union it with the first occurence to compute the tightest range...
			rangeInOriginalString = replaceRange = NSUnionRange(firstOccurence, [textContents rangeOfString:targetString options:NSBackwardsSearch|searchOption range:replaceRange]);

			temp = [[NSMutableAttributedString alloc] init];

			[temp beginEditing];

		// The following loop can execute an unlimited number of times, and it could have autorelease activity.
		// To keep things under control, we use a pool, but to be a bit efficient, instead of emptying everytime through
		// the loop, we do it every so often. We can only do this as long as autoreleased items are not supposed to
		// survive between the invocations of the pool!

			pool = [[NSAutoreleasePool alloc] init];

			while (rangeInOriginalString.length > 0) {
				NSRange foundRange = [textContents rangeOfString:targetString options:searchOption range:rangeInOriginalString];
		// Because we computed the tightest range above, foundRange should always be valid.
		NSRange rangeToCopy = NSMakeRange(rangeInOriginalString.location, foundRange.location - rangeInOriginalString.location + 1);	// Copy upto the start of the found range plus one char (to maintain attributes with the overlap)...
				[temp appendAttributedString:[textStorage attributedSubstringFromRange:rangeToCopy]];
				[temp replaceCharactersInRange:NSMakeRange([temp length] - 1, 1) withString:replaceString];
				rangeInOriginalString.length -= NSMaxRange(foundRange) - rangeInOriginalString.location;
				rangeInOriginalString.location = NSMaxRange(foundRange);
				replaced++;
		if (replaced % 100 == 0) {	// Refresh the pool... See warning above!
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
			}

		[pool release];

			[temp endEditing];

		// Now modify the original string
			if ([text shouldChangeTextInRange:replaceRange replacementString:[temp string]]) {
				[textStorage replaceCharactersInRange:replaceRange withAttributedString:temp];
				[text didChangeText];
			} else {	// For some reason the string didn't want to be modified. Bizarre...
				replaced = 0;
			}

			[temp release];
		}
		if (replaced == 0) {
			NSBeep();
			[statusField setStringValue:NSLocalizedStringFromTable(@"Not found", @"FindPanel", @"Status displayed in find panel when the find string is not found.")];
		} else {
#warning 64BIT: Check formatting arguments
			[statusField setStringValue:[NSString localizedStringWithFormat:NSLocalizedStringFromTable(@"%d replaced", @"FindPanel", @"Status displayed in find panel when indicated number of matches are replaced."), replaced]];
		}
	}
}

- (void)takeFindStringFromSelection:(id)sender {
	NSTextView *textView = [self textObjectToSearchIn];
	if (textView) {
		NSString *selection = [[textView string] substringWithRange:[textView selectedRange]];
		[self setFindString:selection];
	}
}

- (void) jumpToSelection:sender {
	NSTextView *textView = [self textObjectToSearchIn];
	if (textView) {
		[textView scrollRangeToVisible:[textView selectedRange]];
	}
}

@end


@implementation NSString (NSStringTextFinding)

- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(NSUInteger)options wrap:(BOOL)wrap {
	BOOL forwards = (options & NSBackwardsSearch) == 0;
	NSUInteger length = [self length];
	NSRange searchRange, range;

	if (forwards) {
	searchRange.location = NSMaxRange(selectedRange);
	searchRange.length = length - searchRange.location;
	range = [self rangeOfString:string options:options range:searchRange];
		if ((range.length == 0) && wrap) {	/* If not found look at the first part of the string */
		searchRange.location = 0;
			searchRange.length = selectedRange.location;
			range = [self rangeOfString:string options:options range:searchRange];
		}
	} else {
	searchRange.location = 0;
	searchRange.length = selectedRange.location;
		range = [self rangeOfString:string options:options range:searchRange];
		if ((range.length == 0) && wrap) {
			searchRange.location = NSMaxRange(selectedRange);
			searchRange.length = length - searchRange.location;
			range = [self rangeOfString:string options:options range:searchRange];
		}
	}
	return range;
}

@end
