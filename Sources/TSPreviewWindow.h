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
 * $Id: TSPreviewWindow.h 260 2007-08-08 22:51:09Z richard_koch $
 *
 * Originally part of TSDocument. Broken out by dirk on Tue Jan 09 2001.
 *
 */

#import "UseMitsu.h"

#import <AppKit/NSWindow.h>
#import <Quartz/Quartz.h>


@class TSDocument;

@interface TSPreviewWindow : NSWindow
{
//	TSDocument	*myDocument;
//	BOOL		windowIsSplit;
//	BOOL		firstClose;
//	PDFView		*activeView;
//	PDFView		*myPDFKitView;
//	PDFView		*myPDFKitView2;
//	NSSplitView	*pdfKitSplitView;
//	BOOL		willClose;
}

@property               BOOL            willClose;
@property               BOOL            windowIsSplit;
@property               BOOL            firstClose;
@property (retain)      PDFView         *activeView;
@property (retain)      PDFView         *myPDFKitView;
@property (retain)      PDFView         *myPDFKitView2;
@property (retain)      NSSplitView    *pdfKitSplitView;
@property (retain)      TSDocument      *myDocument;

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)defaultFrame;

- (void) close;
- (void) doTextMagnify: sender;   // for toolbar in text mode
- (void) doTextPage: sender;      // for toolbar in text mode
- (void) magnificationDidEnd:(NSWindow *)sheet returnCode: (NSInteger)returnCode contextInfo: (void *)contextInfo;
- (void) pagenumberDidEnd:(NSWindow *)sheet returnCode: (NSInteger)returnCode contextInfo: (void *)contextInfo;
- (void) previousPage: sender;
- (void) nextPage: sender;
- (void) zoomIn: sender;
- (void) zoomOut: sender;

- (void) displayLog: sender;
- (void) displayConsole: sender;
- (void) trashAUXFiles: sender;
- (void) abort: sender;

- (void) firstPage: sender;
- (void) lastPage: sender;
- (void) up: sender;
- (void) down: sender;
- (void) top: sender;
- (void) bottom: sender;
- (void) left: sender; // mitsu 1.29 (O)
- (void) right: sender; // mitsu 1.29 (O)


- (void) doError: sender;
- (void) doChooseMethod: sender;
- (void) rotateClockwise: sender;
- (void) rotateCounterclockwise: sender;
- (void) savePreviewPosition: sender;
- (void) savePortablePreviewPosition: sender;
- (void) orderOut: sender;
- (void) sendEvent:(NSEvent *)theEvent;
- (void) associatedWindow: sender;
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
- (TSDocument *)document;
#ifdef MITSU_PDF
- (void)changePageStyle: (id)sender; // mitsu 1.29 (O)
- (void)changePDFViewSize: (id)sender; // mitsu 1.29 (O)
- (void)saveSelectionToFile: (id)sender; // mitsu 1.29 (O)
#endif
// - (void)pagenumberDidEnd:(NSWindow *)sheet returnCode: (NSInteger)returnCode contextInfo: (void *)contextInfo;
// - (void)magnificationDidEnd:(NSWindow *)sheet returnCode: (NSInteger)returnCode contextInfo: (void *)contextInfo;
//- (void)configurePaperSize: sender;
- (void) splitPdfKitWindow: (id)sender; 
- (void) splitWindow: (id)sender; // so menu item can split both source and preview window
- (void)fixAfterRotation: (BOOL) clockwise;
// - (BOOL) validateMenuItem:(NSMenuItem *)anItem;
- (void) setActiveView:(PDFView *)theView;
- (void) changeMouseMode: sender;
- (void) doStepper: sender;
- (void) changeScale: sender;
- (void) goToKitPage: sender;
// - (void) doFind: sender;
- (IBAction) takeDestinationFromOutline: (id) sender;
- (IBAction) convertTiff:(id)sender;

- (PDFView *)activeView;
- (BOOL)windowIsSplit;

@end
