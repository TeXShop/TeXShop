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
 * $Id$
 *
 * Originally part of TSDocument. Broken out by dirk on Tue Jan 09 2001.
 *
 */

#import <AppKit/AppKit.h>
#import "TSConsoleWindow.h"
#import "TSDocument.h"
#import "globals.h"


@implementation TSConsoleWindow : NSWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	id  result;
	result = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];
	float alpha = [SUD floatForKey: ConsoleWindowAlphaKey];
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

// for scripting
- (TSDocument *)document
{
	return myDocument;
}
// end addition


@end
