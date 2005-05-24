#import "MatrixTableView.h"
#import "Matrixcontroller.h"

// RGB values for stripe color (light blue)
#define STRIPE_RED   (237.0 / 255.0)
#define STRIPE_GREEN (243.0 / 255.0)
#define STRIPE_BLUE  (254.0 / 255.0)
static NSColor *sStripeColor = nil;

@implementation MatrixTableView

/*-(NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    if (isLocal) return NSDragOperationEvery;
    else return NSDragOperationCopy;
}*/

-(BOOL)ignoreModifierKeysWhileDragging{return YES;}

- (void) highlightSelectionInClipRect:(NSRect)rect {
    [self drawStripesInRect:rect];
    [super highlightSelectionInClipRect:rect];
}

-(void) reloadData{
    [super reloadData];
    int i;
    for (i=0; i< [self numberOfColumns];i++){
	if (i>=[[[self dataSource] theMatrix] actCols]) [[[self tableColumns] objectAtIndex:i] setDataCell:[[InactiveTextFieldCell alloc] init]];
	else [[[self tableColumns] objectAtIndex:i] setDataCell:[[ActiveTextFieldCell alloc] init]];
    }
}

-(id)init {
    self=[super init];
    [self setDataSource:[MatrixData init]];
    return self;
}

// draw background of area of tableview, which will be inserted

- (void) drawStripesInRect:(NSRect)clipRect {
    NSRect stripeRect;
    int actCols=[[[self dataSource] theMatrix] actCols];
    int actRows=[[[self dataSource] theMatrix] actRows];
    float fullRowHeight = [self rowHeight] + [self intercellSpacing].height;
    float clipBottom = MIN(NSMaxY(clipRect) , actRows*fullRowHeight);
    float clipRight=0;
    int i;
    NSArray* tableCols;
    
    int firstStripe = clipRect.origin.y / fullRowHeight;
    if (firstStripe < actRows){
     			
	tableCols=[self tableColumns];
	for (i=0; i<actCols;i++) {
	    clipRight+= [[tableCols objectAtIndex:i] width] + [self intercellSpacing].width;
	}
	
    stripeRect.origin.x = clipRect.origin.x;
    stripeRect.origin.y = firstStripe * fullRowHeight;
    stripeRect.size.width = MIN(clipRect.size.width, clipRight-clipRect.origin.x);
    stripeRect.size.height = fullRowHeight;
    // set the color
    if (sStripeColor == nil)
        sStripeColor = [[NSColor colorWithCalibratedRed:STRIPE_RED green:STRIPE_GREEN blue:STRIPE_BLUE alpha:1.0] retain];
    [sStripeColor set];
    // and draw the stripes
    while (stripeRect.origin.y < clipBottom) {
        NSRectFill(stripeRect);
        stripeRect.origin.y += fullRowHeight;
    }
    }
}

@end

@implementation InactiveTextFieldCell 
-(id)init{
    self=[super init];
    [self setTextColor:[NSColor colorWithCalibratedWhite:0.827 alpha:1]];
    [self setEditable:YES];
    [self setEnabled:YES];
    [self setDrawsBackground:YES];
    [self setBackgroundColor:[NSColor colorWithCalibratedRed:1 green:1 blue:.985 alpha:1]];

    return self;
}
@end

@implementation ActiveTextFieldCell 
-(id)init{
    self=[super init];
    //[self setTextColor:[NSColor disabledControlTextColor]];
    [self setEditable:YES];
    [self setDrawsBackground:NO];
   // [self setBackgroundColor:[NSColor blueColor]];

    return self;
}
@end

@implementation MatrixTableColumn 
-(id) init {
    return  [self initWithIdentifier:@"0"];    

}
- (id)initWithIdentifier:(id)identifier{
    self=[super initWithIdentifier:identifier];
    activeRows=0;
    //[_inactiveDataCell init];
    _dataCell=[[ActiveTextFieldCell alloc] init];
    _inactiveDataCell=[[InactiveTextFieldCell alloc] init];
    return self;
}
    
-(id)inactiveDataCell{return _inactiveDataCell;}
-(id)dataCellForRow:(int)row {
   // NSTextFieldCell *acell=[self dataCell];
    if ([self tableView]==nil || row==-1) { return [self dataCell];}
    else {
	if (([[[[self tableView] dataSource] theMatrix] actRows]<=row) ) {
	    return [self inactiveDataCell];
	}
    }
    return [self dataCell];
}

@end
