//
//  MyPDFView.m
//  TeXShop
//
//  Originally part of MyDocument. Broken out by dirk on Tue Jan 09 2001.
//

#import <AppKit/AppKit.h>
#import "MyPDFView.h"
#import "MyDocument.h"
#import "globals.h"
#import <Carbon/Carbon.h>

#define SUD [NSUserDefaults standardUserDefaults]

NSPanel *pageNumberWindow = nil;
// int imageCopyType = IMAGE_TYPE_JPEG_MEDIUM;  //koch; made this a global
BOOL centerPage = YES; // temporary option to turn on/off the centering of the page
NSData *draggedData;

@implementation MyPDFView : NSView

#pragma mark =====set up the view=====
- (id)initWithFrame:(NSRect)frameRect
{
    id		value;
    
    value = [super initWithFrame: frameRect];
    [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(changeMagnification:) 
            name:MagnificationChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(rememberMagnification:) 
            name:MagnificationRememberNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(revertMagnification:) 
            name:MagnificationRevertNotification object:nil];
    fixScroll = NO;
    myRep = nil;
    rotationAmount = 0;
    //largeMagnify = NO; // mitsu 1.29 (O) not used
	
	// mitsu 1.29 (O)
	myDocument = nil; // can be connected in InterfaceBuilder
	pageStyle = [SUD integerForKey: PdfPageStyleKey]; // set in "initWithFrame:"
        firstPageStyle = [SUD integerForKey: PdfFirstPageStyleKey];
	if (!pageStyle) pageStyle = PDF_MULTI_PAGE_STYLE; // should be single? set also in "updateControlsFromUserDefaults"
	mouseMode = [SUD integerForKey:PdfMouseModeKey];
	if (!mouseMode) mouseMode = MOUSE_MODE_MAG_GLASS;
	currentMouseMode = mouseMode;
	selRectTimer = nil;
	pageBackgroundColor = [[NSColor whiteColor] retain];
	// end mitsu 1.29
    
    return value;
}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[pageBackgroundColor release]; // mitsu 1.29
    // the next two lines are by Wolfgang Lux, fixing the bug that pdf files are still open in the finder after closing
     if (myRep != nil)
	[myRep release];   
    [super dealloc];
}

