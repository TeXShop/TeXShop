/* PDFKitViewer - MyPDFView.m
 *
 * Created 2004
 * 
 * Copyright (c) 2004 Apple Computer, Inc.
 * All rights reserved.
 */

/* IMPORTANT: This Apple software is supplied to you by Apple Computer,
 Inc. ("Apple") in consideration of your agreement to the following terms,
 and your use, installation, modification or redistribution of this Apple
 software constitutes acceptance of these terms.  If you do not agree with
 these terms, please do not use, install, modify or redistribute this Apple
 software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following text
 and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple. Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES
 NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE
 IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
 ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT
 LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE. */


#import "MyPDFKitView.h"
#import "Globals.h"
#import "MyDocument.h"
#import "EncodingSupport.h"

#define PAGE_SPACE_H	10
#define PAGE_SPACE_V	10

#define HORIZONTAL_SCROLL_AMOUNT	60
#define VERTICAL_SCROLL_AMOUNT	60
#define HORIZONTAL_SCROLL_OVERLAP	60
#define VERTICAL_SCROLL_OVERLAP		60
#define SCROLL_TOLERANCE 0.5

#define PAGE_WINDOW_H_OFFSET	60
#define PAGE_WINDOW_V_OFFSET	-10
#define PAGE_WINDOW_WIDTH		55
#define PAGE_WINDOW_HEIGHT		20
#define PAGE_WINDOW_DRAW_X		7
#define PAGE_WINDOW_DRAW_Y		3
#define PAGE_WINDOW_HAS_SHADOW	NO

#define SIZE_WINDOW_H_OFFSET	75
#define SIZE_WINDOW_V_OFFSET	-10
#define SIZE_WINDOW_WIDTH		70
#define SIZE_WINDOW_HEIGHT		20
#define SIZE_WINDOW_DRAW_X		5
#define SIZE_WINDOW_DRAW_Y		3
#define SIZE_WINDOW_HAS_SHADOW	NO

#define NUMBER_OF_SOURCE_FILES	60



#define SUD [NSUserDefaults standardUserDefaults]


@implementation MyPDFKitView : PDFView

- (void) dealloc
{
	// No more notifications.
	[[NSNotificationCenter defaultCenter] removeObserver: self];
 	
	// Clean up.
	[_searchResults release];
}


- (void) initializeDisplay;
{

	NSColor	*backColor;
	
	downOverLink = NO;
	
	drawMark = NO;
	pageStyle = [SUD integerForKey: PdfPageStyleKey]; 
	firstPageStyle = [SUD integerForKey: PdfFirstPageStyleKey];
	resizeOption = [SUD integerForKey: PdfKitFitSizeKey];
	if ((resizeOption == NEW_PDF_FIT_TO_WIDTH) || (resizeOption == NEW_PDF_FIT_TO_HEIGHT))
		resizeOption = PDF_FIT_TO_WINDOW;

	
	// Display mode
	[self setupPageStyle];
		
	// Size Option
	[self setupMagnificationStyle];
	
	backColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:PdfPageBack_RKey] 
		green: [SUD floatForKey:PdfPageBack_GKey] blue: [SUD floatForKey:PdfPageBack_BKey] 
		alpha: 1];
	[[[self documentView] window] setBackgroundColor: backColor];

	
}

- (void) setupPageStyle;
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

- (void) setupMagnificationStyle;
{
	double	theMagnification;
	int		mag;
	
		switch (resizeOption) {
	
		case NEW_PDF_ACTUAL_SIZE:	theMagnification = 1.0;
									mag = round(theMagnification * 100.0);
									[myStepper setIntValue: mag];
									[myStepper1 setIntValue: mag];
									[self setScaleFactor: theMagnification];
									break;
		
		case NEW_PDF_FIT_TO_NONE:	theMagnification = [SUD floatForKey:PdfMagnificationKey];
									mag = round(theMagnification * 100.0);
									[myStepper setIntValue: mag];
									[myStepper1 setIntValue: mag];
									[self setScaleFactor: theMagnification];
									break;

		
		case NEW_PDF_FIT_TO_WIDTH:
		case NEW_PDF_FIT_TO_HEIGHT:
		case NEW_PDF_FIT_TO_WINDOW:	[self setAutoScales: YES];
									break;
		
		}
}

- (void) setupOutline;
{
	if (![SUD boolForKey: UseOutlineKey])
		return;
	
	if (_outline)
		[_outline release];
	_outline = NULL;
	_outline = [[[self document] outlineRoot] retain];
	if (_outline)
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

- (void) setup;
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


		mouseMode = [SUD integerForKey: PdfKitMouseModeKey];
		[[myDocument mousemodeMatrix] selectCellWithTag: mouseMode];
		[[[myDocument mousemodeMenu] itemWithTag: mouseMode] setState: NSOnState];
		currentMouseMode = mouseMode;
		selRectTimer = nil;
		
		totalRotation = 0;
		
		[self initializeDisplay];
}

- (void) showWithPath: (NSString *)imagePath;
{

		PDFDocument	*pdfDoc;
		PDFPage	*aPage;
		NSRect	tempRect;
		
		sourceFiles = nil;
		pdfDoc = [[[PDFDocument alloc] initWithURL: [NSURL fileURLWithPath: imagePath]] retain];
		[self setDocument: pdfDoc];
		[self setup];
		totalPages = [[self document] pageCount];
		[totalPage setIntValue:totalPages];
		[totalPage1 setIntValue: totalPages];
		[totalPage display];
		[totalPage1 display];
		[[self document] setDelegate: self];
		[self setupOutline];
		
		[myPDFWindow makeKeyAndOrderFront: self];
	

}

- (void) reShowWithPath: (NSString *)imagePath;
{

		PDFDocument	*pdfDoc;
		PDFPage		*aPage;
		int			theindex, oldindex;
		BOOL		needsInitialization;
		int			i, amount, newAmount;
		PDFPage		*myPage;
		
		[self cleanupMarquee: YES];
		
		if (sourceFiles != nil) {
			[sourceFiles release];
			sourceFiles = nil;
			}
		if ([self document] == nil)
			needsInitialization = YES;
		else
			needsInitialization = NO;
		
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
			[_searchResults release];
			_searchResults = NULL;
			}
		pdfDoc = [[[PDFDocument alloc] initWithURL: [NSURL fileURLWithPath: imagePath]] retain];
		[self setDocument: pdfDoc];
		[[self document] setDelegate: self];
		totalPages = [[self document] pageCount];
		[totalPage setIntValue:totalPages];
		[totalPage1 setIntValue: totalPages];
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
		aPage = [[self document] pageAtIndex: theindex];
		[self goToPage: aPage];
}



- (void) rotateClockwise:sender;
{
	int			i, amount, newAmount;
	PDFPage		*myPage;
	
	[self cleanupMarquee: YES];
	
	totalRotation = totalRotation + 90;
	if (totalRotation >= 360)
		totalRotation = totalRotation - 360;
	for (i = 0; i < totalPages; i++) {
		myPage = [[self document] pageAtIndex:i];
		amount = [myPage rotation];
		newAmount = amount + 90;
		[myPage setRotation: newAmount];
		}
	[self layoutDocumentView];
}

- (void) rotateCounterclockwise:sender;
{
	int			i, amount, newAmount;
	PDFPage		*myPage;
	
	[self cleanupMarquee: YES];
	
	totalRotation = totalRotation - 90;
	if (totalRotation < 0)
		totalRotation = totalRotation + 360;

	for (i = 0; i < totalPages; i++) {
		myPage = [[self document] pageAtIndex:i];
		amount = [myPage rotation];
		newAmount = amount - 90;
		[myPage setRotation: newAmount];
		}
	[self layoutDocumentView];
}

- (void) goBack:sender;
{
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE)) 
		[self cleanupMarquee: YES];
	[super goBack:sender];
}

- (void) goForward: sender;
{
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE)) 
		[self cleanupMarquee: YES];
	[super goForward:sender];
}

- (void) scaleChanged: (NSNotification *) notification
{
	float	theScale;
	int		magsize;
	
	theScale = [self scaleFactor];
	magsize = theScale * 100;
	[myScale setIntValue: magsize];
	[myScale1 setIntValue: magsize];
	[myScale display];
	[myStepper setIntValue: magsize];
	[myStepper1 setIntValue: magsize];
}
	
- (void) pageChanged: (NSNotification *) notification
{
	PDFPage			*aPage;
	int				pageNumber;
	int				numRows, i, newlySelectedRow;
	unsigned int	newPageIndex;
	
	
	aPage = [self currentPage];
	pageNumber = [[self document] indexForPage: aPage] + 1;
	[currentPage setIntValue: pageNumber];
	[currentPage1 setIntValue: pageNumber];
	
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
			[_outlineView selectRow: newlySelectedRow byExtendingSelection: NO];
			break;
		}
		else if ([[self document] indexForPage: [[outlineItem destination] page]] > newPageIndex)
		{
			newlySelectedRow = i - 1;
			[_outlineView selectRow: newlySelectedRow byExtendingSelection: NO];
			break;
		}
	}
	
	// Auto-scroll.
	if (newlySelectedRow != -1)
		[_outlineView scrollRowToVisible: newlySelectedRow];
}

- (double)magnification;
{
    double	magsize;
   
    magsize = [myScale intValue] / 100.0;
    return magsize;
}


- (void) changeScale: sender;
{
    int		scale;
    double	magSize;
    
	[self cleanupMarquee: YES];
	
    if (sender == myScale1)
        [myScale setIntValue: [myScale1 intValue]];
    scale = [myScale intValue];
    if (scale < 20) {
        scale = 20;
        [myScale setIntValue: scale];
        [myScale1 setIntValue: scale];
        [myScale display];
        }
    if (scale > 1000) {
        scale = 1000;
        [myScale setIntValue: scale];
        [myScale1 setIntValue: scale];
        [myScale display];
        }
    [[self window] makeFirstResponder: myScale];
    [myStepper setIntValue: scale];
    [myStepper1 setIntValue: scale];
    magSize = [self magnification];
    [self setScaleFactor: magSize];
	if (sender == myScale1) {
		[NSApp endSheet: [myDocument magnificationKitPanel]];
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

- (void) doStepper: sender;
{
    if (sender == myStepper) 
        [myScale setIntValue: [myStepper intValue]];
    else
        [myScale setIntValue: [myStepper1 intValue]];
    [self changeScale: self];
}


- (void) previousPage: (id)sender;
{
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE)) 
		[self cleanupMarquee: YES];
	[self goToPreviousPage:self];
}

- (void) nextPage: (id)sender;
{
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE)) 
		[self cleanupMarquee: YES];
	[self goToNextPage:sender];
}

- (void) firstPage: (id)sender;
{
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE)) 
		[self cleanupMarquee: YES];
	[self goToFirstPage:self];
}

- (void) lastPage: (id)sender;
{
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE)) 
		[self cleanupMarquee: YES];
	[self goToLastPage:sender];
}

- (void) goToKitPageNumber: (int) thePage;
{
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE)) 
		[self cleanupMarquee: YES];
	
	PDFPage	*aPage;
	
	if (thePage < 1)
		thePage = 1;
	if (thePage > totalPages)
		thePage = totalPages;
	
	[currentPage setIntValue: thePage];
	[currentPage1 setIntValue: thePage];
	[currentPage display];
	[[self window] makeFirstResponder: currentPage];
	
	thePage = thePage - 1; 
	aPage = [[self document] pageAtIndex: thePage];
	[self goToPage: aPage];
	
}


- (void) goToKitPage: (id)sender;
{
	int		thePage;
	
	if  ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE)) 
		[self cleanupMarquee: YES];
	thePage = [sender intValue];
	[self goToKitPageNumber: thePage];
	
	if (sender == currentPage1) 
		[NSApp endSheet:[myDocument pagenumberKitPanel]];

}



// action for menu items "Single Page/Two Page/Multi-Page/Double Multi-Page"
// -- tags should be correctly set
- (void)changePageStyle: (id)sender
{
	
	[self cleanupMarquee: YES];
	if ([sender tag] != pageStyle)
	{
		// mitsu 1.29b uncheck menu item Preview=>Display Format
		NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
							NSLocalizedString(@"Preview", @"Preview")] submenu];
		NSMenu *menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Display Format", @"Display Format")] submenu];
		NSMenuItem *item = [menu itemWithTag: pageStyle];
		[item setState: NSOffState];
		// end mitsu 1.29b
		
		// change page style
		pageStyle = [sender tag];
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
			[[self window] discardCachedImage];
		}
*/
	}
}


