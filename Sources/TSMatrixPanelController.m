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
 * $Id: TSMatrixPanelController.m 254 2007-06-03 21:09:25Z fingolfin $
 *
 * Created by Jonas Zimmermann on Fri Nov 28 2003.
 *
 */

#import "TSMatrixPanelController.h"
#import "TSMatrixTableView.h"
#import "TSWindowManager.h"


#import "globals.h"
#define MatPboardType 	@"MatrixRowPboardType"
#define MATSIZE 10

@implementation TSMatrixPanelController


static id _sharedInstance = nil;

+ (id)sharedInstance
{
	if (_sharedInstance == nil)
		_sharedInstance = [[TSMatrixPanelController alloc] initWithWindowNibName:@"matrixpanel"];
	return _sharedInstance;
}

- (id)init
{
	if ((self = [super init])) {
		shown = NO;
	}
	return self;
}

- (void)dealloc
{
//	[myMatrix release];
//	[arrayMatrix release];
//	myMatrix = nil;
//	arrayMatrix = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];

//	[super dealloc];
}

- (MatrixData *)theMatrix
{
	return self.myMatrix;
}

/*

- (NSArray*)draggedRows
{
	return draggedRows;
}
*/

-(void)awakeFromNib
{
	NSArray *upArray;
	NSArray *downArray;
	
	// MatrixSize = MATSIZE;
	MatrixSize = [SUD integerForKey:MatrixSizeKey];
	if (MatrixSize < 2)
		MatrixSize = 2;
	if (MatrixSize > 100)
		MatrixSize = 100;
	
	[hstep setMaxValue:MatrixSize];
	[vstep setMaxValue:MatrixSize];
	self.myMatrix=[[MatrixData alloc]init];
	NSInteger j;
	for (j = 0; j < MatrixSize; j++) {
		[self.myMatrix addRow];
	}
	
	while ([self.myMatrix colCount]<MatrixSize) {
		[self.myMatrix addCol];
		MatrixTableColumn *newcol;
		newcol = [[MatrixTableColumn alloc] initWithIdentifier:[[NSNumber numberWithInteger:[self.myMatrix colCount]-1] stringValue]];
		[[newcol headerCell] setStringValue:[[NSNumber numberWithInteger:[self.myMatrix colCount]] stringValue]];
		[newcol setMinWidth:40];
		[newcol setWidth:60];
		[matrixtable addTableColumn:newcol];
	}

	[self.myMatrix setActRows:3];
	[self.myMatrix setActCols:3];
	
	upArray = [NSArray arrayWithObjects:[NSNumber numberWithDouble:2.0], nil];
	downArray = [NSArray arrayWithObjects:[NSNumber numberWithDouble:.5], nil];
		
	[NSRulerView registerUnitWithName:@"Rows" abbreviation:@"rw"
		 unitToPointsConversionFactor:19 stepUpCycle:upArray stepDownCycle:downArray];
	
	[mtscrv setHasVerticalRuler:YES];
	[mtscrv setRulersVisible:YES];
	[[mtscrv verticalRulerView] setMeasurementUnits:@"Rows"];

	[matrixtable setAutosaveTableColumns:TRUE];
	[matrixtable setVerticalMotionCanBeginDrag:NO];
	[matrixtable registerForDraggedTypes:[NSArray arrayWithObjects:MatPboardType, nil]];
	
	[matrixtable reloadData];
}

