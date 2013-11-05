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
 * $Id: TSMatrixPanelController.h 108 2006-02-10 13:50:25Z fingolfin $
 *
 * Created by Jonas Zimmermann on Fri Nov 28 2003.
 *
 */

#import <AppKit/AppKit.h>
@class MatrixData;

@interface TSMatrixPanelController : NSWindowController
{
	IBOutlet id borderbutton;
	IBOutlet id brselcl;
	IBOutlet id brselop;
	IBOutlet id brtfcl;
	IBOutlet id brtfop;
	IBOutlet id chbfig;
	IBOutlet id envsel;
	IBOutlet id gridbutton;
	IBOutlet id hstep;
	IBOutlet id htf;
	IBOutlet id matmod;
	IBOutlet id matrixtable;
	IBOutlet id mtscrv;
	IBOutlet id vstep;
	IBOutlet id vtf;
	
	NSInteger			MatrixSize;

	BOOL shown; //YES if user has chosen to display panel

	NSArray *arrayMatrix;
	NSNotificationCenter *notifcenter;
	NSMutableArray	    *draggedRows;

	MatrixData *myMatrix;
}
+ (id)sharedInstance;

- (void)hideWindow:(id)sender;
- (MatrixData *) theMatrix;
- (IBAction)envselChange:(id)sender;
- (IBAction)brselChange:(id)sender;
- (IBAction)insertMatrix:(id)sender;
- (IBAction)resetMatrix:(id)sender;
- (IBAction)resizeMatrix:(id)sender;
- (NSArray*)draggedRows;

@end


@interface MatrixData : NSObject {
	NSMutableArray    *rows;
	NSInteger activeRows;
	NSInteger activeCols;
}

- (NSInteger)rowCount;
- (NSInteger)colCount;
- (id)objectInRow:(NSUInteger)row inCol:(NSUInteger)col;
- (id)myRowAtIndex:(NSUInteger)row;
- (void)replaceObjectInRow:(NSUInteger)row inCol:(NSUInteger)col withObject:(id) anObj;
- (void)addRow;
- (void)insertRow:(NSMutableArray*)row atIndex:(NSInteger)ind;
- (void)removeRowAtIndex:(NSUInteger)ind;
- (void)removeRow:(id)row;
- (void)removeRowIdenticalTo:(id)row;
- (void)addCol;
- (void)removeLastCol;
- (void)removeLastRow;
- (NSInteger)actRows;
- (NSMutableArray*)rows;
- (void)setActRows:(NSInteger)num;
- (NSInteger)actCols;
- (void)setActCols:(NSInteger)num;

@end