// action for menu items "Actual Size/Fixed Magnification/Fit To ..."
- (void)changePDFViewSize: (id)sender
{
	[self cleanupMarquee: YES];
	
	if (![sender tag]) return;

	NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
				NSLocalizedString(@"Preview", @"Preview")] submenu];
	NSMenu *menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Magnification", @"Magnification")] submenu];
	NSMenuItem *item =[menu itemWithTag: resizeOption];
	if (item) [item setState: NSOffState];
	
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
	item =[menu itemWithTag: resizeOption];
	if (item) [item setState: NSOnState];
	// end mitsu
}


- (void) copy: (id)sender;
{
	if (mouseMode != NEW_MOUSE_MODE_SELECT_PDF)
		[super copy:sender];
	else {
		NSString *dataType;
		NSPasteboard *pboard = [NSPasteboard generalPasteboard];
		int imageCopyType = [SUD integerForKey:PdfCopyTypeKey]; // mitsu 1.29b
	
		if (imageCopyType != IMAGE_TYPE_PDF && imageCopyType != IMAGE_TYPE_EPS && 
			imageCopyType != IMAGE_TYPE_PICT)
			dataType = NSTIFFPboardType;
		else if (imageCopyType == IMAGE_TYPE_PICT)
			dataType = NSPICTPboardType;
		else if (imageCopyType == IMAGE_TYPE_PDF)
			dataType = NSPDFPboardType;
		else if (imageCopyType == IMAGE_TYPE_EPS)
			dataType = NSPostScriptPboardType;
	
		NSData *data = [self imageDataFromSelectionType: imageCopyType];
		if (data)
			{
				[pboard declareTypes:[NSArray arrayWithObjects: dataType, nil] owner:self];
				[pboard setData:data forType:dataType]; 
			}
		else
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

- (int) outlineView: (NSOutlineView *) outlineView numberOfChildrenOfItem: (id) item
{
	if (item == NULL)
	{
		if (_outline)
			return [_outline numberOfChildren];
		else
			return 0;
	}
	else
		return [(PDFOutline *)item numberOfChildren];
}

// --------------------------------------------------------------------------------------------- outlineView:child:ofItem

- (id) outlineView: (NSOutlineView *) outlineView child: (int) index ofItem: (id) item
{
	if (item == NULL)
	{
		if (_outline)
			return [[_outline childAtIndex: index] retain];
		else
			return NULL;
	}
	else
		return [[(PDFOutline *)item childAtIndex: index] retain];
}

// ----------------------------------------------------------------------------------------- outlineView:isItemExpandable

- (BOOL) outlineView: (NSOutlineView *) outlineView isItemExpandable: (id) item
{
	if (item == NULL)
	{
		if (_outline)
			return ([_outline numberOfChildren] > 0);
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
	if ([[self document] isFinding])
		[[self document] cancelFindString];
	
	// Lazily allocate _searchResults.
	if (_searchResults == NULL)
		_searchResults = [[NSMutableArray arrayWithCapacity: 10] retain];
	
	[[self document] beginFindString: [sender stringValue] withOptions: NSCaseInsensitiveSearch];
}

// ------------------------------------------------------------------------------------------------------------ startFind

- (void) startFind: (NSNotification *) notification
{
	// Empty arrays.
	[_searchResults removeAllObjects];
	
	[_searchTable reloadData];
	[_searchProgress startAnimation: self];
}

// --------------------------------------------------------------------------------------------------------- findProgress

- (void) findProgress: (NSNotification *) notification
{
	double		pageIndex;
	
	pageIndex = [[[notification userInfo] objectForKey: @"PDFDocumentPageIndex"] doubleValue];
	[_searchProgress setDoubleValue: pageIndex / [[self document] pageCount]];
}

// ------------------------------------------------------------------------------------------------------- didMatchString
// Called when an instance was located. Delegates can instantiate.

- (void) didMatchString: (PDFSelection *) instance
{
	// Add page label to our array.
	[_searchResults addObject: [instance copy]];
	
	// Force a reload.
	[_searchTable reloadData];
}

// -------------------------------------------------------------------------------------------------------------- endFind

- (void) endFind: (NSNotification *) notification
{
	[_searchProgress stopAnimation: self];
	[_searchProgress setDoubleValue: 0];
}


#pragma mark ------ NSTableView delegate methods
// ---------------------------------------------------------------------------------------------- numberOfRowsInTableView

// The table view is used to hold search results.  Column 1 lists the page number for the search result, 
// column two the section in the PDF (x-ref with the PDF outline) where the result appears.

- (int) numberOfRowsInTableView: (NSTableView *) aTableView
{
	return ([_searchResults count]);
}

// ------------------------------------------------------------------------------ tableView:objectValueForTableColumn:row

- (id) tableView: (NSTableView *) aTableView objectValueForTableColumn: (NSTableColumn *) theColumn
		row: (int) rowIndex
{
	if ([[theColumn identifier] isEqualToString: @"page"])
		return ([[[[_searchResults objectAtIndex: rowIndex] pages] objectAtIndex: 0] label]);
	else if ([[theColumn identifier] isEqualToString: @"section"])
		return ([[[self document] outlineItemForSelection: [_searchResults objectAtIndex: rowIndex]] label]);
	else
		return NULL;
}

// ------------------------------------------------------------------------------------------ tableViewSelectionDidChange

- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
	int			rowIndex;
	
	// What was selected.  Skip out if the row has not changed.
	rowIndex = [(NSTableView *)[notification object] selectedRow];
	if (rowIndex >= 0)
	{
		[self setCurrentSelection: [_searchResults objectAtIndex: rowIndex]];
		[self centerSelectionInVisibleArea: self];
	}
}

- (void) changeMouseMode: (id)sender;
{
	int	oldMouseMode;
	
	oldMouseMode = mouseMode;

	if ([sender isKindOfClass: [NSButton class]] || [sender isKindOfClass: [NSMenuItem class]])
	{
		[[[myDocument mousemodeMenu] itemWithTag: mouseMode] setState: NSOffState]; 
		mouseMode = currentMouseMode = [sender tag];
		[[myDocument mousemodeMatrix] selectCellWithTag: mouseMode];
		[[[myDocument mousemodeMenu] itemWithTag: mouseMode] setState: NSOnState];
	}
	else if ([sender isKindOfClass: [NSMatrix class]])
	{
		[[[myDocument mousemodeMenu] itemWithTag: mouseMode] setState: NSOffState];
		mouseMode = currentMouseMode = [[sender selectedCell] tag];
		[[myDocument mousemodeMatrix] selectCellWithTag: mouseMode];
		[[[myDocument mousemodeMenu] itemWithTag: mouseMode] setState: NSOnState];
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
	NSNumber		*myNumber;
	NSPoint			aPoint;
	NSRect			aRect;

	initialLocation = [theEvent locationInWindow];
	visibleRect = [[self documentView] visibleRect];
    keepGoing = YES;

	[grabHandCursor() set];
	
    while (keepGoing)
    {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        switch ([theEvent type])
        {
            case NSLeftMouseDragged:
            {
                NSPoint	newLocation;
                NSRect	newVisibleRect;
                float	xDelta, yDelta;

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
	
	if (selRectTimer)
		mySelectedRect = [self convertRect: selectedRect fromView: [self documentView]];
		
	switch (currentMouseMode)
	{
		case NEW_MOUSE_MODE_SCROLL: 
			[super resetCursorRects];
			[self addCursorRect:[self visibleRect] cursor:openHandCursor()];
			break;
		case NEW_MOUSE_MODE_SELECT_TEXT: 
			[super resetCursorRects];
			break;
		case NEW_MOUSE_MODE_SELECT_PDF: 
			[super resetCursorRects];
			[self addCursorRect:[self visibleRect] cursor:[NSCursor _crosshairCursor]];
			if (selRectTimer)
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

- (void)setIndexForMark: (int)index;
{
	pageIndexForMark = index;
}

- (void)setBoundsForMark: (NSRect)bounds;
{
	pageBoundsForMark = bounds;
}

- (void)setDrawMark: (BOOL)value;
{
	drawMark = value;
}


- (void)drawPage:(PDFPage *)page
{
	int					pagenumber;
	NSPoint				p;
	int					rotation;
	NSRect				boxRect, tempRect;
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
		[transform rotateByDegrees: 270];
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
		[transform rotateByDegrees: 90];
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
			// NSDrawWindowBackground(boxRect);
			}
		}
	
	else


	NSDrawWindowBackground(boxRect);
	
	[NSGraphicsContext restoreGraphicsState];
	[page drawWithBox:[self displayBox]];
	
	// Set up transform to handle rotated page.
	
switch (rotation)
	{
		case 90:
		transform = [NSAffineTransform transform];
		[transform translateXBy: 0 yBy: boxRect.size.width];
		[transform rotateByDegrees: 270];
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
		[transform rotateByDegrees: 90];
		[transform concat];
		break;
	}
	
	p.x = 0; p.y = 0;
	pagenumber = [[self document] indexForPage:page];
	[self drawDotsForPage:pagenumber atPoint: p];
	
	int theIndex = [[self document] indexForPage: page];
	if (drawMark && (theIndex == pageIndexForMark)) {
		NSBezierPath *myPath = [NSBezierPath bezierPathWithOvalInRect: pageBoundsForMark];
		NSColor *myColor = [NSColor redColor];
		[myColor set];
		[myPath stroke];
		}
	
}

#pragma mark =====mouse routines=====

- (void) mouseDown: (NSEvent *) theEvent
{

		// koch; Dec 5, 2003
		
        if (!([theEvent modifierFlags] & NSAlternateKeyMask) && ([theEvent modifierFlags] & NSCommandKeyMask)) {
                currentMouseMode = mouseMode;
                [[self window] invalidateCursorRectsForView: self];
                [self doSync: theEvent];
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
				if(selRectTimer && [self mouse: [self convertPoint: 
					[theEvent locationInWindow] fromView: nil] inRect: [self convertRect:selectedRect fromView: [self documentView]]])
				{
					// mitsu 1.29 drag & drop
					// Koch: I commented out the moveSelection choice since it seems to be broken due to sync
					// if (([theEvent modifierFlags] & NSCommandKeyMask) && 
					//					(mouseMode == NEW_MOUSE_MODE_SELECT_PDF))
					//	[self moveSelection: theEvent];
					// else
						[self startDragging: theEvent]; 
					// end mitsu 1.29
				}
				else
					[self selectARect: theEvent];
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
		return;
		}
		
	if (downOverLink) {
		[super mouseMoved: theEvent];
		return;
		}

	if (([self areaOfInterestForMouse: theEvent] & kPDFLinkArea) != 0)
			[[NSCursor pointingHandCursor] set];
	else if (([self areaOfInterestForMouse: theEvent] & kPDFPageArea) != 0)
			switch (mouseMode) {
				case NEW_MOUSE_MODE_SCROLL:
							[[NSCursor openHandCursor] set];
							break;
							
				case NEW_MOUSE_MODE_SELECT_PDF:
							[[NSCursor _crosshairCursor] set];
							break;
				case NEW_MOUSE_MODE_MAG_GLASS:
				case NEW_MOUSE_MODE_MAG_GLASS_L: 
							[[NSCursor arrowCursor] set];
							break;
				}
	else 
		[super mouseMoved: theEvent];
		
	/*
	
	switch (mouseMode) {
	
		case NEW_MOUSE_MODE_SCROLL:				break;
	
		case NEW_MOUSE_MODE_SELECT_TEXT:		[super mouseMoved: theEvent];
												break;
												
		case NEW_MOUSE_MODE_MAG_GLASS:			break;
		
		case NEW_MOUSE_MODE_MAG_GLASS_L:		break;
		
		case NEW_MOUSE_MODE_SELECT_PDF:			break;
		
		}
	*/


/*
	NSPoint		cursorLocation;
	PDFPage		*page;
	int			edgeHit = -1;
	
	if ([(MyPDFDocument *)_controller mode] == kViewPDFMode)
	{
		[super mouseMoved: theEvent];
		return;
	}
	
	// Convert to view space.
	cursorLocation = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
	
	// Over a page?
	page = [self pageForPoint: cursorLocation nearest: NO];
	if (page)
	{
		// Convert to page space.
		cursorLocation = [self convertPoint: cursorLocation toPage: page];
		edgeHit = [self edgeHitTest: cursorLocation];
	}
	
	switch (edgeHit)
	{
		case 0:
		case 1:
		[[NSCursor resizeLeftRightCursor] set];
		break;
		
		case 2:
		case 3:
		[[NSCursor resizeUpDownCursor] set];
		break;
		
		default:
		[[NSCursor arrowCursor] set];
		break;
	}
*/
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


	
/*
	PDFPage			*page;
	NSPoint			point;
	PDFAnnotation	*annotation;
	
	// In View mode, let PDFView handle the event.
	if ([(MyPDFDocument *)_controller mode] == kViewPDFMode)
	{
		[super mouseDown: theEvent];
		return;
	}
	
	// Handle edit mode.
	// Mouse in view coordinates.
	_mouseDownLocation = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
	
	// Page we're over.
	page = [self pageForPoint: _mouseDownLocation nearest: NO];
	point = [self convertPoint: _mouseDownLocation toPage: page];
	
	// Test first to see if we are re-sizing the selected annotation.
	_partHit = [self edgeHitTest: point];
	if (_partHit != -1)
	{
		return;
	}
	
	// Get annotation we're over (if any).
	annotation = [page annotationAtPoint: point];
	if ((annotation) && ([[annotation type] isEqualToString: @"Link"]))
	{
		_partHit = 4;
		
		if (annotation != _selectedAnnotation)
		{
			// Old select annotation is going away - need to redraw.
			if (_selectedAnnotation)
			{
				[self setNeedsDisplayInRect: [self convertRect: [_selectedAnnotation bounds] fromPage: 
						[_selectedAnnotation page]]];
			}
			
			// Assign new annotation.
			_selectedAnnotation = (PDFAnnotationLink *)annotation;
			_oldAnnotationBounds = [_selectedAnnotation bounds];
			
			// Will also need to be redrawn.
			[self setNeedsDisplayInRect: [self convertRect: [_selectedAnnotation bounds] fromPage: 
					[_selectedAnnotation page]]];
			
			// Send notification.
			[[NSNotificationCenter defaultCenter] postNotificationName: @"LinkSelected" object: _selectedAnnotation];
		}
	}
	else
	{
		// Old select annotation is being de-selected - need to redraw.
		if (_selectedAnnotation)
		{
			[self setNeedsDisplayInRect: [self convertRect: [_selectedAnnotation bounds] fromPage: 
					[_selectedAnnotation page]]];
			
			// Nothing selected.
			_selectedAnnotation = NULL;
			_partHit = -1;
			
			// Send notification.
			[[NSNotificationCenter defaultCenter] postNotificationName: @"LinkSelected" object: _selectedAnnotation];
		}
	}
}
*/


// ------------------------------------------------------------------------------------------- windowControllerDidLoadNib

/*
- (void) windowControllerDidLoadNib: (NSWindowController *) controller
{
	NSSize		windowSize;
	
	// Super.
	[super windowControllerDidLoadNib: controller];
	
	// Load PDF.
	if ([self fileName])
	{
		PDFDocument	*pdfDoc;
		PDFPage	*aPage;
		
		pdfDoc = [[[PDFDocument alloc] initWithURL: [NSURL fileURLWithPath: [self fileName]]] autorelease];
		[_pdfView setDocument: pdfDoc];
		aPage = [pdfDoc pageAtIndex:0];
		[aPage setRotation:90];
		[_pdfView layoutDocumentView];
	}
	

	
	// Page changed notification.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pageChanged:) 
			name: PDFViewPageChangedNotification object: NULL];
	
	
	// My own internal notification to indicate that the Link selection has changed.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(linkSelected:) 
			name: @"LinkSelected" object: NULL];
	
	// Set self to be delegate (find).
	[[_pdfView document] setDelegate: self];
	
	// Get outline.
	_outline = [[[_pdfView document] outlineRoot] retain];
	if (_outline)
	{
		// Remove text that says, "No outline."
		[_noOutlineText removeFromSuperview];
		_noOutlineText = NULL;
		
		// Force it to load up.
		[_outlineView reloadData];
	}
	else
	{
		// Remove outline view (leaving instead text that says, "No outline.").
		[[_outlineView enclosingScrollView] removeFromSuperview];
		_outlineView = NULL;
	}
	
	// Open drawer.
	[_drawer open];
	
	// Size the window.
	windowSize = [[[_pdfView document] pageAtIndex: 0] boundsForBox: [_pdfView displayBox]].size;
	if (([_pdfView displayMode] == kPDFDisplaySinglePageContinuous) || 
			([_pdfView displayMode] == kPDFDisplayTwoUpContinuous))
	{
		windowSize.width += [NSScroller scrollerWidth];
	}
	
	windowSize.height += 75.0 - [NSScroller scrollerWidth];
	
	[[controller window] setContentSize: windowSize];
	
	// Set up segmented control for view/edit widget.
	[[_modeControl cell] setSegmentCount: 2];
	[[_modeControl cell] setImage: [NSImage imageNamed: @"PDFViewAdorn"] forSegment: kViewPDFMode];
	[[_modeControl cell] setImage: [NSImage imageNamed: @"PDFEditAdorn"] forSegment: kEditPDFMode];
	[[_modeControl cell] setTag: kViewPDFMode forSegment: kViewPDFMode];
	[[_modeControl cell] setTag: kEditPDFMode forSegment: kEditPDFMode];
//	[[_modeControl cell] setAction: @selector(setTabView:)];
	[[_modeControl cell] setTrackingMode: NSSegmentSwitchTrackingSelectOne];
	[_modeControl sizeToFit];
	[_modeControl setSelectedSegment: kViewPDFMode];
	
	// Initially in viewing mode.
	[self setViewMode: self];

}
*/

/*

// --------------------------------------------------------------------------------------------------------- linkSelected

- (void) linkSelected: (NSNotification *) notification
{
	// Update Info button enable state.
	[_infoButton setEnabled: ([notification object] != NULL)];
}


#pragma mark ------ View and Edit modes
// ----------------------------------------------------------------------------------------------------------------- mode

- (int) mode
{
	return _mode;
}

// ----------------------------------------------------------------------------------------------------------- modeSwitch

- (void) modeSwitch: (id) sender
{
	// Set mode.
	if ([sender selectedSegment] == kViewPDFMode)
		[self setViewMode: self];
	else if ([sender selectedSegment] == kEditPDFMode)
		[self setEditMode: self];
}

// ---------------------------------------------------------------------------------------------------------- setViewMode

- (void) setViewMode: (id) sender
{
	// Assign mode.
	_mode = kViewPDFMode;
	
	// Enable/disable New Link button as appropriate.
	[_newLinkButton setEnabled: NO];
	[_infoButton setEnabled: NO];
	
	[_pdfView setSelectedAnnotation: NULL];
	[_pdfView setNeedsDisplay: YES];
}

// ---------------------------------------------------------------------------------------------------------- setEditMode

- (void) setEditMode: (id) sender
{
	// Assign mode.
	_mode = kEditPDFMode;
	
	// Enable/disable New Link button as appropriate.
	[_newLinkButton setEnabled: YES];
	
	[_pdfView clearSelection];
	[_pdfView setNeedsDisplay: YES];
}

// -------------------------------------------------------------------------------------------------------------- newLink

- (void) newLink: (id) sender
{
	PDFPage				*currentPage;
	NSRect				pageBounds;
	NSRect				bounds;
	PDFAnnotationLink	*newLink;
	
	currentPage = [_pdfView currentPage];
	pageBounds = [currentPage boundsForBox: [_pdfView displayBox]];
	
	// Center a rectangle on the page.
	bounds = NSMakeRect(0.0, 0.0, 120.0, 20.0);
	bounds = NSOffsetRect(bounds, (pageBounds.size.width - bounds.size.width) / 2.0, 
			(pageBounds.size.height - bounds.size.height) / 2.0);
	
	// Create annotation.
	newLink = [[PDFAnnotationLink alloc] initWithBounds: bounds];
	
	// Assign to page.
	[currentPage addAnnotation: newLink];
	
	// Lazy.
	[_pdfView setNeedsDisplay: YES];
	
	// Clean up.
	[newLink release];
}

// -------------------------------------------------------------------------------------------------------------- getInfo

- (void) getInfo: (id) sender
{
	PDFAnnotationLink	*annotation;
	
	// Get selected annotation.
	annotation = [_pdfView selectedAnnotation];
	
	// Shouldn't happen...
	if (annotation == NULL)
		return;
	
	// URL or page-point destination?
	[self setupPageLinkFields: [[_pdfView selectedAnnotation] destination]];
	[self setupURLLinkFields: [[_pdfView selectedAnnotation] URL]];
	
	// Select initial tab correctly.
	if ([[_pdfView selectedAnnotation] destination] != NULL)
	{
		[_linkTab selectTabViewItemAtIndex: 0];
		[_linkMatrix selectCellAtRow: 0 column: 0];
	}
	else if ([[_pdfView selectedAnnotation] URL] != NULL)
	{
		[_linkTab selectTabViewItemAtIndex: 1];
		[_linkMatrix selectCellAtRow: 1 column: 0];
	}
	
	// Bring up the page number panel as a sheet.
	[NSApp beginSheet: _linkPanel modalForWindow: _myWindow modalDelegate: self 
			didEndSelector: @selector(infoSheetDidEnd: returnCode: contextInfo:) contextInfo: NULL];
}

// ------------------------------------------------------------------------------------------------------ infoSheetDidEnd

- (void) infoSheetDidEnd: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void  *) contextInfo
{
	// Page or URL link?
	if ([_linkTab indexOfTabViewItem: [_linkTab selectedTabViewItem]] == 0)
	{
		int				pageIndex;
		NSPoint			thePoint;
		PDFDestination	*newDestination;
		
		// Page link.
		// Get the page index from the page index text field.
		pageIndex = [_linkPageField intValue];
		
		// Range error?
		if ((pageIndex < 1) || (pageIndex > [[_pdfView document] pageCount]))
		{
			PDFPage		*thePage;
			
			// Return to legal value, bail.
			thePage = [[_pdfView selectedAnnotation] page];
			pageIndex =  [[thePage document] indexForPage: thePage] + 1;
			NSBeep();
		}
		
		// Get the original point.
		thePoint = [[[_pdfView selectedAnnotation] destination] point];
		
		// Create a new destination.
		newDestination = [[PDFDestination alloc] initWithPage: [[_pdfView document] pageAtIndex: pageIndex - 1] 
				atPoint: thePoint];
		
		// Assign new destination.
		[[_pdfView selectedAnnotation] setDestination: newDestination];
		
		// Done with destination.
		[newDestination release];
	}
	else
	{
		// URL link.
		[[_pdfView selectedAnnotation] setDestination: NULL];
		[[_pdfView selectedAnnotation] setURL: [NSURL URLWithString: [_linkURLField stringValue]]];
	}
	
	[_linkPanel close];
}

#pragma mark ------ Info panel
// ------------------------------------------------------------------------------------------------------ linkTypeChanged

- (void) linkTypeChanged: (id) sender
{
	[_linkTab selectTabViewItemAtIndex: [(NSMatrix *)sender selectedRow]];
}

// -------------------------------------------------------------------------------------------------- setupPageLinkFields

- (void) setupPageLinkFields: (PDFDestination *) destination
{
	PDFPage		*thePage;
	
	// Get the page.
	if (destination)
		thePage = [destination page];
	else
		thePage = [[_pdfView selectedAnnotation] page];
	
	// Set up page value.
	if (destination)
		[_linkPageField setIntValue: [[thePage document] indexForPage: thePage] + 1];
	else
		[_linkPageField setIntValue: 1];
	
	// Display page range.
	[_linkPageRange setStringValue: [NSString stringWithFormat: @"(1 to %d)", [[thePage document] pageCount]]];
}

// --------------------------------------------------------------------------------------------------- setupURLLinkFields

- (void) setupURLLinkFields: (NSURL *) url
{
	// Set up page value.
	if (url)
		[_linkURLField setStringValue: [url absoluteString]];
	else
		[_linkURLField setStringValue: @"http://"];
}

// ------------------------------------------------------------------------------------------------------ linkPageChanged

- (void) linkPageChanged: (id) sender
{
	int			pageIndex;
	
	// Get the page index from the page index text field.
	pageIndex = [_linkPageField intValue];
	
	// Range error?
	if ((pageIndex < 1) || (pageIndex > [[_pdfView document] pageCount]))
	{
		PDFPage		*thePage;
		
		// Reset to legal value, bail.
		thePage = [[_pdfView selectedAnnotation] page];
		[_linkPageField setIntValue: [[thePage document] indexForPage: thePage] + 1];
		NSBeep();
	}
}

// ------------------------------------------------------------------------------------------------------- linkURLChanged

- (void) linkURLChanged: (id) sender
{
}

// ------------------------------------------------------------------------------------------------------------- infoDone

- (void) infoDone: (id) sender
{
	// Done.
	[NSApp endSheet: _linkPanel returnCode: 0];
}

// ----------------------------------------------------------------------------------------------------- validateMenuItem
*/

- (BOOL) validateMenuItem: (id) menuItem
{
	BOOL		enable = YES;

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
	
	return enable;
}



/*
@implementation MyPDFKitView
// ======================================================================================================== MyPDFDocument
// --------------------------------------------------------------------------------------------------- selectedAnnotation

- (PDFAnnotationLink *) selectedAnnotation
{
	return _selectedAnnotation;
}

// ------------------------------------------------------------------------------------------------ setSelectedAnnotation

- (void) setSelectedAnnotation: (PDFAnnotationLink *) annotation
{
	_selectedAnnotation = annotation;
}

// ---------------------------------------------------------------------------------------------------------- edgeHitTest

- (int) edgeHitTest: (NSPoint) point
{
	int		whichEdge = -1;
	
	if (_selectedAnnotation)
	{
		NSRect		bounds;
		NSRect		edge;
		
		// Annotation bounds.
		bounds = [_selectedAnnotation bounds];
		
		// Hit-detect left edge first.
		edge = NSMakeRect(-2.0, 0.0, 5.0, bounds.size.height);
		edge = NSOffsetRect(edge, NSMinX(bounds), NSMinY(bounds));
		if (NSPointInRect(point, edge))
		{
			whichEdge = 0;
			goto done;
		}
		
		// Hit-detect right edge.
		edge = NSMakeRect(-2.0, 0.0, 5.0, bounds.size.height);
		edge = NSOffsetRect(edge, NSMaxX(bounds), NSMinY(bounds));
		if (NSPointInRect(point, edge))
		{
			whichEdge = 1;
			goto done;
		}
		
		// Hit-detect bottom edge.
		edge = NSMakeRect(0.0, -2.0, bounds.size.width, 5.0);
		edge = NSOffsetRect(edge, NSMinX(bounds), NSMinY(bounds));
		if (NSPointInRect(point, edge))
		{
			whichEdge = 2;
			goto done;
		}
		
		// Hit-detect top edge.
		edge = NSMakeRect(0.0, -2.0, bounds.size.width, 5.0);
		edge = NSOffsetRect(edge, NSMinX(bounds), NSMaxY(bounds));
		if (NSPointInRect(point, edge))
		{
			whichEdge = 3;
			goto done;
		}
	}
	
done:
	
	return whichEdge;
}

// ------------------------------------------------------------------------------------------------------------- drawPage

- (void) drawPage: (PDFPage *) pdfPage
{
	NSRect				boxRect;
	int					rotation;
	NSAffineTransform   *transform;
	
	[super drawPage: pdfPage];
	
	// Set up transform to handle rotated page.
	boxRect = [pdfPage boundsForBox: [self displayBox]];
	
	rotation = [pdfPage rotation];
	switch (rotation)
	{
		case 90:
		transform = [NSAffineTransform transform];
		[transform translateXBy: 0 yBy: boxRect.size.height];
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
		[transform translateXBy: boxRect.size.width yBy: 0];
		[transform rotateByDegrees: 360 - rotation];
		[transform concat];
		break;
	}
	
	if ([(MyPDFDocument *)_controller mode] == kEditPDFMode)
	{
		NSArray		*annotations;
		int			count;
		int			i;
		
		// Handle edit mode.
		// Walk through annotations (if any) looking for Link annotations.
		annotations = [pdfPage annotations];
		count = [annotations count];
		for (i = 0; i < count; i++)
		{
			// Only interested in link annotations.
			if ([[(PDFAnnotation *)[annotations objectAtIndex: i] type] isEqualToString: @"Link"])
			{
				NSRect		bounds;
				
				bounds = [(PDFAnnotation *)[annotations objectAtIndex: i] bounds];
				
				if ([annotations objectAtIndex: i] == _selectedAnnotation)
				{
					[[NSColor redColor] set];
					NSFrameRectWithWidth(bounds, 2.0);
				}
				else
				{
					[[NSColor grayColor] set];
					NSFrameRectWithWidth(bounds, 2.0);
				}
			}
		}
	}
}

// ----------------------------------------------------------------------------------------------------------- mouseMoved

- (void) mouseMoved: (NSEvent *) theEvent
{
	NSPoint		cursorLocation;
	PDFPage		*page;
	int			edgeHit = -1;
	
	if ([(MyPDFDocument *)_controller mode] == kViewPDFMode)
	{
		[super mouseMoved: theEvent];
		return;
	}
	
	// Convert to view space.
	cursorLocation = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
	
	// Over a page?
	page = [self pageForPoint: cursorLocation nearest: NO];
	if (page)
	{
		// Convert to page space.
		cursorLocation = [self convertPoint: cursorLocation toPage: page];
		edgeHit = [self edgeHitTest: cursorLocation];
	}
	
	switch (edgeHit)
	{
		case 0:
		case 1:
		[[NSCursor resizeLeftRightCursor] set];
		break;
		
		case 2:
		case 3:
		[[NSCursor resizeUpDownCursor] set];
		break;
		
		default:
		[[NSCursor arrowCursor] set];
		break;
	}
}

// ------------------------------------------------------------------------------------------------------------ mouseDown

- (void) mouseDown: (NSEvent *) theEvent
{
	PDFPage			*page;
	NSPoint			point;
	PDFAnnotation	*annotation;
	
	// In View mode, let PDFView handle the event.
	if ([(MyPDFDocument *)_controller mode] == kViewPDFMode)
	{
		[super mouseDown: theEvent];
		return;
	}
	
	// Handle edit mode.
	// Mouse in view coordinates.
	_mouseDownLocation = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
	
	// Page we're over.
	page = [self pageForPoint: _mouseDownLocation nearest: NO];
	point = [self convertPoint: _mouseDownLocation toPage: page];
	
	// Test first to see if we are re-sizing the selected annotation.
	_partHit = [self edgeHitTest: point];
	if (_partHit != -1)
	{
		return;
	}
	
	// Get annotation we're over (if any).
	annotation = [page annotationAtPoint: point];
	if ((annotation) && ([[annotation type] isEqualToString: @"Link"]))
	{
		_partHit = 4;
		
		if (annotation != _selectedAnnotation)
		{
			// Old select annotation is going away - need to redraw.
			if (_selectedAnnotation)
			{
				[self setNeedsDisplayInRect: [self convertRect: [_selectedAnnotation bounds] fromPage: 
						[_selectedAnnotation page]]];
			}
			
			// Assign new annotation.
			_selectedAnnotation = (PDFAnnotationLink *)annotation;
			_oldAnnotationBounds = [_selectedAnnotation bounds];
			
			// Will also need to be redrawn.
			[self setNeedsDisplayInRect: [self convertRect: [_selectedAnnotation bounds] fromPage: 
					[_selectedAnnotation page]]];
			
			// Send notification.
			[[NSNotificationCenter defaultCenter] postNotificationName: @"LinkSelected" object: _selectedAnnotation];
		}
	}
	else
	{
		// Old select annotation is being de-selected - need to redraw.
		if (_selectedAnnotation)
		{
			[self setNeedsDisplayInRect: [self convertRect: [_selectedAnnotation bounds] fromPage: 
					[_selectedAnnotation page]]];
			
			// Nothing selected.
			_selectedAnnotation = NULL;
			_partHit = -1;
			
			// Send notification.
			[[NSNotificationCenter defaultCenter] postNotificationName: @"LinkSelected" object: _selectedAnnotation];
		}
	}
}

// --------------------------------------------------------------------------------------------------------- mouseDragged

- (void) mouseDragged: (NSEvent *) theEvent
{
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
}

// -------------------------------------------------------------------------------------------------------------- mouseUp

- (void) mouseUp: (NSEvent *) theEvent
{
	if ([(MyPDFDocument *)_controller mode] == kViewPDFMode)
	{
		[super mouseUp: theEvent];
		return;
	}
	
	// Handle edit mode.
	if ((_partHit != -1) && (_selectedAnnotation))
		_oldAnnotationBounds = [_selectedAnnotation bounds];
}

*/

#pragma mark =====select and copy=====

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

- (void)selectARect: (NSEvent *)theEvent
{
    NSPoint mouseLocWindow, startPoint, currentPoint;
	NSRect myBounds, selRectWindow, selRectSuper;
	NSBezierPath *path = [NSBezierPath bezierPath];
	BOOL startFromCenter = NO;
	static int phase = 0;
	float xmin, xmax, ymin, ymax, pattern[] = {3,3};
	
	[path setLineWidth: 0.01];
	mouseLocWindow = [theEvent locationInWindow];
	startPoint = [[self documentView] convertPoint: mouseLocWindow fromView:nil];
	[NSEvent startPeriodicEventsAfterDelay: 0 withPeriod: 0.2];
	[self cleanupMarquee: YES];
	[[self window] discardCachedImage];
	
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
			[[self window] restoreCachedImage];
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
			[[self window] cacheImageInRect:NSInsetRect(selRectWindow, -2, -2)];
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
                        NSString *sizeString = [NSString stringWithFormat: @"%d x %d", 
				(int)floor(selRectWindow.size.width), (int)floor(selRectWindow.size.height)];
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
		selRectTimer = [NSTimer scheduledTimerWithTimeInterval: 0.2 target:self 
			selector:@selector(updateMarquee:) userInfo:nil repeats:YES];
		oldVisibleRect = [[self documentView] visibleRect];
	}
	else
	{
		selRectTimer = nil;
		[[self window] restoreCachedImage];
		[[self window] flushWindow];
		[[self window] discardCachedImage];
	}
	[self flagsChanged: theEvent]; // update cursor
#ifndef DO_NOT_SHOW_SELECTION_SIZE
	[sizeWindow close];
#endif
}
/*
{
    NSPoint mouseLocWindow, startPoint, currentPoint;
	NSRect myBounds, selRectWindow, selRectSuper;
	NSBezierPath *path = [NSBezierPath bezierPath];
	BOOL startFromCenter = NO;
	static int phase = 0;
	float xmin, xmax, ymin, ymax, pattern[] = {3,3};
	
	[path setLineWidth: 0.01];
	mouseLocWindow = [theEvent locationInWindow];
	startPoint = [self convertPoint: mouseLocWindow fromView:nil];
	[NSEvent startPeriodicEventsAfterDelay: 0 withPeriod: 0.2];
	[self cleanupMarquee: YES];
	[[self window] discardCachedImage];
	
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
			[[self window] restoreCachedImage];
			[[self window] flushWindow];
			// get Mouse location and check if it is with the view's rect
			if (!([theEvent type]==NSFlagsChanged || [theEvent type]==NSPeriodic))
			{
				mouseLocWindow = [theEvent locationInWindow];
				// scroll if the mouse is out of visibleRect
				[self autoscroll: theEvent];
			}
			// calculate the rect to select
			currentPoint = [self convertPoint: mouseLocWindow fromView:nil];
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
			myBounds = [self bounds];
			xmin = fmax(selectedRect.origin.x, myBounds.origin.x);
			xmax = fmin(selectedRect.origin.x+selectedRect.size.width, 
						myBounds.origin.x+myBounds.size.width);
			ymin = fmax(selectedRect.origin.y, myBounds.origin.y);
			ymax = fmin(selectedRect.origin.y+selectedRect.size.height, 
						myBounds.origin.y+myBounds.size.height);
			selectedRect = NSMakeRect(xmin,ymin,xmax-xmin,ymax-ymin);
			// do not use selectedRect = NSIntersectionRect(selectedRect, [self bounds]);
			selRectWindow = [self convertRect: selectedRect toView: nil];
			// cache the window image
			[[self window] cacheImageInRect:NSInsetRect(selRectWindow, -2, -2)];
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
                        NSString *sizeString = [NSString stringWithFormat: @"%d x %d", 
				(int)floor(selRectWindow.size.width), (int)floor(selRectWindow.size.height)];
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
		selRectTimer = [NSTimer scheduledTimerWithTimeInterval: 0.2 target:self 
			selector:@selector(updateMarquee:) userInfo:nil repeats:YES];
		oldVisibleRect = [self visibleRect];
	}
	else
	{
		selRectTimer = nil;
		[[self window] restoreCachedImage];
		[[self window] flushWindow];
		[[self window] discardCachedImage];
	}
	[self flagsChanged: theEvent]; // update cursor
#ifndef DO_NOT_SHOW_SELECTION_SIZE
	[sizeWindow close];
#endif
}
*/

- (void)selectAll: (id)sender;
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
	static int phase = 0;
	float pattern[] = {3,3};
	
	[path setLineWidth: 0.01];
	[self cleanupMarquee: YES];
	[[self window] discardCachedImage];
        			            
        // restore the cached image in order to clear the rect
        [[self window] restoreCachedImage];
                        
        selectedRect = [self frame];
		// FIX THIS: KOCH
        // selectedRect.size.width = totalWidth;
        //selectedRect.size.height = totalHeight;
        selRectWindow = [self convertRect: selectedRect toView: nil];
        // cache the window image
        [[self window] cacheImageInRect:NSInsetRect(selRectWindow, -2, -2)];
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
			
	selRectTimer = [NSTimer scheduledTimerWithTimeInterval: 0.2 target:self 
			selector:@selector(updateMarquee:) userInfo:nil repeats:YES];
	oldVisibleRect = [self visibleRect];
    }

}



// updates the frame of selected rectangle
- (void)updateMarquee: (NSTimer *)timer
{
	static int phase = 0;
	float pattern[2] = {3,3};
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

/*
{
	static int phase = 0;
	float pattern[2] = {3,3};
	NSView *clipView;
	NSRect selRectSuper, clipBounds;
	NSBezierPath *path;
	
	if ([[self window] isMainWindow])
	{
		clipView = [self superview];
		clipBounds = [clipView bounds];
		[clipView lockFocus];
		[[NSGraphicsContext currentContext] setShouldAntialias: NO];
		selRectSuper = [self convertRect:selectedRect toView: clipView];
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
*/

// earses the frame of selected rectangle and cleans up the cached image
- (void)cleanupMarquee: (BOOL)terminate
{
	NSRect		tempRect;
	
	if (selRectTimer)
	{
		NSRect visRect = [[self documentView] visibleRect];
		// if (NSEqualRects(visRect, oldVisibleRect))
		//	[[self window] restoreCachedImage];
                // change by mitsu to cleanup marquee immediately
                if (NSEqualRects(visRect, oldVisibleRect))
		{
			[[self window] restoreCachedImage];
			[[self window] flushWindow];
		}
		else // the view was moved--do not use the cached image
		{
			[[self window] discardCachedImage];
			tempRect =  [self convertRect: NSInsetRect(
				NSIntegralRect([[self documentView] convertRect: selectedRect toView: nil]), -2, -2) 
				fromView: nil];
			[self displayRect: tempRect];
		}
		oldVisibleRect.size.width = 0; // do not use this cache again
		if (terminate)
		{
			[selRectTimer invalidate]; // this will release the timer
			selRectTimer = nil;
		}
	}
}
/*
{
	if (selRectTimer)
	{
		NSRect visRect = [self visibleRect];
		// if (NSEqualRects(visRect, oldVisibleRect))
		//	[[self window] restoreCachedImage];
                // change by mitsu to cleanup marquee immediately
                if (NSEqualRects(visRect, oldVisibleRect))
		{
			[[self window] restoreCachedImage];
			[[self window] flushWindow];
		}
		else // the view was moved--do not use the cached image
		{
			[[self window] discardCachedImage];
			[self displayRect: [self convertRect: NSInsetRect(
				NSIntegralRect([self convertRect: selectedRect toView: nil]), -2, -2) 
				fromView: nil]];
		}
		oldVisibleRect.size.width = 0; // do not use this cache again
		if (terminate)
		{
			[selRectTimer invalidate]; // this will release the timer
			selRectTimer = nil;
		}
	}
}
*/

// recache the image around selected rectangle for quicker response
- (void)recacheMarquee
{
	if (selRectTimer)
	{
		[[self window] cacheImageInRect: 
					NSInsetRect([[self documentView] convertRect: selectedRect toView: nil], -2, -2)];
		oldVisibleRect = [self visibleRect];
	}
}

// The following command probably moved the selection marquee; I have commented it out
// since it is replaced by sync; Koch, March 26, 2005
- (void)moveSelection: (NSEvent *)theEvent
{
/*
    NSPoint startPointWindow, startPointView, mouseLocWindow, mouseLocView, mouseLocScreen;
	NSRect originalSelRect, selRectWindow, selRectSuper, screenFrame;
	NSRect mySelectedRect;
	float deltaX, deltaY, pattern[] = {3,3};
	NSBezierPath *path = [NSBezierPath bezierPath];
	static int phase = 0;
	
	mySelectedRect = [self convertRect: selectedRect fromView: [self documentView]];
	
	if (!selRectTimer) return;
	startPointWindow = mouseLocWindow = [theEvent locationInWindow];
	startPointView = mouseLocView = [self convertPoint: startPointWindow fromView:nil];
	originalSelRect = mySelectedRect;
	[NSEvent startPeriodicEventsAfterDelay: 0 withPeriod: 0.2];
	[self cleanupMarquee: NO];
	[path setLineWidth: 0.01];
	
	do {
		if ([theEvent type]==NSLeftMouseDragged || [theEvent type]==NSLeftMouseDown || 
			[theEvent type]==NSFlagsChanged || [theEvent type]==NSPeriodic) 
		{	            
			// restore the cached image in order to clear the rect
			[[self window] restoreCachedImage];
			// get Mouse location and check if it is with the view's rect
			if (!([theEvent type]==NSFlagsChanged || [theEvent type]==NSPeriodic))
			{
				mouseLocWindow = [theEvent locationInWindow];
				// scroll if the mouse is out of visibleRect
				[self autoscroll: theEvent];
			}
			// calculate the rect to select
			mouseLocView = [self convertPoint: mouseLocWindow fromView:nil];
			deltaX = mouseLocView.x-startPointView.x;
			deltaY = mouseLocView.y-startPointView.y;
			if ([theEvent modifierFlags] & NSShiftKeyMask)
			{
				if (fabs(deltaX) >= fabs(deltaY))
					deltaY = 0;
				else
					deltaX = 0;
			}
			mySelectedRect.origin.x = originalSelRect.origin.x + deltaX;
			mySelectedRect.origin.y = originalSelRect.origin.y + deltaY;
			// cache the window image
			selRectWindow = [self convertRect: mySelectedRect toView: nil];
			[[self window] cacheImageInRect:NSInsetRect(selRectWindow, -2, -2)];
			// draw rect frame
			[path removeAllPoints]; // reuse path
			// in order to draw a clear frame we draw an adjusted rect in clip view
			selRectSuper = [[self superview] convertRect:selRectWindow fromView: nil];
			if (!NSIsEmptyRect(selRectSuper))
			{	// shift the coordinated by a half integer
				selRectSuper = NSInsetRect(NSIntegralRect(selRectSuper), .5, .5);
				[path appendBezierPathWithRect: selRectSuper];
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
		}
		else if ([theEvent type]==NSLeftMouseUp)
		{
			break;
		}
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
                NSLeftMouseDraggedMask | NSFlagsChangedMask | NSPeriodicMask];
	} while (YES);

	[NSEvent stopPeriodicEvents];
	// if the mouse in is menu bar, cancel the move
	mouseLocScreen = [[self window] convertBaseToScreen: [theEvent locationInWindow]];
	screenFrame = [[NSScreen mainScreen] frame];
	if (([[NSScreen screens] count] == 1 || NSPointInRect(mouseLocScreen, screenFrame)) && 
			mouseLocScreen.y >= screenFrame.origin.y + screenFrame.size.height - 22)
	{
		selectedRect = originalSelRect;
		[[self window] restoreCachedImage];
		selRectWindow = [self convertRect: selectedRect toView: nil];
		[[self window] cacheImageInRect:NSInsetRect(selRectWindow, -2, -2)];
		oldVisibleRect = [self visibleRect];
	}
	
	selectedRect = NSIntersectionRect(selectedRect, [self bounds]);
	if (selectedRect.size.width > 2 && selectedRect.size.height > 2)
	{
		oldVisibleRect = [self visibleRect];
	}
	else
	{
		[selRectTimer invalidate]; // this will release the timer
		selRectTimer = nil;
		[[self window] restoreCachedImage];
		[[self window] flushWindow];
		[[self window] discardCachedImage];
	}
	[self flagsChanged: theEvent]; // update cursor
*/
}


- (BOOL)hasSelection
{
	return (selRectTimer != nil);
}


// get image data from the selected rectangle with specified type
- (NSData *)imageDataFromSelectionType: (int)type
{
	NSRect visRect, newRect, selRectWindow;
	NSRect mySelectedRect;
	NSData *data = nil;
	NSBitmapImageRep *bitmap = nil;
	NSImage *image = nil;
	NSBitmapImageFileType fileType;
	NSDictionary *dict;
	NSColor *backColor, *oldBackColor, *backColor1, *oldBackColor1;
	
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
			bitmap = [[[NSBitmapImageRep alloc] initWithFocusedViewRect: 
											newRect] autorelease];
			[self unlockFocus];
		}
		else // there is some portion which is not visible
		{
			// new routine which creates image by directly calling drawRect
			image = [self imageFromRect: mySelectedRect];
				
			if (image)
			{	
				[image setScalesWhenResized: NO];
				[image setSize: NSMakeSize(floor(selRectWindow.size.width), 
											floor(selRectWindow.size.height))];
				bitmap = [[[NSBitmapImageRep alloc] initWithData: 
										[image TIFFRepresentation]] autorelease];
			}
		}
		// color mapping
		if (bitmap && [SUD boolForKey:PdfColorMapKey])
		{
			NSColor *foreColor, *backColor;
			if ([SUD stringForKey:PdfFore_RKey])
			{
				foreColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:PdfFore_RKey] 
					green: [SUD floatForKey:PdfFore_GKey] blue: [SUD floatForKey:PdfFore_BKey] 
					alpha: [SUD floatForKey:PdfFore_AKey]];
			}
			else
				foreColor = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1];
			if ([SUD stringForKey:PdfBack_RKey])
			{
				backColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:PdfBack_RKey] 
					green: [SUD floatForKey:PdfBack_GKey] blue: [SUD floatForKey:PdfBack_BKey] 
					alpha: [SUD floatForKey:PdfBack_AKey]];
			}
			else
				backColor = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1];
			int colorParam1 = [SUD integerForKey:PdfColorParam1Key];
			// call transformColor() below to map the colors
			bitmap = transformColor(bitmap, foreColor, backColor, colorParam1);
		}
		// convert to the specified format
		if (bitmap && type != IMAGE_TYPE_PICT)
		{
			switch (type)
			{
				case IMAGE_TYPE_TIFF_NC:
					fileType = NSTIFFFileType;
					dict = [NSDictionary  dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInt: NSTIFFCompressionNone], 
							NSImageCompressionMethod, nil];
					break;
				case IMAGE_TYPE_TIFF_LZW:
					fileType = NSTIFFFileType;
					dict = [NSDictionary  dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInt: NSTIFFCompressionLZW], 
							NSImageCompressionMethod, nil];
					break;
				case IMAGE_TYPE_TIFF_PB:
					fileType = NSTIFFFileType;
					dict = [NSDictionary  dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInt: NSTIFFCompressionPackBits], 
							NSImageCompressionMethod, nil];
					break;
				case IMAGE_TYPE_JPEG_HIGH:
					fileType = NSJPEGFileType;
					dict = [NSDictionary  dictionaryWithObjectsAndKeys: 
							[NSNumber numberWithFloat: JPEG_COMPRESSION_HIGH], 
							NSImageCompressionFactor, nil];
					break;
				case IMAGE_TYPE_JPEG_MEDIUM:
					fileType = NSJPEGFileType;
					dict = [NSDictionary  dictionaryWithObjectsAndKeys: 
							[NSNumber numberWithFloat: JPEG_COMPRESSION_MEDIUM], 
							NSImageCompressionFactor, nil];
					break;
				case IMAGE_TYPE_JPEG_LOW:
					fileType = NSJPEGFileType;
					dict = [NSDictionary  dictionaryWithObjectsAndKeys: 
							[NSNumber numberWithFloat: JPEG_COMPRESSION_LOW], 
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
							[NSNumber numberWithFloat: JPEG_COMPRESSION_MEDIUM], 
							NSImageCompressionFactor, nil];
			}
			data = [bitmap representationUsingType: fileType properties: dict];
		}
		else if (bitmap && type == IMAGE_TYPE_PICT)
		{
			data = getPICTDataFromBitmap(bitmap);
		}
		else
			data = nil;
	}
	else // IMAGE_TYPE_PDF or IMAGE_TYPE_EPS
	{
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
		
		oldBackColor = [self backgroundColor];
		backColor = [NSColor colorWithCalibratedRed: 1 
		green: 0 blue: 0 
		alpha: 0];
		[self setBackgroundColor: backColor];
		
		if (type == IMAGE_TYPE_PDF)
			data = [self dataWithPDFInsideRect: newRect];
		else // IMAGE_TYPE_EPS
			data = [self dataWithEPSInsideRect: newRect];
			
		[self setBackgroundColor: oldBackColor];
			
	}
	NS_HANDLER
		data = nil;
		//NSRunAlertPanel(@"Error", @"error occured in imageDataFromSelectionType:", nil, nil, nil);
	NS_ENDHANDLER
	return data;
}


