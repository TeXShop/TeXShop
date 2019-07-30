/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2007 Richard Koch
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * $Id: TSEncodingSupport.m 254 2007-06-03 21:09:25Z fingolfin $
 *
 * Created by Mitsuhiro Shishikura on Fri Dec 13 2002.
 *
 */

#import "TSEncodingSupport.h"
#import "TSDocument.h" // mitsu 1.29 (P)
#import "globals.h"
#import "GlobalData.h"
#import "NSString-Extras.h"  //Terada

static NSString *yenString = nil;

@implementation TSEncodingSupport

// Pointer to the TSEncodingSupport singleton
static id sharedEncodingSupport = nil;

// We pair CFStringEncoding with custom names
typedef struct {
	NSStringEncoding	nsEnc;
	CFStringEncoding	cfEnc;
    //	NSString			*name;
} TSEncoding;


// List of the supported encodings.
static TSEncoding _availableEncodings[] = {
	{ 0, kCFStringEncodingMacRoman }, //			@"MacOSRoman" },
	{ 0, kCFStringEncodingISOLatin1}, //			@"IsoLatin" },
	{ 0, kCFStringEncodingISOLatin2}, //			@"IsoLatin2" },
	{ 0, kCFStringEncodingISOLatin5}, //			@"IsoLatin5" },
	{ 0, kCFStringEncodingISOLatin9}, //			@"IsoLatin9" },
	{ 0, kCFStringEncodingISOLatinGreek}, //		@"IsoLatinGreek" }, //Greek ISO 8859-7
	{ 0, kCFStringEncodingMacCentralEurRoman}, //	@"Mac Central European Roman" }, // added at request of Czech Republic respondent
	{ 0, kCFStringEncodingMacJapanese}, //			@"MacJapanese" },
	{ 0, kCFStringEncodingDOSJapanese}, //			@"DOSJapanese" },
	{ 0, kCFStringEncodingShiftJIS_X0213_00}, //	@"SJIS_X0213" },
	{ 0, kCFStringEncodingEUC_JP}, //				@"EUC_JP" },
	{ 0, kCFStringEncodingISO_2022_JP}, //			@"JISJapanese" },
	{ 0, kCFStringEncodingMacKorean}, //			@"MacKorean" },
    { 0, kCFStringEncodingDOSKorean}, //			@"DOSKorean" },
	{ 0, kCFStringEncodingUTF8}, //					@"UTF-8 Unicode" },
	{ 0, kCFStringEncodingUnicode}, //				@"Standard Unicode" },
	{ 0, kCFStringEncodingMacCyrillic}, //			@"Mac Cyrillic" },
	{ 0, kCFStringEncodingDOSCyrillic}, //			@"DOS Cyrillic" },
	{ 0, kCFStringEncodingDOSRussian}, //			@"DOS Russian" },
	{ 0, kCFStringEncodingWindowsLatin1}, //		@"Windows Latin 1" }, // code page 1252
	{ 0, kCFStringEncodingWindowsLatin2}, //		@"WindowsCentralEurRoman" }, // code page 1250
	{ 0, kCFStringEncodingWindowsCyrillic}, //		@"Windows Cyrillic" },
	{ 0, kCFStringEncodingKOI8_R}, //				@"KOI8_R" },
	{ 0, kCFStringEncodingMacChineseTrad}, //		@"Mac Chinese Traditional" },
	{ 0, kCFStringEncodingMacChineseSimp}, //		@"Mac Chinese Simplified" },
	{ 0, kCFStringEncodingDOSChineseTrad}, //		@"DOS Chinese Traditional" },
	{ 0, kCFStringEncodingDOSChineseSimplif}, //	@"DOS Chinese Simplified" },
	{ 0, kCFStringEncodingGBK_95}, //				@"GBK" },
	{ 0, kCFStringEncodingGB_2312_80}, //			@"GB 2312" },
	{ 0, kCFStringEncodingGB_18030_2000}, //		@"GB 18030" },
};

