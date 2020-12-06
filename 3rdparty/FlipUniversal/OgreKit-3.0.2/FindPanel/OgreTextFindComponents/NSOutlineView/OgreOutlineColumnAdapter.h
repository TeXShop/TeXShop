/*
 * Name: OgreOutlineColumnAdapter.h
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

@class OgreOutlineColumn;

@interface OgreOutlineColumnAdapter : OgreTextFindBranch 
{
    OgreOutlineColumn   *_outlineColumn;
}

- (id)initWithOutlineColumn:(OgreOutlineColumn*)anOutlineColumn;
- (void)expandItemEnclosingItem:(id)item;   // dummy

@end
