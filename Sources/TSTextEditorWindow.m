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
 * $Id: TSTextEditorWindow.m 260 2007-08-08 22:51:09Z richard_koch $
 *
 * Originally part of TSDocument. Broken out by dirk on Tue Jan 09 2001.
 *
 */

#import <AppKit/AppKit.h>
#import "TSTextEditorWindow.h"
#import "TSDocument.h" // for the definition of isTeX (move this to a separate file!!)
#import "globals.h"



@implementation TSTextEditorWindow : NSWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	id  result;
	result = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];
	CGFloat alpha = [SUD floatForKey: SourceWindowAlphaKey];
	if (alpha < 0.999)
		 [self setAlphaValue:alpha];
	return result;
}


- (void) becomeMainWindow
{
	if([myDocument fileURL] != nil ) [self setTitle:[myDocument fileTitleName]]; // added by Terada
	[super becomeMainWindow];
	[myDocument resetSpelling];
	[myDocument fixMacroMenuForWindowChange];
}

// added by mitsu --(H) Macro menu; used to detect the document from a window
- (TSDocument *)document
{
	return myDocument;
}
// end addition

- (void)makeKeyAndOrderFront:(id)sender
{
    
	if (
		(! [myDocument externalEditor]) &&
		(([myDocument documentType] == isTeX) || ([myDocument documentType] == isOther))
		)
		[super makeKeyAndOrderFront: sender];
	[myDocument tryBadEncodingDialog:self];
}

- (void)associatedWindow:(id)sender
{
	if ([myDocument documentType] == isTeX) {
		[myDocument bringPdfWindowFront];
	}
}

- (void) doChooseMethod: sender
{
	[myDocument doChooseMethod: sender];
}

- (void) abort: sender
{
	[myDocument abort: sender];
}

- (void) trashAUXFiles: sender
{
	[myDocument trashAUXFiles: sender];
}


// forsplit
- (BOOL)makeFirstResponder:(NSResponder *)aResponder
{
	BOOL	result;

	result = [super makeFirstResponder:aResponder];
	// FIXME: This is kind of ugly...
	if (result && [[aResponder className] isEqualTo:@"TSTextView"]) {
		[myDocument setTextView:aResponder];
	}
	return result;
}
// end forsplit

- (void)close
{
    
	[[NSNotificationCenter defaultCenter] removeObserver:[myDocument pdfView]]; // this fixes a bug; the application crashed when closing
	// the last window in multi-page mode; investigation shows that the
	// myPDFView "wasScrolled" method was called from the notification center before dealloc, but after other items in the window
	// were released
	NSArray *myDocuments = [[NSDocumentController sharedDocumentController] documents];
	if (myDocuments != nil) {
		NSEnumerator *enumerator = [myDocuments objectEnumerator];
		id anObject;
		while ((anObject = [enumerator nextObject])) {
			if ([anObject getCallingWindow] == self)
				[anObject setCallingWindow: nil];
		}
	}

	[super close];
}

- (void)sendEvent:(NSEvent *)theEvent
{
	
//	if (([theEvent type] == NSFlagsChanged) && ([theEvent modifierFlags] & NSCommandKeyMask))
//		NSLog(@"yes");
	
	if (([theEvent type] == NSKeyDown) && ([theEvent modifierFlags] & NSCommandKeyMask)) {
		
		if  ([[theEvent characters] characterAtIndex:0] == '[') {
			[myDocument doCommentOrIndentForTag:Munindent];
			return;
		} 
	
		if  ([[theEvent characters] characterAtIndex:0] == ']') {
			[myDocument doCommentOrIndentForTag:Mindent];
			return;
		} 
	}
	
	[super sendEvent: theEvent];
}

- (void)saveSourcePosition: sender
{
	[myDocument saveSourcePosition];
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)defaultFrame
{
	NSRect	newFrame;
	
	newFrame = defaultFrame;
	if (defaultFrame.size.width > 1024)
		newFrame.size.width = 1024;
	return newFrame;
}



@end