/*
// put the image data from selected rectangle into pasteboard
- (void)copy: (id)sender
{
	NSString *dataType;
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	int imageCopyType = [SUD integerForKey:PdfCopyTypeKey]; // mitsu 1.29b
	
	if (imageCopyType != IMAGE_TYPE_PDF && imageCopyType != IMAGE_TYPE_EPS && 
		imageCopyType != IMAGE_TYPE_PICT)
		dataType = NSTIFFPboardType;
	else if (imageCopyType == IMAGE_TYPE_PICT)
		dataType = NSPICTPboardType;
	else if (imageCopyType == IMAGE_TYPE_PDF)
		dataType = NSPDFPboardType;
	else if (imageCopyType == IMAGE_TYPE_EPS)
		dataType = NSPostScriptPboardType;
	
	NSData *data = [self imageDataFromSelectionType: imageCopyType];
	if (data)
	{
		[pboard declareTypes:[NSArray arrayWithObjects: dataType, nil] owner:self];
		[pboard setData:data forType:dataType]; 
	}
	else
		NSRunAlertPanel(@"Error", @"failed to copy selection.", nil, nil, nil);
}
*/


// start save-dialog as a sheet 
-(void)saveSelectionToFile: (id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel  setAccessoryView: imageTypeView];
	[imageTypeView retain];
	int itemIndex = [imageTypePopup indexOfItemWithTag: [SUD integerForKey: PdfExportTypeKey]]; 
	if (itemIndex == -1) itemIndex = 0; // default PdfExportTypeKey
    [imageTypePopup selectItemAtIndex: itemIndex];
	[self chooseExportImageType: imageTypePopup]; // this sets up required type
	[savePanel setCanSelectHiddenExtension: YES];
	
	[savePanel beginSheetForDirectory:nil file:nil 
		modalForWindow:[self window] modalDelegate:self 
		didEndSelector:@selector(saveSelctionPanelDidEnd:returnCode:contextInfo:) 
		contextInfo:nil];
}