- (void)windowDidLoad
{
	NSPoint		aPoint;
	NSString		*matrixPath;
	NSDictionary	*matrixDictionary;


	NSBundle *myBundle = [NSBundle mainBundle];

	matrixPath = [MatrixPanelPath stringByStandardizingPath];
	matrixPath = [matrixPath stringByAppendingPathComponent:@"matrixpanel_1"];
	matrixPath = [matrixPath stringByAppendingPathExtension:@"plist"];
	if ([[NSFileManager defaultManager] fileExistsAtPath: matrixPath])
		matrixDictionary = [NSDictionary dictionaryWithContentsOfFile:matrixPath];
	else
		matrixDictionary = [NSDictionary dictionaryWithContentsOfFile:
			[myBundle pathForResource:@"matrixpanel_1" ofType:@"plist"]];

	[super windowDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(panelDidMove:)
												 name:NSWindowDidMoveNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(panelWillClose:)
												 name:NSWindowWillCloseNotification object:[self window]];


	// result = [[self window] setFrameAutosaveName:LatexPanelNameKey];
	aPoint.x = [[NSUserDefaults standardUserDefaults] floatForKey:MPanelOriginXKey];
	aPoint.y = [[NSUserDefaults standardUserDefaults] floatForKey:MPanelOriginYKey];
	[[self window] setFrameOrigin: aPoint];
	[[self window] setHidesOnDeactivate: YES];
	// [self window] is actually an NSPanel, so it responds to the message below
	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded: NO];

	self.arrayMatrix = [[NSArray alloc] initWithArray:[matrixDictionary objectForKey:@"Matrix" ]];

	notifcenter = [NSNotificationCenter defaultCenter];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [self.myMatrix rowCount];
}

// Mandatory tableview data source method
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString  *theValue, *colid;
	colid = [tableColumn identifier];
	NSParameterAssert(row >= 0 && row < [self.myMatrix rowCount]);
	if ([colid isEqualToString:@"col"]) {
		return [NSNumber numberWithInteger:row+1];
	} else {
		theValue = [self.myMatrix objectInRow:row inCol:[colid integerValue]];
		return theValue;
	}

}
- (void)tableViewColumnDidMove:(NSNotification *)aNotification
{
	[matrixtable reloadData];
	[matrixtable setNeedsDisplay];
}

- (void)tableView:(NSTableView *)tv setObjectValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(NSInteger)row
{
	[self.myMatrix replaceObjectInRow:row inCol:[[tc identifier] integerValue] withObject:objectValue];
}

	// when a drag-and-drop operation comes through, and a filename is being dropped on the table,
	// we need to tell the table where to put the new filename (right at the end of the table).
	// This controls the visual feedback to the user on where their drop will go.
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
	[tv setDropRow:row dropOperation:NSTableViewDropAbove];
	return [info draggingSourceOperationMask];
}

- (BOOL) tableView:(NSTableView*)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard *)pboard
{
	NSInteger i;
	NSMutableArray *j = [NSMutableArray array];
	[pboard declareTypes:[NSArray arrayWithObject:MatPboardType] owner:self];
	
	for (i = 0; i < [rows count]; i++) {
		[j addObject:[self.myMatrix myRowAtIndex:[[rows objectAtIndex:i] integerValue]]];
	}
	[pboard setPropertyList:j forType:MatPboardType];
	self.draggedRows = j;
	
	return YES;
	
}


// This routine does the actual processing for a drag-and-drop operation on a tableview.
// As the tableview's data source, we get this call when it's time to update our backend data.
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
	// Get the drag-n-drop pasteboard
	NSPasteboard *myPasteboard=[info draggingPasteboard];
	// What type of data are we going to allow to be dragged?  The pasteboard
	// might contain different formats
	NSArray *typeArray=[NSArray arrayWithObjects:MatPboardType,nil];
	NSString *availableType;
	NSArray *_draggedrows;
	NSMutableArray *matRow;
	NSMutableIndexSet* indset = [NSMutableIndexSet indexSet];
	NSInteger i;
	
	// find the best match of the types we'll accept and what's actually on the pasteboard
	availableType=[myPasteboard availableTypeFromArray:typeArray];
	// In the file format type that we're working with, get all data on the pasteboard
	_draggedrows=[myPasteboard propertyListForType:availableType];
	
	for (i = 0; i < [_draggedrows count]; i++) {
		matRow = [_draggedrows objectAtIndex:i];
		if (row > [[self.myMatrix rows] indexOfObjectIdenticalTo:[[(TSMatrixPanelController *)[[info draggingSource] dataSource] draggedRows] objectAtIndex:i]])
			row--;
		[[self.myMatrix rows] removeObjectIdenticalTo:[[(TSMatrixPanelController *)[[info draggingSource] dataSource] draggedRows] objectAtIndex:i]];
		
		[[self.myMatrix rows] insertObject:matRow atIndex:row+i];
	}
	for (i = 0; i < [_draggedrows count]; i++) {
		matRow = [_draggedrows objectAtIndex:i];
		[indset addIndex:[[self.myMatrix rows] indexOfObjectIdenticalTo:matRow]];
	}
	
	[matrixtable reloadData];
	[matrixtable selectRowIndexes:indset byExtendingSelection:NO];
	
	return YES;
}



