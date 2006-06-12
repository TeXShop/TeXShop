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
 * $Id: TSMatrixPanelController.m 108 2006-02-10 13:50:25Z fingolfin $
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
	[myMatrix release];
	[arrayMatrix release];
	myMatrix = nil;
	arrayMatrix = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

- (MatrixData *)theMatrix
{
	return myMatrix;
}

- (NSArray*)draggedRows
{
	return draggedRows;
}

-(void)awakeFromNib
{
	NSArray *upArray;
	NSArray *downArray;
	[hstep setMaxValue:MATSIZE];
	[vstep setMaxValue:MATSIZE];
	myMatrix=[[MatrixData alloc]init];
	int j;
	for (j = 0; j < MATSIZE; j++) {
		[myMatrix addRow];
	}
	
	while ([myMatrix colCount]<MATSIZE) {
		[myMatrix addCol];
		MatrixTableColumn *newcol;
		newcol = [[MatrixTableColumn alloc] initWithIdentifier:[[NSNumber numberWithInt:[myMatrix colCount]-1] stringValue]];
		[[newcol headerCell] setStringValue:[[NSNumber numberWithInt:[myMatrix colCount]] stringValue]];
		[newcol setMinWidth:40];
		[newcol setWidth:60];
		[matrixtable addTableColumn:newcol];
	}

	[myMatrix setActRows:3];
	[myMatrix setActCols:3];
	
	upArray = [NSArray arrayWithObjects:[NSNumber numberWithFloat:2.0], nil];
	downArray = [NSArray arrayWithObjects:[NSNumber numberWithFloat:.5], nil];
		
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

	arrayMatrix = [[NSArray alloc] initWithArray:[matrixDictionary objectForKey:@"Matrix" ]];

	notifcenter = [NSNotificationCenter defaultCenter];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [myMatrix rowCount];
}

// Mandatory tableview data source method
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString  *theValue, *colid;
	colid = [tableColumn identifier];
	NSParameterAssert(row >= 0 && row < [myMatrix rowCount]);
	if ([colid isEqualToString:@"col"]) {
		return [NSNumber numberWithInt:row+1];
	} else {
		theValue = [myMatrix objectInRow:row inCol:[colid intValue]];
		return theValue;
	}

}
- (void)tableViewColumnDidMove:(NSNotification *)aNotification
{
	[matrixtable reloadData];
	[matrixtable setNeedsDisplay];
}

- (void)tableView:(NSTableView *)tv setObjectValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(int)row
{
	[myMatrix replaceObjectInRow:row inCol:[[tc identifier] intValue] withObject:objectValue];
}

	// when a drag-and-drop operation comes through, and a filename is being dropped on the table,
	// we need to tell the table where to put the new filename (right at the end of the table).
	// This controls the visual feedback to the user on where their drop will go.
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
	[tv setDropRow:row dropOperation:NSTableViewDropAbove];
	return [info draggingSourceOperationMask];
}

- (BOOL) tableView:(NSTableView*)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard *)pboard
{
	int i;
	NSMutableArray *j = [NSMutableArray array];
	[pboard declareTypes:[NSArray arrayWithObject:MatPboardType] owner:self];
	
	for (i = 0; i < [rows count]; i++) {
		[j addObject:[myMatrix myRowAtIndex:[[rows objectAtIndex:i] intValue]]];
	}
	[pboard setPropertyList:j forType:MatPboardType];
	draggedRows = j;
	
	return YES;
	
}


// This routine does the actual processing for a drag-and-drop operation on a tableview.
// As the tableview's data source, we get this call when it's time to update our backend data.
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
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
	int i;
	
	// find the best match of the types we'll accept and what's actually on the pasteboard
	availableType=[myPasteboard availableTypeFromArray:typeArray];
	// In the file format type that we're working with, get all data on the pasteboard
	_draggedrows=[myPasteboard propertyListForType:availableType];
	
	for (i = 0; i < [_draggedrows count]; i++) {
		matRow = [_draggedrows objectAtIndex:i];
		if (row > [[myMatrix rows] indexOfObjectIdenticalTo:[[[[info draggingSource] dataSource] draggedRows] objectAtIndex:i]])
			row--;
		[[myMatrix rows] removeObjectIdenticalTo:[[[[info draggingSource] dataSource] draggedRows] objectAtIndex:i]];
		
		[[myMatrix rows] insertObject:matRow atIndex:row+i];
	}
	for (i = 0; i < [_draggedrows count]; i++) {
		matRow = [_draggedrows objectAtIndex:i];
		[indset addIndex:[[myMatrix rows] indexOfObjectIdenticalTo:matRow]];
	}
	
	[matrixtable reloadData];
	[matrixtable selectRowIndexes:indset byExtendingSelection:NO];
	
	return YES;
}



