/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2007 Richard Koch
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
 * $Id: MyDragView.m 197 2006-05-29 21:19:33Z fingolfin $
 *
 */

#import <AppKit/AppKit.h>
#import "MyDragView.h"

@implementation MyDragView : NSView

#pragma mark =====set up the view=====
- (id)initWithFrame:(NSRect)frameRect
{
	id		value;

	value = [super initWithFrame: frameRect];

	return value;
}

/*

- (void)dealloc
{
	// [myRep release];
	[super dealloc];
}
*/

- (void) setImageRep: (NSPDFImageRep *)theRep
{	
	if (theRep != nil)
		self.myRep = theRep;
}

#pragma mark =====drawRect=====

- (void)drawRect:(NSRect)aRect
{
		[self.myRep draw];
}

@end

