//
//  TSWindowManager.m
//  TeXShop
//
//  Created by dirk on Sat Feb 17 2001.
//

#import "UseMitsu.h"

#import "TSWindowManager.h"
#import "globals.h"
#import "extras.h"
// added by mitsu --(J+) Check mark in "Typeset" menu
#import "MyDocument.h"
// end addition
#ifdef MITSU_PDF
#import "MyPDFView.h"
#endif

@implementation TSWindowManager
/*"

"*/

static id _sharedInstance = nil;

/*" This class is implemented as singleton, i.e. there is only one single instance in the runtime. This is the designated accessor method to get the shared instance of the Preferences class.
"*/
//------------------------------------------------------------------------------
+ (id)sharedInstance
//------------------------------------------------------------------------------
{
	if (_sharedInstance == nil)
	{\
		_sharedInstance = [[TSWindowManager alloc] init];
	}
	return _sharedInstance;
}

//------------------------------------------------------------------------------
- (id)init 
//------------------------------------------------------------------------------
{
    if (_sharedInstance != nil) 
	{
        [super dealloc];
        return _sharedInstance;
    }
	_sharedInstance = self;
	return self;
}

//------------------------------------------------------------------------------
- (void)dealloc
//------------------------------------------------------------------------------
{
	[super dealloc];
}

/*" This method is registered with the NotificationCenter and will be sent whenever a document window becomes key. We register this document window here so when TSPreferences needs this information when setting the window position it will be available.
"*/
//-----------------------------------------------------------------------------
- (void)documentWindowDidBecomeKey:(NSNotification *)note
//-----------------------------------------------------------------------------
{    
    // do not retain the window here!
    _activeDocumentWindow = [note object];
    
    // added by mitsu --(J+) check mark in "Typeset" menu
    [self checkProgramMenuItem: [[[note object] document] whichEngine] checked: YES];
// end addition

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
        
    The fix is to add the following new call, used only by the close method of MyDocument.
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
- (void)closeActiveDocument
{
    _activeDocumentWindow = nil;
}

/*" This method is registered with the NotificationCenter and will be called when a document window will be closed. 
"*/
//-----------------------------------------------------------------------------
- (void)documentWindowWillClose:(NSNotification *)note
//-----------------------------------------------------------------------------
{
    _activeDocumentWindow = nil;
}

/*" Returns the active document window or nil if no document window is active.
"*/
//-----------------------------------------------------------------------------
- (NSWindow *)activeDocumentWindow
//-----------------------------------------------------------------------------
{
    return _activeDocumentWindow;
}

/*" This method is registered with the NotificationCenter and will be sent whenever a pdf window becomes key. We register this pdf window here so when TSPreferences needs this information when setting the window position it will be available.
"*/
//-----------------------------------------------------------------------------
- (void)pdfWindowDidBecomeKey:(NSNotification *)note
//-----------------------------------------------------------------------------
{    
    // do not retain the window here!
    _activePdfWindow = [note object];
    
// added by mitsu --(J+) check mark in "Typeset" menu
    if ([[[note object] document] imageType] == isTeX)
		[self checkProgramMenuItem: [[[note object] document] whichEngine] checked: YES];
// end addition

#ifdef MITSU_PDF
	// mitsu 1.29b check menu item Preview=>Display Format/Magnification
	MyDocument *doc = [[note object] document];
    if ([doc imageType] == isTeX || [doc imageType] == isPDF)
	{
		NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
				NSLocalizedString(@"Preview", @"Preview")] submenu];
		NSMenu *menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Display Format", @"Display Format")] submenu];
		NSMenuItem *item = [menu itemWithTag:[[doc pdfView] pageStyle]];
		[item setState: NSOnState];
		menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Magnification", @"Magnification")] submenu];
		item = [menu itemWithTag:[[doc pdfView] resizeOption]];
		[item setState: NSOnState];
	}
	//[[doc pdfView] recacheMarquee]; // cache it for quick drawing
	// end mitsu 1.29b
#endif
}

/*" This method is registered with the NotificationCenter and will be called when a document window will be closed. 
"*/
//-----------------------------------------------------------------------------
- (void)pdfWindowWillClose:(NSNotification *)note
//-----------------------------------------------------------------------------
{
    _activePdfWindow = nil;

}

//-----------------------------------------------------------------------------
- (NSWindow *)activePdfWindow
//-----------------------------------------------------------------------------
{
    return _activePdfWindow;
}

// added by mitsu --(J+) check mark in "Typeset" menu
//-----------------------------------------------------------------------------
- (void)documentWindowDidResignKey:(NSNotification *)note
//-----------------------------------------------------------------------------
{    
    [self checkProgramMenuItem: [[[note object] document] whichEngine] checked: NO];
}

//-----------------------------------------------------------------------------
- (void)pdfWindowDidResignKey:(NSNotification *)note
//-----------------------------------------------------------------------------
{    
    if ([[[note object] document] imageType] == isTeX)
		[self checkProgramMenuItem: [[[note object] document] whichEngine] checked: NO];
                
#ifdef MITSU_PDF
	// mitsu 1.29b (O) uncheck menu item Preview=>Display Format/Magnification
	MyDocument *doc = [[note object] document];
    if ([doc imageType] == isTeX || [doc imageType] == isPDF)
	{
		NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
				NSLocalizedString(@"Preview", @"Preview")] submenu];
		NSMenu *menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Display Format", @"Display Format")] submenu];
		NSMenuItem *item = [menu itemWithTag:[[doc pdfView] pageStyle]];
		[item setState: NSOffState];
		menu = [[previewMenu itemWithTitle:
				NSLocalizedString(@"Magnification", @"Magnification")] submenu];
		item = [menu itemWithTag:[[doc pdfView] resizeOption]];
		[item setState: NSOffState];
	}
	//[[doc pdfView] cleanupMarquee: NO]; // erase marquee?
	// end mitsu 1.29b
#endif
}


//-----------------------------------------------------------------------------
- (void)checkProgramMenuItem: (int)programID checked: (BOOL)flag
//-----------------------------------------------------------------------------
{    
    [[[[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Typeset", @"Typeset")] submenu] 
        itemWithTag:programID] setState: (flag)?NSOnState:NSOffState];
}

// end addition



@end
