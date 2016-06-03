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

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	id		result;
	NSColor	*backColor;

	result = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];

	// backColor = [NSColor lightGrayColor];
	backColor = [NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha: 1.0];
	[self setBackgroundColor: backColor];

	CGFloat alpha = [SUD floatForKey: PreviewWindowAlphaKey];
	if (alpha < 0.999)
		[self setAlphaValue:alpha];

	self.activeView = nil;
	self.windowIsSplit = NO;
	self.willClose = NO;
	return result;
}


- (void)close
{
    TSDocument *theDocument = self.myDocument;
    
//	[self.myPDFKitView setDocument: nil];
//	[self.myPDFKitView2 setDocument: nil];
	self.willClose = YES;
 // self.myDocument = nil;
    if ([theDocument skipTextWindow]) {
        self.myDocument = nil;
        [theDocument close];
        }
    
	[super close];
}

- (void)resignMainWindow
{
    [(MyPDFKitView *)self.myPDFKitView cleanupMarquee: YES];
    [(MyPDFKitView *)self.myPDFKitView2 cleanupMarquee: YES];
    [super resignMainWindow];
}

/*
- (void) makeDefaultEditor:(id)sender
{
    [self.myDocument makeDefaultEditor:sender];
}
*/


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
   self.willClose = NO;
	if([self.myDocument fileURL] != nil ) [self setTitle:[[[self.myDocument fileTitleName] stringByDeletingPathExtension] stringByAppendingString: @".pdf"]]; // added by Terada
	[super becomeMainWindow];

	[self.myDocument fixMacroMenuForWindowChange];
}


- (void) doTextMagnify: sender
{
	id	thePanel;

	thePanel = [self.myDocument magnificationPanel];

	[NSApp beginSheet: thePanel
			modalForWindow: self
			modalDelegate: self
			didEndSelector: @selector(magnificationDidEnd:returnCode:contextInfo:)
			contextInfo: nil];
}

- (void)magnificationDidEnd:(NSWindow *)sheet returnCode: (NSInteger)returnCode contextInfo: (void *)contextInfo
{
	// [sheet close];
	[sheet orderOut: self];
}

- (void) doTextPage: sender      // for toolbar in text mode
{
	id	thePanel;

	thePanel = [self.myDocument pagenumberPanel];

	[NSApp beginSheet: thePanel
			modalForWindow: self
			modalDelegate: self
			didEndSelector:  @selector(pagenumberDidEnd:returnCode:contextInfo:)
			contextInfo: nil];
}

- (void)pagenumberDidEnd:(NSWindow *)sheet returnCode: (NSInteger)returnCode contextInfo: (void *)contextInfo
{
	// [sheet close];
	[sheet orderOut: self];
}

- (void) displayLog: sender
{
	[self.myDocument displayLog: sender];
}

- (void) displayConsole: sender
{
	[self.myDocument displayConsole: sender];
}

- (void) abort: sender
{
	[self.myDocument abort: sender];
}

- (void) trashAUXFiles: sender
{
	[self.myDocument trashAUXFiles: sender];
}

- (void) runPageLayout: sender
{
	[self.myDocument runPageLayout: sender];
}

- (void) printDocument: sender
{
	[self.myDocument printDocument: sender];
}

- (void) printSource: sender
{
	[self.myDocument printSource: sender];
}

- (void) doTypeset: sender
{
	[self.myDocument doTypeset: sender];
}

- (void) flipShowSync: sender
{
	[self.myDocument flipShowSync: sender];
}

- (void) doTex: sender
{
	[self.myDocument doTex: sender];
}

- (void) doLatex: sender
{
	[self.myDocument doLatex: sender];
}

- (void) doBibtex: sender
{
	[self.myDocument doBibtex: sender];
}

- (void) doIndex: sender
{
	[self.myDocument doIndex: sender];
}

- (void) doMetapost: sender
{
	[self.myDocument doMetapost: sender];
}

- (void) doContext: sender
{
	[self.myDocument doContext: sender];
}

- (void) doMetaFont: sender
{
	[self.myDocument doMetaFont: sender];
}

