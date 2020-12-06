/*
 * Name: OgreTest.m
 * Project: OgreKit
 *
 * Creation Date: Sep 7 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "OgreTest.h"
#import "Calc.h"

@implementation OgreTest

- (IBAction)match:(id)sender
{
	OGRegularExpression			*rx;
	OGRegularExpressionMatch	*match, *lastMatch = nil;
	int	i;
	
	// キャレットを最後に。
	[resultTextView setSelectedRange: NSMakeRange([[resultTextView string] length], 0)];
	
	// テキストフィールドから読み込む
	NSString	*pattern = [patternTextField stringValue];
	NSString	*str = [targetTextField stringValue];

	// \の代替文字
	NSString	*escapeChar = [escapeCharacterTextField stringValue];
	[OGRegularExpression setDefaultEscapeCharacter:escapeChar];
	// 構文
	[OGRegularExpression setDefaultSyntax:OgreRubySyntax];
	
	/*double	sum = 0;
	NSDate	*processTime;
	for(i = 0; i < 100; i++) {
		processTime = [NSDate date];*/

		// 正規表現オブジェクトの作成
		NS_DURING
			rx = [OGRegularExpression regularExpressionWithString: pattern options: OgreFindNotEmptyOption | OgreCaptureGroupOption | OgreIgnoreCaseOption];
		NS_HANDLER
			// 例外処理
			[resultTextView insertText: [NSString stringWithFormat: @"%@ caught in 'regularExpressionWithString:'\n", [localException name]] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
			[resultTextView insertText: [NSString stringWithFormat: @"reason = \"%@\"\n", [localException reason]] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
			return;
		NS_ENDHANDLER
		
		match = [rx matchInString:str];
		if (match == nil) {
			// マッチしなかった場合
            [resultTextView insertText:@"search fail\n" replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
			return;
		}

	/*sum += -[processTime timeIntervalSinceNow];
	}
	NSLog(@"process time: %fsec/inst", sum/100);*/
	
    /*NSLog(@"regex: %@", [rx description]);
    [NSArchiver archiveRootObject:rx toFile: [@"~/Desktop/rx.archive" stringByExpandingTildeInPath]];
    OGRegularExpression	*rx2 = [NSUnarchiver unarchiveObjectWithFile: [@"~/Desktop/rx.archive" stringByExpandingTildeInPath]];
    NSLog(@"regex2: %@", [rx2 description]);
    rx = rx2;*/
    
	/* 検索 */
	NSEnumerator	*enumerator = [rx matchEnumeratorInString:str];

    /*NSLog(@"enumerator: %@", [enumerator description]);
    [NSArchiver archiveRootObject:enumerator toFile: [@"~/Desktop/en.archive" stringByExpandingTildeInPath]];
    NSEnumerator	*enumerator2 = [NSUnarchiver unarchiveObjectWithFile: [@"~/Desktop/en.archive" stringByExpandingTildeInPath]];
    NSLog(@"enumerator2: %@", [enumerator2 description]);
    enumerator = enumerator2;*/
	
	//[resultTextView setString:@""];
	[resultTextView insertText: [NSString stringWithFormat:@"OgreKit version: %@, OniGuruma version: %@\n", [OGRegularExpression version], [OGRegularExpression onigurumaVersion]] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
	[resultTextView insertText: [NSString stringWithFormat:@"target string: \"%@\", escape character: \"%@\"\n", str, [OGRegularExpression defaultEscapeCharacter]] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
	
	int	matches = 0;
	while((match = [enumerator nextObject]) != nil) {
		if(matches == 0) {
			NSRange	range = [match rangeOfPrematchString];
			[resultTextView insertText: [NSString stringWithFormat:@"prematch string: (%lu-%lu) \"%@\"\n", (unsigned long)range.location, (unsigned long)range.location + range.length, [match prematchString]] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
		} else {
			NSRange	range = [match rangeOfStringBetweenMatchAndLastMatch];
			[resultTextView insertText: [NSString stringWithFormat:@"string between match #%d and match #%d: (%lu-%lu) \"%@\"\n", matches - 1, matches, (unsigned long)range.location, (unsigned long)range.location + range.length, [match stringBetweenMatchAndLastMatch]] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
		}

		for (i = 0; i < [match count]; i++) {
			NSRange	subexpRange = [match rangeOfSubstringAtIndex:i];
			[resultTextView insertText: [NSString stringWithFormat:@"#%ld.%d", [match index], i] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
			if([match nameOfSubstringAtIndex:i] != nil) {
				[resultTextView insertText:[NSString stringWithFormat:@"(\"%@\")", [match nameOfSubstringAtIndex:i]] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
			}
			[resultTextView insertText:[NSString stringWithFormat:@": (%lu-%lu)", (unsigned long)subexpRange.location, (unsigned long)subexpRange.location + subexpRange.length] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
			if([match substringAtIndex:i] == nil) {
				[resultTextView insertText:@" no match!\n" replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
			} else {
				[resultTextView insertText:@" \"" replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
				[resultTextView insertText:[match substringAtIndex:i] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
				[resultTextView insertText:@"\"\n" replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
			}
		}
        
        OGRegularExpressionCapture  *captureHistory = [match captureHistory];
        if (captureHistory != nil) {
            [resultTextView insertText:@"Capture History:\n" replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
            [captureHistory acceptVisitor:self];
        }
        
		/*NSLog(@"match: %@", [match description]);
		[NSArchiver archiveRootObject:match toFile: [@"~/Desktop/mt.archive" stringByExpandingTildeInPath]];
		OGRegularExpressionMatch	*match2 = [NSUnarchiver unarchiveObjectWithFile: [@"~/Desktop/mt.archive" stringByExpandingTildeInPath]];
		NSLog(@"match2: %@", [match2 description]);
		match = match2;*/
        
		matches++;
		lastMatch = match;
	}
	if(lastMatch != nil) {
		NSRange	range = [lastMatch rangeOfPostmatchString];
		[resultTextView insertText: [NSString stringWithFormat:@"postmatch string: (%lu-%lu) \"%@\"\n", (unsigned long)range.location, (unsigned long)range.location + range.length, [lastMatch postmatchString]] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
	} else {
		[resultTextView insertText:@"search fail\n" replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
	}
	[resultTextView insertText:@"\n" replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
	[resultTextView setFont:[NSFont fontWithName:@"Monaco" size:10.0]];
	[resultTextView display];
}

- (IBAction)replace:(id)sender
{
	OGRegularExpression	*rx;
	
	// キャレットを最後に。
	[resultTextView setSelectedRange: NSMakeRange([[resultTextView string] length], 0)];
	
	// テキストフィールドから読み込む
	NSString	*pattern = [patternTextField stringValue];
	NSString	*str     = [targetTextField stringValue];
	NSString	*newStr  = [replaceTextField stringValue];
	
	// \の代替文字
	NSString	*escapeChar = [escapeCharacterTextField stringValue];
	[OGRegularExpression setDefaultEscapeCharacter:escapeChar];
	// 構文
	[OGRegularExpression setDefaultSyntax:OgreRubySyntax];
	
	/*NSDate	*processTime;
	int i;
	double	sum = 0;
	for(i = 0; i < 100; i++) {
		processTime = [NSDate date];*/
		
		// 正規表現オブジェクトの作成
		rx = [OGRegularExpression regularExpressionWithString: pattern options: OgreFindNotEmptyOption | OgreCaptureGroupOption];
		[rx replaceAllMatchesInString:str withString:newStr options:OgreNoneOption];
		
	/*	sum += -[processTime timeIntervalSinceNow];
	}
	NSLog(@"process time: %fsec/inst", sum/100);*/
	
	// 置換
	[resultTextView insertText: [NSString stringWithFormat:@"replaced string: \"%@\"\n", [rx replaceAllMatchesInString:str withString:newStr options:OgreNoneOption]] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
	[resultTextView setFont:[NSFont fontWithName:@"Monaco" size:10.0]];
	[resultTextView display];
}

// 開始処理
- (void)awakeFromNib
{
	[resultTextView setRichText: NO];
	[resultTextView setFont:[NSFont fontWithName:@"Monaco" size:10.0]];
	[resultTextView setContinuousSpellCheckingEnabled:NO];

	[self replaceTest];
	[self categoryTest];
    [self captureTreeTest];
}

- (void)captureTreeTest
{
	NSLog(@"Capture Tree Test");
    NSString    *expr = @"(1+2)*3+4";
    Calc        *calc = [[[Calc alloc] init] autorelease];
    NSLog(@"%@ = %@", expr, [calc eval:expr]);
    
    expr = @"36.5*9/5+32";
    NSLog(@"%@ = %@", expr, [calc eval:expr]);
}

// デリゲートに処理を委ねた置換／マッチした部分での分割
- (void)replaceTest
{
	NSLog(@"Replacement Test");
	
	OGRegularExpression			*regex = [OGRegularExpression regularExpressionWithString:@"a*"];
	NSEnumerator				*matcher = [regex matchEnumeratorInString:@"aaaaaaa" range:NSMakeRange(1, 3)];
	OGRegularExpressionMatch	*match;
	while ((match = [matcher nextObject]) != nil) {
    NSRange matchRange = [match rangeOfMatchedString];
		NSLog(@"(%lu, %lu)", (unsigned long)matchRange.location, (unsigned long)matchRange.length);
	}
	
	// デリゲートに処理を委ねた置換
	NSString	*targetString = @"36.5C, 3.8C, -195.8C";
	NSLog(@"%@", targetString);
	OGRegularExpression	*celciusRegex = [OGRegularExpression regularExpressionWithString:@"([+-]?\\d+(?:\\.\\d+)?)C\\b"];
	NSLog(@"%@", [celciusRegex replaceAllMatchesInString:targetString 
		delegate:self 
		replaceSelector:@selector(fahrenheitFromCelsius:contextInfo:) 
		contextInfo:nil]);
	
	// 文字列を分割する
	OGRegularExpression	*delimiterRegex = [OGRegularExpression regularExpressionWithString:@"\\s*,\\s*"];
	NSLog(@"%@", [[delimiterRegex splitString:targetString] description]);
}

- (void)categoryTest
{
	NSLog(@"NSString (OgreKitAdditions) Test");
	NSString	*string = @"36.5C, 3.8C, -195.8C";
	NSLog(@"%@", [[string componentsSeparatedByRegularExpressionString:@"\\s*,\\s*"] description]);
	NSMutableString *mstr = [NSMutableString stringWithString:string];
	NSUInteger	numberOfReplacement = [mstr replaceOccurrencesOfRegularExpressionString:@"C"
		withString:@"F" options:OgreNoneOption range:NSMakeRange(0, [string length])];
	NSLog(@"%ld %@", numberOfReplacement, mstr);
	NSRange matchRange = [string rangeOfRegularExpressionString:@"\\s*,\\s*"];
	NSLog(@"(%lu, %lu)", (unsigned long)matchRange.location, (unsigned long)matchRange.length);
}

// 摂氏を華氏に変換する。
- (NSString*)fahrenheitFromCelsius:(OGRegularExpressionMatch*)aMatch contextInfo:(id)contextInfo
{
	//NSLog(@"matchedString:%@ index:%d", [aMatch matchedString], [aMatch index]);
	double	celcius = [[aMatch substringAtIndex:1] doubleValue];
	double	fahrenheit = celcius * 9.0 / 5.0 + 32.0;
	
	// 置換した文字列を返す。nilを返した場合は置換を終了する。
	return [NSString stringWithFormat:@"%.1fF", fahrenheit];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)aApp
{
	return YES;	// 全てのウィンドウを閉じたら終了する。
}


/* OGRegularExpressionCaptureVisitor protocol */
- (void)visitAtFirstCapture:(OGRegularExpressionCapture*)aCapture
{
    NSMutableString *indent = [NSMutableString string];
    NSInteger i;
    for (i = 0; i < [aCapture level]; i++) [indent appendString:@"  "];
    NSRange matchRange = [aCapture range];
    
    /*NSLog(@"capture: %@", [aCapture description]);
    [NSArchiver archiveRootObject:aCapture toFile: [@"~/Desktop/cap.archive" stringByExpandingTildeInPath]];
    OGRegularExpressionCapture	*capture2 = [NSUnarchiver unarchiveObjectWithFile: [@"~/Desktop/cap.archive" stringByExpandingTildeInPath]];
    NSLog(@"capture2: %@", [capture2 description]);
    aCapture = capture2;*/
    
    [resultTextView insertText:[NSString stringWithFormat:@" %@#%ld", indent, [aCapture groupIndex]] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
    if([aCapture groupName] != nil) {
        [resultTextView insertText:[NSString stringWithFormat:@"(\"%@\")", [aCapture groupName]] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
    }
    [resultTextView insertText:[NSString stringWithFormat:@": (%lu-%lu) \"%@\"\n",
        matchRange.location, matchRange.length,
        [aCapture string]] replacementRange:NSMakeRange([[resultTextView textStorage] length], 0)];
}

- (void)visitAtLastCapture:(OGRegularExpressionCapture*)aCapture
{
    /* do nothing */
}

@end
