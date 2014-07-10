/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2005 Richard
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
 * $Id: MyPDFKitView.m 261 2007-08-09 20:10:11Z richard_koch $
 *
 * Parts of this code are taken from Apple's example PDFKitViewer.
 *
 */
 
 // WARNING --------------------------------------------
 // In Leopard, particularly when using the new Image Resolution ability, 
 // NSWindow's cacheImageInRect, restoreCachedImage, and discardCachedImage
 // do not work. Engineers at WWDC recommended better methods of rubber banding.
 // 
 // The code below is messy because the old cacheImage mechanism is present but
 // commented out. It has been replaced by equivalent methods which work on Leopard
 // and also on older operating systems.
 // Eventually I'll clean up these routines, but for the moment I thought it
 // best to leave the old code in place
 // -----------------------------------------------------

 // See comments below for further changes required by Mavericks. Koch.

// // QUESTIONABLE_BUG_FIX  (Search for this)

#import "MyPDFKitView.h"
#import "MyPDFView.h"
#import "globals.h"
#import "TSDocument.h"
#import "TSEncodingSupport.h"
#import "MyDragView.h"
#import "TSPreviewWindow.h"

#define NUMBER_OF_SOURCE_FILES	60



@implementation MyPDFKitView : PDFView

- (void) dealloc
{
	
	[self cleanupMarquee: YES];
	
	// No more notifications.
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	// Clean up.
/*
	if (self.searchResults != NULL) {
		[self.searchResults removeAllObjects];
		[self.searchResults release];
		self.searchResults = NULL;
	}
	[self.sourceFiles release];


	[super dealloc];
 */
}

- (id)init
{
	// WARNING: This may never be called. (??)	
	if ((self = [super init])) {
		protectFind = NO;
		}
     return self;
}

/*
- (BOOL)wantsScrollEventsForSwipeTrackingOnAxis:(NSEventGestureAxis)axis
{ 
    return YES;
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    NSLog(@"scrollWheel Called");
    [super scrollWheel:theEvent];
}
*/


/*
- (void)scheduleAddingToolips
{
}
*/

- (void)setScaleFactor:(CGFloat)scale
{
    [super setScaleFactor: scale];
    resizeOption =  NEW_PDF_FIT_TO_NONE;
}


- (NSInteger)pageStyle
{
    return pageStyle;
}

- (NSInteger)firstPageStyle
{
    return firstPageStyle;
}

- (NSInteger)resizeOption
{
    return resizeOption;
}

- (void)setPageStyle: (NSInteger)thePageStyle
{
    pageStyle = thePageStyle;
}

- (void)setFirstPageStyle: (NSInteger)theFirstPageStyle;
{
    firstPageStyle = theFirstPageStyle;
}

- (void)setResizeOption: (NSInteger)theResizeOption
{
    resizeOption = theResizeOption;
}




- (void) initializeDisplay
{
    

    [self.myPDFWindow setDelegate: self];
    
	downOverLink = NO;
	
	drawMark = NO;
	showSync = NO;
	if ([SUD boolForKey:ShowSyncMarksKey])
		showSync = YES;
	pageStyle = [SUD integerForKey: PdfPageStyleKey];
	firstPageStyle = [SUD integerForKey: PdfFirstPageStyleKey];
	resizeOption = [SUD integerForKey: PdfKitFitSizeKey];
	if ((resizeOption == NEW_PDF_FIT_TO_WIDTH) || (resizeOption == NEW_PDF_FIT_TO_HEIGHT))
		resizeOption = PDF_FIT_TO_WINDOW;


	// Display mode
	[self setupPageStyle];

	// Size Option
	[self setupMagnificationStyle];
	
	/*
	backColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:PdfPageBack_RKey]
		green: [SUD floatForKey:PdfPageBack_GKey] blue: [SUD floatForKey:PdfPageBack_BKey]
		alpha: 1];
	*/


}

- (void) setupPageStyle
{
    
	switch (pageStyle) {
		case PDF_SINGLE_PAGE_STYLE:			[self setDisplayMode: kPDFDisplaySinglePage];
											[self setDisplaysPageBreaks: NO];
											break;

		case PDF_TWO_PAGE_STYLE:			[self setDisplayMode: kPDFDisplayTwoUp];
											[self setDisplaysPageBreaks: YES];
											switch (firstPageStyle) {
												case PDF_FIRST_LEFT:	[self setDisplaysAsBook: NO];
																		break;

												case PDF_FIRST_RIGHT:	[self setDisplaysAsBook: YES];
																		break;
												}
											break;

		case PDF_MULTI_PAGE_STYLE:			[self setDisplayMode: kPDFDisplaySinglePageContinuous];
											[self setDisplaysPageBreaks: YES];
											break;

		case PDF_DOUBLE_MULTI_PAGE_STYLE:	[self setDisplayMode: kPDFDisplayTwoUpContinuous];
											[self setDisplaysPageBreaks: YES];
											switch (firstPageStyle) {
												case PDF_FIRST_LEFT:	[self setDisplaysAsBook: NO];
																		break;

												case PDF_FIRST_RIGHT:	[self setDisplaysAsBook: YES];
																		break;
												}
											break;

		}
}

- (void) setupMagnificationStyle
{
	double	theMagnification;
	NSInteger		mag;
	
		switch (resizeOption) {

		case NEW_PDF_ACTUAL_SIZE:	theMagnification = 1.0;
									mag = round(theMagnification * 100.0);
									[myStepper setIntegerValue:mag];
									[myStepper1 setIntegerValue:mag];
									[self setScaleFactor: theMagnification];
									break;

		case NEW_PDF_FIT_TO_NONE:	theMagnification = [SUD floatForKey:PdfMagnificationKey];
									mag = round(theMagnification * 100.0);
									[myStepper setIntegerValue:mag];
									[myStepper1 setIntegerValue:mag];
									[self setScaleFactor: theMagnification];
									break;


		case NEW_PDF_FIT_TO_WIDTH:
		case NEW_PDF_FIT_TO_HEIGHT:
		case NEW_PDF_FIT_TO_WINDOW:	[self setAutoScales: YES];
									break;

		}
}

- (void) setupOutline
{
	if (![SUD boolForKey: UseOutlineKey])
		return;

//	if (_outline)
//		[_outline release];
//	_outline = NULL;
	self.outline = [[self document] outlineRoot];
	if (self.outline)
	{
		// Remove text that says, "No outline."
//		[_noOutlineText removeFromSuperview];
//		_noOutlineText = NULL;

		// Force it to load up.
		[_outlineView reloadData];
		[_outlineView display];
	}
	else
	{
		// Remove outline view (leaving instead text that says, "No outline.").
//		[[_outlineView enclosingScrollView] removeFromSuperview];
//		_outlineView = NULL;
	}
}

- (void) notificationSetup;
{
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pageChanged:)
												 name: PDFViewPageChangedNotification object: self];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(scaleChanged:)
												 name: PDFViewScaleChangedNotification object: self];
	// Find notifications.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(startFind:)
												 name: PDFDocumentDidBeginFindNotification object: NULL];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(findProgress:)
												 name: PDFDocumentDidEndPageFindNotification object: NULL];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(endFind:)
												 name: PDFDocumentDidEndFindNotification object: NULL];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(changeMagnification:)
												 name:MagnificationChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(rememberMagnification:)
												 name:MagnificationRememberNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(revertMagnification:)
												 name:MagnificationRevertNotification object:nil];
	
}

- (void) setup
{
	[self notificationSetup];
	
	// lines below were moved to toolbar setup to avoid "toolbar bug"
	// mouseMode = [SUD integerForKey: PdfKitMouseModeKey];
	// [[myDocument mousemodeMatrix] selectCellWithTag: mouseMode];
	
	[[[self.myDocument mousemodeMenu] itemWithTag: mouseMode] setState: NSOnState];
	currentMouseMode = mouseMode;
	self.selRectTimer = nil;
	
	totalRotation = 0;
	
	[self initializeDisplay];
}

- (BOOL) doReleaseDocument
{
// This entire routine was protection for a bug in Tiger. So we can
//     bypass it
    
    return YES;
}


- (void) showWithPath: (NSString *)imagePath
{
	PDFDocument	*pdfDoc;
	NSData	*theData;
    
     NSDisableScreenUpdates();
	
	self.sourceFiles = nil;
	
	// For the next line, we initialize once, but then when reshowing, 
	// or even closing and opening the window, we keep the previous value
	
	mouseMode = [SUD integerForKey: PdfKitMouseModeKey];
	
	// if ([SUD boolForKey:ReleaseDocumentClassesKey]) {
	if ([self doReleaseDocument]) {
		pdfDoc = [[PDFDocument alloc] initWithURL: [NSURL fileURLWithPath: imagePath]];
		[self setDocument: pdfDoc];
		// [pdfDoc release];
	} else {
		theData = [NSData dataWithContentsOfURL: [NSURL fileURLWithPath: imagePath]];
		pdfDoc = [[PDFDocument alloc] initWithData: theData];
		[self setDocument: pdfDoc];
	}
		
	[self setup];
	totalPages = [[self document] pageCount];
	[totalPage setIntegerValue:totalPages];
	[totalPage1 setIntegerValue:totalPages];
	[totalPage display];
	[totalPage1 display];
	[[self document] setDelegate: self];
	[self setupOutline];
    NSEnableScreenUpdates();
	
	[self.myPDFWindow makeKeyAndOrderFront: self];
	if ([SUD boolForKey:PreviewDrawerOpenKey]) 
		[self toggleDrawer: self];
}

- (void) showForSecond;
{
	// totalRotation = 0;
	self.sourceFiles = nil;
	
	if (mouseMode == 0)
		mouseMode = currentMouseMode = [SUD integerForKey: PdfKitMouseModeKey];
	totalPages = [[self document] pageCount];
	[self notificationSetup];
	[self initializeDisplay];
}


- (void) reShowWithPath: (NSString *)imagePath
{
	
	PDFDocument	*pdfDoc, *oldDoc;
	PDFPage		*aPage;
	NSInteger			theindex, oldindex;
	BOOL		needsInitialization;
	NSInteger			i, amount, newAmount;
	PDFPage		*myPage;
	NSData		*theData;

	// A note below explains dangers of NSDisableScreenUpdates
    // but these dangers don't apply to Intel on recent systems.
    // Experiments show that in single page mode, "disableFlushWindow"
    // adds a flash showing the initial page before switching to the
    // current page. NSDisableScreenUpdates fixes that.
    
    
	// [[self window] disableFlushWindow];
    NSDisableScreenUpdates();

	[self cleanupMarquee: YES];
	
	if (self.sourceFiles != nil) {
//		[self.sourceFiles release];
		self.sourceFiles = nil;
	}
	if ([self document] == nil)
		needsInitialization = YES;
	else
		needsInitialization = NO;
	
	NSRect visibleRect = [[self documentView] visibleRect];
	NSRect fullRect = [[self documentView] bounds];
	
	drawMark = NO;
	aPage = [self currentPage];
	theindex = [[self document] indexForPage: aPage];
	oldindex = theindex;
	theindex++;
	if ([[self document] isFinding])
		[[self document] cancelFindString];
	if (_searchResults != NULL) {
		[_searchResults removeAllObjects];
		[_searchTable reloadData];
//		[_searchResults release];
		_searchResults = NULL;
	}
			
	// if ([SUD boolForKey:ReleaseDocumentClassesKey]) {
	if ([self doReleaseDocument]) {
		// NSLog(@"texshop release");
		pdfDoc = [[PDFDocument alloc] initWithURL: [NSURL fileURLWithPath: imagePath]];
		[self setDocument: pdfDoc];
		// [pdfDoc release];
	} else {
		oldDoc = [self document];
		theData = [NSData dataWithContentsOfURL: [NSURL fileURLWithPath: imagePath]];
		pdfDoc = [[PDFDocument alloc] initWithData: theData];
		// pdfDoc = [[PDFDocument alloc] initWithData: theData];
		[self setDocument: pdfDoc];
		if (oldDoc != NULL) {
			[oldDoc setDelegate: NULL];
//			[oldDoc release];
		}
	}

	[[self document] setDelegate: self];
	totalPages = [[self document] pageCount];
	[totalPage setIntegerValue:totalPages];
	[totalPage1 setIntegerValue:totalPages];
	[totalPage display];
	[totalPage1 display];
	if (theindex > totalPages)
		theindex = totalPages;
	theindex--;
	if (needsInitialization)
		[self setup];
	if (totalRotation != 0) {
		for (i = 0; i < totalPages; i++) {
			myPage = [[self document] pageAtIndex:i];
			amount = [myPage rotation];
			newAmount = amount + totalRotation;
			[myPage setRotation: newAmount];
		}
		[self layoutDocumentView];
	}
	[self setupOutline];
		
	// WARNING: The next 9 lines of code are very fragile. Initially I used
	// NSDisableScreenUpdates until I discovered that this call is only in 10.4.3 and above
	// and works on Intel but not on PowerPC.
	// In the code below, you'd think that goToPage should be inside the disableFlushWindow,
	// but it doesn't seem to work there. If changes are made, be sure to test on
	// Intel and on PowerPC.
	aPage = [[self document] pageAtIndex: theindex];
	[self goToPage: aPage];
	
    NSRect newFullRect = [[self documentView] bounds];
    NSInteger difference = newFullRect.size.height - fullRect.size.height;
    
	visibleRect.origin.y = visibleRect.origin.y + difference - 1;
	[[self documentView] scrollRectToVisible: visibleRect];

/*
//   The test just below seems to show that we need to adjust by -1, and then
//   the visible rect ends up in the correct spot. Perhaps this is the width of the
//   line around the rectange (?)
    
    NSNumber *myNumber = [NSNumber numberWithInteger: visibleRect.origin.y];
    NSLog([myNumber stringValue]);
    myNumber = [NSNumber numberWithInteger: visibleRect.size.height];
    NSLog([myNumber stringValue]);
//
   NSInteger difference = -1;
    
//    NSRect  modifiedVisibleRect = NSInsetRect(visibleRect, 1, 1);
 //   if (NSIsEmptyRect(modifiedVisibleRect))
 //       modifiedVisibleRect = visibleRect;
    
	visibleRect.origin.y = visibleRect.origin.y + difference;
	[[self documentView] scrollRectToVisible: visibleRect];
    
//    [self scrollRectToVisible: modifiedVisibleRect];
*/
	//[[self window] enableFlushWindow];
    NSEnableScreenUpdates();
	[self display]; //this is needed outside disableFlushWindow when the user does not bring the window forward
}

- (NSInteger)index
{
    PDFPage		*aPage;
	NSInteger	theindex;
    
    aPage = [self currentPage];
	theindex = [[self document] indexForPage: aPage];
    return theindex;
}

- (void)moveSplitToCorrectSpot:(NSInteger)index;
{
    PDFPage		*aPage;
    
    aPage = [[self document] pageAtIndex: index];
    [self goToPage: aPage];
    
}

- (void)prepareSecond
{	PDFPage		*aPage;
	NSInteger			oldindex;
	
	[self cleanupMarquee: YES];
	
	if ([self document] == nil)
		secondNeedsInitialization = YES;
	else
		secondNeedsInitialization = NO;
	
	
	secondVisibleRect = [[self documentView] visibleRect];
	secondFullRect = [[self documentView] bounds];
	
	
	drawMark = NO;
	aPage = [self currentPage];
	secondTheIndex = [[self document] indexForPage: aPage];
	oldindex = secondTheIndex;
	secondTheIndex++;
	
	/*
	 if ([[self document] isFinding])
	 [[self document] cancelFindString];
	 if (_searchResults != NULL) {
	 [_searchResults removeAllObjects];
	 [_searchTable reloadData];
	 [_searchResults release];
	 _searchResults = NULL;
	 }
	*/ 
}	 

- (void) reShowForSecond
{
	
	PDFPage		*aPage;
	
	[[self window] disableFlushWindow];
	totalPages = [[self document] pageCount];
	/*
	[self cleanupMarquee: YES];

	if ([self document] == nil)
		secondNeedsInitialization = YES;
	else
		secondNeedsInitialization = NO;


	NSRect visibleRect = [[self documentView] visibleRect];
	NSRect fullRect = [[self documentView] bounds];


	drawMark = NO;
	aPage = [self currentPage];
	theindex = [[self document] indexForPage: aPage];
	oldindex = theindex;
	theindex++;
	*/
	
/*
	if ([[self document] isFinding])
		[[self document] cancelFindString];
	if (_searchResults != NULL) {
		[_searchResults removeAllObjects];
		[_searchTable reloadData];
		[_searchResults release];
		_searchResults = NULL;
	}

	
	// if ([SUD boolForKey:ReleaseDocumentClassesKey]) {
	if ([self doReleaseDocument]) {
		// NSLog(@"texshop release");
		pdfDoc = [[[PDFDocument alloc] initWithURL: [NSURL fileURLWithPath: imagePath]] autorelease]; 
		[self setDocument: pdfDoc];
		// [pdfDoc release];
	} else {
		oldDoc = [self document];
		theData = [NSData dataWithContentsOfURL: [NSURL fileURLWithPath: imagePath]];
		pdfDoc = [[[PDFDocument alloc] initWithData: theData] retain];
		// pdfDoc = [[PDFDocument alloc] initWithData: theData];
		[self setDocument: pdfDoc];
		if (oldDoc != NULL) {
			[oldDoc setDelegate: NULL];
			[oldDoc release];
		}
	}
 */
// ----------------------------------	
    
	
/*
	[[self document] setDelegate: self];
*/
	totalPages = [[self document] pageCount];
/*
	[totalPage setIntValue:totalPages];
	[totalPage1 setIntValue: totalPages];
	[totalPage display];
	[totalPage1 display];
 */
	if (secondTheIndex > totalPages)
		secondTheIndex = totalPages;
	secondTheIndex--;
 

	if (secondNeedsInitialization)
		[self initializeDisplay];
	
/*
	if (totalRotation != 0) {
		for (i = 0; i < totalPages; i++) {
			myPage = [[self document] pageAtIndex:i];
			amount = [myPage rotation];
			newAmount = amount + totalRotation;
			[myPage setRotation: newAmount];
		}
		[self layoutDocumentView];
	}
	[self setupOutline];
*/
	
	// WARNING: The next 9 lines of code are very fragile. Initially I used
	// NSDisableScreenUpdates until I discovered that this call is only in 10.4.3 and above
	// and works on Intel but not on PowerPC.
	// In the code below, you'd think that goToPage should be inside the disableFlushWindow,
	// but it doesn't seem to work there. If changes are made, be sure to test on
	// Intel and on PowerPC.
	
	if (self.sourceFiles != nil) {
//		[self.sourceFiles release];
		self.sourceFiles = nil;
	}
	aPage = [[self document] pageAtIndex: secondTheIndex];
	[self goToPage: aPage];
	
	NSRect newFullRect = [[self documentView] bounds];
	NSInteger difference = newFullRect.size.height - secondFullRect.size.height;
	secondVisibleRect.origin.y = secondVisibleRect.origin.y + difference;
	
	// [self display];
	[[self documentView] scrollRectToVisible: secondVisibleRect];
	[[self window] enableFlushWindow];
	[self display]; //this is needed outside disableFlushWindow when the user does not bring the window forward
}

- (void) rotateClockwisePrimary
{	
	NSInteger			i, amount, newAmount;
	PDFPage		*myPage;
	
	totalRotation = totalRotation + 90;
	if (totalRotation >= 360)
		totalRotation = totalRotation - 360;
	for (i = 0; i < totalPages; i++) {
		myPage = [[self document] pageAtIndex:i];
		amount = [myPage rotation];
		newAmount = amount + 90;
		[myPage setRotation: newAmount];
	}
}


- (void) rotateClockwise:sender
{
	
	
	[self cleanupMarquee: YES];

	// [self rotateClockwisePrimary];
	[(TSPreviewWindow *)self.myPDFWindow fixAfterRotation: YES];
	// [self layoutDocumentView];
}

- (void) rotateCounterclockwisePrimary
{
	NSInteger			i, amount, newAmount;
	PDFPage		*myPage;
	
	totalRotation = totalRotation - 90;
	if (totalRotation < 0)
		totalRotation = totalRotation + 360;
	
	for (i = 0; i < totalPages; i++) {
		myPage = [[self document] pageAtIndex:i];
		amount = [myPage rotation];
		newAmount = amount - 90;
		[myPage setRotation: newAmount];
	}
}

- (void) rotateCounterclockwise:sender
{
	
	

	[self cleanupMarquee: YES];
	
	// [self rotateCounterclockwisePrimary];

	[(TSPreviewWindow *)self.myPDFWindow fixAfterRotation: NO];
	// [self layoutDocumentView];
}

- (void) goBack:sender
{
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE))
		[self cleanupMarquee: YES];
	[super goBack:sender];
}

- (void) goForward: sender
{
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE))
		[self cleanupMarquee: YES];
	[super goForward:sender];
}

- (void) scaleChanged: (NSNotification *) notification
{
	CGFloat	theScale;
	NSInteger		magsize;
	
	theScale = [self scaleFactor];
	magsize = theScale * 100;
	scaleMag = magsize;
	if (self == [self.myDocument topView]) {
		[myScale setIntegerValue:magsize];
		[myScale1 setIntegerValue:magsize];
		[myScale display];
		[myStepper setIntegerValue:magsize];
		[myStepper1 setIntegerValue:magsize];
		}
}

- (void) pageChanged: (NSNotification *) notification
{
	PDFPage			*aPage;
	NSInteger				pageNumber;
	NSInteger				numRows, i, newlySelectedRow;
	NSUInteger	newPageIndex;
	NSIndexSet		*myIndexSet;
	
	aPage = [self currentPage];
	pageNumber = [[self document] indexForPage: aPage] + 1;
	[currentPage setIntegerValue:pageNumber];
	[currentPage1 setIntegerValue:pageNumber];
    
 	// Skip out if there is no outline.
	if ([[self document] outlineRoot] == NULL)
		return;

	// What is the new page number (zero-based).
	newPageIndex = [[self document] indexForPage: [self currentPage]];

	// Walk outline view looking for best firstpage number match.
	newlySelectedRow = -1;
	numRows = [_outlineView numberOfRows];
	for (i = 0; i < numRows; i++)
	{
		PDFOutline	*outlineItem;

		// Get the destination of the given row....
		outlineItem = (PDFOutline *)[_outlineView itemAtRow: i];

		if ([[self document] indexForPage: [[outlineItem destination] page]] == newPageIndex)
		{
			newlySelectedRow = i;
			myIndexSet = [NSIndexSet indexSetWithIndex: i];
			// [_outlineView selectRow: newlySelectedRow byExtendingSelection: NO]; //this was deprecated, so
			[_outlineView selectRowIndexes: myIndexSet byExtendingSelection: NO];
			break;
		}
		else if ([[self document] indexForPage: [[outlineItem destination] page]] > newPageIndex)
		{
			newlySelectedRow = i - 1;
			myIndexSet = [NSIndexSet indexSetWithIndex: i];
			// [_outlineView selectRow: newlySelectedRow byExtendingSelection: NO]; //this was deprecated, so
			[_outlineView selectRowIndexes: myIndexSet byExtendingSelection: NO];
			break;
		}
	}

	// Auto-scroll.
	if (newlySelectedRow != -1)
		[_outlineView scrollRowToVisible: newlySelectedRow];
}

- (double)magnification
{
	double	magsize;

	magsize = [myScale integerValue] / 100.0;
	return magsize;
}

- (void)zoomIn: sender
{
	
	NSInteger	scale;
	
	scale = [myScale integerValue];
	scale = scale + 10;
	if (scale > 1000)
		scale = 1000;
	scaleMag = scale;
	[myScale setIntegerValue:scale];
	[self changeScale: self];
}

- (void)zoomOut: sender
{
	NSInteger	scale;
	
	scale = [myScale integerValue];
	scale = scale - 10;
	if (scale< 20)
		scale = 20;
	scaleMag = scale;
	[myScale setIntegerValue:scale];
	[self changeScale: self];
}


- (void) changeScale: sender
{
	NSInteger		scale;
	double	magSize;
	
	[self cleanupMarquee: YES];

	if (sender == myScale1) {
		[myScale setIntegerValue:[myScale1 integerValue]];
		scaleMag = [myScale1 integerValue];
		}
	scale = [myScale integerValue];
	if (scale < 20) {
		scale = 20;
		scaleMag = scale;
		[myScale setIntegerValue:scale];
		[myScale1 setIntegerValue:scale];
		[myScale display];
		}
	if (scale > 1000) {
		scale = 1000;
		scaleMag = scale;
		[myScale setIntegerValue:scale];
		[myScale1 setIntegerValue:scale];
		[myScale display];
		}
	if ((sender == myScale) || (sender == myScale1))
		[[self window] makeFirstResponder: myScale];
	[myStepper setIntegerValue:scale];
	[myStepper1 setIntegerValue:scale];
	magSize = [self magnification];
	[self setScaleFactor: magSize];
	if (sender == myScale1) {
		[NSApp endSheet: [self.myDocument magnificationPanel]];
	}

/*
	// mitsu 1.29b
	// uncheck menu item Preview=>Magnification
	NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
						NSLocalizedString(@"Preview", @"Preview")] submenu];
	NSMenu *menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Magnification", @"Magnification")] submenu];
	[[menu itemWithTag: resizeOption] setState: NSOffState];
	if (magSize == 1.0)
		resizeOption = NEW_PDF_ACTUAL_SIZE;
	else
		resizeOption = NEW_PDF_FIT_TO_NONE;
	// uncheck menu item Preview=>Magnification
	[[menu itemWithTag: resizeOption] setState: NSOnState];
	// end mitsu 1.29
*/
}

