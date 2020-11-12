/*
 * Name: OgreTableCellAdapter.h
 * Project: OgreKit
 *
 * Creation Date: Jun 05 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreTextFindBranch.h>
#import <OgreKit/OgreTextFindLeaf.h>

@class OgreTableColumn;

@interface OgreTableCellAdapter : OgreTextFindLeaf
{
    OgreTableColumn *_tableColumn;
    NSInteger       _rowIndex;
}

- (id)initWithTableColumn:(OgreTableColumn*)tableColumn row:(NSInteger)rowIndex;

@end
