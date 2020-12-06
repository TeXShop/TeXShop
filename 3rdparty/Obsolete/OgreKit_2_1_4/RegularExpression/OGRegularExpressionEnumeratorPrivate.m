/*
 * Name: OGRegularExpressionEnumeratorPrivate.m
 * Project: OgreKit
 *
 * Creation Date: Sep 03 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionMatchPrivate.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGRegularExpressionEnumeratorPrivate.h>
#import <OgreKit/OGString.h>


@implementation OGRegularExpressionEnumerator (Private)

- (id) initWithOGString:(NSObject<OGStringProtocol>*)targetString 
	options:(unsigned)searchOptions 
	range:(NSRange)searchRange 
	regularExpression:(OGRegularExpression*)regex
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithOGString: of %@", [self className]);
#endif
	self = [super init];
	if (self) {
		// �����Ώە������ێ�
		// target string��UTF16������ɕϊ�����B
		_targetString = [targetString copy];
		NSString	*targetPlainString = [_targetString string];
        _lengthOfTargetString = [_targetString length];
        
        _UTF16TargetString = (unichar*)NSZoneMalloc([self zone], sizeof(unichar) * (_lengthOfTargetString + 4));	// +4��oniguruma��memory access violation���ւ̑Ώ��Ö@
        if (_UTF16TargetString == NULL) {
            // ���������m�ۂł��Ȃ������ꍇ�A��O�𔭐�������B
            [self release];
            [NSException raise:NSMallocException format:@"fail to allocate a memory"];
        }
        [targetPlainString getCharacters:_UTF16TargetString range:NSMakeRange(0, _lengthOfTargetString)];
            
        /* DEBUG 
        {
            NSLog(@"TargetString: '%@'", _targetString);
            int     i, count = _lengthOfTargetString;
            unichar *utf16Chars = _UTF16TargetString;
            for (i = 0; i < count; i++) {
                NSLog(@"UTF16: %04x", *(utf16Chars + i));
            }
        }*/
        
		// �����͈�
		_searchRange = searchRange;
		
		// ���K�\���I�u�W�F�N�g��ێ�
		_regex = [regex retain];
		
		// �����I�v�V����
		_searchOptions = searchOptions;
		
		/* �����l�ݒ� */
		// �Ō�Ƀ}�b�`����������̏I�[�ʒu
		// �����l 0
		// �l >=  0 �I�[�ʒu
		// �l == -1 �}�b�`�I��
		_terminalOfLastMatch = 0;
		
		// �}�b�`�J�n�ʒu
		_startLocation = 0;
	
		// �O��̃}�b�`���󕶎��񂾂������ǂ���
		_isLastMatchEmpty = NO;
		
		// �}�b�`������
		_numberOfMatches = 0;
	}
	
	return self;
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
#ifdef DEBUG_OGRE
	NSLog(@"-finalize of %@", [self className]);
#endif
	NSZoneFree([self zone], _UTF16TargetString);
    [super finalize];
}
#endif

- (void)dealloc
{
#ifdef DEBUG_OGRE
	NSLog(@"-dealloc of %@", [self className]);
#endif
	[_regex release];
	NSZoneFree([self zone], _UTF16TargetString);
	[_targetString release];
	
	[super dealloc];
}

/* accessors */
// private
- (void)_setTerminalOfLastMatch:(int)location
{
	_terminalOfLastMatch = location;
}

- (void)_setIsLastMatchEmpty:(BOOL)yesOrNo
{
	_isLastMatchEmpty = yesOrNo;
}

- (void)_setStartLocation:(unsigned)location
{
	_startLocation = location;
}

- (void)_setNumberOfMatches:(unsigned)aNumber
{
	_numberOfMatches = aNumber;
}

- (OGRegularExpression*)regularExpression
{
	return _regex;
}

- (void)setRegularExpression:(OGRegularExpression*)regularExpression
{
	[regularExpression retain];
	[_regex release];
	_regex = regularExpression;
}

// public?
- (NSObject<OGStringProtocol>*)targetString
{
	return _targetString;
}

- (unichar*)UTF16TargetString
{
	return _UTF16TargetString;
}

- (NSRange)searchRange
{
	return _searchRange;
}


@end
