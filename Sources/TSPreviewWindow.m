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
 * $Id: TSPreviewWindow.m 260 2007-08-08 22:51:09Z richard_koch $
 *
 * Originally part of TSDocument. Broken out by dirk on Tue Jan 09 2001.
 *
 */

/*
 * Among other things, this window controls splitting of the Preview Window views.
 * Splitting is done here, and controls which affect both views simultaneously
 * are connected here. Many controls automatically use the active view without help.
 *
 * The TSDocument class is involved only slightly in splitting. It receives a few toolbar
 * commands to split the window, but immediately passes them to this class. It also
 * initializes *activeView when the nib is first expanded; from them on, active view
 * is set here from calls in split window or in the pdfkitview's activate routine.
 */

#import "UseMitsu.h"

#import <AppKit/AppKit.h>
#import "TSPreviewWindow.h"
#import "TSDocument.h"
#import "MyPDFView.h"
#import "MyPDFKitView.h"
#import "globals.h"

extern NSPanel *pageNumberWindow;


@implementation TSPreviewWindow


- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	id		result;
	NSColor	*backColor;

	result = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];

	// backColor = [NSColor lightGrayColor];
	backColor = [NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha: 1.0];
	[self setBackgroundColor: backColor];

	float alpha = [SUD floatForKey: PreviewWindowAlphaKey];
	if (alpha < 0.999)
		[self setAlphaValue:alpha];

	activeView = nil;
	windowIsSplit = NO;
	willClose = NO;
	return result;
}

- (void)close
{
	[myPDFKitView setDocument: nil];
	[myPDFKitView2 setDocument: nil];
	willClose = YES;
	
	[super close];
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)defaultFrame
{
	NSRect	newFrame;
	
	newFrame = defaultFrame;
	newFrame.origin.x = newFrame.origin.x + 200;
	
	newFrame.size.width = newFrame.size.width - 200;
	return newFrame;
}



/*
- (BOOL)makeFirstResponder:(NSResponder *)aResponder
{
	if (aResponder == self)
		return NO;
	else return [super makeFirstResponder: aResponder];
}
*/

- (void) becomeMainWindow
{
	willClose = NO;
	if([myDocument fileName] != nil ) [self setTitle:[[[myDocument fileTitleName] stringByDeletingPathExtension] stringByAppendingString: @".pdf"]]; // added by Terada
	[super becomeMainWindow];

	[myDocument fixMacroMenuForWindowChange];
}


- (void) doTextMagnify: sender
{
	id	thePanel;

	thePanel = [myDocument magnificationPanel];

	[NSApp beginSheet: thePanel
			modalForWindow: self
			modalDelegate: self
			didEndSelector: @selector(magnificationDidEnd:returnCode:contextInfo:)
			contextInfo: nil];
}

- (void)magnificationDidEnd:(NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
	// [sheet close];
	[sheet orderOut: self];
}

- (void) doTextPage: sender      // for toolbar in text mode
{
	id	thePanel;

	thePanel = [myDocument pagenumberPanel];

	[NSApp beginSheet: thePanel
			modalForWindow: self
			modalDelegate: self
			didEndSelector:  @selector(pagenumberDidEnd:returnCode:contextInfo:)
			contextInfo: nil];
}

- (void)pagenumberDidEnd:(NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
	// [sheet close];
	[sheet orderOut: self];
}

- (void) displayLog: sender
{
	[myDocument displayLog: sender];
}

- (void) displayConsole: sender
{
	[myDocument displayConsole: sender];
}

- (void) abort: sender
{
	[myDocument abort: sender];
}

- (void) trashAUXFiles: sender
{
	[myDocument trashAUXFiles: sender];
}

- (void) runPageLayout: sender
{
	[myDocument runPageLayout: sender];
}

- (void) printDocument: sender
{
	[myDocument printDocument: sender];
}

- (void) printSource: sender
{
	[myDocument printSource: sender];
}

- (void) doTypeset: sender
{
	[myDocument doTypeset: sender];
}

- (void) flipShowSync: sender
{
	[myDocument flipShowSync: sender];
}

- (void) doTex: sender
{
	[myDocument doTex: sender];
}

- (void) doLatex: sender
{
	[myDocument doLatex: sender];
}

- (void) doBibtex: sender
{
	[myDocument doBibtex: sender];
}

- (void) doIndex: sender
{
	[myDocument doIndex: sender];
}

- (void) doMetapost: sender
{
	[myDocument doMetapost: sender];
}

- (void) doContext: sender
{
	[myDocument doContext: sender];
}

- (void) doMetaFont: sender
{
	[myDocument doMetaFont: sender];
}

- (void) previousPage: sender
{
	if ([myDocument fromKit])
		[[myDocument pdfKitView] previousPage: sender];
	else
		[[myDocument pdfView] previousPage: sender];
}