// mitsu 1.29 (O)
- (void)awakeFromNib 
{
	[self setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[mouseModeMatrix selectCellWithTag: mouseMode];
	[[mouseModeMenu itemWithTag: mouseMode] setState: NSOnState];
}
// end mitsu 1.29

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

- (void) setImageType: (int)theType;
{
    imageType = theType;
}

- (void) setDocument: (id) theDocument;
{
    myDocument = theDocument;
}

/*
WARNING: The code below attaches a pdf file to the pdf preview view.
There are three cases:
    a) This is the initial attachment
    b) This is a new version caused by typesetting again
    c) This is a new version caused by typesetting again and
        the bounds of the pdf file changed, perhaps because the
        user is experimenting with bounds in a slide package.
Cases b) and c) require care, because the user may have rotated and
magnified the image. The code for c) below handles this, but has
the unfortunate side effect of resetting the scrollers. Since b)
is the most common case and does not require resetting any bounds,
it is separated out for special minimal treatment to preserve
scroller position.
*/
- (void) setImageRep: (NSPDFImageRep *)theRep;
{
// mitsu 1.29 (O) completely changed
    [self renewGState];

	if ((imageType == isTeX) || (imageType == isPDF)) 
	{
		[self setupForPDFRep:theRep style:pageStyle];
	}
	else // imageType == isTIFF or isJPG or isEPS
	{
		if (theRep != nil)
		{
			if (theRep != myRep && myRep != nil)
				[myRep release];
			myRep = theRep;
			pageStyle = PDF_SINGLE_PAGE_STYLE;
			totalWidth = pageWidth = [myRep size].width;
			totalHeight = pageHeight = [myRep size].height;
			theMagSize = [SUD floatForKey:PdfMagnificationKey];
			int magPercent = round(theMagSize * 100.0);
			[myScale setIntValue: magPercent];
                        [myScale1 setIntValue: magPercent];
			[myStepper setIntValue: magPercent];
                        [myStepper1 setIntValue: magPercent];
			
			[self fitToSize];
			
			NSRect myBounds = [self bounds]; 
			NSPoint topLeftPoint;
			topLeftPoint.x = myBounds.origin.x;
			topLeftPoint.y = myBounds.origin.y + myBounds.size.height;
			[self scrollPoint: topLeftPoint];
            [totalPage setIntValue: 1];
            [totalPage1 setIntValue: 1];
            [currentPage setIntValue: 1];
            [currentPage1 setIntValue: 1];
            [currentPage display];
			[[self superview] setPostsBoundsChangedNotifications: NO];
		}
	}
	
	[pageBackgroundColor release];
	[SUD synchronize];
	if ([SUD stringForKey:PdfPageBack_RKey])
	{
		pageBackgroundColor = [[NSColor colorWithCalibratedRed: 
			[SUD floatForKey:PdfPageBack_RKey] 
			green: [SUD floatForKey:PdfPageBack_GKey] 
			blue: [SUD floatForKey:PdfPageBack_BKey] 
			alpha: 1] retain];
	}
	else
		pageBackgroundColor = [[NSColor whiteColor] retain];
		
	[[self enclosingScrollView] setNeedsDisplay:YES];

/*  int		pagenumber;
    NSRect	myBounds, newBounds;
    double	magsize;
    BOOL	modifiedRep = NO;
    double	newWidth, newHeight;
   
    NSScrollView *enclosingScrollView = [self enclosingScrollView];
    NSView *documentView = [enclosingScrollView documentView];

    magsize = [self magnification];
    theMagSize = magsize;
    [self renewGState];

    if (theRep != nil)
     
        {
        if (myRep != nil) {
            modifiedRep = YES;
            pagenumber = [myRep currentPage] + 1;
            [myRep release];
            }
        else
            pagenumber = 1;
        myRep = theRep;
        
        if ((imageType == isTeX) || (imageType == isPDF)) {
         
//            myBounds = [theRep bounds];
// mitsu change; the file dvipdfmx for Japanese users creates pdf files with nonzero origin, but the origin must
// be zero in TeXShop to draw correctly
            myBounds.origin.x = 0; myBounds.origin.y = 0;
            myBounds.size = [theRep bounds].size;
// end 
            
            newWidth = myBounds.size.width;
            newHeight = myBounds.size.height;
            [totalPage setIntValue: [myRep pageCount]];
            if (pagenumber < 1) pagenumber = 1;
            if (pagenumber > [myRep pageCount]) pagenumber = [myRep pageCount];
            [currentPage setIntValue: pagenumber];
            [currentPage display];
            [myRep setCurrentPage: (pagenumber - 1)];
            if (! modifiedRep) {
                // myBounds = [myRep bounds];
                // mitsu change
                myBounds.origin.x = 0; myBounds.origin.y = 0;
                myBounds.size = [myRep bounds].size;
                // end 

                oldWidth = myBounds.size.width;
                oldHeight = myBounds.size.height;
                newBounds.size.width = myBounds.size.width * (magsize);
                newBounds.size.height = myBounds.size.height * (magsize);
                [documentView setFrame: newBounds];
                [documentView setBounds: myBounds];
                // [self setMagnification: theMagSize];
                }
            else if ((abs(newHeight - oldHeight) > 1) || (abs(newWidth - oldWidth) > 1)) {
                oldWidth = newWidth;
                oldHeight = newHeight;
                newBounds.size.width = myBounds.size.width * (magsize);
                newBounds.size.height = myBounds.size.height * (magsize);
                [documentView setFrame: newBounds];
                [documentView setBounds: myBounds];
                [self setMagnification: theMagSize];
                }
            }
        else {
            [totalPage setIntValue: 1];
            [currentPage setIntValue: 1];
            [currentPage display];
            }
            
        [[self superview] setNeedsDisplay:YES];
        [[self enclosingScrollView] setNeedsDisplay:YES];
        [self setNeedsDisplay:YES];
        }
*/
}


// set up the view for PDFImageRep or change pageStyle
// if the view has previous imageRep, remember the page position
// calculate new page size
// set frame and bounds via "fitToSize"
// scroll so that top left corner is the same as previous imageRep
// 		calls "fitToSize" which calls "setFrameAndBounds" and "setMagnification"
- (void)setupForPDFRep: (NSPDFImageRep *)newRep style: (int)newPageStyle{
    int		pagenumber; // 0 to [newRep pageCount]-1
	NSPoint topLeft, aPoint, theOrigin;
    NSRect	myBounds, visRect;
	NSSize 	oldSize;
    BOOL	modifiedRep = NO, copiesOnScroll;

	copiesOnScroll = [(NSClipView *)[self superview] copiesOnScroll];
	[(NSClipView *)[self superview] setCopiesOnScroll: NO]; // this prevents annoying flashing effect

	if (myRep != nil) // if there is previous one, remember the size, pagenumber and top left
	{	
		modifiedRep = YES;
		if (selRectTimer) // if there was a selection
		{
			[[self window] discardCachedImage];
			oldVisibleRect.size.width = 0;
		}

		oldSize = NSMakeSize(totalWidth, totalHeight);
		if (pageStyle == PDF_SINGLE_PAGE_STYLE)
		{
			pagenumber = [myRep currentPage];
			topLeft.x = [self visibleRect].origin.x;
			topLeft.y = [self visibleRect].origin.y + [self visibleRect].size.height;
		}
		else // PDF_MULTI_PAGE_STYLE, PDF_DOUBLE_MULTI_PAGE_STYLE or PDF_TWO_PAGE_STYLE
		{
			visRect = [self visibleRect];
			aPoint = NSMakePoint(visRect.origin.x+visRect.size.width/2, 
								visRect.origin.y+visRect.size.height/2); // center
			pagenumber = [self pageNumberForPoint: aPoint]; // page number for the center
			aPoint = [self pointForPage: pagenumber]; // page origin
			topLeft.x = visRect.origin.x - aPoint.x; // relative position to page origin
			topLeft.y = visRect.origin.y + visRect.size.height - aPoint.y;
		}
		if (newRep != myRep)
			[myRep release];
	}
	else // this is a new one
	{
		pagenumber = 0;
		theMagSize = [SUD floatForKey:PdfMagnificationKey];
		int magPercent = round(theMagSize * 100.0);
        [myScale setIntValue: magPercent];
        [myScale1 setIntValue: magPercent];
    	[myStepper setIntValue: magPercent];
        [myStepper1 setIntValue: magPercent];
		//pageStyle = [SUD integerForKey: PdfPageStyleKey]; // moved to "initWithFrame:"
		//if (!pageStyle)
		//	pageStyle = PDF_MULTI_PAGE_STYLE; // should be single? 
		resizeOption = [SUD integerForKey: PdfFitSizeKey];
		if (!resizeOption)
			resizeOption = PDF_FIT_TO_NONE; // should be single? set also in "updateControlsFromUserDefaults"
		//[self setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	}
	// replace the image rep and the style
	myRep = newRep;
	pageStyle = newPageStyle;
	[totalPage setIntValue: [myRep pageCount]];
        [totalPage1 setIntValue: [myRep pageCount]];
	if (pagenumber < 0) pagenumber = 0;
	if (pagenumber >= [myRep pageCount]) pagenumber = [myRep pageCount]-1;
        [myRep setCurrentPage: pagenumber];
	// set up page size--pageWidth, pageHeight, totalWidth, totalHeight
	if (newPageStyle == PDF_SINGLE_PAGE_STYLE)
	{
		// [myRep setCurrentPage: pagenumber];
		totalWidth = pageWidth = [myRep size].width;
		totalHeight = pageHeight = [myRep size].height;
		[[self superview] setPostsBoundsChangedNotifications: NO];
	}
	else if (newPageStyle == PDF_MULTI_PAGE_STYLE)
	{
		totalWidth = pageWidth = [myRep size].width; 
		pageHeight = [myRep size].height;
		totalHeight = (pageHeight + PAGE_SPACE_V)*[myRep pageCount] - PAGE_SPACE_V;
		[[self superview] setPostsBoundsChangedNotifications: YES];
	}
	else // PDF_DOUBLE_MULTI_PAGE_STYLE or PDF_TWO_PAGE_STYLE
	{
                pageWidth = [myRep size].width; 
		if ([myRep pageCount] > 1)
			totalWidth = 2*pageWidth + PAGE_SPACE_H;
		else
			totalWidth = pageWidth;
		pageHeight = [myRep size].height; 
		if (newPageStyle == PDF_DOUBLE_MULTI_PAGE_STYLE) {
                        switch (firstPageStyle) {
                            case PDF_FIRST_LEFT: 
                                totalHeight = (pageHeight + PAGE_SPACE_V)*(([myRep pageCount]+1)/2) - PAGE_SPACE_V;
                                break;
                            case PDF_FIRST_RIGHT:
                                totalHeight = (pageHeight + PAGE_SPACE_V)*(([myRep pageCount]+2)/2) - PAGE_SPACE_V;
                                break;
                        }                
                }
		else // PDF_TWO_PAGE_STYLE
			totalHeight = pageHeight;
		[[self superview] setPostsBoundsChangedNotifications: YES];
	}
	// if the view is a new one or if the page size has been changed, 
	// set frame and bounds, then try to scroll so that top left corner 
	// corresponds to the same point when there was a previous imageRep
	if (!modifiedRep || (abs(totalWidth - oldSize.width) > 1) || 
						(abs(totalHeight - oldSize.height) > 1))
	{
		// set frame and bounds respecting the resizeOption
		[self fitToSize];
		
		myBounds = [self bounds];
		visRect = [self visibleRect];
		if (!modifiedRep) // if it's a new one
			topLeft = NSMakePoint(0, totalHeight);
		else if (newPageStyle != PDF_SINGLE_PAGE_STYLE) // use relative position
		{
			aPoint = [self pointForPage: pagenumber];
			topLeft.x += aPoint.x;
			topLeft.y += aPoint.y;
		}
		theOrigin.x = topLeft.x;
		theOrigin.y = topLeft.y - visRect.size.height;		
		// shift so that new visible rect is within bounds
		if (theOrigin.x + visRect.size.width > myBounds.origin.x + myBounds.size.width)
			theOrigin.x = myBounds.origin.x + myBounds.size.width - visRect.size.width;
		if (theOrigin.x < myBounds.origin.x)
			theOrigin.x = myBounds.origin.x;
		if (theOrigin.y < myBounds.origin.y)
			theOrigin.y = myBounds.origin.y;
		if (theOrigin.y + visRect.size.height > myBounds.origin.y + myBounds.size.height)
			theOrigin.y = myBounds.origin.y + myBounds.size.height - visRect.size.height;
		visRect.origin = theOrigin;
		[self scrollRectToVisible:visRect];
		if (selRectTimer) // if there was a selection
		{
			[selRectTimer invalidate]; // this will release the timer
			selRectTimer = nil;
		}
	}
	// update currentPage text field
	if (newPageStyle == PDF_SINGLE_PAGE_STYLE)
	{
		[currentPage setIntValue: pagenumber+1];
                [currentPage1 setIntValue: pagenumber+1];
		[currentPage display];
	}
	else
	{
		[self updateCurrentPage];	
	}
	[(NSClipView *)[self superview] setCopiesOnScroll: copiesOnScroll];
        
}

// this is the routine which set up frame and bounds of the view, 
// given totalWidth, totalHeight, theMagSize and rotationAmount.
// if the width and/or height of pages are smaller than the bounds of 
// clip view and if centerPage is YES, extend the bounds and frame 
// so that the pages are centered.  
// for this reason, the bounds can be bigger than totalWidth and totalHeight.
- (void)setFrameAndBounds
{
	NSRect newBounds, newFrame, superBounds;
	
	newBounds = NSMakeRect(0, 0, totalWidth, totalHeight);
	superBounds = [[self superview] bounds];
	newFrame.origin.x = newFrame.origin.y = 0;
	if (rotationAmount == 0 || rotationAmount == 180)
	{
		newFrame.size.width = totalWidth * (theMagSize);
		if (superBounds.size.width > newFrame.size.width + 1.0)
		{
			newBounds.origin.x = -(superBounds.size.width-newFrame.size.width)/(2*theMagSize);
			newBounds.size.width = superBounds.size.width/theMagSize;
			newFrame.size.width = superBounds.size.width;
		}
		newFrame.size.height = totalHeight * (theMagSize);
		if (superBounds.size.height > newFrame.size.height + 1.0)
		{
			newBounds.origin.y = -(superBounds.size.height-newFrame.size.height)/(2*theMagSize);
			newBounds.size.height = superBounds.size.height/theMagSize;
			newFrame.size.height = superBounds.size.height;
		}
	}
	else
	{
		newFrame.size.width = totalHeight * (theMagSize);
		if (centerPage && superBounds.size.width > newFrame.size.width + 1.0)
		{
			newBounds.origin.y = -(superBounds.size.width-newFrame.size.width)/(2*theMagSize);
			newBounds.size.height = superBounds.size.width/theMagSize;
			newFrame.size.width = superBounds.size.width;
		}
		newFrame.size.height = totalWidth * (theMagSize);
		if (centerPage && superBounds.size.height > newFrame.size.height + 1.0)
		{
			newBounds.origin.x = -(superBounds.size.height-newFrame.size.height)/(2*theMagSize);
			newBounds.size.width = superBounds.size.height/theMagSize;
			newFrame.size.height = superBounds.size.height;
		}
	}
	[self setFrame: newFrame];

	if (rotationAmount == 0)
		[self setBounds: newBounds];
	else if (rotationAmount == 90)
		[self setBounds: Make90Rect(newBounds)];
	else if (rotationAmount == 180)
	{
		[self setBounds: Make180Rect(newBounds)];
		[self setBoundsRotation: 180];
	}
	else if (rotationAmount == -90)
		[self setBounds: Make270Rect(newBounds)];
}


// set up the frame and bounds of the view after setting the magnification 
// according to the resizeOption
- (void)fitToSize;
{
	float fitWidth, fitHeight, tempMagH, tempMagV, newMag;
	
	if (resizeOption == PDF_ACTUAL_SIZE || resizeOption == PDF_FIT_TO_NONE)
	{
		[self setFrameAndBounds]; // this adjusts the space outside the pages
		[[self enclosingScrollView] setNeedsDisplay:YES]; 
	}
	else // PDF_FIT_TO_WIDTH, PDF_FIT_TO_HEIGHT or PDF_FIT_TO_WINDOW
	{	
		fitWidth = totalWidth;
		fitHeight = pageHeight;	
		if (rotationAmount == 0 || rotationAmount == 180)
		{
			tempMagH = [[self superview] bounds].size.width/fitWidth;
			tempMagV = [[self superview] bounds].size.height/fitHeight;
		}
		else
		{
			tempMagH = [[self superview] bounds].size.width/fitHeight;
			tempMagV = [[self superview] bounds].size.height/fitWidth;
		}
		
		if (resizeOption == PDF_FIT_TO_WIDTH)
			newMag = tempMagH;
		else if (resizeOption == PDF_FIT_TO_HEIGHT)  
			newMag = tempMagV;
		else 
			newMag = (tempMagH <= tempMagV)?tempMagH:tempMagV;
		
		newMag = floor(newMag * 100 +0.0001)/100;
		[self setMagnification: newMag];
	}
}

- (BOOL)acceptsFirstResponder;
{
    return YES;
}


#pragma mark =====magnification=====

- (double)magnification;
{
    double	magsize;
   
    magsize = [myScale intValue] / 100.0;
    return magsize;
}

/* 
WARNING: The code in setMagnification, and in RotateClockwise just below, is
tricky. The setFrame and setBounds commands send notifications to other
views to reset their bounds. These notifications are acted on AFTER setMagnification
completes. If these notifications incorrectly set various sizes, it is not
possible to fix those sizes inside setMagnification.

The commands below work, and were found after various unpleasant experiments
failed. If you change the code below, be sure to test carefully!
*/
- (void) setMagnification: (double)magSize;
{
	// mitsu 1.29 (O) 
	NSRect	myBounds, visRect;
	NSPoint topLeft, theOrigin;
	int	magPercent;
	BOOL copiesOnScroll;
	
	copiesOnScroll = [(NSClipView *)[self superview] copiesOnScroll];
	[(NSClipView *)[self superview] setCopiesOnScroll: NO]; // this prevents annoying flashing effect
	
	[[self window] discardCachedImage];
	oldVisibleRect.size.width = 0;
	theMagSize = magSize;
	myBounds = [self bounds];
	visRect = [self visibleRect];
	topLeft.x = visRect.origin.x;
	topLeft.y = visRect.origin.y + visRect.size.height;

	[self setFrameAndBounds];
	
	// keep the same point as top left
	myBounds = [self bounds];
	visRect = [self visibleRect];
	theOrigin.x = topLeft.x;
	theOrigin.y = topLeft.y - visRect.size.height;
	// adjust so that new visible rect will be within bounds
	if (theOrigin.x + visRect.size.width > myBounds.origin.x + myBounds.size.width)
		theOrigin.x = myBounds.origin.x + myBounds.size.width - visRect.size.width;
	if (theOrigin.x < myBounds.origin.x)
		theOrigin.x = myBounds.origin.x;
	if (theOrigin.y < myBounds.origin.y)
		theOrigin.y = myBounds.origin.y;
	if (theOrigin.y + visRect.size.height > myBounds.origin.y + myBounds.size.height)
		theOrigin.y = myBounds.origin.y + myBounds.size.height - visRect.size.height;
	visRect.origin = theOrigin;
	[self scrollRectToVisible:visRect];
	
	magPercent = round(theMagSize * 100.0);
	[myScale setIntValue: magPercent];
        [myScale1 setIntValue: magPercent];
	[myStepper setIntValue: magPercent];
        [myStepper1 setIntValue: magPercent];
	
	if (((imageType == isTeX) || (imageType == isPDF)) && 
		((pageStyle == PDF_MULTI_PAGE_STYLE) || (pageStyle == PDF_DOUBLE_MULTI_PAGE_STYLE))) 
		[self updateCurrentPage];

	[[self enclosingScrollView] setNeedsDisplay:YES]; 
	[(NSClipView *)[self superview] setCopiesOnScroll: copiesOnScroll];
	// end mitsu 1.29

/* old code was: 
        double	mag;
        NSRect	myBounds, newBounds;
        double	tempRotationAmount;
        
        NSScrollView *enclosingScrollView = [self enclosingScrollView];
        NSView *documentView = [enclosingScrollView documentView];
        
        tempRotationAmount = rotationAmount;
        rotationAmount = 0;
        [self fixRotation];
        rotationAmount = tempRotationAmount;
      
        myBounds = [self bounds];
        newBounds.size.width = myBounds.size.width * (magSize);
        newBounds.size.height = myBounds.size.height * (magSize);
        theMagSize = magSize;
        [documentView setFrame: newBounds];
        [documentView setBounds: myBounds];
        
        [self fixRotation];
        
        mag = round(magSize * 100.0);
        // Warning: if the next line is changed to setIntValue, the magnification
        //    fails! 
        [myScale setDoubleValue: mag];
        // [myStepper setIntValue: mag];

        [[self superview] setNeedsDisplay:YES];
        [[self enclosingScrollView] setNeedsDisplay:YES];
        [self setNeedsDisplay:YES];
*/
}

- (void) changeScale: sender;
{
    int		scale;
    double	magSize;
    
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
    [self setMagnification: magSize];
	
	// mitsu 1.29b 
	// uncheck menu item Preview=>Magnification
	NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
						NSLocalizedString(@"Preview", @"Preview")] submenu];
	NSMenu *menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Magnification", @"Magnification")] submenu];
	[[menu itemWithTag: resizeOption] setState: NSOffState];
	if (magSize == 1.0)
		resizeOption = PDF_ACTUAL_SIZE;
	else
		resizeOption = PDF_FIT_TO_NONE;
	// uncheck menu item Preview=>Magnification
	[[menu itemWithTag: resizeOption] setState: NSOnState];
	
	// end mitsu 1.29
}

