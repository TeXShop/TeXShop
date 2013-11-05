//
//  TSStationery.m
//  TeXShop
//
//  Created by Richard Koch on 7/8/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "TSStationery.h"
#import "Globals.h"


@implementation TSStationery

- (id)init
{
	id result = [super init];
	sourceData = nil;
	fullSourceData = nil;
	commentData = nil;
	return result;
}

- (void)dealloc
{
	if (sourceData)
		[sourceData release];
	if (fullSourceData)
		[fullSourceData release];
	if (commentData)
		[commentData release];
	[super dealloc];
}	

- (IBAction)newFromStationery: (id)sender
{
	NSString			*title, *title1, *path, *comment;
	BOOL				isDirectory;
	NSInteger					i;
	NSStringEncoding	enc;
	
	if (sourceData == nil) {
		
		sourceData = [[NSMutableArray alloc] initWithCapacity:10];
		[sourceData retain];
		fullSourceData = [[NSMutableArray alloc] initWithCapacity:10];
		[fullSourceData retain];
		commentData = [[NSMutableArray alloc] initWithCapacity:10];
		[commentData retain];
		
		NSFileManager *fileManager = [ NSFileManager defaultManager ];
		NSString *basePath = [ StationeryPath stringByStandardizingPath ];
		NSArray *files = [ fileManager contentsOfDirectoryAtPath:basePath error: nil];
		
		for (i = 0; i < [files count]; i++) {
			title = [ files objectAtIndex: i ];
			path  = [ basePath stringByAppendingPathComponent: title ];
			if (([fileManager fileExistsAtPath:path isDirectory: &isDirectory]) && (! isDirectory)) {
				if ([ [[title pathExtension] lowercaseString] isEqualToString: @"tex"]) {
					title1 = [title stringByDeletingPathExtension];
					[sourceData addObject: title1];
					[fullSourceData addObject: title];
					path = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"comment"];
					if (([fileManager fileExistsAtPath:path isDirectory: &isDirectory]) && (! isDirectory)) {
						comment = [NSString stringWithContentsOfFile:path usedEncoding:&enc error: nil];
						if (comment)
							[commentData addObject: comment];
						else 
							[commentData addObject:@" "];
					}
					else 
						[commentData addObject:@" "];
					
				}
			}
		}
	}
	
	[stationeryWindow makeKeyAndOrderFront:self];
	[tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [sourceData count];
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
			row:(NSInteger)row
{
	if ([[tableColumn identifier] isEqualToString:@"Description"])
		return [commentData objectAtIndex: row];
	else
		return [sourceData objectAtIndex: row];
}



- (void) okForStationeryPanel: sender
{
	NSDocumentController	*myController;
	NSURL					*myURL;
	NSInteger						index1;
	
	index1 = [tableView selectedRow];
	[stationeryWindow close];
	if (index1 >= 0) {
		NSString *basePath = [ StationeryPath stringByStandardizingPath ];
		NSString *fullPath = [basePath stringByAppendingPathComponent: [fullSourceData objectAtIndex: index1]];
		// NSLog([sourceData objectAtIndex:index]);
		// NSLog(fullPath);
		myURL = [NSURL fileURLWithPath: fullPath];
		myController = [NSDocumentController sharedDocumentController];
		id theDocument = [myController openDocumentWithContentsOfURL: myURL display:YES error:nil];
		[theDocument setFileURL: nil];
		[[theDocument window] setDocumentEdited: YES];
		
	}
	
}

- (void) cancelForStationeryPanel: sender
{
	[stationeryWindow close];
}


- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
{
	return NO;
}


@end
