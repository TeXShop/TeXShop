//
//  EncodingSupport.m
//
//  Created by Mitsuhiro Shishikura on Fri Dec 13 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "EncodingSupport.h"

#import "globals.h"
#define SUD [NSUserDefaults standardUserDefaults]

// NSStringEncoding currentEncodingID = NSMacOSRomanStringEncoding; // good idea, but I decided 'not yet'; koch
NSString *yenString = nil;

@implementation EncodingSupport

static id sharedEncodingSupport = nil;

//------------------------------------------------------------------------------
+ (id)sharedInstance 
//------------------------------------------------------------------------------
{
    if (sharedEncodingSupport == nil) 
	{
        sharedEncodingSupport = [[EncodingSupport alloc] init];
    }
    return sharedEncodingSupport;
}

//------------------------------------------------------------------------------
- (id)init 
//------------------------------------------------------------------------------
{
    if (sharedEncodingSupport) 
	{
        [super dealloc];
	}
	else
	{
		sharedEncodingSupport = [super init];
		
                shouldFilter = filterNone;
		// initialize yen string
		unichar yenChar = 0x00a5;
		yenString = [[NSString stringWithCharacters: &yenChar length:1] retain];
		
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

//------------------------------------------------------------------------------
- (void)dealloc
//------------------------------------------------------------------------------
{
	if (self != sharedEncodingSupport) [super dealloc];	// Don't free our shared instance
}

// Delegate method for text fields
//------------------------------------------------------------------------------
- (void)controlTextDidChange:(NSNotification *)note
//------------------------------------------------------------------------------
{
	NSText *fieldEditor = [[note userInfo] objectForKey: @"NSFieldEditor"];
	if (!fieldEditor)
		return;
	NSString *oldString = [fieldEditor string];
	NSRange selectedRange = [fieldEditor selectedRange];
	NSString *newString;
	
	if (shouldFilter == filterMacJ)
	{
		newString = filterBackslashToYen(oldString);
		[fieldEditor setString: newString];
		[fieldEditor setSelectedRange: selectedRange];
	}
	else if (shouldFilter == filterNSSJIS)
	{
		newString = filterYenToBackslash(oldString);
		[fieldEditor setString: newString];
		[fieldEditor setSelectedRange: selectedRange];
	}		
}


// set up texChar, kTaggedTeXSections and menu item for tex character conversion
//------------------------------------------------------------------------------
- (void)setupForEncoding
//------------------------------------------------------------------------------
{
	NSString *currentEncoding;
	NSMenu *editMenu;
	NSMenuItem *item;
	NSMutableString *menuTitle;
	
	currentEncoding = [SUD stringForKey:EncodingKey];
        
/* not yet; koch */ 
/*
	if([currentEncoding isEqualToString:@"MacOSRoman"])
        currentEncodingID = NSMacOSRomanStringEncoding;
    else if([currentEncoding isEqualToString:@"IsoLatin"])
        currentEncodingID = NSISOLatin1StringEncoding;
    else if([currentEncoding isEqualToString:@"MacJapanese"]) 
        currentEncodingID = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacJapanese); 
	else if([currentEncoding isEqualToString:@"NSShiftJIS"]) 
        currentEncodingID = NSShiftJISStringEncoding;
    else if([currentEncoding isEqualToString:@"EUCJapanese"]) 
        currentEncodingID = NSJapaneseEUCStringEncoding;
    else if([currentEncoding isEqualToString:@"JISJapanese"]) 
        currentEncodingID = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP);
    else if([currentEncoding isEqualToString:@"MacKorean"]) 
        currentEncodingID = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacKorean);
    else 
         currentEncodingID = NSMacOSRomanStringEncoding;
*/

	editMenu = [[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Edit", @"Edit")] submenu];
	if (editMenu)
	{
		int i = [editMenu indexOfItemWithTarget:self andAction:@selector(toggleTeXCharConversion:)];
		if (i>=0)	// remove menu item
		{
			[editMenu removeItemAtIndex: i];
			if ([[editMenu itemAtIndex: i-1] isSeparatorItem])
				[editMenu removeItemAtIndex: i-1];
		}
	}

	if ([currentEncoding isEqualToString:@"MacJapanese"])
	{
		texChar = 0x00a5; // yen
		if (kTaggedTeXSections)
			[kTaggedTeXSections release];
		kTaggedTeXSections = [[NSArray alloc] initWithObjects:
							filterBackslashToYen(@"\\chapter"),
							filterBackslashToYen(@"\\section"),
							filterBackslashToYen(@"\\subsection"),
							filterBackslashToYen(@"\\subsubsection"),
							nil];
		shouldFilter = filterMacJ;
		// set up menu item
		if (editMenu)
		{
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
	}
	else 
	{
		texChar = 0x005c; // backslash
		if (kTaggedTeXSections)
			[kTaggedTeXSections release];
		kTaggedTeXSections = [[NSArray alloc] initWithObjects:
							@"\\chapter",
							@"\\section",
							@"\\subsection",
							@"\\subsubsection",
							nil];
	
		if ([currentEncoding isEqualToString:@"DOSJapanese"] ||
				[currentEncoding isEqualToString:@"EUC_JP"] || 
				[currentEncoding isEqualToString:@"JISJapanese"])
		{
			shouldFilter = filterNSSJIS;
			// set up menu item
			if (editMenu)
			{
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
		}
		else
		{
			shouldFilter = filterNone;
		}
	}
}

// called when the encoding is changed in Preferences dialog
//------------------------------------------------------------------------------
- (void)encodingChanged: (NSNotification *)note
//------------------------------------------------------------------------------
{
	[self setupForEncoding];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ResetTagsMenuNotification" object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DocumentSyntaxColorNotification" object:self];
	//[[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadMacrosNotification" object:self];
}


// action for "Convert * to * in Pasteboard"
//------------------------------------------------------------------------------
- (IBAction)toggleTeXCharConversion:(id)sender
//------------------------------------------------------------------------------
{
	NSString *currentEncoding;
	NSString *theKey;
	
	currentEncoding = [SUD stringForKey:EncodingKey];
	if ([currentEncoding isEqualToString:@"MacJapanese"])
		theKey = @"ConvertToBackslash";
	else if ([currentEncoding isEqualToString:@"DOSJapanese"] ||
		[currentEncoding isEqualToString:@"EUC_JP"] || 
		[currentEncoding isEqualToString:@"JISJapanese"])
		theKey = @"ConvertToYen";
	else
		return;	
	[SUD setBool: ![SUD boolForKey: theKey]  forKey: theKey];
	[SUD synchronize];
	[(NSMenuItem *)sender setState: [SUD boolForKey: theKey]?NSOnState:NSOffState];
}
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