/*
 * Name: MyObject.h
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

#import <AppKit/AppKit.h>
#import <OgreKit/OgreKit.h>

@interface MyDocument : NSDocument <OgreTextFindDataSource>
{
	IBOutlet NSTextView		*textView;
	NSString				*_tmpString;
	OgreNewlineCharacter	_newlineCharacter;	// 改行コードの種類
}

// 改行コードの変更
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter;

@end
