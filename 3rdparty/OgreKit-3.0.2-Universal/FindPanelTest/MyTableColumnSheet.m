/*
 * Name: MyTableColumnSheet.m
 * Project: OgreKit
 *
 * Creation Date: Jun 01 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyTableColumnSheet.h"


@implementation MyTableColumnSheet

- (id)initWithParentWindow:(NSWindow*)parentWindow tableColumn:(NSTableColumn*)aColumn OKSelector:(SEL)OKSelector CancelSelector:(SEL)CancelSelector target:(id)aTarget
{
    self = [super init];
    if (self != nil) {
        _parentWindow = parentWindow;
        _column = [aColumn retain];
        _okSelector = OKSelector;
        _cancelSelector = CancelSelector;
        _target = aTarget;
        
        NSArray*    topLevelObjects = [NSArray new];
        [[NSBundle mainBundle] loadNibNamed:@"MyTableColumnSheet" owner:self topLevelObjects:&topLevelObjects];
    }
    
    return self;
}

- (void)awakeFromNib
{
	[self retain];
    NSString    *oldTitle = [[_column headerCell] stringValue];
    [oldTitleField setStringValue:oldTitle];
    [newTitleField setStringValue:oldTitle];
    [_parentWindow beginSheet:columnSheet completionHandler:^(NSModalResponse returnCode) {
        [self sheetDidEnd:columnSheet returnCode:returnCode contextInfo:nil];
    }];
}

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(NSModalResponse)returnCode contextInfo:(void*)contextInfo
{
	[self release];
}

- (void)dealloc
{
    [_column release];
    [super dealloc];
}

- (IBAction)cancel:(id)sender
{
	[_target performSelector:_cancelSelector withObject:self];
    [NSApp endSheet:columnSheet returnCode:0];
    [columnSheet orderOut:nil];
}

- (IBAction)ok:(id)sender
{
	[_target performSelector:_okSelector withObject:self];
    [NSApp endSheet:columnSheet returnCode:0];
    [columnSheet orderOut:nil];
}

- (NSString*)newTitle
{
    return [newTitleField stringValue];
}

- (NSTableColumn*)tableColumn
{
    return _column;
}


@end
