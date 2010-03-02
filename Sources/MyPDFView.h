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
 * $Id: MyPDFView.h 108 2006-02-10 13:50:25Z fingolfin $
 *
 * Originally part of TSDocument. Broken out by dirk on Tue Jan 09 2001.
 *
 */

#import <AppKit/NSView.h>

@class TSDocument;

@interface MyPDFView : NSView
{
	id			currentPage;
	id			totalPage;
	id			myScale;
	id			myStepper;
	id			currentPage1;
	id			totalPage1;
	id			myScale1;
	id			myStepper1;
	int			documentType;
	double		oldMagnification;
	//double		oldWidth, oldHeight; // mitsu 1.29 (O) not used
	BOOL		fixScroll;
	BOOL		showSync;
	NSPDFImageRep	*myRep;
	TSDocument		*myDocument;
	int			rotationAmount;  // will be 0, 90, -90, 180
	double		theMagSize;
	//BOOL		largeMagnify; // for magnifying glass // mitsu 1.29 (O) not used

	// mitsu 1.29 (O)
	int 	pageStyle;
		int     firstPageStyle;
	float 	pageWidth;
	float 	pageHeight;
	float 	totalWidth;
	float 	totalHeight;
	int 	resizeOption;
	NSRect selectedRect;
	NSRect oldVisibleRect;
	NSTimer *selRectTimer;
	int mouseMode;
	int currentMouseMode;
	IBOutlet NSMatrix *mouseModeMatrix;
	IBOutlet NSMenu *mouseModeMenu;
	IBOutlet NSView *imageTypeView;
	IBOutlet NSPopUpButton *imageTypePopup;
		NSColor *pageBackgroundColor;
	// end mitsu 1.29
}

// set up the view
- (void) setImageType: (int)theType;
- (void) setDocument: (id) theDocument;
- (void) setImageRep: (NSPDFImageRep *)theRep;
- (void)setupForPDFRep: (NSPDFImageRep *)newRep style: (int)newPageStyle;
- (void)setFrameAndBounds; // mitsu 1.29 (O)
- (void)fitToSize;
- (BOOL)acceptsFirstResponder;
// magnification
- (double) magnification;
- (void) setMagnification: (double) magSize;
- (void) changeScale: sender;
- (void) doStepper: sender;
- (void) resetMagnification;
// drawRect
- (int)pageNumberForPoint: (NSPoint)aPoint;
- (NSPoint)pointForPage: (int)aPage;
- (NSImage *)imageFromRect: (NSRect)aRect;
// moving
- (void) previousPage: sender;
- (void) firstPage: sender;
- (void) up: sender;
- (void) top: sender;
- (void) nextPage: sender;
- (void) lastPage: sender;
- (void) down: sender;
- (void) bottom: sender;
- (void) left: sender;
- (void) right: sender;
- (void) goToPage: sender;
- (void)displayPage: (int)pagenumber;
- (void)updateCurrentPage;
- (void)wasScrolled: (NSNotification *)aNotification;
// rotation
- (void) rotateClockwise:sender;
- (void) rotateCounterclockwise:sender;
- (void) fixRotation;
- (float)rotationAmount;
// printing
- (void) printDocument: sender;
// mouseDown
- (void)changeMouseMode: (id)sender;
- (void)flagsChanged:(NSEvent *)theEvent;
- (void)doMagnifyingGlass:(NSEvent *)theEvent level: (int)level;
- (void)scrollByDragging: (NSEvent *)theEvent;
// select and copy
- (void)selectARect: (NSEvent *)theEvent;
- (void)selectAll: (id)sender;
- (void)updateMarquee: (NSTimer *)timer;
- (void)cleanupMarquee: (BOOL)terminate;
- (void)recacheMarquee;
- (void)moveSelection: (NSEvent *)theEvent;
- (BOOL)hasSelection;
- (NSData *)imageDataFromSelectionType: (int)type;
- (void)saveSelectionToFile: (id)sender;
- (void) chooseExportImageType: sender;
// drag & drop
- (void)startDragging: (NSEvent *)theEvent; // mitsu 1.29 drag & drop
// others
- (int)pageStyle;
- (void)changePageStyle: (id)sender;
- (int)resizeOption;
- (void)changePDFViewSize: (id)sender;
- (void)doSync: (NSEvent *)theEvent;
- (void)drawDotsForPage:(int)page atPoint: (NSPoint)p;
- (void)setShowSync: (BOOL)value;
@end

@interface FlippedClipView : NSClipView {
}
@end

NSBitmapImageRep *transformColor(NSBitmapImageRep *srcBitmap, NSColor *foreColor, NSColor *backColor, int param1);
NSData *getPICTDataFromBitmap(NSBitmapImageRep *bitmap);

extern NSString *extensionForType(int type); // mitsu 1.29 drag & drop
