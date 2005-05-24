/* PDFKitViewer - MyPDFDocument.h
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
//#import "MyPDFView.h"


//#define kViewPDFMode			0
//#define kEditPDFMode			1


//@class MyDocument;


@interface MyPDFDocument : NSObject
{
	NSWindow			*myPDFWindow;
	PDFView				*_pdfView;
	//PDFOutline						*_outline;
	//NSMutableArray					*_searchResults;
	//int								_mode;
	//IBOutlet NSWindow				*_myWindow;
	//IBOutlet MyPDFView				*_pdfView;
	//IBOutlet NSDrawer				*_drawer;
	//IBOutlet NSOutlineView			*_outlineView;
	//IBOutlet NSTextField			*_noOutlineText;
	//IBOutlet NSTableView			*_searchTable;
	//IBOutlet NSProgressIndicator	*_searchProgress;
	//IBOutlet NSSegmentedControl		*_modeControl;
	//IBOutlet NSButton				*_newLinkButton;
	//IBOutlet NSButton				*_infoButton;
	//IBOutlet NSPanel				*_linkPanel;			// Link Panel
	//IBOutlet NSMatrix				*_linkMatrix;
	//IBOutlet NSTabView				*_linkTab;
	//IBOutlet NSTextField			*_linkPageField;
	//IBOutlet NSTextField			*_linkPageRange;
	//IBOutlet NSTextField			*_linkURLField;
}

//- (IBAction) toggleDrawer: (id) sender;
//- (void) takeDestinationFromOutline: (id) sender;
//- (IBAction) displaySinglePage: (id) sender;
//- (IBAction) displayTwoUp: (id) sender;
//- (void) doFind: (id) sender;

//- (int) mode;
//- (void) modeSwitch: (id) sender;
//- (void) setViewMode: (id) sender;
//- (void) setEditMode: (id) sender;
//- (void) newLink: (id) sender;
//- (void) getInfo: (id) sender;

//- (void) linkTypeChanged: (id) sender;
//- (void) setupPageLinkFields: (PDFDestination *) destination;
//- (void) setupURLLinkFields: (NSURL *) url;
//- (void) linkPageChanged: (id) sender;
//- (void) linkURLChanged: (id) sender;
//- (void) infoDone: (id) sender;

// Notifications.

//- (void) pageChanged: (NSNotification *) notification;
//- (void) startFind: (NSNotification *) notification;
//- (void) findProgress: (NSNotification *) notification;
//- (void) endFind: (NSNotification *) notification;

@end