- (IBAction)resizeMatrix:(id)sender
{
	NSInteger ival = [sender integerValue];
	if (ival > MatrixSize)
		ival = MatrixSize;
	else if (ival < 1)
		ival = 1;

	if ((sender == hstep) || (sender == htf)) {
		while ((ival != [self.myMatrix actCols]) && (ival <= MatrixSize) && (ival > 0)) {
			if (ival > [self.myMatrix actCols]) {
				[self.myMatrix setActCols:[self.myMatrix actCols]+1];
			} else {
				[self.myMatrix setActCols:[self.myMatrix actCols]-1];
				
			}
		}
		
		if (sender == hstep)
			[htf setIntegerValue:[self.myMatrix actCols]];
		else {
			[hstep setIntegerValue:[self.myMatrix actCols]];
			[htf setIntegerValue:[self.myMatrix actCols]];
		}
		
	} else if ((sender == vstep) || (sender == vtf)) {
		
		while ((ival != [self.myMatrix actRows]) && (ival <= MatrixSize) && (ival > 0)) {
			if (ival > [self.myMatrix actRows]) {
				[self.myMatrix setActRows:[self.myMatrix actRows]+1];
			} else {
				[self.myMatrix setActRows:[self.myMatrix actRows]-1];
			}
		}
		
		if (sender == vstep)
			[vtf setIntegerValue:[self.myMatrix actRows]];
		else {
			[vstep setIntegerValue:[self.myMatrix actRows]];
			[vtf setIntegerValue:[self.myMatrix actRows]];
		}
		
	}
	[matrixtable reloadData];
}

- (IBAction)insertMatrix:(id)sender
{
	NSMutableString *insertion = [NSMutableString stringWithCapacity:200];
	NSInteger i, j;
	NSInteger brstyleop = [[brselop selectedCell] tag];
	NSInteger brstylecl = [[brselcl selectedCell] tag];
	NSInteger environment = [[envsel selectedCell] tag];
	NSInteger tablenv = ([chbfig state] == NSOnState);
	NSInteger drawborder = ([borderbutton state] == NSOnState);
	NSInteger drawgrid = ([gridbutton state] == NSOnState);
	NSInteger hsize = [self.myMatrix actCols];
	NSInteger vsize = [self.myMatrix actRows];

	if (environment == 0) {
		if ((brstyleop == 4) && (brstylecl == 4)) {
		} else {
			[insertion appendString:[self.arrayMatrix objectAtIndex:6]];
			if (brstyleop == 0) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:8]];
			} else if (brstyleop == 1) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:10]];
			} else if (brstyleop == 2) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:12]];
			} else if (brstyleop == 3) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:14]];
			} else if (brstyleop == 5) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:15]];
				[insertion appendString:[brtfop stringValue]];
			} else if (brstyleop == 4) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:15]];
			} else if (brstylecl == 6) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:16]];
			}

		}
	}

	if (environment == 0) {
		[insertion appendString:[self.arrayMatrix objectAtIndex:0]];
	} else {
		if (tablenv) {
			[insertion appendString:[self.arrayMatrix objectAtIndex:20]];
		}
		[insertion appendString:[self.arrayMatrix objectAtIndex:17]];
	}

	if (drawborder)
		[insertion appendString:[self.arrayMatrix objectAtIndex:14]];

	for (i = 0; i < hsize; i++)  {
		[insertion appendString:[self.arrayMatrix objectAtIndex:1]];
		if ((drawgrid) && (i<hsize-1))
			[insertion appendString:[self.arrayMatrix objectAtIndex:14]];
	}
	if (drawborder)
		[insertion appendString:[self.arrayMatrix objectAtIndex:14]];

	[insertion appendString:[self.arrayMatrix objectAtIndex:2]];
	if (drawborder)
		[insertion appendString:[self.arrayMatrix objectAtIndex:19]];

	for (j = 0; j < vsize; j++) {
		for (i = 0; i < hsize; i++) {
			[insertion appendString:[self.myMatrix objectInRow:j inCol:[[[[matrixtable tableColumns] objectAtIndex:i] identifier] integerValue] ]];
			if (i < hsize-1)
				[insertion appendString:[self.arrayMatrix objectAtIndex:3]];
		}
		if (j < vsize-1) {
			[insertion appendString:[self.arrayMatrix objectAtIndex:4]];
			if (drawgrid)
				[insertion appendString:[self.arrayMatrix objectAtIndex:19]];
		}

	}
	if (drawborder) {
		[insertion appendString:[self.arrayMatrix objectAtIndex:4]];
		[insertion appendString:[self.arrayMatrix objectAtIndex:19]];
	}

	if (environment == 0) {
		[insertion appendString:[self.arrayMatrix objectAtIndex:5]];
	} else {
		[insertion appendString:[self.arrayMatrix objectAtIndex:18]];
		if (tablenv) {
			[insertion appendString:[self.arrayMatrix objectAtIndex:21]];
		}

	}

	if (environment == 0) {
		if ((brstyleop == 4) && (brstylecl == 4)) {
		} else {
			[insertion appendString:[self.arrayMatrix objectAtIndex:7]];
			if (brstylecl == 0) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:9]];
			} else if (brstylecl == 1) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:11]];
			} else if (brstylecl == 2) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:13]];
			} else if (brstylecl == 3) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:14]];
			} else if (brstylecl == 5) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:15]];
				[insertion appendString:[brtfcl stringValue]];
			} else if (brstylecl == 4) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:15]];
			} else if (brstylecl == 6) {
				[insertion appendString:[self.arrayMatrix objectAtIndex:16]];
			}
		}
	}

	[notifcenter postNotificationName:@"matrixpanel" object:insertion];
}

