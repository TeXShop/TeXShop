//
//  MyPDFView.h
//  TeXShop
//
//  Originally part of My Document. Broken out dirk on Tue Jan 09 2001.
//

#import <AppKit/NSView.h>

@class MyDocument;

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
    int			imageType;
    double		oldMagnification;
    //double		oldWidth, oldHeight; // mitsu 1.29 (O) not used
    BOOL		fixScroll;
    NSPDFImageRep	*myRep;
    MyDocument		*myDocument;
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
@end

@interface FlippedClipView : NSClipView {
}
@end

NSBitmapImageRep *transformColor(NSBitmapImageRep *srcBitmap, NSColor *foreColor, NSColor *backColor, int param1);
NSData *getPICTDataFromBitmap(NSBitmapImageRep *bitmap);

NSString *extensionForType(int type); // mitsu 1.29 drag & drop

NSCursor *openHandCursor();
NSCursor *grabHandCursor();

@interface NSCursor (crosshairCursor)
+ (NSCursor *)_crosshairCursor;
// be careful: _crosshairCursor is not documented by Apple
@end


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


// to set the bounds of rotated view
#define Make90Rect(rect) (NSMakeRect(rect.origin.x, rect.origin.y+rect.size.height, rect.size.height, rect.size.width))
#define Make180Rect(rect) (NSMakeRect(-rect.origin.x-rect.size.width, -rect.origin.y-rect.size.height, rect.size.width, rect.size.height))
#define Make270Rect(rect) (NSMakeRect(rect.origin.x+rect.size.width, rect.origin.y, rect.size.height, rect.size.width))

#define JPEG_COMPRESSION_HIGH	1.0
#define JPEG_COMPRESSION_MEDIUM	0.95
#define JPEG_COMPRESSION_LOW	0.85