- (void) doStepper: sender
{
	if (sender == myStepper)
		[myScale setIntegerValue:[myStepper integerValue]];
	else
		[myScale setIntegerValue:[myStepper1 integerValue]];
	scaleMag = [myScale integerValue];
	[self changeScale: self];
}


- (void) previousPage: (id)sender
{
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE))
		[self cleanupMarquee: YES];
	[self goToPreviousPage:self];
}

- (void) nextPage: (id)sender
{
	
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE))
		[self cleanupMarquee: YES];
	[self goToNextPage:sender];
}

- (void) firstPage: (id)sender
{
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE))
		[self cleanupMarquee: YES];
	[self goToFirstPage:self];
}

- (void) lastPage: (id)sender
{
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE))
		[self cleanupMarquee: YES];
	[self goToLastPage:sender];
}

- (void) goToKitPageNumber: (NSInteger) thePage
{
	NSInteger			myPage;
	PDFPage		*aPage;
	
	myPage = thePage;
	
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE))
		[self cleanupMarquee: YES];
	


	if (myPage < 1)
		myPage = 1;
	if (myPage > totalPages)
		myPage = totalPages;

	[currentPage setIntegerValue:myPage];
	[currentPage1 setIntegerValue:myPage];
	[currentPage display];
	[[self window] makeFirstResponder: currentPage];

	myPage = myPage - 1;
	aPage = [[self document] pageAtIndex: myPage];
	[self goToPage: aPage];

}


- (void) goToKitPage: (id)sender
{
	NSInteger		thePage;

	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE))
		[self cleanupMarquee: YES];
	thePage = [sender integerValue];
	if (sender == currentPage1)
		[NSApp endSheet:[self.myDocument pagenumberPanel]];
	[self goToKitPageNumber: thePage];


}

- (void)changePageStyleTo:(NSInteger)newStyle
{
        NSInteger number, i;
        id item;
    
    
    [self cleanupMarquee: YES];
	if ( newStyle != pageStyle)
	{
		// mitsu 1.29b uncheck menu item Preview=>Display Format
		NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
                                NSLocalizedString(@"Preview", @"Preview")] submenu];
		NSMenu *menu = [[previewMenu itemWithTitle:
                         NSLocalizedString(@"Display Format", @"Display Format")] submenu];
        number = [menu numberOfItems];
        for (i = 0; i < number; i++)
            [[menu itemAtIndex:i] setState: NSOffState];
        
		// id item = [menu itemWithTag: pageStyle];
		// [item setState: NSOffState];
		// end mitsu 1.29b
        
		// change page style
		pageStyle = newStyle;
		[self setupPageStyle];
        
		// mitsu 1.29b check menu item Preview=>Display Format
		item = [menu itemWithTag: pageStyle];
		[item setState: NSOnState];
		// end mitsu 1.29b
        
        /*
         // clean up the timer for selected rectangle
         if (selRectTimer)
         {
         [selRectTimer invalidate]; // this will release the timer
         selRectTimer = nil;
         rect = NSMakeRect(0, 0, 1, 1); // [[self window] discardCachedImage];
         }
         */
	}
} 
    

// action for menu items "Single Page/Two Page/Multi-Page/Double Multi-Page"
// -- tags should be correctly set
- (void)changePageStyle: (id)sender
{
    NSInteger newStyle;
    newStyle = [sender tag];
    [self changePageStyleTo:newStyle];
    /*
	[self cleanupMarquee: YES];
	if ([sender tag] != pageStyle)
	{
		// mitsu 1.29b uncheck menu item Preview=>Display Format
		NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
							NSLocalizedString(@"Preview", @"Preview")] submenu];
		NSMenu *menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Display Format", @"Display Format")] submenu];
		id item = [menu itemWithTag: pageStyle];
		[item setState: NSOffState];
		// end mitsu 1.29b

		// change page style
		pageStyle = [sender tag];
		[self setupPageStyle];

		// mitsu 1.29b check menu item Preview=>Display Format
		item = [menu itemWithTag: pageStyle];
		[item setState: NSOnState];
		// end mitsu 1.29b


	//	// clean up the timer for selected rectangle
	//	if (selRectTimer)
	//	{
	//		[selRectTimer invalidate]; // this will release the timer
	//		selRectTimer = nil;
	//		rect = NSMakeRect(0, 0, 1, 1); // [[self window] discardCachedImage];
	//	}

    }
    */
}

- (void)changePDFViewSizeTo: (NSInteger)newResizeOption
{
        NSInteger number, i;
        id item;
    
        [self cleanupMarquee: YES];
        
        if (newResizeOption == 0) return;
        
        
        NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
                                NSLocalizedString(@"Preview", @"Preview")] submenu];
        NSMenu *menu = [[previewMenu itemWithTitle:
                         NSLocalizedString(@"Magnification", @"Magnification")] submenu];
        number = [menu numberOfItems];
        for (i = 0; i < number; i++)
            [[menu itemAtIndex:i] setState: NSOffState];

        // id  item = [menu itemWithTag: resizeOption];
        // [item setState: NSOffState];
        
        resizeOption = newResizeOption;
        [self setupMagnificationStyle];
        
        /*
         if (resizeOption == PDF_ACTUAL_SIZE)
         {
         [self setMagnification: 1.0];
         }
         else if (resizeOption == PDF_FIT_TO_NONE)
         {
         }
         else if (resizeOption == PDF_FIT_TO_WIDTH || resizeOption == PDF_FIT_TO_HEIGHT
         || resizeOption == PDF_FIT_TO_WINDOW)
         {
         [self fitToSize];
         }
         else // possibley called by a menu in toolbar
         {
         [self setMagnification: ((double)resizeOption)/100];
         resizeOption = PDF_FIT_TO_NONE;
         }
         */
        
        // mitsu: check menu item Preview=>Magnification
        item = [menu itemWithTag: resizeOption];
        [item setState: NSOnState];
        // end mitsu

    
    
}

// action for menu items "Actual Size/Fixed Magnification/Fit To ..."
- (void)changePDFViewSize: (id)sender
{
    if (![sender tag]) return;
    
    [self changePDFViewSizeTo:[sender tag]];
     
    return;
	[self cleanupMarquee: YES];

	if (![sender tag]) return;

	NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
				NSLocalizedString(@"Preview", @"Preview")] submenu];
	NSMenu *menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Magnification", @"Magnification")] submenu];
	id  item = [menu itemWithTag: resizeOption];
	[item setState: NSOffState];

	resizeOption = [sender tag];
	[self setupMagnificationStyle];

/*
	if (resizeOption == PDF_ACTUAL_SIZE)
	{
		[self setMagnification: 1.0];
	}
	else if (resizeOption == PDF_FIT_TO_NONE)
	{
	}
	else if (resizeOption == PDF_FIT_TO_WIDTH || resizeOption == PDF_FIT_TO_HEIGHT
				|| resizeOption == PDF_FIT_TO_WINDOW)
	{
		[self fitToSize];
	}
	else // possibley called by a menu in toolbar
	{
		[self setMagnification: ((double)resizeOption)/100];
		resizeOption = PDF_FIT_TO_NONE;
	}
*/

	// mitsu: check menu item Preview=>Magnification
	item = [menu itemWithTag: resizeOption];
	[item setState: NSOnState];
	// end mitsu
}


- (void) copy: (id)sender
{
	
	if (mouseMode != NEW_MOUSE_MODE_SELECT_PDF)
		[super copy:sender];
	else {
		NSString *dataType = 0;
		NSPasteboard *pboard = [NSPasteboard generalPasteboard];
		NSInteger imageCopyType = [SUD integerForKey:PdfCopyTypeKey]; // mitsu 1.29b

		if (imageCopyType != IMAGE_TYPE_PDF && imageCopyType != IMAGE_TYPE_EPS)
			dataType = NSTIFFPboardType;
		else if (imageCopyType == IMAGE_TYPE_PDF)
			dataType = NSPDFPboardType;
		else if (imageCopyType == IMAGE_TYPE_EPS)
			dataType = NSPostScriptPboardType;

		NSData *data = [self imageDataFromSelectionType: imageCopyType];
		if (data) {
			// FIXME: If imageCopyType is unknown, then dataType is 0 here!
			[pboard declareTypes:[NSArray arrayWithObjects: dataType, nil] owner:self];
			[pboard setData:data forType:dataType];
		} else
			NSRunAlertPanel(@"Error", @"failed to copy selection.", nil, nil, nil);
		}
}


// --------------------------------------------------------------------------------------------------------- toggleDrawer

- (IBAction) toggleDrawer: (id) sender
{
	[_drawer toggle: self];
}

// ------------------------------------------------------------------------------------------- takeDestinationFromOutline

- (IBAction) takeDestinationFromOutline: (id) sender
{
	// Get the destination associated with the search result list.  Tell the PDFView to go there.
	[self goToDestination: [[sender itemAtRow: [sender selectedRow]] destination]];
}


#pragma mark ------ NSOutlineView delegate methods
// ----------------------------------------------------------------------------------- outlineView:numberOfChildrenOfItem

// The outline view is for the PDF outline.  Not all PDF's have an outline.

- (NSInteger) outlineView: (NSOutlineView *) outlineView numberOfChildrenOfItem: (id) item
{
	if (item == NULL)
	{
		if (self.outline)
			return [self.outline numberOfChildren];
		else
			return 0;
	}
	else
		return [(PDFOutline *)item numberOfChildren];
}

// --------------------------------------------------------------------------------------------- outlineView:child:ofItem

- (id) outlineView: (NSOutlineView *) outlineView child: (NSInteger) idx ofItem: (id) item
{
	if (item == NULL)
	{
		if (self.outline)
			return [self.outline childAtIndex: idx];
		else
			return NULL;
	}
	else
		return [(PDFOutline *)item childAtIndex: idx];
}

// ----------------------------------------------------------------------------------------- outlineView:isItemExpandable

- (BOOL) outlineView: (NSOutlineView *) outlineView isItemExpandable: (id) item
{
	if (item == NULL)
	{
		if (self.outline)
			return ([self.outline numberOfChildren] > 0);
		else
			return NO;
	}
	else
		return ([(PDFOutline *)item numberOfChildren] > 0);
}

// ------------------------------------------------------------------------- outlineView:objectValueForTableColumn:byItem

- (id) outlineView: (NSOutlineView *) outlineView objectValueForTableColumn: (NSTableColumn *) tableColumn
		byItem: (id) item
{
	return [(PDFOutline *)item label];
}


- (void) doFind: (id) sender
{
	if (protectFind) {
		// NSLog(@"protectFind");
		return;
		}
	
	if ([[self document] isFinding])
		[[self document] cancelFindString];

	// Lazily allocate _searchResults.
	if (_searchResults == NULL)
		_searchResults = [NSMutableArray arrayWithCapacity: 10];

	[[self document] beginFindString: [sender stringValue] withOptions: NSCaseInsensitiveSearch];
}

// ------------------------------------------------------------------------------------------------------------ startFind

- (void) startFind: (NSNotification *) notification
{
	if (protectFind) {
		// NSLog(@"protectFind: start");
		return;
	}
	
	if ([notification object] != [self document])
		return;
	// Empty arrays.
	if (self != [self.myDocument topView])
		; 
	else {
	[_searchResults removeAllObjects];

	[_searchTable reloadData];
	[_searchProgress startAnimation: self];
	}
}

// --------------------------------------------------------------------------------------------------------- findProgress

- (void) findProgress: (NSNotification *) notification
{
	double		pageIndex;
	
	if (protectFind) {
		// NSLog(@"protectFind: progress");
		return;
	}
	
	if ([notification object] != [self document])
		return;

	if (self != [self.myDocument topView])
		; 
	else {
	
	pageIndex = [[[notification userInfo] objectForKey: @"PDFDocumentPageIndex"] doubleValue];
	[_searchProgress setDoubleValue: pageIndex / [[self document] pageCount]];
	}
}

// ------------------------------------------------------------------------------------------------------- didMatchString
// Called when an instance was located. Delegates can instantiate.

- (void) didMatchString: (PDFSelection *) instance
{
	if (protectFind) {
		// NSLog(@"protectFind: match");
		return;
	}
	
	if (self != [self.myDocument topView])
		;
		else {
	// Add page label to our array.
	if (_searchResults != NULL){
		[_searchResults addObject: [instance copy]];
		// Force a reload.
		[_searchTable reloadData];
		}
	}
}

// -------------------------------------------------------------------------------------------------------------- endFind

- (void) endFind: (NSNotification *) notification
{
	
	if (protectFind) {
		// NSLog(@"protectFind: end");
		return;
	}
	
	if ([notification object] != [self document])
		return;
	
	if (self != [self.myDocument topView])
		;
	else {
	[_searchProgress stopAnimation: self];
	[_searchProgress setDoubleValue: 0];
	}
}


#pragma mark ------ NSTableView delegate methods
// ---------------------------------------------------------------------------------------------- numberOfRowsInTableView

// The table view is used to hold search results.  Column 1 lists the page number for the search result,
// column two the section in the PDF (x-ref with the PDF outline) where the result appears.

- (NSInteger) numberOfRowsInTableView: (NSTableView *) aTableView
{
	if (self != [self.myDocument topView])
		return ([[self.myDocument topView] numberOfRowsInTableView: aTableView]);
	else
		return ([_searchResults count]);
}

// ------------------------------------------------------------------------------ tableView:objectValueForTableColumn:row

- (id) tableView: (NSTableView *) aTableView objectValueForTableColumn: (NSTableColumn *) theColumn
		row: (NSInteger) rowIndex
{
	if (self != [self.myDocument topView])
		return ([[self.myDocument topView] tableView: aTableView objectValueForTableColumn: theColumn row: rowIndex]);

	else {
		if ([[theColumn identifier] isEqualToString: @"page"])
			return ([[[[_searchResults objectAtIndex: rowIndex] pages] objectAtIndex: 0] label]);
		else if ([[theColumn identifier] isEqualToString: @"section"])
			return ([[[self document] outlineItemForSelection: [_searchResults objectAtIndex: rowIndex]] label]);
		else
			return NULL;
		}
}

// ------------------------------------------------------------------------------------------ tableViewSelectionDidChange

- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
	NSInteger				rowIndex;
	NSMutableArray	*_firstSearchResults;
	
	if ([notification object] != _searchTable)
		return;
	
	// What was selected.  Skip out if the row has not changed.
	rowIndex = [(NSTableView *)[notification object] selectedRow];
	if (rowIndex >= 0)
	{
		if (self != [self.myDocument topView]) {
			_firstSearchResults = [[self.myDocument topView] getSearchResults];
			[self setCurrentSelection:[_firstSearchResults objectAtIndex: rowIndex]];
			}
		else
			[self setCurrentSelection: [_searchResults objectAtIndex: rowIndex]];
		[self centerSelectionInVisibleArea: self];
	}
}

- (void) changeMouseMode: (id)sender
{
	NSInteger	oldMouseMode;

	oldMouseMode = mouseMode;

	if ([sender isKindOfClass: [NSButton class]] || [sender isKindOfClass: [NSMenuItem class]])
	{
		[[[self.myDocument mousemodeMenu] itemWithTag: mouseMode] setState: NSOffState];
		mouseMode = currentMouseMode = [sender tag];
		[[self.myDocument mousemodeMatrix] selectCellWithTag: mouseMode];
		[[[self.myDocument mousemodeMenu] itemWithTag: mouseMode] setState: NSOnState];
	}
	else if ([sender isKindOfClass: [NSMatrix class]])
	{
		[[[self.myDocument mousemodeMenu] itemWithTag: mouseMode] setState: NSOffState];
		mouseMode = currentMouseMode = [[sender selectedCell] tag];
		[[self.myDocument mousemodeMatrix] selectCellWithTag: mouseMode];
		[[[self.myDocument mousemodeMenu] itemWithTag: mouseMode] setState: NSOnState];
	}

	if ((oldMouseMode == NEW_MOUSE_MODE_SELECT_PDF) && (mouseMode != NEW_MOUSE_MODE_SELECT_PDF) &&
	(mouseMode != NEW_MOUSE_MODE_SCROLL))

		[self cleanupMarquee: YES];

	[[self window] invalidateCursorRectsForView: self]; // this updates the cursor rects

/*
//	[[self window] invalidateCursorRectsForView: self]; // this updates the cursor rects
//        [self cleanupMarquee: YES]; // added by koch to erase marquee
*/
}

// mitsu 1.29 (S2)
// derived from Apple's Sample code PDFView/DraggableScrollView.m
- (void)scrollByDragging: (NSEvent *)theEvent
{
	NSPoint 		initialLocation;
	NSRect			visibleRect;
	BOOL			keepGoing;

	initialLocation = [theEvent locationInWindow];
	visibleRect = [[self documentView] visibleRect];
	keepGoing = YES;

	[[NSCursor closedHandCursor] set];

	while (keepGoing)
	{
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		switch ([theEvent type])
		{
			case NSLeftMouseDragged:
			{
				NSPoint	newLocation;
				NSRect	newVisibleRect;
				CGFloat	xDelta, yDelta;

				newLocation = [theEvent locationInWindow];
				xDelta = initialLocation.x - newLocation.x;
				yDelta = initialLocation.y - newLocation.y;


				//	This was an amusing bug: without checking for flipped,
				//	you could drag up, and the document would sometimes move down!
				if ([self isFlipped])
					yDelta = -yDelta;

				newVisibleRect = NSOffsetRect (visibleRect, xDelta, yDelta);
				[[self documentView] scrollRectToVisible: newVisibleRect];
				//[super scrollRectToVisible: newVisibleRect];
			}
			break;

			case NSLeftMouseUp:
				keepGoing = NO;
				break;

			default:
				/* Ignore any other kind of event. */
				break;
		}								// end of switch (event type)
	}									// end of mouse-tracking loop
	[[NSCursor arrowCursor] set];
	[self flagsChanged: theEvent]; // update cursor
}



- (void)resetCursorRects
{
	NSRect	mySelectedRect;

	if (self.selRectTimer)
		mySelectedRect = [self convertRect: selectedRect fromView: [self documentView]];

	switch (currentMouseMode)
	{
		case NEW_MOUSE_MODE_SCROLL:
			[super resetCursorRects];
			[self addCursorRect:[self visibleRect] cursor:[NSCursor openHandCursor]];
			break;
		case NEW_MOUSE_MODE_SELECT_TEXT:
			[super resetCursorRects];
			break;
		case NEW_MOUSE_MODE_SELECT_PDF:
			[super resetCursorRects];
			[self addCursorRect:[self visibleRect] cursor:[NSCursor crosshairCursor]];
			if (self.selRectTimer)
				[self addCursorRect:mySelectedRect cursor:[NSCursor arrowCursor]];
			break;
		case NEW_MOUSE_MODE_MAG_GLASS: // want magnifying glass cursor?
		case NEW_MOUSE_MODE_MAG_GLASS_L:
			[super resetCursorRects];
			[self addCursorRect:[self visibleRect] cursor:[NSCursor arrowCursor]];
			break;
		default:
			[super resetCursorRects];
			[self addCursorRect:[self visibleRect] cursor:[NSCursor arrowCursor]];
			break;
	}
}

#pragma mark =====drawPage=====

- (void)setIndexForMark: (NSInteger)idx
{
	pageIndexForMark = idx;
}

- (void)setBoundsForMark: (NSRect)bounds
{
	pageBoundsForMark = bounds;
}

- (void)setDrawMark: (BOOL)value
{
	drawMark = value;
}

/*
- (void)drawPage:(PDFPage *)page
{
	[page drawWithBox: kPDFDisplayBoxMediaBox];
}
*/

- (void)setOldSync: (BOOL)value
{
	oldSync = value;
}


/*

- (void)drawPage:(PDFPage *)page
{
	
	NSInteger					pagenumber;
	NSPoint				p;
	NSInteger					rotation;
	NSRect				boxRect;
	NSAffineTransform   *transform;
	
	// boxRect = [page boundsForBox: [self displayBox]];
	boxRect = [page boundsForBox: kPDFDisplayBoxMediaBox];
	rotation = [page rotation];

	// [super drawPage: page];

	[NSGraphicsContext saveGraphicsState];
	switch (rotation)
	{
		case 90:
			transform = [NSAffineTransform transform];
			[transform translateXBy: 0 yBy: boxRect.size.width];
			[transform rotateByDegrees: 360 - rotation];
			[transform concat];
			break;

		case 180:
			transform = [NSAffineTransform transform];
			[transform translateXBy: boxRect.size.width yBy: boxRect.size.height];
			[transform rotateByDegrees: 360 - rotation];
			[transform concat];

			break;

		case 270:
			transform = [NSAffineTransform transform];
			[transform translateXBy: boxRect.size.height yBy: 0];
			[transform rotateByDegrees: 360 - rotation];
			[transform concat];
			break;
	}

	// the following draws the background for dataWithPDFInsideRect etc.
	if (![NSGraphicsContext currentContextDrawingToScreen])
	{
		// set a break point here to check the consistency of dataWithPDFInsideRect
		//NSLog(@"In drawRect aRect: %@", NSStringFromRect(aRect));
		NSColor *backColor;
		if ([SUD boolForKey:PdfColorMapKey] && [SUD stringForKey:PdfBack_RKey])
		{
			backColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:PdfBack_RKey]
												  green: [SUD floatForKey:PdfBack_GKey] blue: [SUD floatForKey:PdfBack_BKey]
												  alpha: [SUD floatForKey:PdfBack_AKey]];
			[backColor set];
			NSRectFill(boxRect);
		}

		else {
			backColor = [NSColor colorWithCalibratedRed: 1 green: 1 blue: 1 alpha: 0];
			[backColor set];
			 NSRectFill(boxRect);
			// NSDrawWindowBackground(boxRect); NO
		}
	}

	else {
		[PreviewBackgroundColor set];
		NSRectFill(boxRect);
	}

		 // NSDrawWindowBackground(boxRect);

	[NSGraphicsContext restoreGraphicsState];
	[page drawWithBox:[self displayBox]];

	// Set up transform to handle rotated page.

	switch (rotation)
	{
		case 90:
			transform = [NSAffineTransform transform];
			[transform translateXBy: 0 yBy: boxRect.size.width];
			[transform rotateByDegrees: 360 - rotation];
			[transform concat];
			break;

		case 180:
			transform = [NSAffineTransform transform];
			[transform translateXBy: boxRect.size.width yBy: boxRect.size.height];
			[transform rotateByDegrees: 360 - rotation];
			[transform concat];

			break;

		case 270:
			transform = [NSAffineTransform transform];
			[transform translateXBy: boxRect.size.height yBy: 0];
			[transform rotateByDegrees: 360 - rotation];
			[transform concat];
			break;
	}

	p.x = 0; p.y = 0;
	pagenumber = [[self document] indexForPage:page];
	[self drawDotsForPage:pagenumber atPoint: p];

	NSInteger theIndex = [[self document] indexForPage: page];
	if (drawMark && (theIndex == pageIndexForMark)) {
		NSBezierPath *myPath = [NSBezierPath bezierPathWithOvalInRect: pageBoundsForMark];
		NSColor *myColor = [NSColor redColor];
		[myColor set];
		[myPath stroke];
	}

}
 
*/

