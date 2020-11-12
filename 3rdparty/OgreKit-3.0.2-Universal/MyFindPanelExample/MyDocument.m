/*
 * Name: MyObject.m
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

#import "MyDocument.h"


@implementation MyDocument

// 検索対象となるTextViewをOgreTextFinderに教える。
// 検索させたくない場合はnilをsetする。
// 定義を省略した場合、main windowのfirst responderがNSTextViewならばそれを採用する。
- (void)tellMeTargetToFindIn:(id)textFinder
{
	[textFinder setTargetToFindIn:textView];
}


/* ここから下はFind Panelに関係しないコード */
- (NSString*)windowNibName {
    return @"MyDocument";
}

- (NSData *)dataOfType:(NSString *)typeName
                 error:(NSError * _Nullable *)outError
{
	// 改行コードを(置換すべきなら)置換し、保存する。
	_tmpString = [textView string];
	if ([OGRegularExpression newlineCharacterInString:_tmpString] != _newlineCharacter) {
		_tmpString = [OGRegularExpression replaceNewlineCharactersInString:_tmpString 
			withCharacter:_newlineCharacter];
	}
	
    return [_tmpString dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError * _Nullable *)outError
{
	// ファイルから読み込む。(UTF8決めうち。)
	id	aString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	// 改行コードの種類を得る。
	_newlineCharacter = [OGRegularExpression newlineCharacterInString:aString];
	if (_newlineCharacter == OgreNonbreakingNewlineCharacter) {
		// 改行のない場合はOgreUnixNewlineCharacterとみなす。
		//NSLog(@"nonbreaking");
		_newlineCharacter = OgreUnixNewlineCharacter;
	}
	
	// 改行コードを(置換すべきなら)置換する。
	if (_newlineCharacter != OgreUnixNewlineCharacter) {
		_tmpString = [[OGRegularExpression replaceNewlineCharactersInString:aString 
			withCharacter:OgreUnixNewlineCharacter] retain];
	} else {
		_tmpString = [aString retain];
	}
	[aString release];
    aString = nil;
	//NSLog(@"newline character: %d (-1:Nonbreaking 0:LF(Unix) 1:CR(Mac) 2:CR+LF(Windows) 3:UnicodeLineSeparator 4:UnicodeParagraphSeparator)", _newlineCharacter, [OgreTextFinder newlineCharacterInString:_tmpString]);
	//NSLog(@"%@", [OGRegularExpression chomp:_tmpString]);
	
    return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController*)controller
{
	if (_tmpString) {
		[textView setString:_tmpString];
		[_tmpString release];
        _tmpString = nil;
	} else {
		_newlineCharacter = OgreUnixNewlineCharacter;	// デフォルトの改行コード
	}
    [super windowControllerDidLoadNib:controller];
}

// 改行コードの変更
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter
{
	_newlineCharacter = aNewlineCharacter;
}

@end
