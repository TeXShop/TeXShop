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
 * $Id: TSPrintView.m 153 2006-05-23 21:42:59Z fingolfin $
 *
 * Originally part of TSDocument. Broken out by dirk on Tue Jan 09 2001.
 *
 */

#import <AppKit/AppKit.h>
#import "TSPrintView.h"

@implementation TSPrintView : NSView

- (TSPrintView *)initWithImageRep: (NSImageRep *) aRep
{
	NSRect	frame;

	frame.origin.x = 0;
	frame.origin.y = 0;
	frame.size = [aRep size];
	if ((self = [super initWithFrame: frame])) {
		_imageRep = [aRep retain];
	}
	// end
	return self;
}

- (void)dealloc {
	[_imageRep release];
	[super dealloc];
}

- (BOOL)isVerticallyCentered
{
	return YES;
}

- (BOOL)isHorizontallyCentered
{
	return YES;
}

- (void)drawRect:(NSRect)aRect
{
	NSRect  myRect;

	myRect = [self bounds];
	if ([_imageRep isKindOfClass:[NSPDFImageRep class]]) {
		NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
		float scale = [[[printInfo dictionary] objectForKey:NSPrintScalingFactor]
						floatValue];
		myRect.size.height = myRect.size.height * scale;
		myRect.size.width = myRect.size.width * scale;

		[_imageRep drawInRect: myRect];
	} else {
		NSEraseRect(myRect);
		[_imageRep draw];
	}
}


- (BOOL)knowsPageRange:(NSRangePointer)range
{
	if ([_imageRep isKindOfClass:[NSPDFImageRep class]]) {
		range->location = 1;
		range->length = [(NSPDFImageRep *)_imageRep pageCount];
		return YES;
	} else {
		return NO;
	}
}

- (NSRect)rectForPage:(int)pageNumber
{
	// This method will only be called when knowsPageRange: return YES, i.e. only
	// if _imageRep is a NSPDFImageRep.
	NSPDFImageRep *pdfRep = (NSPDFImageRep *)_imageRep;
	int		thePage;
	NSRect	aRect;

	thePage = pageNumber;
	if (thePage < 1)
		thePage = 1;
	if (thePage > [pdfRep pageCount])
		thePage = [pdfRep pageCount];
	[pdfRep setCurrentPage: thePage - 1];

	aRect.origin.x = 0;
	aRect.origin.y = 0;
	aRect.size = [pdfRep bounds].size;

	NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
	float scale = [[[printInfo dictionary] objectForKey:NSPrintScalingFactor]
					floatValue];
	aRect.size.height = aRect.size.height * scale;
	aRect.size.width = aRect.size.width * scale;

	return aRect;
}

@end