// List of the supported encodings.
static TSEncoding _availableTexworksEncodings[] = {
    { 0, kCFStringEncodingMacRoman }, //			@"MacOSRoman" },
    { 0, kCFStringEncodingISOLatin1}, //			@"IsoLatin" },
    { 0, kCFStringEncodingISOLatin2}, //			@"IsoLatin2" },
    { 0, kCFStringEncodingISOLatin5}, //			@"IsoLatin5" },
    { 0, kCFStringEncodingISOLatin9}, //			@"IsoLatin9" },
    { 0, kCFStringEncodingISOLatinGreek}, //		@"IsoLatinGreek" }, //Greek ISO 8859-7
    { 0, kCFStringEncodingMacCentralEurRoman}, //	@"Mac Central European Roman" }, // added at request of Czech Republic respondent
    { 0, kCFStringEncodingShiftJIS_X0213_00}, //	@"SJIS_X0213" },
    { 0, kCFStringEncodingEUC_JP}, //				@"EUC_JP" },
    { 0, kCFStringEncodingUTF8}, //					@"UTF-8 Unicode" },
    { 0, kCFStringEncodingUnicode}, //				@"Standard Unicode" },
    { 0, kCFStringEncodingWindowsLatin1}, //		@"Windows Latin 1" }, // code page 1252
    { 0, kCFStringEncodingWindowsLatin2}, //		@"WindowsCentralEurRoman" }, // code page 1250
    { 0, kCFStringEncodingWindowsCyrillic}, //		@"Windows Cyrillic" },
    { 0, kCFStringEncodingKOI8_R}, //				@"KOI8_R" },
    { 0, kCFStringEncodingGB_18030_2000}, //		@"GB 18030" },
};




+ (void)initialize
{
	// Conver the CF encodings to NS encodings.
	NSInteger i;
	for (i = 0; i < ARRAYSIZE(_availableEncodings); ++i)
		_availableEncodings[i].nsEnc = CFStringConvertEncodingToNSStringEncoding(_availableEncodings[i].cfEnc);
    
    for (i = 0; i < ARRAYSIZE(_availableTexworksEncodings); ++i)
        _availableTexworksEncodings[i].nsEnc = CFStringConvertEncodingToNSStringEncoding(_availableTexworksEncodings[i].cfEnc);

	// initialize yen string
	unichar yenChar = YEN;
	yenString = [NSString stringWithCharacters: &yenChar length:1];
}

+ (id)sharedInstance
{
	if (sharedEncodingSupport == nil) {
		sharedEncodingSupport = [[TSEncodingSupport alloc] init];
	}
	return sharedEncodingSupport;
}

- (id)init
{
    NSMutableArray  *myArray;
    NSMutableArray  *texWorksArray;
    
	if (sharedEncodingSupport) {
		// [super dealloc];
	} else {
		sharedEncodingSupport = [super init];
        
       myArray = [NSMutableArray arrayWithObjects: @"MacOSRoman", @"IsoLatin", @"IsoLatin2", @"IsoLatin5", @"IsoLatin9", @"IsoLatinGreek", @"Mac Central European Roman", @"MacJapanese", @"DOSJapanese", @"SJIS_X0213", @"EUC_JP", @"JISJapanese", @"MacKorean", @"DOSKorean", @"UTF-8 Unicode", @"Standard Unicode", @"Mac Cyrillic", @"DOS Cyrillic", @"DOS Russian", @"Windows Latin 1", @"WindowsCentralEurRoman", @"Windows Cyrillic", @"KOI8_R", @"Mac Chinese Traditional", @"Mac Chinese Simplified", @"DOS Chinese Traditional", @"DOS Chinese Simplified", @"GBK", @"GB 2312", @"GB 18030", nil];
        
        
        texWorksArray = [NSMutableArray arrayWithObjects:  @"Apple Roman", @"ISO 8859-1", @"ISO 8859-2", @"ISO 8859-9", @"ISO 8859-15", @"ISO 8859-7", @"macce", @"Shift-JIS", @"EUC_JP", @"UTF-8", @"UTF-16", @"ansinew", @"Windows-1250", @"Windows-1251", @"KOI8-R", @"GB18030-0", nil];
        
        self.availableEncodingsNames = myArray;
        self.availableTexworksEncodingNames = texWorksArray;
        self.defaultEncodingNumber = 4; // ISOLatin9


		g_shouldFilter = kNoFilterMode;

		// register for encoding changed notification
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(encodingChanged:)
				name:@"EncodingChangedNotification" object:nil];

		// Here preferences are set for the state of the pasteboard conversion facility, which is only used with Japanese encoding.
		if ([SUD objectForKey: @"ConvertToBackslash"] == nil)
			[SUD setBool: NO forKey: @"ConvertToBackslash"];
		if ([SUD objectForKey: @"ConvertToYen"] == nil)
			[SUD setBool: YES forKey: @"ConvertToYen"];
	}
	return sharedEncodingSupport;
}

