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
	self.firstResize = NO;
	result = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];
	CGFloat alpha = [SUD floatForKey: ConsoleWindowAlphaKey];
	if (alpha < 0.999)
		 [self setAlphaValue:alpha];
	return result;
}

- (void) doChooseMethod: sender
{
	[self.myDocument doChooseMethod: sender];
}

- (void) doError: sender
{
	[self.myDocument doError: sender];
}

- (void) doTypeset: sender
{
	[self.myDocument doTypeset: sender];
}

- (void) displayLog: sender
{
	[self.myDocument displayLog: sender];
}

- (void) displayConsole: sender
{
	[self.myDocument displayConsole: sender];
}

- (void)associatedWindow: (id)sender
{
    TSDocument *myDocument = (TSDocument*)self.myDocument;
    [myDocument doError: sender];
    if ([myDocument externalEditor])
        return;
    if ([myDocument documentType] == isTeX) {
        if ([myDocument getCallingWindow] == nil)
            [[myDocument textWindow] makeKeyAndOrderFront: self];
        else
            [[myDocument getCallingWindow] makeKeyAndOrderFront: self];
        
    }
}

- (void) abort: sender
{
	[self.myDocument abort: sender];
}

- (void) trashAUXFiles: sender
{
	[self.myDocument trashAUXFiles: sender];
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
	
	if (self.firstResize) {
		newFrameSize = proposedFrameSize;
		oldFrame = [window frame];
		newFrameSize.width = oldFrame.size.width;
		return newFrameSize;
		}
	else {
		self.firstResize = YES;
		return proposedFrameSize;
		}
}

- (IBAction) convertTiff:(id)sender
{
    [(TSDocument *)self.myDocument convertTiff:sender];
}


// for scripting
- (TSDocument *)document
{
	return self.myDocument;
}
// end addition


@end
