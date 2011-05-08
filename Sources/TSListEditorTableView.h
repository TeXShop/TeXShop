// TSListEditorTableView.h
// Created by Terada, Apr 2011

#import <Cocoa/Cocoa.h>

@interface NSIndexSet (Extension)
-(uint)countOfIndexesInRange:(NSRange)range;
@end

@interface TSListEditorTableView : NSTableView {
	BOOL	draggingOut; 
	NSPoint	startPoint,offset; 
}
@end
