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
 * $Id: TSConsoleWindow.m 108 2006-02-10 13:50:25Z fingolfin $
 *
 * Originally part of TSDocument. Broken out by dirk on Tue Jan 09 2001.
 *
 */

#import <AppKit/AppKit.h>
#import "TSLogWindow.h"
#import "TSDocument.h"
#import "globals.h"


@implementation TSLogWindow : NSWindow

- (void) doTypeset: sender
{
	[myDocument doTypeset: sender];
}

- (void) displayLog: sender
{
	[myDocument displayLog: sender];
}

- (void) displayConsole: sender
{
	[myDocument displayConsole: sender];
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)defaultFrame
{
	NSRect	oldFrame;
	NSRect	newFrame;

	
	oldFrame = [window frame];
	newFrame = defaultFrame;
	
	if (defaultFrame.size.width > 1024)
		newFrame.size.width = 1024;
	
	newFrame.origin = oldFrame.origin;
	
	return newFrame;
}

/*
- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize
{

	NSRect	oldFrame;
	NSSize	newFrameSize;
	
	if ([SUD boolForKey:ConsoleWidthResizeKey])
		return proposedFrameSize;
	
	if (firstResize) {
		newFrameSize = proposedFrameSize;
		oldFrame = [window frame];
		newFrameSize.width = oldFrame.size.width;
		return newFrameSize;
		}
	else {
		firstResize = YES;
		return proposedFrameSize;
		}
}
*/


@end