- (void) nextPage: sender;
{	
	
	if ([myDocument fromKit])
		[[myDocument pdfKitView] nextPage: sender];
	else
		[[myDocument pdfView] nextPage: sender];
}


- (void) doChooseMethod: sender
{
	[myDocument doChooseMethod: sender];
}

- (void) doError: sender
{
	[myDocument doError: sender];
}

- (void) setProjectFile: sender
{
	[myDocument setProjectFile: sender];
}

- (void) rotateClockwise: sender
{
	if ([myDocument fromKit])
		[[myDocument pdfKitView] rotateClockwise: sender];
	else {
		[[myDocument pdfView] rotateClockwise: sender];
	}
}

- (void) rotateCounterclockwise: sender
{
	if ([myDocument fromKit])
		[[myDocument pdfKitView] rotateCounterclockwise: sender];
	else {
		[[myDocument pdfView] rotateCounterclockwise: sender];
	}
}

////////////////////// key movement ///////////////////////////////////

- (void) firstPage: sender;
{	if ([myDocument fromKit])
		[[myDocument pdfKitView] firstPage: sender];
	else
		[[myDocument pdfView] firstPage: sender];
}

- (void) lastPage: sender
{
	if ([myDocument fromKit])
		[[myDocument pdfKitView] lastPage: sender];
	else
		[[myDocument pdfView] lastPage: sender];
}

- (void) up: sender
{
	if (![myDocument fromKit]) {
		[[myDocument pdfView] up: sender];
	}
}

- (void) down: sender
{
	if (![myDocument fromKit]) {
		[[myDocument pdfView] down: sender];
	}
}

- (void) top: sender
{
	if (![myDocument fromKit]) {
		[[myDocument pdfView] top: sender];
	}
}

- (void) bottom: sender
{
	if (![myDocument fromKit]) {
		[[myDocument pdfView] bottom: sender];
	}
}

// mitsu 1.29 (O)
- (void) left: sender
{
	if (![myDocument fromKit]) {
		[[myDocument pdfView] left: sender];
	}
}

- (void) right: sender
{
	if (![myDocument fromKit]) {
		[[myDocument pdfView] right: sender];
	}
}

////////// end key movement /////////////////////////

- (void) orderOut:sender
{
	willClose = YES;
	if ([myDocument externalEditor]) {
		if (! [myDocument getWillClose]) {
			[myDocument setWillClose: YES];
			[myDocument close];
		}
	}
	else if (([myDocument documentType] != isTeX) && ([myDocument documentType] != isOther)) {
		if (! [myDocument getWillClose]) {
			[myDocument setWillClose: YES];
			[myDocument close];
		}		
	}
	else
		[super orderOut: sender];
}

- (void)associatedWindow:(id)sender
{
	if ([myDocument documentType] == isTeX) {
		if ([myDocument getCallingWindow] == nil)
			[[myDocument textWindow] makeKeyAndOrderFront: self];
		else
			[[myDocument getCallingWindow] makeKeyAndOrderFront: self];

		}
}