// save the image data from selected rectangle to a file
- (void)saveSelctionPanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
{
	if (returnCode == NSFileHandlingPanelOKButton && [sheet filename])
	{
		NSData *data = nil;
		NSNumber *aNumber;
		
		aNumber = [NSNumber numberWithInt: [SUD integerForKey: PdfExportTypeKey]];
		NSLog([aNumber stringValue]);
		
		data = [self imageDataFromSelectionType: [SUD integerForKey: PdfExportTypeKey]];
		
		if ([SUD integerForKey: PdfExportTypeKey] == IMAGE_TYPE_PICT)
		{	// PICT file needs to start with 512 bytes 0's
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




// control image type popup
- (void) chooseExportImageType: sender;
{
	int imageExportType;
    NSSavePanel *savePanel;
	
	imageExportType = [[sender selectedItem] tag];
	savePanel = (NSSavePanel *)[sender window];
	[savePanel setRequiredFileType: extensionForType(imageExportType)];// mitsu 1.29 drag & drop
		
	if (imageExportType != [SUD integerForKey: PdfExportTypeKey])
	{
		[SUD setInteger:imageExportType forKey:PdfExportTypeKey];
	}
}

// mitsu 1.29 drag & drop
#pragma mark =====drag & drop=====

- (void)startDragging: (NSEvent *)theEvent
{
    NSPasteboard *pboard;
	int imageCopyType;
	NSString *dataType, *filePath;
	NSData *data;
	NSImage *image;
    NSSize dragOffset = NSMakeSize(0, 0);
	NSRect	mySelectedRect;
	
	mySelectedRect = [self convertRect: selectedRect fromView: [self documentView]];

    pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	imageCopyType = [SUD integerForKey:PdfCopyTypeKey];
	if (imageCopyType != IMAGE_TYPE_PDF && imageCopyType != IMAGE_TYPE_EPS && 
		imageCopyType != IMAGE_TYPE_PICT)
		dataType = NSTIFFPboardType;
	else if (imageCopyType == IMAGE_TYPE_PICT)
		dataType = NSPICTPboardType;
	else if (imageCopyType == IMAGE_TYPE_PDF)
		dataType = NSPDFPboardType;
	else if (imageCopyType == IMAGE_TYPE_EPS)
		dataType = NSPostScriptPboardType;
	[pboard declareTypes:[NSArray arrayWithObjects: dataType, 
							NSFilenamesPboardType, nil] owner:self];
	
	if (!((imageCopyType == IMAGE_TYPE_PDF || imageCopyType == IMAGE_TYPE_EPS)
		&& [SUD boolForKey: PdfQuickDragKey]))
	{
		data = [self imageDataFromSelectionType: imageCopyType];
		if (data)
		{
			[pboard setData:data forType:dataType]; 
			filePath = [[DraggedImagePathKey stringByStandardizingPath] 
					stringByAppendingPathExtension: extensionForType(imageCopyType)];
			if ([data writeToFile: filePath atomically: NO])
				[pboard setPropertyList:[NSArray arrayWithObject: filePath] 
									forType:NSFilenamesPboardType];
			image = [[[NSImage alloc] initWithData: data] autorelease];
			if (image)
			{
				[self dragImage:image at:mySelectedRect.origin offset:dragOffset 
					event:theEvent pasteboard:pboard source:self slideBack:YES];
			}
		}
	}
	else // quick drag for PDF & EPS
	{
		image = [self imageFromRect: mySelectedRect];
		if (image)
		{
			//[self pasteboard:pboard provideDataForType:dataType];
			//[self pasteboard:pboard provideDataForType:NSFilenamesPboardType];
			[self dragImage:image at:mySelectedRect.origin offset:dragOffset 
					event:theEvent pasteboard:pboard source:self slideBack:YES];
		}
	}
}

// NSDraggingSource required method
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return (isLocal)?NSDragOperationNone:NSDragOperationCopy;
}

// NSDraggingSource optional method for promised data
- (void)pasteboard:(NSPasteboard *)pboard provideDataForType:(NSString *)type
{
	NSString *filePath;
	NSData *data;
	int imageCopyType = [SUD integerForKey:PdfCopyTypeKey];
	
	if ([type isEqualToString: NSTIFFPboardType] || 
		[type isEqualToString: NSPICTPboardType] || 
		[type isEqualToString: NSPDFPboardType] || 
		[type isEqualToString: NSPostScriptPboardType]) 
	{
		data = [self imageDataFromSelectionType: imageCopyType];
		if (data)
			[pboard setData:data forType:type]; 
	}
	else if ([type isEqualToString: NSFilenamesPboardType])
	{
		data = [self imageDataFromSelectionType: imageCopyType];
		if (data)
		{
			filePath = [[DraggedImagePathKey stringByStandardizingPath] 
						stringByAppendingPathExtension: extensionForType(imageCopyType)];
			if ([data writeToFile: filePath atomically: NO])
				[pboard setPropertyList:[NSArray arrayWithObject: filePath] 
									forType:NSFilenamesPboardType];
		}
	}
}

// end mitsu 1.29


#pragma mark =====sync=====

- (void)setupSourceFiles;
{
	NSString		*sourceText, *searchText, *filePath, *filePathNew, *rootPath;
	unsigned int	sourceLength;
	BOOL			done;
	NSRange			maskRange, searchRange, newSearchRange, fileRange;
	int				currentIndex;
	NSFileManager	*manager;
	BOOL			isDir;
	
	manager = [NSFileManager defaultManager];
	
	rootPath = [[myDocument fileName] stringByDeletingLastPathComponent];
	sourceFiles = [[NSMutableArray arrayWithCapacity: NUMBER_OF_SOURCE_FILES] retain];
	currentIndex = 0;
	sourceText = [[myDocument textView] string];
	sourceLength = [sourceText length];
	
	searchText = @"\include{";
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
				fileRange.location = searchRange.location + 8;
				fileRange.length = newSearchRange.location - fileRange.location;
				filePath = [sourceText substringWithRange: fileRange];
				// if ([[filePath pathExtension] length] == 0)
					filePath = [filePath stringByAppendingPathExtension: @"tex"];
				filePath = [[rootPath stringByAppendingString:@"/"] stringByAppendingString: filePath];
				filePath = [filePath stringByStandardizingPath];
				// add this to the array
				if (([manager fileExistsAtPath: filePath isDirectory:&isDir]) && (!isDir)) {
					[sourceFiles insertObject: filePath atIndex: currentIndex];
					currentIndex++;
					}
				}
			}
		}
		
	searchText = @"\input{";
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
				fileRange.location = searchRange.location + 6;
				fileRange.length = newSearchRange.location - fileRange.location;
				filePath = [sourceText substringWithRange: fileRange];
				// if ([[filePath pathExtension] length] == 0)
					filePathNew = [filePath stringByAppendingPathExtension: @"tex"];
				filePathNew = [[rootPath stringByAppendingString:@"/"] stringByAppendingString: filePathNew];
				filePathNew = [filePathNew stringByStandardizingPath];
				// add this to the array
				if (([manager fileExistsAtPath: filePathNew isDirectory:&isDir]) && (!isDir)) {
					[sourceFiles insertObject: filePathNew atIndex: currentIndex];
					currentIndex++;
					}
				else {
					filePath = [[rootPath stringByAppendingString:@"/"] stringByAppendingString: filePath];
					filePath = [filePath stringByStandardizingPath];
					// add this to the array
					if (([manager fileExistsAtPath: filePath isDirectory:&isDir]) && (!isDir)) {
						[sourceFiles insertObject: filePath atIndex: currentIndex];
						currentIndex++;
						}
					}
				}
			}
		}

	searchText = @"\import{";
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
				fileRange.location = searchRange.location + 7;
				fileRange.length = newSearchRange.location - fileRange.location;
				filePath = [sourceText substringWithRange: fileRange];
				// if ([[filePath pathExtension] length] == 0)
					filePath = [filePath stringByAppendingPathExtension: @"tex"];
				filePath = [[rootPath stringByAppendingString:@"/"] stringByAppendingString: filePath];
				filePath = [filePath stringByStandardizingPath];
				// add this to the array
				if (([manager fileExistsAtPath: filePath isDirectory:&isDir]) && (!isDir)) {
					[sourceFiles insertObject: filePath atIndex: currentIndex];
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


- (BOOL)doNewSync: (NSEvent *)theEvent;
{
	int						theIndex;
	int						searchStart, searchEnd, testIndex;
	int						pageNumber, numberOfTests;
	int						searchWindow;
	unsigned int			searchlength;
	unsigned int			sourcelength[NUMBER_OF_SOURCE_FILES + 1];
	int						startIndex, endIndex;
	NSRange					searchRange, newSearchRange, maskRange, theRange;
	NSString				*searchText;
	NSString				*sourceText[NUMBER_OF_SOURCE_FILES + 1];
	BOOL					found;
	int						length;
	int						numberOfFiles;
	int						i;
	BOOL					foundOne, foundMoreThanOne;
	int						foundIndex;
	NSRange					foundRange;
	unsigned int			foundlength;
	NSRange					correctedFoundRange;
	MyDocument				*newDocument;
	NSTextView				*myTextView;
	NSWindow				*myTextWindow;
	NSDictionary			*mySelectedAttributes;
	NSMutableDictionary		*newSelectedAttributes;
	
	int						tag, theTag;
    id						myData;
    NSStringEncoding		theEncoding;
    NSString				*firstBytes, *encodingString, *testString;
    NSRange					encodingRange, newEncodingRange, myRange, theRange1;
    unsigned				length1, start, end, irrelevant;
    BOOL					done;
    int						linesTested;
	NSString				*aString;
	int						correction;

	NSPoint windowPosition = [theEvent locationInWindow];
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
	
	sourceText[0] = [[myDocument textView] string];
	sourcelength[0] = [sourceText[0] length];
	
	if (numberOfFiles > 0)
		for (i = 0; i < numberOfFiles; i++) {
			
			tag = [myDocument encoding];
			theEncoding = [[EncodingSupport sharedInstance] stringEncodingForTag: tag];
			myData = [NSData dataWithContentsOfFile:[sourceFiles objectAtIndex:i]];
    
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
				if (encodingRange.location != NSNotFound) {
					done = YES;
					newEncodingRange.location = encodingRange.location + 16;
					newEncodingRange.length = [testString length] - newEncodingRange.location;
					if (newEncodingRange.length > 0) {
						encodingString = [[testString substringWithRange: newEncodingRange] 
							stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
						theTag = [[EncodingSupport sharedInstance] tagForEncoding:encodingString];
						theEncoding = [[EncodingSupport sharedInstance] stringEncodingForTag: theTag];
						}
					}
				else if ([SUD boolForKey:UseOldHeadingCommandsKey]) {
					encodingRange = [testString rangeOfString:@"%&encoding="];
					if (encodingRange.location != NSNotFound) {
						done = YES;
						newEncodingRange.location = encodingRange.location + 11;
						newEncodingRange.length = [testString length] - newEncodingRange.location;
						if (newEncodingRange.length > 0) {
							encodingString = [[testString substringWithRange: newEncodingRange] 
								stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
							theTag = [[EncodingSupport sharedInstance] tagForEncoding:encodingString];
							theEncoding = [[EncodingSupport sharedInstance] stringEncodingForTag: theTag];
							}
						}
					}
				}

			[firstBytes release];
	
    
    
			aString = [[[NSString alloc] initWithData:myData encoding:theEncoding] autorelease];
			if (! aString) {
				tag = [[EncodingSupport sharedInstance] tagForEncoding: @"MacOSRoman"];
				theEncoding = [[EncodingSupport sharedInstance] stringEncodingForTag: tag];
				aString = [[[NSString alloc] initWithData:myData encoding:theEncoding] autorelease];
				}

			sourceText[i + 1] = aString;
			//sourceText[i + 1] = [NSString stringWithContentsOfFile: [sourceFiles objectAtIndex:i] encoding:NSMacOSRomanStringEncoding error: &theError];
			sourcelength[i + 1] = [sourceText[i + 1] length];
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
		for (i = 0; i < (numberOfFiles + 1); i++)
			{
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
				myTextView = [myDocument textView];
				myTextWindow = [myDocument textWindow];
				[myDocument setTextSelectionYellow: YES];
				}
			else {
				newDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:[sourceFiles objectAtIndex:(foundIndex - 1)] display:YES];
				myTextView = [newDocument textView];
				myTextWindow = [newDocument textWindow];
				[newDocument setTextSelectionYellow: YES];
				}
			mySelectedAttributes = [myTextView selectedTextAttributes];
			newSelectedAttributes = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes];
			[newSelectedAttributes setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
			[myTextView setSelectedTextAttributes: newSelectedAttributes];
			correction = theIndex - testIndex + 5;
			correctedFoundRange.location = foundRange.location + correction;
			correctedFoundRange.length = foundRange.length;
			if ((correction < 0) || (correctedFoundRange.location + correctedFoundRange.length) > foundlength)
				correctedFoundRange = foundRange;
			[myTextView setSelectedRange: correctedFoundRange];
			[myTextView scrollRangeToVisible: correctedFoundRange];
			[myTextWindow makeKeyAndOrderFront:self];
			// [myTextView setSelectedTextAttributes: mySelectedAttributes];
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
		for (i = 0; i < (numberOfFiles + 1); i++)
			{
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
				myTextView = [myDocument textView];
				myTextWindow = [myDocument textWindow];
				}
			else {
				newDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:[sourceFiles objectAtIndex:(foundIndex - 1)] display:YES];
				myTextView = [newDocument textView];
				myTextWindow = [newDocument textWindow];
				}
			mySelectedAttributes = [myTextView selectedTextAttributes];
			newSelectedAttributes = [NSMutableDictionary dictionaryWithDictionary: mySelectedAttributes];
			[newSelectedAttributes setObject:[NSColor yellowColor] forKey:@"NSBackgroundColor"];
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

- (void)doSync: (NSEvent *)theEvent
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
        int             pageNumber;
        NSRange         pageRangeStart;
        NSRange         pageRangeEnd;
        NSRange         remainingRange;
        NSRange         thisRange, newRange, foundRange;
        NSNumber        *anotherNumber;
        int             aNumber;
        int             syncNumber, oldSyncNumber, x, oldx, y, oldy;
        BOOL            found, done;
        unsigned        theStart, theEnd, theContentsEnd;
        NSString        *newFileName, *theExtension;
        MyDocument      *newDocument;
        unsigned        start, end, irrelevant;
		BOOL			result;
	
	int syncMethod = [SUD integerForKey:SyncMethodKey];
	
	if ((syncMethod == SEARCHONLY) || (syncMethod == SEARCHFIRST)) {
		result = [self doNewSync: theEvent];
		if (result)
			return;
		}
	if (syncMethod == SEARCHONLY)
		return;
    
    includeFileName = nil;
        
    // The code below finds the page number, and the position of the click
    // in view coordinates. 
        
    NSPoint windowPosition = [theEvent locationInWindow];
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
    int tempY = viewPosition.y - 14;
    // int yValue = viewPosition.y * 65536;
    int yValue = tempY * 65536;
    
    // now see if the sync file exists
    fileManager = [NSFileManager defaultManager];
    NSString *fileName = [myDocument fileName];
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
        syncInfo = [NSString stringWithContentsOfFile:infoFile];
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
    thePageNumber = [NSNumber numberWithInt: pageNumber];
    pageSearchString = [[NSString stringWithString:@"s "] stringByAppendingString: [thePageNumber stringValue]];
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
    thePageNumber = [NSNumber numberWithInt: pageNumber];
    pageSearchString = [[NSString stringWithString:@"s "] stringByAppendingString: [thePageNumber stringValue]];
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
    thePageNumber = [NSNumber numberWithInt: pageNumber];
    pageSearchString = [[NSString stringWithString:@"s "] stringByAppendingString: [thePageNumber stringValue]];
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
    thePageNumber = [NSNumber numberWithInt: pageNumber];
    pageSearchString = [[NSString stringWithString:@"s "] stringByAppendingString: [thePageNumber stringValue]];
    pageRangeStart = [syncInfo rangeOfString: pageSearchString];
    
    if (pageRangeStart.location == NSNotFound)
        return;
    [syncInfo getLineStart: &start end: &end contentsEnd: &irrelevant forRange: pageRangeStart];
    if (pageRangeStart.location != start)
        return;
        
    searchString = [NSString stringWithString:@"p "];
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
        if (remainingRange.length < 0) 
            {found = NO; break;}
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
            syncNumber = [keyLine intValue]; // number of entry
    
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
            x = [keyLine intValue];
    
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
            y = [keyLine intValue];
            }
        }
    while (found && (y > yValue));
    
    if ((oldSyncNumber < 0) && (syncNumber < 0))
        return;
        
    if (oldSyncNumber < 0)
        oldSyncNumber = syncNumber;
        
    anotherNumber = [NSNumber numberWithInt: oldSyncNumber];
    pageSearchString = [[NSString stringWithString:@"l "] stringByAppendingString: [anotherNumber stringValue]];
    /*
    pageRangeStart = [syncInfo rangeOfString: pageSearchString];
    if (pageRangeStart.location == NSNotFound) {
        syncInfo = [NSString stringWithContentsOfFile:infoFile];
        pageRangeStart = [syncInfo rangeOfString: pageSearchString];
        }
    */
        syncInfo = [NSString stringWithContentsOfFile:infoFile];
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

    aNumber = [valueString intValue];
    
    // at this point, we know the line number containing the click, but we must still find the
    // name of the file which contains that line. So we search backward from found range, for
    // ( without a matching later ). If we found one, then it will give the name of the
    // file. Otherwise the file is the current file.
    
    NSRange         lineRange, oneLineRange;
    NSString        *theLine, *theFile;
    NSMutableArray  *theStack;
    int             stackPointer;
    
    searchCloseString = [NSString stringWithString:@")"];
    searchOpenString = [NSString stringWithString:@"("];

    done = NO;
    theStack = [NSMutableArray arrayWithCapacity: 10];
    stackPointer = -1;
    
    lineRange.location = 0;
    lineRange.length = 1;
    while ((! done) && (lineRange.location <= foundRange.location)) {
    
        searchCloseRange.location = lineRange.location; searchCloseRange.length = foundRange.location - lineRange.location;
        searchCloseResultRange = [syncInfo rangeOfString: searchCloseString options:0 range: searchCloseRange];
        searchOpenRange.location = lineRange.location; searchOpenRange.length = foundRange.location - lineRange.location;
        searchOpenResultRange = [syncInfo rangeOfString: searchOpenString options:0 range: searchOpenRange];
        if ((searchOpenResultRange.location == NSNotFound) && (searchCloseResultRange.location == NSNotFound))
            done = YES;
        else if (searchOpenResultRange.location == NSNotFound)
            lineRange.location = searchCloseResultRange.location;
        else if (searchCloseResultRange.location == NSNotFound)
            lineRange.location = searchOpenResultRange.location;
        else if (searchOpenResultRange.location <= searchCloseResultRange.location)
            lineRange.location = searchOpenResultRange.location;
        else
            lineRange.location = searchCloseResultRange.location;
            
        
        if (! done) {
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
                    }
                else if ([theLine characterAtIndex:0] == ')') {
                    if (stackPointer >= 0)
                        stackPointer--;
                    }
                
                }
            }
        }
        
    includeFileName = nil;
    if (stackPointer >= 0)
        includeFileName = [theStack objectAtIndex: stackPointer];
            

