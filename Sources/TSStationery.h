//
//  TSStationery.h
//  TeXShop
//
//  Created by Richard Koch on 7/8/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NSInteger NSInteger;



@interface TSStationery : NSObject {
	
	IBOutlet NSPanel	*stationeryWindow;
	IBOutlet NSTableView *tableView;
//	NSMutableArray		*fullSourceData;
//	NSMutableArray		*sourceData;
//	NSMutableArray		*commentData;
	
}

@property (retain) NSMutableArray		*fullSourceData;
@property (retain)NSMutableArray		*sourceData;
@property (retain)NSMutableArray		*commentData;

- (IBAction)newFromStationery: (id)sender;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
			row:(NSInteger)row;


- (IBAction)okForStationeryPanel:(id)sender;
- (IBAction)cancelForStationeryPanel:(id)sender;
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

@end
