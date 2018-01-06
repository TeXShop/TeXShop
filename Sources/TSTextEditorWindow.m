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
#import "TSDocumentController.h"



@implementation TSTextEditorWindow : NSWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	id  result;
	result = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];
	CGFloat alpha = [SUD floatForKey: SourceWindowAlphaKey];
	if (alpha < 0.999)
        //[self setAlphaValue:alpha]; // removed by Terada
        [self performSelector:@selector(setAlpha:) withObject:[NSNumber numberWithFloat:alpha] afterDelay:0.5]; // added by Terada   
    [self performSelector:@selector(refreshTitle) withObject:nil afterDelay:1]; // added by Terada
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTitle) name:NSApplicationDidBecomeActiveNotification object:NSApp]; // added by Terada
    self.wasClosed = NO;
	return result;
}

-(void)setAlpha:(NSNumber*)alpha // added by Terada
{
    [self setAlphaValue:[alpha floatValue]];
}

- (void)refreshTitle // added by Terada
{
	if([self.myDocument fileURL] != nil) [self setTitle:[self.myDocument fileTitleName]];
}

// In the pair of commands below, becomeMainWindow and resignMainWindow should do nothing
// unless the window has a "% !TEX" command. In this case
// becomeMainWindow should remember the current language, set the spell to the
// % !TEX choice, and set a global saying "don't use UID to record language

// If the window has % !TEX, then resign Main Window should
// reset the language to the remebered current language, and unset
// the global for "dont use UID to record language"



- (void) becomeMainWindow
{
 	[self refreshTitle]; // added by Terada
	[super becomeMainWindow];
	[self.myDocument resetSpelling];
	[self.myDocument fixMacroMenuForWindowChange];
// WARNING: The following line caused a BIG delay when switching from the pdf window to the text window!!
// It can be turned on with a hidden preference, but the only users who need it
// a) use Japanese input methods and b) customize the background and foreground source colors and c) have a dark background color
    if ([SUD boolForKey:ResetSourceTextColorEachTimeKey])
        [self.myDocument setSourceTextColorFromPreferences:nil]; // added by Terada
}

- (void) resignMainWindow
{
    [super resignMainWindow];
    [self.myDocument resignSpelling];
}

// added by mitsu --(H) Macro menu; used to detect the document from a window
- (TSDocument *)document
{
	return self.myDocument;
}
// end addition

- (void)makeKeyAndOrderFront:(id)sender
{
    
	if 
		((! [self.myDocument externalEditor]) && (! [self.myDocument useFullSplitWindow]) &&
		(([self.myDocument documentType] == isTeX) || ([self.myDocument documentType] == isOther)))
    {
        [super makeKeyAndOrderFront: sender];
    }
	[self.myDocument tryBadEncodingDialog:self];
}

- (void)associatedWindow:(id)sender
{
	if ([self.myDocument documentType] == isTeX) {
		[self.myDocument bringPdfWindowFront];
	}
}

- (void) doChooseMethod: sender
{
	[self.myDocument doChooseMethod: sender];
}

- (void) abort: sender
{
	[self.myDocument abort: sender];
}

- (void) trashAUXFiles: sender
{
	[self.myDocument trashAUXFiles: sender];
}


// forsplit
- (BOOL)makeFirstResponder:(NSResponder *)aResponder
{
	BOOL	result;

	result = [super makeFirstResponder:aResponder];
	// FIXME: This is kind of ugly...
	if (result && [[aResponder className] isEqualTo:@"TSTextView"]) {
		[self.myDocument setTextView:aResponder];
	}
	return result;
}
// end forsplit

- (void)close
{
    self.wasClosed = YES;
    
// MAYBE NOW IRRELEVANT?
 
// Yusuke Terada addition to fix crash at close
    if(([[[TSDocumentController sharedDocumentController] documents] count] > 0) && self.myDocument && [self.myDocument respondsToSelector:@selector(pdfView)] && [self.myDocument pdfView])
        [[NSNotificationCenter defaultCenter] removeObserver:[self.myDocument pdfView]];
// end of patch
    // this fixes a bug; the application crashed when closing
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

    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // added by Terada
    
/*
    TSDocument *aDocument = self.myDocument;
    self.myDocument = nil;
    [aDocument close];
*/
    

	[super close];
}

- (void)sendEvent:(NSEvent *)theEvent
{
	
//	if (([theEvent type] == NSFlagsChanged) && ([theEvent modifierFlags] & NSCommandKeyMask))
//		NSLog(@"yes");
	
	if (([theEvent type] == NSKeyDown) && ([theEvent modifierFlags] & NSCommandKeyMask)) {
		
		if  ([[theEvent characters] characterAtIndex:0] == '[') {
			[self.myDocument doCommentOrIndentForTag:Munindent];
			return;
		} 
	
		if  ([[theEvent characters] characterAtIndex:0] == ']') {
			[self.myDocument doCommentOrIndentForTag:Mindent];
			return;
		} 
	}
	
	[super sendEvent: theEvent];
}

- (void)saveSourcePosition: sender
{
	[self.myDocument saveSourcePosition];
}


- (void)savePortableSourcePosition: sender
{
	[self.myDocument savePortableSourcePosition];
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
