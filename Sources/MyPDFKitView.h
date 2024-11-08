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
 * $Id: MyPDFKitView.h 260 2007-08-08 22:51:09Z richard_koch $
 *
 * Parts of this code are taken from Apple's example PDFKitViewer.
 *
 */

#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Quartz/Quartz.h>
#import <AppKit/NSEvent.h>
#import "OverView.h"
#import "TSDocument.h"
#import "HideView.h"
#import "synctex_parser.h"

@interface MyPDFKitView : PDFView <NSTableViewDelegate, NSWindowDelegate>
{
                    IBOutlet	NSTextField								*currentPage0;
    // "currentPage" is a very dangerous choice, because the PDFView class has a method called 'currentPage"
    // used by our code. But the instance variable holds the 'current page textbox' Luckily, the class has no
    // [self currentPage] method returning this variable. Therefore, all uses like [currentPage setValue:19]
    // refer to the textbox, but [self currentPage] gives the PDFPage in the document which is current. Gulp.
    
                    IBOutlet	NSTextField						*scurrentPage;
                    IBOutlet    NSTextField						*totalPage;
                    IBOutlet    NSTextField                     *stotalPage;
                    IBOutlet	NSTextField						*myScale;
                    IBOutlet	NSTextField						*smyScale;
                    IBOutlet	id								myStepper;
                    IBOutlet	id								smyStepper;
                    IBOutlet	NSTextField						*currentPage1;
                    IBOutlet	NSTextField						*totalPage1;
                    IBOutlet	NSTextField						*myScale1;
                    IBOutlet	id 				            	myStepper1;
                       
// @property (weak) IBOutlet	TSDocument						*myDocument;
                    IBOutlet	NSDrawer						*_drawer;
//           PDFOutline						*_outline;
                    IBOutlet	NSTextField						*_noOutlineText;
                    IBOutlet	NSOutlineView					*_outlineView;

//	NSMutableArray					*_searchResults;
                    IBOutlet    NSTableView                     *_searchTable;
                    IBOutlet    NSProgressIndicator             *_searchProgress;
                    IBOutlet    NSMatrix                        *mouseModeMatrix;
                    IBOutlet    NSMenu                          *mouseModeMenu;
                    IBOutlet    NSSearchField                   *_searchField;
   

//	NSWindow						*myPDFWindow;
	NSInteger								pageStyle;
    // NSInteger                               oldPageStyle;
    // NSInteger                               fullscreenPageStyle;
	NSInteger								firstPageStyle;
	NSInteger								resizeOption;
    // NSInteger                               oldResizeOption;
    // NSInteger                               fullscreenResizeOption;

	NSInteger								totalPages;

	NSInteger								mouseMode;
	NSInteger								currentMouseMode;

	NSInteger								totalRotation;
	NSInteger								scaleMag;  // view's magnification

	NSRect							selectedRect;
	NSRect							oldVisibleRect;
//	NSTimer							*selRectTimer;

	// copy/paste stuff
//	id								imageTypeView;
//	id								imageTypePopup;

	NSInteger						pageIndexForMark;
	NSRect							pageBoundsForMark;
	BOOL							drawMark;
	BOOL							showSync;
//	NSMutableArray					*sourceFiles;

	double							oldMagnification;

	BOOL							downOverLink;
	NSRect							rect;  // to simulate cacheImageInRect
	
	NSPoint							offsetPoint;
	
	BOOL							secondNeedsInitialization;
	NSInteger								secondTheIndex;
	NSRect							secondFullRect, secondVisibleRect;
	BOOL							protectFind;
    
    BOOL							oldSync;
    NSRect							syncRect[200];
	int								numberSyncRect;
    
    NSTask                          *externalSyncTask;
    NSTask                          *textMateTask;
    NSTask                          *otherEditorTask;
    struct synctex_scanner_t        *external_scanner;
//    OverView                        *overView;
    
// Variables used when splitting window
    
    NSInteger   splitTheIndex;
    NSRect      splitVisibleRect, splitVisibleRectLimited, splitFullRect;
    
// Variables for Annotations
    
    PDFAnnotation    *_activeAnnotation;
    NSPoint            _mouseDownLoc;
    NSPoint            _clickDelta;
    NSRect            _wasBounds;
    NSPoint        _wasPoint;
    BOOL            _mouseDownInAnnotation;
    BOOL            _dragging;
    BOOL            _resizing;
    BOOL           _resizeLineUsingEnd;
    BOOL            _resizeLineUsingStart;
    BOOL            _editMode;
    NSRect         selectedBounds;
    PDFPage        *selectedPage;
    BOOL           withBorder;
    
    
	
}