- (void)drawPage:(PDFPage *)page
{
	
	int					pagenumber;
	NSPoint				p;
	int					rotation;
	NSRect				boxRect;
	NSAffineTransform   *transform;
    BOOL				redOvals;
	NSColor				*aColor, *myColor;

	
	// boxRect = [page boundsForBox: [self displayBox]];
	boxRect = [page boundsForBox: kPDFDisplayBoxMediaBox];
	rotation = [page rotation];
    
	// [super drawPage: page];
    
	[NSGraphicsContext saveGraphicsState];
	switch (rotation)
	{
		case 90:
			transform = [NSAffineTransform transform];
			[transform translateXBy: 0 yBy: boxRect.size.width];
			[transform rotateByDegrees: 360 - rotation];
			[transform concat];
			break;
            
		case 180:
			transform = [NSAffineTransform transform];
			[transform translateXBy: boxRect.size.width yBy: boxRect.size.height];
			[transform rotateByDegrees: 360 - rotation];
			[transform concat];
            
			break;
            
		case 270:
			transform = [NSAffineTransform transform];
			[transform translateXBy: boxRect.size.height yBy: 0];
			[transform rotateByDegrees: 360 - rotation];
			[transform concat];
			break;
	}
    
	// the following draws the background for dataWithPDFInsideRect etc.
	if (![NSGraphicsContext currentContextDrawingToScreen])
	{
		// set a break point here to check the consistency of dataWithPDFInsideRect
		//NSLog(@"In drawRect aRect: %@", NSStringFromRect(aRect));
		NSColor *backColor;
		if ([SUD boolForKey:PdfColorMapKey] && [SUD stringForKey:PdfBack_RKey])
		{
			backColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:PdfBack_RKey]
												  green: [SUD floatForKey:PdfBack_GKey] blue: [SUD floatForKey:PdfBack_BKey]
												  alpha: [SUD floatForKey:PdfBack_AKey]];
			[backColor set];
			NSRectFill(boxRect);
		}
        
		else {
			backColor = [NSColor colorWithCalibratedRed: 1 green: 1 blue: 1 alpha: 0];
			[backColor set];
            NSRectFill(boxRect);
			// NSDrawWindowBackground(boxRect); NO
		}
	}
    
	else {
		[PreviewBackgroundColor set];
		NSRectFill(boxRect);
	}
    
    // NSDrawWindowBackground(boxRect);
    
	[NSGraphicsContext restoreGraphicsState];
	
    [NSGraphicsContext saveGraphicsState];
	switch (rotation)
	{
		case 90:
			transform = [NSAffineTransform transform];
			[transform translateXBy: 0 yBy: boxRect.size.width];
			[transform rotateByDegrees: 360 - rotation];
			[transform concat];
			break;
			
		case 180:
			transform = [NSAffineTransform transform];
			[transform translateXBy: boxRect.size.width yBy: boxRect.size.height];
			[transform rotateByDegrees: 360 - rotation];
			[transform concat];
			
			break;
			
		case 270:
			transform = [NSAffineTransform transform];
			[transform translateXBy: boxRect.size.height yBy: 0];
			[transform rotateByDegrees: 360 - rotation];
			[transform concat];
			break;
	}
	
	p.x = 0; p.y = 0;
	pagenumber = [[self document] indexForPage:page];
	[self drawDotsForPage:pagenumber atPoint: p];
	
    int theIndex = [[self document] indexForPage: page];
	redOvals = [SUD boolForKey: syncWithRedOvalsKey];
	if (drawMark && (theIndex == pageIndexForMark)) {
		int i = 0;
		NSBezierPath *myPath;
        if (oldSync)
			myColor = [NSColor redColor];
		else if (redOvals) {
			myColor = [NSColor redColor];
        }
		else {
			aColor = [NSColor yellowColor];
			myColor = [aColor colorWithAlphaComponent: 0.5];
        }
		[myColor set];
        if (oldSync) {
			myPath = [NSBezierPath bezierPathWithOvalInRect: pageBoundsForMark];
			[myPath stroke];
            }
		else while (i < numberSyncRect) {
			if (redOvals) {
				myPath = [NSBezierPath bezierPathWithOvalInRect: syncRect[i]];
                [myPath stroke];
			}
			else {
				myPath = [NSBezierPath bezierPathWithRect: syncRect[i]];
				[myPath fill];
            }
			i++;
		}
	}
    
    
    
	[NSGraphicsContext restoreGraphicsState];
    
    [NSGraphicsContext saveGraphicsState];
    BOOL shouldAntiAlias = [SUD boolForKey: AntiAliasKey];
    if (shouldAntiAlias) {
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        }
	[page drawWithBox:[self displayBox]];
    [NSGraphicsContext restoreGraphicsState];

    
	// Set up transform to handle rotated page.
    /*
     switch (rotation)
     {
     case 90:
     transform = [NSAffineTransform transform];
     [transform translateXBy: 0 yBy: boxRect.size.width];
     [transform rotateByDegrees: 360 - rotation];
     [transform concat];
     break;
     
     case 180:
     transform = [NSAffineTransform transform];
     [transform translateXBy: boxRect.size.width yBy: boxRect.size.height];
     [transform rotateByDegrees: 360 - rotation];
     [transform concat];
     
     break;
     
     case 270:
     transform = [NSAffineTransform transform];
     [transform translateXBy: boxRect.size.height yBy: 0];
     [transform rotateByDegrees: 360 - rotation];
     [transform concat];
     break;
     }
     
     
     p.x = 0; p.y = 0;
     pagenumber = [[self document] indexForPage:page];
     [self drawDotsForPage:pagenumber atPoint: p];
     
     
     int theIndex = [[self document] indexForPage: page];
     if (drawMark && (theIndex == pageIndexForMark)) {
     int i = 0;
     NSBezierPath *myPath;
     NSColor *aColor = [NSColor yellowColor];
     NSColor *myColor = [aColor colorWithAlphaComponent: 0.5];
     [myColor set];
     while (i < numberSyncRect) {
     NSBezierPath *myPath = [NSBezierPath bezierPathWithRect: syncRect[i]];
     [myPath fill];
     i++;
     }
     
     
     
     
     
     //		NSBezierPath *myPath = [NSBezierPath bezierPathWithOvalInRect: pageBoundsForMark];
     //		NSColor *myColor = [NSColor redColor];
     //		[myColor set];
     //		[myPath stroke];
     }
     */
    
}




#pragma mark =====mouse routines=====

- (void) mouseDown: (NSEvent *) theEvent
{
    
    if (drawMark) {
		[self setDrawMark: NO];
		[self display];
	}


	// koch; Dec 5, 2003

	// The next lines fix a strange bug. Suppose the user has chosen the select tool,
	// but then changes to the source window with command-1 and typesets to get back
	// to the preview. Then the select tool is not active. The reason is that
	// pushing the command key calls "flags changed" but releasing it doesn't call
	// "flags changed" because now another window is active. Koch Jan 11, 2006
	if (!([theEvent modifierFlags] & NSAlternateKeyMask) &&
		!([theEvent modifierFlags] & NSCommandKeyMask) &&
		!([theEvent modifierFlags] & NSControlKeyMask))
		currentMouseMode = mouseMode;
	
	if (!([theEvent modifierFlags] & NSAlternateKeyMask) && ([theEvent modifierFlags] & NSCommandKeyMask)) {
		currentMouseMode = mouseMode;
		[[self window] invalidateCursorRectsForView: self];
		NSPoint thePoint = [theEvent locationInWindow];
		[self doSync: thePoint];
		return;
	}

	if (([self areaOfInterestForMouse: theEvent] &  kPDFLinkArea) != 0) {
		[self cleanupMarquee: YES];
		downOverLink = YES;
		[super mouseDown: theEvent];
		return;
				}


	//	[[self window] makeFirstResponder: [self window]]; // mitsu 1.29b
	[[self window] makeFirstResponder: self];

	if ([theEvent clickCount] >= 2)
	{
		currentMouseMode = NEW_MOUSE_MODE_MAG_GLASS;
		[[self window] invalidateCursorRectsForView: self];
#ifndef SELECTION_SHOUND_PERSIST
		[self cleanupMarquee: YES];
#endif
		[self doMagnifyingGlass: theEvent level:
			((mouseMode==NEW_MOUSE_MODE_MAG_GLASS_L)?1:((mouseMode==NEW_MOUSE_MODE_MAG_GLASS)?0:(-1)))];
	}
	else
	{
		switch (currentMouseMode)
		{
			case NEW_MOUSE_MODE_SCROLL:
#ifndef SELECTION_SHOUND_PERSIST
				// [self cleanupMarquee: YES];
#endif
				[self scrollByDragging: theEvent];
				break;
			case NEW_MOUSE_MODE_MAG_GLASS:
#ifndef SELECTION_SHOUND_PERSIST
				[self cleanupMarquee: YES];
#endif
				[self doMagnifyingGlass: theEvent level: 0];
				break;
			case NEW_MOUSE_MODE_MAG_GLASS_L:
#ifndef SELECTION_SHOUND_PERSIST
				[self cleanupMarquee: YES];
#endif
				[self doMagnifyingGlass: theEvent level: 1];
				break;
			case NEW_MOUSE_MODE_SELECT_PDF:
                
      //       if (atLeastMavericks && [self overView] && [self mouse: [self convertPoint:
                if ([self overView] && [self mouse: [self convertPoint:
                                                    [theEvent locationInWindow] fromView: nil] inRect: [self convertRect:selectedRect fromView: [self documentView]]])
                 [self startDragging: theEvent];
            
            
            else if (self.selRectTimer && [self mouse: [self convertPoint:
							  [theEvent locationInWindow] fromView: nil] inRect: [self convertRect:selectedRect fromView: [self documentView]]])
                
				
					// mitsu 1.29 drag & drop
					// Koch: I commented out the moveSelection choice since it seems to be broken due to sync
					// if (([theEvent modifierFlags] & NSCommandKeyMask) &&
					//					(mouseMode == NEW_MOUSE_MODE_SELECT_PDF))
					//	[self moveSelection: theEvent];
					// else
					[self startDragging: theEvent];
					// end mitsu 1.29
            
            else
                    [self selectARectForMavericks: theEvent];
                
                
        //        else
		//			[self selectARect: theEvent];
                 
				break;
			case NEW_MOUSE_MODE_SELECT_TEXT:
#ifndef SELECTION_SHOUND_PERSIST
				[self cleanupMarquee: YES];
#endif
				[super mouseDown: theEvent];
				break;
		}
	}

}

// ----------------------------------------------------------------------------------------------------------- mouseMoved

- (void) mouseMoved: (NSEvent *) theEvent
{
	if (mouseMode == NEW_MOUSE_MODE_SELECT_TEXT) {
		[super mouseMoved: theEvent];
	}
	else if (downOverLink) {
		[super mouseMoved: theEvent];
	}
	else if (([self areaOfInterestForMouse: theEvent] & kPDFLinkArea) != 0) {
		[[NSCursor pointingHandCursor] set];
	}
	else if (([self areaOfInterestForMouse: theEvent] & kPDFPageArea) != 0) {
		switch (mouseMode) {
			case NEW_MOUSE_MODE_SCROLL:
				[[NSCursor openHandCursor] set];
				break;

			case NEW_MOUSE_MODE_SELECT_PDF:
				[[NSCursor crosshairCursor] set];
				break;
			case NEW_MOUSE_MODE_MAG_GLASS:
			case NEW_MOUSE_MODE_MAG_GLASS_L:
				[[NSCursor arrowCursor] set];
				break;
		}
	}
	else {
		[super mouseMoved: theEvent];
	}
}


// --------------------------------------------------------------------------------------------------------- mouseDragged

- (void) mouseDragged: (NSEvent *) theEvent
{

	if (downOverLink) {
		[super mouseDragged: theEvent];
		return;
	}

	switch (mouseMode) {

		case NEW_MOUSE_MODE_SCROLL:				break;

		case NEW_MOUSE_MODE_SELECT_TEXT:		[super mouseDragged: theEvent];
												break;

		case NEW_MOUSE_MODE_MAG_GLASS:			break;

		case NEW_MOUSE_MODE_MAG_GLASS_L:		break;

		case NEW_MOUSE_MODE_SELECT_PDF:			break;

	}

/*
	if ([(MyPDFDocument *)_controller mode] == kViewPDFMode)
	{
		[super mouseDragged: theEvent];
		return;
	}

	// Handle edit mode.
	if ((_partHit != -1) && (_selectedAnnotation))
	{
		NSPoint		mouseDragLocation;
		NSRect		newBounds;

		// Mouse in display view coordinates.
		mouseDragLocation = [self convertPoint: [theEvent locationInWindow] fromView: NULL];

		// Redraw old location.
		[self setNeedsDisplayInRect: [self convertRect: [_selectedAnnotation bounds] fromPage:
				[_selectedAnnotation page]]];

		switch (_partHit)
		{
			case 0:
			newBounds = _oldAnnotationBounds;
			newBounds.origin.x += mouseDragLocation.x - _mouseDownLocation.x;
			newBounds.size.width -= mouseDragLocation.x - _mouseDownLocation.x;
			[_selectedAnnotation setBounds: newBounds];
			break;

			case 1:
			newBounds = _oldAnnotationBounds;
			newBounds.size.width += mouseDragLocation.x - _mouseDownLocation.x;
			[_selectedAnnotation setBounds: newBounds];
			break;

			case 2:
			newBounds = _oldAnnotationBounds;
			newBounds.origin.y += mouseDragLocation.y - _mouseDownLocation.y;
			newBounds.size.height -= mouseDragLocation.y - _mouseDownLocation.y;
			[_selectedAnnotation setBounds: newBounds];
			break;

			case 3:
			newBounds = _oldAnnotationBounds;
			newBounds.size.height += mouseDragLocation.y - _mouseDownLocation.y;
			[_selectedAnnotation setBounds: newBounds];
			break;

			case 4:
			newBounds = _oldAnnotationBounds;
			newBounds.origin.x += mouseDragLocation.x - _mouseDownLocation.x;
			newBounds.origin.y += mouseDragLocation.y - _mouseDownLocation.y;
			[_selectedAnnotation setBounds: newBounds];
			break;

			default:
			break;
		}

		// Redraw new location.
		[self setNeedsDisplayInRect: [self convertRect: [_selectedAnnotation bounds] fromPage:
				[_selectedAnnotation page]]];
	}
*/
}

// -------------------------------------------------------------------------------------------------------------- mouseUp

- (void) mouseUp: (NSEvent *) theEvent
{

	if (downOverLink) {
		downOverLink = NO;
		if (([self areaOfInterestForMouse: theEvent] &  kPDFLinkArea) != 0)
				[super mouseUp: theEvent];
		return;
	}


	switch (mouseMode) {

		case NEW_MOUSE_MODE_SCROLL:				break;

		case NEW_MOUSE_MODE_SELECT_TEXT:		[super mouseUp: theEvent];
												break;

		case NEW_MOUSE_MODE_MAG_GLASS:			break;

		case NEW_MOUSE_MODE_MAG_GLASS_L:		break;

		case NEW_MOUSE_MODE_SELECT_PDF:			break;

	}

/*
	if ([(MyPDFDocument *)_controller mode] == kViewPDFMode)
	{
		[super mouseUp: theEvent];
		return;
	}

	// Handle edit mode.
	if ((_partHit != -1) && (_selectedAnnotation))
		_oldAnnotationBounds = [_selectedAnnotation bounds];
*/
}



- (BOOL) validateMenuItem:(NSMenuItem *)anItem
{
	
		
		return [super validateMenuItem: anItem];	
		

/*
	if ([menuItem action] == @selector(getInfo:))
	{
		enable = [_pdfView selectedAnnotation] != NULL;
	}
	else if ([menuItem action] == @selector(newLink:))
	{
		enable = _mode == kEditPDFMode;
	}
*/

}


#pragma mark =====select and copy=====

// REMARK: by Koch, July 10, 2013.
//
// The section below contains code which selects a region in the pdf window to be copied and pasted elsewhere
// or saved to a file. It also contains the magnifying glass code.
//
// The "rubber band" code selecting a region, and the code controlling the magnifying glass,
// have had periods of instability over the light of TeXShop.
// The original magnifying glass code broke in Leopard and had to be replaced by a different routine. Indeed,
// I talked to the author of PDFKit at WWDC in 2007 about the magnifying code.
//
// Both pieces of code broke again in OS X Mavericks. The fixes below work on Mavericks, but
// don't work on earlier systems. So the old code is used on systems from Leopard through
// Mountain Lion, and the new code is used on Mavericks and beyond.
//
// The key problem with these routines is that PDFView acts "sort of like an NSView" but is not a
// subclass of NSView. So standard techniques for drawing on top of NsView objects often fail for
// PDFView objects. Apple has not yet fully explained the PDFKit code changes in Mavericks. But it appears
// that these code changes make the PDFView closer to a standard NSView.
//
// In a sense, our previous code for rubberbanding and for the magnifying glass depended on
// special routines which "just happened to work" for these tasks. In contrast, the Mavericks code
// is the "right way to handle temporary drawing over a view." It works by temporarily placing a
// transparent view over the PDFView and drawing into that temporary view.
//
// Note that the new routines produce slightly different results. The old rubberbanding code drew
// a dotted border around the seledted region, with a dotted pattern that slowly resolved. The
// new code draws a solid, unchanging border. The magnifying glass does not support as many options
// via using the Control, Shift, and Option keys as the old routines.
//
//


// Previous remark about old routines by 
// select and copy:
// group of routines for selecting a rectangular region and copying as an image
// routines:
//		selectARect: --- to be called from mouseDown: select a rect, and lauches a timer
//		updateMarquee: --- a timer routine which updates the selected rectangle
//		cleanupMarquee: --- cleans up the rect and the timer
//		hasSelection --- check if there is a selected rectangle (by checking if there is a timer)
//		imageDataFromSelectionType: --- create data from the image inside the selected rect
//		copy: --- copies the selection to pasteboard
//		saveSelectionToFile: --- saves the selection to a file, uses the next routine
//			saveSelectionPanelDidEnd:returnCode:contextInfo:
// variables
//		selRectTimer --- holds reference to a timer which redraw the frame of selected rect
//		selectedRect --- selected rectangle in  pdfView coordinate
//		oldVisibleRect --- on exit save the visible rect so that when selectedRect has to be
//					erased we can use a faster drawing if the visible rect is the same
//		[SUD integerForKey:PdfCopyTypeKey](defaults) --- format of image data for copying
//					set in the Preferences, and can be changed on the fly in TSAppDelegate's
//					changeImageCopyType.
//		startFromCenter(global or defaults?) --- should the selection be centered around start point?
// technical points
//	for faster redrawing, use NSWindow's caching mechanisim
//		this is done by calling cacheImageInRect, restoreCachedImage, discardCachedImage
//		make sure that the cached image is consistent with current setting such as visibleRect
//	to draw a clear dotted rectangle frame (usually one gets a fuzzy one),
//		turn off antialiasing by [[NSGraphicsContext currentContext] setShouldAntialias: NO];
//		specify a rectangle whise coordinates in window (or in clip view) are half integers,
//			using NSInsetRect(NSIntegralRect(...), 0.5, 0.5)
//		draw in clip view and use integer values for patterns
// 	getting image data from selection
//		for bitmap image types (JPEG,TIFF,PNG,GIF,BMP), use
//			NSBitmapImageRep's initWithFocusedViewRect, if the entire selection is visible,
//			NSView's dataWithPDFInsideRect and convert via NSImage and NSBitmapImageRep, otherwise.
//		the latter is slower and takes more memory.
//		then convert to the specified type by NSBitmapImageRep's representationUsingType:properties:
//		for PDF and EPS types, use NSView's dataWithPDFInsideRect/dataWithEPSInsideRect
//			the size of the data you get is as big as or bigger than the original data for all pages
//			moreover if the magnification is not 100%, there seems to be an inconsistency
//			between the bounds and the size (if this the way the data is supposed to look?)
//			so rescale the view temporarily and call dataWithPDFInsideRect/dataWithEPSInsideRect.
// to reuse the code in other applications
//		copy the routines and variables mentioned above
//		set the imageCopyType elsewhere (in Preferences; see also TSAppDelegate's changeImageCopyType)
//		supply the rescaling part of imageDataFromSelectionType for PDF/EPS (not necessary?)


// Here are the routines used only by Mavericks
// -----------------------------------------------------------------------

/*
- (void) setOverView:(OverView *)theOverView
{
    overView = theOverView;
}

- (OverView *)overView
{
    return overView;
}
*/

// Obsolete Version
/*
 - (void)selectARectForMavericks: (NSEvent *)theEvent
 {
 NSPoint mouseLocWindow, startPoint, currentPoint;
 BOOL startFromCenter = NO;
 
 [self cleanupMarquee: NO];
 
 OverView *theOverView = [[OverView alloc] initWithFrame: [[self documentView] frame] ];
 [self setOverView: theOverView];
 [[self documentView] addSubview: [self overView]];
 
 mouseLocWindow = [theEvent locationInWindow];
 startPoint = [[self documentView] convertPoint: mouseLocWindow fromView:nil];
 rect = NSMakeRect(0, 0, 1, 1);
 
 do {
 if ([theEvent type]==NSLeftMouseDragged || [theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged)
 {
 
 
 // [self displayRect: [self visibleRect]];
 // [[self window] flushWindow];
 
 // get Mouse location and check if it is with the view's rect
 if (!([theEvent type]==NSFlagsChanged ))
 {
 mouseLocWindow = [theEvent locationInWindow];
 // scroll if the mouse is out of visibleRect
 [[self documentView] autoscroll: theEvent];
 }
 // calculate the rect to select
 currentPoint = [[self documentView] convertPoint: mouseLocWindow fromView:nil];
 
 selectedRect.size.width = abs(currentPoint.x-startPoint.x);
 selectedRect.size.height = abs(currentPoint.y-startPoint.y);
 
 if ([theEvent modifierFlags] & NSShiftKeyMask)
 {
 if (selectedRect.size.width > selectedRect.size.height)
 selectedRect.size.height = selectedRect.size.width;
 else
 selectedRect.size.width = selectedRect.size.height;
 }
 
 if (currentPoint.x < startPoint.x || startFromCenter)
 selectedRect.origin.x = startPoint.x - selectedRect.size.width;
 else
 selectedRect.origin.x = startPoint.x;
 if (currentPoint.y < startPoint.y || startFromCenter)
 selectedRect.origin.y = startPoint.y - selectedRect.size.height;
 else
 selectedRect.origin.y = startPoint.y;
 if (startFromCenter)
 {
 selectedRect.size.width *= 2;
 selectedRect.size.height *= 2;
 }
 
 
 [[self overView] setDrawRubberBand: YES];
 [[self overView] setSelectionRect: selectedRect];
 // [[self overView] drawRect: [[self documentView] visibleRect]];
 [[self overView] displayRect: [[self documentView] visibleRect]];
 //[[self window] flushWindow];
 
 }
 else if ([theEvent type]==NSLeftMouseUp)
 {
 break;
 }
 theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
 NSLeftMouseDraggedMask | NSFlagsChangedMask ];
 } while (YES);
 
 [self flagsChanged: theEvent]; // update cursor
 }

 */
 
- (void)selectARectForMavericks: (NSEvent *)theEvent
{
  
//    if ((floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7) &&
//        ([self displayMode] != kPDFDisplaySinglePageContinuous) && ([self displayMode] != kPDFDisplayTwoUpContinuous))
    
      if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7)
        
        return;
    
   //    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7)
   //         return;
    
    
    NSPoint mouseLocWindow, startPoint, currentPoint;
    BOOL startFromCenter = NO;
    
    [self cleanupMarquee: NO];
    
    OverView *theOverView = [[OverView alloc] initWithFrame: [[self documentView] frame] ] ;
    [self setOverView: theOverView];
    [[self documentView] addSubview: [self overView]];
    
    mouseLocWindow = [theEvent locationInWindow];
    startPoint = [[self documentView] convertPoint: mouseLocWindow fromView:nil];
    rect = NSMakeRect(0, 0, 1, 1);
    
    do {
        if ([theEvent type]==NSLeftMouseDragged || [theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged)
        {
            
            
             // get Mouse location and check if it is with the view's rect
            if (!([theEvent type]==NSFlagsChanged ))
            {
                mouseLocWindow = [theEvent locationInWindow];
                // scroll if the mouse is out of visibleRect
                [[self documentView] autoscroll: theEvent];
            }
            // calculate the rect to select
            currentPoint = [[self documentView] convertPoint: mouseLocWindow fromView:nil];
            
            selectedRect.size.width = abs(currentPoint.x-startPoint.x);
            selectedRect.size.height = abs(currentPoint.y-startPoint.y);
            
            if ([theEvent modifierFlags] & NSShiftKeyMask)
            {
                if (selectedRect.size.width > selectedRect.size.height)
                    selectedRect.size.height = selectedRect.size.width;
                else
                    selectedRect.size.width = selectedRect.size.height;
            }
            
            if (currentPoint.x < startPoint.x || startFromCenter)
                selectedRect.origin.x = startPoint.x - selectedRect.size.width;
            else
                selectedRect.origin.x = startPoint.x;
            if (currentPoint.y < startPoint.y || startFromCenter)
                selectedRect.origin.y = startPoint.y - selectedRect.size.height;
            else
                selectedRect.origin.y = startPoint.y;
            if (startFromCenter)
            {
                selectedRect.size.width *= 2;
                selectedRect.size.height *= 2;
            }
            
            
            [[self overView] setDrawRubberBand: YES];
            [[self overView] setSelectionRect: selectedRect];
            // [[self overView] displayRect: [[self documentView] visibleRect]];
            [[self overView] setNeedsDisplayInRect:[[self documentView] visibleRect]];
            
        }
        else if ([theEvent type]==NSLeftMouseUp)
        {
            break;
        }
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
                    NSLeftMouseDraggedMask | NSFlagsChangedMask ];
    } while (YES);
    
    [self flagsChanged: theEvent]; // update cursor
}


// Here is a routine used by both techniques to turn off the rubber band
// ------------------------------------------------------------------------------

// earses the frame of selected rectangle and cleans up the cached image
- (void)cleanupMarquee: (BOOL)terminate
{
    // for Mavericks
   //  if (atLeastMavericks) {
    {
        OverView *theOverView = [self overView];
        if (theOverView) {
            [theOverView removeFromSuperview];
            [self setOverView: nil];
            }
        return;
    }
    
    NSRect		tempRect;
        
        if (self.selRectTimer)
        {
            NSRect visRect = [[self documentView] visibleRect];
            // if (NSEqualRects(visRect, oldVisibleRect))
            //	[self updateBackground: rect]; // [[self window] restoreCachedImage];
            // change by mitsu to cleanup marquee immediately
            if (NSEqualRects(visRect, oldVisibleRect))
            {
                [self updateBackground: rect]; //[[self window] restoreCachedImage];
                [[self window] flushWindow];
            }
            else // the view was moved--do not use the cached image
            {
                rect = NSMakeRect(0, 0, 1, 1); // [[self window] discardCachedImage];
                tempRect =  [self convertRect: NSInsetRect(
                                                           NSIntegralRect([[self documentView] convertRect: selectedRect toView: nil]), -2, -2)
                                     fromView: nil];
                [self displayRect: tempRect];
            }
            oldVisibleRect.size.width = 0; // do not use this cache again
            if (terminate)
            {
                [self.selRectTimer invalidate]; // this will release the timer
                self.selRectTimer = nil;
            }
        }
}




