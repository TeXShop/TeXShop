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

#define ADJUST 7
#define ADJUST1 47

extern NSPanel *pageNumberWindow;


@implementation TSPreviewWindow


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	id		result;
	NSColor	*backColor;
    
 	result = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];
    
    self.firstTime = YES;

	// backColor = [NSColor lightGrayColor];
	backColor = [NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha: 1.0];
	[self setBackgroundColor: backColor];

	CGFloat alpha = [SUD floatForKey: PreviewWindowAlphaKey];
	if (alpha < 0.999)
		[self setAlphaValue:alpha];

	self.activeView = nil;
	self.windowIsSplit = NO;
	self.willClose = NO;
    self.horizontal = YES;
    self.oldUnsplitAfterSwitch = NO;
    
    
	return result;
}


- (void)close
{
    TSDocument *theDocument = self.myDocument;
    
//	[self.myPDFKitView setDocument: nil];
//	[self.myPDFKitView2 setDocument: nil];
	self.willClose = YES;
    self.previewClosed = YES;
 // self.myDocument = nil;
    if ([theDocument skipTextWindow]) {
        self.myDocument = nil;
        [theDocument close];
        }
    
 //   self.myPDFKitView = nil;
 //   self.myPDFKitView2 = nil;
 //   self.activeView = nil;
    
	[super close];
}

- (void)resignMainWindow
{
    [(MyPDFKitView *)self.myPDFKitView cleanupMarquee: YES];
    [(MyPDFKitView *)self.myPDFKitView2 cleanupMarquee: YES];
    [super resignMainWindow];
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
   self.willClose = NO;
	if([self.myDocument fileURL] != nil ) [self setTitle:[[[self.myDocument fileTitleName] stringByDeletingPathExtension] stringByAppendingString: @".pdf"]]; // added by Terada
	[super becomeMainWindow];

	[self.myDocument fixMacroMenuForWindowChange];
}


- (void) doTextMagnify: sender
{
    [self.myDocument doTextMagnify: sender];
}