// @property BOOL      useAnnotationMenu;
@property (retain) PDFOutline						*outline;
@property (retain) NSMutableArray					*searchResults;
@property (weak) TSPreviewWindow                    *myPDFWindow;
@property (retain) NSTimer							*selRectTimer;
@property (retain) id								imageTypeView;
@property (retain) id								imageTypePopup;
@property (retain) NSMutableArray					*sourceFiles;
@property (retain) OverView                        *overView;
@property           BOOL                            waiting;
@property (weak)    IBOutlet	TSDocument          *myDocument;
@property (retain) NSString                         *oneOffSearchString;
@property           BOOL                            toolbarFind;
@property           NSInteger                       handlingLink; // 0 = NO, 1 = Possible, 2 = ShowingLink
@property           NSInteger                       timerNumber; // 0 <= timerNumber <= 100
@property           NSRect                          olderVisibleRect;
@property (retain)  NSTimer                         *updatePageNumberTimer;
@property (retain)  HideView                        *myHideView1;
@property (retain)  HideView                        *myHideView2;
@property BOOL                                      PDFFlashFix;
@property double                                    PDFFlashDelay;

@property BOOL                                      locationSaved;
@property BOOL                                      verticalSplitSaved;
@property BOOL                                      horizontalSplitSaved;
@property double                                    horizontalHeight1;
@property double                                    horizontalHeight2;
@property double                                    verticalWidth1;
@property double                                    verticalWidth2;

@property NSRect                                    oldVisibleRect;
@property NSInteger                                 oldIndex;
@property BOOL                                      oldUsed;
@property BOOL                                      doScroll;
@property BOOL                                      skipLinks;
@property BOOL                                      globalLongTerm;
@property NSInteger                                 stringAlignment;

@property BOOL                                      firstTime;



// - (void) scheduleAddintToolips;
- (id) init;
- (void) awakeFromNib;
- (void) setup;
- (void) initializeDisplay;
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
- (void) showWithPath: (NSString *)imagePath;
- (void) reShowWithPath: (NSString *)imagePath;
- (void) showForSecond;
- (void) prepareSecond;
- (void) reShowForSecond;
- (void) setupPageStyle;
- (void) setupMagnificationStyle;
- (BOOL) doReleaseDocument;

- (NSInteger)pageStyle;
- (NSInteger)firstPageStyle;
- (NSInteger)resizeOption;
- (void)setPageStyle: (NSInteger)thePageStyle;
- (void)setFirstPageStyle: (NSInteger)theFirstPageStyle;
- (void)setResizeOption: (NSInteger)theResizeOption;

- (void) rotateClockwise:sender;
- (void) rotateCounterclockwise:sender;
- (void) rotateClockwisePrimary;
- (void) rotateCounterclockwisePrimary;

- (void) goBack:sender;
- (void) goForward: sender;

- (void) goToKitPageNumber: (NSInteger)thePage;
- (void) goToKitPage: (id)sender;
- (void) previousPage: (id)sender;
- (void) nextPage: (id)sender;
- (void) firstPage: (id)sender;
- (void) lastPage: (id)sender;
- (IBAction) changeScale: sender;
- (IBAction) doStepper: sender;
- (IBAction) doFind: sender;
- (IBAction) doFindOne: sender;
- (void) doFindOneFullWindow: (id) sender;
- (void) doFindAgain;
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
- (void) zoomIn: (id)sender;
- (void) zoomOut: (id)sender;
- (void) fancyMouseDown: (NSEvent *)theEvent;
- (BOOL) toolIsMagnification;
- (BOOL) validateMenuItem:(NSMenuItem *)anItem;
- (void) changeLinkPopups;
// - (void) changeAnnotationMenu;
- (void)setCurrentSelection:(PDFSelection *)selection;
- (void)displayTotalPage: (NSInteger) totalPageCount;
- (void) displayPageChange: (NSInteger)pageNumber;
                    

// printing
- (void) printDocument: sender;
- (void)selectARect: (NSEvent *)theEvent;
- (void)selectAll: (id)sender;
- (void)updateMarquee: (NSTimer *)timer;
- (void)cleanupMarquee: (BOOL)terminate;
- (void)recacheMarquee;
- (BOOL)hasSelection;
- (NSData *)imageDataFromSelectionType: (NSInteger)type;
- (NSData *)PDFImageDataFromSelection;
// - (void)saveSelectionToFile: (id)sender;
// - (void) chooseExportImageType: sender;
// drag & drop
- (void)startDragging: (NSEvent *)theEvent; // mitsu 1.29 drag & drop
- (void)flagsChanged:(NSEvent *)theEvent;
- (void)doSync: (NSPoint)thePoint;
- (BOOL)doNewSync: (NSPoint)thePoint;
- (BOOL)doSyncTeX: (NSPoint)thePoint;
- (void)drawDotsForPage:(NSInteger)page atPoint: (NSPoint)p;
- (void)drawPage:(PDFPage *)page;
- (void)resetCursorRects;
- (void)setIndexForMark: (NSInteger)idx;
- (void)setBoundsForMark: (NSRect)bounds;
- (void)setDrawMark: (BOOL)value;
- (void)setupSourceFiles;
- (void)keyDown:(NSEvent *)theEvent;
- (void)updateBackground: (NSRect)aRect;
// - (void)goToKitPageNumber: (NSInteger) thePage;
- (NSMenu *)menuForEvent:(NSEvent *)theEvent;
- (void)fixMagnificationControls;
- (NSMutableArray *)getSearchResults;
- (void)resetSearchDelegate;
- (void)cancelSearch;
- (void)setProtectFind: (BOOL)value;
- (void) setShowSync: (BOOL)value;
- (void)setNumberSyncRect: (int)value;
- (void)setSyncRect: (int)which originX: (float)x originY: (float)y width: (float)width height: (float)height;
- (void)setOldSync: (BOOL)value;
- (void)changePageStyleTo:(NSInteger)newStyle;
- (void)changePDFViewSizeTo: (NSInteger)newResizeOption;
- (void)moveSplitToCorrectSpot:(NSInteger)index;
- (NSInteger)index;
- (NSImage *)imageFromSelection;
- (NSDrawer *)drawer;
- (void) breakConnections;
// - (void) setOverView:(OverView *)theOveView;
// - (OverView *)overView;
// - (BOOL)resignFirstResponder;
- (void)fixWhiteDisplay;

