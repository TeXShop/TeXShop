//
//  Matrixcontroller.m
//
//  Created by Jonas Zimmermann on Fri Nov 28 2003.
//  Copyright (c) 2001 __NorignalSoft__. All rights reserved.
//

#import "Matrixcontroller.h"
#import "MatrixTableView.h"
#import "TSWindowManager.h"


#import "globals.h"
#define MatPboardType 	@"MatrixRowPboardType"
#define MATSIZE 10

@implementation Matrixcontroller


static id _sharedInstance = nil;

+ (id)sharedInstance
{
    if (_sharedInstance == nil)
    {
        _sharedInstance = [[Matrixcontroller alloc] initWithWindowNibName:@"matrixpanel"];
    }
    return _sharedInstance;
}
- (void)dealloc {
    [myMatrix release];
    [arrayMatrix release];
 //   [draggedRows release];
 //   draggedRows=nil;
    myMatrix = nil;
    arrayMatrix = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}
- (id)init
{
    id result;
    result = [super init];
    shown = NO;
    return result;
}

- (MatrixData *) theMatrix{
    return myMatrix;
}
- (NSArray*)draggedRows{return draggedRows;}

-(void)awakeFromNib
{
    NSArray *upArray;
    NSArray *downArray;
//    NSString* matrixAutosaveName=@"matrixpanel";
  //  NSRulerMarker *lastRowMarker;
    [hstep setMaxValue:MATSIZE];
    [vstep setMaxValue:MATSIZE];
    myMatrix=[[MatrixData alloc]init];
    int j;
    for ( j=0;j<MATSIZE;j++) {
        [myMatrix addRow];
    }

    while ([myMatrix colCount]<MATSIZE) {
	[myMatrix addCol];
	MatrixTableColumn *newcol;
	newcol=[[MatrixTableColumn alloc] initWithIdentifier:[[NSNumber numberWithInt:[myMatrix colCount]-1] stringValue]];
	[[newcol headerCell] setStringValue:[[NSNumber numberWithInt:[myMatrix colCount]] stringValue]];
	[newcol setMinWidth:40];
	[newcol setWidth:60];
	//[[newcol dataCell] setDrawsBackground:NO];
	//[[newcol inactiveDataCell] setDrawsBackground:NO];
	
	//[[newcol dataCellForRow:0] setEnabled:NO];
	[matrixtable addTableColumn:newcol];
    }
    /*for( j=0;j<[myMatrix rowCount];j++) {
        for( k=0;k<[myMatrix colCount];k++) {
            [myMatrix replaceObjectInRow:j inCol:k withObject:[[NSNumber numberWithInt:j*40+k] stringValue]];
	}
	//[[[[matrixtable tableColumns] objectAtIndex:0] dataCell] setEditable:NO];
    }*/
    [myMatrix setActRows:3];
    [myMatrix setActCols:3];
   /* for (i=0; i< [matrixtable numberOfColumns];i++){
	if (i>=[myMatrix actCols]) [[[matrixtable tableColumns] objectAtIndex:i] setDataCell:[[InactiveTextFieldCell alloc] init]];
	else [[[matrixtable tableColumns] objectAtIndex:i] setDataCell:[[ActiveTextFieldCell alloc] init]];
    }*/
    
/*    for ( i=0; i<[[matrixtable tableColumns] count];i++) {
	id ident=[[[matrixtable tableColumns] objectAtIndex:i] identifier];
    }
*/
    
    upArray = [NSArray arrayWithObjects:[NSNumber numberWithFloat:2.0], nil];
    downArray = [NSArray arrayWithObjects:[NSNumber numberWithFloat:.5], nil];
    
    
    
    [NSRulerView registerUnitWithName:@"Rows" abbreviation:@"rw" 
                        unitToPointsConversionFactor:19 stepUpCycle:upArray stepDownCycle:downArray];
    
    [mtscrv setHasVerticalRuler:YES];
    [mtscrv setRulersVisible:YES];
    [[mtscrv verticalRulerView] setMeasurementUnits:@"Rows"];
   // lastRowMarker=[[NSRulerMarker alloc] initWithRulerView:[mtscrv verticalRulerView] markerLocation:4*19 image:<#(NSImage *)image#> imageOrigin:<#(NSPoint)imageOrigin#>]
   // [[mtscrv verticalRulerView] addMarker:[NSRulerMarker ]
    
    
 //   [matrixtable setAutosaveName:matrixAutosaveName];
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

    
    NSBundle *myBundle=[NSBundle mainBundle];
    
    matrixPath = [MatrixPanelPathKey stringByStandardizingPath];
    matrixPath = [matrixPath stringByAppendingPathComponent:@"matrixpanel_1"];
    matrixPath = [matrixPath stringByAppendingPathExtension:@"plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath: matrixPath]) 
        matrixDictionary=[NSDictionary dictionaryWithContentsOfFile:matrixPath];
    else
        matrixDictionary=[NSDictionary dictionaryWithContentsOfFile:
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
    
    arrayMatrix=[[NSArray alloc] initWithArray:[matrixDictionary objectForKey:@"Matrix" ]];
    
    notifcenter=[NSNotificationCenter defaultCenter];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    int i=[myMatrix rowCount];
    return i;
}

// Mandatory tableview data source method
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    
    NSString  *theValue, *colid;
    colid=[tableColumn identifier];
    NSParameterAssert(row >= 0 && row < [myMatrix rowCount]);
    if ([colid isEqualToString:@"col"]) {
        return [NSNumber numberWithInt:row+1];
    }
    else {
        
        theValue = [myMatrix objectInRow:row inCol:[colid intValue]];
        return theValue;
    }
    
}
- (void)tableViewColumnDidMove:(NSNotification *)aNotification {
    [matrixtable reloadData];
    [matrixtable setNeedsDisplay];
}
- (void)tableView:(NSTableView *)tv setObjectValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(int)row {
    [myMatrix replaceObjectInRow:row inCol:[[tc identifier] intValue] withObject:objectValue];
//        [[matrixRows objectAtIndex:row] setValue:objectValue forKey:[tc identifier]];
    
}

//- (BOOL)tableView:(NSTableView *)tv shouldEditTableColumn:(NSTableColumn *)tc row:(int)row
//{    return NO; }

    // when a drag-and-drop operation comes through, and a filename is being dropped on the table,
    // we need to tell the table where to put the new filename (right at the end of the table).
    // This controls the visual feedback to the user on where their drop will go.
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
    return     [info draggingSourceOperationMask];

    
}

