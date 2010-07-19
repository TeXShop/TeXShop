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
 * $Id$
 *
 * Created by dirk on Sat Feb 17 2001.
 *
 */

#import "UseMitsu.h"

#import "TSWindowManager.h"
#import "globals.h"

#import "TSDocument.h"
#import "MyPDFView.h"

@implementation TSWindowManager
/*"

"*/

static id _sharedInstance = nil;

/*" This class is implemented as singleton, i.e. there is only one single instance in the runtime. This is the designated accessor method to get the shared instance of the Preferences class.
"*/
+ (id)sharedInstance
{
	if (_sharedInstance == nil)
		_sharedInstance = [[TSWindowManager alloc] init];
	return _sharedInstance;
}

- (id)init
{
	if (_sharedInstance != nil)
	{
		[super dealloc];
		return _sharedInstance;
	}
	_sharedInstance = self;
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

/*" This method is registered with the NotificationCenter and will be sent whenever a
    document window becomes key. We register this document window here so when TSPreferences
	needs this information when setting the window position it will be available.
"*/
- (void)textWindowDidBecomeKey:(NSNotification *)note
{
	// do not retain the window here!
	_activeTextWindow = [note object];

	// Update check mark in "Typeset" menu
	[self checkProgramMenuItem: [[[note object] document] whichEngine] checked: YES];
}

/* This method was added on November 9, 2003, to fix the following bug: in Jaguar (but not Panther)
	when the application does not open empty windows upon activation,  suppose we make the
	preview window be the active window, and then reach over and close the document window.
	If no other windows are active, then clicking on the menu bar causes a crash.

	Investigation shows that in Panther, the various notifications below are sent in the following
	order:

		pdf close
		document active
		document close

	but in 10.2.8 they are sent in the following order

		document close
		pdf close
		document active

	The fix is to add the following new call, used only by the close method of TSDocument.
	Experiments show that this call and the various notifications are made in the following order
	in Panther

		pdf close
		document active
		new call
		document close

	and in 10.2.8

		document close
		pdf close
		document active
		new call

	If a second document is available and becomes active, then in either case it's
	document active notification is received after all of the above calls.

*/
- (void)notifyActiveTextWindowClosed
{
	_activeTextWindow = nil;
}

/*" This method is registered with the NotificationCenter and will be called when a document window will be closed.
"*/
- (void)documentWindowWillClose:(NSNotification *)note
{
	_activeTextWindow = nil;
}

/*" Returns the active document window or nil if no document window is active.
"*/
- (NSWindow *)activeTextWindow
{
	return _activeTextWindow;
}

- (void)setPdfWindowWithDocument:(TSDocument *) doc isActive:(BOOL)flag
{
	// Update check mark in "Typeset" menu
	if ([doc documentType] == isTeX)
		[self checkProgramMenuItem: [doc whichEngine] checked: flag];

	// Update menu item Preview=>Display Format/Magnification
	if ([doc documentType] == isTeX || [doc documentType] == isPDF)
	{
		NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
				NSLocalizedString(@"Preview", @"Preview")] submenu];
		NSMenu *menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Display Format", @"Display Format")] submenu];
		id <NSMenuItem> item = [menu itemWithTag:[[doc pdfView] pageStyle]];
		[item setState: flag ? NSOnState : NSOffState];
		menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Magnification", @"Magnification")] submenu];
		item = [menu itemWithTag:[[doc pdfView] resizeOption]];
		[item setState: flag ? NSOnState : NSOffState];
	}
}


/*" This method is registered with the NotificationCenter and will be sent whenever a pdf window becomes key. We register this pdf window here so when TSPreferences needs this information when setting the window position it will be available.
"*/
- (void)pdfWindowDidBecomeKey:(NSNotification *)note
{
	// do not retain the window here!
	_activePDFWindow = [note object];

	[self setPdfWindowWithDocument:[[note object] document] isActive:YES];
}

/*" This method is registered with the NotificationCenter and will be called when a document window will be closed.
"*/
- (void)pdfWindowWillClose:(NSNotification *)note
{
	_activePDFWindow = nil;

}

- (NSWindow *)activePDFWindow
{
	return _activePDFWindow;
}

- (void)documentWindowDidResignKey:(NSNotification *)note
{
	[self checkProgramMenuItem: [[[note object] document] whichEngine] checked: NO];
}

- (void)pdfWindowDidResignKey:(NSNotification *)note
{
	[self setPdfWindowWithDocument:[[note object] document] isActive:NO];
}


- (void)checkProgramMenuItem: (int)programID checked: (BOOL)flag
{
	[[[[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Typeset", @"Typeset")] submenu]
		itemWithTag:programID] setState: (flag)?NSOnState:NSOffState];
}


@end
