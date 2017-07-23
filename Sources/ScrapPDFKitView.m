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

#import "ScrapPDFKitView.h"
#import "globals.h"
#import "TSDocument.h"
#import "TSEncodingSupport.h"




@implementation ScrapPDFKitView : PDFView



- (void) showWithPath: (NSString *)imagePath
{
	PDFDocument	*pdfDoc;
    
    NSDisableScreenUpdates();
	
    pdfDoc = [[PDFDocument alloc] initWithURL: [NSURL fileURLWithPath: imagePath]];
    [self setDocument: pdfDoc];

/*
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
*/
}


- (void) reShowWithPath: (NSString *)imagePath
{
	PDFDocument     *pdfDoc;
	BOOL            needsInitialization;
    NSRect          tempRect;
    NSRect          visibleRectA, fullRectA;
    
	// A note below explains dangers of NSDisableScreenUpdates
    // but these dangers don't apply to Intel on recent systems.
    // Experiments show that in single page mode, "disableFlushWindow"
    // adds a flash showing the initial page before switching to the
    // current page. NSDisableScreenUpdates fixes that.
    
    visibleRectA = [[self documentView] visibleRect];
	fullRectA = [[self documentView] bounds];

    
	// [[self window] disableFlushWindow];
    NSDisableScreenUpdates();
    
    
	if ([self document] == nil)
		needsInitialization = YES;
	else
		needsInitialization = NO;
    
    if (needsInitialization) {
        [self setAutoScales: YES];
       // [self setScaleFactor:3];
        }
    else {
        tempRect = [[self documentView] visibleRect];
        // tempRect.origin.y = tempRect.origin.y + tempRect.size.height;
        // tempRect.size.height = 1;
        // tempRect.size.width = 1;
        self.scrapVisibleRect = tempRect;
        self.scrapFullRect = [[self documentView] bounds];
        }

    
    pdfDoc = [[PDFDocument alloc] initWithURL: [NSURL fileURLWithPath: imagePath]];
    [self setDocument: pdfDoc];
    
    if (needsInitialization) {
        /*
        for (i = 1; i <= 10; i++)
            [self zoomIn:self];
        */
        /*
        myPage = [[self document] pageAtIndex:0];
        mySelection = [[self document] selectionFromPage:myPage atCharacterIndex: 2 toPage:myPage atCharacterIndex: 3];
        [self setCurrentSelection: mySelection];
        [self scrollSelectionToVisible: self];
         */
        }
    else
        /*
        {
        NSRect newFullRect = [[self documentView] bounds];
        NSInteger difference = newFullRect.size.height - self.scrapFullRect.size.height;
        original =  self.scrapVisibleRect.origin.y;
        [[self documentView] scrollRectToVisible: visibleRect];
            
        newVisibleRect = [[self documentView] visibleRect];
        new = newVisibleRect.origin.y;
        difference = original - new;
        newVisibleRect.origin.y = newVisibleRect.origin.y + difference;
        [[self documentView] scrollRectToVisible: newVisibleRect];
        }
        */
    {
        NSRect newFullRectA = [[self documentView] bounds];
        NSInteger differenceA = newFullRectA.size.height - fullRectA.size.height;
        
        visibleRectA.origin.y = visibleRectA.origin.y + differenceA - 5;
        [[self documentView] scrollRectToVisible: visibleRectA];
  
        
    }
    
    
	[[self document] setDelegate: self];
     NSEnableScreenUpdates();
	[self display]; //this is needed outside disableFlushWindow when the user does not bring the window forward
    
}


@end
