/*
 * Name: OgreTextViewMatchFindResult.m
 * Project: OgreKit
 *
 * Creation Date: Sep 26 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextViewMatchFindResult.h>


@implementation OgreTextViewMatchFindResult

- (id)name
{
    return [(OgreTextViewFindResult*)[self parent] lineOfMatchedStringAtIndex:[self index]];
}

- (id)outline
{
    return [(OgreTextViewFindResult*)[self parent] matchedStringAtIndex:[self index]]; 
}

- (BOOL)showMatchedString
{
    return [(OgreTextViewFindResult*)[self parent] showMatchedStringAtIndex:[self index]];
}

- (BOOL)selectMatchedString
{
    return [(OgreTextViewFindResult*)[self parent] selectMatchedStringAtIndex:[self index]];
}

@end
