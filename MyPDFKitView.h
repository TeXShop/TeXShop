/* PDFKitViewer - MyPDFView.h
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


#import <AppKit/AppKit.h>
#import <Quartz/Quartz.h>


@interface MyPDFKitView : PDFView
{
	id								currentPage;
    id								totalPage;
    id								myScale;
    id								myStepper;
    id								currentPage1;
    id								totalPage1;
    id								myScale1;
    id								myStepper1;
	id								myDocument;
	NSDrawer						*_drawer;
	PDFOutline						*_outline;
	NSTextField						*_noOutlineText;
	NSOutlineView					*_outlineView;
	
	NSMutableArray					*_searchResults;
	IBOutlet NSTableView			*_searchTable;
	IBOutlet NSProgressIndicator	*_searchProgress;
	IBOutlet NSMatrix				*mouseModeMatrix;
	IBOutlet NSMenu					*mouseModeMenu;
	
	
	NSWindow						*myPDFWindow;
	int								pageStyle;
	int								firstPageStyle;
	int								resizeOption;
	
	int								totalPages;
	
	int								mouseMode;
	int								currentMouseMode;
	
	int								totalRotation;
	
	NSRect							selectedRect;
	NSRect							oldVisibleRect;
	NSTimer							*selRectTimer;
	
	// copy/paste stuff
	id								imageTypeView;
	id								imageTypePopup;
	
	int								pageIndexForMark;
	NSRect							pageBoundsForMark;
	BOOL							drawMark;
	NSMutableArray					*sourceFiles;
	
	double							oldMagnification;
	
	BOOL							downOverLink;
}

- (void) setup;
- (void) initializeDisplay;
- (void) showWithPath: (NSString *)imagePath;
- (void) reShowWithPath: (NSString *)imagePath;
- (void) setupPageStyle;
- (void) setupMagnificationStyle;

- (void) rotateClockwise:sender;
- (void) rotateCounterclockwise:sender;

- (void) goBack:sender;
- (void) goForward: sender;

- (void) goToKitPageNumber: (int)thePage;
- (void) goToKitPage: (id)sender;
- (void) previousPage: (id)sender;
- (void) nextPage: (id)sender;
- (void) firstPage: (id)sender;
- (void) lastPage: (id)sender;
- (void) changeScale: sender;
- (void) doStepper: sender;
- (double)magnification;
- (void) setMagnification: (double)magnification;
- (void) changePageStyle: (id)sender;
- (void) changePDFViewSize: (id)sender;
- (void) copy: (id)sender;
- (void) saveSelectionToFile: (id)sender;
- (IBAction) toggleDrawer: (id) sender;
- (void) takeDestinationFromOutline: (id) sender;
- (void) changeMouseMode: (id)sender;
- (void) mouseDown: (NSEvent *) theEvent;
- (void) mouseUp: (NSEvent *) theEvent;
- (void) mouseDragged: (NSEvent *) theEvent;
- (void) mouseMoved: (NSEvent *) theEvent;
- (void) scrollByDragging: (NSEvent *)theEvent;

- (void)selectARect: (NSEvent *)theEvent;
- (void)selectAll: (id)sender;
- (void)updateMarquee: (NSTimer *)timer;
- (void)cleanupMarquee: (BOOL)terminate;
- (void)recacheMarquee;
- (void)moveSelection: (NSEvent *)theEvent;
- (BOOL)hasSelection;
- (NSData *)imageDataFromSelectionType: (int)type;
// - (void)saveSelectionToFile: (id)sender;
- (void) chooseExportImageType: sender;
// drag & drop
- (void)startDragging: (NSEvent *)theEvent; // mitsu 1.29 drag & drop
- (void)doMagnifyingGlass:(NSEvent *)theEvent level: (int)level;
- (void)flagsChanged:(NSEvent *)theEvent;
- (void)doSync: (NSEvent *)theEvent;
- (BOOL)doNewSync: (NSEvent *)theEvent;
- (void)drawDotsForPage:(int)page atPoint: (NSPoint)p;
- (void)drawPage:(PDFPage *)page;
- (void)resetCursorRects;
- (void)setIndexForMark: (int)index;
- (void)setBoundsForMark: (NSRect)bounds;
- (void)setDrawMark: (BOOL)value;
- (void)setupSourceFiles;
- (void)keyDown:(NSEvent *)theEvent;
@end

#define JPEG_COMPRESSION_HIGH	1.0
#define JPEG_COMPRESSION_MEDIUM	0.95
#define JPEG_COMPRESSION_LOW	0.85

