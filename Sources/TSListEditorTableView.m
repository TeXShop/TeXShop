// TSListEditorTableView.m
// Created by Terada, Apr 2011

#import "TSListEditorTableView.h"
#import "TSAutoCompletionListEditor.h"

@implementation NSIndexSet (Extension)
-(NSUInteger)countOfIndexesInRange:(NSRange)range
{
	NSUInteger start, end, count;
	
	if ((range.location == 0) && (range.length == 0)) return 0;	
	
	start	= range.location;
	end		= start + range.length;
	count	= 0;
	
	NSUInteger currentIndex = [self indexGreaterThanOrEqualToIndex:start];
	
	while ((currentIndex != NSNotFound) && (currentIndex < end)){
		count++;
		currentIndex = [self indexGreaterThanIndex:currentIndex];
	}
	
	return count;
}
@end


@implementation TSListEditorTableView
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    return  isLocal ? NSDragOperationEvery : NSDragOperationCopy;
}

- (void)dragImage:(NSImage *)anImage
               at:(NSPoint)imageLoc
           offset:(NSSize)mouseOffset
            event:(NSEvent *)theEvent
       pasteboard:(NSPasteboard *)pboard
           source:(id)sourceObject
        slideBack:(BOOL)slideBack
{
    startPoint = [[self window] convertBaseToScreen:[theEvent locationInWindow]];

    [super dragImage:anImage
                  at:imageLoc
              offset:mouseOffset
               event:theEvent
          pasteboard:pboard
              source:sourceObject
           slideBack:NO];
}

- (void)draggedImage:(NSImage *)anImage
             beganAt:(NSPoint)aPoint
{
    draggingOut = NO;
	
    offset.x = startPoint.x - aPoint.x;
    offset.y = startPoint.y - aPoint.y;
}

- (void)draggedImage:(NSImage *)draggedImage
             movedTo:(NSPoint)screenPoint
{
    BOOL    pointInView;
    NSPoint windowPoint,viewPoint;
    
    windowPoint = [[self window] convertScreenToBase:screenPoint];
    windowPoint.x += offset.x;
    windowPoint.y += offset.y;
    viewPoint = [self convertPoint:windowPoint fromView:nil];
    pointInView = NSPointInRect(viewPoint,[self bounds]);
    if(draggingOut && pointInView)
    {
        [[NSCursor arrowCursor] set];
        draggingOut = NO;
    }
	else if (!pointInView) {
		[[NSCursor disappearingItemCursor] set];
		draggingOut = YES;
	}
}

- (void)draggedImage:(NSImage *)anImage
             endedAt:(NSPoint)aPoint
           operation:(NSDragOperation)operation
{
    if(operation == NSDragOperationNone && draggingOut)
    {
		[(TSAutoCompletionListEditor *)[self dataSource] removeDraggedOutRows];
        NSShowAnimationEffect(NSAnimationEffectPoof,
                              NSMakePoint(aPoint.x + offset.x, aPoint.y + offset.y),
							  NSZeroSize,
                              nil,
                              nil,
                              nil);
        [[NSCursor arrowCursor] set];
		[self selectRowIndexes:nil byExtendingSelection:NO];
    }
}

- (BOOL)isFirstResponder:(NSView *)view
{
    if ([[view window] firstResponder] == view) {
        return YES;
    }
	
	id subview;
	NSEnumerator* enumerator = [[view subviews] objectEnumerator];
    while((subview = [enumerator nextObject])){
        if ([self isFirstResponder:subview]) {
            return YES;
        }
    }
    return NO;
}

- (void)keyDown:(NSEvent *)theEvent
{
	NSUInteger keyCode = [theEvent keyCode];
	NSIndexSet *selectedRows = [self selectedRowIndexes];
	if (keyCode == 51 && [selectedRows count] > 0) { // delete key
		[(TSAutoCompletionListEditor *)[self dataSource] removeObjectsAtIndexes:selectedRows]; 
		[self selectRowIndexes:nil byExtendingSelection:NO];
	}else {
		[super keyDown:theEvent];
	}
}

@end
