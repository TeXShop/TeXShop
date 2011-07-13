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
 * $Id: TextFinder.h 108 2006-02-10 13:50:25Z fingolfin $
 *
 * This code was derived from Apple Sample code TextEdit
 *
 */

#import <AppKit/AppKit.h>

// from Apple

#define Forward YES
#define Backward NO

@interface TextFinder : NSObject {
	NSString *findString;
	id findTextField;
	id replaceTextField;
	id ignoreCaseButton;
	id findNextButton;
	id replaceAllScopeMatrix;
	id statusField;
	BOOL findStringChangedSinceLastPasteboardUpdate;
	BOOL lastFindWasSuccessful;		/* A bit of a kludge */
}

/* Common way to get a text finder. One instance of TextFinder per app is good enough. */
+ (id)sharedInstance;

/* Main method for external users; does a find in the first responder. Selects found range or beeps. */
- (BOOL)find:(BOOL)direction;

/* Loads UI lazily */
- (NSPanel *)findPanel;

/* Gets the first responder and returns it if it's an NSTextView */
- (NSTextView *)textObjectToSearchIn;

/* Get/set the current find string. Will update UI if UI is loaded */
- (NSString *)findString;
- (void)setFindString:(NSString *)string;

/* Misc internal methods */
- (void)appDidActivate:(NSNotification *)notification;
- (void)addWillDeactivate:(NSNotification *)notification;
- (void)loadFindStringFromPasteboard;
- (void)loadFindStringToPasteboard;

/* Methods sent from the find panel UI */
- (void)findNext:(id)sender;
- (void)findPrevious:(id)sender;
- (void)findNextAndOrderFindPanelOut:(id)sender;
- (void)replace:(id)sender;
- (void)replaceAndFind:(id)sender;
- (void)replaceAll:(id)sender;
- (void)orderFrontFindPanel:(id)sender;
- (void)takeFindStringFromSelection:(id)sender;
- (void)jumpToSelection:(id)sender;

@end


@interface NSString (NSStringTextFinding)

- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(NSUInteger)mask wrap:(BOOL)wrapFlag;

@end

/* Posted whenever the find selection has changed. */
extern NSString *FindStringChangedNotification;
