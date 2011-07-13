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
#import "TSConsoleWindow.h"
#import "TSDocument.h"
#import "globals.h"


@implementation TSConsoleWindow : NSWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	id  result;
	firstResize = NO;
	result = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];
	CGFloat alpha = [SUD floatForKey: ConsoleWindowAlphaKey];
	if (alpha < 0.999)
		 [self setAlphaValue:alpha];
	return result;
}

- (void) doChooseMethod: sender
{
	[myDocument doChooseMethod: sender];
}

- (void) doError: sender
{
	[myDocument doError: sender];
}

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

- (void) abort: sender
{
	[myDocument abort: sender];
}

- (void) trashAUXFiles: sender
{
	[myDocument trashAUXFiles: sender];
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)defaultFrame
{
	NSRect	oldFrame;
	NSRect	newFrame;
	CGFloat	newWidth;
	
	oldFrame = [window frame];
	newFrame = defaultFrame;
	
	newWidth = oldFrame.size.width;
	newFrame.size.width = newWidth; 
	newFrame.origin = oldFrame.origin;
	
	return newFrame;
}



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



// for scripting
- (TSDocument *)document
{
	return myDocument;
}
// end addition


@end
