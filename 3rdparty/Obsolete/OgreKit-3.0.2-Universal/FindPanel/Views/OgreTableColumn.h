/*
 * Name: OgreTableColumn.h
 * Project: OgreKit
 *
 * Creation Date: Jun 13 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <AppKit/AppKit.h>


@interface OgreTableColumn : NSTableColumn 
{
    id              _ogreObservableController;
    NSString        *_ogreControllerKeyOfValueBinding;
    NSMutableString *_ogreModelKeyPathOfValueBinding;
}

- (NSInteger)ogreNumberOfRows;
- (id)ogreObjectValueForRow:(NSInteger)row;
- (void)ogreSetObjectValue:(id)anObject forRow:(NSInteger)row;

@end