- (IBAction)envselChange:(id)sender
{
	if ([[sender selectedCell] tag] == 1) {
		[brselcl setEnabled:NO];
		[brselop setEnabled:NO];
		[brtfcl setEnabled:NO];
		[brtfop setEnabled:NO];
		[chbfig setEnabled:YES];
	} else {
		[brselcl setEnabled:YES];
		[brselop setEnabled:YES];
		[brtfcl setEnabled:YES];
		[brtfop setEnabled:YES];
		[chbfig setEnabled:NO];

	}
}

- (IBAction)brselChange:(id)sender
{
	if ([[sender selectedCell] tag] == 5) {
		if (sender == brselop) {
			[brtfop setEnabled:YES];
		} else {
			[brtfcl setEnabled:YES];
		}
	} else {
		if (sender == brselop) {
			[brtfop setEnabled:NO];
		} else {
			[brtfcl setEnabled:NO];
		}
	}
}

- (IBAction)resetMatrix:(id)sender
{
	NSInteger i, j, action;
	NSInteger mwdth, mhght;
	mwdth = [self.myMatrix colCount];
	mhght = [self.myMatrix rowCount];
	
	if (sender == matmod) {
		action = [[sender selectedCell] tag];
		if (action == 2) {
			for (i = 0; i < mhght; i++) {
				for (j = 0; j < mwdth; j++) {
					[self.myMatrix replaceObjectInRow:i inCol:j withObject:@"0"];
				}
			}
		} else if (action == 0) {
			for (i = 0; i < mhght; i++) {
				for (j = 0; j < mwdth; j++) {
					[self.myMatrix replaceObjectInRow:i inCol:j withObject:@" "];
				}
			}
		} else {
			for (i = 0; i < mhght; i++) {
				for (j = 0; j < mwdth; j++) {
					[self.myMatrix replaceObjectInRow:i inCol:j withObject:@"0"];
				}
			}
			for(i = 0; (i < mwdth) && (i < mhght); i++)
				[self.myMatrix replaceObjectInRow:i inCol:[[[[matrixtable tableColumns]objectAtIndex:i] identifier] integerValue] withObject:@"1"];
			
		}
	}
	[matrixtable reloadData];
	
}



