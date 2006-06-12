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
 * $Id: TSMatrixTableView.h 108 2006-02-10 13:50:25Z fingolfin $
 *
 */

#import <Cocoa/Cocoa.h>

@interface TSMatrixTableView : NSTableView
{
	IBOutlet id myController;
}
- (void) drawStripesInRect:(NSRect)clipRect;

@end

// TODO: Try to get rid of this class
@interface InactiveTextFieldCell : NSTextFieldCell
-(id)init;
@end

// TODO: Try to get rid of this class
@interface ActiveTextFieldCell : NSTextFieldCell
-(id)init;
@end

@interface MatrixTableColumn : NSTableColumn
{
	NSCell *_inactiveDataCell;
}
-(id)init;
-(id)initWithIdentifier:(id)identifier;
@end

