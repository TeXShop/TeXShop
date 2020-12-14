/*
 * Name: OgreOutlineView.h
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


@interface OgreOutlineView : NSOutlineView <OgreView>
{
    NSInteger   _ogreSelectedColumn;
    id          _ogreSelectedItem;
    NSRange     _ogreSelectedRange;
    
    NSMutableArray  *_ogrePathComponents;
}

- (NSInteger)ogreSelectedColumn;
- (void)ogreSetSelectedColumn:(NSInteger)column;

- (NSArray*)ogrePathComponentsOfSelectedItem;
- (void)ogreSetSelectedItem:(id)item;

- (NSRange)ogreSelectedRange;
- (void)ogreSetSelectedRange:(NSRange)aRange;

@end