/*
- (void)dealloc
{
	if (self != sharedEncodingSupport)
		[super dealloc];	// Don't free our shared instance
}
*/

// Delegate method for text fields
- (void)controlTextDidChange:(NSNotification *)note
{
	NSText *fieldEditor = [[note userInfo] objectForKey: @"NSFieldEditor"];
	if (!fieldEditor)
		return;
	NSString *oldString = [fieldEditor string];
	NSRange selectedRange = [fieldEditor selectedRange];
	NSString *newString;

	if (g_shouldFilter == kMacJapaneseFilterMode) {
		newString = filterBackslashToYen(oldString);
		[fieldEditor setString: newString];
		[fieldEditor setSelectedRange: selectedRange];
	} else if (g_shouldFilter == kOtherJapaneseFilterMode) {
		newString = filterYenToBackslash(oldString);
		[fieldEditor setString: newString];
		[fieldEditor setSelectedRange: selectedRange];
	}
}


// set up g_texChar, g_taggedTeXSections and menu item for tex character conversion
// FIXME: This is only called when starting up or when the encoding prefs are changed.
// In particular, it is *not* sufficient to just save a file with a different encoding!
// TODO: Correct this by making the encoding checks document specific. In particular,
// g_texChar, g_taggedTeXSections should be replaced by TSDocument members.
- (void)setupForEncoding
{
	NSString *currentEncoding;
	NSMenu *editMenu;
	id item;
	NSMutableString *menuTitle;
	TSDocument *theDoc;

	currentEncoding = [SUD stringForKey:EncodingKey];

	editMenu = [[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Edit", @"Edit")] submenu];
	if (editMenu) {
		NSInteger i = [editMenu indexOfItemWithTarget:self andAction:@selector(toggleTeXCharConversion:)];
		if (i >= 0)	{ // remove menu item
			[editMenu removeItemAtIndex: i];
			if ([[editMenu itemAtIndex: i-1] isSeparatorItem])
				[editMenu removeItemAtIndex: i-1];
		}
	}

	if ([currentEncoding isEqualToString:@"MacJapanese"] ||
			[currentEncoding isEqualToString:@"SJIS_X0213"] ) {
		g_texChar = YEN; // yen
		// ARC [g_taggedTeXSections release];

		if ([SUD boolForKey: ConTeXtTagsKey]) {
			g_taggedTeXSections = [[NSArray alloc] initWithObjects:
					filterBackslashToYen(@"\\chapter"),
					filterBackslashToYen(@"\\section"),
					filterBackslashToYen(@"\\subsection"),
					filterBackslashToYen(@"\\subsubsection"),
					filterBackslashToYen(@"\\subsubsubsection"),
					filterBackslashToYen(@"\\subsubsubsubsection"),
					filterBackslashToYen(@"\\part"),
					filterBackslashToYen(@"\\title"),
					filterBackslashToYen(@"\\subject"),
					filterBackslashToYen(@"\\subsubject"),
					filterBackslashToYen(@"\\subsubsubject"),
					filterBackslashToYen(@"\\subsubsubsubject"),
					filterBackslashToYen(@"\\subsubsubsubsubject"),
					nil];
		} else {
			g_taggedTeXSections = [[NSArray alloc] initWithObjects:
							filterBackslashToYen(@"\\chapter"),
							filterBackslashToYen(@"\\section"),
							filterBackslashToYen(@"\\subsection"),
							filterBackslashToYen(@"\\subsubsection"),
							nil];
		}
				// mitsu 1.29 (P)

		// If the command completion list already exists, and we are about to change the filter mode:
		// Update the command completion list to match the new filter mode.
		if (g_shouldFilter != kMacJapaneseFilterMode && g_commandCompletionList) {
			[g_commandCompletionList replaceOccurrencesOfString: @"\\" withString: yenString
						options: 0 range: NSMakeRange(0, [g_commandCompletionList length])];
			theDoc = [[NSDocumentController sharedDocumentController]
				documentForFileName: [[GlobalData sharedGlobalData].CommandCompletionPath stringByStandardizingPath]];
			if (theDoc)
				[[theDoc textView] setString: filterBackslashToYen([[theDoc textView] string])];
		}
		// end mitsu 1.29
		g_shouldFilter = kMacJapaneseFilterMode;
		// set up menu item
		if (editMenu) {
			[editMenu addItem: [NSMenuItem separatorItem]];
			menuTitle = [NSMutableString stringWithString:
						NSLocalizedString(@"Convert \\yen to \\ in Pasteboard", @"Convert \\yen to \\ in Pasteboard")];
			[menuTitle replaceOccurrencesOfString: @"\\yen" withString: yenString
						options: 0 range: NSMakeRange(0, [menuTitle length])];
			item = [editMenu addItemWithTitle: menuTitle
					action:@selector(toggleTeXCharConversion:) keyEquivalent: @""];
			[item setTarget: self];
			[item setState: [SUD boolForKey: @"ConvertToBackslash"]?NSOnState:NSOffState];
		}
	} else {
		g_texChar = BACKSLASH;
		
		/*
		[g_taggedTeXSections release];
		g_taggedTeXSections = [[NSArray alloc] initWithObjects:
							@"\\chapter",
							@"\\section",
							@"\\subsection",
							@"\\subsubsection",
							nil];
		*/
				// mitsu 1.29 (P)
		// If the command completion list already exists, and we are about to change the filter mode:
		// Update the command completion list to match the new filter mode. {
		if (g_shouldFilter == kMacJapaneseFilterMode && g_commandCompletionList) {
			[g_commandCompletionList replaceOccurrencesOfString: yenString withString: @"\\"
						options: 0 range: NSMakeRange(0, [g_commandCompletionList length])];
			theDoc = [[NSDocumentController sharedDocumentController]
				documentForFileName: [[GlobalData sharedGlobalData].CommandCompletionPath stringByStandardizingPath]];
			if (theDoc)
				[[theDoc textView] setString: filterYenToBackslash([[theDoc textView] string])];
		}
		// end mitsu 1.29

		if ([currentEncoding isEqualToString:@"DOSJapanese"] ||
				[currentEncoding isEqualToString:@"EUC_JP"] ||
				[currentEncoding isEqualToString:@"JISJapanese"] ||
				([currentEncoding isEqualToString:@"UTF-8 Unicode"] && [SUD boolForKey:ptexUtfOutputEnabledKey]) )
		{
			g_shouldFilter = kOtherJapaneseFilterMode;
			// set up menu item
			if (editMenu) {
				[editMenu addItem: [NSMenuItem separatorItem]];
				menuTitle = [NSMutableString stringWithString:
								NSLocalizedString(@"Convert \\ to \\yen in Pasteboard", @"Convert \\ to \\yen in Pasteboard")];
				[menuTitle replaceOccurrencesOfString: @"\\yen" withString: yenString
							options: 0 range: NSMakeRange(0, [menuTitle length])];
				item = [editMenu addItemWithTitle: menuTitle
						action:@selector(toggleTeXCharConversion:) keyEquivalent: @""];
				[item setTarget: self];
				[item setState: [SUD boolForKey: @"ConvertToYen"]?NSOnState:NSOffState];
			}
		} else {
			g_shouldFilter = kNoFilterMode;
		}
	}
}

// called when the encoding is changed in Preferences dialog
- (void)encodingChanged: (NSNotification *)note
{
	[self setupForEncoding];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"ResetTagsMenuNotification" object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DocumentSyntaxColorNotification" object:self];
	//[[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadMacrosNotification" object:self];
}


// action for "Convert * to * in Pasteboard"
- (IBAction)toggleTeXCharConversion:(id)sender
{
	NSString *currentEncoding;
	NSString *theKey;

	currentEncoding = [SUD stringForKey:EncodingKey];
	if ([currentEncoding isEqualToString:@"MacJapanese"] ||
			[currentEncoding isEqualToString:@"SJIS_X0213"])
		theKey = @"ConvertToBackslash";
	else if ([currentEncoding isEqualToString:@"DOSJapanese"] ||
		[currentEncoding isEqualToString:@"EUC_JP"] ||
		[currentEncoding isEqualToString:@"JISJapanese"] ||
		([currentEncoding isEqualToString:@"UTF-8 Unicode"] && [SUD boolForKey:ptexUtfOutputEnabledKey]) )
		theKey = @"ConvertToYen";
	else
		return;
	[SUD setBool: ![SUD boolForKey: theKey]  forKey: theKey];
	[SUD synchronize];
	[(NSMenuItem *)sender setState: [SUD boolForKey: theKey]?NSOnState:NSOffState];
}

#pragma mark New encoding API

- (NSStringEncoding)defaultEncoding
{
	NSString	*currentEncoding;

	currentEncoding = [SUD stringForKey:EncodingKey];
	return [self stringEncodingForKey: currentEncoding];
}


- (NSStringEncoding)stringEncodingForKey: (NSString *)key
{

	NSInteger i;
	for (i = 0; i < ARRAYSIZE(_availableEncodings); ++i) {
//		if ([key isEqualToString:_availableEncodings[i].name])
        if ([key isEqualToString:self.availableEncodingsNames[i]])
			return _availableEncodings[i].nsEnc;
	}
    

    for (i = 0; i < ARRAYSIZE(_availableTexworksEncodings); ++i) {
        //		if ([key isEqualToString:_availableEncodings[i].name])
        if ([key isEqualToString:self.availableTexworksEncodingNames[i]])
            return _availableTexworksEncodings[i].nsEnc;
    }

    
	// In 2.18, the old name CentralEurRoman was changed to the new name Mac Central European Roman
	// Unfortunately, members of Mathematical Institute of Silesian University in Opava, Czech Republic, Europe had
	// hundreds of documents with encoding set by %!TEX encoding = CentralEurRoman
	// We special case that name for those folks!
	if ([key isEqualToString: @"CentralEurRoman"]) 
			return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacCentralEurRoman);


	// If the encoding is unknown, use the default encoding in our list (Latin 9).
    NSRunAlertPanel(NSLocalizedString(@"Error", @"Error"),
                    NSLocalizedString(@"Unknown encoding; using Latin 9.", @"Unknown encoding; using Latin 9."),
                    nil, nil, nil);

    return _availableEncodings[self.defaultEncodingNumber].nsEnc;
	// return _availableEncodings[0].nsEnc;
}

- (NSString *)keyForStringEncoding: (NSStringEncoding)encoding
{
	NSInteger i;
	for (i = 0; i < ARRAYSIZE(_availableEncodings); ++i) {
		if (_availableEncodings[i].nsEnc == encoding)
			return self.availableEncodingsNames[i];
	}
	// If the encoding is unknown, use the default encoding in our list (Latin 9).
    NSRunAlertPanel(NSLocalizedString(@"Error", @"Error"),
                    NSLocalizedString(@"Unknown encoding; using Latin 9.", @"Unknown encoding; using Latin 9."),
                    nil, nil, nil);
    return self.availableEncodingsNames[self.defaultEncodingNumber];
	// return self.availableEncodingsNames[0];
}

- (NSString *)localizedNameForKey: (NSString *)key
{
	return NSLocalizedStringFromTable(key, @"Encodings", @"Fetch localized encoding name");
}

- (NSString *)localizedNameForStringEncoding: (NSStringEncoding)encoding
{
	return [self localizedNameForKey: [self keyForStringEncoding:encoding]];
}

- (void)addEncodingsToMenu:(NSMenu *)menu withTarget:(id)aTarget action:(SEL)anAction
{
	id item;
	NSString *name;
	NSStringEncoding enc;
	NSInteger i;

	for (i = 0; i < ARRAYSIZE(_availableEncodings); ++i) {
		enc = _availableEncodings[i].nsEnc;
		name = [self localizedNameForKey:self.availableEncodingsNames[i]];

		item = [[NSMenuItem alloc] initWithTitle: name action:anAction keyEquivalent:@""];
		if (aTarget)
			[item setTarget: aTarget];
		[item setTag: enc];
		[menu addItem: item];
	}
}

#pragma mark Support for utf.sty

// zenitani and itoh, 1.35 (C) -- support for utf.sty
- (BOOL)ptexUtfOutputCheck: (NSString *)dataString withEncoding: (NSStringEncoding)enc
{
	NSString *currentEncoding;
	currentEncoding = [self keyForStringEncoding:enc];

	if( ![dataString canBeConvertedToEncoding:
			CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP)] ) {
		return YES;
	} else {
		return NO;
	}
}