/*    
    done = NO;
    searchCloseString = [NSString stringWithString:@")"];
    searchOpenString = [NSString stringWithString:@"("];

    while (! done) {
    
        searchCloseRange.location = 0; searchCloseRange.length = foundRange.location;
        searchCloseResultRange = [syncInfo rangeOfString: searchCloseString options:NSBackwardsSearch range: searchCloseRange];
        
        searchOpenRange.location = 0; searchOpenRange.length = foundRange.location;
        searchOpenResultRange = [syncInfo rangeOfString: searchOpenString options:NSBackwardsSearch range: searchOpenRange];
        
        if (searchOpenResultRange.location == NSNotFound) {
            done = YES;
            includeFileName = nil;
            }
            
        else if ((searchCloseResultRange.location == NSNotFound) ||
                (searchCloseResultRange.location < searchOpenResultRange.location)) {
            done = YES;
             NS_DURING
            [syncInfo getLineStart: &theStart end: &theEnd contentsEnd: nil forRange: searchOpenResultRange];
            NS_HANDLER
            return;
            NS_ENDHANDLER
            smallerRange.location = theStart + 1;
            smallerRange.length = theEnd - theStart - 2;
            NS_DURING
            includeFileName = [syncInfo substringWithRange: smallerRange];
            NS_HANDLER
            return;
            NS_ENDHANDLER
            }
            
        else {
            foundRange.location = searchOpenResultRange.location - 1;
            }
        }
*/
        
    if (includeFileName == nil) {
        [myDocument toLine:aNumber];
        [[myDocument  textWindow] makeKeyAndOrderFront:self];
        }
    else {
        newFileName = [[[myDocument fileName] stringByDeletingLastPathComponent] stringByAppendingString:@"/"];
        newFileName = [newFileName stringByAppendingString: includeFileName];
        theExtension = [newFileName pathExtension];
        if ([theExtension length] == 0)
            includeFileName = [[newFileName stringByStandardizingPath] stringByAppendingPathExtension: @"tex"];
        else
            includeFileName = [newFileName stringByStandardizingPath];
        newDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:includeFileName display:YES];
        [newDocument toLine:aNumber];
        [[newDocument textWindow] makeKeyAndOrderFront:self];
        }


    
