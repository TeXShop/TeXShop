//
//  TSAppDelegate.h
//  TeXShop
//
//  Created by dirk on Tue Jan 23 2001.
//

#import <Foundation/Foundation.h>
#import "Autrecontroller.h"
// added by mitsu --(H) Macro menu and (G) EncodingSupport
// #import "MacroMenuController.h"
#import "EncodingSupport.h"
// end addition

@interface TSAppDelegate : NSObject 
{
    BOOL	forPreview;
}

- (IBAction)openForPreview:(id)sender;
- (IBAction)displayLatexPanel:(id)sender;
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
- (BOOL)forPreview;
- (void)configureExternalEditor;
- (void)configureMenuShortcutsFolder;
- (void)configureAutoCompletion;
- (void)configureTemplates;
- (void)configureLatexPanel;
- (void)configureMacro;
- (void)finishAutoCompletionConfigure;
- (void)finishMenuKeyEquivalentsConfigure;
- (void)showConfiguration:(id)sender;
- (void)showMacrosHelp:(id)sender;
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;
@end
