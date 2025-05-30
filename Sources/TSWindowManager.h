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
 * $Id: TSWindowManager.h 108 2006-02-10 13:50:25Z fingolfin $
 *
 * Created by dirk on Sat Feb 17 2001.
 *
 */

#import <AppKit/AppKit.h>

@interface TSWindowManager : NSObject
{
// 	NSWindow		*_activeTextWindow;
//	NSWindow 		*_activePDFWindow;
}

@property (retain) 	NSWindow		*activeTextWindow;
@property (retain)  NSWindow 		*activePDFWindow;
@property (retain)  NSWindow        *activeHTMLWindow;


+ (id)sharedInstance;

/*
- (NSWindow *)activeTextWindow;
- (NSWindow *)activePDFWindow;
*/

- (void)notifyActiveTextWindowClosed;	// FIXME: Get rid of this

// added by mitsu --(J+) check mark in "Typeset" menu
- (void)checkProgramMenuItem: (NSInteger)programID checked: (BOOL)flag;
// end addition

- (void)textWindowDidBecomeKey:(NSNotification *)note;
- (void)documentWindowWillClose:(NSNotification *)note;
- (void)pdfWindowDidBecomeKey:(NSNotification *)note;
- (void)pdfWindowWillClose:(NSNotification *)note;
- (void)documentWindowDidResignKey:(NSNotification *)note;
- (void)pdfWindowDidResignKey:(NSNotification *)note;

- (void)textSplitWindowDidBecomeKey:(NSNotification *)note;
- (void)documentSplitWindowWillClose:(NSNotification *)note;
- (void)documentSplitWindowDidResignKey:(NSNotification *)note;

- (void)HtmlWindowDidBecomeKey:(NSNotification *)note;
- (void)HtmlWindowWillClose:(NSNotification *)note;
- (void)HtmlWindowDidResignKey:(NSNotification *)note;

@end