///////////////////////////////////////////////////////////
/*
    // search backward for ); if found, replace syncInfo with everything after the character
    searchString = [NSString stringWithString:@")"];
    searchRange.location = 0; searchRange.length = pageRangeStart.location;
    searchResultRange = [syncInfo rangeOfString: searchString options:NSBackwardsSearch range: searchRange];
    if (searchResultRange.location != NSNotFound) {
        smallerRange.location = searchResultRange.location + 1;
        smallerRange.length = [syncInfo length] - searchResultRange.location - 1;
        NS_DURING
        syncInfo = [syncInfo substringWithRange: smallerRange];
        NS_HANDLER
        return;
        NS_ENDHANDLER
        }
        
    // search backward for (; if found, record the filename and then search forward for ) and replace syncInfo by
    // everything between these spots
    pageSearchString = [[NSString stringWithString:@"s "] stringByAppendingString: [thePageNumber stringValue]];
    pageRangeStart = [syncInfo rangeOfString: pageSearchString];
    if (pageRangeStart.location == NSNotFound)
        return;
    searchString = [NSString stringWithString:@"("];
    searchRange.location = 0; searchRange.length = pageRangeStart.location;
    searchResultRange = [syncInfo rangeOfString: searchString options:NSBackwardsSearch range: searchRange];
    if (searchResultRange.location != NSNotFound) {
        NS_DURING
        [syncInfo getLineStart: &theStart end: &theEnd contentsEnd: nil forRange: searchResultRange];
        NS_HANDLER
        return;
        NS_ENDHANDLER
        smallerRange.location = theStart + 1;
        smallerRange.length = theEnd - theStart - 2;
        NS_DURING
        includeFileName = [syncInfo substringWithRange: smallerRange];
        NS_HANDLER
        return;
        NS_ENDHANDLER
        smallerRange.location = theEnd;
        smallerRange.length = [syncInfo length] - smallerRange.location - 1;
        
        // logInt = [syncInfo length];
        // logNumber = [NSNumber numberWithInt: logInt];
        // NSLog([logNumber stringValue]);
       
        NS_DURING 
        syncInfo = [syncInfo substringWithRange: smallerRange];
        NS_HANDLER
        return;
        NS_ENDHANDLER
        searchString = [NSString stringWithString:@")"];
        searchResultRange = [syncInfo rangeOfString: searchString];
        if (searchResultRange.location != NSNotFound) {
            smallerRange.location = 0;
            smallerRange.length = searchResultRange.location + 1;
            NS_DURING
            syncInfo = [syncInfo substringWithRange: smallerRange];
            NS_HANDLER
            return;
            NS_ENDHANDLER
            }
        }
        
        
    // Search backward to the previous page number, if one exists
    // Search forward to the next page number, if one exists
    // Replace syncInfo by the information between these two numbers
    pageNumber = pageNumber - 1;
    thePageNumber = [NSNumber numberWithInt: pageNumber];
    pageSearchString = [[NSString stringWithString:@"s "] stringByAppendingString: [thePageNumber stringValue]];
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
    thePageNumber = [NSNumber numberWithInt: pageNumber];
    pageSearchString = [[NSString stringWithString:@"s "] stringByAppendingString: [thePageNumber stringValue]];
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
    
    // Search backwards to any line starting with "p". Remove this first stuff
    pageNumber = pageNumber - 1;
    thePageNumber = [NSNumber numberWithInt: pageNumber];
    pageSearchString = [[NSString stringWithString:@"s "] stringByAppendingString: [thePageNumber stringValue]];
    pageRangeStart = [syncInfo rangeOfString: pageSearchString];
    
    if (pageRangeStart.location == NSNotFound)
        return;
    searchString = [NSString stringWithString:@"p"];
    searchRange.location = 0; searchRange.length = pageRangeStart.location;
    
    searchResultRange = [syncInfo rangeOfString: searchString options:NSBackwardsSearch range: searchRange];
    if (!(searchResultRange.location == NSNotFound)) {
        NS_DURING
        [syncInfo getLineStart: &theStart end: &theEnd contentsEnd: nil forRange: searchResultRange];
        NS_HANDLER
        return;
        NS_ENDHANDLER
        smallerRange.location = theEnd;
        smallerRange.length = [syncInfo length] - theEnd;
        NS_DURING
        syncInfo = [syncInfo substringWithRange: smallerRange];
        NS_HANDLER
        return;
        NS_ENDHANDLER
        }

        
    // Now syncInfo contains exactly the required information for the given page
    // and nothing more. Also if includeFileName is not nil, it contains the name
    // of the include file being examined
    
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
        if (remainingRange.length < 0) 
            {found = NO; break;}
        searchResultRange = [syncInfo rangeOfString: @"p" options: NSLiteralSearch range: remainingRange];
        if (searchResultRange.location == NSNotFound)
            {found = NO; break;}
        
        NS_DURING
        [syncInfo getLineStart: &theStart end: &theEnd contentsEnd: nil forRange: searchResultRange];
        NS_HANDLER
        return;
        NS_ENDHANDLER
        remainingRange.location = theEnd + 1;
        remainingRange.length = [syncInfo length] - remainingRange.location;
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
        syncNumber = [keyLine intValue]; // number of entry
    
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
        x = [keyLine intValue];
    
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
        y = [keyLine intValue];
        }
    while (found && (y > yValue));
    
    if ((oldSyncNumber < 0) && (syncNumber < 0))
        return;
        
    if (oldSyncNumber < 0)
        oldSyncNumber = syncNumber;
        
    aNumber = [NSNumber numberWithInt: oldSyncNumber];
    pageSearchString = [[NSString stringWithString:@"l "] stringByAppendingString: [aNumber stringValue]];
    pageRangeStart = [syncInfo rangeOfString: pageSearchString];
    if (pageRangeStart.location == NSNotFound) {
        syncInfo = [NSString stringWithContentsOfFile:infoFile];
        pageRangeStart = [syncInfo rangeOfString: pageSearchString];
        }
    NS_DURING
    [syncInfo getLineStart: &theStart end: &theEnd contentsEnd: nil forRange: pageRangeStart];
    NS_HANDLER
    return;
    NS_ENDHANDLER
    newRange.location = theStart;
    newRange.length = (theEnd - theStart);
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
    
    aNumber = [valueString intValue];
    if (includeFileName == nil) {
        [myDocument toLine:aNumber];
        [[myDocument  textWindow] makeKeyAndOrderFront:self];
        }
    else {
        newFileName = [[[myDocument fileName] stringByDeletingLastPathComponent] stringByAppendingString:@"/"];
        newFileName = [newFileName stringByAppendingString: includeFileName];
        includeFileName = [[newFileName stringByStandardizingPath] stringByAppendingPathExtension: @"tex"];
        newDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:includeFileName display:YES];
        [newDocument toLine:aNumber];
        [[newDocument textWindow] makeKeyAndOrderFront:self];
        }
*/
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


