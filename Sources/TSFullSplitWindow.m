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
 * $Id: TSTextEditorWindow.m 260 2007-08-08 22:51:09Z richard_koch $
 *
 * Originally part of TSDocument. Broken out by dirk on Tue Jan 09 2001.
 *
 */

#import <AppKit/AppKit.h>
#import "TSFullSplitWindow.h"
#import "TSDocument.h" // for the definition of isTeX (move this to a separate file!!)
#import "globals.h"
#import "TSDocumentController.h"



@implementation TSFullSplitWindow : NSWindow

- (void)displayConsole: (id)sender
{
    [self.myDocument displayConsole: sender];
}

- (void)displayLog: (id)sender
{
    [self.myDocument displayLog:sender];
}

- (void)doMove: (id)sender
{
    [self.myDocument doMove: sender];
}

- (void)doSeparateWindows: (id)sender
{
    [self.myDocument doSeparateWindows: sender];
}

- (void)doTemplate: (id)sender
{
    [self.myDocument doTemplate: sender];
}

- (void)doTag: (id)sender;
{
    [self.myDocument doTag: sender];
}

- (void)newTag: (id)sender
{
    [self.myDocument newTag: sender];
}

- (void) doChooseMethod: sender
{
	[self.myDocument doChooseMethod: sender];
}

- (void) abort: sender
{
	[self.myDocument abort: sender];
}

- (void) trashAUXFiles: sender
{
	[self.myDocument trashAUXFiles: sender];
}


- (void) doTypeset: sender
{
	[self.myDocument doTypeset: sender];
}

- (void) doTex: sender
{
	[self.myDocument doTex: sender];
}

- (void) doLatex: sender
{
	[self.myDocument doLatex: sender];
}

- (void) doBibtex: sender
{
	[self.myDocument doBibtex: sender];
}

- (void) doIndex: sender
{
	[self.myDocument doIndex: sender];
}

- (void) doMetapost: sender
{
	[self.myDocument doMetapost: sender];
}

- (void) doContext: sender
{
	[self.myDocument doContext: sender];
}

- (void) closeCurrentEnvironment: sender
{
	[self.myDocument closeCurrentEnvironment: sender];
}

- (void) changeAutoComplete: sender
{
	[self.myDocument changeAutoComplete: sender];
}

- (void) showHideLineNumbers: sender
{
	[self.myDocument showHideLineNumbers: sender];
}

- (void) showHideInvisibleCharacters:(id)sender
{
	[self.myDocument showHideInvisibleCharacters: sender];
}

- (void) saveSourcePosition: sender
{
	[self.myDocument saveSourcePosition];
}

- (void) savePortableSourcePosition:(id)sender
{
	[self.myDocument savePortableSourcePosition];
}

- (void)doCommentOrIndent: (id)sender
{
    [self.myDocument doCommentOrIndent: sender];
}

- (void)setLineBreakMode: (id)sender
{
    [self.myDocument setLineBreakMode: sender];
}

- (void)hardWrapSelection: (id)sender
{
    [self.myDocument hardWrapSelection: sender];
}

- (void)removeNewLinesFromSelection: (id)sender
{
    [self.myDocument removeNewLinesFromSelection: sender];
}

- (void)doNextBullet: (id)sender
{
    [self.myDocument doNextBullet: sender];
}

- (void)doNextBulletAndDelete: (id)sender
{
    [self.myDocument doNextBulletAndDelete: sender];
}

- (void)doPreviousBullet: (id)sender
{
    [self.myDocument doPreviousBullet: sender];
}

- (void)doPreviousBulletAndDelete: (id)sender
{
    [self.myDocument doPreviousBulletAndDelete: sender];
}

- (void)placeBullet: (id)sender
{
    [self.myDocument placeBullet: sender];
}

- (void)placeComment: (id)sender
{
    [self.myDocument placeComment: sender];
}

- (void)registerForCommandCompletion: (id)sender
{
     [[self.myDocument textView] registerForCommandCompletion: sender];
}


- (void)tryScrap: (id)sender
{
    [self.myDocument tryScrap: sender];
}

- (void)doLine: (id)sender
{
    [self.myDocument doLine: sender];
}

- (void)doError: (id)sender
{
    [self.myDocument doError: sender];
}

- (void)showStatistics: (id)sender
{
    [self.myDocument showStatistics: sender];
}


- (void)runPageLayout: (id)sender
{
    return;
}

- (void)printDocument: (id)sender
{
    [self.myDocument printDocument: sender];
}

- (void)printSource: (id)sender
{
    [self.myDocument printSource: sender];
}