- (void)textWindowDidBecomeKey:(NSNotification *)note
{
	// if matrix panel is hidden, show it
	if (shown)
		[[self window] orderFront:self];
}

- (void)pdfWindowDidBecomeKey:(NSNotification *)note
{
	// if matrix panel is visible, hide it
	if (shown)
		[[self window] orderOut:self];
}

- (IBAction)showWindow:(id)sender
{
	shown = YES;
	[super showWindow:sender];
}

- (void)hideWindow:(id)sender
{
	shown = NO;
	[[self window] close];
}

- (void)panelWillClose:(NSNotification *)notification
{
	shown = NO;
	NSMenuItem *myItem = [[NSApp windowsMenu] itemWithTitle:NSLocalizedString(@"Close Matrix Panel", @"Close Matrix Panel")];
	[myItem  setTitle:NSLocalizedString(@"Matrix Panel...", @"Matrix Panel...")];
	[myItem setTag:0];
}

- (void)panelDidMove:(NSNotification *)notification
{
	NSRect	myFrame;
	CGFloat	x, y;

	myFrame = [[self window] frame];
	x = myFrame.origin.x;
	y = myFrame.origin.y;
	[[NSUserDefaults standardUserDefaults] setFloat:x forKey:MPanelOriginXKey];
	[[NSUserDefaults standardUserDefaults] setFloat:y forKey:MPanelOriginYKey];
	// [[self window] saveFrameUsingName:@"theLatexPanel"];
}

@end



@implementation MatrixData

-(id) init
{
	if ((self = [super init])) {
		self.rows = [[NSMutableArray alloc] init];
		activeRows = 0;
		activeCols = 0;
	}
	return self;
}

/*
- (void)dealloc
{
	[rows release];
	[super dealloc];
}
*/

/*

- (NSMutableArray*)rows
{
	return rows;
}
*/

- (NSInteger)actRows
{
	return activeRows;
}

-(void)setActRows:(NSInteger)num
{
	activeRows=num;
}

- (NSInteger)actCols
{
	return activeCols;
}

-(void)setActCols:(NSInteger)num
{
	activeCols = num;
}

-(id)myRowAtIndex:(NSUInteger)row
{
	return [self.rows objectAtIndex:row];  //retain];
}

-(NSInteger)rowCount
{
	return [self.rows count];
}

-(NSInteger)colCount
{
	if ([self rowCount]==0)
		return 0;
	return [[self myRowAtIndex:0] count];
}

-(id)objectInRow:(NSUInteger)row inCol:(NSUInteger)col
{
	return [[self myRowAtIndex:row] objectAtIndex:col];
}

-(void)replaceObjectInRow:(NSUInteger)row inCol:(NSUInteger)col withObject:(id) anObj{
	[[self myRowAtIndex:row] replaceObjectAtIndex:col withObject:anObj];
}

-(void)addRow
{
	NSInteger i;
	[self.rows addObject:[NSMutableArray arrayWithCapacity:[self colCount]]]; //retain]];
	for (i = [[self.rows objectAtIndex:[self.rows count]-1] count]; i < [self colCount]; i++) {
		[[self.rows objectAtIndex:[self.rows count]-1] addObject:@"0"];
	}
	activeRows++;

}

- (void)insertRow:(NSMutableArray*)row atIndex:(NSInteger)ind
{
	[self.rows insertObject:row atIndex:ind];
}

- (void)removeRow:(id )row
{
	[self.rows removeObject:row];
}

- (void)removeRowIdenticalTo:(id)row
{
	[self.rows removeObjectIdenticalTo:row];
}

- (void)removeRowAtIndex:(NSUInteger )ind
{
	[self.rows removeObjectAtIndex:ind];
}

-(void)addCol
{
	NSInteger i;
	for (i = 0; i < [self rowCount]; i++) {
 		[[self myRowAtIndex:i] addObject:@"0"];
	}
	activeCols++;
}

-(void)removeLastCol
{
	NSInteger i;
	for (i = 0; i < [self rowCount]; i++) {
		[[self myRowAtIndex:i] removeLastObject];
	}
	activeCols--;
}

-(void)removeLastRow
{
	[self.rows removeLastObject];
	activeRows--;
}

@end