- (IBAction)resizeMatrix:(id)sender
{
	int ival = [sender intValue];
	if (ival > MATSIZE)
		ival = MATSIZE;
	else if (ival < 1)
		ival = 1;

	if ((sender == hstep) || (sender == htf)) {
		while ((ival != [myMatrix actCols]) && (ival <= MATSIZE) && (ival > 0)) {
			if (ival > [myMatrix actCols]) {
				[myMatrix setActCols:[myMatrix actCols]+1];
			} else {
				[myMatrix setActCols:[myMatrix actCols]-1];
				
			}
		}
		
		if (sender == hstep)
			[htf setIntValue:[myMatrix actCols]];
		else {
			[hstep setIntValue:[myMatrix actCols]];
			[htf setIntValue:[myMatrix actCols]];
		}
		
	} else if ((sender == vstep) || (sender == vtf)) {
		
		while ((ival != [myMatrix actRows]) && (ival <= MATSIZE) && (ival > 0)) {
			if (ival > [myMatrix actRows]) {
				[myMatrix setActRows:[myMatrix actRows]+1];
			} else {
				[myMatrix setActRows:[myMatrix actRows]-1];
			}
		}
		
		if (sender == vstep)
			[vtf setIntValue:[myMatrix actRows]];
		else {
			[vstep setIntValue:[myMatrix actRows]];
			[vtf setIntValue:[myMatrix actRows]];
		}
		
	}
	[matrixtable reloadData];
}