-(BOOL) tableView:(NSTableView*)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard *)pboard {
    int i;
    NSMutableArray *j=[NSMutableArray array];
    [pboard declareTypes:[NSArray arrayWithObject:MatPboardType] owner:self];
    //[pboard setData:[NSData data] forType:MatPboardType];
    for (i=0;i<[rows count];i++) {
	[j addObject:[myMatrix rowAtIndex:[[rows objectAtIndex:i] intValue]]];
	}    
    [pboard setPropertyList:j forType:MatPboardType];
    draggedRows=j;

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
    NSMutableIndexSet* indset=[NSMutableIndexSet indexSet];
    int i;
    
    // find the best match of the types we'll accept and what's actually on the pasteboard
    availableType=[myPasteboard availableTypeFromArray:typeArray];
    // In the file format type that we're working with, get all data on the pasteboard
    _draggedrows=[myPasteboard propertyListForType:availableType];
    
    for (i=0;i<[_draggedrows count];i++)
    {
        matRow=[_draggedrows objectAtIndex:i];
	if (row> [[myMatrix rows] indexOfObjectIdenticalTo:[[[[info draggingSource] dataSource] draggedRows] objectAtIndex:i]]) row--;
	[[myMatrix rows] removeObjectIdenticalTo:[[[[info draggingSource] dataSource] draggedRows] objectAtIndex:i]];
	
        [[myMatrix rows] insertObject:matRow atIndex:row+i];	
    }
    for (i=0;i<[_draggedrows count];i++)
    {        matRow=[_draggedrows objectAtIndex:i];

        [indset addIndex:[[myMatrix rows] indexOfObjectIdenticalTo:matRow]];
		
    }

    [matrixtable reloadData];
    [matrixtable selectRowIndexes:indset byExtendingSelection:NO];
    
    return YES;
}



