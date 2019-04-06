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
 * $Id: TSTextEditorWindow.h 260 2007-08-08 22:51:09Z richard_koch $
 *
 * Originally part of TSDocument. Broken out by dirk on Tue Jan 09 2001.
 *
 */

#import <AppKit/NSWindow.h>
#import "TSDocument.h"


@interface TSTextEditorWindow : NSWindow
{
}

@property (weak) TSDocument   *myDocument;
@property BOOL wasClosed;

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
- (void)performFindPanelAction: sender;

// end forsplit
@end