- (void) previousPage: sender
{
	if ([self.myDocument fromKit])
		[[self.myDocument pdfKitView] previousPage: sender];
	else
		[[self.myDocument pdfView] previousPage: sender];
}

- (void) nextPage: sender;
{	
	
	if ([self.myDocument fromKit])
		[[self.myDocument pdfKitView] nextPage: sender];
	else
		[[self.myDocument pdfView] nextPage: sender];
}


- (void) doChooseMethod: sender
{
	[self.myDocument doChooseMethod: sender];
}

- (void) doError: sender
{
	[self.myDocument doError: sender];
}

- (void) setProjectFile: sender
{
	[self.myDocument setProjectFile: sender];
}

- (void) rotateClockwise: sender
{
	if ([self.myDocument fromKit])
		[[self.myDocument pdfKitView] rotateClockwise: sender];
	else {
		[[self.myDocument pdfView] rotateClockwise: sender];
	}
}

- (void) rotateCounterclockwise: sender
{
	if ([self.myDocument fromKit])
		[[self.myDocument pdfKitView] rotateCounterclockwise: sender];
	else {
		[[self.myDocument pdfView] rotateCounterclockwise: sender];
	}
}

////////////////////// key movement ///////////////////////////////////

- (void) firstPage: sender;
{	if ([self.myDocument fromKit])
		[[self.myDocument pdfKitView] firstPage: sender];
	else
		[[self.myDocument pdfView] firstPage: sender];
}

- (void) lastPage: sender
{
	if ([self.myDocument fromKit])
		[[self.myDocument pdfKitView] lastPage: sender];
	else
		[[self.myDocument pdfView] lastPage: sender];
}

- (void) up: sender
{
	if (![self.myDocument fromKit]) {
		[[self.myDocument pdfView] up: sender];
	}
}

- (void) down: sender
{
	if (![self.myDocument fromKit]) {
		[[self.myDocument pdfView] down: sender];
	}
}

- (void) top: sender
{
	if (![self.myDocument fromKit]) {
		[[self.myDocument pdfView] top: sender];
	}
}

- (void) bottom: sender
{
	if (![self.myDocument fromKit]) {
		[[self.myDocument pdfView] bottom: sender];
	}
}

// mitsu 1.29 (O)
- (void) left: sender
{
	if (![self.myDocument fromKit]) {
		[[self.myDocument pdfView] left: sender];
	}
}

- (void) right: sender
{
	if (![self.myDocument fromKit]) {
		[[self.myDocument pdfView] right: sender];
	}
}

- (void)doMove: (id)sender
{
    [self.myDocument doMove:sender];
}


////////// end key movement /////////////////////////

- (void) orderOut:sender
{
	self.willClose = YES;
	if ([self.myDocument externalEditor]) {
		if (! [self.myDocument getWillClose]) {
			[self.myDocument setWillClose: YES];
			[self.myDocument close];
		}
	}
	else if (([self.myDocument documentType] != isTeX) && ([self.myDocument documentType] != isOther)) {
		if (! [self.myDocument getWillClose]) {
			[self.myDocument setWillClose: YES];
			[self.myDocument close];
		}		
	}
	else
		[super orderOut: sender];
}

- (void)associatedWindow:(id)sender
{
    if ([self.myDocument externalEditor])
        return;
 	if ([self.myDocument documentType] == isTeX) {
 		if ([self.myDocument getCallingWindow] == nil) {
            [[self.myDocument textWindow] makeKeyAndOrderFront: self];
            }
		else
			[[self.myDocument getCallingWindow] makeKeyAndOrderFront: self];

		}
}

