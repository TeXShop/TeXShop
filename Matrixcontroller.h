//
//  Matrixcontroller.h
//
//  Created by Jonas Zimmermann on Fri Nov 28 2003.
//  Copyright (c) 2001 __CompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
@class MatrixData;

@interface Matrixcontroller : NSWindowController
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

    BOOL shown; //YES if user has chosen to display panel
    
    NSArray *arrayMatrix;
    NSNotificationCenter *notifcenter;
    NSMutableArray	    *draggedRows;

    MatrixData *myMatrix;
    //NSMutableArray *myRows;



}
+ (id)sharedInstance;

- (void)hideWindow:(id)sender;
- (MatrixData *) theMatrix;
- (IBAction)envselChange:(id)sender;
- (IBAction)brselChange:(id)sender;
- (IBAction)insertMatrix:(id)sender;
- (IBAction)resetMatrix:(id)sender;
- (IBAction)resizeMatrix:(id)sender;
- (NSMutableArray*)draggedRows;

@end

@interface MatrixData : NSObject {
    NSMutableArray    *rows;
    int activeRows;
    int activeCols;
}

- (NSMutableArray *)rowAtIndex:(unsigned)row;
- (int)rowCount;
- (int)colCount;
- (id)objectInRow:(unsigned)row inCol:(unsigned)col;
- (id)myRowAtIndex:(unsigned)row;
-(void)replaceObjectInRow:(unsigned)row inCol:(unsigned)col withObject:(id) anObj;
- (void)addRow;
- (void)insertRow:(NSMutableArray*)row atIndex:(int)ind;
- (void)removeRowAtIndex:(unsigned int)ind;
- (void)removeRow:(id)row;
- (void)removeRowIdenticalTo:(id)row;
- (void)addCol;
- (void)removeLastCol;
- (void)removeLastRow;
- (int)actRows;
- (NSMutableArray*)rows;
-(void)setActRows:(int)num;
- (int)actCols;
-(void)setActCols:(int)num;

@end