- (IBAction)resizeMatrix:(id)sender
{ 
    int ival;
    ival=[sender intValue];
    if (ival>MATSIZE) ival=MATSIZE;
    if (ival<1) ival=1;
    if ((sender==hstep)||(sender==htf)) 
    {
        while ((ival!=[myMatrix actCols]) && (ival<=MATSIZE) && (ival>0))
	{
            if (ival>[myMatrix actCols]) 
	    {
                //[myMatrix addCol];
		[myMatrix setActCols:[myMatrix actCols]+1];
                
            }
	    else 
	    {
		[myMatrix setActCols:[myMatrix actCols]-1];
		
	    }
	}
	
	if (sender==hstep) [htf setIntValue:[myMatrix actCols]]; else {
	    [hstep setIntValue:[myMatrix actCols]];
	    [htf setIntValue:[myMatrix actCols]];
	}
	
    }
    else if ((sender==vstep)||(sender==vtf)) 
    {
	
	while ((ival!=[myMatrix actRows]) && (ival<=MATSIZE) && (ival>0))
	{
	    if (ival>[myMatrix actRows]) 
	    {
		[myMatrix setActRows:[myMatrix actRows]+1];

		//[myMatrix addRow];
	    }
	    else {
		[myMatrix setActRows:[myMatrix actRows]-1];

//		[myMatrix removeLastRow];
	    }
	    
	}
	
	if (sender==vstep)  [vtf setIntValue:[myMatrix actRows]]; else {
	    [vstep setIntValue:[myMatrix actRows]];
	    [vtf setIntValue:[myMatrix actRows]];
	}
	
    }
    //   [matrixtable setBackgroundColor:[NSColor colorWithCalibratedWhite:1 alpha:.9]];
    [matrixtable reloadData];
    
    
    //    [rowtable reloadData];
    
    
}

