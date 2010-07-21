//
//  TSStationery.h
//  TeXShop
//
//  Created by Richard Koch on 7/8/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#if __LP64__ || TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
typedef long NSInteger;
#else
typedef int NSInteger;
#endif


@interface TSStationery : NSObject {
	
	IBOutlet NSPanel	*stationeryWindow;
	IBOutlet NSTableView *tableView;
	NSMutableArray		*fullSourceData;
	NSMutableArray		*sourceData;
	NSMutableArray		*commentData;
	
	
}

- (IBAction)newFromStationery: (id)sender;

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
			row:(int)row;


- (IBAction)okForStationeryPanel:(id)sender;
- (IBAction)cancelForStationeryPanel:(id)sender;
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

@end