- (IBAction)insertMatrix:(id)sender
{
	NSMutableString *insertion = [NSMutableString stringWithCapacity:200];
	int i, j;
	int brstyleop = [[brselop selectedCell] tag];
	int brstylecl = [[brselcl selectedCell] tag];
	int environment = [[envsel selectedCell] tag];
	int tablenv = ([chbfig state] == NSOnState);
	int drawborder = ([borderbutton state] == NSOnState);
	int drawgrid = ([gridbutton state] == NSOnState);
	int hsize = [myMatrix actCols];
	int vsize = [myMatrix actRows];

	if (environment == 0) {
		if ((brstyleop == 4) && (brstylecl == 4)) {
		} else {
			[insertion appendString:[arrayMatrix objectAtIndex:6]];
			if (brstyleop == 0) {
				[insertion appendString:[arrayMatrix objectAtIndex:8]];
			} else if (brstyleop == 1) {
				[insertion appendString:[arrayMatrix objectAtIndex:10]];
			} else if (brstyleop == 2) {
				[insertion appendString:[arrayMatrix objectAtIndex:12]];
			} else if (brstyleop == 3) {
				[insertion appendString:[arrayMatrix objectAtIndex:14]];
			} else if (brstyleop == 5) {
				[insertion appendString:[arrayMatrix objectAtIndex:15]];
				[insertion appendString:[brtfop stringValue]];
			} else if (brstyleop == 4) {
				[insertion appendString:[arrayMatrix objectAtIndex:15]];
			} else if (brstylecl == 6) {
				[insertion appendString:[arrayMatrix objectAtIndex:16]];
			}

		}
	}

	if (environment == 0) {
		[insertion appendString:[arrayMatrix objectAtIndex:0]];
	} else {
		if (tablenv) {
			[insertion appendString:[arrayMatrix objectAtIndex:20]];
		}
		[insertion appendString:[arrayMatrix objectAtIndex:17]];
	}

	if (drawborder)
		[insertion appendString:[arrayMatrix objectAtIndex:14]];

	for (i = 0; i < hsize; i++)  {
		[insertion appendString:[arrayMatrix objectAtIndex:1]];
		if ((drawgrid) && (i<hsize-1))
			[insertion appendString:[arrayMatrix objectAtIndex:14]];
	}
	if (drawborder)
		[insertion appendString:[arrayMatrix objectAtIndex:14]];

	[insertion appendString:[arrayMatrix objectAtIndex:2]];
	if (drawborder)
		[insertion appendString:[arrayMatrix objectAtIndex:19]];

	for (j = 0; j < vsize; j++) {
		for (i = 0; i < hsize; i++) {
			[insertion appendString:[myMatrix objectInRow:j inCol:[[[[matrixtable tableColumns] objectAtIndex:i] identifier] intValue] ]];
			if (i < hsize-1)
				[insertion appendString:[arrayMatrix objectAtIndex:3]];
		}
		if (j < vsize-1) {
			[insertion appendString:[arrayMatrix objectAtIndex:4]];
			if (drawgrid)
				[insertion appendString:[arrayMatrix objectAtIndex:19]];
		}

	}
	if (drawborder) {
		[insertion appendString:[arrayMatrix objectAtIndex:4]];
		[insertion appendString:[arrayMatrix objectAtIndex:19]];
	}

	if (environment == 0) {
		[insertion appendString:[arrayMatrix objectAtIndex:5]];
	} else {
		[insertion appendString:[arrayMatrix objectAtIndex:18]];
		if (tablenv) {
			[insertion appendString:[arrayMatrix objectAtIndex:21]];
		}

	}

	if (environment == 0) {
		if ((brstyleop == 4) && (brstylecl == 4)) {
		} else {
			[insertion appendString:[arrayMatrix objectAtIndex:7]];
			if (brstylecl == 0) {
				[insertion appendString:[arrayMatrix objectAtIndex:9]];
			} else if (brstylecl == 1) {
				[insertion appendString:[arrayMatrix objectAtIndex:11]];
			} else if (brstylecl == 2) {
				[insertion appendString:[arrayMatrix objectAtIndex:13]];
			} else if (brstylecl == 3) {
				[insertion appendString:[arrayMatrix objectAtIndex:14]];
			} else if (brstylecl == 5) {
				[insertion appendString:[arrayMatrix objectAtIndex:15]];
				[insertion appendString:[brtfcl stringValue]];
			} else if (brstylecl == 4) {
				[insertion appendString:[arrayMatrix objectAtIndex:15]];
			} else if (brstylecl == 6) {
				[insertion appendString:[arrayMatrix objectAtIndex:16]];
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
	int i, j, action;
	int mwdth, mhght;
	mwdth = [myMatrix colCount];
	mhght = [myMatrix rowCount];
	
	if (sender == matmod) {
		action = [[sender selectedCell] tag];
		if (action == 2) {
			for (i = 0; i < mhght; i++) {
				for (j = 0; j < mwdth; j++) {
					[myMatrix replaceObjectInRow:i inCol:j withObject:@"0"];
				}
			}
		} else if (action == 0) {
			for (i = 0; i < mhght; i++) {
				for (j = 0; j < mwdth; j++) {
					[myMatrix replaceObjectInRow:i inCol:j withObject:@" "];
				}
			}
		} else {
			for (i = 0; i < mhght; i++) {
				for (j = 0; j < mwdth; j++) {
					[myMatrix replaceObjectInRow:i inCol:j withObject:@"0"];
				}
			}
			for(i = 0; (i < mwdth) && (i < mhght); i++)
				[myMatrix replaceObjectInRow:i inCol:[[[[matrixtable tableColumns]objectAtIndex:i] identifier] intValue] withObject:@"1"];
			
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
	[[[NSApp windowsMenu] itemWithTitle:NSLocalizedString(@"Close Matrix Panel", @"Close Matrix Panel")] setTitle:NSLocalizedString(@"Matrix Panel...", @"Matrix Panel...")];
}

- (void)panelDidMove:(NSNotification *)notification
{
	NSRect	myFrame;
	float	x, y;

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
		rows = [[NSMutableArray alloc] init];
		activeRows = 0;
		activeCols = 0;
	}
	return self;
}

- (void)dealloc
{
	[rows release];
	[super dealloc];
}

- (NSMutableArray*)rows
{
	return rows;
}

- (int)actRows
{
	return activeRows;
}

-(void)setActRows:(int)num
{
	activeRows=num;
}

- (int)actCols
{
	return activeCols;
}

-(void)setActCols:(int)num
{
	activeCols = num;
}

-(id)myRowAtIndex:(unsigned)row
{
	return [[rows objectAtIndex:row]retain];
}

-(int)rowCount
{
	return [rows count];
}

-(int)colCount
{
	if ([self rowCount]==0)
		return 0;
	return [[self myRowAtIndex:0] count];
}

-(id)objectInRow:(unsigned)row inCol:(unsigned)col
{
	return [[self myRowAtIndex:row] objectAtIndex:col];
}

-(void)replaceObjectInRow:(unsigned)row inCol:(unsigned)col withObject:(id) anObj{
	[[self myRowAtIndex:row] replaceObjectAtIndex:col withObject:anObj];
}

-(void)addRow
{
	int i;
	[rows addObject:[[NSMutableArray arrayWithCapacity:[self colCount]]retain]];
	for (i = [[rows objectAtIndex:[rows count]-1] count]; i < [self colCount]; i++) {
		[[rows objectAtIndex:[rows count]-1] addObject:@"0"];
	}
	activeRows++;

}

- (void)insertRow:(NSMutableArray*)row atIndex:(int)ind
{
	[rows insertObject:row atIndex:ind];
}

- (void)removeRow:(id )row
{
	[rows removeObject:row];
}

- (void)removeRowIdenticalTo:(id)row
{
	[rows removeObjectIdenticalTo:row];
}

- (void)removeRowAtIndex:(unsigned int )ind
{
	[rows removeObjectAtIndex:ind];
}

-(void)addCol
{
	int i;
	for (i = 0; i < [self rowCount]; i++) {
 		[[self myRowAtIndex:i] addObject:@"0"];
	}
	activeCols++;
}

-(void)removeLastCol
{
	int i;
	for (i = 0; i < [self rowCount]; i++) {
		[[self myRowAtIndex:i] removeLastObject];
	}
	activeCols--;
}

-(void)removeLastRow
{
	[rows removeLastObject];
	activeRows--;
}

@end