- (void) doStepper: sender;
{
    if (sender == myStepper) 
        [myScale setIntValue: [myStepper intValue]];
    else
        [myScale setIntValue: [myStepper1 intValue]];
    [self changeScale: self];
}


// mitsu 1.29b
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	// this method will be called when the field was modified and 
	// the field is about to quit FirstResponder.  
	// if the event is not keyDown or it is keyDown with tab, 
	// revert the field.  (i.e. the values in the fields take effect only on 
	// return/enter.)  MyPDFView should be the delegate of the text fields. 
	// if we use [currentPage setIntValue: ...], it sometimes fails.  
	// set the string directly to the field editor.  
                
	if ([[[self window] currentEvent] type] != NSKeyDown ||
		[[[[self window] currentEvent] characters] isEqualToString: @"\t"])
	{
		if (control == currentPage)
		{
			int pagenumber;
			if (pageStyle == PDF_SINGLE_PAGE_STYLE)
			{
				pagenumber = [myRep currentPage]+1;
			}
			else
			{
				NSRect visRect = [self visibleRect];
				pagenumber = [self pageNumberForPoint: 
					NSMakePoint(visRect.origin.x+visRect.size.width/2,
							visRect.origin.y+visRect.size.height/2)] + 1;
			}
			[fieldEditor setString:[NSString stringWithFormat:@"%d", pagenumber]];
		}
		else if (control == myScale)
		{
			int magPercent = round(theMagSize * 100.0);
			[fieldEditor setString: [NSString stringWithFormat: @"%d", magPercent]];
		}
	}
	return YES;
}
// end 1.29b


/*
- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    // [[self window] makeFirstResponder:[[aNotification userInfo] objectForKey:@"NSFieldEditor"]];
}
*/ 

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


#pragma mark =====drawRect=====

- (void)drawRect:(NSRect)aRect 
{
    NSRect   pageRect, boxRect; 
    NSPoint  p;
    
	if (myRep == nil) return;

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
			NSRectFill(aRect);
		}
	}
	
	if ((imageType == isTeX) || (imageType == isPDF)) 
	{
		if (pageStyle == PDF_SINGLE_PAGE_STYLE)
		{
			pageRect = NSMakeRect(0,0,totalWidth,totalHeight);
			if ([NSGraphicsContext currentContextDrawingToScreen])
			{
				[pageBackgroundColor set];
				NSRectFill(pageRect); 
			}
			NSRectClip(pageRect);
			[myRep draw];
                        p.x = 0; p.y = 0;
                        [self drawDotsForPage:[myRep currentPage] atPoint: p];
		}
		else // PDF_MULTI_PAGE_STYLE, PDF_DOUBLE_MULTI_PAGE_STYLE or PDF_TWO_PAGE_STYLE
		{
			int i, startPage, endPage;
			NSPoint thePoint;
			// arrays of edge names and gray levels for NSDrawTiledRects()
			static NSRectEdge mySides[] = { NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge, 
											NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge, 
											NSMinYEdge, NSMaxXEdge };
			static float myGrays[] = {.8, .8, .8, .8, .5, .5, .5, .5, .3, .3};
			
			pageRect.size = NSMakeSize(pageWidth, pageHeight);
			startPage = [self pageNumberForPoint: 
						NSMakePoint(aRect.origin.x, aRect.origin.y+aRect.size.height)];
			endPage = [self pageNumberForPoint: 
						NSMakePoint(aRect.origin.x+aRect.size.width, aRect.origin.y)];
			for (i=startPage; i<=endPage; i++)
			{
				thePoint = [self pointForPage: i];
				pageRect.origin = thePoint;
				if ( i>= 0 && i< [myRep pageCount])
				{
					[NSGraphicsContext saveGraphicsState];
                                        boxRect.origin.x = pageRect.origin.x -2;
                                        boxRect.origin.y = pageRect.origin.y - 3;
                                        boxRect.size.width = pageRect.size.width + 5;
                                        boxRect.size.height = pageRect.size.height + 5;
                                        NSRectClip(boxRect);
					NSDrawTiledRects(boxRect, boxRect, mySides, myGrays, 10); // this eats edges 
					NSRectClip(pageRect);
					if ([NSGraphicsContext currentContextDrawingToScreen])
					{
						[pageBackgroundColor set];
						NSRectFill(pageRect); 
					}
					[myRep setCurrentPage: i];
					[myRep drawAtPoint: thePoint];
                                        [self drawDotsForPage: i atPoint: thePoint];
                                        [NSGraphicsContext restoreGraphicsState];
				}
			}
		}
	}
	else if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) 
	{
		pageRect = NSMakeRect(0,0,totalWidth,totalHeight);
		if ([NSGraphicsContext currentContextDrawingToScreen])
		{
			[pageBackgroundColor set];
			NSRectFill(pageRect); 
		}
		NSRectClip(pageRect);
		[myRep draw];
	}
}

// calculate the page number(0 to pageCount-1) from point
- (int)pageNumberForPoint: (NSPoint)aPoint
{
	if (pageStyle == PDF_MULTI_PAGE_STYLE)
	{
		return floor((totalHeight - aPoint.y)/(pageHeight + PAGE_SPACE_V));
	}
	else if (pageStyle == PDF_DOUBLE_MULTI_PAGE_STYLE)
	{
                switch (firstPageStyle) {
                
                    case PDF_FIRST_LEFT:
                        return (2 * floor((totalHeight - aPoint.y)/(pageHeight + PAGE_SPACE_V)) 
		 		+ floor(aPoint.x/(pageWidth + PAGE_SPACE_H)));
                                
                    case PDF_FIRST_RIGHT:
                         return (2 * floor((totalHeight - aPoint.y)/(pageHeight + PAGE_SPACE_V)) 
		 		+ floor(aPoint.x/(pageWidth + PAGE_SPACE_H)) - 1);
                    }
                    
	}
	else if (pageStyle == PDF_TWO_PAGE_STYLE)
	{
		switch (firstPageStyle) { 
                
                    case PDF_FIRST_LEFT: return  (2 * ([myRep currentPage]/2)
		 	+ ((aPoint.x >= pageWidth + PAGE_SPACE_H/2)?1:0));
                        
                    case PDF_FIRST_RIGHT: return  (2 * (([myRep currentPage] + 1)/2) - 1
			+ ((aPoint.x >= pageWidth + PAGE_SPACE_H/2)?1:0));
                    }
	}
	return 0;
}

// calculate the origin from page number
- (NSPoint)pointForPage: (int)aPage;
{
	NSPoint thePoint;
	if (pageStyle == PDF_MULTI_PAGE_STYLE)
	{
		thePoint.x = 0;
		thePoint.y = totalHeight - (pageHeight + PAGE_SPACE_V)*aPage - pageHeight;
	}
	else if (pageStyle == PDF_DOUBLE_MULTI_PAGE_STYLE)
	{
                switch (firstPageStyle) {
                
                    case PDF_FIRST_LEFT:
                        thePoint.x = (pageWidth + PAGE_SPACE_H)*(aPage % 2);
                        thePoint.y = totalHeight - (pageHeight + PAGE_SPACE_V)*(aPage/2) - pageHeight;
                        break;
                        
                    case PDF_FIRST_RIGHT:
                        thePoint.x = (pageWidth + PAGE_SPACE_H)*((aPage + 1) % 2);
                        thePoint.y = totalHeight - (pageHeight + PAGE_SPACE_V)*((aPage + 1)/2) - pageHeight;
                        break;
                    }
	}
	else // PDF_TWO_PAGE_STYLE
	{
		[myRep setCurrentPage: aPage];
                switch (firstPageStyle) {
                    case PDF_FIRST_LEFT:   thePoint.x = (pageWidth + PAGE_SPACE_H)*(aPage % 2);
                                            break;
                    case PDF_FIRST_RIGHT:   thePoint.x = (pageWidth + PAGE_SPACE_H)*((aPage + 1) % 2);
                                            break;
                    }
		thePoint.y = 0;
	}
	return thePoint;
}

// NSImage from rectangle
// We imitate by NSAffineTransform what System does to calculate the coordinate 
// transformation from  view's coordinate to window.  move the origin to (0,0).  
// then drawRect into an image.  
- (NSImage *)imageFromRect: (NSRect)aRect
{
	NSImage *image;
	NSAffineTransform *aMap;
	NSSize aSize;
	
	if (NSIsEmptyRect(aRect)) return nil;
	aSize = [self convertSize: aRect.size toView: nil]; // autual size in window
	image = [[NSImage alloc] initWithSize: aSize]; // create an image to which we will draw
	aMap = [NSAffineTransform transform];
	[aMap scaleBy: theMagSize];
	if (rotationAmount == 0)
	{
		[aMap translateXBy: -aRect.origin.x yBy: -aRect.origin.y];
	}
	else if (rotationAmount == 90)
	{
		[aMap rotateByDegrees: 90];
		[aMap translateXBy: -aRect.origin.x yBy: -aRect.origin.y-aRect.size.height];
	}
	else if (rotationAmount == 180)
	{
		[aMap rotateByDegrees: 180];
		[aMap translateXBy: -aRect.origin.x-aRect.size.width yBy: -aRect.origin.y-aRect.size.height];
	}
	else if (rotationAmount == -90)
	{
		[aMap rotateByDegrees: -90];
		[aMap translateXBy: -aRect.origin.x-aRect.size.width yBy: -aRect.origin.y];
	}
	[image lockFocus];
	//[NSGraphicsContext saveGraphicsState];
	[aMap concat];
	[[NSColor windowBackgroundColor] set];
	NSRectFill(aRect);
	[self drawRect: aRect];
	//[NSGraphicsContext restoreGraphicsState];
	[image unlockFocus];
	return [image autorelease];
}

#pragma mark =====moving=====

