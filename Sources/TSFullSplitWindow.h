/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2014 Richard Koch
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
 * $Id: TSTextEditorWindow.h 260 2007-08-08 22:51:09Z richard_koch $
 *
 * Originally part of TSDocument. Broken out by dirk on Tue Jan 09 2001.
 *
 */

#import <AppKit/NSWindow.h>
#import "TSDocument.h"


@interface TSFullSplitWindow: NSWindow
{
}

@property(weak) IBOutlet TSDocument   *myDocument;
@property BOOL wasClosed;

- (void)displayConsole: (id)sender;
- (void)displayLog: (id)sender;
- (void)doMove: (id)sender;
- (void)doSeparateWindows: (id)sender;
- (void)doTemplate: (id)sender;
- (void)doTag: (id)sender;
- (void)newTag: (id)sender;
- (void)doTypeset: (id)sender;
- (void)doTex: (id)sender;
- (void)doLatex: (id)sender;
- (void)doBibtex: (id)sender;
- (void)doIndex: (id)sender;
- (void)doMetapost: (id)sender;
//- (void)doContext: (id)sender;
- (void)closeCurrentEnvironment: (id)sender;
- (void)changeAutoComplete: (id)sender;
- (void)showHideLineNumbers: (id)sender;
- (void)showHideInvisibleCharacters: (id)sender;
- (void)showSourcePosition: (id)sender;
- (void)savePortableSourcePosition: (id)sender;
- (void)doCommentOrIndent: (id)sender;
- (void)setLineBreakMode: (id)sender;
- (void)hardWrapSelection: (id)sender;
- (void)removeNewLinesFromSelection: (id)sender;
- (void)doNextBullet: (id)sender;
- (void)doNextBulletAndDelete: (id)sender;
- (void)doPreviousBullet: (id)sender;
- (void)doPreviousBulletAndDelete: (id)sender;
- (void)placeBullet: (id)sender;
- (void)placeComment: (id)sender;
- (void)registerForCommandCompletion: (id)sender;
- (void)tryScrap: (id)sender;
- (void)doLine: (id)sender;
- (void)doError: (id)sender;
- (void)showStatistics: (id)sender;
- (void)runPageLayout: (id)sender;
- (void)printSource: (id)sender;
- (void)printDocument: (id)sender;
- (void)convertTiff: (id)sender;
- (void)splitWindow: (id)sender;
- (void) becomeMainWindow;
- (void) resignMainWindow;
- (BOOL)makeFirstResponder:(NSResponder *)aResponder;
- (void)associatedWindow:(id)sender;
- (void)abort:(id)sender;
- (void)performFindPanelAction: sender;
- (void) sendEvent:(NSEvent *)theEvent;

- (void)toggleDrawer: sender;
- (void)previousPage: sender;
- (void)nextPage: sender;
- (void)goBack: sender;
- (void)goForward: sender;
- (void)rotateClockwise: sender;
- (void)rotateCounterclockwise: sender;
- (void)saveSelectionToFile: sender;
- (void)changePDFViewSize: sender;
- (void)zoomIn: sender;
- (void)zoomOut: sender;
- (void)changePageStyle: sender;

/* WARNING: These do not make sense in single window mode
- (void)duplicateDocument: sender;
- (void)renameDocument: sender;
- (void)moveDocument: sender;
- (void)saveDocumentTo: sender;
- (void)revertDocumentToSaved: sender;
*/

/*

// added by mitsu --(H) Macro menu; used to detect the document from a window
// following is OK; it returns myDocument
 - (TSDocument *)document;
// end addition

- (void) doChooseMethod: sender;
- (void) saveSourcePosition: sender;
- (void) savePortableSourcePosition: sender;
- (void) makeKeyAndOrderFront:(id)sender;
- (void) trashAUXFiles: sender;
- (void) abort: sender;
- (void) becomeMainWindow;
- (void) resignMainWindow;
- (void) sendEvent:(NSEvent *)theEvent;
- (void) associatedWindow:(id)sender;
- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)defaultFrame;
// forsplit
- (BOOL)makeFirstResponder:(NSResponder *)aResponder;
- (void)close;
// end forsplit
*/


@end
