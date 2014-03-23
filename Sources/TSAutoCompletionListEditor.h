// TSAutoCompletionListEditor.h
// Created by Terada, Apr 2011

#import <Cocoa/Cocoa.h>
#import "TSListEditorTableView.h"

@interface TSAutoCompletionListEditor : NSObject {
	IBOutlet NSWindow *window;
	IBOutlet NSTextField *newKeyField;
	IBOutlet NSTextField *newValueField;
	IBOutlet TSListEditorTableView *tableView;
//	NSMutableArray *autocompletionKeys;
//	NSMutableArray *autocompletionValues;
}

@property (retain) 	NSMutableArray *autocompletionKeys;
@property (retain)  NSMutableArray *autocompletionValues;

- (IBAction)openAutoCompletionListEditor: (id)sender;
- (IBAction)savePressed:(id)sender;
- (IBAction)cancelPressed:(id)sender;
- (IBAction)removePressed:(id)sender;
- (IBAction)addPressed:(id)sender;
- (void)removeDraggedOutRows;
- (void)removeObjectsAtIndexes:(NSIndexSet*)indexes;
@end