// Here are the routines used only by Mountain Lion and lower
// -------------------------------------------------------------------------

// updates the frame of selected rectangle
- (void)updateMarquee: (NSTimer *)timer
{
	static NSInteger phase = 0;
	CGFloat pattern[2] = {3,3};
	NSView *clipView;
	NSRect selRectSuper, clipBounds;
	NSRect mySelectedRect;
	NSBezierPath *path;
    
	mySelectedRect = [self convertRect: selectedRect fromView: [self documentView]];
    
	if ([[self window] isMainWindow])
	{
		//clipView = [[self documentView] superview];
		clipView = [[self documentView] superview];
		clipBounds = [clipView bounds];
		[clipView lockFocus];
		[[NSGraphicsContext currentContext] setShouldAntialias: NO];
		selRectSuper = [self convertRect:mySelectedRect toView: clipView];
		// selRectSuper = [self convertRect: selRectSuper toView:self];
		selRectSuper = NSInsetRect(NSIntegralRect(selRectSuper), 0.5, 0.5);
		// if the eddges are slightly off the clip view, adjust them.
		if (NSMinX(clipBounds)-1<NSMinX(selRectSuper) && NSMinX(selRectSuper)<NSMinX(clipBounds))
		{
			selRectSuper.origin.x += 1;
			selRectSuper.size.width -= 1;
		}
		else if (NSMaxX(clipBounds)<NSMaxX(selRectSuper) && NSMaxX(selRectSuper)<NSMaxX(clipBounds)+1)
			selRectSuper.size.width -= 1;
		if (NSMinY(clipBounds)-1<NSMinY(selRectSuper) && NSMinY(selRectSuper)<NSMinY(clipBounds))
		{
			selRectSuper.origin.y += 1;
			selRectSuper.size.height -= 1;
		}
		else if (NSMaxY(clipBounds)<NSMaxY(selRectSuper) && NSMaxY(selRectSuper)<NSMaxY(clipBounds)+1)
			selRectSuper.size.height -= 1;
		// create a bezier path and draw
		path = [NSBezierPath bezierPathWithRect: selRectSuper];
		[path setLineWidth: 0.01];
		[[NSColor whiteColor] set];
		[path stroke];
		[path setLineDash: pattern count: 2 phase: phase];
		[[NSColor blackColor] set];
		[path stroke];
		[clipView unlockFocus];
		if (timer)
			[[self window] flushWindow];
		phase = (phase+1) % 6;
	}
}



// recache the image around selected rectangle for quicker response
- (void)recacheMarquee
{
    
	NSRect	theRect;
	
	if (self.selRectTimer)
	{
		theRect = NSInsetRect([[self documentView] convertRect: selectedRect toView: nil], -2, -2);
		// [[self window] cacheImageInRect: theRect];
		rect = [self convertRect: theRect fromView: nil];
		oldVisibleRect = [self visibleRect];
	}
}

- (BOOL)hasSelection
{
	return (self.selRectTimer != nil);
}



- (void)selectARect: (NSEvent *)theEvent
{
	NSPoint mouseLocWindow, startPoint, currentPoint;
	NSRect myBounds, selRectWindow, selRectSuper;
	NSBezierPath *path = [NSBezierPath bezierPath];
	BOOL startFromCenter = NO;
	static NSInteger phase = 0;
	CGFloat xmin, xmax, ymin, ymax, pattern[] = {3,3};

	[path setLineWidth: 0.01];
	mouseLocWindow = [theEvent locationInWindow];
	startPoint = [[self documentView] convertPoint: mouseLocWindow fromView:nil];
	[NSEvent startPeriodicEventsAfterDelay: 0 withPeriod: 0.2];
	[self cleanupMarquee: YES];
	rect = NSMakeRect(0, 0, 1, 1); //[[self window] discardCachedImage];

#ifndef DO_NOT_SHOW_SELECTION_SIZE
	// create a small window displaying the size of selection
	NSRect aRect;
	aRect.origin = [[self window] convertBaseToScreen: mouseLocWindow];
	aRect.origin.x -= SIZE_WINDOW_H_OFFSET;
	aRect.origin.y += SIZE_WINDOW_V_OFFSET;
	aRect.size = NSMakeSize(SIZE_WINDOW_WIDTH, SIZE_WINDOW_HEIGHT);
	NSPanel *sizeWindow = [[NSPanel alloc] initWithContentRect: aRect
			styleMask: NSBorderlessWindowMask | NSUtilityWindowMask
			backing: NSBackingStoreBuffered //NSBackingStoreRetained
			defer: NO];
	[sizeWindow setOpaque: NO];
	[sizeWindow setHasShadow: SIZE_WINDOW_HAS_SHADOW];
	[sizeWindow orderFront: nil];
	[sizeWindow setFloatingPanel: YES];
#endif

	do {
		if ([theEvent type]==NSLeftMouseDragged || [theEvent type]==NSLeftMouseDown ||
			[theEvent type]==NSFlagsChanged || [theEvent type]==NSPeriodic)
		{
			// restore the cached image in order to clear the rect
            
            // We replace rect by [self visibleRect] to solve the bug that in MountainLion,
            // garbage is left on the screen. This fix could be improved!
  			 // [self updateBackground: rect]; //[[self window] restoreCachedImage];
            [self updateBackground: [self visibleRect]];
 			 [[self window] flushWindow];
            
			// get Mouse location and check if it is with the view's rect
			if (!([theEvent type]==NSFlagsChanged || [theEvent type]==NSPeriodic))
			{
				mouseLocWindow = [theEvent locationInWindow];
				// scroll if the mouse is out of visibleRect
				[[self documentView] autoscroll: theEvent];
			}
			// calculate the rect to select
			currentPoint = [[self documentView] convertPoint: mouseLocWindow fromView:nil];
			selectedRect.size.width = abs(currentPoint.x-startPoint.x);
			selectedRect.size.height = abs(currentPoint.y-startPoint.y);
			if ([theEvent modifierFlags] & NSShiftKeyMask)
			{
				if (selectedRect.size.width > selectedRect.size.height)
					selectedRect.size.height = selectedRect.size.width;
				else
					selectedRect.size.width = selectedRect.size.height;
			}
			if (currentPoint.x < startPoint.x || startFromCenter)
				selectedRect.origin.x = startPoint.x - selectedRect.size.width;
			else
				selectedRect.origin.x = startPoint.x;
			if (currentPoint.y < startPoint.y || startFromCenter)
				selectedRect.origin.y = startPoint.y - selectedRect.size.height;
			else
				selectedRect.origin.y = startPoint.y;
			if (startFromCenter)
			{
				selectedRect.size.width *= 2;
				selectedRect.size.height *= 2;
			}
			// calculate the intersection of selectedRect with bounds
			// -- we do not want to use NSIntersectionRect
			// because even if it's empty, we want information on origin and edges
			// in our case, the only way the intersection can be empty is that
			// one of the edges has length zero.
			myBounds = [[self documentView] bounds];
			xmin = fmax(selectedRect.origin.x, myBounds.origin.x);
			xmax = fmin(selectedRect.origin.x+selectedRect.size.width,
						myBounds.origin.x+myBounds.size.width);
			ymin = fmax(selectedRect.origin.y, myBounds.origin.y);
			ymax = fmin(selectedRect.origin.y+selectedRect.size.height,
						myBounds.origin.y+myBounds.size.height);
			selectedRect = NSMakeRect(xmin,ymin,xmax-xmin,ymax-ymin);
			// do not use selectedRect = NSIntersectionRect(selectedRect, [self bounds]);
			selRectWindow = [[self documentView] convertRect: selectedRect toView: nil];
			// cache the window image
			// [[self window] cacheImageInRect:NSInsetRect(selRectWindow, -2, -2)];
			rect = [self convertRect: NSInsetRect(selRectWindow, -2, -2) fromView: nil];
			// draw rect frame
			[path removeAllPoints]; // reuse path
			// in order to draw a clear frame we draw an adjusted rect in clip view
			// selRectSuper = [[self superview] convertRect:selRectWindow fromView: nil];
			selRectSuper = [self convertRect:selRectWindow fromView: nil];
			if (!NSIsEmptyRect(selRectSuper))
			{	// shift the coordinated by a half integer
				selRectSuper = NSInsetRect(NSIntegralRect(selRectSuper), .5, .5);
				[path appendBezierPathWithRect: selRectSuper];
			}
			else // if width or height is zero, we cannot use NSIntegralRect, which returns zero rect
			{	 // so draw a path by hand
				selRectSuper.origin.x = floor(selRectSuper.origin.x)+0.5;
				selRectSuper.origin.y = floor(selRectSuper.origin.y)+0.5;
				[path appendBezierPathWithPoints: &(selRectSuper.origin) count: 1];
				selRectSuper.origin.x += floor(selRectSuper.size.width);
				selRectSuper.origin.y += floor(selRectSuper.size.height);
				[path appendBezierPathWithPoints: &(selRectSuper.origin) count: 1];
			}
			//[path setLineWidth: 0.01];
			// [[self superview] lockFocus];
            
 			[self lockFocus];
			[[NSGraphicsContext currentContext] setShouldAntialias: NO];
			[[NSColor whiteColor] set];
			[path stroke];
			[path setLineDash: pattern count: 2 phase: phase];
			[[NSColor blackColor] set];
			[path stroke];
			phase = (phase+1) % 6;
			// [[self superview] unlockFocus];
			 [self unlockFocus];
			// display the image drawn in the buffer
			[[self window] flushWindow];
  
#ifndef DO_NOT_SHOW_SELECTION_SIZE

			// update the size window
			// first compute where to show the window
			NSRect contentRect = [[[self window] contentView] bounds];
			xmin = fmax(selRectWindow.origin.x, contentRect.origin.x);
			ymin = fmax(selRectWindow.origin.y, contentRect.origin.y);
			ymax = fmin(selRectWindow.origin.y+selRectWindow.size.height,
						contentRect.origin.y+contentRect.size.height);
			NSPoint aPoint = NSMakePoint(xmin, (ymin+ymax)/2);
			aPoint = [[self window] convertBaseToScreen: aPoint];
			aPoint.x -= SIZE_WINDOW_H_OFFSET;
			aPoint.y += SIZE_WINDOW_V_OFFSET;
			[sizeWindow setFrameOrigin: aPoint]; // set the position
			// do the drawing
#warning 64BIT: Check formatting arguments
						NSString *sizeString = [NSString stringWithFormat: @"%d x %d",
				(NSInteger)floor(selRectWindow.size.width), (NSInteger)floor(selRectWindow.size.height)];
						NSView *sizeView = [sizeWindow contentView];
			[sizeView lockFocus];
						[[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.5 alpha:0.8] set];//change color?
			NSRectFill([sizeView bounds]);
						[sizeString drawAtPoint: NSMakePoint(SIZE_WINDOW_DRAW_X,SIZE_WINDOW_DRAW_Y)
								withAttributes: [NSDictionary dictionary]];
						[[NSGraphicsContext currentContext] flushGraphics];
			[sizeView unlockFocus];

#endif
		}
		else if ([theEvent type]==NSLeftMouseUp)
		{
			break;
		}
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
				NSLeftMouseDraggedMask | NSFlagsChangedMask | NSPeriodicMask];
	} while (YES);

	[NSEvent stopPeriodicEvents];
	if (selectedRect.size.width > 3 && selectedRect.size.height > 3)
	{
		self.selRectTimer = [NSTimer scheduledTimerWithTimeInterval: 0.2 target:self
			selector:@selector(updateMarquee:) userInfo:nil repeats:YES];
		oldVisibleRect = [[self documentView] visibleRect];
	}
	else
	{
		self.selRectTimer = nil;
		[self updateBackground: rect]; //[[self window] restoreCachedImage];
		[[self window] flushWindow];
		rect = NSMakeRect(0, 0, 1, 1); //[[self window] discardCachedImage];
	}
	[self flagsChanged: theEvent]; // update cursor
#ifndef DO_NOT_SHOW_SELECTION_SIZE
	[sizeWindow close];
#endif
}


- (void)selectAll: (id)sender
{
/*
	if ((mouseMode == NEW_MOUSE_MODE_SELECT_PDF) &&
		((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE)
	//	|| ([myRep pageCount] <= 20)
		))
		{
*/
	if ((mouseMode == NEW_MOUSE_MODE_SELECT_PDF) &&
	((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE) ||
	([[self document] pageCount] <= 20)
	))
	{
	NSRect selRectWindow, selRectSuper;
	NSBezierPath *path = [NSBezierPath bezierPath];
	static NSInteger phase = 0;
	CGFloat pattern[] = {3,3};

	[path setLineWidth: 0.01];
	[self cleanupMarquee: YES];
	rect = NSMakeRect(0, 0, 1, 1); // [[self window] discardCachedImage];

		// restore the cached image in order to clear the rect
		[self updateBackground: rect]; //[[self window] restoreCachedImage];


		selectedRect = [self frame];
		// FIX THIS: KOCH
		// selectedRect.size.width = totalWidth;
		//selectedRect.size.height = totalHeight;
		selRectWindow = [self convertRect: selectedRect toView: nil];
		// cache the window image
		// [[self window] cacheImageInRect:NSInsetRect(selRectWindow, -2, -2)];
		rect = [self convertRect: NSInsetRect(selRectWindow, -2, -2) fromView: nil];

		// draw rect frame
		[path removeAllPoints]; // reuse path
		// in order to draw a clear frame we draw an adjusted rect in clip view
		selRectSuper = [[self superview] convertRect:selRectWindow fromView: nil];
		if (!NSIsEmptyRect(selRectSuper))
		{	// shift the coordinated by a half integer
				selRectSuper = NSInsetRect(NSIntegralRect(selRectSuper), .5, .5);
				[path appendBezierPathWithRect: selRectSuper];
		}
		else // if width or height is zero, we cannot use NSIntegralRect, which returns zero rect
		{	 // so draw a path by hand
				selRectSuper.origin.x = floor(selRectSuper.origin.x)+0.5;
				selRectSuper.origin.y = floor(selRectSuper.origin.y)+0.5;
				[path appendBezierPathWithPoints: &(selRectSuper.origin) count: 1];
				selRectSuper.origin.x += floor(selRectSuper.size.width);
				selRectSuper.origin.y += floor(selRectSuper.size.height);
				[path appendBezierPathWithPoints: &(selRectSuper.origin) count: 1];
		}
		//[path setLineWidth: 0.01];
		[[self superview] lockFocus];
		[[NSGraphicsContext currentContext] setShouldAntialias: NO];
		[[NSColor whiteColor] set];
		[path stroke];
		[path setLineDash: pattern count: 2 phase: phase];
		[[NSColor blackColor] set];
		[path stroke];
		phase = (phase+1) % 6;
		[[self superview] unlockFocus];
		// display the image drawn in the buffer
		[[self window] flushWindow];

	self.selRectTimer = [NSTimer scheduledTimerWithTimeInterval: 0.2 target:self
			selector:@selector(updateMarquee:) userInfo:nil repeats:YES];
	oldVisibleRect = [self visibleRect];
	}

}

// end of routines for Mountain Lion and below
// -------------------------------------------------------------------------

- (void) printDocument: sender
{
	[self.myDocument printDocument: sender];
}




- (NSImage *)imageFromSelection
{
   if ([self hasSelection])
   {
    NSData *theData = [self imageDataFromSelectionType:IMAGE_TYPE_PDF];
    if (! theData)
        return nil;
    NSPDFImageRep *imageRep = [NSPDFImageRep imageRepWithData: theData];
    if (! imageRep)
        return nil;
    NSImage *theImage = [[NSImage alloc] init];
    [theImage addRepresentation: imageRep];
  //  [theImage autorelease];
    return theImage;
    }
else
    return nil;
}

// The next routine is only used in Mavericks
- (NSData *)PDFImageDataFromSelection
{
    NSRect  aRect;
    
    aRect = selectedRect;
    
    if ([self overView] == nil)
        return nil;
    
    if ((aRect.size.width < 5.0) || (aRect.size.height < 5.0))
        return nil;
    
    [self cleanupMarquee: NO];
    
    return [[self documentView] dataWithPDFInsideRect:aRect];
}

// get image data from the selected rectangle with specified type
- (NSData *)imageDataFromSelectionType: (NSInteger)type
{
	NSRect visRect, newRect, newRectRevised, pageRect, pageDataRect, selRectWindow, frameRect;
	NSRect mySelectedRect;
	NSData *data = nil;
	NSBitmapImageRep *bitmap = nil;
	NSBitmapImageFileType fileType;
	NSDictionary *dict;
	NSColor *foreColor, *backColor;
	NSSize mySize;
	
	offsetPoint.x = 0; offsetPoint.y = 0;

	mySelectedRect = [self convertRect: selectedRect fromView: [self documentView]];
	visRect = [self visibleRect];
	selRectWindow = [[self documentView] convertRect: selectedRect toView: nil];

	//test
	NSSize aSize = [self convertSize: mySelectedRect.size toView: nil];
	if (abs(selRectWindow.size.width - aSize.width)>1 ||
		abs(selRectWindow.size.height - aSize.height)>1)
	{
		// I don't know why this can happen, but it does happen from
		// time to time, when the view is rotated and selection is not visible.
		// The same thing happens when calling dataWithPDFInsideRect.
		// (To see this set a break point in drawRect within "if (![ .. drawingToScreen])".
		// and compare selectedRect and aRect.)
		//NSLog(@"a bug! \nconvertRect.size: %@, convertSize: %@",
		//	NSStringFromSize(selRectWindow.size), NSStringFromSize(aSize));
		selRectWindow.size = aSize;
	}

	NS_DURING
	if (type != IMAGE_TYPE_PDF && type != IMAGE_TYPE_EPS)
	{
		if (NSContainsRect(visRect, mySelectedRect))
		{	// if the rect is contained in visible rect
			[self cleanupMarquee: NO];
			[self recacheMarquee];

			// Apple does not document the size of the imageRep one gets from
			// "initWithFocusedViewRect:".  My experiments show that
			// the size is, in most cases, floor(selRectWindow.size.width/height).
			// However if theMagSize is not 1.0 and selRectWindow.size.width/height
			// is near integer, then the size can be off by one (larger or smaller).
			// So for safety, one might need to use the modified size.

			newRect = mySelectedRect;
			// get a bit map image from window for the rect in view coordinate
			[self lockFocus];
			bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:
											newRect] ;
			[self unlockFocus];
		}
		else // there is some portion which is not visible
		{
			// new routine which creates image by directly calling drawRect
			// TODO / FIXME: MyPDFKitView currently does *not* implement imageFromRect:!
			// Hence I am disabling this code for now.
#if 0
			NSImage *image = [self imageFromRect: mySelectedRect];

			if (image) {
				[image setScalesWhenResized: NO];
				[image setSize: NSMakeSize(floor(selRectWindow.size.width),
											floor(selRectWindow.size.height))];
				bitmap = [[[NSBitmapImageRep alloc] initWithData:
										[image TIFFRepresentation]] autorelease];
			}
#endif
		}
		// color mapping
		if (bitmap && [SUD boolForKey:PdfColorMapKey]) {
			if ([SUD stringForKey:PdfFore_RKey]) {
				foreColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:PdfFore_RKey]
					green: [SUD floatForKey:PdfFore_GKey] blue: [SUD floatForKey:PdfFore_BKey]
					alpha: [SUD floatForKey:PdfFore_AKey]];
			} else
				foreColor = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1];
			if ([SUD stringForKey:PdfBack_RKey]) {
				backColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:PdfBack_RKey]
					green: [SUD floatForKey:PdfBack_GKey] blue: [SUD floatForKey:PdfBack_BKey]
					alpha: [SUD floatForKey:PdfBack_AKey]];
			} else
				backColor = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1];
			NSInteger colorParam1 = [SUD integerForKey:PdfColorParam1Key];
			// call transformColor() below to map the colors
			bitmap = transformColor(bitmap, foreColor, backColor, colorParam1);
		}
		// convert to the specified format
		if (bitmap && type != IMAGE_TYPE_PICT) {
			switch (type) {
				case IMAGE_TYPE_TIFF_NC:
					fileType = NSTIFFFileType;
					dict = [NSDictionary  dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInteger:NSTIFFCompressionNone],
							NSImageCompressionMethod, nil];
					break;
				case IMAGE_TYPE_TIFF_LZW:
					fileType = NSTIFFFileType;
					dict = [NSDictionary  dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInteger:NSTIFFCompressionLZW],
							NSImageCompressionMethod, nil];
					break;
				case IMAGE_TYPE_TIFF_PB:
					fileType = NSTIFFFileType;
					dict = [NSDictionary  dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInteger:NSTIFFCompressionPackBits],
							NSImageCompressionMethod, nil];
					break;
				case IMAGE_TYPE_JPEG_HIGH:
					fileType = NSJPEGFileType;
					dict = [NSDictionary  dictionaryWithObjectsAndKeys:
							[NSNumber numberWithDouble:JPEG_COMPRESSION_HIGH],
							NSImageCompressionFactor, nil];
					break;
				case IMAGE_TYPE_JPEG_MEDIUM:
					fileType = NSJPEGFileType;
					dict = [NSDictionary  dictionaryWithObjectsAndKeys:
							[NSNumber numberWithDouble:JPEG_COMPRESSION_MEDIUM],
							NSImageCompressionFactor, nil];
					break;
				case IMAGE_TYPE_JPEG_LOW:
					fileType = NSJPEGFileType;
					dict = [NSDictionary  dictionaryWithObjectsAndKeys:
							[NSNumber numberWithDouble:JPEG_COMPRESSION_LOW],
							NSImageCompressionFactor, nil];
					break;
				case IMAGE_TYPE_PNG:
					fileType = NSPNGFileType;
					dict = [NSDictionary  dictionary];
					break;
				case IMAGE_TYPE_GIF: // GIF is not right format for our purpose
					fileType = NSGIFFileType;
					dict = [NSDictionary  dictionary];
					break;
				case IMAGE_TYPE_BMP: // does not work?
					fileType = NSBMPFileType;
					dict = [NSDictionary  dictionary];
					break;
				default: //default IMAGE_TYPE_JPEG_MEDIUM?
					fileType = NSJPEGFileType;
					dict = [NSDictionary  dictionaryWithObjectsAndKeys:
							[NSNumber numberWithDouble:JPEG_COMPRESSION_MEDIUM],
							NSImageCompressionFactor, nil];
			}
			data = [bitmap representationUsingType: fileType properties: dict];
		} else if (bitmap && type == IMAGE_TYPE_PICT) {
			data = getPICTDataFromBitmap(bitmap);
		}
		else
			data = nil;
	} else { // IMAGE_TYPE_PDF or IMAGE_TYPE_EPS
		// BE CAREFUL: dataWithPDFInsideRect may crash!
		// if the magnification is not 100%, there seems to be an inconsistency between
		// the bounds and the size.  to avoid this problem change the size of selectedRect.
		// see above for discussion on  dataWithPDFInsideRect

		newRect.origin = mySelectedRect.origin;
		// if (rotationAmount == 0)
		newRect.size = selRectWindow.size;
		//else if (rotationAmount == 180)// && theMagSize >= 1.0)//if theMagSize<1.0 image may be clipped?
		//{
		//	newRect.size = selRectWindow.size;
			//future origin is (_.origin.x+_.size.width, _.origin.y+_.size.height)
		//	newRect.origin.x += selectedRect.size.width;
		//	newRect.origin.y += selectedRect.size.height;
			//recalculate new origin given the future origin and size
		//	newRect.origin.x -= newRect.size.width;
		//	newRect.origin.y -= newRect.size.height;
		//}
		//else // probably one should use [NSPrintOperation PDFOperationWithView:insideRect:toData:]
		//	[NSException raise: @"cannot handle rotated view" format: @""];
		
		// -----------------------------------------------------------------
		// Richard Koch: August 9, 2007
		// The code below works around a Leopard bug
		// The following lines fail in Leopard at the final line
		//      oldBackColor = [self backgroundColor]
		//      [self setBackgroundColor: transparentColor];
		//      data = [self dataWithPDFInsideRect: newRect];
		//		[self setBackgroundColor: oldBackColor]
		// However, this problem goes away if we do not call dataWithPDFInsideRect
		// Apparently this line of code destroys oldBackColor
		// To work around this, we must decompose oldBackColor and then reconstruct it

		// oldBackColor = [self backgroundColor];
		
		// Richard Koch: December 10, 2007
		// The above fix failed on the release version of Leopard. Instead
		// an entirely new method is required, which was suggested to me at the
		// developer conference by the author of PDFKit
		
		// The code commented out below is the original fix
		
		/*
		oldBackColor = [[self backgroundColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace]; 
		float backRedColor, backGreenColor, backBlueColor, backAlphaColor;
		backRedColor = [oldBackColor redComponent];
		backGreenColor = [oldBackColor greenComponent];
		backBlueColor = [oldBackColor blueComponent];
		backAlphaColor = [oldBackColor alphaComponent];
		
		backColor = [NSColor colorWithCalibratedRed: 1.0
		green: 0.0 blue: 0.0
		alpha: 0.0];
		[self setBackgroundColor: backColor];
		*/

		// if (type == IMAGE_TYPE_PDF) 
		// data = [self dataWithPDFInsideRect: newRect];
						
			NSPoint myLocation = [[self window] mouseLocationOutsideOfEventStream];
			myLocation = [self convertPoint: myLocation fromView:nil];
			PDFPage *myPage = [self pageForPoint: myLocation nearest:YES];
			NSData	*myData = [myPage dataRepresentation];
			NSPDFImageRep *myRep = [NSPDFImageRep imageRepWithData: myData];
		
			pageDataRect = [self convertRect:newRect toPage:myPage];
			pageRect = [myPage boundsForBox: kPDFDisplayBoxMediaBox];
			pageDataRect = NSIntersectionRect(pageDataRect, pageRect);
			newRectRevised = [self convertRect:pageDataRect fromPage:myPage];
			offsetPoint.x = newRectRevised.origin.x - newRect.origin.x;
			offsetPoint.y = newRectRevised.origin.y - newRect.origin.y;
			 
			MyDragView *myDragView = [[MyDragView alloc] initWithFrame: pageRect];
			[myDragView setImageRep: myRep];
			
			double amount;
			amount = [self magnification];
			frameRect = [myDragView frame];
			frameRect.size.width = frameRect.size.width * amount;
			frameRect.size.height = frameRect.size.height * amount;
			[myDragView setFrame: frameRect];
			
			mySize.width = amount;
			mySize.height = amount;
			[myDragView scaleUnitSquareToSize: mySize];
			
			
			pageDataRect.size.height = pageDataRect.size.height * amount;
			pageDataRect.size.width = pageDataRect.size.width * amount;
			// pageDataRect.origin.x = pageDataRect.origin.x * amount;
			// pageDataRect.origin.y = pageDataRect.origin.y * amount;
			
		if (type == IMAGE_TYPE_PDF) 
				data = [myDragView dataWithPDFInsideRect: pageDataRect];
			else if (type == IMAGE_TYPE_EPS)
				data = [myDragView dataWithEPSInsideRect: pageDataRect];
			else
				data = nil;
				
	//		[myDragView release];
			
			
		// else // IMAGE_TYPE_EPSfile://localhost/Users/koch/Library/TeXShop/DraggedImages/texshop_image.pdf
		//	data = [self dataWithEPSInsideRect: newRect];
		
		/*
		NSColor *olderBackColor = [NSColor colorWithCalibratedRed: backRedColor green: backGreenColor blue: backBlueColor alpha: backAlphaColor];
		[self setBackgroundColor: olderBackColor];
		// [self setBackgroundColor: oldBackColor];
		
		// end of workaround
		// --------------------------------------------------------------
		*/

	}
	NS_HANDLER
		data = nil;
		//NSRunAlertPanel(@"Error", @"error occured in imageDataFromSelectionType:", nil, nil, nil);
	NS_ENDHANDLER
	return data;
}