// splittingWindow
- (void)saveLocation;
- (void)saveLocationLimited;
- (void)writeLocation: (NSInteger)anIndex andFullRect: (NSRect) fullRect andVisibleRect: (NSRect) visibleRect;
- (void)readLocation: (NSInteger *) anIndex andFullRect: (NSRect *) fullRect andVisibleRect: (NSRect *) visibleRect;
- (void)restoreLocation;
- (void)restoreLocationLimited;
- (double)returnHeight;


@end

@interface MyPDFKitView (PDFDocumentDelegate)
- (void) documentDidBeginDocumentFind: (NSNotification *) notification;
- (void) documentDidEndDocumentFind: (NSNotification *) notification;
- (void) documentDidEndPageFind: (NSNotification *)notification;
- (void) documentDidFindMatch: (NSNotification *)notification;

@end

@interface MyPDFKitView (Magnification)
- (void)doMagnifyingGlass:(NSEvent *)theEvent level: (NSInteger)level;
- (void)doMagnifyingGlassMavericks:(NSEvent *)theEvent level: (NSInteger)level;
- (void)doMagnifyingGlassML:(NSEvent *)theEvent level: (NSInteger)level;
@end

@interface MyPDFKitView (ExternalEditor)
- (void)doErrorWithLine: (NSInteger)myErrorLine andPath: (NSString *)myErrorPath;
- (void)doExternalSync: (NSPoint)thePoint;
- (void)doNewExternalSync: (NSPoint)thePoint;
- (void)allocateExternalSyncScanner;
- (void)doExternalSyncTeXForPage: (NSInteger)pageNumber x: (CGFloat)xPosition y: (CGFloat)yPosition yOriginal: (CGFloat)yOriginalPosition;
- (void)doExternalSyncTeXForPageConTeXt: (NSInteger)pageNumber x: (CGFloat)xPosition y: (CGFloat)yPosition yOriginal: (CGFloat)yOriginalPosition;
@end

@interface MyPDFKitView (TextMate)
- (void)sendLineToTextMate: (NSInteger)aLine forPath: (NSString *)aPath;
- (void)sendLineToOtherEditor: (NSInteger)aLine forPath: (NSString *)aPath;
@end


@interface MyPDFKitView (Annotations)
- (void)strikeoutAnnotation: (id)sender;
- (void)highlightAnnotation: (id)sender;
- (void)underlineAnnotation: (id)sender;
- (void)squareAnnotation: (id)sender;
- (void)bsquareAnnotation: (id)sender;
- (void)circleAnnotation: (id)sender;
- (void)bcircleAnnotation: (id)sender;
- (void)textAnnotation: (id)sender;
- (void)btextAnnotation: (id)sender;
- (void)arrowAnnotation: (id)sender;
- (void)popupAnnotation: (id)sender;
- (void)displayChoicesPanel: (id)sender;
- (IBAction)endTheSheetWithOK:(id)sender;
- (IBAction)endTheSheetWithCancel:(id)sender;


// - (void) saveDocument: (id) sender;
// - (void) saveDocumentAs: (id) sender;
// - (void) delete: (id) sender;
// - (void) reflectFont;
// - (NSRect) resizeThumbForRect: (NSRect) rect rotation: (NSInteger) rotation;

 - (void) transformContextForPage: (PDFPage *) page;
 - (void) selectAnnotation: (PDFAnnotation *) annotation;
 - (void) annotationChanged;
 - (void)setEditMode: (id)sender;
- (void)removeStreams: (id)sender;
- (void)showColorPanel: (id)sender;
- (void)showFontPanel: (id)sender;
- (void)showTextPanel: (id)sender;
- (void)acceptString: (id)sender;
- (void)setRunMode: (id)sender;
- (void)closePanels;
- (void) saveAnnotations: (id)sender;
- (void) toggleEditMode: (id)sender;

- (BOOL)annotationDrawPage: (PDFPage *)page;
- (BOOL)annotationMouseDown: (NSEvent *)theEvent;
- (BOOL)annotationMouseDragged: (NSEvent *)theEvent;
- (BOOL)annotationMouseUp: (NSEvent *)theEvent;
- (BOOL)annotationKeyDown: (NSEvent *)theEvent;


@end