- (void)sendEvent:(NSEvent *)theEvent
{
	 if (willClose) {
		[super sendEvent: theEvent];
		return;
	}
	
	if ([myDocument fromKit] && ([theEvent type] == NSKeyDown) && ([theEvent modifierFlags] & NSCommandKeyMask)) {
		if ([[theEvent characters] characterAtIndex:0] == '[') {
			// [[myDocument pdfKitView] goBack: self];
			[activeView zoomOut:nil];
			return;
		} 
		
		if ([[theEvent characters] characterAtIndex:0] == ']') {
			// [[myDocument pdfKitView] goForward: self];
			[activeView zoomIn:nil];
			return;
		} 
	
	}

	if (![myDocument fromKit]) {
		
		unichar	theChar;

		if ([theEvent type] == NSKeyDown) {

			/*
			if (([theEvent modifierFlags] & NSControlKeyMask) &&
				([myDocument documentType] == isTeX) &&
				([[theEvent charactersIgnoringModifiers] isEqualToString:@"1"])) {

				[[myDocument textWindow] makeKeyAndOrderFront: self];
				return;
			}
			*/

			theChar = [[theEvent characters] characterAtIndex:0];

			switch (theChar) {

#ifdef MITSU_PDF

				case NSUpArrowFunctionKey: [self up:self]; return;

				case NSDownArrowFunctionKey: [self down:self]; return;

				case NSLeftArrowFunctionKey: [self left: self]; return;// mitsu 1.29 (O) changed from previousPage

				case NSRightArrowFunctionKey: [self right: self]; return;// mitsu 1.29 (O) changed from nextPage

				case NSPageUpFunctionKey: [self top:self]; return;

				case NSPageDownFunctionKey: [self bottom:self]; return;

#else

				case NSLeftArrowFunctionKey: [self previousPage: self]; return;

				case NSRightArrowFunctionKey: [self nextPage: self]; return;

#endif

				case NSHomeFunctionKey: [self firstPage: self]; return;

				case NSEndFunctionKey: [self lastPage: self]; return;

				case ' ':
					if (([theEvent modifierFlags] & NSShiftKeyMask) == 0)
						[self nextPage: self];
					else
						[self previousPage: self];
					return;
			}
		}


#ifdef MITSU_PDF

		else if ([theEvent type] == NSFlagsChanged) // mitsu 1.29 (S2)
		{
			[[myDocument pdfView] flagsChanged: theEvent];
			return;
		}
		else if ([theEvent type] == NSLeftMouseDown) // mitsu 1.29 (O) resize PDF view
		{
			// check if mouse was in vertical scroller's knob
			MyPDFView *pdfView = [myDocument pdfView];
			NSScroller *scroller = [[pdfView enclosingScrollView] verticalScroller];
			if (([scroller testPart: [theEvent locationInWindow]] == NSScrollerKnob) &&
				([myDocument documentType] == isTeX || [myDocument documentType] == isPDF) &&
				([pdfView pageStyle] == PDF_MULTI_PAGE_STYLE ||
				 [pdfView pageStyle] == PDF_DOUBLE_MULTI_PAGE_STYLE) &&
				([pdfView rotationAmount] == 0 || [pdfView rotationAmount] == 180))
			{
				// create a small window displaying page number
				NSRect aRect = [scroller rectForPart: NSScrollerKnob];
				aRect = [scroller convertRect: aRect toView: nil]; // use rect not point
				aRect.origin = [self convertBaseToScreen: aRect.origin];
				aRect.origin.x -= PAGE_WINDOW_H_OFFSET;
				aRect.origin.y += aRect.size.height/2 + PAGE_WINDOW_V_OFFSET;
				aRect.size.width = PAGE_WINDOW_WIDTH;
				aRect.size.height = PAGE_WINDOW_HEIGHT;
				pageNumberWindow = [[NSPanel alloc] initWithContentRect: aRect
															  styleMask: NSBorderlessWindowMask | NSUtilityWindowMask
																backing: NSBackingStoreBuffered //NSBackingStoreRetained
																  defer: NO];
				[pageNumberWindow setHasShadow: PAGE_WINDOW_HAS_SHADOW];
				[pageNumberWindow orderFront: nil];
				[pageNumberWindow setFloatingPanel: YES];
				[[myDocument pdfView] updateCurrentPage]; // draw page number

				[super sendEvent: theEvent]; // let the scroller handle the situation

				[pageNumberWindow close];
				pageNumberWindow = nil;
				return;
			}
		}

#endif
	}
	[super sendEvent: theEvent];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	
	if ([anItem action] == @selector(splitWindow:)) {
		if (windowIsSplit)
			[anItem setState:NSOnState];
		else
			[anItem setState:NSOffState];
		return YES;
	}

	if ([anItem action] == @selector(displayLatexPanel:))
		return NO;
	if ([anItem action] == @selector(displayMatrixPanel:))
		return NO;

#ifdef MITSU_PDF
#else
	if ([anItem action] == @selector(rotateClockwise:) ||
		[anItem action] == @selector(rotateCounterclockwise:))
		return (([myDocument documentType] == isTeX) || ([myDocument documentType] == isPDF));
#endif

	if ([anItem action] == @selector(doError:) ||
		[anItem action] == @selector(printSource:))
		return ((![myDocument externalEditor]) && ([myDocument documentType] == isTeX));

	if ([anItem action] == @selector(setProjectFile:))
		return ([myDocument documentType] == isTeX);

	if ([myDocument documentType] != isTeX) {
		if ([anItem action] == @selector(saveDocument:))
			return ([myDocument documentType] == isOther);
		if ([anItem action] == @selector(doTex:) ||
			[anItem action] == @selector(doLatex:) ||
			[anItem action] == @selector(doBibtex:) ||
			[anItem action] == @selector(doIndex:) ||
			[anItem action] == @selector(doMetapost:) ||
			[anItem action] == @selector(doContext:) ||
			[anItem action] == @selector(doMetaFont:) ||
			[anItem action] == @selector(doTypeset:))
			return NO;
		if ([anItem action] == @selector(printDocument:))
			return (([myDocument documentType] == isPDF) ||
					([myDocument documentType] == isJPG) ||
					([myDocument documentType] == isTIFF));
	}

#ifdef MITSU_PDF

		// mitsu 1.29 (O)
	if ([anItem action] == @selector(changePageStyle:)) {
		
		return (([myDocument documentType] == isTeX) || ([myDocument documentType] == isPDF));
	}

	if ([anItem action] == @selector(copy:) || [anItem action] == @selector(saveSelectionToFile:))
		return ([[myDocument pdfView] hasSelection]);
	// end mitsu 1.29 (O)

#endif

	return [super validateMenuItem: anItem];
}