- (void)drawDotsForPage:(int)page atPoint: (NSPoint)p;
{
        NSFileManager	*fileManager;
        int             pageNumber;
        NSNumber        *thePageNumber;
        NSString         *syncInfo, *pageSearchString, *keyLine;
        NSRange         pageRangeStart, myRange;
        NSRange         pageRangeEnd, smallerRange;
        NSRange         remainingRange, searchResultRange;
        NSRange         newRange;
        int             syncNumber, x, y;
        unsigned        theStart, theEnd;
        double          newx, newy;
        NSRect          smallRect;
        NSColor         *backColor;
        unsigned        start, end, irrelevant;
    
    if (! [myDocument syncState])
        return;
        
    pageNumber = page + 1;
        
    // now convert to pdf coordinates
    // int yValue = viewPosition.y * 65536;

    // now see if the sync file exists
    fileManager = [NSFileManager defaultManager];
    NSString *fileName = [myDocument fileName];
    NSString *infoFile = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"pdfsync"];
    if (![fileManager fileExistsAtPath: infoFile])
        return;
    
    // get the contents of the sync file as a string
    NS_DURING
        syncInfo = [NSString stringWithContentsOfFile:infoFile];
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
    thePageNumber = [NSNumber numberWithInt: pageNumber];
    pageSearchString = [[NSString stringWithString:@"s "] stringByAppendingString: [thePageNumber stringValue]];
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
    thePageNumber = [NSNumber numberWithInt: pageNumber];
    pageSearchString = [[NSString stringWithString:@"s "] stringByAppendingString: [thePageNumber stringValue]];
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
            syncNumber = [keyLine intValue]; // number of entry
    
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
            x = [keyLine intValue];
    
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
            y = [keyLine intValue];
        
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