- (void)convertTiff: (id)sender
{
    [self.myDocument convertTiff: sender];
}

- (void)splitWindow: (id)sender
 {
     [self.myDocument splitWindow: sender];
 }

- (void)close
{
    self.wasClosed = YES;
    [[self.myDocument textWindow] close];
    // MAYBE NOW IRRELEVANT?
    
    // Yusuke Terada addition to fix crash at close
    if(([[[TSDocumentController sharedDocumentController] documents] count] > 0) && self.myDocument && [self.myDocument respondsToSelector:@selector(pdfView)] && [self.myDocument pdfView])
        [[NSNotificationCenter defaultCenter] removeObserver:[self.myDocument pdfView]];
    // end of patch
    // this fixes a bug; the application crashed when closing
 	// the last window in multi-page mode; investigation shows that the
	// myPDFView "wasScrolled" method was called from the notification center before dealloc, but after other items in the window
	// were released
	NSArray *myDocuments = [[NSDocumentController sharedDocumentController] documents];
	if (myDocuments != nil) {
		NSEnumerator *enumerator = [myDocuments objectEnumerator];
		id anObject;
		while ((anObject = [enumerator nextObject])) {
			if ([anObject getCallingWindow] == self)
				[anObject setCallingWindow: nil];
		}
	}
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // added by Terada
    
    /*
     TSDocument *aDocument = self.myDocument;
     self.myDocument = nil;
     [aDocument close];
     */
    
    
	[super close];
}


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	id  result;
	result = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];
    self.wasClosed = NO;
    return result;
    
/*
	CGFloat alpha = [SUD floatForKey: SourceWindowAlphaKey];
	if (alpha < 0.999)
        //[self setAlphaValue:alpha]; // removed by Terada
        [self performSelector:@selector(setAlpha:) withObject:[NSNumber numberWithFloat:alpha] afterDelay:0.5]; // added by Terada   
    [self performSelector:@selector(refreshTitle) withObject:nil afterDelay:1]; // added by Terada
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTitle) name:NSApplicationDidBecomeActiveNotification object:NSApp]; // added by Terada
	return result;
 */
}

/*
-(void)setAlpha:(NSNumber*)alpha // added by Terada
{
    [self setAlphaValue:[alpha floatValue]];
}

- (void)refreshTitle // added by Terada
{
	if([self.myDocument fileURL] != nil) [self setTitle:[self.myDocument fileTitleName]];
}

// In the pair of commands below, becomeMainWindow and resignMainWindow should do nothing
// unless the window has a "% !TEX" command. In this case
// becomeMainWindow should remember the current language, set the spell to the
// % !TEX choice, and set a global saying "don't use UID to record language

// If the window has % !TEX, then resign Main Window should
// reset the language to the remebered current language, and unset
// the global for "dont use UID to record language"
*/

