/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2022 Richard Koch
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
  */

#import <AppKit/NSWindow.h>
#import <Quartz/Quartz.h>

@class TSDocument;

@interface TSHTMLWindow : NSWindow
{
}

@property               BOOL            willClose;
@property               BOOL            firstClose;
@property (weak) IBOutlet   TSDocument      *myDocument;


- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)defaultFrame;

- (void) close;
- (void) previousPage: sender;
- (void) nextPage: sender;

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

- (void) doTypeset: sender;
- (void) doAlternateTypeset: sender;
- (void) doError: sender;
- (void) toggleSyntaxColor: sender;
- (void) doChooseMethod: sender;
- (void) saveHTMLPosition: sender;
- (void) showHTMLWindow: sender; 
- (void) orderOut: sender;
- (void) sendEvent:(NSEvent *)theEvent;
- (void) associatedWindow: sender;
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
- (void)resignMainWindow;
- (TSDocument *)document;

@end
