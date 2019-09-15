/*
 * Name: OgreOutlineColumnFindResult.h
 * Project: OgreKit
 *
 * Creation Date: Jun 07 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreFindResultBranch.h>

@class OgreOutlineCellFindResult, OgreOutlineItemFindResult, OgreOutlineColumn;

@interface OgreOutlineColumnFindResult : OgreFindResultBranch
{
    OgreOutlineColumn   *_outlineColumn;
    NSMutableArray      *_components;
}

- (id)initWithOutlineColumn:(OgreOutlineColumn*)outlineColumn;
- (void)targetIsMissing;
- (void)expandItemEnclosingItem:(id)item;

- (void)mergeFindResult:(OgreOutlineCellFindResult*)aBranch;
- (void)replaceFindResult:(OgreOutlineItemFindResult*)aBranch withFindResultsFromArray:(NSArray*)resultsArray;

@end
