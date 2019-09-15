/*
 * Name: OgreReplaceAndFindThread.h
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2004-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreFindThread.h>

@interface OgreReplaceAndFindThread : OgreFindThread 
{
    BOOL    _replacingOnly;
}

- (BOOL)replacingOnly;
- (void)setReplacingOnly:(BOOL)replacingOnly;

@end