- (void)setAutoSaveRelatedMenuItemsEnabled:(BOOL)enabled
{
    NSString    *theTitle, *theAction;
    SEL         anAction;
    
    NSMenu *fileMenu = [[[NSApp mainMenu] itemAtIndex:1] submenu];
    NSInteger saveMenuItemIndex = [fileMenu indexOfItemWithTarget:nil andAction:@selector(saveDocument:)];
    
    [fileMenu setAutoenablesItems:enabled];
    for (NSInteger i=1; i<=7; i++) {
        
        anAction = [[fileMenu itemAtIndex:saveMenuItemIndex+i] action];
        theAction = NSStringFromSelector(anAction);
        
        if ([theAction isEqualToString: @"submenuAction:"])
             {
               theTitle = [[fileMenu itemAtIndex:saveMenuItemIndex+i] title];
            if ([theTitle isEqualToString: NSLocalizedString(@"Revert To", @"Revert To")])
            /*
            if (([theTitle isEqualToString: @"Revert To"]) ||           // English
                ([theTitle isEqualToString: @"Volver a"]) ||            // Spanich
                ([theTitle isEqualToString: @"Revenir à"]) ||           // French
                ([theTitle isEqualToString: @"Zurücksetzen auf"]) ||    // German
                ([theTitle isEqualToString: @"バージョンを戻す"]) ||        // Japanese
                ([theTitle isEqualToString: @"다음으로 복귀"]) ||           // Korean
                ([theTitle isEqualToString: @"复原到"]) ||                // Simplified Chinese
                ([theTitle isEqualToString: @"Ripristina a"]) ||         // Italian
                ([theTitle isEqualToString: @"Vorige versie"]) ||        // Netherlands
                ([theTitle isEqualToString: @"Reverter Para"]) ||       // Portuguese Brazil
                ([theTitle isEqualToString: @"Restabelecer"]) ||       // Portuguese
                ([theTitle isEqualToString: @"Revino la"])          // Romanian
                )
             */
                 [[fileMenu itemAtIndex:saveMenuItemIndex+i] setEnabled:enabled];
             }
        else if (([theAction isEqualToString:@"saveDocumentAs:"]) ||
            ([theAction isEqualToString:@"duplicateDocument:"]) ||
            ([theAction isEqualToString:@"renameDocument:"]) ||
            ([theAction isEqualToString:@"moveDocument:"]) ||
            ([theAction isEqualToString:@"saveDocumentTo:"]) ||
            ([theAction isEqualToString:@"revertDocumentToSaved:"])
            )
                [[fileMenu itemAtIndex:saveMenuItemIndex+i] setEnabled:enabled];
        
        // 1: Save As; saveDocumentAs:
        // 2: Duplicate; duplicateDocument:
        // 3: Rename…; renameDocument:
        // 4: Move To…; moveDocument:
        // 5: Export…; saveDocumentTo:
        // 6: Revert To Saved; revertDocumentToSaved:
        // 7: Revert To: subMenu
    }

    if (enabled == NO)
    {
        NSInteger anIndex;
        
        anIndex = [fileMenu indexOfItemWithTarget:nil andAction:@selector(displayConsole:)];
        [[fileMenu itemAtIndex:anIndex] setEnabled:YES];
        
        anIndex = [fileMenu indexOfItemWithTarget:nil andAction:@selector(displayLog:)];
        [[fileMenu itemAtIndex:anIndex] setEnabled:YES];
        
        anIndex = [fileMenu indexOfItemWithTarget:nil andAction:@selector(performClose:)];
        [[fileMenu itemAtIndex:anIndex] setEnabled:YES];
        
        anIndex = [fileMenu indexOfItemWithTarget:nil andAction:@selector(saveDocument:)];
        [[fileMenu itemAtIndex:anIndex] setEnabled:YES];
        
        anIndex = [fileMenu indexOfItemWithTarget:nil andAction:@selector(saveDocumentAs:)];
        [[fileMenu itemAtIndex:anIndex] setEnabled:YES];
        
   //     anIndex = [fileMenu indexOfItemWithTarget:nil andAction:@selector(saveDocumentTo:)];
   //     [[fileMenu itemAtIndex:anIndex] setEnabled:YES];
  
   //     anIndex = [fileMenu indexOfItemWithTarget:nil andAction:@selector(showConsole:)];
   //     [[fileMenu itemAtIndex:anIndex] setEnabled:YES];
        
        anIndex = [fileMenu indexOfItemWithTarget:nil andAction:@selector(printDocument:)];
        [[fileMenu itemAtIndex:anIndex] setEnabled:YES];
    
  
        anIndex = [fileMenu indexOfItemWithTarget:nil andAction:@selector(printSource:)];
        [[fileMenu itemAtIndex:anIndex] setEnabled:YES];
        
        anIndex = [fileMenu indexOfItemWithTarget:nil andAction:@selector(convertTiff:)];
       [[fileMenu itemAtIndex:anIndex] setEnabled:YES];
   
       anIndex = [fileMenu indexOfItemWithTarget:nil andAction:@selector(abort:)];
       [[fileMenu itemAtIndex:anIndex] setEnabled:YES];
    
        anIndex = [fileMenu indexOfItemWithTarget:nil andAction:@selector(trashAUXFiles:)];
        [[fileMenu itemAtIndex:anIndex] setEnabled:YES];
   
     }

    
}



- (void) becomeMainWindow
{
    NSMenu      *menuBar;
    NSMenu      *fileMenu;

    [self setAutoSaveRelatedMenuItemsEnabled: NO];
    
// 	[self refreshTitle]; // added by Terada
	[super becomeMainWindow];
	[self.myDocument resetSpelling];
	[self.myDocument fixMacroMenuForWindowChange];
// WARNING: The following line caused a BIG delay when switching from the pdf window to the text window!!
// It can be turned on with a hidden preference, but the only users who need it
// a) use Japanese input methods and b) customize the background and foreground source colors and c) have a dark background color
    if ([SUD boolForKey:ResetSourceTextColorEachTimeKey])
        [self.myDocument setSourceTextColorFromPreferences:nil]; // added by Terada
    
    menuBar = [[NSApplication sharedApplication ] mainMenu];
    fileMenu = [[menuBar itemAtIndex:1] submenu];
    [[fileMenu itemWithTitle:@"Duplicate"] setEnabled: NO];

}