-(IBAction)insertMatrix:(id)sender
{
    
    int hsize,vsize,i,j,
    brstyleop=[[brselop selectedCell] tag],
    brstylecl=[[brselcl selectedCell] tag],
    environment=[[envsel selectedCell] tag],
    tablenv=[chbfig state]==NSOnState,
    drawborder=[borderbutton state]==NSOnState,
    drawgrid=[gridbutton state]==NSOnState;
    hsize =(int) [myMatrix actCols];
    vsize =(int) [myMatrix actRows];
    NSMutableString *insertion=[NSMutableString stringWithCapacity:200];
    
    if (environment==0) {
	if ((brstyleop==4)&&(brstylecl==4)) {
	}else {
	    [insertion appendString:[arrayMatrix objectAtIndex:6]];
	    if (brstyleop==0) {
		[insertion appendString:[arrayMatrix objectAtIndex:8]];
	    } else if (brstyleop==1) {
		[insertion appendString:[arrayMatrix objectAtIndex:10]];
	    } else if (brstyleop==2) {
		[insertion appendString:[arrayMatrix objectAtIndex:12]];
	    } else if (brstyleop==3) {
		[insertion appendString:[arrayMatrix objectAtIndex:14]];
	    } else if (brstyleop==5) {
		//if ((brstylecl!=5)&&(brstylecl!=4))
		[insertion appendString:[arrayMatrix objectAtIndex:15]];
		[insertion appendString:[brtfop stringValue]];
	    } else if (brstyleop==4) {
		[insertion appendString:[arrayMatrix objectAtIndex:15]];
	    } else if (brstylecl==6) {
		[insertion appendString:[arrayMatrix objectAtIndex:16]];
	    }
	    
	}
    }
    
    if (environment==0) {
	[insertion appendString:[arrayMatrix objectAtIndex:0]];
    } else {
	if (tablenv) { [insertion appendString:[arrayMatrix objectAtIndex:20]];}
	[insertion appendString:[arrayMatrix objectAtIndex:17]];
    }
    
    if (drawborder) [insertion appendString:[arrayMatrix objectAtIndex:14]];
    
    for (i=0;i<hsize;i++)  {
	[insertion appendString:[arrayMatrix objectAtIndex:1]];
	if ((drawgrid)&&(i<hsize-1)) 	[insertion appendString:[arrayMatrix objectAtIndex:14]];
    }
    if (drawborder) [insertion appendString:[arrayMatrix objectAtIndex:14]];

    [insertion appendString:[arrayMatrix objectAtIndex:2]];
    if (drawborder) [insertion appendString:[arrayMatrix objectAtIndex:19]];

    for (j=0;j<vsize;j++) {
        for (i=0;i<hsize;i++) {
            [insertion appendString:[myMatrix objectInRow:j inCol:[[[[matrixtable tableColumns] objectAtIndex:i] identifier] intValue] ]];
            if (i<hsize-1) [insertion appendString:[arrayMatrix objectAtIndex:3]];
        }
        if (j<vsize-1) {
	    [insertion appendString:[arrayMatrix objectAtIndex:4]];
	    if (drawgrid) [insertion appendString:[arrayMatrix objectAtIndex:19]];
	}

    }
    if (drawborder) {
	[insertion appendString:[arrayMatrix objectAtIndex:4]];
	[insertion appendString:[arrayMatrix objectAtIndex:19]];
    }
    
    if (environment==0) {
	[insertion appendString:[arrayMatrix objectAtIndex:5]];
    } else {
	[insertion appendString:[arrayMatrix objectAtIndex:18]];
	if (tablenv) { [insertion appendString:[arrayMatrix objectAtIndex:21]];}

    }
    
    if (environment==0) if ((brstyleop==4)&&(brstylecl==4)) {
    }else{
        [insertion appendString:[arrayMatrix objectAtIndex:7]];
        if (brstylecl==0) {
            [insertion appendString:[arrayMatrix objectAtIndex:9]];
        } else if (brstylecl==1) {
            [insertion appendString:[arrayMatrix objectAtIndex:11]];
        } else if (brstylecl==2) {
            [insertion appendString:[arrayMatrix objectAtIndex:13]];
        } else if (brstylecl==3) {
            [insertion appendString:[arrayMatrix objectAtIndex:14]];
        } else if (brstylecl==5) {
            //if ((brstyleop!=4)&&(brstyleop!=5))
            [insertion appendString:[arrayMatrix objectAtIndex:15]];
            [insertion appendString:[brtfcl stringValue]];
        } else if (brstylecl==4) {
            [insertion appendString:[arrayMatrix objectAtIndex:15]];
        } else if (brstylecl==6) {
            [insertion appendString:[arrayMatrix objectAtIndex:16]];
        }
    }
    
        [notifcenter postNotificationName:@"matrixpanel" object:insertion];

    
}

