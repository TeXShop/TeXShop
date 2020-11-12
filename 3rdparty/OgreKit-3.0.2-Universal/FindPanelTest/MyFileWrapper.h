/*
 * Name: MyFileWrapper.h
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

#import <Foundation/Foundation.h>


@interface MyFileWrapper : NSObject 
{
    NSString        *_name;
    NSString        *_path;
    NSMutableString *_info;
    NSImage         *_icon;
    BOOL            _isDirectory;
    NSMutableArray  *_components;
    MyFileWrapper   *_parent;
}

- (id)initWithName:(NSString*)name path:(NSString*)path parent:(id)parent;
- (NSString*)name;
- (NSString*)path;
- (NSString*)info;
- (NSImage*)icon;
- (BOOL)isDirectory;
- (NSArray*)components;
- (id)componentAtIndex:(NSUInteger)index;
- (NSUInteger)numberOfComponents;
- (void)removeComponent:(id)aComponent;
- (void)remove;

- (void)initComponents;

@end
