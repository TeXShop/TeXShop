/*
 * Name: OgreOutlineViewAdapter.h
 * Project: OgreKit
 *
 * Creation Date: Jun 06 2004
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

@class OgreOutlineView;

@interface OgreOutlineViewAdapter : OgreTextFindBranch <OgreTextFindTargetAdapter> 
{
    OgreOutlineView *_outlineView;
}

- (id)initWithTarget:(id)anOutlineView;

@end