- (NSData *)ptexUtfOutput: (NSTextView *)dataView withEncoding: (NSStringEncoding)enc
{
	NSString *dataString;
	
    dataString = [dataView string];
	NSMutableString *utfString, *newString = [NSMutableString string];
	NSRange charRange, aCIDRange;
	NSString *subString;
	NSGlyphInfo *aGlyph;
	NSUInteger startl, endl, end;
    
	charRange = NSMakeRange(0,1);
	endl = 0;
	while (charRange.location < [dataString length]) {
		if (charRange.location == endl) {
			[dataString getLineStart:&startl end:&endl contentsEnd:&end forRange:charRange];
			//            NSLog( @"%d %d %d", startl, end, endl);
		}
		//        NSLog( @"%d %d", charRange.length, charRange.location);
		charRange = [dataString rangeOfComposedCharacterSequenceAtIndex: charRange.location];
		//        NSLog( @"%d %d", charRange.length, charRange.location);
		subString = [dataString substringWithRange: charRange];
        
		if (![subString canBeConvertedToEncoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP)]) {
			aGlyph = [[dataView textStorage] attribute:NSGlyphInfoAttributeName
											   atIndex:charRange.location effectiveRange:&aCIDRange];
			if (aGlyph) {
				utfString = [NSMutableString stringWithFormat:@"%CCID{%ld}",
                             (unichar)g_texChar,(unsigned long)[aGlyph characterIdentifier]];
			} else if (charRange.length > 1) {
				NSLayoutManager *aLayout = [dataView layoutManager];
				utfString = [NSMutableString stringWithFormat:@"%CCID{%d}", (unichar)g_texChar,
                             [aLayout glyphAtIndex:charRange.location]];
				// 0x2014,0x2015 fix (reported by Kino-san)
			} else if ( [subString characterAtIndex: 0] == 0x2015) {
				utfString = [NSMutableString stringWithFormat:@"%C", (unichar)0x2014];
			} else {
				utfString = [NSMutableString stringWithFormat:@"%CUTF{%04X}",
                             (unichar)g_texChar, [subString characterAtIndex: 0]];
			}
			if ((charRange.location + charRange.length) == end) {
				[utfString appendString: @"%"];
			}
			[newString appendString: utfString];
		} else {
			[newString appendString: subString];
		}
		charRange.location += charRange.length;
		charRange.length = 1;
	}
    
    if ( [SUD boolForKey:AutomaticUTF8MACtoUTF8ConversionKey] )
        newString = [NSMutableString stringWithString:[newString normalizedStringWithModifiedNFC]];
    
	return [newString dataUsingEncoding:enc allowLossyConversion:YES];
}
// end 1.35 (C)


@end

// replace backslashes by yens
NSMutableString *filterBackslashToYen(NSString *aString)
{
	NSMutableString *newString = [NSMutableString stringWithString: aString];
	[newString replaceOccurrencesOfString: @"\\" withString: yenString
                                  options: 0 range: NSMakeRange(0, [newString length])];
	return newString;
}

// replace yens by backslashes
NSMutableString *filterYenToBackslash(NSString *aString)
{
	NSMutableString *newString = [NSMutableString stringWithString: aString];
	[newString replaceOccurrencesOfString: yenString withString: @"\\"
                                  options: 0 range: NSMakeRange(0, [newString length])];
	return newString;
}