- (TSDocument *)document
{
	return myDocument;
}

#ifdef MITSU_PDF


// mitsu 1.29 (O)
- (void)changePageStyle: (id)sender
{
	if ([myDocument fromKit])
		[[myDocument pdfKitView] changePageStyle: sender];
	else
		[[myDocument pdfView] changePageStyle: sender];
}

- (void)changePDFViewSize: (id)sender
{	if ([myDocument fromKit])
		[[myDocument pdfKitView] changePDFViewSize: sender];
	else
		[[myDocument pdfView] changePDFViewSize: sender];
}

- (void)zoomIn: (id)sender
{
	if ([myDocument fromKit])
		[[myDocument pdfKitView] zoomIn: sender];
}

- (void)zoomOut: (id)sender
{
	
	if ([myDocument fromKit])
		[[myDocument pdfKitView] zoomOut: sender];
}

- (void)fullscreen: (id)sender
{
	if ([myDocument fromKit])
		[myDocument fullscreen: sender];
}

- (void) savePreviewPosition: sender
{
	[myDocument savePreviewPosition];
}

- (void)copy: (id)sender
{
	if ([myDocument fromKit])
		[[myDocument pdfKitView] copy: sender];
	else
		[[myDocument pdfView] copy: sender];
}

-(void)saveSelectionToFile: (id)sender
{	if ([myDocument fromKit])
		[[myDocument pdfKitView] saveSelectionToFile: sender];
	else
		[[myDocument pdfView] saveSelectionToFile: sender];
}
// end mitsu 1.29 (O)
// end mitsu 1.29

/*
- (void) configurePaperSize: sender
{
    [myDocument configurePaperSize: self];
}
*/

#endif

- (void) splitPdfKitWindow: (id)sender
{
	NSSize		newSize;
	NSRect		theFrame;
	
	[(MyPDFKitView *)myPDFKitView cleanupMarquee: YES];
	[(MyPDFKitView *)myPDFKitView2 cleanupMarquee: YES];
	
	
	if (windowIsSplit) {
		windowIsSplit = NO;
		activeView = myPDFKitView;
		[(MyPDFKitView *)activeView resetSearchDelegate];
	}
	else {
		windowIsSplit = YES;
		activeView = myPDFKitView;
		}
	
	if (windowIsSplit) {
		theFrame = [myPDFKitView frame];
		newSize.width = theFrame.size.width;
		newSize.height = 100;
		[myPDFKitView setFrameSize:newSize];
		[myPDFKitView2 setFrameSize:newSize];
		[pdfKitSplitView addSubview: myPDFKitView2];
		[pdfKitSplitView adjustSubviews];
		if ([myPDFKitView2 document] == nil) {
			// [[myPDFKitView document] retain];
			[myPDFKitView2 setDocument:[myPDFKitView document]];
		}
	}
	else
		[myPDFKitView2 removeFromSuperview];
}

// Procedure called by menu item which splits both source and preview windows
- (void) splitWindow: (id)sender
{
	[self splitPdfKitWindow: sender];
}

- (void) fixAfterRotation: (BOOL) clockwise
{
	if (clockwise)
		[(MyPDFKitView *)myPDFKitView rotateClockwisePrimary];
	else
		[(MyPDFKitView *)myPDFKitView rotateCounterclockwisePrimary];
	[myPDFKitView layoutDocumentView];
	[myPDFKitView2 layoutDocumentView];
}

// Among other times, this is called by TSDocument at nib initialization time
- (void) setActiveView:(PDFView *)theView
{
	
	if (activeView) {
		[(MyPDFKitView *)activeView setDrawMark: NO];
		[activeView display];
		}
	activeView = theView;
}

- (PDFView *)activeView;
{
	if (activeView == nil)
		activeView = myPDFKitView;
	return activeView;
}

- (void) changeMouseMode: sender
{
	[(MyPDFKitView *)myPDFKitView changeMouseMode: sender];
	[(MyPDFKitView *)myPDFKitView2 changeMouseMode: sender];
}

- (void) doStepper: sender;
{
		[(MyPDFKitView *)activeView doStepper: sender]; 
}

- (void) changeScale: sender;
{
	[(MyPDFKitView *)activeView changeScale: sender]; 
}

- (void) goToKitPage: sender
{
	[(MyPDFKitView *)activeView goToKitPage: sender]; 
}

/*
- (void) doFind: sender
{
	[(MyPDFKitView *)activeView doFind: sender]; 
}
*/

- (IBAction) takeDestinationFromOutline: (id) sender
{
	[(MyPDFKitView *)activeView takeDestinationFromOutline: sender]; 
}
@end
