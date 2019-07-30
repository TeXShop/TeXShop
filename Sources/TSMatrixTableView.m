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
 * $Id: TSMatrixTableView.m 108 2006-02-10 13:50:25Z fingolfin $
 *
 */

#import "TSMatrixTableView.h"
#import "TSMatrixPanelController.h"

// RGB values for stripe color (light blue)
#define STRIPE_RED   (237.0 / 255.0)
#define STRIPE_GREEN (243.0 / 255.0)
#define STRIPE_BLUE  (254.0 / 255.0)
static NSColor *sStripeColor = nil;

@implementation TSMatrixTableView

/*
-(NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	if (isLocal) return NSDragOperationEvery;
	else return NSDragOperationCopy;
}
*/

-(BOOL)ignoreModifierKeysWhileDragging
{
	return YES;
}

- (void) highlightSelectionInClipRect:(NSRect)rect
{
	[self drawStripesInRect:rect];
	//[super highlightSelectionInClipRect:rect];
}

-(void) reloadData
{
	[super reloadData];
	NSInteger i;
	for (i = 0; i < [self numberOfColumns]; i++) {
		if (i >= [[(TSMatrixPanelController *)[self dataSource] theMatrix] actCols])
			[[[self tableColumns] objectAtIndex:i] setDataCell:[[InactiveTextFieldCell alloc] init]];
		else
			[[[self tableColumns] objectAtIndex:i] setDataCell:[[ActiveTextFieldCell alloc] init]];
	}
}

-(id)init
{
	if ((self = [super init])) {
		[self setDataSource:[MatrixData init]];
	}
	return self;
}

// draw background of area of tableview, which will be inserted

- (void) drawStripesInRect:(NSRect)clipRect
{
    
	NSRect stripeRect;
	NSInteger actCols = [[(TSMatrixPanelController *)[self dataSource] theMatrix] actCols];
	NSInteger actRows = [[(TSMatrixPanelController *)[self dataSource] theMatrix] actRows];
	CGFloat fullRowHeight = [self rowHeight] + [self intercellSpacing].height;
	CGFloat clipBottom = MIN(NSMaxY(clipRect), actRows*fullRowHeight);
	CGFloat clipRight=0;
	NSInteger i;
	NSArray* tableCols;
	
	NSInteger firstStripe = clipRect.origin.y / fullRowHeight;
	if (firstStripe < actRows) {
		
		tableCols = [self tableColumns];
		for (i = 0; i < actCols;i++) {
			clipRight += [[tableCols objectAtIndex:i] width] + [self intercellSpacing].width;
		}
		
		stripeRect.origin.x = clipRect.origin.x;
		stripeRect.origin.y = firstStripe * fullRowHeight;
		stripeRect.size.width = MIN(clipRect.size.width, clipRight-clipRect.origin.x);
		stripeRect.size.height = fullRowHeight;
		// set the color
		if (sStripeColor == nil)
			sStripeColor = [NSColor colorWithCalibratedRed:STRIPE_RED green:STRIPE_GREEN blue:STRIPE_BLUE alpha:1.0];  //retain];
		[sStripeColor set];
		// and draw the stripes
		while (stripeRect.origin.y < clipBottom) {
			NSRectFill(stripeRect);
			stripeRect.origin.y += fullRowHeight;
		}
	}
}

@end

/*
//Old
 
 @implementation InactiveTextFieldCell
 
 -(id)init
 {
 if ((self = [super init])) {
 [self setTextColor:[NSColor colorWithCalibratedWhite:0.827 alpha:1]];
 [self setEditable:YES];
 [self setEnabled:YES];
 [self setDrawsBackground:YES];
 [self setBackgroundColor:[NSColor colorWithCalibratedRed:1 green:1 blue:.985 alpha:1]];
 }
 return self;
 }
 
 @end
 
 
 
 @implementation ActiveTextFieldCell
 
 -(id)init
 {
 if ((self = [super init])) {
 //[self setTextColor:[NSColor disabledControlTextColor]];
 [self setEditable:YES];
 [self setDrawsBackground:NO];
 // [self setBackgroundColor:[NSColor blueColor]];
 }
 return self;
 }
 */

@implementation InactiveTextFieldCell

-(id)init
{
	if ((self = [super init])) {
		[self setTextColor:[NSColor colorWithCalibratedWhite:0.827 alpha:1]];
       // [self setTextColor: [NSColor blackColor]];  //textColor
		[self setEditable:YES];
		[self setEnabled:YES];
		[self setDrawsBackground:YES];
		[self setBackgroundColor:[NSColor colorWithCalibratedRed:1 green:1 blue:.985 alpha:1]];
       // [self setBackgroundColor: [NSColor textBackgroundColor]];
	}
	return self;
}

@end



@implementation ActiveTextFieldCell

-(id)init
{
	if ((self = [super init])) {
		// [self setTextColor:[NSColor disabledControlTextColor]];
        [self setTextColor:[NSColor redColor]];
        // [self setTextColor:[NSColor colorWithCalibratedWhite:0.011 alpha:1]];
       // [self setTextColor:[NSColor blackColor]];
 		[self setEditable:YES];
		[self setDrawsBackground:NO];
	   // [self setBackgroundColor:[NSColor blueColor]];
	}
	return self;
}

@end



@implementation MatrixTableColumn

-(id) init
{
	return [self initWithIdentifier:@"0"];
}

- (id)initWithIdentifier:(id)identifier
{
	if ((self = [super initWithIdentifier:identifier])) {
		//[_inactiveDataCell init];
		
		// FIXME: BAD HACK! We are directly accessing a member variable of NSTextFieldCell here!
		self.dataCell = [[ActiveTextFieldCell alloc] init];
		
		_inactiveDataCell = [[InactiveTextFieldCell alloc] init];
	}
	return self;
}

-(id)dataCellForRow:(NSInteger)row
{
	// NSTextFieldCell *acell=[self dataCell];
	if ([self tableView] == nil || row == -1) {
		return [self dataCell];
	} else {
		if (([[(TSMatrixPanelController *)[[self tableView] dataSource] theMatrix] actRows] <= row) ) {
			return _inactiveDataCell;
		}
	}
	return [self dataCell];
}

@end
