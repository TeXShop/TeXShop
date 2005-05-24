/* PDFKitViewer - MyPDFDocument.m
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


#import "MyPDFDocument.h"
#import "AppDelegate.h"
#import <Quartz/Quartz.h>


@implementation MyPDFDocument
// ======================================================================================================== MyPDFDocument
// ----------------------------------------------------------------------------------------------------------------- init

- (id) init
{
	self = [super init];
	if (self)
	{
		// Add your subclass-specific initialization here.
		// If an error occurs here, send a [self release] message and return nil.
		
	}
	
	return self;
}

// -------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// No more notifications.
	[[NSNotificationCenter defaultCenter] removeObserver: self];
 	
	// Clean up.
	[_searchResults release];
}

// -------------------------------------------------------------------------------------------------------- windowNibName

- (NSString *) windowNibName
{
	// Override returning the nib file name of the document
	return @"MyDocument";
}

// ------------------------------------------------------------------------------------------- windowControllerDidLoadNib

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
	
	// Find notifications.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(startFind:) 
			name: PDFDocumentDidBeginFindNotification object: NULL];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(findProgress:) 
			name: PDFDocumentDidEndPageFindNotification object: NULL];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(endFind:) 
			name: PDFDocumentDidEndFindNotification object: NULL];
	
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

// --------------------------------------------------------------------------------------------- dataRepresentationOfType

- (NSData *) dataRepresentationOfType: (NSString *) aType
{
	// Insert code here to write your document from the given data.  You can also choose to override 
	// -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
	return nil;
}

// ---------------------------------------------------------------------------------------- loadDataRepresentation:ofType

- (BOOL) loadDataRepresentation: (NSData *) data ofType: (NSString *) aType
{
	// Insert code here to read your document from the given data.  You can also choose to override 
	// -loadFileWrapperRepresentation:ofType: or -readFromFile:ofType: instead.
	return YES;
}

#pragma mark -
// --------------------------------------------------------------------------------------------------------- toggleDrawer

- (IBAction) toggleDrawer: (id) sender
{
	[_drawer toggle: self];
}

// ------------------------------------------------------------------------------------------- takeDestinationFromOutline

- (IBAction) takeDestinationFromOutline: (id) sender
{
	// Get the destination associated with the search result list.  Tell the PDFView to go there.
	[_pdfView goToDestination: [[sender itemAtRow: [sender selectedRow]] destination]];
}

// ---------------------------------------------------------------------------------------------------- displaySinglePage

- (IBAction) displaySinglePage: (id) sender
{
	// Display single page mode.
	if ([_pdfView displayMode] > kPDFDisplaySinglePageContinuous)
		[_pdfView setDisplayMode: [_pdfView displayMode] - 2];
}

// --------------------------------------------------------------------------------------------------------- displayTwoUp

- (IBAction) displayTwoUp: (id) sender
{
	// Display two-up.
	if ([_pdfView displayMode] < kPDFDisplayTwoUp)
		[_pdfView setDisplayMode: [_pdfView displayMode] + 2];
}

// ---------------------------------------------------------------------------------------------------------- pageChanged

- (void) pageChanged: (NSNotification *) notification
{
	PDFDocument		*document;
	unsigned int	newPageIndex;
	int				numRows;
	int				i;
	int newlySelectedRow;
	
	// Skip out if there is no outline.
	if ([[_pdfView document] outlineRoot] == NULL)
		return;
	
	// Get document and new page index.
	document = [(PDFPage *)[notification object] document];
	if (document != [_pdfView document])
		return;
	
	// What is the new page number (zero-based).
	newPageIndex = [document indexForPage: (PDFPage *)[notification object]];
	
	// Walk outline view looking for best firstpage number match.
	newlySelectedRow = -1;
	numRows = [_outlineView numberOfRows];
	for (i = 0; i < numRows; i++)
	{
		PDFOutline	*outlineItem;
		
		// Get the destination of the given row....
		outlineItem = (PDFOutline *)[_outlineView itemAtRow: i];
		
		if ([document indexForPage: [[outlineItem destination] page]] == newPageIndex)
		{
			newlySelectedRow = i;
			[_outlineView selectRow: newlySelectedRow byExtendingSelection: NO];
			break;
		}
		else if ([document indexForPage: [[outlineItem destination] page]] > newPageIndex)
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

// --------------------------------------------------------------------------------------------------------- linkSelected

- (void) linkSelected: (NSNotification *) notification
{
	// Update Info button enable state.
	[_infoButton setEnabled: ([notification object] != NULL)];
}

#pragma mark -
// --------------------------------------------------------------------------------------------------------------- doFind

- (void) doFind: (id) sender
{
	if ([[_pdfView document] isFinding])
		[[_pdfView document] cancelFindString];
	
	// Lazily allocate _searchResults.
	if (_searchResults == NULL)
		_searchResults = [[NSMutableArray arrayWithCapacity: 10] retain];
	
	[[_pdfView document] beginFindString: [sender stringValue] withOptions: 0];
}

// ------------------------------------------------------------------------------------------------------------ startFind

- (void) startFind: (NSNotification *) notification
{
	// Skip out if it is from another document.
	if ([notification object] != [_pdfView document])
		return;
	
	// Empty arrays.
	[_searchResults removeAllObjects];
	
	[_searchTable reloadData];
	[_searchProgress startAnimation: self];
}

// --------------------------------------------------------------------------------------------------------- findProgress

- (void) findProgress: (NSNotification *) notification
{
	// Skip out if it's not "our" PDFDocument finding. 
	if ([[_pdfView document] isFinding] == NO)
		return;
	
	[_searchProgress setDoubleValue: [[notification object] doubleValue] / [[_pdfView document] pageCount]];
}

// -------------------------------------------------------------------------------------------------------- didMatchString
// Called when an instance was located. Delegates can instantiate.

- (void) didMatchString: (PDFSelection *) instance
{
	// Skip out if it's not "our" PDFDocument finding. 
	if ([[_pdfView document] isFinding] == NO)
		return;
	
	// Add page label to our array.
	[_searchResults addObject: [instance copy]];
	
	// Force a reload.
	[_searchTable reloadData];
}

// -------------------------------------------------------------------------------------------------------------- endFind

- (void) endFind: (NSNotification *) notification
{
	// Skip out if it is from another document.
	if ([notification object] != [_pdfView document])
		return;
	
	[_searchProgress stopAnimation: self];
	[_searchProgress setDoubleValue: 0];
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

- (BOOL) validateMenuItem: (id) menuItem
{
	BOOL		enable = YES;
	
	if ([menuItem action] == @selector(getInfo:))
	{
		enable = [_pdfView selectedAnnotation] != NULL;
	}
	else if ([menuItem action] == @selector(newLink:))
	{
		enable = _mode == kEditPDFMode;
	}
	
	return enable;
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
		return ([[[_pdfView document] outlineItemForSelection: [_searchResults objectAtIndex: rowIndex]] label]);
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
		[_pdfView setCurrentSelection: [_searchResults objectAtIndex: rowIndex]];
		[_pdfView centerSelectionInVisibleArea: self];
	}
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

@end

