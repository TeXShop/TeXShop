/*
 * Name: OGRegularExpressionEnumerator.h
 * Project: OgreKit
 *
 * Creation Date: Sep 03 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>

@class OGRegularExpression;

// Exception
extern NSString	* const OgreEnumeratorException;

@interface OGRegularExpressionEnumerator : NSEnumerator <NSCopying, NSCoding>
{
	OGRegularExpression	*_regex;				// ���K�\���I�u�W�F�N�g
	NSObject<OGStringProtocol>			*_targetString;			// �����Ώە�����
	unichar             *_UTF16TargetString;	// UTF16�ł̌����Ώە�����
	NSUInteger			_lengthOfTargetString;	// [_targetString length]
	NSRange				_searchRange;			// �����͈�
	OnigOptionType		_searchOptions;			// �����I�v�V����
	NSInteger			_terminalOfLastMatch;	// �O��Ƀ}�b�`����������̏I�[�ʒu  (_region->end[0] / sizeof(unichar))
	NSUInteger			_startLocation;			// �}�b�`�J�n�ʒu
	BOOL				_isLastMatchEmpty;		// �O��̃}�b�`���󕶎��񂾂������ǂ���
	
	NSUInteger			_numberOfMatches;		// �}�b�`������
}

// �S�}�b�`���ʂ�z��ŕԂ��B
- (NSArray*)allObjects;
// ���̃}�b�`���ʂ�Ԃ��B
- (id)nextObject;

// description
- (NSString*)description;

@end
