//
//  TSWindowManager.m
//  TeXShop
//
//  Created by dirk on Sat Feb 17 2001.
//

#import "TSWindowManager.h"
#import "globals.h"
#import "extras.h"
// added by mitsu --(J+) Check mark in "Typeset" menu
#import "MyDocument.h"
// end addition

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
