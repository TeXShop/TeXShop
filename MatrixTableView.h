/* MatrixTableView */

#import <Cocoa/Cocoa.h>

@interface MatrixTableView : NSTableView
{
    IBOutlet id myController;
}
- (void) drawStripesInRect:(NSRect)clipRect;

@end

@interface InactiveTextFieldCell : NSTextFieldCell 
-(id)init;
@end

@interface ActiveTextFieldCell : NSTextFieldCell 
-(id)init;
@end

@interface MatrixTableColumn : NSTableColumn
{

    NSCell *_inactiveDataCell;
    unsigned int activeRows;
}
-(id)init;
-(id)initWithIdentifier:(id)identifier;
-(id)inactiveDataCell;
@end