- (void) doTextPage: sender
{
    [self.myDocument doTextPage: sender];
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

- (void) toggleSyntaxColor: (id)sender
{
    [self.myDocument toggleSyntaxColor: sender];
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

- (void) doAlternateTypeset: sender
{
    [self.myDocument doAlternateTypeset: sender];
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

/*
- (void) doContext: sender
{
	[self.myDocument doContext: sender];
}
*/

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
	
	if ([self.myDocument fromKit] && ([theEvent type] == NSEventTypeKeyDown) && ([theEvent modifierFlags] & NSCommandKeyMask)) {
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
  
    
#ifdef IMMEDIATEMAGNIFY
  if (([self.myDocument fromKit]) && ([theEvent type] == NSEventTypeLeftMouseDown) && ([[self.myDocument pdfKitView] toolIsMagnification]))
  {
      NSUInteger modifiers = NSEvent.modifierFlags;
      NSUInteger modifiersPressed = modifiers & (NSEventModifierFlagControl | NSEventModifierFlagCommand | NSEventModifierFlagOption);
      if (! modifiersPressed)
      {
          NSPoint thePoint = [theEvent locationInWindow];
          NSPoint aPoint = [[self.myDocument pdfKitView] convertPoint:thePoint fromView:nil];
          NSView *aView = [self.myDocument pdfKitView];
          NSRect Inside = aView.bounds;
          Inside = NSInsetRect(Inside, 15, 15);
          BOOL inPDF = [aView mouse: aPoint inRect: Inside];
          if (inPDF)
          {
              if ([self isMainWindow])
              {
                  [[self.myDocument pdfKitView] fancyMouseDown: theEvent];
                  // [super sendEvent: theEvent]; this call kills scrolling by trackpad in the pdf window
                  return;
              }
          }
      }
   }
#endif
 
	if (![self.myDocument fromKit]) {
		
		unichar	theChar;

		if ([theEvent type] == NSEventTypeKeyDown) {

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

		else if ([theEvent type] == NSEventTypeFlagsChanged) // mitsu 1.29 (S2)
		{
			[[self.myDocument pdfView] flagsChanged: theEvent];
			return;
		}
		else if ([theEvent type] == NSEventTypeLeftMouseDown) // mitsu 1.29 (O) resize PDF view
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
				aRect = [self convertRectToScreen: aRect];
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
    
    if ([anItem action] == @selector(toggleLinkPopups:)) {
        MyPDFKitView *aView;
        aView = (MyPDFKitView *)self.myPDFKitView;
        
        if (aView.skipLinks)
            [anItem setState:NSOffState];
        else
            [anItem setState:NSOnState];
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


- (void) saveHTMLPosition: sender
{
    [self.myDocument saveHTMLPosition: sender];
}

- (void) showHTMLWindow: sender
{
    [self.myDocument showHTMLWindow: sender];
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

/*
 - (void)moveSplitToCorrectSpot:(NSInteger)index;
 {
     PDFPage        *aPage;
     
     aPage = [[self document] pageAtIndex: index];
     [self goToPage: aPage];
     
 }

 */


- (void)switchViews;

{
    NSInteger       index1, index2;
    NSInteger       pageIndex1, pageIndex2;
    NSRect          visibleRect1, visibleRect2;
    NSRect          splitFullRect1, splitFullRect2;
    
    MyPDFKitView    *aView, *aView2;
    NSRect          newFullRect, newSplitFullRect, newVisibleRect;
    NSInteger       difference;
    
    
/*
    aView = (MyPDFKitView *)self.myPDFKitView;
    index1 = [aView index];
    visibleRect1 = [[aView documentView] visibleRect];
    splitFullRect1 = [[aView documentView] bounds];

    aView = (MyPDFKitView *)self.myPDFKitView2;
    index2 = [aView index];
    visibleRect2 = [[aView documentView] visibleRect];
    splitFullRect2 = [[aView documentView] bounds];
 */

    if (self.windowIsSplit) {
        
          self.oldUnsplitAfterSwitch = YES;
        
          aView = (MyPDFKitView *)self.myPDFKitView;
          index1 = [aView index];
          visibleRect1 = [[aView documentView] visibleRect];
          splitFullRect1 = [[aView documentView] bounds];

          aView = (MyPDFKitView *)self.myPDFKitView2;
          index2 = [aView index];
          visibleRect2 = [[aView documentView] visibleRect];
          splitFullRect2 = [[aView documentView] bounds];
          
          aView =(MyPDFKitView *)self.myPDFKitView;
          [aView moveSplitToCorrectSpot: index2];
          newFullRect = [[aView documentView] bounds];
          newSplitFullRect = splitFullRect2;
          newVisibleRect = visibleRect2;
          difference = newFullRect.size.height - newSplitFullRect.size.height;
          newVisibleRect.origin.y = newVisibleRect.origin.y + difference - 1;
          [[aView documentView] scrollRectToVisible: newVisibleRect];
          
        
          
          aView =(MyPDFKitView *)self.myPDFKitView2;
          [aView moveSplitToCorrectSpot: index1];
          newFullRect = [[aView documentView] bounds];
          newSplitFullRect = splitFullRect1;
          newVisibleRect = visibleRect1;
          difference = newFullRect.size.height - newSplitFullRect.size.height;
          newVisibleRect.origin.y = newVisibleRect.origin.y + difference - 1;
          [[aView documentView] scrollRectToVisible: newVisibleRect];
        
      }
   
    else {
        /*
         [self mainSplitPdfKitWindow];
         [self switchViews];
         [self mainSplitPdfKitWindow];
       */
        
        aView = (MyPDFKitView *)self.myPDFKitView;
        pageIndex1 = [[aView document] indexForPage:[aView currentPage]];
        visibleRect1 = [[[aView documentView] enclosingScrollView] documentVisibleRect];
        
        if (aView.oldUsed)
        {
            [aView goToPage: [[aView document] pageAtIndex: aView.oldIndex]];
            if (aView.doScroll)
                [[aView documentView] scrollRectToVisible: aView.oldVisibleRect];
            //else
               // NSLog(@"Did Not Scroll");
            aView.doScroll = YES;
            aView.oldIndex = pageIndex1;
            aView.oldVisibleRect = visibleRect1;
        }
        else
        {
            aView.oldUsed = YES;
            aView.oldIndex = pageIndex1;
            aView.oldVisibleRect = visibleRect1;
        }
        
         
     }
        
 }

- (void)switchSplitViews: (id)sender
{
    [self switchViews];
}

- (void)toggleLinkPopups:(id)sender;
{
    MyPDFKitView    *aView, *aView2;
    
    aView = (MyPDFKitView *)self.myPDFKitView;
    aView2 = (MyPDFKitView *)self.myPDFKitView2;
    [aView changeLinkPopups];
    [aView2 changeLinkPopups];
}

/*

- (void) mainSplitPdfKitWindow
{
    NSSize        theSize, newSize1, newSize2;
    NSRect        theFrame, theFrame1, theFrame2;
    NSRect      myVisibleRect;
    double      myScrollAmount;
    double      mag, magnification;
    BOOL        result;
    double      temp1, temp2, myHeight, myHeight1;
    MyPDFKitView    *aView;
    
// Fix encrypted pdf bug
    MyPDFKitView *firstView;
    MyPDFKitView *secondView;
    
    firstView = (MyPDFKitView *)self.myPDFKitView;
    secondView = (MyPDFKitView *)self.myPDFKitView2;
    
    if (self.firstTime)
    {
        self.firstTime = NO;
        [firstView removeConstraints: firstView.constraints];
        [secondView removeConstraints: secondView.constraints];
    }
// end of fix
    
// "saveLocation" below saves index, documentview's visualRect, and documentview's bounds
 
    if (self.windowIsSplit)
        {
            [(MyPDFKitView *)self.myPDFKitView saveLocation];
            [(MyPDFKitView *)self.myPDFKitView2 saveLocation];
            ((MyPDFKitView *)self.myPDFKitView).locationSaved = YES;
            ((MyPDFKitView *)self.myPDFKitView2).locationSaved = YES;
        }
    else {
        [(MyPDFKitView *)self.myPDFKitView saveLocation];
    }
    
    
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
        newSize1.width = theFrame.size.width;
        newSize1.height = 100;
        newSize2 = newSize1;
        if ((self.horizontal) && ((MyPDFKitView *)self.myPDFKitView2).horizontalSplitSaved)
                {
                    newSize1.height = ((MyPDFKitView *)self.myPDFKitView2).horizontalHeight1;
                    newSize2.height = ((MyPDFKitView *)self.myPDFKitView2).horizontalHeight2;
                }
        if ((! self.horizontal) && ((MyPDFKitView *)self.myPDFKitView2).verticalSplitSaved)
                {
                    newSize1.width = ((MyPDFKitView *)self.myPDFKitView2).verticalWidth1;
                    newSize2.width = ((MyPDFKitView *)self.myPDFKitView2).verticalWidth2;
                }
        [self.myPDFKitView setFrameSize:newSize1];
        [self.myPDFKitView2 setFrameSize:newSize2];
        
        
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
        
        if (self.horizontal)
            {
                theFrame1 = [self.myPDFKitView frame];
                theFrame2 = [self.myPDFKitView2 frame];
                // tempBounds = [self.myPDFKitView2 bounds];
                temp1 = theFrame1.size.height;
                temp2 = theFrame2.size.height;
                ((MyPDFKitView *)self.myPDFKitView2).horizontalSplitSaved = YES;
                ((MyPDFKitView *)self.myPDFKitView2).horizontalHeight1 = temp1;
               // ((MyPDFKitView *)self.myPDFKitView2).horizontalHeight2 = temp2;
                ((MyPDFKitView *)self.myPDFKitView2).horizontalHeight2 = temp2;
                // [((MyPDFKitView *)self.myPDFKitView2) documentView].bounds = tempBounds;
                
                // theScale = ((MyPDFKitView *)self.myPDFKitView2).scaleFactor;
                // ((MyPDFKitView *)self.myPDFKitView2).scale = theScale;
            }
        else
            {
                theFrame1 = [self.myPDFKitView frame];
                theFrame2 = [self.myPDFKitView2 frame];
                // tempBounds = [self.myPDFKitView2 bounds];
                temp1 = theFrame1.size.width;
                temp2 = theFrame2.size.width;
                ((MyPDFKitView *)self.myPDFKitView2).verticalSplitSaved = YES;
                ((MyPDFKitView *)self.myPDFKitView2).verticalWidth1 = temp1;
                ((MyPDFKitView *)self.myPDFKitView2).verticalWidth2 = temp2;
             }
        [self.myPDFKitView2 removeFromSuperview];
        theFrame = [self.myPDFKitView frame];
        theSize.width = theFrame.size.width;
        theSize.height = self.frame.size.height;
        [self.myPDFKitView setFrameSize:theSize];
    }
    
  
    
    if (self.windowIsSplit)
        {
            if (self.horizontal)
            {
 
            myVisibleRect = ((MyPDFKitView *)self.myPDFKitView).documentView.visibleRect;
            myHeight = ((MyPDFKitView *)self.myPDFKitView2).documentView.visibleRect.size.height;
            myHeight1 = self.pdfKitSplitView.dividerThickness;
            myScrollAmount = myHeight + myHeight1 - 2;
         
            
            myVisibleRect.origin.y = myVisibleRect.origin.y + myScrollAmount;
            [[((MyPDFKitView *)self.myPDFKitView) documentView] scrollRectToVisible: myVisibleRect];
            }
            else
                [(MyPDFKitView *)self.myPDFKitView restoreLocation];
            
            if (((MyPDFKitView *)self.myPDFKitView2).locationSaved)
                [(MyPDFKitView *)self.myPDFKitView2 restoreLocation];
        }
    else
    {
        if (self.horizontal)
        {
            //    [(MyPDFKitView *)self.myPDFKitView restoreLocation];
        
        myVisibleRect = ((MyPDFKitView *)self.myPDFKitView).documentView.visibleRect;
            
            
        myHeight = ((MyPDFKitView *)self.myPDFKitView2).documentView.visibleRect.size.height;
        
        
  //      NSRect myHeightV = ((MyPDFKitView *)self.myPDFKitView2).documentView.visibleRect;
 //      double myScaleFactor = ((MyPDFKitView *)self.myPDFKitView2).scaleFactor;
 //      double scaleFactorLower = myScaleFactor;
 //      NSLog(@"height of lower half %f", myHeightV.size.height);
 //      NSLog(@"scalefactor of lower half %f", myScaleFactor);
            
 //       myHeightV = ((MyPDFKitView *)self.myPDFKitView).documentView.visibleRect;
 //       myScaleFactor = ((MyPDFKitView *)self.myPDFKitView).scaleFactor;
 //       NSLog(@"height of upper half %f", myHeightV.size.height);
 //       NSLog(@"scalefactor of upper half %f", myScaleFactor);
            
       // NSRect visibleRectInWindow = [self convertRect:myHeightV toView:nil];
        
            
        myHeight1 = self.pdfKitSplitView.dividerThickness;
             
        myScrollAmount = myHeight + myHeight1 + 35;
           
        // myScrollAmount = myHeight * scaleFactorLower + myHeight1;
            
         myVisibleRect.origin.y = myVisibleRect.origin.y - myScrollAmount;
        [[((MyPDFKitView *)self.myPDFKitView) documentView] scrollRectToVisible: myVisibleRect];
        }
        else
            
            [(MyPDFKitView *)self.myPDFKitView restoreLocation];
        
    }
    
}

*/

- (void) mainSplitPdfKitWindow
{
    NSSize        theSize, newSize1, newSize2;
    NSRect        theFrame, theFrame1, theFrame2;
    NSRect      myVisibleRect;
    double      myScrollAmount;
    double      mag, magnification;
    BOOL        result;
    double      temp1, temp2, myHeight, myHeight1;
    MyPDFKitView    *aView;
    BOOL        splitInMiddle;
    BOOL        topToBottom;
    
    splitInMiddle = NO;
    topToBottom = NO;
    if (([NSEvent modifierFlags ] & NSEventModifierFlagShift) && ([NSEvent modifierFlags ] & NSEventModifierFlagControl))
    {
        splitInMiddle = YES;
        self.oldUnsplitAfterSwitch = YES;
    }
    
    else if ([NSEvent modifierFlags ] & NSEventModifierFlagShift)
    {
        topToBottom = YES;
        splitInMiddle = YES;
        self.oldUnsplitAfterSwitch = YES;
    }
    
//    else if ([NSEvent modifierFlags ] & NSEventModifierFlagNumericPad)
//    {
//        topToBottom = YES;
//        splitInMiddle = YES;
//        self.oldUnsplitAfterSwitch = NO;
//     }
    
// FIX ENCRYPTED PDF BUG
    
    MyPDFKitView *firstView;
    MyPDFKitView *secondView;
    
    firstView = (MyPDFKitView *)self.myPDFKitView;
    secondView = (MyPDFKitView *)self.myPDFKitView2;
    
    if (splitInMiddle)
    {
        [firstView autoScales];
        [secondView autoScales];
    }
    
    if (self.firstTime)
    {
        self.firstTime = NO;
        [firstView removeConstraints: firstView.constraints];
        [secondView removeConstraints: secondView.constraints];
    }
    
// END OF ENCRYPTED PDF BUG FIX
    
    // "saveLocation" below saves index, documentview's visualRect, and documentview's bounds
    
// SAVE CURRENT LOCATIONS FOR LATER RESTORE
    
    if (self.windowIsSplit)
        {
           
            [(MyPDFKitView *)self.myPDFKitView saveLocation];
            [(MyPDFKitView *)self.myPDFKitView2 saveLocation];
            ((MyPDFKitView *)self.myPDFKitView).locationSaved = YES;
            ((MyPDFKitView *)self.myPDFKitView2).locationSaved = YES;
        }
    else {
        [(MyPDFKitView *)self.myPDFKitView saveLocation];
        [(MyPDFKitView *)self.myPDFKitView saveLocationLimited];
    }
    
    
// REVISE self.windowIsSplit FOR SPLITING, BUT DO NOT YET SPLIT
    
    
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
    
// ACTUALLY SPLIT OR UNSPLIT THE WINDOW
    

    if (self.windowIsSplit) {  // THIS SPLITS THE WINDOW
        
        // FORCE SPLIT BAR TO THE MIDDLE OF THE WINDOW
        
        theFrame = [self.myPDFKitView frame];
        newSize1.width = theFrame.size.width;
        newSize1.height = 100;
        newSize2 = newSize1;
        if ((self.horizontal) && (! splitInMiddle) && ((MyPDFKitView *)self.myPDFKitView2).horizontalSplitSaved)
                {
                    newSize1.height = ((MyPDFKitView *)self.myPDFKitView2).horizontalHeight1;
                    newSize2.height = ((MyPDFKitView *)self.myPDFKitView2).horizontalHeight2;
                }
        if ((! self.horizontal) && ((MyPDFKitView *)self.myPDFKitView2).verticalSplitSaved)
                {
                    newSize1.width = ((MyPDFKitView *)self.myPDFKitView2).verticalWidth1;
                    newSize2.width = ((MyPDFKitView *)self.myPDFKitView2).verticalWidth2;
                }
        [self.myPDFKitView setFrameSize:newSize1];
        [self.myPDFKitView2 setFrameSize:newSize2];
        
        // DO SPLIT
        
        [self.pdfKitSplitView addSubview: self.myPDFKitView2];
         [self.pdfKitSplitView adjustSubviews];
        [(MyPDFKitView *)self.myPDFKitView restoreLocationLimited];
        
        // ADJUST DISPLAY PARAMETERS
        
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

        if ([self.myPDFKitView2 document] == nil)
             [self.myPDFKitView2 setDocument:[self.myPDFKitView document]];
                   
        [(MyPDFKitView *)self.myPDFKitView2 moveSplitToCorrectSpot:[(MyPDFKitView *)self.myPDFKitView index]];
    }

    else
    { //THIS UNSPLITS THE WINDOW
        
        if (self.horizontal)
            {
                theFrame1 = [self.myPDFKitView frame];
                theFrame2 = [self.myPDFKitView2 frame];
                // tempBounds = [self.myPDFKitView2 bounds];
                temp1 = theFrame1.size.height;
                temp2 = theFrame2.size.height;
                ((MyPDFKitView *)self.myPDFKitView2).horizontalSplitSaved = YES;
                ((MyPDFKitView *)self.myPDFKitView2).horizontalHeight1 = temp1;
               // ((MyPDFKitView *)self.myPDFKitView2).horizontalHeight2 = temp2;
                ((MyPDFKitView *)self.myPDFKitView2).horizontalHeight2 = temp2;
                // [((MyPDFKitView *)self.myPDFKitView2) documentView].bounds = tempBounds;
                
                // theScale = ((MyPDFKitView *)self.myPDFKitView2).scaleFactor;
                // ((MyPDFKitView *)self.myPDFKitView2).scale = theScale;
            }
        else
            {
                theFrame1 = [self.myPDFKitView frame];
                theFrame2 = [self.myPDFKitView2 frame];
                // tempBounds = [self.myPDFKitView2 bounds];
                temp1 = theFrame1.size.width;
                temp2 = theFrame2.size.width;
                ((MyPDFKitView *)self.myPDFKitView2).verticalSplitSaved = YES;
                ((MyPDFKitView *)self.myPDFKitView2).verticalWidth1 = temp1;
                ((MyPDFKitView *)self.myPDFKitView2).verticalWidth2 = temp2;
             }
        [self.myPDFKitView2 removeFromSuperview];
        theFrame = [self.myPDFKitView frame];
        theSize.width = theFrame.size.width;
        theSize.height = self.frame.size.height;
        [self.myPDFKitView setFrameSize:theSize];
    }
  
 // ADJUST SCROLLING OF SPLIT OR UNSPLIT WINDOW
    
    if (self.windowIsSplit)
        {  // THIS ADJUSTS SCROLLING OF THE SPLIT WINDOW
            if (self.horizontal)
            {
 
            myVisibleRect = ((MyPDFKitView *)self.myPDFKitView).documentView.visibleRect;
            myHeight = ((MyPDFKitView *)self.myPDFKitView2).documentView.visibleRect.size.height;
            myHeight1 = self.pdfKitSplitView.dividerThickness;
            myScrollAmount = myHeight + myHeight1 - 2;
         
            
            myVisibleRect.origin.y = myVisibleRect.origin.y + myScrollAmount;
            [[((MyPDFKitView *)self.myPDFKitView) documentView] scrollRectToVisible: myVisibleRect];
            }
            else

                ; // [(MyPDFKitView *)self.myPDFKitView restoreLocation];  // commenting out this line restores correct unsplit location
            
            if (((MyPDFKitView *)self.myPDFKitView2).locationSaved)
                [(MyPDFKitView *)self.myPDFKitView2 restoreLocation];
            
            if (topToBottom)
                [[((MyPDFKitView *)self.myPDFKitView2) documentView] scrollRectToVisible: myVisibleRect];
            
            
        }
    else
    { // THIS ADJUSTS SCROLLING OF THE UNSPLIT WINDOW
        if ((self.horizontal) && ( ! self.oldUnsplitAfterSwitch))
        {
            aView = (MyPDFKitView *)self.myPDFKitView;
            
            PDFPage *firstPage = [aView.document pageAtIndex:0];
            CGRect firstPageBounds = [firstPage boundsForBox:aView.displayBox];
            [aView goToRect:CGRectMake(0, firstPageBounds.size.height, 1, 1) onPage:firstPage];
             
            [(MyPDFKitView *)self.myPDFKitView restoreLocationLimited];
        }
        else if (! self.horizontal)
            
        {
            self.oldUnsplitAfterSwitch = NO;
            [(MyPDFKitView *)self.myPDFKitView restoreLocation];
        }
        
        else
        {
            self.oldUnsplitAfterSwitch = NO;
            
            myVisibleRect = ((MyPDFKitView *)self.myPDFKitView).documentView.visibleRect;
            
            
            myHeight = ((MyPDFKitView *)self.myPDFKitView2).documentView.visibleRect.size.height;
            
            
            // NSRect myHeightV = ((MyPDFKitView *)self.myPDFKitView2).documentView.visibleRect;
            // double myScaleFactor = ((MyPDFKitView *)self.myPDFKitView2).scaleFactor;
            // double scaleFactorLower = myScaleFactor;
            // NSLog(@"height of lower half %f", myHeightV.size.height);
            // NSLog(@"scalefactor of lower half %f", myScaleFactor);
            
            // myHeightV = ((MyPDFKitView *)self.myPDFKitView).documentView.visibleRect;
            // myScaleFactor = ((MyPDFKitView *)self.myPDFKitView).scaleFactor;
            // NSLog(@"height of upper half %f", myHeightV.size.height);
            // NSLog(@"scalefactor of upper half %f", myScaleFactor);
            
            // NSRect visibleRectInWindow = [self convertRect:myHeightV toView:nil];
            
            
            myHeight1 = self.pdfKitSplitView.dividerThickness;
            
            myScrollAmount = myHeight + myHeight1 + 35;
            
            // myScrollAmount = myHeight * scaleFactorLower + myHeight1;
            
            myVisibleRect.origin.y = myVisibleRect.origin.y - myScrollAmount;
            [[((MyPDFKitView *)self.myPDFKitView) documentView] scrollRectToVisible: myVisibleRect];
            
        }
    }
}





- (void) splitPdfKitWindow: (id)sender
{

if (! self.windowIsSplit)
        {
            if ([NSEvent modifierFlags ] & NSEventModifierFlagOption)
                {
                    [self.pdfKitSplitView setVertical:YES];
                    self.horizontal = NO;
                }
            else
                {
                    [self.pdfKitSplitView setVertical: NO];
                    self.horizontal = YES;
                }
        }
  
    [self mainSplitPdfKitWindow];

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


- (void) doFind: sender
{
  //  [self makeFirstResponder: [self.myDocument pdfKitSearchField]];
}


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