- (void)sendEvent:(NSEvent *)theEvent
{
	 if (self.willClose) {
		[super sendEvent: theEvent];
		return;
	}
	
	if ([self.myDocument fromKit] && ([theEvent type] == NSKeyDown) && ([theEvent modifierFlags] & NSCommandKeyMask)) {
		if ([[theEvent characters] characterAtIndex:0] == '[') {
			// [[self.myDocument pdfKitView] goBack: self];
			[self.activeView zoomOut:nil];
			return;
		} 
		
		if ([[theEvent characters] characterAtIndex:0] == ']') {
			// [[self.myDocument pdfKitView] goForward: self];
			[self.activeView zoomIn:nil];
			return;
		} 
	
	}

	if (![self.myDocument fromKit]) {
		
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
			[[self.myDocument pdfView] flagsChanged: theEvent];
			return;
		}
		else if ([theEvent type] == NSLeftMouseDown) // mitsu 1.29 (O) resize PDF view
		{
			// check if mouse was in vertical scroller's knob
			MyPDFView *pdfView = [self.myDocument pdfView];
			NSScroller *scroller = [[pdfView enclosingScrollView] verticalScroller];
			if (([scroller testPart: [theEvent locationInWindow]] == NSScrollerKnob) &&
				([self.myDocument documentType] == isTeX || [self.myDocument documentType] == isPDF) &&
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
				[[self.myDocument pdfView] updateCurrentPage]; // draw page number

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
		if (self.windowIsSplit)
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
		return ((![self.myDocument externalEditor]) && ([self.myDocument documentType] == isTeX));

	if ([anItem action] == @selector(setProjectFile:))
		return ([self.myDocument documentType] == isTeX);

	if ([self.myDocument documentType] != isTeX) {
		if ([anItem action] == @selector(saveDocument:))
			return ([self.myDocument documentType] == isOther);
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
			return (([self.myDocument documentType] == isPDF) ||
					([self.myDocument documentType] == isJPG) ||
					([self.myDocument documentType] == isTIFF));
	}

#ifdef MITSU_PDF

		// mitsu 1.29 (O)
	if ([anItem action] == @selector(changePageStyle:)) {
		
		return (([self.myDocument documentType] == isTeX) || ([self.myDocument documentType] == isPDF));
	}

	if ([anItem action] == @selector(copy:) || [anItem action] == @selector(saveSelectionToFile:))
		return ([[self.myDocument pdfView] hasSelection]);
	// end mitsu 1.29 (O)

#endif

	return [super validateMenuItem: anItem];
}


- (TSDocument *)document
{
	return self.myDocument;
}

#ifdef MITSU_PDF


// mitsu 1.29 (O)
- (void)changePageStyle: (id)sender
{
	if ([self.myDocument fromKit])
		[[self.myDocument pdfKitView] changePageStyle: sender];
	else
		[[self.myDocument pdfView] changePageStyle: sender];
}

- (void)changePDFViewSize: (id)sender
{	if ([self.myDocument fromKit])
		[[self.myDocument pdfKitView] changePDFViewSize: sender];
	else
		[[self.myDocument pdfView] changePDFViewSize: sender];
}

- (void)zoomIn: (id)sender
{
	if ([self.myDocument fromKit])
		[[self.myDocument pdfKitView] zoomIn: sender];
}

- (void)zoomOut: (id)sender
{
	
	if ([self.myDocument fromKit])
		[[self.myDocument pdfKitView] zoomOut: sender];
}

- (void)fullscreen: (id)sender
{
	if ([self.myDocument fromKit])
		[self.myDocument fullscreen: sender];
}

- (void) savePreviewPosition: sender
{
	[self.myDocument savePreviewPosition];
}

- (void) savePortablePreviewPosition: sender
{
	[self.myDocument savePortablePreviewPosition];
}


- (void)copy: (id)sender
{
	if ([self.myDocument fromKit])
		[[self.myDocument pdfKitView] copy: sender];
	else
		[[self.myDocument pdfView] copy: sender];
}

-(void)saveSelectionToFile: (id)sender
{	if ([self.myDocument fromKit])
		[[self.myDocument pdfKitView] saveSelectionToFile: sender];
	else
		[[self.myDocument pdfView] saveSelectionToFile: sender];
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
    BOOL        result;
	
	[(MyPDFKitView *)self.myPDFKitView cleanupMarquee: YES];
	[(MyPDFKitView *)self.myPDFKitView2 cleanupMarquee: YES];
	
	
	if (self.windowIsSplit) {
		self.windowIsSplit = NO;
		self.activeView = self.myPDFKitView;
        result = [self.activeView becomeFirstResponder];
		[(MyPDFKitView *)self.activeView resetSearchDelegate];
	}
	else {
		self.windowIsSplit = YES;
		self.activeView = self.myPDFKitView;
		}
	
	if (self.windowIsSplit) {
		theFrame = [self.myPDFKitView frame];
		newSize.width = theFrame.size.width;
		newSize.height = 100;
		[self.myPDFKitView setFrameSize:newSize];
		[self.myPDFKitView2 setFrameSize:newSize];
		[self.pdfKitSplitView addSubview: self.myPDFKitView2];
		[self.pdfKitSplitView adjustSubviews];
        
        [(MyPDFKitView *)self.myPDFKitView2 setPageStyle:[(MyPDFKitView *)self.myPDFKitView pageStyle]];
        [(MyPDFKitView *)self.myPDFKitView2 setFirstPageStyle:[(MyPDFKitView *)self.myPDFKitView firstPageStyle]];
        if ( [(MyPDFKitView *)self.myPDFKitView resizeOption] == NEW_PDF_FIT_TO_NONE)
          [(MyPDFKitView *)self.myPDFKitView2 setMagnification: [(MyPDFKitView *)self.myPDFKitView magnification]];
        else {
            [(MyPDFKitView *)self.myPDFKitView2 setResizeOption:[(MyPDFKitView *)self.myPDFKitView resizeOption]];
            [(MyPDFKitView *)self.myPDFKitView2 setupMagnificationStyle];
            }
        [(MyPDFKitView *)self.myPDFKitView2 setupPageStyle];
       //  [(MyPDFKitView *)self.myPDFKitView2 setupMagnificationStyle];

		if ([self.myPDFKitView2 document] == nil) {
			// [[self.myPDFKitView document] retain];
			[self.myPDFKitView2 setDocument:[self.myPDFKitView document]];
           		}
        [(MyPDFKitView *)self.myPDFKitView2 moveSplitToCorrectSpot:[(MyPDFKitView *)self.myPDFKitView index]];
	}
	else
    {
		[self.myPDFKitView2 removeFromSuperview];
        theFrame = [self.myPDFKitView frame];
        newSize.width = theFrame.size.width;
        newSize.height = self.frame.size.height;
        [self.myPDFKitView setFrameSize:newSize];
    }
}

// Procedure called by menu item which splits both source and preview windows
- (void) splitWindow: (id)sender
{
	[self splitPdfKitWindow: sender];
}

- (void) fixAfterRotation: (BOOL) clockwise
{
	if (clockwise)
		[(MyPDFKitView *)self.myPDFKitView rotateClockwisePrimary];
	else
		[(MyPDFKitView *)self.myPDFKitView rotateCounterclockwisePrimary];
	[self.myPDFKitView layoutDocumentView];
	[self.myPDFKitView2 layoutDocumentView];
}

// Among other times, this is called by TSDocument at nib initialization time
/*
- (void) setActiveView:(PDFView *)theView
{
	
	if (self.activeView) {
		[(MyPDFKitView *)self.activeView setDrawMark: NO];
		[self.activeView display];
		}
	self.activeView = theView;
}

- (PDFView *)activeView;
{
	if (activeView == nil)
		activeView = myPDFKitView;
	return activeView;
}
*/

- (void) changeMouseMode: sender
{
	[(MyPDFKitView *)self.myPDFKitView changeMouseMode: sender];
	[(MyPDFKitView *)self.myPDFKitView2 changeMouseMode: sender];
}

- (void) doStepper: sender;
{
		[(MyPDFKitView *)self.activeView doStepper: sender];
}

- (void) changeScale: sender;
{
	[(MyPDFKitView *)self.activeView changeScale: sender];
}

- (void) goToKitPage: sender
{
	[(MyPDFKitView *)self.activeView goToKitPage: sender];
}

/*
- (void) doFind: sender
{
	[(MyPDFKitView *)self.activeView doFind: sender];
}
*/

- (IBAction) takeDestinationFromOutline: (id) sender
{
	[(MyPDFKitView *)self.activeView takeDestinationFromOutline: sender];
}

- (IBAction)convertTiff:(id)sender
{
    [(TSDocument *)self.myDocument convertTiff:sender];
}

/*
- (BOOL)windowIsSplit
{
    return self.windowIsSplit;
}
*/

@end
