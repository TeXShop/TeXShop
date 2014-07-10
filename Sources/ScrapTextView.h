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
 * $Id: TSTextView.h 140 2006-05-21 13:36:28Z fingolfin $
 *
 */

#import <Cocoa/Cocoa.h>
#import "TSDocument.h"

@interface ScrapTextView : NSTextView 
{
    BOOL _alternateDown;
    BOOL latexSpecial; // was last time LaTeX Special?  \begin{...}
    BOOL wasCompleted; // was completed on last keyDown
    NSUInteger replaceLocation; // completion started here
    NSUInteger completionListLocation; // location to start search in the list
    NSUInteger textLocation; // location of insertion point
    
    /*
    BOOL			_alternateDown;
    // (HS) variables for Command Completion now instance/member variables --- moved from keyDown --- 2012/05/15.
    BOOL wasCompleted; // was completed on last keyDown
    //   NSString *originalString; // string before completion, starts at replaceLocation
    //   NSString *currentString; // completed string
    NSUInteger replaceLocation; // completion started here
    NSUInteger completionListLocation; // location to start search in the list
    NSUInteger textLocation; // location of insertion point
    */
	
}

@property (weak) TSDocument   *document;
@property (retain) NSString     *originalString;
@property (retain) NSString     *currentString;


@end