- (void) resignMainWindow
{
    NSMenu  *menuBar;
    NSMenu  *fileMenu;
    

    [self setAutoSaveRelatedMenuItemsEnabled: YES];

    [super resignMainWindow];
    [self.myDocument resignSpelling];
    
    menuBar = [[NSApplication sharedApplication ] mainMenu];
    fileMenu = [[menuBar itemAtIndex:1] submenu];
    [[fileMenu itemWithTitle:@"Duplicate"] setEnabled: YES];

}

- (BOOL)makeFirstResponder:(NSResponder *)aResponder
{
    BOOL	result;
    
    result = [super makeFirstResponder:aResponder];
    // FIXME: This is kind of ugly...
    if (result && [[aResponder className] isEqualTo:@"TSTextView"]) {
        [self.myDocument setTextView:aResponder];
    }
    return result;
}

- (void)associatedWindow:(id)sender
{
    [self.myDocument doAssociatedWindow];
/*
    if ([self.myDocument documentType] == isTeX) {
        [self.myDocument bringPdfWindowFront];
    }
*/
}



/*

// added by mitsu --(H) Macro menu; used to detect the document from a window
- (TSDocument *)document
{
	return self.myDocument;
}
// end addition

- (void)makeKeyAndOrderFront:(id)sender
{
    
	if (
		(! [self.myDocument externalEditor]) &&
		(([self.myDocument documentType] == isTeX) || ([self.myDocument documentType] == isOther))
		)
		[super makeKeyAndOrderFront: sender];
	[self.myDocument tryBadEncodingDialog:self];
}


- (void) doChooseMethod: sender
{
	[self.myDocument doChooseMethod: sender];
}

- (void) abort: sender
{
	[self.myDocument abort: sender];
}

- (void) trashAUXFiles: sender
{
	[self.myDocument trashAUXFiles: sender];
}


// forsplit
- (BOOL)makeFirstResponder:(NSResponder *)aResponder
{
	BOOL	result;

	result = [super makeFirstResponder:aResponder];
	// FIXME: This is kind of ugly...
	if (result && [[aResponder className] isEqualTo:@"TSTextView"]) {
		[self.myDocument setTextView:aResponder];
	}
	return result;
}
// end forsplit

- (void)close
{
    
// MAYBE NOW IRRELEVANT?
 
// Yusuke Terada addition to fix crash at close
    if(([[[TSDocumentController sharedDocumentController] documents] count] > 0) && self.myDocument && [self.myDocument respondsToSelector:@selector(pdfView)] && [self.myDocument pdfView])
        [[NSNotificationCenter defaultCenter] removeObserver:[self.myDocument pdfView]];
// end of patch
    // this fixes a bug; the application crashed when closing
 	// the last window in multi-page mode; investigation shows that the
	// myPDFView "wasScrolled" method was called from the notification center before dealloc, but after other items in the window
	// were released
	NSArray *myDocuments = [[NSDocumentController sharedDocumentController] documents];
	if (myDocuments != nil) {
		NSEnumerator *enumerator = [myDocuments objectEnumerator];
		id anObject;
		while ((anObject = [enumerator nextObject])) {
			if ([anObject getCallingWindow] == self)
				[anObject setCallingWindow: nil];
		}
	}

    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // added by Terada
    
//
//    TSDocument *aDocument = self.myDocument;
//    self.myDocument = nil;
//    [aDocument close];
//
    

	[super close];
}

- (void)sendEvent:(NSEvent *)theEvent
{
	
//	if (([theEvent type] == NSFlagsChanged) && ([theEvent modifierFlags] & NSCommandKeyMask))
//		NSLog(@"yes");
	
	if (([theEvent type] == NSKeyDown) && ([theEvent modifierFlags] & NSCommandKeyMask)) {
		
		if  ([[theEvent characters] characterAtIndex:0] == '[') {
			[self.myDocument doCommentOrIndentForTag:Munindent];
			return;
		} 
	
		if  ([[theEvent characters] characterAtIndex:0] == ']') {
			[self.myDocument doCommentOrIndentForTag:Mindent];
			return;
		} 
	}
	
	[super sendEvent: theEvent];
}

- (void)saveSourcePosition: sender
{
	[self.myDocument saveSourcePosition];
}


- (void)savePortableSourcePosition: sender
{
	[self.myDocument savePortableSourcePosition];
}


- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)defaultFrame
{
	NSRect	newFrame;
	
	newFrame = defaultFrame;
	if (defaultFrame.size.width > 1024)
		newFrame.size.width = 1024;
	return newFrame;
}

*/


@end