- (IBAction)envselChange:(id)sender{
    if([[sender selectedCell] tag]==1) {
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

- (IBAction)brselChange:(id)sender{
    if ([[sender selectedCell] tag]==5) {
	if (sender==brselop) {
	    [brtfop setEnabled:YES];
	} else {
	    [brtfcl setEnabled:YES];
	}
    } else {
	if (sender==brselop) {
	    [brtfop setEnabled:NO];
	} else {
	    [brtfcl setEnabled:NO];
	}
    }
}

- (IBAction)resetMatrix:(id)sender{
    int i,j,action;
    int mwdth,mhght;
    mwdth=[myMatrix colCount];
    mhght=[myMatrix rowCount];
    
    if (sender==matmod) {
        action=[[sender selectedCell] tag];
        if (action==2) {
            for (i=0; i<mhght;i++) for (j=0;j<mwdth ;j++)
            {
                [myMatrix replaceObjectInRow:i inCol:j withObject:@"0"];
            }
        } else if (action==0) {
            for (i=0; i<mhght;i++) for (j=0;j<mwdth ;j++)
            {
                [myMatrix replaceObjectInRow:i inCol:j withObject:@" "];
            }
        } else {
            for (i=0; i<mhght;i++) for (j=0;j<mwdth ;j++)
            {
                [myMatrix replaceObjectInRow:i inCol:j withObject:@"0"];
            }
                for(i=0;(i<mwdth)&&(i<mhght);i++) 
		    
                    [myMatrix replaceObjectInRow:i inCol:[[[[matrixtable tableColumns]objectAtIndex:i] identifier] intValue] withObject:@"1"];
	    
        }
    }
            [matrixtable reloadData];
            
}



- (void)documentWindowDidBecomeKey:(NSNotification *)note
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
    x = myFrame.origin.x; y = myFrame.origin.y;
    [[NSUserDefaults standardUserDefaults] setFloat:x forKey:MPanelOriginXKey];
    [[NSUserDefaults standardUserDefaults] setFloat:y forKey:MPanelOriginYKey];
    // [[self window] saveFrameUsingName:@"theLatexPanel"];
}

  

@end

@implementation MatrixData

-(id) init {
    self = [super init];
    if (self) {
        rows=[[NSMutableArray alloc] init];
    }
    activeRows=0;
    activeCols=0;
    return self;
}
- (NSMutableArray*)rows{return rows;}

- (int)actRows {
    return activeRows;
}
-(void)setActRows:(int)num {
    activeRows=num;
}
- (int)actCols {
    return activeCols;
}
-(void)setActCols:(int)num {
    activeCols=num;
}
-(NSMutableArray *)rowAtIndex:(unsigned)row {
    return [[rows objectAtIndex:row]retain];
}
-(int)rowCount {
    return [rows count];
}
-(int)colCount {
    if ([self rowCount]==0) return 0; else
    return [[self rowAtIndex:0] count];
}

-(id)objectInRow:(unsigned)row inCol:(unsigned)col{
    return [[self rowAtIndex:row] objectAtIndex:col];
}
-(void)replaceObjectInRow:(unsigned)row inCol:(unsigned)col withObject:(id) anObj{
    [[self rowAtIndex:row] replaceObjectAtIndex:col withObject:anObj];
}
-(void)addRow{
    int i;
    [rows addObject:[[NSMutableArray arrayWithCapacity:[self colCount]]retain]];
    for (i=[[rows objectAtIndex:[rows count]-1] count];i<[self colCount];i++) {
        [[rows objectAtIndex:[rows count]-1] addObject:@"0"];
    }
    activeRows++;
        
}

- (void)insertRow:(NSMutableArray*)row atIndex:(int)ind {
    [rows insertObject:row atIndex:ind];
}

- (void)removeRow:(id )row {
    [rows removeObject:row];
}
- (void)removeRowIdenticalTo:(id)row{
    [rows removeObjectIdenticalTo:row];
}

- (void)removeRowAtIndex:(unsigned int )ind {
    [rows removeObjectAtIndex:ind];
}


-(void)addCol{
    int i;
    for (i=0;i<[self rowCount];i++) {
        [[self rowAtIndex:i] addObject:@"0"];
    }
    activeCols++;
}
-(void)removeLastCol{
    int i;
    for (i=0;i<[self rowCount];i++) {
        [[self rowAtIndex:i] removeLastObject];
    }
    activeCols--;
}
-(void)removeLastRow {
    [rows removeLastObject];
    activeRows--;
}

@end