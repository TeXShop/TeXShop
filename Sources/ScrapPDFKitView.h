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
 * $Id: MyPDFKitView.h 260 2007-08-08 22:51:09Z richard_koch $
 *
 * Parts of this code are taken from Apple's example PDFKitViewer.
 *
 */

#import <AppKit/AppKit.h>
#import <Quartz/Quartz.h>
#import <AppKit/NSEvent.h>
#import "OverView.h"


@interface ScrapPDFKitView : PDFView 
{

    
	
}

@property           NSRect      scrapVisibleRect;
@property           NSRect      scrapFullRect;

- (void) reShowWithPath: (NSString *) imagePath;

@end

