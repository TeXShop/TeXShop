/*
 * Name: MyRTFDocument.m
 * Project: OgreKit
 *
 * Creation Date: Sep 29 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyRTFDocument.h"


@implementation MyRTFDocument

// 検索対象となるTextViewをOgreTextFinderに教える。
// 検索させたくない場合はnilをsetする。
// 定義を省略した場合、main windowのfirst responderが検索可能ならばそれを採用する。
- (void)tellMeTargetToFindIn:(id)textFinder
{
	[textFinder setTargetToFindIn:textView];
}


/* ここから下はFind Panelに関係しないコード */
- (NSString*)windowNibName {
    return @"MyRTFDocument";
}

- (id)init
{
    self = [super init];
    if (self != nil) {
		_newlineCharacter = OgreUnixNewlineCharacter;	// デフォルトの改行コード
        _RTFData = [[NSData alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_RTFData release];
    [super dealloc];
}

- (NSData*)rtfData
{
    return _RTFData;
}

- (void)setRtfData:(NSData*)newRTFData
{
    [_RTFData autorelease];
    _RTFData = [newRTFData retain];
}

- (NSData *)dataOfType:(NSString *)typeName
                 error:(NSError * _Nullable *)outError
{
	// 改行コードを(置換すべきなら)置換し、保存する。
    if ([myController isEditing]) [myController commitEditing];
    
    return [self rtfData];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError * _Nullable *)outError
{
    [self setRtfData:data];
    
    return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController*)controller
{
    [super windowControllerDidLoadNib:controller];
}

// 改行コードの変更
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter
{
	_newlineCharacter = aNewlineCharacter;
}

@end
