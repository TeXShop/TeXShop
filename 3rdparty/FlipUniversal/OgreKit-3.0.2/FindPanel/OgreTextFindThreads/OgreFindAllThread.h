/*
 * Name: OgreFindAllThread.h
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

#import <OgreKit/OgreTextFindThread.h>

@class OGRegularExpressionMatch, OGRegularExpressionEnumerator, OgreFindResult;
@class OgreTextFindThread;

@interface OgreFindAllThread : OgreTextFindThread 
{
    OGRegularExpressionMatch        *match, *lastMatch;
    NSEnumerator                    *matchEnumerator;
    OgreFindResultBranch <OgreFindResultCorrespondingToTextFindLeaf>    *result;
    NSUInteger                      searchLength;
    
    NSString                        *progressMessage, *progressMessagePlural, *remainingTimeMesssage;
}

@end