#pragma mark =====magnifying glass=====

- (void)doMagnifyingGlass:(NSEvent *)theEvent level: (int)level
{
	NSPoint mouseLocWindow, mouseLocView, mouseLocDocumentView;
	NSRect oldBounds, newBounds, magRectWindow, magRectView;
	BOOL postNote, postnoteDV, cursorVisible;
	float magWidth, magHeight, magOffsetX, magOffsetY;
	int originalLevel, currentLevel;
	float magScale; 	//0.4	// you may want to change this

	postNote = [[self documentView] postsBoundsChangedNotifications];
	[[self documentView] setPostsBoundsChangedNotifications: NO];
	
	oldBounds = [[self documentView] bounds];
	cursorVisible = YES;
	originalLevel = level+[theEvent clickCount];
	
	//[self cleanupMarquee: NO];
	[[self window] discardCachedImage]; // make sure not use the cached image
	
	do {
		if ([theEvent type]==NSLeftMouseDragged || [theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) 
		{	            
			// set up the size and magScale
			if ([theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged)
			{	
				currentLevel = originalLevel+(([theEvent modifierFlags] & NSAlternateKeyMask)?1:0);
				if (currentLevel <= 1)
				{
					magWidth = 150; magHeight = 100;
					magOffsetX = magWidth/2; magOffsetY = magHeight/2;
				}
				else if (currentLevel == 2)
				{
					magWidth = 380; magHeight = 250;
					magOffsetX = magWidth/2; magOffsetY = magHeight/2;
				}
				else // currentLevel >= 3 // need to cache the image
				{
					[[self window] restoreCachedImage];
					[[self window] cacheImageInRect:[self convertRect:[self visibleRect] toView: nil]];
				}
				if (!([theEvent modifierFlags] & NSShiftKeyMask))
				{
					if ([theEvent modifierFlags] & NSCommandKeyMask)
						magScale = 0.25; 	// x4
					else if ([theEvent modifierFlags] & NSControlKeyMask)
						magScale = 0.66666; // x1.5
					else
						magScale = 0.4; 	// x2.5
				}
				else // shrink the image with shift key -- can be very slow
				{
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
			
			if([self mouse:mouseLocView inRect:[self visibleRect]])
			{
				if (cursorVisible)
				{
					[NSCursor hide];
					cursorVisible = NO;
				}
				// define rect for magnification in window coordinate
				if (currentLevel >= 3) // mitsu 1.29 (S5) set magRectWindow here
				{
					magRectWindow = [self convertRect:[self visibleRect] toView:nil];
				}
				else // currentLevel <= 2
				{
					magRectWindow = NSMakeRect(mouseLocWindow.x-magOffsetX, mouseLocWindow.y-magOffsetY, 
											magWidth, magHeight);
					// restore the cached image in order to clear the rect
					[[self window] restoreCachedImage];
					[[self window] cacheImageInRect:  
						NSIntersectionRect(NSInsetRect(magRectWindow, -2, -2), 
						[[self superview] convertRect:[[self superview] bounds] 
						toView:nil])]; // mitsu 1.29b
				}
				// draw marquee
				if (selRectTimer)
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

			}
			else // mouse is not in the rect
			{
				// show cursor 
				if (!cursorVisible)
				{
					[NSCursor unhide];
					cursorVisible = YES;
				}
				// restore the cached image in order to clear the rect
				[[self window] restoreCachedImage];
				// autoscroll
				if (!([theEvent type]==NSFlagsChanged))
					[self autoscroll: theEvent];
				if (currentLevel >= 3)
					[[self window] cacheImageInRect:magRectWindow];
				else
					[[self window] discardCachedImage];
			}
		}
		else if ([theEvent type]==NSLeftMouseUp)
		{
			break;
		}
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
                NSLeftMouseDraggedMask | NSFlagsChangedMask];
	} while (YES);
	
	[[self window] restoreCachedImage];
	[[self window] flushWindow];
	[NSCursor unhide];
	[[self documentView] setPostsBoundsChangedNotifications: postNote];
	[self flagsChanged: theEvent]; // update cursor
	// recache the image around marquee for quicker response
	oldVisibleRect.size.width = 0;
	[self cleanupMarquee: NO];
	[self recacheMarquee]; 
}
// end Magnifying Glass

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
    int		scale;
    double	magSize;
    
	[self cleanupMarquee: YES];
	
	scale = magnification * 100.0;
	if (scale < 20)
		scale = 20;
	if (scale > 1000)
		scale = 1000;
		
	[myScale setIntValue: scale];
	[myScale1 setIntValue: scale];
	[myScale display];
	[myScale1 display];
	[myStepper setIntValue: scale];
	[myStepper1 setIntValue: scale];
	
    [self setScaleFactor: magnification];

}

- (void)resetMagnification;
{
    double	theMagnification;
    int		mag;
    
    theMagnification = [SUD floatForKey:PdfMagnificationKey];
    
    if (theMagnification != [self magnification]) 
        [self setMagnification: theMagnification];
    
    mag = round(theMagnification * 100.0);
    [myStepper setIntValue: mag];
    [myStepper1 setIntValue: mag];
}


- (void)changeMagnification:(NSNotification *)aNotification;
{
    [self resetMagnification];
}

- (void)rememberMagnification:(NSNotification *)aNotification;
{
    oldMagnification = [self magnification];
}
    
- (void) revertMagnification:(NSNotification *)aNotification;
{
    if (oldMagnification != [self magnification])
        [self setMagnification: oldMagnification];
} 


// Left and right arrows perform page up and page down if horizontal scroll bar is inactive
- (void)keyDown:(NSEvent *)theEvent;
{
	NSString	*theKey;
	
	theKey = [theEvent characters];
	
	if (([theKey characterAtIndex:0] == NSLeftArrowFunctionKey) && ([theEvent modifierFlags] & NSCommandKeyMask))
		{
		[self previousPage:self];
		return;
		}
		
	if (([theKey characterAtIndex:0] == NSRightArrowFunctionKey) && ([theEvent modifierFlags] & NSCommandKeyMask))
		{
		[self nextPage:self];
		return;
		}
	
	if ((([theKey characterAtIndex:0] == NSLeftArrowFunctionKey) || ([theKey characterAtIndex:0] == NSRightArrowFunctionKey)) 
		&& (! [[[[self documentView] enclosingScrollView] horizontalScroller] isEnabled])
		) {
		if ([theKey characterAtIndex:0] == NSLeftArrowFunctionKey)
			[self previousPage:self];
		else
			[self nextPage:self];
		return;
		}
	else 
		[super keyDown:theEvent];
}


@end