// start save-dialog as a sheet
-(void)saveSelectionToFile: (id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel  setAccessoryView: self.imageTypeView];
//	[self.imageTypeView retain];
	NSInteger itemIndex = [self.imageTypePopup indexOfItemWithTag: [SUD integerForKey: PdfExportTypeKey]];
	if (itemIndex == -1) itemIndex = 0; // default PdfExportTypeKey
	[self.imageTypePopup selectItemAtIndex: itemIndex];
	[self chooseExportImageType: self.imageTypePopup]; // this sets up required type
	[savePanel setCanSelectHiddenExtension: YES];

//	[savePanel beginSheetForDirectory:nil file:nil
//		modalForWindow:[self window] modalDelegate:self
//		didEndSelector:@selector(saveSelectionPanelDidEnd:returnCode:contextInfo:)
//		contextInfo:nil];
    
    [savePanel beginSheetModalForWindow: [self window]
            completionHandler:^(NSInteger result) {
                if (NSFileHandlingPanelOKButton) {
                    NSData *data = nil;
                     data = [self imageDataFromSelectionType: [SUD integerForKey: PdfExportTypeKey]];
                    
                    if ([SUD integerForKey: PdfExportTypeKey] == IMAGE_TYPE_PICT) {
                        // PICT file needs to start with 512 bytes 0's
                        NSMutableData *pictData = [NSMutableData dataWithLength: 512];//initialized by 0's
                        [pictData appendData: data];
                        data = pictData;
                    }
                    if (data)
                        [data writeToFile:[[savePanel URL] path] atomically:YES];
                    else
                        NSRunAlertPanel(@"Error", @"failed to save selection to the file.", nil, nil, nil);
                }
            }];
}


// save the image data from selected rectangle to a file
/*
- (void)saveSelectionPanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo
{
	if (returnCode == NSFileHandlingPanelOKButton && [sheet filename]) {
		NSData *data = nil;
		//NSNumber *aNumber;

		//aNumber = [NSNumber numberWithInt: [SUD integerForKey: PdfExportTypeKey]];
		//NSLog([aNumber stringValue]);

		data = [self imageDataFromSelectionType: [SUD integerForKey: PdfExportTypeKey]];

		if ([SUD integerForKey: PdfExportTypeKey] == IMAGE_TYPE_PICT) {
			// PICT file needs to start with 512 bytes 0's
			NSMutableData *pictData = [NSMutableData dataWithLength: 512];//initialized by 0's
			[pictData appendData: data];
			data = pictData;
		}
		if (data)
			[data writeToFile:[sheet filename] atomically:YES];
		else
			NSRunAlertPanel(@"Error", @"failed to save selection to the file.", nil, nil, nil);
	}
}
*/



// control image type popup
- (void) chooseExportImageType: sender
{
	NSInteger imageExportType;
	NSSavePanel *savePanel;

	imageExportType = [[sender selectedItem] tag];
	savePanel = (NSSavePanel *)[sender window];
	// [savePanel setRequiredFileType: extensionForType(imageExportType)];// mitsu 1.29 drag & drop
    NSArray *myTypes = [NSArray arrayWithObject: extensionForType(imageExportType)];
    [savePanel setAllowedFileTypes: myTypes];
	if (imageExportType != [SUD integerForKey: PdfExportTypeKey]) {
		[SUD setInteger:imageExportType forKey:PdfExportTypeKey];
	}
}

// mitsu 1.29 drag & drop
#pragma mark =====drag & drop=====

- (void)startDragging: (NSEvent *)theEvent
{
	NSPasteboard *pboard;
	NSInteger imageCopyType;
	NSString *dataType = 0, *filePath;
	NSData *data;
	NSImage *image;
	NSSize dragOffset = NSMakeSize(0, 0);
	NSRect	mySelectedRect;
	NSPoint	offset;
	
	mySelectedRect = [self convertRect: selectedRect fromView: [self documentView]];

	
	pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	imageCopyType = [SUD integerForKey:PdfCopyTypeKey];
	if (imageCopyType != IMAGE_TYPE_PDF && imageCopyType != IMAGE_TYPE_EPS)
		dataType = NSTIFFPboardType;
	else if (imageCopyType == IMAGE_TYPE_PDF)
		dataType = NSPDFPboardType;
	else if (imageCopyType == IMAGE_TYPE_EPS)
		dataType = NSPostScriptPboardType;
	// FIXME: If imageCopyType is unknown, then dataType is 0 here!
	[pboard declareTypes:[NSArray arrayWithObjects: dataType,
							NSFilenamesPboardType, nil] owner:self];
	

	if (!((imageCopyType == IMAGE_TYPE_PDF || imageCopyType == IMAGE_TYPE_EPS)
		&& [SUD boolForKey: PdfQuickDragKey])) {
		data = [self imageDataFromSelectionType: imageCopyType];
		if (data) {
			
			[pboard setData:data forType:dataType];
			filePath = [[DraggedImagePath stringByStandardizingPath]
					stringByAppendingPathExtension: extensionForType(imageCopyType)];
			if ([data writeToFile: filePath atomically: NO])
				
			// WARNING: the next line causes a crash at program end!
				[pboard setPropertyList:[NSArray arrayWithObject: filePath]
									forType:NSFilenamesPboardType];
			image = [[NSImage alloc] initWithData: data] ;
			if (image) {
				// drag pdf image here
				offset = mySelectedRect.origin;
				offset.x = offset.x + offsetPoint.x; offset.y = offset.y + offsetPoint.y;
				[self dragImage:image at:offset offset:dragOffset
					event:theEvent pasteboard:pboard source:self slideBack:YES];
			}
		}
	} else { // quick drag for PDF & EPS
		// TODO / FIXME: MyPDFKitView currently does *not* implement imageFromRect:!
		// Hence I am disabling this code for now.
#if 0
		image = [self imageFromRect: mySelectedRect];
		
		if (image) {
			//[self pasteboard:pboard provideDataForType:dataType];
			//[self pasteboard:pboard provideDataForType:NSFilenamesPboardType];
			[self dragImage:image at:mySelectedRect.origin offset:dragOffset
					event:theEvent pasteboard:pboard source:self slideBack:YES];
		}
#endif
	}
}

// NSDraggingSource required method
- (NSUInteger)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return (isLocal)?NSDragOperationNone:NSDragOperationCopy;
}

// NSDraggingSource optional method for promised data
- (void)pasteboard:(NSPasteboard *)pboard provideDataForType:(NSString *)type
{
	NSString *filePath;
	NSData *data;
	NSInteger imageCopyType = [SUD integerForKey:PdfCopyTypeKey];

	if ([type isEqualToString: NSTIFFPboardType] ||
		[type isEqualToString: NSPDFPboardType] ||
		[type isEqualToString: NSPostScriptPboardType]) {
		data = [self imageDataFromSelectionType: imageCopyType];
		if (data)
			[pboard setData:data forType:type];
	} else if ([type isEqualToString: NSFilenamesPboardType]) {
		data = [self imageDataFromSelectionType: imageCopyType];
		if (data) {
			filePath = [[DraggedImagePath stringByStandardizingPath]
						stringByAppendingPathExtension: extensionForType(imageCopyType)];
			if ([data writeToFile: filePath atomically: NO])
				[pboard setPropertyList:[NSArray arrayWithObject: filePath]
									forType:NSFilenamesPboardType];
		}
	}
}

// end mitsu 1.29


#pragma mark =====sync=====

- (void)setupSourceFiles
{
	NSString		*sourceText, *searchText, *filePath, *filePathNew, *rootPath;
	NSUInteger	sourceLength;
	BOOL			done;
	NSRange			maskRange, searchRange, newSearchRange, fileRange;
	NSInteger				currentIndex;
	NSFileManager	*manager;
	BOOL			isDir;
	NSUInteger	startIndex, lineEndIndex, contentsEndIndex;

	manager = [NSFileManager defaultManager];

	rootPath = [[self.myDocument fileName] stringByDeletingLastPathComponent];
	self.sourceFiles = [NSMutableArray arrayWithCapacity: NUMBER_OF_SOURCE_FILES] ;
	currentIndex = 0;
	sourceText = [[self.myDocument textView] string];
	sourceLength = [sourceText length];
	
	
	// TODO: It should be possible to unify the following four loops. There are a few
	// differences, but those aren't a real problem.

	searchText = @"%!TEX projectfile =";
	done = NO;
	maskRange.location = 0;
	maskRange.length = sourceLength;
	
	// experiments show that the syntax is \include{file} where "file" cannot include ".tex" but the name must be "file.tex"
	while ((!done) && (maskRange.length > 0) && (currentIndex < NUMBER_OF_SOURCE_FILES)) {
		searchRange = [sourceText rangeOfString: searchText options:NSLiteralSearch range:maskRange];
		if (searchRange.location == NSNotFound)
			done = YES;
		else {
			maskRange.location = searchRange.location + 1;
			maskRange.length = sourceLength - maskRange.location;
			[sourceText getLineStart: &startIndex end: &lineEndIndex contentsEnd: &contentsEndIndex forRange: searchRange];
			newSearchRange.location = searchRange.location + [searchText length];
			newSearchRange.length = contentsEndIndex - newSearchRange.location;
			filePath = [sourceText substringWithRange: newSearchRange];
			if (filePath)
			    filePath = [filePath stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]; 
			if (filePath && ([filePath length] > 0)) {
			    if ([filePath characterAtIndex: 0] != '/')
					filePath = [[rootPath stringByAppendingString:@"/"] stringByAppendingString: filePath];
			    filePath = [filePath stringByStandardizingPath];
			    // add this to the array
			    if (([manager fileExistsAtPath: filePath isDirectory:&isDir]) && (!isDir)) {
					[self.sourceFiles insertObject: filePath atIndex: currentIndex];
					currentIndex++;
				}
			}
		}
	}
	
	searchText = @"% !TEX projectfile =";
	done = NO;
	maskRange.location = 0;
	maskRange.length = sourceLength;
	
	// experiments show that the syntax is \include{file} where "file" cannot include ".tex" but the name must be "file.tex"
	while ((!done) && (maskRange.length > 0) && (currentIndex < NUMBER_OF_SOURCE_FILES)) {
		searchRange = [sourceText rangeOfString: searchText options:NSLiteralSearch range:maskRange];
		if (searchRange.location == NSNotFound)
			done = YES;
		else {
			maskRange.location = searchRange.location + 1;
			maskRange.length = sourceLength - maskRange.location;
			[sourceText getLineStart: &startIndex end: &lineEndIndex contentsEnd: &contentsEndIndex forRange: searchRange];
			newSearchRange.location = searchRange.location + [searchText length];
			newSearchRange.length = contentsEndIndex - newSearchRange.location;
			filePath = [sourceText substringWithRange: newSearchRange];
			if (filePath)
			    filePath = [filePath stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]; 
			if (filePath && ([filePath length] > 0)) {
			    if ([filePath characterAtIndex: 0] != '/')
					filePath = [[rootPath stringByAppendingString:@"/"] stringByAppendingString: filePath];
			    filePath = [filePath stringByStandardizingPath];
			    // add this to the array
			    if (([manager fileExistsAtPath: filePath isDirectory:&isDir]) && (!isDir)) {
					[self.sourceFiles insertObject: filePath atIndex: currentIndex];
					currentIndex++;
				}
			}
		}
	}
	
	searchText = @"\\include{";
	done = NO;
	maskRange.location = 0;
	maskRange.length = sourceLength;

	// experiments show that the syntax is \include{file} where "file" cannot include ".tex" but the name must be "file.tex"
	while ((!done) && (maskRange.length > 0) && (currentIndex < NUMBER_OF_SOURCE_FILES)) {
		searchRange = [sourceText rangeOfString: searchText options:NSLiteralSearch range:maskRange];
		if (searchRange.location == NSNotFound)
			done = YES;
		else {
			maskRange.location = searchRange.location + 1;
			maskRange.length = sourceLength - maskRange.location;
			newSearchRange = [sourceText rangeOfString: @"}" options: NSLiteralSearch range:maskRange];
			if (newSearchRange.location == NSNotFound)
				done = YES;
			else {
				maskRange.location = newSearchRange.location + 1;
				maskRange.length = sourceLength - maskRange.location;
				fileRange.location = searchRange.location + [searchText length];
				fileRange.length = newSearchRange.location - fileRange.location;
				filePath = [sourceText substringWithRange: fileRange];
				// if ([[filePath pathExtension] length] == 0)
					filePath = [filePath stringByAppendingPathExtension: @"tex"];
				filePath = [[rootPath stringByAppendingString:@"/"] stringByAppendingString: filePath];
				filePath = [filePath stringByStandardizingPath];
				// add this to the array
				if (([manager fileExistsAtPath: filePath isDirectory:&isDir]) && (!isDir)) {
					[self.sourceFiles insertObject: filePath atIndex: currentIndex];
					currentIndex++;
				}
			}
		}
	}

	searchText = @"\\input{";
	done = NO;
	maskRange.location = 0;
	maskRange.length = sourceLength;

	// experiments show that the syntax is \input{file} where "file" may or may not end in ".tex" even if the actual file has
	// extension ".tex" and where "file" can also have no extension, or can have some other extension like ".ltx"
	// To handle this, the syntax below first adds ".tex" and looks for the file. If not found, it takes the name as presented
	// and looks for that
	while ((!done) && (maskRange.length > 0) && (currentIndex < NUMBER_OF_SOURCE_FILES)) {
		searchRange = [sourceText rangeOfString: searchText options:NSLiteralSearch range:maskRange];
		if (searchRange.location == NSNotFound)
			done = YES;
		else {
			maskRange.location = searchRange.location + 1;
			maskRange.length = sourceLength - maskRange.location;
			newSearchRange = [sourceText rangeOfString: @"}" options: NSLiteralSearch range:maskRange];
			if (newSearchRange.location == NSNotFound)
				done = YES;
			else {
				maskRange.location = newSearchRange.location + 1;
				maskRange.length = sourceLength - maskRange.location;
				fileRange.location = searchRange.location + [searchText length];
				fileRange.length = newSearchRange.location - fileRange.location;
				filePath = [sourceText substringWithRange: fileRange];
				// if ([[filePath pathExtension] length] == 0)
					filePathNew = [filePath stringByAppendingPathExtension: @"tex"];
				filePathNew = [[rootPath stringByAppendingString:@"/"] stringByAppendingString: filePathNew];
				filePathNew = [filePathNew stringByStandardizingPath];
				// add this to the array
				if (([manager fileExistsAtPath: filePathNew isDirectory:&isDir]) && (!isDir)) {
					[self.sourceFiles insertObject: filePathNew atIndex: currentIndex];
					currentIndex++;
				} else {
					filePath = [[rootPath stringByAppendingString:@"/"] stringByAppendingString: filePath];
					filePath = [filePath stringByStandardizingPath];
					// add this to the array
					if (([manager fileExistsAtPath: filePath isDirectory:&isDir]) && (!isDir)) {
						[self.sourceFiles insertObject: filePath atIndex: currentIndex];
						currentIndex++;
					}
				}
			}
		}
	}

	searchText = @"\\import{";
	done = NO;
	maskRange.location = 0;
	maskRange.length = sourceLength;

	while ((!done) && (maskRange.length > 0) && (currentIndex < NUMBER_OF_SOURCE_FILES)) {
		searchRange = [sourceText rangeOfString: searchText options:NSLiteralSearch range:maskRange];
		if (searchRange.location == NSNotFound)
			done = YES;
		else {
			maskRange.location = searchRange.location + 1;
			maskRange.length = sourceLength - maskRange.location;
			newSearchRange = [sourceText rangeOfString: @"}" options: NSLiteralSearch range:maskRange];
			if (newSearchRange.location == NSNotFound)
				done = YES;
			else {
				maskRange.location = newSearchRange.location + 1;
				maskRange.length = sourceLength - maskRange.location;
				fileRange.location = searchRange.location + [searchText length];
				fileRange.length = newSearchRange.location - fileRange.location;
				filePath = [sourceText substringWithRange: fileRange];
				// if ([[filePath pathExtension] length] == 0)
					filePath = [filePath stringByAppendingPathExtension: @"tex"];
				filePath = [[rootPath stringByAppendingString:@"/"] stringByAppendingString: filePath];
				filePath = [filePath stringByStandardizingPath];
				// add this to the array
				if (([manager fileExistsAtPath: filePath isDirectory:&isDir]) && (!isDir)) {
					[self.sourceFiles insertObject: filePath atIndex: currentIndex];
					currentIndex++;
				}
			}
		}
	}

// These last lines are for debugging only
//	int numberOfFiles = [sourceFiles count];
//	int	i;
//	for (i = 0; i < numberOfFiles; i++) {
//		NSLog([sourceFiles objectAtIndex:i]);
//		}

}

- (BOOL)doSyncTeX: (NSPoint) thePoint
{

/* // this section moved to TSDocument-SyncTeX

	myFileName = [self.myDocument fileName];
	if (! myFileName)
		return NO;
	mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex"];
	if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
		{
		return NO;
		}
	mySyncTeX = [[SUD stringForKey:TetexBinPath] stringByAppendingPathComponent: @"synctex"];
	if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeX])
		{
		return NO;
		} 
*/
		
		 
	NSPoint windowPosition = thePoint;
	NSPoint kitPosition = [self convertPoint: windowPosition fromView:nil];
	PDFPage *thePage = [self pageForPoint: kitPosition nearest:YES];
	if (thePage == NULL)
		return NO;
	NSRect pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
	NSPoint viewPosition = [self convertPoint: kitPosition toPage: thePage];
	NSInteger pageNumber = [[self document] indexForPage: thePage] + 1;
	CGFloat xCoordinate = viewPosition.x;
	CGFloat yOriginalCoordinate = viewPosition.y;
	CGFloat yCoordinate = pageSize.size.height - viewPosition.y;
	
	
	return [self.myDocument doSyncTeXForPage: pageNumber x: xCoordinate y: yCoordinate yOriginal: yOriginalCoordinate];
}


//-----------------------------

/*

- (BOOL)doNewSync: (NSPoint) thePoint
{
    return NO;
}
 
*/

