/*
 * Name: OgreTableView.h
 * Project: OgreKit
 *
 * Creation Date: Jun 13 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <AppKit/AppKit.h>
#import <OgreKit/OgreView.h>


@interface OgreTableView : NSTableView <OgreView>
{
    NSInteger   _ogreSelectedColumn;
    NSInteger   _ogreSelectedRow;
    NSRange     _ogreSelectedRange;
}

- (NSObject <OgreTextFindComponent>*)ogreAdapter;

- (NSInteger)ogreSelectedColumn;
- (void)ogreSetSelectedColumn:(NSInteger)column;

- (NSInteger)ogreSelectedRow;
- (void)ogreSetSelectedRow:(NSInteger)row;

- (NSRange)ogreSelectedRange;
- (void)ogreSetSelectedRange:(NSRange)aRange;

@end