- (void) previousPage: sender
{	
    int		pagenumber;
    NSRect	myBounds, myVisible, newVisible;

    if (!myRep || (imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
        
	if (pageStyle == PDF_SINGLE_PAGE_STYLE)
	{
		if ([SUD boolForKey:NoScrollEnabledKey]) {
			pagenumber = [myRep currentPage];
			if (pagenumber > 0) {
				[self cleanupMarquee: YES];
				pagenumber--;
				[currentPage setIntValue: (pagenumber + 1)];
                                [currentPage1 setIntValue: (pagenumber + 1)];
				[myRep setCurrentPage: pagenumber];
				[currentPage display];
				[self display];
				}
			}
		
		else {
			myBounds = [self bounds];
			myVisible = [self visibleRect];
			newVisible = myVisible;
			newVisible.origin.y = myVisible.origin.y + myVisible.size.height;
			if (newVisible.origin.y > (myBounds.size.height - myVisible.size.height)) 
				newVisible.origin.y = (myBounds.size.height - myVisible.size.height);
			if (! [self scrollRectToVisible:newVisible]) {
				pagenumber = [myRep currentPage];
                            	if (pagenumber > 0) {
					[self cleanupMarquee: YES];
					pagenumber--;
					[currentPage setIntValue: (pagenumber + 1)];
                                        [currentPage1 setIntValue: (pagenumber + 1)];
					[myRep setCurrentPage: pagenumber];
					[currentPage display];
					newVisible = myVisible;
					newVisible.origin.y = 0;
					[self scrollRectToVisible:newVisible];
						// [self display];
					}
				}
			[self display];
			}
	}
	else // PDF_MULTI_PAGE_STYLE, PDF_DOUBLE_MULTI_PAGE_STYLE or PDF_TWO_PAGE_STYLE
	{
	//	pagenumber = [myRep currentPage];
                pagenumber = [currentPage intValue] - 1;
		if (pageStyle == PDF_DOUBLE_MULTI_PAGE_STYLE )
                    switch (firstPageStyle) {
                        case PDF_FIRST_LEFT: 
                            if ((pagenumber % 2 == 1) && 
				NSMinX([self visibleRect]) < 1)
                            pagenumber--;
                            break;
                        case PDF_FIRST_RIGHT: 
                            if (((pagenumber + 1) % 2 == 1) && 
				NSMinX([self visibleRect]) < 1)
                            pagenumber--;
                            break;
                        }
                if (pageStyle == PDF_TWO_PAGE_STYLE) {
                    switch (firstPageStyle) {
                        case PDF_FIRST_LEFT: 
                            if ((pagenumber % 2 == 1) && 
				NSMinX([self visibleRect]) < 1)
                            pagenumber--;
                            break;
                        case PDF_FIRST_RIGHT:
                            if (((pagenumber + 1) % 2 == 1) && 
				NSMinX([self visibleRect]) < 1)
                            pagenumber--;
                            break;
                        }
                    }
		if (pagenumber > 0) 
		{
			pagenumber--;
			[self displayPage: pagenumber];
		}
	}
}

- (void) firstPage: sender
{	
    int		pagenumber;

    if (!myRep || (imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
	
	if (pageStyle == PDF_SINGLE_PAGE_STYLE)
	{
		pagenumber = 0;
		if (pagenumber != [myRep currentPage])
			[self cleanupMarquee: YES];
		[currentPage setIntValue: (pagenumber + 1)];
                [currentPage1 setIntValue: (pagenumber + 1)];
		[myRep setCurrentPage: pagenumber];
		[currentPage display];
		[self display];
	}
	else // PDF_MULTI_PAGE_STYLE, PDF_DOUBLE_MULTI_PAGE_STYLE or PDF_TWO_PAGE_STYLE
	{
		[self displayPage: 0];
	}
}


- (void) up: sender
{	
    NSRect	myBounds, myVisible, newVisible;
	// mitsu 1.29 (O)  commented out--this should work with TIFF etc. 
    //if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;        
    if (!myRep) return;
	
	myBounds = [self bounds];
	myVisible = [self visibleRect];
	newVisible = myVisible;
	// newVisible.origin.y = myVisible.origin.y + myVisible.size.height;
	newVisible.origin.y = myVisible.origin.y + 20;
	if (newVisible.origin.y > (myBounds.size.height - myVisible.size.height)) 
		newVisible.origin.y = (myBounds.size.height - myVisible.size.height);
	[self scrollRectToVisible:newVisible];
	[self display];
}

- (void) top: sender
{	
    NSRect	myBounds, myVisible, newVisible;

	// mitsu 1.29 (O)  commented out--this should work with TIFF etc. 
    //if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
    if (!myRep) return;
	
	myBounds = [self bounds];
	myVisible = [self visibleRect];
	newVisible = myVisible;
	newVisible.origin.y = (myBounds.size.height - myVisible.size.height);
	[self scrollRectToVisible:newVisible];
	[self display];
}



- (void) nextPage: sender;
{	
    int		pagenumber;
    NSRect	myBounds, myVisible, newVisible;

    if (!myRep || (imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
        
	if (pageStyle == PDF_SINGLE_PAGE_STYLE)
	{
		if ([SUD boolForKey:NoScrollEnabledKey]) {
			pagenumber = [myRep currentPage];
			if (pagenumber < ([myRep pageCount]) - 1) {
				[self cleanupMarquee: YES];
				pagenumber++;
				[currentPage setIntValue: (pagenumber + 1)];
                                [currentPage1 setIntValue: (pagenumber + 1)];
				[myRep setCurrentPage: pagenumber];
				[currentPage display];
				[self display];
				}
			} 
		
		else {
			myBounds = [self bounds];
			myVisible = [self visibleRect];
			newVisible = myVisible;
			newVisible.origin.y = myVisible.origin.y - myVisible.size.height;
			if (newVisible.origin.y < 0) newVisible.origin.y = 0;
			if (! [self scrollRectToVisible:newVisible]) {
				pagenumber = [myRep currentPage];
				if (pagenumber < ([myRep pageCount]) - 1) {
					[self cleanupMarquee: YES];
					pagenumber++;
					[currentPage setIntValue: (pagenumber + 1)];
                                        [currentPage1 setIntValue: (pagenumber + 1)];
					[myRep setCurrentPage: pagenumber];
					[currentPage display];
					newVisible = myVisible;
					newVisible.origin.y = (myBounds.size.height - myVisible.size.height);
					[self scrollRectToVisible:newVisible];
					}
				}
			[self display];
			}
	}
	else // PDF_MULTI_PAGE_STYLE, PDF_DOUBLE_MULTI_PAGE_STYLE or PDF_TWO_PAGE_STYLE
	{
		// pagenumber = [myRep currentPage];
                pagenumber = [currentPage intValue] - 1;
                if ((pageStyle == PDF_DOUBLE_MULTI_PAGE_STYLE || 
				pageStyle == PDF_TWO_PAGE_STYLE))
                    switch (firstPageStyle) {
                        case PDF_FIRST_LEFT:
                            if ((pagenumber % 2 == 0) && 
				NSMaxX([self visibleRect]) > totalWidth - 1)
                            pagenumber++;
                            break;
                        case PDF_FIRST_RIGHT:
                            if (((pagenumber + 1) % 2 == 0) && 
				NSMaxX([self visibleRect]) > totalWidth - 1)
                            pagenumber++;
                            break;
                        }
		if (pagenumber < ([myRep pageCount]) - 1) 
		{
			pagenumber++;
                        [self cleanupMarquee: YES];
			[self displayPage: pagenumber];
		}
	}
}

- (void) lastPage: sender;
{	
    int		pagenumber;

    if (!myRep || (imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
        
	if (pageStyle == PDF_SINGLE_PAGE_STYLE)
	{
		if (pagenumber != [myRep currentPage])
			[self cleanupMarquee: YES];
		pagenumber = [myRep pageCount] - 1;
		[currentPage setIntValue: (pagenumber + 1)];
                [currentPage1 setIntValue: (pagenumber + 1)];
		[myRep setCurrentPage: pagenumber];
		[currentPage display];
		[self display];
	}
	else // PDF_MULTI_PAGE_STYLE, PDF_DOUBLE_MULTI_PAGE_STYLE or PDF_TWO_PAGE_STYLE
	{
		[self displayPage: [myRep pageCount] - 1];
	}
}


- (void) down: sender
{	
    NSRect	myBounds, myVisible, newVisible;
	// mitsu 1.29 (O)  commented out--this should work with TIFF etc. 
	//if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
    if (!myRep) return;
	            
	myBounds = [self bounds];
	myVisible = [self visibleRect];
	newVisible = myVisible;
	// newVisible.origin.y = myVisible.origin.y - myVisible.size.height;
	newVisible.origin.y = myVisible.origin.y - 20;
	if (newVisible.origin.y < 0) newVisible.origin.y = 0;
	[self scrollRectToVisible:newVisible];
	[self display];
}

- (void) bottom: sender
{	
    NSRect	myBounds, myVisible, newVisible;
	// mitsu 1.29 (O)  commented out--this should work with TIFF etc. 
    //if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) return;
    if (!myRep) return;
	            
	myBounds = [self bounds];
	myVisible = [self visibleRect];
	newVisible = myVisible;
	newVisible.origin.y = 0;
	[self scrollRectToVisible:newVisible];
	[self display];
}

- (void)left: (id)sender
{	
    NSRect	myBounds, newVisible;

	if (!myRep) return;
	
    if ((imageType == isTeX) || (imageType == isPDF))
	{
		if (pageStyle == PDF_SINGLE_PAGE_STYLE)
		{
			[self previousPage: sender];
		}
		else // PDF_MULTI_PAGE_STYLE, PDF_DOUBLE_MULTI_PAGE_STYLE or PDF_TWO_PAGE_STYLE
		{
			myBounds = [self bounds];
			newVisible = [self visibleRect];
			if ((pageStyle == PDF_DOUBLE_MULTI_PAGE_STYLE || pageStyle == PDF_TWO_PAGE_STYLE) && 
				(newVisible.origin.x > myBounds.origin.x + SCROLL_TOLERANCE)) 
			{	// scroll horizontally
				newVisible.origin.x -= newVisible.size.width - HORIZONTAL_SCROLL_OVERLAP;
				if (newVisible.origin.x < myBounds.origin.x)
					newVisible.origin.x = myBounds.origin.x;
			}
			else if (pageStyle == PDF_TWO_PAGE_STYLE)
                        {
                                 switch (firstPageStyle) {
                                    case PDF_FIRST_LEFT: 
                                        if ([myRep currentPage] > 1)
                                            [self displayPage: 2*([myRep currentPage]/2)-1];
                                        break;
                                    case PDF_FIRST_RIGHT:
                                        if ([myRep currentPage] > 0)
                                            [self displayPage: 2*(([myRep currentPage] + 1)/2)-2];
                                        break;
                                    }
                                return;
			}
			else 
			{	// scroll vertically
				newVisible.origin.y += newVisible.size.height - VERTICAL_SCROLL_OVERLAP;
				if (newVisible.origin.y > (myBounds.origin.y + myBounds.size.height - newVisible.size.height)) 
					newVisible.origin.y = (myBounds.origin.y + myBounds.size.height - newVisible.size.height);
				newVisible.origin.x = myBounds.origin.x + myBounds.size.width - newVisible.size.width;
			}
			[self scrollRectToVisible:newVisible];
			//[self display];
			[self updateCurrentPage];
		}
	}
	else
	{
		myBounds = [self bounds];
		newVisible = [self visibleRect];
		newVisible.origin.x -= HORIZONTAL_SCROLL_AMOUNT;
		if (newVisible.origin.x < myBounds.origin.x)
			newVisible.origin.x = myBounds.origin.x;
		[self scrollRectToVisible:newVisible];
	}
}


- (void)right: (id)sender
{	
    NSRect	myBounds, newVisible;

	if (!myRep) return;
	
    if ((imageType == isTeX) || (imageType == isPDF))
	{
		if (pageStyle == PDF_SINGLE_PAGE_STYLE)
		{
			[self nextPage: sender];
		}
		else // PDF_MULTI_PAGE_STYLE, PDF_DOUBLE_MULTI_PAGE_STYLE or PDF_TWO_PAGE_STYLE
		{
			myBounds = [self bounds];
			newVisible = [self visibleRect];
			if ((pageStyle == PDF_DOUBLE_MULTI_PAGE_STYLE || pageStyle == PDF_TWO_PAGE_STYLE) && 
					(newVisible.origin.x + newVisible.size.width < 
					myBounds.origin.x + myBounds.size.width - SCROLL_TOLERANCE)) 
			{	// scroll horizontally
				newVisible.origin.x += newVisible.size.width - HORIZONTAL_SCROLL_OVERLAP;
				if (newVisible.origin.x + newVisible.size.width > myBounds.origin.x + myBounds.size.width)
					newVisible.origin.x = myBounds.origin.x + myBounds.size.width - newVisible.size.width;
			}
			else if (pageStyle == PDF_TWO_PAGE_STYLE)
			{
                                switch (firstPageStyle) {
                                    case PDF_FIRST_LEFT: 
                                        if (2*([myRep currentPage]/2)+2 <[myRep pageCount])
                                            [self displayPage: 2*([myRep currentPage]/2)+2];
                                        break;
                                    case PDF_FIRST_RIGHT:
                                        if (2*(([myRep currentPage] + 1)/2)+1 < [myRep pageCount])
                                            [self displayPage: 2*(([myRep currentPage] + 1)/2)+1];
                                        break;
                                    }
                                return;
                        }
			else
			{	// scroll vertically
				newVisible.origin.y -= newVisible.size.height - VERTICAL_SCROLL_OVERLAP;
				if (newVisible.origin.y < myBounds.origin.y) 
					newVisible.origin.y = myBounds.origin.y;
				newVisible.origin.x = myBounds.origin.x;
			}
			[self scrollRectToVisible:newVisible];
			//[self display];
			[self updateCurrentPage];
		}
	}
	else
	{
		myBounds = [self bounds];
		newVisible = [self visibleRect];
		newVisible.origin.x += HORIZONTAL_SCROLL_AMOUNT;
		if (newVisible.origin.x + newVisible.size.width > myBounds.origin.x + myBounds.size.width)
			newVisible.origin.x = myBounds.origin.x + myBounds.size.width - newVisible.size.width;
		[self scrollRectToVisible:newVisible];
	}
}


- (void) goToPage: sender;
{
        int		pagenumber;
	NSRect		myBounds, myVisible, newVisible;

	if ((imageType == isTIFF) || (imageType == isJPG) || (imageType == isEPS)) 
	{
		[currentPage setIntValue: 1];
                [currentPage1 setIntValue: 1];
		[currentPage display];
		return;
	}
	if (myRep == nil) return;
	
        if (sender == currentPage1)
                pagenumber = [currentPage1 intValue];
            else
	pagenumber = [currentPage intValue];
	if (pagenumber < 1) pagenumber = 1;
	if (pagenumber > [myRep pageCount]) pagenumber = [myRep pageCount];
	[currentPage setIntValue: pagenumber];
        [currentPage1 setIntValue: pagenumber];
	[currentPage display];
        [[self window] makeFirstResponder: currentPage];
	if (pageStyle == PDF_SINGLE_PAGE_STYLE)
	{
		if (pagenumber != [myRep currentPage])
			[self cleanupMarquee: YES];
		[myRep setCurrentPage: (pagenumber - 1)];
		if (![SUD boolForKey:NoScrollEnabledKey]) {
			myBounds = [self bounds];
			myVisible = [self visibleRect];
			newVisible = myVisible;
			newVisible.origin.y = (myBounds.size.height - myVisible.size.height);
			[self scrollRectToVisible:newVisible];
			}
		[[self enclosingScrollView] setNeedsDisplay: YES]; // mitsu 1.29b
	}
	else // PDF_MULTI_PAGE_STYLE, PDF_DOUBLE_MULTI_PAGE_STYLE or PDF_TWO_PAGE_STYLE
	{
		[self displayPage: pagenumber - 1];
	}
}

// go to page number
- (void)displayPage: (int)pagenumber
{
	NSRect myBounds, newVisible;
	NSPoint thePoint;
	
	if (pageStyle == PDF_TWO_PAGE_STYLE && pagenumber/2 != [myRep currentPage]/2)
		[self cleanupMarquee: YES];
	[currentPage setIntValue: (pagenumber + 1)];
        [currentPage1 setIntValue: (pagenumber + 1)];
	[currentPage display];
	myBounds = [self bounds];
	newVisible.size = [self visibleRect].size;
	thePoint = [self pointForPage: pagenumber];
	newVisible.origin.x = thePoint.x;
	newVisible.origin.y = thePoint.y + pageHeight - newVisible.size.height;
	if ((pageStyle == PDF_DOUBLE_MULTI_PAGE_STYLE || pageStyle == PDF_TWO_PAGE_STYLE) &&
		(newVisible.origin.x+newVisible.size.width > myBounds.origin.x+myBounds.size.width))
            switch (firstPageStyle) {
                case PDF_FIRST_LEFT: if (pagenumber % 2)
                    newVisible.origin.x = myBounds.origin.x+myBounds.size.width-newVisible.size.width;
                    break;
                case PDF_FIRST_RIGHT: if ((pagenumber + 1) % 2)
                    newVisible.origin.x = myBounds.origin.x+myBounds.size.width-newVisible.size.width;
                    break;
                }
	[self scrollRectToVisible: newVisible];
	[[self enclosingScrollView] setNeedsDisplay: YES]; // mitsu 1.29b
}


// update "currentPage" text field on scroll or move--used only in Multi/Double page
- (void)updateCurrentPage
{
	NSPoint thePoint;
	NSRect visRect;
	int pageNumber;
	
	visRect = [self visibleRect];
	thePoint = visRect.origin;
	// use the center of page
	thePoint.x += visRect.size.width/2;
	thePoint.y += visRect.size.height/2;
	// or use top left - page spaces?
	//thePoint.x += PAGE_SPACE_H;
	//thePoint.y += visRect.size.height - PAGE_SPACE_V;
	pageNumber = [self pageNumberForPoint: thePoint] + 1;
	[currentPage setIntValue: pageNumber];
        [currentPage1 setIntValue: pageNumber];
	[currentPage display];

	if (pageNumberWindow)
	{
		NSScroller *scroller = [[self enclosingScrollView] verticalScroller];
		NSRect aRect = [scroller rectForPart: NSScrollerKnob];
		aRect = [scroller convertRect: aRect toView: nil];
		NSPoint aPoint = [[self window] convertBaseToScreen: aRect.origin];
		aPoint.x -= PAGE_WINDOW_H_OFFSET;
		aPoint.y += aRect.size.height/2 + PAGE_WINDOW_V_OFFSET;
		[pageNumberWindow setFrameOrigin: aPoint];
		
		NSString *pageString = [NSString stringWithFormat: @"%d/%d", pageNumber, [myRep pageCount]];
                
                
		NSView *theView = [pageNumberWindow contentView];
		[theView lockFocus];
 		[[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.6 alpha:1.0] set]; // change color?
				NSRectFill([theView bounds]);
		[pageString drawAtPoint: NSMakePoint(PAGE_WINDOW_DRAW_X,PAGE_WINDOW_DRAW_Y) 
							withAttributes: [NSDictionary dictionary]];
                [[NSGraphicsContext currentContext] flushGraphics];                                        
 		[theView unlockFocus];
	}
}

// receive notification from clip view when pdfView is scrolled
- (void)wasScrolled: (NSNotification *)aNotification
{ 
        if (((imageType == isTeX) || (imageType == isPDF)) && 
		((pageStyle == PDF_MULTI_PAGE_STYLE) || (pageStyle ==
                        PDF_DOUBLE_MULTI_PAGE_STYLE)
			|| (pageStyle == PDF_TWO_PAGE_STYLE))) 
		[self updateCurrentPage];
  
}


#pragma mark =====rotation=====

- (void) rotateClockwise:sender
{
    rotationAmount = rotationAmount - 90;
    if (rotationAmount < -90)
        rotationAmount = 180;
    [self fixRotation];
    [[self enclosingScrollView] setNeedsDisplay:YES];// mitsu 1.29 (O)
}


- (void) rotateCounterclockwise:sender
{
    rotationAmount = rotationAmount + 90;
    if (rotationAmount > 180)
        rotationAmount = -90;
    [self fixRotation];
    [[self enclosingScrollView] setNeedsDisplay:YES];// mitsu 1.29 (O)
}


- (void) fixRotation
{
	// mitsu 1.29 (O) completely rewritten
    NSPoint	theCenter, theOrigin;
    NSRect	myBounds, visRect;
    double	width, height;
    
	myBounds = [self bounds];
	width = myBounds.size.width;
	height = myBounds.size.height;
	visRect = [self visibleRect];
	theCenter.x = visRect.origin.x + visRect.size.width/2;
	theCenter.y = visRect.origin.y + visRect.size.height/2;

	[self setBoundsRotation: rotationAmount];
	
	[self setFrameAndBounds];
	
	// keep the same point as the center
	myBounds = [self bounds];
	visRect = [self visibleRect]; 
	//visRect = [self convertRect: [[self superview] bounds] fromView: [self superview]];
	theOrigin.x = theCenter.x - visRect.size.width/2;
	theOrigin.y = theCenter.y - visRect.size.height/2;
	// adjust so that new visible rect will be within bounds
	if (theOrigin.x + visRect.size.width > myBounds.origin.x + myBounds.size.width)
		theOrigin.x = myBounds.origin.x + myBounds.size.width - visRect.size.width;
	if (theOrigin.x < myBounds.origin.x)
		theOrigin.x = myBounds.origin.x;
	if (theOrigin.y < myBounds.origin.y)
		theOrigin.y = myBounds.origin.y;
	if (theOrigin.y + visRect.size.height > myBounds.origin.y + myBounds.size.height)
		theOrigin.y = myBounds.origin.y + myBounds.size.height - visRect.size.height;
	visRect.origin = theOrigin;
	[self scrollRectToVisible:visRect];
	// end mitsu 1.29
	
/* old code was:
    NSPoint	aPoint;
    NSRect	newBounds, selfBounds;
    double	width, height;
    
     NSScrollView *enclosingScrollView = [self enclosingScrollView];
     NSView *documentView = [enclosingScrollView documentView];
     
     selfBounds = [self bounds];
     width = selfBounds.size.width;
     height = selfBounds.size.height;
     
     [documentView setBoundsRotation: rotationAmount];

     switch (rotationAmount) {
        case 0: aPoint.x = 0; aPoint.y = 0;
                newBounds.size.width = width * theMagSize;
                newBounds.size.height = height * theMagSize;
                break;
        case 90: aPoint.x = 0; aPoint.y = height; 
                newBounds.size.width = height * theMagSize;
                newBounds.size.height = width * theMagSize;
                break;
        case 180: aPoint.x = width; aPoint.y = height; 
                newBounds.size.width = width * theMagSize;
                newBounds.size.height = height * theMagSize;
                break;
        case -90: aPoint.x = width; aPoint.y = 0;
                newBounds.size.width = height * theMagSize;
                newBounds.size.height = width * theMagSize;
        }
    [documentView setBoundsOrigin: aPoint];
    [documentView setFrameSize: newBounds.size];
     
    [self setNeedsDisplay:YES];
    [[self superview] setNeedsDisplay:YES];
    [[self enclosingScrollView] setNeedsDisplay:YES];
*/
}

- (float)rotationAmount
{
	return rotationAmount;
}


#pragma mark =====printing=====

- (void) printDocument: sender;
{
    [myDocument printDocument: sender];
}	

- (void) printSource: sender;
{
    [myDocument printSource: sender];
}

#pragma mark =====sync=====


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
    
    includeFileName = nil;
        
    // The code below finds the page number, and the position of the click
    // in view coordinates. 
        
    NSPoint windowPosition = [theEvent locationInWindow];
    NSPoint viewPosition = [self convertPoint: windowPosition fromView:nil];
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


#pragma mark =====mouse down=====

// mouseDown etc.
// react to mouseDown, change mouseMode and cursor
// mouseMode can be set by the toolbar item "mouseModeMatrix"
//		MOUSE_MODE_SCROLL: scroll (hand cursor)
//		MOUSE_MODE_MAG_GLASS: magnifying glass
//		MOUSE_MODE_MAG_GLASS_L: large magnifying glass
//		MOUSE_MODE_SELECT: select a rectangle (cross hair cursor)
// modifier keys override the mouseMode and defines currentMouseMode
//		control: scroll
//		option: magnifying glass
//		command: selection
//		double (or more) click: magnifying glass
// cursor is updated in resetCursorRects
//		this is called when bounds/frame are changed or from NSWindow's 
//		invalidateCursorRectsForView.  the latter is called from 
//		changeMouseMode and flagsChanged.  
// mouseDown dispatches the event accroding to currentMouseMode
//		MOUSE_MODE_SCROLL: scrollByDragging:
//		MOUSE_MODE_MAG_GLASS/MOUSE_MODE_MAG_GLASS_L: doMagnifyingGlass:level:
//		MOUSE_MODE_SELECT: selectARect:
//		doMagnifyingGlass:level: can start from a level which is determined 
//		by currentMouseMode, or by clickCount and mouseMode.  
//		see doMagnifyingGlass:level: for more on modifiers.  

- (void)mouseDown:(NSEvent *)theEvent
{
        // koch; Dec 5, 2003
        if (!([theEvent modifierFlags] & NSAlternateKeyMask) && ([theEvent modifierFlags] & NSCommandKeyMask)) {
                currentMouseMode = mouseMode;
                [[self window] invalidateCursorRectsForView: self];
                [self doSync: theEvent];
                return;
                }
                

//	[[self window] makeFirstResponder: [self window]]; // mitsu 1.29b
        [[self window] makeFirstResponder: self];

	if ([theEvent clickCount] >= 2)
	{
		currentMouseMode = MOUSE_MODE_MAG_GLASS;
		[[self window] invalidateCursorRectsForView: self];
                #ifndef SELECTION_SHOUND_PERSIST
                [self cleanupMarquee: YES];
                #endif
		[self doMagnifyingGlass: theEvent level:
			((mouseMode==MOUSE_MODE_MAG_GLASS_L)?1:((mouseMode==MOUSE_MODE_MAG_GLASS)?0:(-1)))];
	}
	else
	{
		switch (currentMouseMode)
		{
			case MOUSE_MODE_SCROLL:
                                #ifndef SELECTION_SHOUND_PERSIST
                                [self cleanupMarquee: YES];
                                #endif
				[self scrollByDragging: theEvent];
				break;
			case MOUSE_MODE_MAG_GLASS: 
                                #ifndef SELECTION_SHOUND_PERSIST
                                [self cleanupMarquee: YES];
                                #endif
				[self doMagnifyingGlass: theEvent level: 0];
				break;
			case MOUSE_MODE_MAG_GLASS_L: 
                                #ifndef SELECTION_SHOUND_PERSIST
                                [self cleanupMarquee: YES];
                                #endif
				[self doMagnifyingGlass: theEvent level: 1];
				break;
			case MOUSE_MODE_SELECT: 
				if(selRectTimer && [self mouse: [self convertPoint: 
					[theEvent locationInWindow] fromView: nil] inRect: selectedRect])
				{
					// mitsu 1.29 drag & drop
					if (([theEvent modifierFlags] & NSCommandKeyMask) && 
										(mouseMode == MOUSE_MODE_SELECT))
						[self moveSelection: theEvent];
					else
						[self startDragging: theEvent]; 
					// end mitsu 1.29
				}
				else
					[self selectARect: theEvent];
				break;
		}
	}
}

// change mouse mode in response to mouseModeMatrix or mouseModeMenu
- (void)changeMouseMode: (id)sender
{
	if ([sender isKindOfClass: [NSButton class]] || [sender isKindOfClass: [NSMenuItem class]])
	{
		[[mouseModeMenu itemWithTag: mouseMode] setState: NSOffState]; 
		mouseMode = currentMouseMode = [sender tag];
		[mouseModeMatrix selectCellWithTag: mouseMode];
		[[mouseModeMenu itemWithTag: mouseMode] setState: NSOnState];
	}
	else if ([sender isKindOfClass: [NSMatrix class]])
	{
		[[mouseModeMenu itemWithTag: mouseMode] setState: NSOffState];
		mouseMode = currentMouseMode = [[sender selectedCell] tag];
		[mouseModeMatrix selectCellWithTag: mouseMode];
		[[mouseModeMenu itemWithTag: mouseMode] setState: NSOnState];
	}
	[[self window] invalidateCursorRectsForView: self]; // this updates the cursor rects
        [self cleanupMarquee: YES]; // added by koch to erase marquee
}


// change mouse mode when a modifier key is pressed
- (void)flagsChanged:(NSEvent *)theEvent
{
        if (([theEvent modifierFlags] & NSCommandKeyMask) && (!([theEvent modifierFlags] & NSAlternateKeyMask)))
                currentMouseMode = MOUSE_MODE_NULL; 
	else if ([theEvent modifierFlags] & NSControlKeyMask)
		currentMouseMode = MOUSE_MODE_SCROLL;
	else if ([theEvent modifierFlags] & NSCommandKeyMask)
		currentMouseMode = MOUSE_MODE_SELECT;
	else if ([theEvent modifierFlags] & NSAlternateKeyMask)
		currentMouseMode = MOUSE_MODE_MAG_GLASS;
	else
		currentMouseMode = mouseMode;
		
	[[self window] invalidateCursorRectsForView: self]; // this updates the cursor rects
}

// update cursor rect
// called from NSWindow's invalidateCursorRectsForView or when the bounds/frame are changed
- (void)resetCursorRects
{
	switch (currentMouseMode)
	{
		case MOUSE_MODE_SCROLL: 
			[self addCursorRect:[self visibleRect] cursor:openHandCursor()];
			break;
		case MOUSE_MODE_SELECT: 
			[self addCursorRect:[self visibleRect] cursor:[NSCursor _crosshairCursor]];
			if (selRectTimer)
				[self addCursorRect:selectedRect cursor:[NSCursor arrowCursor]];
			break;
                case MOUSE_MODE_NULL:
		case MOUSE_MODE_MAG_GLASS: // want magnifying glass cursor?
		case MOUSE_MODE_MAG_GLASS_L: 
			[self addCursorRect:[self visibleRect] cursor:[NSCursor arrowCursor]];
			break;
		default: 
			[self addCursorRect:[self visibleRect] cursor:[NSCursor arrowCursor]];
			break;
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

- (void)doMagnifyingGlass:(NSEvent *)theEvent level: (int)level
{
    NSPoint mouseLocWindow, mouseLocView;
	NSRect oldBounds, newBounds, magRectWindow, magRectView;
	BOOL postNote, cursorVisible;
	float magWidth, magHeight, magOffsetX, magOffsetY;
	int originalLevel, currentLevel;
	float magScale; 	//0.4	// you may want to change this

	postNote = [self postsBoundsChangedNotifications];
	[self setPostsBoundsChangedNotifications: NO];	// block the view from sending notification
	
	oldBounds = [self bounds];
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
				newBounds = NSMakeRect(mouseLocView.x+magScale*(oldBounds.origin.x-mouseLocView.x), 
								mouseLocView.y+magScale*(oldBounds.origin.y-mouseLocView.y),
								magScale*(oldBounds.size.width), magScale*(oldBounds.size.height));
				
				// mitsu 1.29 (S1) fix for rotated view
				if (rotationAmount == 0)
					[self setBounds: newBounds];
				else if (rotationAmount == 90)
					[self setBounds: Make90Rect(newBounds)];
				else if (rotationAmount == 180)
				{
					[self setBounds: Make180Rect(newBounds)];
					[self setBoundsRotation: 180];
				}
				else if (rotationAmount == -90)
					[self setBounds: Make270Rect(newBounds)];
				// it was:
				//[self setBounds: newBounds];
				
				// draw it in the rect
				magRectView = NSInsetRect([self convertRect:magRectWindow fromView:nil],1,1);
				[self displayRect: magRectView]; // this flushes the buffer
				
				// reset bounds
				if (rotationAmount == 0)
					[self setBounds: oldBounds];
				if (rotationAmount == 90)
					[self setBounds: Make90Rect(oldBounds)];
				if (rotationAmount == 180)
				{
					[self setBounds: Make180Rect(oldBounds)];
					[self setBoundsRotation: 180];
				}
				else if (rotationAmount == -90)
					[self setBounds: Make270Rect(oldBounds)];
				// it was: 
				//[self setBounds: oldBounds];
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
				[[self window] flushWindow];
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
	[self setPostsBoundsChangedNotifications: postNote];
	[self flagsChanged: theEvent]; // update cursor
	// recache the image around marquee for quicker response
	oldVisibleRect.size.width = 0;
	[self cleanupMarquee: NO];
	[self recacheMarquee]; 
}
// end Magnifying Glass

/* old version 
// added by mitsu --(I) Magnifying Glass
- (void)doMagnifyingGlass:(NSEvent *)theEvent
{
    NSPoint mouseLocWindow, mouseLocView;
	NSRect oldBounds, newBounds, magRectWindow, magRectView, oldRect, diffRect;
	float minY, maxY;
	BOOL postNote, cursorVisible, commandDown = NO, wasDoubleClick, wasTripleClick;
	float magWidth, magHeight, magOffsetX, magOffsetY;
	
#define magScale 	0.4	// you may want to change this

	//if (rotationAmount == 180) // mitsu 1.29 (S1) due to a bug in PDFImageRep, escape here
	//	return;
        
	postNote = [self postsBoundsChangedNotifications];
	[self setPostsBoundsChangedNotifications: NO];	// block the view from sending notification
	//[self lockFocus]; // the view is already focused, so it is not necessary to lock?
	
	oldBounds = [self bounds];
	oldRect.origin = [self convertPoint: [theEvent locationInWindow] fromView:nil];
	oldRect.size = NSMakeSize(0,0);
	cursorVisible = YES;
	wasDoubleClick = ([theEvent clickCount] == 2); // mitsu 1.29 (S5)-- allow double/triple click
	wasTripleClick = ([theEvent clickCount] > 2);
	
	do {
		if ([theEvent type]==NSLeftMouseDragged || [theEvent type]==NSLeftMouseDown || [theEvent type]==NSFlagsChanged) 
		{	            
			// get Mouse location and check if it is with the view's rect
			if (!([theEvent type]==NSFlagsChanged))
				mouseLocWindow = [theEvent locationInWindow];
			mouseLocView = [self convertPoint: mouseLocWindow fromView:nil];
			// check if the mouse is in the rect
			if([self mouse:mouseLocView inRect:[self visibleRect]])
			{
				if (cursorVisible)
				{
					[NSCursor hide];
					cursorVisible = NO;
				}
				// define rect for magnification in window coordinate
				if (wasTripleClick) // mitsu 1.29 (S5) set magRectWindow here
				{
					magRectWindow = [self convertRect:[self visibleRect] toView:nil];
				}
				else
				{
					if (wasDoubleClick) 
					{
						magWidth = 380;
						magHeight = 250;
						magOffsetX = magWidth/2;
						magOffsetY = magHeight/2;
					}
					else
					{
						// koch
						if (([theEvent modifierFlags] & NSCommandKeyMask)) 
						{
							if (! commandDown) {
								largeMagnify = !largeMagnify;
								if (largeMagnify) {
									magWidth = 380; magHeight = 250;}
								else {
									magWidth = 150; magHeight = 100;}
								commandDown = YES;
							}
						}
						else 
							commandDown = NO;
						if (([theEvent modifierFlags] & NSAlternateKeyMask) && (! commandDown)) 
						{
							if (largeMagnify) {
								magWidth = 150; magHeight = 100;}
							else {
								magWidth = 380; magHeight = 250;}
							}
						else {
							if (largeMagnify) {
								magWidth = 380; magHeight = 250;}
							else {
								magWidth = 150; magHeight = 100;}
							}
						// end koch
					}
					magOffsetX = magWidth/2;
					magOffsetY = magHeight/2;
					magRectWindow = NSMakeRect(mouseLocWindow.x-magOffsetX, mouseLocWindow.y-magOffsetY, 
											magWidth, magHeight);
				}
				// resize bounds around mouseLocView
				newBounds = NSMakeRect(mouseLocView.x+magScale*(oldBounds.origin.x-mouseLocView.x), 
								mouseLocView.y+magScale*(oldBounds.origin.y-mouseLocView.y),
								magScale*(oldBounds.size.width), magScale*(oldBounds.size.height));
				
				// mitsu 1.29 (S1) fix for rotated view
				if (rotationAmount == 0)
					[self setBounds: newBounds];
				else if (rotationAmount == 90)
					[self setBounds: Make90Rect(newBounds)];
				else if (rotationAmount == 180)
				{
					[self setBounds: Make180Rect(newBounds)];
					[self setBoundsRotation: 180];
				}
				else if (rotationAmount == -90)
					[self setBounds: Make270Rect(newBounds)];
				// it was:
				//[self setBounds: newBounds];
				// end mitsu 1.29
				
				// draw it in the rect
				magRectView = NSInsetRect([self convertRect:magRectWindow fromView:nil],1,1);
				[self displayRect: magRectView];
				
				// reset bounds
				// mitsu 1.29 (S1)
				if (rotationAmount == 0)
					[self setBounds: oldBounds];
				if (rotationAmount == 90)
					[self setBounds: Make90Rect(oldBounds)];
				if (rotationAmount == 180)
				{
					[self setBounds: Make180Rect(oldBounds)];
					[self setBoundsRotation: 180];
				}
				else if (rotationAmount == -90)
					[self setBounds: Make270Rect(oldBounds)];
				// it was: 
				//[self setBounds: oldBounds];
				// end mitsu 1.29
				
				magRectView = [self convertRect:magRectWindow fromView:nil];
				// clean up the trace
				diffRect.origin.x = oldRect.origin.x;
				diffRect.size.width = oldRect.size.width;
				if ((diffRect.size.height = magRectView.origin.y-oldRect.origin.y) > 0)
				{	// erase bottom
					diffRect.origin.y = oldRect.origin.y;
					[self displayRect: diffRect]; //NSIntegralRect()?
					minY = magRectView.origin.y;
				}
				else
					minY = oldRect.origin.y;
				if ((diffRect.size.height = oldRect.origin.y+oldRect.size.height
									-magRectView.origin.y-magRectView.size.height) > 0)
				{	// erase top
					diffRect.origin.y = magRectView.origin.y+magRectView.size.height;
					[self displayRect: diffRect]; //NSIntegralRect()?
					maxY = magRectView.origin.y+magRectView.size.height;
				}
				else
					maxY = oldRect.origin.y+oldRect.size.height;
				diffRect.origin.y = minY;
				diffRect.size.height = maxY-minY;
				if ((diffRect.size.width = magRectView.origin.x-oldRect.origin.x) > 0)
				{	// erase left
					diffRect.origin.x = oldRect.origin.x;
					[self displayRect: diffRect]; //NSIntegralRect()?
				}
				if ((diffRect.size.width = oldRect.origin.x+oldRect.size.width
											-magRectView.origin.x-magRectView.size.width) > 0)
				{	// erase right
					diffRect.origin.x = magRectView.origin.x+magRectView.size.width;
					[self displayRect: diffRect]; //NSIntegralRect()?
				}
				// remember the current rect
				oldRect = magRectView;
			}
			else
			{
				// mouse is not in the rect, show cursor and reset old rect
				if (!cursorVisible)
				{
					[NSCursor unhide];
					cursorVisible = YES;
				}
				[self displayRect: oldRect];
				oldRect.origin = mouseLocView;
				oldRect.size = NSMakeSize(0,0);
				[self autoscroll: theEvent]; // mitsu 1.29 (S3) added autoscroll
			}
		}
		else if ([theEvent type]==NSLeftMouseUp)
		{
			break;
		}
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
                NSLeftMouseDraggedMask | NSFlagsChangedMask];
	} while (YES);
	
	[NSCursor unhide];
	//[self unlockFocus];
	[self setPostsBoundsChangedNotifications: postNote];
	[self setNeedsDisplayInRect: oldRect];
}
// end addition
*/

// mitsu 1.29 (S2)
// derived from Apple's Sample code PDFView/DraggableScrollView.m
- (void)scrollByDragging: (NSEvent *)theEvent
{
	NSPoint 		initialLocation;
    NSRect			visibleRect;
    BOOL			keepGoing;

	initialLocation = [theEvent locationInWindow];
    visibleRect = [self visibleRect];
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

				if (rotationAmount == 0)
					newVisibleRect = NSOffsetRect (visibleRect, xDelta, yDelta);
				else if (rotationAmount == 90)
					newVisibleRect = NSOffsetRect (visibleRect, yDelta, -xDelta);
				else if (rotationAmount == 180)
					newVisibleRect = NSOffsetRect (visibleRect, -xDelta, -yDelta);
				else if (rotationAmount == -90)
					newVisibleRect = NSOffsetRect (visibleRect, -yDelta, xDelta);
                [self scrollRectToVisible: newVisibleRect];
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
	//[[NSCursor arrowCursor] set];
	[self flagsChanged: theEvent]; // update cursor
}



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

- (void)selectAll: (id)sender;
{
    if ((mouseMode == MOUSE_MODE_SELECT) && 
        ((pageStyle == PDF_SINGLE_PAGE_STYLE) || (pageStyle == PDF_TWO_PAGE_STYLE) || ([myRep pageCount] <= 20)))
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
        selectedRect.size.width = totalWidth;
        selectedRect.size.height = totalHeight;
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

// earses the frame of selected rectangle and cleans up the cached image
- (void)cleanupMarquee: (BOOL)terminate
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

// recache the image around selected rectangle for quicker response
- (void)recacheMarquee
{
	if (selRectTimer)
	{
		[[self window] cacheImageInRect: 
					NSInsetRect([self convertRect: selectedRect toView: nil], -2, -2)];
		oldVisibleRect = [self visibleRect];
	}
}

- (void)moveSelection: (NSEvent *)theEvent
{
    NSPoint startPointWindow, startPointView, mouseLocWindow, mouseLocView, mouseLocScreen;
	NSRect originalSelRect, selRectWindow, selRectSuper, screenFrame;
	float deltaX, deltaY, pattern[] = {3,3};
	NSBezierPath *path = [NSBezierPath bezierPath];
	static int phase = 0;
	
	if (!selRectTimer) return;
	startPointWindow = mouseLocWindow = [theEvent locationInWindow];
	startPointView = mouseLocView = [self convertPoint: startPointWindow fromView:nil];
	originalSelRect = selectedRect;
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
			selectedRect.origin.x = originalSelRect.origin.x + deltaX;
			selectedRect.origin.y = originalSelRect.origin.y + deltaY;
			// cache the window image
			selRectWindow = [self convertRect: selectedRect toView: nil];
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
}


- (BOOL)hasSelection
{
	return (selRectTimer != nil);
}


// get image data from the selected rectangle with specified type
- (NSData *)imageDataFromSelectionType: (int)type
{
	NSRect visRect, newRect, selRectWindow;
	NSData *data = nil;
	NSBitmapImageRep *bitmap = nil;
	NSImage *image = nil;
	NSBitmapImageFileType fileType;
	NSDictionary *dict;
	
	visRect = [self visibleRect];
	selRectWindow = [self convertRect: selectedRect toView: nil];
	
	//test
	NSSize aSize = [self convertSize: selectedRect.size toView: nil];
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
		if (NSContainsRect(visRect, selectedRect))
		{	// if the rect is contained in visible rect
			[self cleanupMarquee: NO];
			[self recacheMarquee];
			
			// Apple does not document the size of the imageRep one gets from 
			// "initWithFocusedViewRect:".  My experiments show that 
			// the size is, in most cases, floor(selRectWindow.size.width/height).
			// However if theMagSize is not 1.0 and selRectWindow.size.width/height 
			// is near integer, then the size can be off by one (larger or smaller).  
			// So for safety, one might need to use the modified size. 
			
			newRect = selectedRect;
			// get a bit map image from window for the rect in view coordinate
			[self lockFocus];
			bitmap = [[[NSBitmapImageRep alloc] initWithFocusedViewRect: 
											newRect] autorelease];
			[self unlockFocus];
		}
		else // there is some portion which is not visible
		{
			// new routine which creates image by directly calling drawRect
			image = [self imageFromRect: selectedRect];
				
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

		newRect.origin = selectedRect.origin;
		if (rotationAmount == 0)
			newRect.size = selRectWindow.size; 
		else if (rotationAmount == 180)// && theMagSize >= 1.0)//if theMagSize<1.0 image may be clipped?
		{
			newRect.size = selRectWindow.size; 
			//future origin is (_.origin.x+_.size.width, _.origin.y+_.size.height)
			newRect.origin.x += selectedRect.size.width;
			newRect.origin.y += selectedRect.size.height;
			//recalculate new origin given the future origin and size
			newRect.origin.x -= newRect.size.width;
			newRect.origin.y -= newRect.size.height;
		}
		else // probably one should use [NSPrintOperation PDFOperationWithView:insideRect:toData:]
			[NSException raise: @"cannot handle rotated view" format: @""];

		if (type == IMAGE_TYPE_PDF)
			data = [self dataWithPDFInsideRect: newRect];
		else // IMAGE_TYPE_EPS
			data = [self dataWithEPSInsideRect: newRect];
	}
	NS_HANDLER
		data = nil;
		//NSRunAlertPanel(@"Error", @"error occured in imageDataFromSelectionType:", nil, nil, nil);
	NS_ENDHANDLER
	return data;
}


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
				[self dragImage:image at:selectedRect.origin offset:dragOffset 
					event:theEvent pasteboard:pboard source:self slideBack:YES];
			}
		}
	}
	else // quick drag for PDF & EPS
	{
		image = [self imageFromRect: selectedRect];
		if (image)
		{
			//[self pasteboard:pboard provideDataForType:dataType];
			//[self pasteboard:pboard provideDataForType:NSFilenamesPboardType];
			[self dragImage:image at:selectedRect.origin offset:dragOffset 
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

#pragma mark =====others=====

// resizeWithOldSuperviewSize is called when superview is live resizing
// For this to happen, the view must set 
// [self setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable]; 
// at least not NSViewNotSizable
/*
- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
	//[self fitToSize]; // live resize according to the resize option--too slow!
}*/


// viewDidEndLiveResize is called at the end of live resizing
// we adjust here the size of our view
- (void)viewDidEndLiveResize
{
	if (centerPage || !(resizeOption == PDF_ACTUAL_SIZE || resizeOption == PDF_FIT_TO_NONE))
		[self fitToSize];
}


- (int)pageStyle
{
	return pageStyle;
}

// action for menu items "Single Page/Two Page/Multi-Page/Double Multi-Page"
// -- tags should be correctly set
- (void)changePageStyle: (id)sender
{
	if (!(imageType == isTeX || imageType == isPDF)) return;
	
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
		[self setupForPDFRep: myRep style: [sender tag]];
		// redisplay
		[[self enclosingScrollView] setNeedsDisplay: YES];

		// mitsu 1.29b check menu item Preview=>Display Format
		item = [menu itemWithTag: pageStyle];
		[item setState: NSOnState];
		// end mitsu 1.29b

		// clean up the timer for selected rectangle
		if (selRectTimer)
		{
			[selRectTimer invalidate]; // this will release the timer
			selRectTimer = nil;
			[[self window] discardCachedImage];
		}
	}
}

- (int)resizeOption
{
	return resizeOption;
}

// action for menu items "Actual Size/Fixed Magnification/Fit To ..."
// optionally you can add "Fit To Height". (is it useful?)
// tags of menu items should be correctly set.  
// also if you add items with positive tag, it is interpreted as 
// the magnification
- (void)changePDFViewSize: (id)sender
{
	if (![sender tag]) return;
	// mitsu 1.29b uncheck menu item Preview=>Magnification
	NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
				NSLocalizedString(@"Preview", @"Preview")] submenu];
	NSMenu *menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Magnification", @"Magnification")] submenu];
	NSMenuItem *item =[menu itemWithTag: resizeOption];
	if (item) [item setState: NSOffState];
	// end mitsu 1.29b
	
	resizeOption = [sender tag];
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
	
	// mitsu 1.29b check menu item Preview=>Magnification
	item =[menu itemWithTag: resizeOption];
	if (item) [item setState: NSOnState];
	// end mitsu 1.29b
}

@end


@implementation FlippedClipView
// the only fuction is to say YES on isFlipped.
- (BOOL)isFlipped
{
	return YES;
}
@end

#pragma mark =====color mapping=====
// structs for pixel data which are to be used in transformColor()
typedef struct rgbPixel
{ 
	unsigned char red; 
	unsigned char green; 
	unsigned char blue; 
} rgbPixel;

typedef struct rgbaPixel
{ 
	unsigned char red; 
	unsigned char green; 
	unsigned char blue; 
	unsigned char alpha; 
} rgbaPixel;


// a routine which transforms colors of a bitmap according to given 
// foreColor (for black part) and backColor (for white part).  
NSBitmapImageRep *transformColor(NSBitmapImageRep *srcBitmap, NSColor *foreColor, NSColor *backColor, int param1)
// see Apple Sample code "Monochrome Image"
{
	NSBitmapImageRep *newBitmap;
	int 	row, column, widthInPixels, heightInPixels, srcBytesPerRow, srcSamplesPerPixel, 
			destBytesPerRow, destSamplesPerPixel;
	float 	foreR, foreG, foreB, foreA, backR, backG, backB, backA, level, t;
	BOOL 	destHasAlpha;
	void 	*srcPixels, *newPixels;
	
	if (!srcBitmap || !([srcBitmap bitsPerSample]==8 && [srcBitmap isPlanar]==NO
						&& [srcBitmap samplesPerPixel]>=3))
		return nil;
	
	NSColor *newForeColor = [foreColor colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
    foreR = [newForeColor redComponent];  foreG = [newForeColor greenComponent]; 
	foreB = [newForeColor blueComponent]; foreA = [newForeColor alphaComponent];
	NSColor *newBackColor = [backColor colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	backR = [newBackColor redComponent];  backG = [newBackColor greenComponent]; 
	backB = [newBackColor blueComponent]; backA = [newBackColor alphaComponent];
	destHasAlpha = !(foreA == 1.0 && backA == 1.0);
	
	widthInPixels  = [srcBitmap size].width;
	heightInPixels = [srcBitmap size].height;
	destSamplesPerPixel = (destHasAlpha)?4:3;
	
	newBitmap = [[NSBitmapImageRep alloc] 
			initWithBitmapDataPlanes: nil // allocate the pixel buffer for us
			pixelsWide: widthInPixels  pixelsHigh: heightInPixels 
			bitsPerSample: 8 samplesPerPixel: destSamplesPerPixel 
			hasAlpha: destHasAlpha  isPlanar: NO 
			colorSpaceName: NSCalibratedRGBColorSpace 
			bytesPerRow: 0     // passing zero means "you figure it out."
			bitsPerPixel: (8 * destSamplesPerPixel)];  // = bitsPerSample * samplesPerPixel
	if (!newBitmap) return nil;
	
	// setup address etc
	srcPixels = [srcBitmap bitmapData]; 
	srcSamplesPerPixel = [srcBitmap samplesPerPixel]; // 3 (no alpha) or 4 (has alpha)
	srcBytesPerRow = [srcBitmap bytesPerRow];
	newPixels = [newBitmap bitmapData];
	destBytesPerRow = [newBitmap bytesPerRow];
	
	// work on each pixel
	for (row = 0; row < heightInPixels; row++)
	{
		for (column = 0; column < widthInPixels; column++)
		{
			// address for source and destination pixels
			rgbPixel *srcpix  = (rgbPixel *)
						(srcPixels + srcBytesPerRow * row + srcSamplesPerPixel * column);
			rgbPixel *destpix = (rgbPixel *)
						(newPixels + destBytesPerRow * row + destSamplesPerPixel * column);
			// source level: level=0 black, level=1 white
			level = ((float)srcpix->red + (float)srcpix->green + (float)srcpix->blue)/765;
			// modify the level
			switch (param1) // just testing various functions
			{
				case 0:
					t = level;
					break;
				case 1:
					t = pow(level, 1.5);				
					break;
				// one could use cubic x + c*x*(1-x)*(1-2*x) with c = -0.5, -1.0?
				case 2:
					t = level*level;
					break;
				case 3:
					t = level*level*level;
					break;
				case 4:
					t = level*level;
					t = t*t;
					break;
				case 5:
					t = level*level;
					t = t*t*level;
					break;
				case -1:
					t = pow(level, 0.8);
					break;
				case -2:
					t = pow(level, 0.5);
					break;
				default:
					t = level;
			}
			// now set colors for destination pixels by interpolating foreColor and backColor
			destpix->red 	= rint( 255*((1-t)*foreR + t*backR) );
			destpix->green 	= rint( 255*((1-t)*foreG + t*backG) );
			destpix->blue 	= rint( 255*((1-t)*foreB + t*backB) );
			if (destHasAlpha) // use original level for better result
				((rgbaPixel *)destpix)->alpha = rint( 255*((1-t)*foreA + t*backA) );
		}
	}

	return [newBitmap autorelease];
}

#pragma mark =====getPICTDataFromBitmap=====
//#include <Carbon/Carbon.h>

typedef struct qdPixel
{ 
	unsigned char unused; 
	unsigned char red; 
	unsigned char green; 
	unsigned char blue; 
} qdPixel;

// Create PICT data from NSBitmapImageRep using Carbon routines
// I don't know if this is a correct way to do it, but it works.  
// The result can be read into NSPICTImageRep by imageRepWithData, 
// or directly put into pasteboard.  Note that in order to save the 
// data in a PICT file, we have to put 512 bytes of zeros before this data.  
NSData *getPICTDataFromBitmap(NSBitmapImageRep *bitmap)
{
	GWorldPtr		gworld;
	Rect			gwRect;
	OpenCPicParams	picParam;
	PicHandle		picture;
	PixMapHandle 	pixmap;
	int 	widthInPixels, heightInPixels, srcBytesPerRow, srcSamplesPerPixel, 
			destRowbytes, destSamplesPerPixel, row, column;
	void 	*srcPixels, *destBaseAddr;
	NSData *data = nil;

	if (!bitmap || !([bitmap bitsPerSample]==8 && 
			[bitmap isPlanar]==NO && [bitmap samplesPerPixel]>=3))
		return nil;
	// first create GWorld
	gwRect.left = gwRect.top = 0;
	gwRect.right = widthInPixels  = [bitmap size].width;
	gwRect.bottom = heightInPixels = [bitmap size].height;
	// NSQuickDrawView will be used as the target of CopyBits while recoding the picture
	NSQuickDrawView *qdView = [[NSQuickDrawView alloc] initWithFrame: 
						NSMakeRect(0, 0, widthInPixels, heightInPixels)];
	if (!qdView )
		return nil;
	// we use GWorld to create picture, as the source of CopyBits
	if (NewGWorld( &gworld, 32, &gwRect, nil, nil, 0L) == noErr)
	{
		srcPixels = [bitmap bitmapData]; 
		srcSamplesPerPixel = [bitmap samplesPerPixel]; 
		srcBytesPerRow = [bitmap bytesPerRow];
		pixmap = GetGWorldPixMap(gworld);
		LockPortBits( gworld ); //LockPixels( pixmap );
		destBaseAddr = GetPixBaseAddr( pixmap );
		destRowbytes = GetPixRowBytes( pixmap ); //((**pixmap).rowBytes & 0x3FFF);
		destSamplesPerPixel = GetPixDepth( pixmap )/8; //(**pixmap).pixelSize/8; // = 4
		// access pixels to reproduce the image in GWorld
		for (row = 0; row < heightInPixels; row++)
		{
			for (column = 0; column < widthInPixels; column++)
			{
				rgbPixel *srcpix  = (rgbPixel *)
							(srcPixels + srcBytesPerRow * row + srcSamplesPerPixel * column);
				qdPixel *destpix = (qdPixel *)
							(destBaseAddr + destRowbytes * row + destSamplesPerPixel * column);
				destpix->unused = 0x00;
				destpix->red 	= srcpix->red;
				destpix->green 	= srcpix->green;
				destpix->blue 	= srcpix->blue;
			}
		}
		// set up a picture and start recording
		picParam.srcRect = gwRect;
		picParam.hRes = 0x00480000;	// for 72dpi
		picParam.vRes = 0x00480000;	// for 72dpi
		picParam.version = -2;
		picParam.reserved1 = 0;
		picParam.reserved2 = 0;
		picture = OpenCPicture( &picParam ); 
		if ( picture )
		{
			// call good'n old CopyBits to record the image
			(**picture).picFrame = gwRect;
			CopyBits( GetPortBitMapForCopyBits(gworld), 
						GetPortBitMapForCopyBits([qdView qdPort]), 
						&gwRect, &gwRect, srcCopy, nil );
			ClosePicture();	// end recording
			// copy the data from picture(Handle) to NSData
			HLock( (Handle)picture );
			data = [NSData dataWithBytes: *picture length: GetHandleSize((Handle)picture) ];
			HUnlock( (Handle)picture );
			KillPicture( picture );
		}
		UnlockPortBits( gworld ); // UnlockPixels( pixmap );
		DisposeGWorld( gworld );
	}
	[qdView release];
	return data;
}


#pragma mark =====extensions=====
// mitsu 1.29 drag & drop
NSString *extensionForType(int type)
{
	switch (type)
	{
		case IMAGE_TYPE_TIFF_NC:
		case IMAGE_TYPE_TIFF_LZW:
		case IMAGE_TYPE_TIFF_PB:
			return @"tiff";
		case IMAGE_TYPE_JPEG_HIGH:
		case IMAGE_TYPE_JPEG_MEDIUM:
		case IMAGE_TYPE_JPEG_LOW:
			return @"jpeg";
		case IMAGE_TYPE_PICT:
			return @"pict";
		case IMAGE_TYPE_PNG:
			return @"png";
		case IMAGE_TYPE_GIF:
			return @"gif";
		case IMAGE_TYPE_BMP:
			return @"bmp";
		case IMAGE_TYPE_PDF:
			return @"pdf";
		case IMAGE_TYPE_EPS:
			return @"eps";
		default: //IMAGE_TYPE_TIFF_NC
			return @"tiff";
	}
}
// end mitsu 1.29

#pragma mark =====cursors=====
// create and hold cursors
NSCursor *openHandCursor()
{
    static NSCursor	*openHandCursor = nil;
    if (openHandCursor == nil)
    {
        NSImage	*image = [NSImage imageNamed: @"OpenHandCursor"];
		if (image)
			openHandCursor = [[NSCursor alloc] initWithImage: image
				hotSpot: NSMakePoint (8, 8)];
    }
    return openHandCursor;
}

NSCursor *grabHandCursor()
{
    static NSCursor	*grabHandCursor = nil;
    if (grabHandCursor == nil)
    {
        NSImage	*image = [NSImage imageNamed: @"GrabHandCursor"]; 
		if (image)
			grabHandCursor = [[NSCursor alloc] initWithImage: image
				hotSpot: NSMakePoint (8, 8)]; 
    }
    return grabHandCursor;
}