//  This is the "old version" with variables upgraded to 64 bits;
//    should be the GOOD version.

 - (BOOL)doNewSync: (NSPoint) thePoint
 {
 NSInteger						theIndex;
 NSInteger						testIndex;
 NSInteger						pageNumber, numberOfTests;
 NSInteger						searchWindow;
 NSUInteger			sourcelength[NUMBER_OF_SOURCE_FILES + 1];
 NSInteger						startIndex, endIndex;
 NSRange					searchRange, newSearchRange, maskRange, theRange;
 NSString				*searchText;
 NSString				*sourceText[NUMBER_OF_SOURCE_FILES + 1];
 BOOL					found;
 NSInteger						length;
 NSInteger						numberOfFiles;
 NSInteger						i;
 BOOL					foundOne, foundMoreThanOne;
 NSInteger						foundIndex = 0;
 NSRange					foundRange = { 0, 0 };
 NSUInteger			foundlength = 0;
 NSRange					correctedFoundRange;
 TSDocument				*newDocument;
 NSTextView				*myTextView;
 NSWindow				*myTextWindow;
 NSDictionary			*mySelectedAttributes;
 NSMutableDictionary		*newSelectedAttributes;
 
 id						myData;
 NSStringEncoding		theEncoding;
 NSString				*firstBytes, *encodingString, *testString;
 NSRange					encodingRange, newEncodingRange, myRange, theRange1;
 NSUInteger				length1, start, end, irrelevant;
 BOOL					done;
 NSInteger						linesTested, offset;
 NSString				*aString;
 NSInteger						correction;
 
 
 
 NSPoint windowPosition = thePoint;
 NSPoint kitPosition = [self convertPoint: windowPosition fromView:nil];
 PDFPage *thePage = [self pageForPoint: kitPosition nearest:YES];
 if (thePage == NULL)
 return NO;
 NSPoint viewPosition = [self convertPoint: kitPosition toPage: thePage];
 pageNumber = [[self document] indexForPage: thePage];
 NSString *fullText = [thePage string];
 length = [fullText length];
 theIndex = [thePage characterIndexAtPoint:viewPosition];
 if (theIndex < 0)
 return NO;
 
 if (self.sourceFiles == nil)
 [self setupSourceFiles];
 numberOfFiles = [self.sourceFiles count];
 
 sourceText[0] = [[self.myDocument textView] string];
 sourcelength[0] = [sourceText[0] length];
 
 if (numberOfFiles > 0) {
 for (i = 0; i < numberOfFiles; i++) {
 
 theEncoding = [self.myDocument encoding];
 myData = [NSData dataWithContentsOfFile:[self.sourceFiles objectAtIndex:i]];
 
 // data in source
 firstBytes = [[NSString alloc] initWithData:myData encoding:NSMacOSRomanStringEncoding];
 length1 = [firstBytes length];
 done = NO;
 linesTested = 0;
 myRange.location = 0;
 myRange.length = 1;
 
 while ((myRange.location < length1) && (!done) && (linesTested < 20)) {
 [firstBytes getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
 myRange.location = end;
 myRange.length = 1;
 linesTested++;
 
 theRange1.location = start; theRange1.length = (end - start);
 testString = [firstBytes substringWithRange: theRange1];
 encodingRange = [testString rangeOfString:@"%!TEX encoding ="];
 offset = 16;
 if (encodingRange.location == NSNotFound) {
 encodingRange = [testString rangeOfString:@"% !TEX encoding ="];
 offset = 17;
 }
 if (encodingRange.location != NSNotFound) {
 done = YES;
 newEncodingRange.location = encodingRange.location + offset;
 newEncodingRange.length = [testString length] - newEncodingRange.location;
 if (newEncodingRange.length > 0) {
 encodingString = [[testString substringWithRange: newEncodingRange]
 stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
 theEncoding = [[TSEncodingSupport sharedInstance] stringEncodingForKey: encodingString];
 }
 } else if ([SUD boolForKey:UseOldHeadingCommandsKey]) {
 encodingRange = [testString rangeOfString:@"%&encoding="];
 if (encodingRange.location != NSNotFound) {
 done = YES;
 newEncodingRange.location = encodingRange.location + 11;
 newEncodingRange.length = [testString length] - newEncodingRange.location;
 if (newEncodingRange.length > 0) {
 encodingString = [[testString substringWithRange: newEncodingRange]
 stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
 theEncoding = [[TSEncodingSupport sharedInstance] stringEncodingForKey: encodingString];
 }
 }
 }
 }
 
// [firstBytes release];
 
 
 
 aString = [[NSString alloc] initWithData:myData encoding:theEncoding] ;
 if (! aString) {
 aString = [[NSString alloc] initWithData:myData encoding:NSMacOSRomanStringEncoding] ;
 }
 
 sourceText[i + 1] = aString;
 sourcelength[i + 1] = [sourceText[i + 1] length];
 }
 }
 
 found = NO;
 searchWindow = 10;
 testIndex = theIndex;
 numberOfTests = 1;
 
 while ((! found) && (numberOfTests < 20) && (testIndex >= 0)) {
 
 // get surrounding letters back and forward
 if (testIndex >= searchWindow)
 startIndex = testIndex - searchWindow;
 else
 startIndex = 0;
 if (testIndex < (length - (searchWindow + 1)))
 endIndex = testIndex + searchWindow;
 else
 endIndex = length - 1;
 
 myRange.location = startIndex;
 myRange.length = endIndex - startIndex;
 searchText = [fullText substringWithRange: myRange];
 testIndex = testIndex - 5;
 numberOfTests++;
 
 // search for this in the source
 
 foundOne = NO;
 foundMoreThanOne = NO;
 for (i = 0; i < numberOfFiles + 1; i++) {
 if (foundMoreThanOne)
 break;
 maskRange.location = 0;
 maskRange.length = sourcelength[i];
 searchRange = [sourceText[i] rangeOfString: searchText options:NSLiteralSearch range:maskRange];
 if (searchRange.location != NSNotFound) {
 maskRange.location = searchRange.location + searchRange.length;
 maskRange.length = sourcelength[i] - maskRange.location;
 newSearchRange = [sourceText[i] rangeOfString: searchText options: NSLiteralSearch range:maskRange];
 if (newSearchRange.location == NSNotFound) {
 if (foundOne)
 foundMoreThanOne = YES;
 foundOne = YES;
 foundIndex = i;
 foundlength = sourcelength[i];
 foundRange = searchRange;
 }
 }
 }
 if (foundOne && (!foundMoreThanOne)) {
 found = YES;
 if (foundIndex == 0) {
 myTextView = [self.myDocument textView];
 myTextWindow = [self.myDocument textWindow];
 [self.myDocument setTextSelectionYellow: YES];
 } else {
 newDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:[self.sourceFiles objectAtIndex:(foundIndex - 1)] display:YES];
 myTextView = [newDocument textView];
 myTextWindow = [newDocument textWindow];
 [newDocument setTextSelectionYellow: YES];
 }
 mySelectedAttributes = [myTextView selectedTextAttributes];
 newSelectedAttributes = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes];
 [newSelectedAttributes setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
 // FIXME: use temporary attributes instead of abusing the text selection
 [myTextView setSelectedTextAttributes: newSelectedAttributes];
 correction = theIndex - testIndex + 5;
 correctedFoundRange.location = foundRange.location + correction;
 correctedFoundRange.length = foundRange.length;
 if ((correction < 0) || (correctedFoundRange.location + correctedFoundRange.length) > foundlength)
 correctedFoundRange = foundRange;
 [myTextView setSelectedRange: correctedFoundRange];
 [myTextView scrollRangeToVisible: correctedFoundRange];
 [myTextWindow makeKeyAndOrderFront:self];
 return YES;
 }
 }
 
 testIndex = theIndex + 5;
 numberOfTests = 2;
 while ((! found) && (numberOfTests < 20) && (testIndex < length)) {
 
 // get surrounding letters back and forward
 if (testIndex > searchWindow)
 startIndex = testIndex - searchWindow;
 else
 startIndex = 0;
 if (testIndex < (length - (searchWindow + 1)))
 endIndex = testIndex + searchWindow;
 else
 endIndex = length - 1;
 
 theRange.location = startIndex;
 theRange.length = endIndex - startIndex;
 searchText = [fullText substringWithRange: myRange];
 testIndex = testIndex + 5;
 numberOfTests++;
 
 // search for this in the source
 // search for this in the source
 foundOne = NO;
 foundMoreThanOne = NO;
 for (i = 0; i < (numberOfFiles + 1); i++) {
 if (foundMoreThanOne)
 break;
 maskRange.location = 0;
 maskRange.length = sourcelength[i];
 searchRange = [sourceText[i] rangeOfString: searchText options:NSLiteralSearch range:maskRange];
 if (searchRange.location != NSNotFound) {
 maskRange.location = searchRange.location + searchRange.length;
 maskRange.length = sourcelength[i] - maskRange.location;
 newSearchRange = [sourceText[i] rangeOfString: searchText options: NSLiteralSearch range:maskRange];
 if (newSearchRange.location == NSNotFound) {
 if (foundOne)
 foundMoreThanOne = YES;
 foundOne = YES;
 foundIndex = i;
 foundlength = sourcelength[i];
 foundRange = searchRange;
 }
 }
 }
 if (foundOne && (!foundMoreThanOne)) {
 found = YES;
 if (foundIndex == 0) {
 myTextView = [self.myDocument textView];
 myTextWindow = [self.myDocument textWindow];
 } else {
 newDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:[self.sourceFiles objectAtIndex:(foundIndex - 1)] display:YES];
 myTextView = [newDocument textView];
 myTextWindow = [newDocument textWindow];
 }
 mySelectedAttributes = [myTextView selectedTextAttributes];
 newSelectedAttributes = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes];
 [newSelectedAttributes setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
 // FIXME: use temporary attributes instead of abusing the text selection
 [myTextView setSelectedTextAttributes: newSelectedAttributes];
 correction = testIndex - theIndex - 10;
 if ((correction < 0) || (foundRange.location < correction))
 correctedFoundRange = foundRange;
 else {
 correctedFoundRange.location = foundRange.location - correction;
 correctedFoundRange.length = foundRange.length;
 }
 [myTextView setSelectedRange: correctedFoundRange];
 [myTextView scrollRangeToVisible: correctedFoundRange];
 [myTextWindow makeKeyAndOrderFront:self];
 return YES;
 }
 }
 
 return NO;
 
 }
 

//


//-----------------------------------------------------

/*
- (BOOL)doNewSync: (NSPoint) thePoint
{
	NSInteger				theIndex;
	NSInteger				testIndex;
	NSInteger				pageNumber, numberOfTests;
	NSInteger				searchWindow;
	NSUInteger              sourcelength[NUMBER_OF_SOURCE_FILES + 1];
	NSInteger				startIndex, endIndex;
	NSRange					searchRange, newSearchRange, maskRange, theRange;
	NSString				*searchText;
	NSString				*sourceText[NUMBER_OF_SOURCE_FILES + 1];
	BOOL					found;
	NSInteger				length;
	NSInteger				numberOfFiles;
	NSInteger				i;
	BOOL					foundOne, foundMoreThanOne;
	NSInteger				foundIndex = 0;
	NSRange					foundRange = { 0, 0 };
	NSUInteger              foundlength = 0;
	NSRange					correctedFoundRange;
	NSTextView				*myTextView;
	NSWindow				*myTextWindow;
	NSDictionary			*mySelectedAttributes;
	NSMutableDictionary		*newSelectedAttributes;
    
	id						myData;
	NSStringEncoding		theEncoding;
	NSString				*firstBytes, *encodingString, *testString;
	NSRange					encodingRange, newEncodingRange, myRange, theRange1;
	NSUInteger				length1, start, end, irrelevant;
	BOOL					done;
	NSInteger				linesTested, offset;
	NSString				*aString;
	NSInteger				correction = 0;
    
// This routine causes hangs in version 3. Since it is old fashioned and no longer needed,
// we temporarily comment it out. For most people who picked the modern SyncTeX, the only
// effect will be that when that method doesn't find a match, it will not call Search TeX
// and possibly hang. The slightly bigger problem is that some users misconfigured their
// machines, disabling SyncTeX. They think they are using it, but they aren't. After this
// fix, they won't sync at all.
    
    return NO;
    
// end of fig
    
    
	NSPoint windowPosition = thePoint;
	NSPoint kitPosition = [self convertPoint: windowPosition fromView:nil];
	PDFPage *thePage = [self pageForPoint: kitPosition nearest:YES];
	if (thePage == NULL)
		return NO;
	NSPoint viewPosition = [self convertPoint: kitPosition toPage: thePage];
	pageNumber = [[self document] indexForPage: thePage];
	NSString *fullText = [thePage string];
	length = [fullText length];
	theIndex = [thePage characterIndexAtPoint:viewPosition];
	if (theIndex < 0)
		return NO;
	
	if (sourceFiles == nil)
		[self setupSourceFiles];
	numberOfFiles = [sourceFiles count];
    
	sourceText[0] = [[self.myDocument textView] string];
	sourcelength[0] = [sourceText[0] length];
    
	if (numberOfFiles > 0) {
		for (i = 0; i < numberOfFiles; i++) {
            
			theEncoding = [self.myDocument encoding];
			myData = [NSData dataWithContentsOfFile:[sourceFiles objectAtIndex:i]];
            
			// data in source
			firstBytes = [[NSString alloc] initWithData:myData encoding:NSISOLatin9StringEncoding];
			length1 = [firstBytes length];
			done = NO;
			linesTested = 0;
			myRange.location = 0;
			myRange.length = 1;
            
			while ((myRange.location < length1) && (!done) && (linesTested < 20)) {
				[firstBytes getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
				myRange.location = end;
				myRange.length = 1;
				linesTested++;
                
				theRange1.location = start; theRange1.length = (end - start);
				testString = [firstBytes substringWithRange: theRange1];
				encodingRange = [testString rangeOfString:@"%!TEX encoding ="];
				offset = 16;
				if (encodingRange.location == NSNotFound) {
					encodingRange = [testString rangeOfString:@"% !TEX encoding ="];
					offset = 17;
                }
				if (encodingRange.location != NSNotFound) {
					done = YES;
					newEncodingRange.location = encodingRange.location + offset;
					newEncodingRange.length = [testString length] - newEncodingRange.location;
					if (newEncodingRange.length > 0) {
						encodingString = [[testString substringWithRange: newEncodingRange]
                                          stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
						theEncoding = [[TSEncodingSupport sharedInstance] stringEncodingForKey: encodingString];
					}
				} else if ([SUD boolForKey:UseOldHeadingCommandsKey]) {
					encodingRange = [testString rangeOfString:@"%&encoding="];
					if (encodingRange.location != NSNotFound) {
						done = YES;
						newEncodingRange.location = encodingRange.location + 11;
						newEncodingRange.length = [testString length] - newEncodingRange.location;
						if (newEncodingRange.length > 0) {
							encodingString = [[testString substringWithRange: newEncodingRange]
                                              stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
							theEncoding = [[TSEncodingSupport sharedInstance] stringEncodingForKey: encodingString];
						}
					}
				}
			}
            
			[firstBytes release];
            
            
            
			aString = [[[NSString alloc] initWithData:myData encoding:theEncoding] autorelease];
			if (! aString) {
				aString = [[[NSString alloc] initWithData:myData encoding:NSISOLatin9StringEncoding] autorelease];
			}
            
			sourceText[i + 1] = aString;
			sourcelength[i + 1] = [sourceText[i + 1] length];
		}
	}
    
	found = NO;
	searchWindow = 10;
	testIndex = theIndex;
	numberOfTests = 1;
    
	while ((! found) && (numberOfTests < 20) && (testIndex >= 0)) {
        
		// get surrounding letters back and forward
		if (testIndex >= searchWindow)
			startIndex = testIndex - searchWindow;
		else
			startIndex = 0;
		if (testIndex < (length - (searchWindow + 1)))
			endIndex = testIndex + searchWindow;
		else
			endIndex = length - 1;
        
		myRange.location = startIndex;
		myRange.length = endIndex - startIndex;
		searchText = [fullText substringWithRange: myRange];
		testIndex = testIndex - 5;
		numberOfTests++;
        
		// search for this in the source
        
		foundOne = NO;
		foundMoreThanOne = NO;
		for (i = 0; i < numberOfFiles + 1; i++) {
			if (foundMoreThanOne)
				break;
			maskRange.location = 0;
			maskRange.length = sourcelength[i];
			searchRange = [sourceText[i] rangeOfString: searchText options:NSLiteralSearch range:maskRange];
			if (searchRange.location != NSNotFound) {
				maskRange.location = searchRange.location + searchRange.length;
				maskRange.length = sourcelength[i] - maskRange.location;
				newSearchRange = [sourceText[i] rangeOfString: searchText options: NSLiteralSearch range:maskRange];
				if (newSearchRange.location == NSNotFound) {
					if (foundOne)
						foundMoreThanOne = YES;
					foundOne = YES;
					foundIndex = i;
					foundlength = sourcelength[i];
					foundRange = searchRange;
				}
			}
		}
		if (foundOne && (!foundMoreThanOne)) {
			found = YES;
			if (foundIndex == 0) {
				myTextView = [self.myDocument textView];
				myTextWindow = [self.myDocument textWindow];
				[self.myDocument setTextSelectionYellow: YES];
                mySelectedAttributes = [myTextView selectedTextAttributes];
                newSelectedAttributes = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes];
                [newSelectedAttributes setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
                // FIXME: use temporary attributes instead of abusing the text selection
                [myTextView setSelectedTextAttributes: newSelectedAttributes];
                correction = theIndex - testIndex + 5;
                correctedFoundRange.location = foundRange.location + correction;
                correctedFoundRange.length = foundRange.length;
                if ((correction < 0) || (correctedFoundRange.location + correctedFoundRange.length) > foundlength)
                    correctedFoundRange = foundRange;
                [myTextView setSelectedRange: correctedFoundRange];
                [myTextView scrollRangeToVisible: correctedFoundRange];
                [myTextWindow makeKeyAndOrderFront:self];
                return YES;
			} else {
				// newDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:[sourceFiles objectAtIndex:(foundIndex - 1)] display:YES];
                [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL: [NSURL fileURLWithPath: [sourceFiles objectAtIndex:(foundIndex - 1)]] display:YES
                                                                             completionHandler: ^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error)
                 {
                     if (document) {
                         NSTextView *myTextView1 = [(TSDocument *)document textView];
                         NSWindow *myTextWindow1 = [(TSDocument *)document textWindow];
                         [(TSDocument *)document setTextSelectionYellow: YES];
                         NSDictionary *mySelectedAttributes1 = [myTextView1 selectedTextAttributes];
                         NSMutableDictionary *newSelectedAttributes1 = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes1];
                         [newSelectedAttributes1 setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
                         // FIXME: use temporary attributes instead of abusing the text selection
                         [myTextView1 setSelectedTextAttributes: newSelectedAttributes1];
                         NSInteger correction1 = theIndex - testIndex + 5;
                         NSRange correctedFoundRange1;
                         correctedFoundRange1.location = foundRange.location + correction1;
                         correctedFoundRange1.length = foundRange.length;
                         if ((correction1 < 0) || (correctedFoundRange1.location + correctedFoundRange1.length) > foundlength)
                             correctedFoundRange1 = foundRange;
                         [myTextView1 setSelectedRange: correctedFoundRange1];
                         [myTextView1 scrollRangeToVisible: correctedFoundRange1];
                         [myTextWindow1 makeKeyAndOrderFront:self];
                        }
                 }];
                // WARNING: Next was commented out
                // newDocument = (TSDocument *)returnDocument;
                // // newDocument = [[NSDocumentController sharedDocumentController] currentDocument];
                // myTextView = [newDocument textView];
                // myTextWindow = [newDocument textWindow];
                // [newDocument setTextSelectionYellow: YES];
                // }
                // mySelectedAttributes = [myTextView selectedTextAttributes];
                 // newSelectedAttributes = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes];
                // [newSelectedAttributes setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
                 // // FIXME: use temporary attributes instead of abusing the text selection
                // [myTextView setSelectedTextAttributes: newSelectedAttributes];
                // correction = theIndex - testIndex + 5;
                // correctedFoundRange.location = foundRange.location + correction;
                // correctedFoundRange.length = foundRange.length;
                // if ((correction < 0) || (correctedFoundRange.location + correctedFoundRange.length) > foundlength)
                // correctedFoundRange = foundRange;
                // [myTextView setSelectedRange: correctedFoundRange];
                // [myTextView scrollRangeToVisible: correctedFoundRange];
                // [myTextWindow makeKeyAndOrderFront:self];
                // END OF COMMENT
                return YES;
            }
        }
        
        testIndex = theIndex + 5;
        numberOfTests = 2;
        while ((! found) && (numberOfTests < 20) && (testIndex < length)) {
            
            // get surrounding letters back and forward
            if (testIndex > searchWindow)
                startIndex = testIndex - searchWindow;
            else
                startIndex = 0;
            if (testIndex < (length - (searchWindow + 1)))
                endIndex = testIndex + searchWindow;
            else
                endIndex = length - 1;
            
            theRange.location = startIndex;
            theRange.length = endIndex - startIndex;
            searchText = [fullText substringWithRange: myRange];
            testIndex = testIndex + 5;
            numberOfTests++;
            
            // search for this in the source
            // search for this in the source
            foundOne = NO;
            foundMoreThanOne = NO;
            for (i = 0; i < (numberOfFiles + 1); i++) {
                if (foundMoreThanOne)
                    break;
                maskRange.location = 0;
                maskRange.length = sourcelength[i];
                searchRange = [sourceText[i] rangeOfString: searchText options:NSLiteralSearch range:maskRange];
                if (searchRange.location != NSNotFound) {
                    maskRange.location = searchRange.location + searchRange.length;
                    maskRange.length = sourcelength[i] - maskRange.location;
                    newSearchRange = [sourceText[i] rangeOfString: searchText options: NSLiteralSearch range:maskRange];
                    if (newSearchRange.location == NSNotFound) {
                        if (foundOne)
                            foundMoreThanOne = YES;
                        foundOne = YES;
                        foundIndex = i;
                        foundlength = sourcelength[i];
                        foundRange = searchRange;
                    }
                }
            }
            if (foundOne && (!foundMoreThanOne)) {
                found = YES;
                if (foundIndex == 0) {
                    myTextView = [self.myDocument textView];
                    myTextWindow = [self.myDocument textWindow];
                    mySelectedAttributes = [myTextView selectedTextAttributes];
                    newSelectedAttributes = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes];
                    [newSelectedAttributes setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
                    // FIXME: use temporary attributes instead of abusing the text selection
                    [myTextView setSelectedTextAttributes: newSelectedAttributes];
                    correction = testIndex - theIndex - 10;
                    if ((correction < 0) || (foundRange.location < correction))
                        correctedFoundRange = foundRange;
                    else {
                        correctedFoundRange.location = foundRange.location - correction;
                        correctedFoundRange.length = foundRange.length;
                    }
                    [myTextView setSelectedRange: correctedFoundRange];
                    [myTextView scrollRangeToVisible: correctedFoundRange];
                    [myTextWindow makeKeyAndOrderFront:self];
                    return YES;
                } else {
                    // newDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:[sourceFiles objectAtIndex:(foundIndex - 1)] display:YES];
                    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL: [NSURL fileURLWithPath: [sourceFiles objectAtIndex:(foundIndex - 1)]] display:YES
                                                                                 completionHandler: ^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error)
                     {
                         if (document) {
                             NSTextView *myTextView1 = [(TSDocument *)document textView];
                             NSWindow *myTextWindow1 = [(TSDocument *)document textWindow];
                             [(TSDocument *)document setTextSelectionYellow: YES];
                             NSDictionary *mySelectedAttributes1 = [myTextView1 selectedTextAttributes];
                             NSMutableDictionary *newSelectedAttributes1 = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes1];
                             [newSelectedAttributes1 setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
                             // FIXME: use temporary attributes instead of abusing the text selection
                             [myTextView1 setSelectedTextAttributes: newSelectedAttributes1];
                             NSInteger correction1 = theIndex - testIndex - 10;
                             NSRange correctedFoundRange1;
                         
                             correctedFoundRange1.location = foundRange.location + correction1;
                             correctedFoundRange1.length = foundRange.length;
                         
                             if ((correction1 < 0) || (foundRange.location < correction))
                                 correctedFoundRange1 = foundRange;
                             else {
                                 correctedFoundRange1.location = foundRange.location - correction;
                                 correctedFoundRange1.length = foundRange.length;
                             }
                             [myTextView1 setSelectedRange: correctedFoundRange1];
                             [myTextView1 scrollRangeToVisible: correctedFoundRange1];
                             [myTextWindow1 makeKeyAndOrderFront:self];
                            }
                     }];
                    return YES;
                }
            }
            
            // WARNING Next was commented out
             // newDocument = (TSDocument *)returnDocument;
             // // newDocument = [[NSDocumentController sharedDocumentController] currentDocument];
            //  myTextView = [newDocument textView];
            //  myTextWindow = [newDocument textWindow];
            //  }
            //  mySelectedAttributes = [myTextView selectedTextAttributes];
            //  newSelectedAttributes = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes];
             // [newSelectedAttributes setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
            //  // FIXME: use temporary attributes instead of abusing the text selection
            //  [myTextView setSelectedTextAttributes: newSelectedAttributes];
            //  correction = testIndex - theIndex - 10;
            //  if ((correction < 0) || (foundRange.location < correction))
            //  correctedFoundRange = foundRange;
            //  else {
            //  correctedFoundRange.location = foundRange.location - correction;
            //  correctedFoundRange.length = foundRange.length;
            //  }
            //  [myTextView setSelectedRange: correctedFoundRange];
            //  [myTextView scrollRangeToVisible: correctedFoundRange];
            //  [myTextWindow makeKeyAndOrderFront:self];
            //  return YES;
             // END OF WARNING
		}
	}
    
	return NO;
    
}
*/


// TODO: This method is way too big and should be split up / simplified
- (void)doSync: (NSPoint)thePoint
{
	NSFileManager	*fileManager;
	NSNumber        *thePageNumber;
	NSString        *syncInfo, *pageSearchString, *valueString;
	NSString        *searchString;
	NSString        *searchOpenString, *searchCloseString;
	NSRange         searchOpenRange, searchCloseRange, myRange;
	NSRange         searchOpenResultRange, searchCloseResultRange;
	NSRange         searchRange, searchResultRange;
	NSRange         smallerRange;
	NSString        *includeFileName;
	NSString        *keyLine;
	NSInteger       pageNumber;
	NSRange         pageRangeStart;
	NSRange         pageRangeEnd;
	NSRange         remainingRange;
	NSRange         thisRange, newRange, foundRange;
	NSNumber        *anotherNumber;
	NSInteger             aNumber;
	NSInteger             syncNumber, oldSyncNumber, x, oldx, y, oldy;
	BOOL            found;
	NSUInteger        theStart, theEnd, theContentsEnd;
	NSString        *newFileName, *theExtension;
	NSUInteger        start, end, irrelevant;
	BOOL			result;
    NSStringEncoding      theEncoding;
	
	NSInteger syncMethod = [SUD integerForKey:SyncMethodKey];
	
	if (syncMethod == SYNCTEXFIRST) {
		result = [self doSyncTeX: thePoint];
		if ((result) || ([SUD boolForKey: SyncTeXOnlyKey]))
			return;
		else
			syncMethod = SEARCHONLY;
		}
	
	
	if ((syncMethod == SEARCHONLY) || (syncMethod == SEARCHFIRST)) {
		result = [self doNewSync: thePoint];
		if (result)
			return;
	}
	if (syncMethod == SEARCHONLY)
		return;
	
	includeFileName = nil;
	
	// The code below finds the page number, and the position of the click
	// in view coordinates.
	
	NSPoint windowPosition = thePoint;
	NSPoint kitPosition = [self convertPoint: windowPosition fromView:nil];
	PDFPage *thePage = [self pageForPoint: kitPosition nearest:YES];
	if (thePage == NULL)
		return;
	NSPoint viewPosition = [self convertPoint: kitPosition toPage: thePage];
	pageNumber = [[self document] indexForPage: thePage];
	/*
	 if (pageStyle == PDF_SINGLE_PAGE_STYLE)
	 pageNumber = [myRep currentPage];
	 else {
		 pageNumber = [self pageNumberForPoint:viewPosition];
		 NSPoint originPoint = [self pointForPage: pageNumber];
		 viewPosition.x = viewPosition.x - originPoint.x;
		 viewPosition.y = viewPosition.y - originPoint.y;
		 if (viewPosition.x < 0)
			 viewPosition.x = 0;
		 if (viewPosition.y < 0)
			 viewPosition.y = 0;
	 }
	 */
	
	pageNumber++;
	
	// logInt = viewPosition.x;
	// logNumber = [NSNumber numberWithInt: logInt];
	// NSLog([logNumber stringValue]);
	
	// logInt = viewPosition.y;
	// logNumber = [NSNumber numberWithInt: logInt];
	// NSLog([logNumber stringValue]);
	
	// now convert to pdf coordinates
	NSInteger tempY = viewPosition.y - 14;
	// int yValue = viewPosition.y * 65536;
	NSInteger yValue = tempY * 65536;
	
	// now see if the sync file exists
	fileManager = [NSFileManager defaultManager];
	NSString *fileName = [self.myDocument fileName];
	NSString *infoFile = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"pdfsync"];
	if (![fileManager fileExistsAtPath: infoFile])
		return;
	
	/*
	 // worry that the user has tex + ghostscript and the sync file is out of date
	 // to do that, test the date of mydoc.pdf and mydoc.pdfsync
	 NSString *pdfName = [[fileName stringByDeletingPathExtension] stringByAppendingString: @".pdf"];
	 NSDictionary *fattrs = [fileManager fileAttributesAtPath: pdfName traverseLink:NO];
	 pdfDate = [fattrs objectForKey:NSFileModificationDate];
	 fattrs = [fileManager fileAttributesAtPath: infoFile traverseLink:NO];
	 pdfsyncDate = [fattrs objectForKey:NSFileModificationDate];
	 if ([pdfDate timeIntervalSince1970] > [pdfsyncDate timeIntervalSince1970])
	 return;
	 */
	
	// get the contents of the sync file as a string
	NS_DURING
    syncInfo = [NSString stringWithContentsOfFile:infoFile usedEncoding: &theEncoding error:NULL];
	NS_HANDLER
		return;
	NS_ENDHANDLER
	
	if (! syncInfo)
		return;
	
	// remove the first two lines
	myRange.location = 0;
	myRange.length = 1;
	NS_DURING
		[syncInfo getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
	NS_HANDLER
		return;
	NS_ENDHANDLER
	syncInfo = [syncInfo substringFromIndex: end];
	NS_DURING
		[syncInfo getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
	NS_HANDLER
		return;
	NS_ENDHANDLER
	syncInfo = [syncInfo substringFromIndex: end];
	
	// find the page number in syncInfo and return if it is not there
	thePageNumber = [NSNumber numberWithInteger:pageNumber];
	pageSearchString = [@"s " stringByAppendingString: [thePageNumber stringValue]];
	pageRangeStart = [syncInfo rangeOfString: pageSearchString];
	if (pageRangeStart.location == NSNotFound)
		return;
	[syncInfo getLineStart: &start end: &end contentsEnd: &irrelevant forRange: pageRangeStart];
	if (pageRangeStart.location != start)
		return;
	
	////////////////////////////////////
	
	// Search backward to the previous page number, if one exists
	// Search forward to the next page number, if one exists
	// Replace syncInfo by the information between these two numbers
	pageNumber = pageNumber - 1;
	thePageNumber = [NSNumber numberWithInteger:pageNumber];
	pageSearchString = [@"s " stringByAppendingString: [thePageNumber stringValue]];
	pageRangeStart = [syncInfo rangeOfString: pageSearchString];
	if (pageRangeStart.location != NSNotFound) {
		smallerRange.location = pageRangeStart.location;
		smallerRange.length = [syncInfo length] - pageRangeStart.location;
		NS_DURING
			syncInfo = [syncInfo substringWithRange: smallerRange];
		NS_HANDLER
			return;
		NS_ENDHANDLER
	}
	pageNumber = pageNumber + 2;
	thePageNumber = [NSNumber numberWithInteger:pageNumber];
	pageSearchString = [@"s " stringByAppendingString: [thePageNumber stringValue]];
	pageRangeEnd = [syncInfo rangeOfString: pageSearchString];
	if (pageRangeEnd.location != NSNotFound) {
		smallerRange.location = 0;
		smallerRange.length = pageRangeEnd.location;
		NS_DURING
			syncInfo = [syncInfo substringWithRange: smallerRange];
		NS_HANDLER
			return;
		NS_ENDHANDLER
	}
	
	// Search backwards to any line starting with "p ". Remove this first stuff.
	// Ignore lines beginning with "p* ".
	pageNumber = pageNumber - 1;
	thePageNumber = [NSNumber numberWithInteger:pageNumber];
	pageSearchString = [@"s " stringByAppendingString: [thePageNumber stringValue]];
	pageRangeStart = [syncInfo rangeOfString: pageSearchString];
	
	if (pageRangeStart.location == NSNotFound)
		return;
	[syncInfo getLineStart: &start end: &end contentsEnd: &irrelevant forRange: pageRangeStart];
	if (pageRangeStart.location != start)
		return;
	
	searchString = @"p ";
	searchRange.location = 0; searchRange.length = pageRangeStart.location;
	
	searchResultRange = [syncInfo rangeOfString: searchString options:NSBackwardsSearch range: searchRange];
	if (!(searchResultRange.location == NSNotFound)) {
		NS_DURING
			[syncInfo getLineStart: &theStart end: &theEnd contentsEnd: nil forRange: searchResultRange];
		NS_HANDLER
			return;
		NS_ENDHANDLER
		if (theStart != searchResultRange.location)
			return;
		smallerRange.location = theEnd;
		smallerRange.length = [syncInfo length] - theEnd;
		NS_DURING
			syncInfo = [syncInfo substringWithRange: smallerRange];
		NS_HANDLER
			return;
		NS_ENDHANDLER
	}
	
	// Now syncInfo contains exactly the required information for the given page
	// and nothing more. (Also if includeFileName is not nil, it contains the name
	// of the include file being examined --- NOT NOW)
	
	// Search  for "p 15 683402 6834958" to find the first
	// element whose y-coordinate is lower than the y-coordinate of the click
	// Back up one element and use the first number to find the corresponding
	// line number; select that line
	
	found = YES;
	syncNumber = -1;
	x = 0; y = 0;
	remainingRange.location = 0;
	remainingRange.length = [syncInfo length];
	do {
		oldSyncNumber = syncNumber;
		oldx = x; oldy = y;
		searchResultRange = [syncInfo rangeOfString: @"p " options: NSLiteralSearch range: remainingRange];
		if (searchResultRange.location == NSNotFound)
		{found = NO; break;}
		
		NS_DURING
			[syncInfo getLineStart: &theStart end: &theEnd contentsEnd: nil forRange: searchResultRange];
		NS_HANDLER
			return;
		NS_ENDHANDLER
		remainingRange.location = theEnd + 1;
		remainingRange.length = [syncInfo length] - remainingRange.location;
		if (theStart == searchResultRange.location) {
			
			
			newRange.location = theStart;
			newRange.length = theEnd - theStart;
			NS_DURING
				keyLine = [syncInfo substringWithRange: newRange];
			NS_HANDLER
				return;
			NS_ENDHANDLER
			
			searchResultRange = [keyLine rangeOfCharacterFromSet: [NSCharacterSet decimalDigitCharacterSet]];
			newRange.location = searchResultRange.location;
			newRange.length = [keyLine length] - newRange.location;
			NS_DURING
				keyLine = [keyLine substringWithRange: newRange];
			NS_HANDLER
				return;
			NS_ENDHANDLER
			syncNumber = [keyLine integerValue]; // number of entry
			
			searchResultRange = [keyLine rangeOfString: @" "];
			if (searchResultRange.location == NSNotFound)
				return;
			newRange.location = searchResultRange.location;
			newRange.length = [keyLine length] - newRange.location;
			NS_DURING
				keyLine = [keyLine substringWithRange: newRange];
			NS_HANDLER
				return;
			NS_ENDHANDLER
			searchResultRange = [keyLine rangeOfCharacterFromSet: [NSCharacterSet decimalDigitCharacterSet]];
			newRange.location = searchResultRange.location;
			newRange.length = [keyLine length] - newRange.location;
			NS_DURING
				keyLine = [keyLine substringWithRange: newRange];
			NS_HANDLER
				return;
			NS_ENDHANDLER
			x = [keyLine integerValue];
			
			searchResultRange = [keyLine rangeOfString: @" "];
			if (searchResultRange.location == NSNotFound)
				return;
			newRange.location = searchResultRange.location;
			newRange.length = [keyLine length] - newRange.location;
			NS_DURING
				keyLine = [keyLine substringWithRange: newRange];
			NS_HANDLER
				return;
			NS_ENDHANDLER
			y = [keyLine integerValue];
		}
	}
	while (found && (y > yValue));
	
	if ((oldSyncNumber < 0) && (syncNumber < 0))
		return;
	
	if (oldSyncNumber < 0)
		oldSyncNumber = syncNumber;
	
	anotherNumber = [NSNumber numberWithInteger:oldSyncNumber];
	pageSearchString = [@"l " stringByAppendingString: [anotherNumber stringValue]];
	/*
	 pageRangeStart = [syncInfo rangeOfString: pageSearchString];
	 if (pageRangeStart.location == NSNotFound) {
		 syncInfo = [NSString stringWithContentsOfFile:infoFile];
		 pageRangeStart = [syncInfo rangeOfString: pageSearchString];
	 }
	 */
	syncInfo = [NSString stringWithContentsOfFile:infoFile usedEncoding: &theEncoding error:NULL];

	pageRangeStart = [syncInfo rangeOfString: pageSearchString];
	NS_DURING
		[syncInfo getLineStart: &theStart end: &theEnd contentsEnd: nil forRange: pageRangeStart];
	NS_HANDLER
		return;
	NS_ENDHANDLER
	newRange.location = theStart;
	newRange.length = (theEnd - theStart);
	foundRange.location = newRange.location;
	foundRange.length = newRange.length;
	thisRange = [syncInfo rangeOfString: @" " options: NSLiteralSearch range: newRange];
	newRange.location = thisRange.location + 1;
	newRange.length = theEnd - newRange.location;
	thisRange = [syncInfo rangeOfString: @" " options: NSLiteralSearch range: newRange];
	newRange.location = thisRange.location + 1;
	newRange.length = theEnd - newRange.location;
	NS_DURING
		valueString = [syncInfo substringWithRange: newRange];
	NS_HANDLER
		return;
	NS_ENDHANDLER
	
	aNumber = [valueString integerValue];
	
	// at this point, we know the line number containing the click, but we must still find the
	// name of the file which contains that line. So we search backward from found range, for
	// ( without a matching later ). If we found one, then it will give the name of the
	// file. Otherwise the file is the current file.
	
	NSRange         lineRange, oneLineRange;
	NSString        *theLine, *theFile;
	NSMutableArray  *theStack;
	NSInteger             stackPointer;
	
	searchCloseString = @")";
	searchOpenString = @"(";
	
	theStack = [NSMutableArray arrayWithCapacity: 10];
	stackPointer = -1;
	
	lineRange.location = 0;
	lineRange.length = 1;
	while (lineRange.location <= foundRange.location) {
		
		searchCloseRange.location = lineRange.location; searchCloseRange.length = foundRange.location - lineRange.location;
		searchCloseResultRange = [syncInfo rangeOfString: searchCloseString options:0 range: searchCloseRange];
		searchOpenRange.location = lineRange.location; searchOpenRange.length = foundRange.location - lineRange.location;
		searchOpenResultRange = [syncInfo rangeOfString: searchOpenString options:0 range: searchOpenRange];
		if ((searchOpenResultRange.location == NSNotFound) && (searchCloseResultRange.location == NSNotFound))
			break;
		else if (searchOpenResultRange.location == NSNotFound)
			lineRange.location = searchCloseResultRange.location;
		else if (searchCloseResultRange.location == NSNotFound)
			lineRange.location = searchOpenResultRange.location;
		else if (searchOpenResultRange.location <= searchCloseResultRange.location)
			lineRange.location = searchOpenResultRange.location;
		else
			lineRange.location = searchCloseResultRange.location;
		
		NS_DURING
			[syncInfo getLineStart: &theStart end: &theEnd contentsEnd: &theContentsEnd forRange: lineRange];
		NS_HANDLER
			return;
		NS_ENDHANDLER
		
		lineRange.location = theEnd;
		oneLineRange.location = theStart;
		oneLineRange.length = theContentsEnd - theStart;
		if (oneLineRange.length >= 1) {
			theLine = [syncInfo substringWithRange: oneLineRange];
			if ([theLine characterAtIndex:0] == '(') {
				stackPointer++;
				oneLineRange.location++;
				oneLineRange.length--;
				if (oneLineRange.length > 0) {
					theFile = [syncInfo substringWithRange: oneLineRange];
					[theStack insertObject:theFile atIndex: stackPointer];
				}
			} else if ([theLine characterAtIndex:0] == ')') {
				if (stackPointer >= 0)
					stackPointer--;
			}
			
		}
	}
	
	includeFileName = nil;
	if (stackPointer >= 0)
		includeFileName = [theStack objectAtIndex: stackPointer];
	
	if (includeFileName == nil) {
		[self.myDocument toLine:aNumber];
		[[self.myDocument  textWindow] makeKeyAndOrderFront:self];
	} else {
		newFileName = [[[self.myDocument fileName] stringByDeletingLastPathComponent] stringByAppendingString:@"/"];
		newFileName = [newFileName stringByAppendingString: includeFileName];
		theExtension = [newFileName pathExtension];
		if ([theExtension length] == 0)
			includeFileName = [[newFileName stringByStandardizingPath] stringByAppendingPathExtension: @"tex"];
		else
			includeFileName = [newFileName stringByStandardizingPath];
            // newDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:includeFileName display:YES];
            [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL: [NSURL fileURLWithPath: includeFileName] display:YES
                    completionHandler: ^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error)
                                    {
                                        [(TSDocument *)document toLine:aNumber];
                                        [[(TSDocument *)document textWindow] makeKeyAndOrderFront:self];
                                    }];
       
	}
}



// Magnifying Glass:
// new routine uses NSWindow's caching mechanisim
//		this is done by calling cacheImageInRect, restoreCachedImage, discardCachedImage
// this seems to be faster and the trace is cleaner because it completely redraws
// level:	1=normal (150x100), 2=large (380x250). 3>=whole window
// 		specify the starting level (size) of magnifying glass according to currentMouseMode
// 		or (clickCount and mouseMode).
//		then the level can be incremented by double or more click and/or option key.
//		for example, if mouseMode is not magnifying glass, a quadruple click or
//		(a triple click and option key) gives you the whole window.  Well, this isn't
//		a recommended way to use it, but you get an idea.
// magScale
//		default magScale is 0.4 which is 250%
//		command key sets magScale to 0.25 (400%)
//		control ket sets magScale to 0.66666 (150%)
//		you may combine shift key to shrink


- (void)drawDotsForPage:(NSInteger)page atPoint: (NSPoint)p
{
		NSFileManager	*fileManager;
		NSInteger             pageNumber;
		NSNumber        *thePageNumber;
		NSString         *syncInfo, *pageSearchString, *keyLine;
		NSRange         pageRangeStart, myRange;
		NSRange         pageRangeEnd, smallerRange;
		NSRange         remainingRange, searchResultRange;
		NSRange         newRange;
		NSInteger             syncNumber, x, y;
		NSUInteger        theStart, theEnd;
		double          newx, newy;
		NSRect          smallRect;
		NSColor         *backColor;
		NSUInteger        start, end, irrelevant;
        NSStringEncoding theEncoding;

// BUG: This causes a crash if NSDocument is being closed and the pdf window needs to be redrawn
//	if (! [self.myDocument syncState])
//	 	return;
	
	if (! showSync)
		return;

	pageNumber = page + 1;

	// now convert to pdf coordinates
	// int yValue = viewPosition.y * 65536;

	// now see if the sync file exists
	fileManager = [NSFileManager defaultManager];
	NSString *fileName = [self.myDocument fileName];
	NSString *infoFile = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"pdfsync"];
	if (![fileManager fileExistsAtPath: infoFile])
		return;

	// get the contents of the sync file as a string
	NS_DURING
    syncInfo = [NSString stringWithContentsOfFile:infoFile usedEncoding: &theEncoding error:NULL];

	NS_HANDLER
		return;
	NS_ENDHANDLER

	// throw away the first two lines


	if (! syncInfo)
		return;

	// remove the first two lines
	myRange.location = 0;
	myRange.length = 1;
	NS_DURING
	[syncInfo getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
	NS_HANDLER
	return;
	NS_ENDHANDLER
	syncInfo = [syncInfo substringFromIndex: end];
	NS_DURING
	[syncInfo getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
	NS_HANDLER
	return;
	NS_ENDHANDLER
	syncInfo = [syncInfo substringFromIndex: end];


	// find the page number in syncInfo and return if it is not there
	thePageNumber = [NSNumber numberWithInteger:pageNumber];
	pageSearchString = [@"s " stringByAppendingString: [thePageNumber stringValue]];
	pageRangeStart = [syncInfo rangeOfString: pageSearchString];
	if (pageRangeStart.location == NSNotFound)
		return;
	[syncInfo getLineStart: &start end: &end contentsEnd: &irrelevant forRange: pageRangeStart];
	if (pageRangeStart.location != start) {
		return;
		}

	// Search forward to the next page number, if one exists
	// Replace syncInfo by the information between these two numbers
	smallerRange.location = pageRangeStart.location;
	smallerRange.length = [syncInfo length] - pageRangeStart.location;
	NS_DURING
	syncInfo = [syncInfo substringWithRange: smallerRange];
	NS_HANDLER
	return;
	NS_ENDHANDLER

	pageNumber = pageNumber + 1;
	thePageNumber = [NSNumber numberWithInteger:pageNumber];
	pageSearchString = [@"s " stringByAppendingString: [thePageNumber stringValue]];
	pageRangeEnd = [syncInfo rangeOfString: pageSearchString];
	if (pageRangeEnd.location != NSNotFound) {
		smallerRange.location = 0;
		smallerRange.length = pageRangeEnd.location;
		NS_DURING
		syncInfo = [syncInfo substringWithRange: smallerRange];
		NS_HANDLER
		return;
		NS_ENDHANDLER
		}

	// backColor = [NSColor blackColor];
	backColor = [NSColor colorWithDeviceRed:0.4   green:0.4    blue:0.4     alpha: .60];
	[backColor set];

	remainingRange.location = 0;
	remainingRange.length = [syncInfo length];
	do {
		if (remainingRange.length <= 0)
			return;
		searchResultRange = [syncInfo rangeOfString: @"p" options: NSLiteralSearch range: remainingRange];
		if (searchResultRange.location == NSNotFound)
			return;

		NS_DURING
		[syncInfo getLineStart: &theStart end: &theEnd contentsEnd: nil forRange: searchResultRange];
		NS_HANDLER
		return;
		NS_ENDHANDLER
		remainingRange.location = theEnd + 1;
		remainingRange.length = [syncInfo length] - remainingRange.location;
		if (searchResultRange.location == theStart) {
			newRange.location = theStart;
			newRange.length = theEnd - theStart;
			NS_DURING
			keyLine = [syncInfo substringWithRange: newRange];
			NS_HANDLER
			return;
			NS_ENDHANDLER

			searchResultRange = [keyLine rangeOfCharacterFromSet: [NSCharacterSet decimalDigitCharacterSet]];
			if (newRange.location == NSNotFound)
				break;
			newRange.location = searchResultRange.location;
			newRange.length = [keyLine length] - newRange.location;
			NS_DURING
			keyLine = [keyLine substringWithRange: newRange];
			NS_HANDLER
			return;
			NS_ENDHANDLER
			syncNumber = [keyLine integerValue]; // number of entry

			searchResultRange = [keyLine rangeOfString: @" "];
			if (searchResultRange.location == NSNotFound)
				break;
			newRange.location = searchResultRange.location;
			newRange.length = [keyLine length] - newRange.location;
			NS_DURING
			keyLine = [keyLine substringWithRange: newRange];
			NS_HANDLER
			return;
			NS_ENDHANDLER
			searchResultRange = [keyLine rangeOfCharacterFromSet: [NSCharacterSet decimalDigitCharacterSet]];
			if (searchResultRange.location == NSNotFound)
				break;
			newRange.location = searchResultRange.location;
			newRange.length = [keyLine length] - newRange.location;
			NS_DURING
			keyLine = [keyLine substringWithRange: newRange];
			NS_HANDLER
			return;
			NS_ENDHANDLER
			x = [keyLine integerValue];

			searchResultRange = [keyLine rangeOfString: @" "];
			if (searchResultRange.location == NSNotFound)
				break;
			newRange.location = searchResultRange.location;
			newRange.length = [keyLine length] - newRange.location;
			NS_DURING
			keyLine = [keyLine substringWithRange: newRange];
			NS_HANDLER
			return;
			NS_ENDHANDLER
			y = [keyLine integerValue];

			newx = x / 65536.0;
			newy = y / 65536.0;

			smallRect.origin.x = newx - 2.0 + p.x;
			smallRect.origin.y = newy- 3.0 + p.y;

			smallRect.size.width = 10;
			smallRect.size.height = 10;

			[NSBezierPath fillRect: smallRect];
			}
		}


	while (remainingRange.length > 0);
}

- (void) cancelSearch
{
	if ([[self document] isFinding])
		[[self document] cancelFindString];
}


#pragma mark =====magnifying glass=====

// WARNING: Modified Version

- (void)updateBackground: (NSRect)aRect
{
	NSRect theRect = NSIntersectionRect(aRect, [self visibleRect]);
	[self displayRect: theRect];
}



- (void)doMagnifyingGlass:(NSEvent *)theEvent level: (NSInteger)level
{
    
// Use new Magnifying Glass Routine on Lion, Mountain Lion, and Mavericks. It works in all these places
// and the old routine has problems in all of these places.
    
 //      if ((floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7) &&
 //          ([self displayMode] != kPDFDisplaySinglePageContinuous) && ([self displayMode] != kPDFDisplayTwoUpContinuous))
           
 //          [self doMagnifyingGlassML: theEvent level:level] ;
    
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7)
 //        [self doMagnifyingGlassML: theEvent level:level] ;
        
        return;
    
    else [self doMagnifyingGlassMavericks: theEvent level:level] ;

    
//    if (atLeastMavericks)
//         [self doMagnifyingGlassMavericks: theEvent level:level] ;
//    else
//         [self doMagnifyingGlassML: theEvent level:level] ;
}

// Obsolte Mavericks Routine
/*
 - (void)doMagnifyingGlassMavericks:(NSEvent *)theEvent level: (NSInteger)level
 {
 NSPoint mouseLocWindow, mouseLocView, mouseLocDocumentView;
 NSRect oldBounds, newBounds, magRectWindow, magRectView, tempRect;
 BOOL postNote, cursorVisible;
 CGFloat magWidth = 0.0, magHeight = 0.0, magOffsetX = 0.0, magOffsetY = 0.0;
 NSInteger originalLevel, currentLevel = 0.0;
 CGFloat magScale = 0.0; 	//0.4	// you may want to change this
 NSData *thePDFData;
 NSPDFImageRep *thePDFImageRep;
 NSImage *theImage;
 NSRect theOriginalRect;
 
 // postNote = [[self documentView] postsBoundsChangedNotifications];
 // [[self documentView] setPostsBoundsChangedNotifications: NO];
 
 oldBounds = [[self documentView] bounds];
 cursorVisible = YES;
 originalLevel = level+[theEvent clickCount];
 
 //[self cleanupMarquee: NO];
 rect = NSMakeRect(0, 0, 1, 1); // [[self window] discardCachedImage]; // make sure not use the cached image
 
 //[[self window] disableFlushWindow];
 
 OverView *theOverView = [[OverView alloc] initWithFrame: [[self documentView] frame] ];
 [self setOverView: theOverView];
 [[self documentView] addSubview: [self overView]];
 
 tempRect = [[self documentView] visibleRect];
 thePDFData = [[self documentView] dataWithPDFInsideRect:[[self documentView] visibleRect]];
 thePDFImageRep = [NSPDFImageRep imageRepWithData: thePDFData];
 theImage = [[NSImage alloc] init];
 [theImage addRepresentation:thePDFImageRep];
 
 [[self overView] setDrawRubberBand: NO];
 [[self overView] setDrawMagnifiedRect: NO];
 [[self overView] setDrawMagnifiedImage: NO];
 [[self overView] setMagnifiedImage: theImage];
 
 
 // [[self window] disableFlushWindow];
 
 
 do {
 
 if ([theEvent type]==NSLeftMouseDragged || [theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) {
 
 // set up the size and magScale
 if ([theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) {
 currentLevel = originalLevel+(([theEvent modifierFlags] & NSAlternateKeyMask)?1:0);
 if (currentLevel <= 1) {
 magWidth = 150; magHeight = 100;
 magOffsetX = magWidth/2; magOffsetY = magHeight/2;
 } else if (currentLevel == 2) {
 magWidth = 380; magHeight = 250;
 magOffsetX = magWidth/2; magOffsetY = magHeight/2;
 } else {
 
 // currentLevel >= 3 // need to cache the image
 [self updateBackground: rect]; // [[self window] restoreCachedImage];
 // [[self window] cacheImageInRect:[self convertRect:[self visibleRect] toView: nil]];
 rect = [self visibleRect];
 
OR  magWidth = 1800; magHeight = 1500;
magOffsetX = magWidth / 2; magOffsetY = magHeight / 2;
}

 if (!([theEvent modifierFlags] & NSShiftKeyMask)) {
 if ([theEvent modifierFlags] & NSCommandKeyMask)
 magScale = 0.25; 	// x4
 else if ([theEvent modifierFlags] & NSControlKeyMask)
 magScale = 0.66666; // x1.5
 else
 magScale = 0.4; 	// x2.5
 } else { // shrink the image with shift key -- can be very slow
 if ([theEvent modifierFlags] & NSCommandKeyMask)
 magScale = 4.0; 	// /4
 else if ([theEvent modifierFlags] & NSControlKeyMask)
 magScale = 1.5; 	// /1.5
 else
 magScale = 2.5; 	// /2.5
 }
 
}
// get Mouse location and check if it is with the view's rect

if (!([theEvent type]==NSFlagsChanged))
mouseLocWindow = [theEvent locationInWindow];
mouseLocView = [self convertPoint: mouseLocWindow fromView:nil];
mouseLocDocumentView = [[self documentView] convertPoint: mouseLocWindow fromView:nil];
// check if the mouse is in the rect

if([self mouse:mouseLocView inRect:[self visibleRect]]) {
    if (cursorVisible) {
        [NSCursor hide];
        cursorVisible = NO;
    }
    // define rect for magnification in window coordinate
 
     if (currentLevel >= 3) { // mitsu 1.29 (S5) set magRectWindow here
     magRectWindow = [self convertRect:[self visibleRect] toView:nil];
     rect = [self visibleRect];
     } else
 
    { // currentLevel <= 2
        
        // [[self overView] setDrawRubberBand: NO];
        //  [[self overView] setDrawMagnifiedRect: NO];
        //  [[self overView] setDrawMagnifiedImage: NO];
        //  [[self overView] drawRect: [[self documentView] visibleRect]];
        //  [self display];
        
        magRectWindow = NSMakeRect(mouseLocDocumentView.x-magOffsetX, mouseLocDocumentView.y-magOffsetY,
                                   magWidth, magHeight);
        // theOriginalRect = NSMakeRect(mouseLocDocumentView.x - magOffsetX / 4.0, mouseLocDocumentView.y - magOffsetY / 4.0,
        //                         magWidth / 4.0, magHeight / 4.0);
        
        
        theOriginalRect = NSMakeRect(mouseLocDocumentView.x - tempRect.origin.x - magOffsetX / 4.0,
                                     mouseLocDocumentView.y - tempRect.origin.y - magOffsetY / 4.0,
                                     magWidth / 4.0, magHeight / 4.0);
        
        // thePDFData = [[self documentView] dataWithPDFInsideRect:[[self documentView] visibleRect]];
        // thePDFImageRep = [NSPDFImageRep imageRepWithData: thePDFData];
        // theImage = [[NSImage alloc] init];
        // [theImage addRepresentation:thePDFImageRep];
        
        // restore the cached image in order to clear the rect
        [self updateBackground:rect]; // [[self window] restoreCachedImage];
        // [[self window] cacheImageInRect:
        //	NSIntersectionRect(NSInsetRect(magRectWindow, -2, -2),
        //					   [[self superview] convertRect:[[self superview] bounds]
        //
        rect = NSIntersectionRect(NSInsetRect(magRectWindow, -2, -2), [[self superview] convertRect:[[self superview] bounds]  toView:nil]); // mitsu 1.29b
        rect = [self convertRect: rect fromView: nil];
    }
    // draw marquee
    if (selRectTimer)
        [self updateMarquee: nil];
    
    
    [[self overView] setDrawRubberBand: NO];
    [[self overView] setDrawMagnifiedRect: NO];
    [[self overView] setDrawMagnifiedImage: YES];
    [[self overView] setSelectionRect: magRectWindow];
    [[self overView] setMagnifiedRect: theOriginalRect];
    //[[self overView] drawRect: [[self documentView] visibleRect]];
    [[self overView] displayRect: [[self documentView] visibleRect]];
    // [[self window] enableFlushWindow];
    
    // [[self window] flushWindow];
    
    // [[self window] disableFlushWindow];
 
     
     
     // resize bounds around mouseLocView
     newBounds = NSMakeRect(mouseLocDocumentView.x+magScale*(oldBounds.origin.x-mouseLocDocumentView.x),
     mouseLocDocumentView.y+magScale*(oldBounds.origin.y-mouseLocDocumentView.y),
     magScale*(oldBounds.size.width), magScale*(oldBounds.size.height));
     
     // mitsu 1.29 (S1) fix for rotated view
     
     [[self documentView] setBounds: newBounds];
     magRectView = NSInsetRect([self convertRect:magRectWindow fromView:nil],1,1);
     [self displayRect: magRectView]; // this flushes the buffer
     // reset bounds
     [[self documentView] setBounds: oldBounds];
     
 
    
} else { // mouse is not in the rect
    // show cursor
    if (!cursorVisible) {
        [NSCursor unhide];
        cursorVisible = YES;
    }
    // restore the cached image in order to clear the rect
    // [self updateBackground: rect]; // [[self window] restoreCachedImage];
    [self updateBackground:rect];
    // autoscroll
    if (!([theEvent type]==NSFlagsChanged))
        [self autoscroll: theEvent];
    if (currentLevel >= 3)
        ; // [[self window] cacheImageInRect:magRectWindow];
    else
        rect = NSMakeRect(0, 0, 1, 1); // [[self window] discardCachedImage];
}

// [[self window] enableFlushWindow];
//  [[self window] flushWindow];
// [[self window] disableFlushWindow];

} else if ([theEvent type] == NSLeftMouseUp) {
    break;
}
theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
            NSLeftMouseDraggedMask | NSFlagsChangedMask];
} while (YES);

if (theOverView) {
    [theOverView removeFromSuperview];
    [self setOverView: nil];
}


// [[self window] enableFlushWindow];


[self updateBackground:rect]; // [[self window] restoreCachedImage];
// [[self window] flushWindow];
[NSCursor unhide];
[[self documentView] setPostsBoundsChangedNotifications: postNote];
[self flagsChanged: theEvent]; // update cursor
// recache the image around marquee for quicker response
oldVisibleRect.size.width = 0;
[self cleanupMarquee: NO];
[self recacheMarquee];
// The line below was added to clean up marks in gray border
// QUESTIONABLE_BUG_FIX
[[self window] display];

}
*/

// Routine for Mavericks
// -------------------------------------------------------------------------

- (void)doMagnifyingGlassMavericks:(NSEvent *)theEvent level: (NSInteger)level
{
	NSPoint mouseLocWindow, mouseLocView, mouseLocDocumentView;
	NSRect magRectWindow, tempRect;
	BOOL cursorVisible;
	CGFloat magWidth = 0.0, magHeight = 0.0, magOffsetX = 0.0, magOffsetY = 0.0;
	NSInteger originalLevel, currentLevel = 0.0;
    CGFloat magScale = 2.5; // 4.0
    
    NSData          *thePDFData;
    NSPDFImageRep   *thePDFImageRep;
    NSImage         *theImage;
    NSRect          theOriginalRect;
	
	cursorVisible = YES;
	originalLevel = level+[theEvent clickCount];
	
    OverView *theOverView = [[OverView alloc] initWithFrame: [[self documentView] frame] ];
    [self setOverView: theOverView];
    [[self documentView] addSubview: [self overView]];
    
    tempRect = [[self documentView] visibleRect];
    thePDFData = [[self documentView] dataWithPDFInsideRect:[[self documentView] visibleRect]];
    thePDFImageRep = [NSPDFImageRep imageRepWithData: thePDFData];
    theImage = [[NSImage alloc] init] ;
    [theImage addRepresentation:thePDFImageRep];
    
    [[self overView] setDrawRubberBand: NO];
    [[self overView] setDrawMagnifiedRect: NO];
    [[self overView] setDrawMagnifiedImage: NO];
    [[self overView] setMagnifiedImage: theImage];
   
    
	do {
        
		if ([theEvent type]==NSLeftMouseDragged || [theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) {
            
			// set up the size and magScale
			if ([theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) {
				currentLevel = originalLevel+(([theEvent modifierFlags] & NSAlternateKeyMask)?1:0);
				if (currentLevel <= 1) {
					magWidth = 150; magHeight = 100;
					magOffsetX = magWidth/2; magOffsetY = magHeight/2;
				} else if (currentLevel == 2) {
					magWidth = 380; magHeight = 250;
					magOffsetX = magWidth/2; magOffsetY = magHeight/2;
				} else {
                    magWidth = 1800; magHeight = 1500;
                    magOffsetX = magWidth / 2; magOffsetY = magHeight / 2;
				}
 			}
            
			// get Mouse location and check if it is with the view's rect
			
			if (!([theEvent type]==NSFlagsChanged))
				mouseLocWindow = [theEvent locationInWindow];
			mouseLocView = [self convertPoint: mouseLocWindow fromView:nil];
  			mouseLocDocumentView = [[self documentView] convertPoint: mouseLocWindow fromView:nil];
			// check if the mouse is in the rect
			
			if([self mouse:mouseLocView inRect:[self visibleRect]]) {
				if (cursorVisible) {
					[NSCursor hide];
					cursorVisible = NO;
                    }
				            
                
                magRectWindow = NSMakeRect(mouseLocDocumentView.x-magOffsetX, mouseLocDocumentView.y-magOffsetY,
											   magWidth, magHeight);
                theOriginalRect = NSMakeRect(mouseLocDocumentView.x - tempRect.origin.x - magOffsetX / magScale,
                                                 mouseLocDocumentView.y - tempRect.origin.y - magOffsetY / magScale,
                                                                         magWidth / magScale, magHeight / magScale);
                
                [[self overView] setDrawRubberBand: NO];
                [[self overView] setDrawMagnifiedRect: NO];
                [[self overView] setDrawMagnifiedImage: YES];
                [[self overView] setSelectionRect: magRectWindow];
                [[self overView] setMagnifiedRect: theOriginalRect];
                // [[self overView] displayRect: [[self documentView] visibleRect]];
                [[self overView] setNeedsDisplayInRect: [[self documentView] visibleRect]];
                

 			} else { // mouse is not in the rect
                // show cursor
				if (!cursorVisible) {
					[NSCursor unhide];
					cursorVisible = YES;
				}
			}
			
 		} else if ([theEvent type] == NSLeftMouseUp) {
			break;
		}
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
                    NSLeftMouseDraggedMask | NSFlagsChangedMask];
	} while (YES);
    
    if (theOverView) {
        [theOverView removeFromSuperview];
        [self setOverView: nil];
    }
	
	[NSCursor unhide];
	[self flagsChanged: theEvent]; // update cursor
    
}



// Routine for Mountain Lion and lower
// -------------------------------------------------------------------------

- (void)doMagnifyingGlassML:(NSEvent *)theEvent level: (NSInteger)level
{
	NSPoint mouseLocWindow, mouseLocView, mouseLocDocumentView;
	NSRect oldBounds, newBounds, magRectWindow, magRectView;
	BOOL postNote, cursorVisible;
	CGFloat magWidth = 0.0, magHeight = 0.0, magOffsetX = 0.0, magOffsetY = 0.0;
	NSInteger originalLevel, currentLevel = 0.0;
	CGFloat magScale = 0.0; 	//0.4	// you may want to change this
	
	postNote = [[self documentView] postsBoundsChangedNotifications];
	[[self documentView] setPostsBoundsChangedNotifications: NO];
	
	oldBounds = [[self documentView] bounds];
	cursorVisible = YES;
	originalLevel = level+[theEvent clickCount];
	
	//[self cleanupMarquee: NO];
	rect = NSMakeRect(0, 0, 1, 1); // [[self window] discardCachedImage]; // make sure not use the cached image
	
	[[self window] disableFlushWindow];
	
	do {
	
		if ([theEvent type]==NSLeftMouseDragged || [theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) {
		
			// [[self window] disableFlushWindow];

			// set up the size and magScale
			if ([theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) {
				currentLevel = originalLevel+(([theEvent modifierFlags] & NSAlternateKeyMask)?1:0);
				if (currentLevel <= 1) {
					magWidth = 150; magHeight = 100;
					magOffsetX = magWidth/2; magOffsetY = magHeight/2;
				} else if (currentLevel == 2) {
					magWidth = 380; magHeight = 250;
					magOffsetX = magWidth/2; magOffsetY = magHeight/2;
				} else { // currentLevel >= 3 // need to cache the image
					[self updateBackground: rect]; // [[self window] restoreCachedImage];
					// [[self window] cacheImageInRect:[self convertRect:[self visibleRect] toView: nil]];
					rect = [self visibleRect];
				}
				if (!([theEvent modifierFlags] & NSShiftKeyMask)) {
					if ([theEvent modifierFlags] & NSCommandKeyMask)
						magScale = 0.25; 	// x4
					else if ([theEvent modifierFlags] & NSControlKeyMask)
						magScale = 0.66666; // x1.5
					else
						magScale = 0.4; 	// x2.5
				} else { // shrink the image with shift key -- can be very slow
					if ([theEvent modifierFlags] & NSCommandKeyMask)
						magScale = 4.0; 	// /4
					else if ([theEvent modifierFlags] & NSControlKeyMask)
						magScale = 1.5; 	// /1.5
					else
						magScale = 2.5; 	// /2.5
				}
			}
			// get Mouse location and check if it is with the view's rect
			
			if (!([theEvent type]==NSFlagsChanged))
				mouseLocWindow = [theEvent locationInWindow];
			mouseLocView = [self convertPoint: mouseLocWindow fromView:nil];
			mouseLocDocumentView = [[self documentView] convertPoint: mouseLocWindow fromView:nil];
			// check if the mouse is in the rect
			
			if([self mouse:mouseLocView inRect:[self visibleRect]]) {
				if (cursorVisible) {
					[NSCursor hide];
					cursorVisible = NO;
				}
				// define rect for magnification in window coordinate
				if (currentLevel >= 3) { // mitsu 1.29 (S5) set magRectWindow here
					magRectWindow = [self convertRect:[self visibleRect] toView:nil];
					rect = [self visibleRect];
				} else { // currentLevel <= 2
					magRectWindow = NSMakeRect(mouseLocWindow.x-magOffsetX, mouseLocWindow.y-magOffsetY,
											   magWidth, magHeight);
					// restore the cached image in order to clear the rect
					[self updateBackground:rect]; // [[self window] restoreCachedImage];
					// [[self window] cacheImageInRect:
					//	NSIntersectionRect(NSInsetRect(magRectWindow, -2, -2),
					//					   [[self superview] convertRect:[[self superview] bounds]
					//
					rect = NSIntersectionRect(NSInsetRect(magRectWindow, -2, -2), [[self superview] convertRect:[[self superview] bounds]  toView:nil]); // mitsu 1.29b
					rect = [self convertRect: rect fromView: nil];
				}
				// draw marquee
				if (self.selRectTimer)
					[self updateMarquee: nil];
				
				// resize bounds around mouseLocView
				newBounds = NSMakeRect(mouseLocDocumentView.x+magScale*(oldBounds.origin.x-mouseLocDocumentView.x),
									   mouseLocDocumentView.y+magScale*(oldBounds.origin.y-mouseLocDocumentView.y),
									   magScale*(oldBounds.size.width), magScale*(oldBounds.size.height));
				
				// mitsu 1.29 (S1) fix for rotated view
				
				[[self documentView] setBounds: newBounds];
				magRectView = NSInsetRect([self convertRect:magRectWindow fromView:nil],1,1);
				[self displayRect: magRectView]; // this flushes the buffer
												 // reset bounds
				[[self documentView] setBounds: oldBounds];
				
			} else { // mouse is not in the rect
					 // show cursor
				if (!cursorVisible) {
					[NSCursor unhide];
					cursorVisible = YES;
				}
				// restore the cached image in order to clear the rect
				// [self updateBackground: rect]; // [[self window] restoreCachedImage];
				[self updateBackground:rect];
				// autoscroll
				if (!([theEvent type]==NSFlagsChanged))
					[self autoscroll: theEvent];
				if (currentLevel >= 3)
					; // [[self window] cacheImageInRect:magRectWindow];
				else
					rect = NSMakeRect(0, 0, 1, 1); // [[self window] discardCachedImage];
			}
			
		[[self window] enableFlushWindow];
		[[self window] flushWindow];
		[[self window] disableFlushWindow];
		
		} else if ([theEvent type] == NSLeftMouseUp) {
			break;
		}
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
			NSLeftMouseDraggedMask | NSFlagsChangedMask];
	} while (YES);
	
	[[self window] enableFlushWindow];
    
	
	[self updateBackground:rect]; // [[self window] restoreCachedImage];
	// [[self window] flushWindow];
	[NSCursor unhide];
	[[self documentView] setPostsBoundsChangedNotifications: postNote];
	[self flagsChanged: theEvent]; // update cursor
								   // recache the image around marquee for quicker response
	oldVisibleRect.size.width = 0;
	[self cleanupMarquee: NO];
	[self recacheMarquee];
    // The line below was added to clean up marks in gray border
    // QUESTIONABLE_BUG_FIX
    [[self window] display];

}
// end Magnifying Glass
//
// End of special routines for Mountain Lion and below
// -----------------------------------------------------------------



// change mouse mode when a modifier key is pressed
- (void)flagsChanged:(NSEvent *)theEvent
{
	if (([theEvent modifierFlags] & NSCommandKeyMask) && (!([theEvent modifierFlags] & NSAlternateKeyMask)))
		currentMouseMode = NEW_MOUSE_MODE_SELECT_TEXT;
	else if ([theEvent modifierFlags] & NSControlKeyMask)
		currentMouseMode = NEW_MOUSE_MODE_SCROLL;
	else if ([theEvent modifierFlags] & NSCommandKeyMask)
		currentMouseMode = NEW_MOUSE_MODE_SELECT_PDF;
	else if ([theEvent modifierFlags] & NSAlternateKeyMask)
		currentMouseMode = MOUSE_MODE_MAG_GLASS;
	else
		currentMouseMode = mouseMode;
	
	[[self window] invalidateCursorRectsForView: self]; // this updates the cursor rects
}

- (void)setMagnification: (double)magnification
{
	NSInteger		scale;

	[self cleanupMarquee: YES];

	scale = magnification * 100.0;
	if (scale < 20)
		scale = 20;
	if (scale > 1000)
		scale = 1000;

	scaleMag = scale;
	[myScale setIntegerValue:scale];
	[myScale1 setIntegerValue:scale];
	[myScale display];
	[myScale1 display];
	[myStepper setIntegerValue:scale];
	[myStepper1 setIntegerValue:scale];

	[self setScaleFactor: magnification];

}

- (void)resetMagnification
{
	double	theMagnification;
	NSInteger		mag;

	theMagnification = [SUD floatForKey:PdfMagnificationKey];

	if (theMagnification != [self magnification])
		[self setMagnification: theMagnification];

	mag = round(theMagnification * 100.0);
	[myStepper setIntegerValue:mag];
	[myStepper1 setIntegerValue:mag];
}


- (void)changeMagnification:(NSNotification *)aNotification
{
	[self resetMagnification];
}

- (void)rememberMagnification:(NSNotification *)aNotification
{
	oldMagnification = [self magnification];
}

- (void) revertMagnification:(NSNotification *)aNotification
{
	if (oldMagnification != [self magnification])
		[self setMagnification: oldMagnification];
}


// Left and right arrows perform page up and page down if horizontal scroll bar is inactive
- (void)keyDown:(NSEvent *)theEvent
{
	NSString	*theKey;
	unichar		key;

	theKey = [theEvent characters];
	if ([theKey length] >= 1)
		key = [theKey characterAtIndex:0];
	else
		key = 0;
	
	if ((key == NSLeftArrowFunctionKey) && ([theEvent modifierFlags] & NSCommandKeyMask)) {
		[self previousPage:self];
	} else if ((key == NSRightArrowFunctionKey) && ([theEvent modifierFlags] & NSCommandKeyMask)) {
		[self nextPage:self];
	} else if (((key == NSLeftArrowFunctionKey) || (key == NSRightArrowFunctionKey)) &&
				([SUD boolForKey: LeftRightArrowsAlwaysPageKey] ||
				! [[[[self documentView] enclosingScrollView] horizontalScroller] isEnabled])
		) {
		if (key == NSLeftArrowFunctionKey)
			[self previousPage:self];
		else
			[self nextPage:self];
	} else {
		[super keyDown:theEvent];
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSMenu *theMenu = [super menuForEvent: theEvent];
	if (theMenu != nil) {
		menuSyncPoint = [theEvent locationInWindow];
		[theMenu insertItemWithTitle: NSLocalizedString(@"Sync", @"Sync") action:@selector(doMenuSync:) keyEquivalent:@"" atIndex:0];
		[theMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
	}
    return theMenu;
}

- (void)doMenuSync: (id)theItem
{
	[[self window] invalidateCursorRectsForView: self];
 	[self doSync: menuSyncPoint];
}


- (void)resetSearchDelegate
{
	[_searchTable setDelegate:self];
}

- (void)fixStuff
{
	NSMenu			*previewMenu, *menu;
	NSArray			*menuArray;
	NSEnumerator	*enumerator;
	id				anObject;
	id              item;
	
	//------Display Format Menu-----------------
	previewMenu = [[[NSApp mainMenu] itemWithTitle:
				NSLocalizedString(@"Preview", @"Preview")] submenu];
	menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Display Format", @"Display Format")] submenu];
	// for all items in submenu
	menuArray = [menu itemArray];
	enumerator = [menuArray objectEnumerator];
	while ((anObject = [enumerator nextObject]))
		[anObject setState: NSOffState];
	item = [menu itemWithTag: pageStyle];
	[item setState: NSOnState];
		
	//-------Magnification Menu------------------
	menu = [[previewMenu itemWithTitle:
					 NSLocalizedString(@"Magnification", @"Magnification")] submenu];
	// for all items in submenu
	menuArray = [menu itemArray];
	enumerator = [menuArray objectEnumerator];
	while ((anObject = [enumerator nextObject]))
		[anObject setState: NSOffState];
	item = [menu itemWithTag: resizeOption];
	[item setState: NSOnState];
	
	//-------Magnification Controls----------
	[self fixMagnificationControls]; //needed when magnify in split mode
	[self scaleChanged: nil];
	[self pageChanged: nil];
	
}

- (BOOL)becomeFirstResponder
{
	BOOL	result;
    
	[(TSPreviewWindow *)self.myPDFWindow setActiveView: self];
	result =  [super becomeFirstResponder];
	[self fixStuff];
	[self resetSearchDelegate];
	return result;
}


- (void)fixMagnificationControls
{
	if (scaleMag == 0)
		scaleMag = 100;
	[myScale setIntegerValue:scaleMag];
	[myScale1 setIntegerValue:scaleMag];
	[myStepper setIntegerValue:scaleMag];
	[myStepper1 setIntegerValue:scaleMag];
}

- (NSMutableArray *)getSearchResults
{
	return _searchResults;
}

- (void)setProtectFind: (BOOL)value
{
	protectFind = value;
}

- (void) setShowSync: (BOOL)value
{	
	showSync = value;
}

- (void)setNumberSyncRect: (int)value
{
	numberSyncRect = value;
}

- (void)setSyncRect: (int)which originX: (float)x originY: (float)y width: (float)width height: (float)height
{
	syncRect[which].origin.x = x;
	syncRect[which].origin.y = y;
	syncRect[which].size.width = width;
	syncRect[which].size.height = height;
}


// NSWindowDelegate methods

- (NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions
{
    NSUInteger NSApplicationPresentationAutoHideToolbar = 2048;
    return (proposedOptions | NSApplicationPresentationAutoHideToolbar);
}


- (void)setDisplayMode:(PDFDisplayMode)mode
{
    [super setDisplayMode: mode];
    switch (mode) {
        case kPDFDisplaySinglePage: pageStyle = PDF_SINGLE_PAGE_STYLE; break;
        case kPDFDisplayTwoUp: pageStyle = PDF_TWO_PAGE_STYLE; break;
        case kPDFDisplaySinglePageContinuous: pageStyle = PDF_MULTI_PAGE_STYLE; break;
        case kPDFDisplayTwoUpContinuous: pageStyle = PDF_DOUBLE_MULTI_PAGE_STYLE; break;
    }
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
/*
    oldPageStyle = pageStyle;
    oldResizeOption = resizeOption;
    if (fullscreenPageStyle == 0)
        fullscreenPageStyle = 2;
    if (fullscreenResizeOption == 0)
        fullscreenResizeOption = 3;
    [[self.myDocument myPdfKitView] changePDFViewSizeTo:fullscreenResizeOption];
    [[self.myDocument myPdfKitView] changePageStyleTo: fullscreenPageStyle];
    [[self.myDocument myPdfKitView2] changePDFViewSizeTo:fullscreenResizeOption];
    [[self.myDocument myPdfKitView2] changePageStyleTo: fullscreenPageStyle];
*/
    [self.myDocument enterFullScreen: notification];

}



- (void)windowWillExitFullScreen:(NSNotification *)notification
{
/*
    fullscreenPageStyle = pageStyle;
    fullscreenResizeOption = resizeOption;
    [[self.myDocument myPdfKitView] changePDFViewSizeTo: oldResizeOption];
    [[self.myDocument myPdfKitView] changePageStyleTo:oldPageStyle];
    [[self.myDocument myPdfKitView2] changePDFViewSizeTo: oldResizeOption];
    [[self.myDocument myPdfKitView2] changePageStyleTo:oldPageStyle];
*/
    [self.myDocument exitFullScreen: notification];
}




@end
