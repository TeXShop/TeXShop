//
//  MacroMenuController.m
//
//  Created by Mitsuhiro Shishikura on Mon Dec 16 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "MacroMenuController.h"

#import "MainWindow.h"
#import "globals.h"
#import "EncodingSupport.h"

#define SUD [NSUserDefaults standardUserDefaults]

@implementation MacroMenuController

static id sharedMacroMenuController = nil;

+ (id)sharedInstance 
{
    if (sharedMacroMenuController == nil) 
        sharedMacroMenuController = [[MacroMenuController alloc] init];
    return sharedMacroMenuController;
}

- (id)init 
{
    if (sharedMacroMenuController) 
        [super dealloc];
	else
	{
		sharedMacroMenuController = [super init];
		macroDict = nil;
                // the next command was commented out by koch because it was moved to NSAppDelegate
		// [self loadMacros]; 
                // the next stuff was commented out by mitsu
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMacros:) 
//			name:@"ReloadMacrosNotification" object:nil];
	}
	return sharedMacroMenuController;
}

- (void)dealloc
{
	if (self != sharedMacroMenuController) 
		[super dealloc];	// Don't free our shared instance
}

- (NSDictionary *)macroDictionary
{
	return macroDict;
}

// load macros from Macros.plist
- (void)loadMacros
{
	NSString *pathStr;
	NSData *myData;
        NSString *aString;

        pathStr = [MacrosPathKey stringByStandardizingPath];
        pathStr = [pathStr stringByAppendingPathComponent:@"Macros"];
        pathStr = [pathStr stringByAppendingPathExtension:@"plist"];


       // pathStr = [[NSString stringWithString: MACRO_DATA_PATH] stringByStandardizingPath];
/*	
	macroDict = nil;
	failed = NO;
	pathStr = [[NSString stringWithString: MACRO_DATA_PATH] stringByStandardizingPath];
	directoryStr = [pathStr stringByDeletingLastPathComponent];
	// does one need more sophisticates calls such as in createTemplates in TSPreferences?
	NS_DURING
		if (!([[NSFileManager defaultManager] fileExistsAtPath: directoryStr isDirectory: &isDirectory]) 
						|| !isDirectory)
		{
			if(!isDirectory || ![[NSFileManager defaultManager] createDirectoryAtPath: 
														directoryStr attributes:nil])
				failed = YES;
		}
		if(!failed)
		{
			if (![[NSFileManager defaultManager] fileExistsAtPath: pathStr isDirectory: &isDirectory])
			{
				if (![[NSFileManager defaultManager] copyPath:[[NSBundle mainBundle] 
						pathForResource: @"Macros" ofType: @"plist"] toPath: pathStr handler:nil])
					failed = YES;
			}
			else if (isDirectory)
				failed = YES;
		}
	NS_HANDLER
		failed = YES;
	NS_ENDHANDLER
	if(failed)
	{
		// alert: failed to create Macros.plist
		NSRunAlertPanel(@"Error", @"failed to create ~/Library/TeXShop/Macros/Macros.plist", nil, nil, nil);
		return;
	}
*/

	NS_DURING
	// macroDict = [NSDictionary dictionaryWithContentsOfFile: pathStr]; // this crashes when the file is not a proper UTF8
	myData = [NSData dataWithContentsOfFile:pathStr];
	aString = [[[NSString alloc] initWithData:myData encoding: NSUTF8StringEncoding] autorelease];
	if (!aString)
		[NSException raise: @"non-UTF-8 format for Macros.plist" format: @""];
	macroDict = (NSDictionary *)[aString propertyList];
	if (!macroDict)
		[NSException raise: @"non-UTF-8 format for Macros.plist" format: @""];
	NS_HANDLER
		macroDict = nil;
	NS_ENDHANDLER
	
	if (!macroDict || ![macroDict isKindOfClass: [NSDictionary class]])
	{	// alert: failed to parse Macros.plist
		NSRunAlertPanel(@"Error", @"failed to parse ~/Library/TeXShop/Macros/Macros.plist", 
						nil, nil, nil);
		macroDict = nil;
		return;
	}
	
	[macroDict retain];
	return;	// we have successfully parsed Macros.plist

}


// set up main macro menu on the menu bar
- (void)setupMainMacroMenu
{
	NSMenuItem *newItem;
	
	if (!macroDict)
		return;
	// remove old items
	while ([macroMenu numberOfItems]>1)
	{	
		
		[macroMenu removeItemAtIndex: 1];
	}
	// add top items -- 
	//newItem = [macroMenu addItemWithTitle: NSLocalizedString(@"Open Macro Editor...", @"Open Macro Editor...") 
	//									action: nil keyEquivalent: @""];
	//[newItem setTarget: [MacroEditor sharedInstance]];
	
	[macroMenu addItem: [NSMenuItem separatorItem]];
	
	// check predefined key equivalents
	keyEquivalents = [NSMutableArray array];
	[self listKeyEquivalents: [NSApp mainMenu]];

	// now add macros from dictionary
	[self addItemsToMenu: macroMenu fromArray: [macroDict objectForKey: SUBMENU_KEY] withKey: YES];
	
	// set dummy actions to submenu items so that they can be disabled
	NSEnumerator *enumerator = [[macroMenu itemArray] objectEnumerator];
	while (newItem = (NSMenuItem *)[enumerator nextObject])
	{
		if ([newItem hasSubmenu])
		{
			[newItem setTarget: self];
			[newItem setAction: @selector(doNothing:)];
		}
	}
}

// reload
- (void)reloadMacros: (id)sender
{
	[macroDict release];
	macroDict = nil;
	[self loadMacros];
	[self setupMainMacroMenu];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ResetMacroButtonNotification" object:self];
}



// build menu from property list
- (void)addItemsToMenu: (NSMenu *)menu fromArray: (NSArray *)array withKey: (BOOL)flag
{
    NSDictionary *dict;
    NSEnumerator *enumerator = [array objectEnumerator];
    NSMenuItem *newItem;
    NSMenu *submenu;
    NSString *nameStr;
    
    while (dict = (NSDictionary *)[enumerator nextObject])
    {
        nameStr = [dict objectForKey: NAME_KEY];
		NSArray *childlenArray = [dict objectForKey: SUBMENU_KEY];
		if (childlenArray)	// submenu item
		{
			newItem = [menu addItemWithTitle: nameStr action: nil keyEquivalent: @""];
            submenu = [[[NSMenu alloc] init] autorelease];
            [self addItemsToMenu: submenu fromArray: childlenArray withKey: flag];
            [newItem setSubmenu: submenu];
		}
		else if ([nameStr isEqualToString: SEPARATOR])	// separator item
		{
			[menu addItem: [NSMenuItem separatorItem]];
		}
		else	// standard item
		{
			newItem = [menu addItemWithTitle: nameStr action: @selector(doMacro:) keyEquivalent: @""];
			[newItem setTarget: self];
			[newItem setRepresentedObject: [dict objectForKey: CONTENT_KEY]];
			if (flag)
			{
				NSString *keyEquiv = (NSString *)[dict objectForKey: KEYEQUIV_KEY];
				unsigned int modifier = getKeyModifierMaskFromString(keyEquiv);
				keyEquiv = getKeyEquivalentFromString(keyEquiv);
				if (keyEquiv && ![self isAlreadyDefined: keyEquiv modifier: modifier])
				{
					[newItem setKeyEquivalent: keyEquiv];
					[newItem setKeyEquivalentModifierMask: modifier];
				}
			}
		}
	}
}
 
// build a menu for popup button in the toolbar
- (void)addItemsToPopupButton: (NSPopUpButton *)popupButton
{
    NSDictionary *dict;
    NSMenuItem *newItem;
    NSMenu *submenu;
    NSString *nameStr;
    
	if (!macroDict)
		return;
	[popupButton removeAllItems];
	 [popupButton addItemWithTitle: NSLocalizedString(@"Macros", @"Macros")];
	
	NSArray *array = [macroDict objectForKey: SUBMENU_KEY];
    NSEnumerator *enumerator = [array objectEnumerator];
    while (dict = (NSDictionary *)[enumerator nextObject])
    {
        nameStr = [dict objectForKey: NAME_KEY];
		NSArray *childlenArray = [dict objectForKey: SUBMENU_KEY];
		if (childlenArray)	// submenu item
		{
			// [popupButton addItemWithTitle: nameStr]; // this method does not return the item
			// newItem = [popupButton lastItem];
                        // Revision on January 28 by Mitsuhiro Shishikura
                        [popupButton addItemWithTitle: @""]; // this method does not return the item
                        newItem = [popupButton lastItem];
                        [newItem setTitle: nameStr];
        
			submenu = [[[NSMenu alloc] init] autorelease];
            [self addItemsToMenu: submenu fromArray: childlenArray withKey: NO];
            [newItem setSubmenu: submenu];
		}
		else if ([nameStr isEqualToString: SEPARATOR])	// separator item
		{
			[popupButton addItemWithTitle: @""];
			newItem = [popupButton lastItem];
			[newItem setState: NSOffState];
		}
		else	// standard item
		{
			[popupButton addItemWithTitle: nameStr]; // this method does not return the item
			newItem = [popupButton lastItem];
			[newItem setAction: @selector(doMacro:)];
			[newItem setTarget: self];
			[newItem setRepresentedObject: [dict objectForKey: CONTENT_KEY]];
		}
	}
}

// now simply call doCompletion routine via notification center
- (void)doMacro: (id)sender
{
	NSString *macroString;
	if ([sender isKindOfClass: [NSMenuItem class]])
		macroString = [(NSMenuItem *)sender representedObject];
	else if ([sender isKindOfClass: [NSString class]])
		macroString = sender;
	else
		return;
		
	if ([macroString length] <14 || 
		(![[[macroString substringToIndex: 13] lowercaseString] isEqualToString:@"--applescript"] 
		&& ![[[macroString substringToIndex: 14] lowercaseString] isEqualToString:@"-- applescript"]))
	{	
		// do ordinary macro
		[[NSNotificationCenter defaultCenter] postNotificationName: @"completionpanel" 
										object: macroString];
	}
	else
	{
		// do AppleScript
		NSMutableString *newString = [NSMutableString stringWithString: macroString];
		NSString *filePath = [[(MainWindow *)[NSApp mainWindow] document] fileName];
		if (!filePath) 
			filePath = @"";
		[newString replaceOccurrencesOfString: @"#FILEPATH#" withString: 
					[NSString stringWithFormat: @"\"%@\"", filePath] 
					options: 0 range: NSMakeRange(0, [newString length])];
		filePath = [filePath stringByDeletingPathExtension];
		[newString replaceOccurrencesOfString: @"#PDFPATH#" withString: 
					[NSString stringWithFormat: @"\"%@.pdf\"", filePath] 
					options: 0 range: NSMakeRange(0, [newString length])];
                [newString replaceOccurrencesOfString: @"#DVIPATH#" withString: 
					[NSString stringWithFormat: @"\"%@.dvi\"", filePath] 
					options: 0 range: NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString: @"#PSPATH#" withString: 
					[NSString stringWithFormat: @"\"%@.ps\"", filePath] 
					options: 0 range: NSMakeRange(0, [newString length])];
		
		NSAppleScript *aScript = [[NSAppleScript alloc] initWithSource: newString];
		NSDictionary *errorInfo;
		NSAppleEventDescriptor *returnValue = [aScript executeAndReturnError: &errorInfo];
		if (returnValue) // successful?
		{	// show the result only if the return value is a text
			if ([returnValue descriptorType] == kAETextSuite)	//kAETextSuite='TEXT'
				NSRunAlertPanel(@"AppleScript Result", [returnValue stringValue], nil, nil, nil);
		}
		else
		{	// show error message
			NSRunAlertPanel(@"AppleScript Error", 
				[errorInfo objectForKey: NSAppleScriptErrorMessage], nil, nil, nil);
		}
		[aScript release];
	}
}

// the following is derived from doCompletion: in MyDocument.m --replaced by the above
/* 
- (void)doMacro: (id)sender
{
    NSWindow		*activeWindow;
	MyDocument 		*document;
	MyTextView		*textView;
    NSRange			oldRange, searchRange;
	NSString		*oldString;
    NSMutableString	*newString;
    unsigned		from, to;
    NSUndoManager	*myManager;
    NSMutableDictionary	*myDictionary;
    NSNumber		*theLocation, *theLength;

	// get window, document, textview
	activeWindow = [[TSWindowManager sharedInstance] activeDocumentWindow];
	if (!activeWindow || !([activeWindow isMemberOfClass: [MainWindow class]]))
		return;
	document = [(MainWindow *)activeWindow document];
    if (!document)
		return;
	textView = [document textView];
	if (!textView)
		return;
		
	// Determine the curent selection range & text
	oldRange = [textView selectedRange];
	oldString = [[textView string] substringWithRange: oldRange];

// support for MacJapanese encoding
	if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"]) {
		newString = filterBackslashToYen([(NSMenuItem *)sender representedObject]); // this string is autoreleased
	}
	else {
// end
		newString = [[[(NSMenuItem *)sender representedObject] mutableCopy] autorelease];
	}

	// Substitute all occurances of #SEL# with the original text
	[newString replaceOccurrencesOfString: @"#SEL#" withString: oldString
						options: 0 range: NSMakeRange(0, [newString length])];

	// Now search for #INS#, remember its position, and remove it. We will
	// Later position the insertion mark there. Defaults to end of string.
	searchRange = [newString rangeOfString: @"#INS#" options:0];
	[newString replaceOccurrencesOfString: @"#INS#" withString: @""
						options: 0 range: NSMakeRange(0, [newString length])];
	
	// Insert the new text
	[textView replaceCharactersInRange: oldRange withString: newString];
        
	// Create & register an undo action
	myManager = [textView undoManager];
	myDictionary = [NSMutableDictionary dictionaryWithCapacity: 3];
	theLocation = [NSNumber numberWithUnsignedInt: oldRange.location];
	theLength = [NSNumber numberWithUnsignedInt: [newString length]];
	[myDictionary setObject: oldString forKey: @"oldString"];
	[myDictionary setObject: theLocation forKey: @"oldLocation"];
	[myDictionary setObject: theLength forKey: @"oldLength"];
	[myManager registerUndoWithTarget: document selector:@selector(fixTyping:) object: myDictionary];
	[myManager setActionName:@"Macro"];
	from = oldRange.location;
	to = from + [newString length];
	[document fixColor:from :to];
	[document setupTags];
	//[newString release];	// the string is autoreleased

	// Place insertion mark
	if (searchRange.location != NSNotFound)
	{
		searchRange.location += oldRange.location;
		searchRange.length = 0;
		[textView setSelectedRange:searchRange];
	}
}
*/

// dummy action for submenu items-- by assigning this to submenu items, they can be disabled
- (void)doNothing: (id)sender
{
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	if ([anItem action] == @selector(reloadMacros:))
		return YES;
	return [[NSApp mainWindow] isMemberOfClass: [MainWindow class]];
}

// list key equivalents which are already assigned
- (void)listKeyEquivalents: (NSMenu *)menu
{
	NSArray *menuitems = [menu itemArray];
	NSEnumerator *enumerator = [menuitems objectEnumerator];
	NSMenuItem *item;
	while (item = (NSMenuItem *)[enumerator nextObject])
	{
		if (![[item keyEquivalent] isEqualToString: @""])
		{
			NSString *keyEquiv = [item keyEquivalent];
			unsigned int modifier = [item keyEquivalentModifierMask];
			if (![keyEquiv isEqualToString: [keyEquiv lowercaseString]])
			{
				keyEquiv = [keyEquiv lowercaseString];
				modifier |= NSShiftKeyMask;
			}
			NSArray *keyPair = [NSArray arrayWithObjects: keyEquiv, 
								[NSNumber numberWithUnsignedInt: modifier], nil];
			[keyEquivalents addObject: keyPair];
		}
		if ([item hasSubmenu])
		{
			[self listKeyEquivalents: [item submenu]];
		}
	}
}

// check with the list of key equivalents which are already assigned
- (BOOL)isAlreadyDefined: (NSString *)keyEquiv modifier: (unsigned int)modifier
{
	NSEnumerator *enumerator = [keyEquivalents objectEnumerator];
	NSArray *item;
	keyEquiv = [keyEquiv lowercaseString];
	while (item = (NSArray *)[enumerator nextObject])
	{
		if ([[item objectAtIndex: 0] isEqualToString: keyEquiv] 
					&& [[item objectAtIndex: 1] unsignedIntValue] == modifier)
		{
			NSArray *keyPair = [NSArray arrayWithObjects: keyEquiv, 
								[NSNumber numberWithUnsignedInt: modifier], nil];
			[keyEquivalents addObject: keyPair];	// add to our list of predefined key equivalents
			return YES;
		}
	}
	return NO;
}

@end

// ================================================================
// Uitility functions for key equivalents.
// ================================================================

// For first two functions, input string is assumed to have forms @"y" or @"y+ShiftKey+OptionKey"
NSString *getKeyEquivalentFromString(NSString *string)
{
	if ([string length]>=1)
		return [[string substringToIndex: 1] lowercaseString];
	else
		return @"";
}

unsigned int getKeyModifierMaskFromString(NSString *string)
{
	unsigned int mask = NSCommandKeyMask;
	NSString *modifiersStr = ([string length]>1)?[string substringFromIndex: 1]:@"";
	NSRange range = [modifiersStr rangeOfString: @"ShiftKey"];
	if (range.location != NSNotFound)
		mask |= NSShiftKeyMask;
	range = [modifiersStr rangeOfString: @"OptionKey"];
	if (range.location != NSNotFound)
		mask |= NSAlternateKeyMask;
	range = [modifiersStr rangeOfString: @"ControlKey"];
	if (range.location != NSNotFound)
		mask |= NSControlKeyMask;
	return mask;
}

// create a string like @"y+ShiftKey+ControlKey"
NSString *getStringFormKeyEquivalent(NSString *key, BOOL shift, BOOL option, BOOL control)
{
	NSMutableString *string;
	if ([key length]==0)
		return @"";
	string = [NSMutableString stringWithString: [[key substringToIndex: 1] uppercaseString]];
	if (shift)
		[string appendString: @"+ShiftKey"];
	if (option)
		[string appendString: @"+OptionKey"];
	if (control)
		[string appendString: @"+ControlKey"];
	return string;
}

// make a string which is to be displayed in MacroEditor
NSString *getMenuItemString(NSString *string)
{
	unichar c;	// command 0x2318  shift 0x21E7  option 0x2325  control 0x005E '^'
	NSRange range;
	if ([string length]==0)
		return @"";
	NSMutableString *menuItemStr = [NSMutableString string];
	NSString *modifiersStr = ([string length]>1)?[string substringFromIndex: 1]:@"";
	range = [modifiersStr rangeOfString: @"ControlKey"];
	if (range.location != NSNotFound)
	{
		[menuItemStr appendString: @"^"];
	}
	range = [modifiersStr rangeOfString: @"OptionKey"];
	if (range.location != NSNotFound)
	{
		c = 0x2325;
		[menuItemStr appendString: [NSString stringWithCharacters: &c length: 1]];
	}
	range = [modifiersStr rangeOfString: @"ShiftKey"];
	if (range.location != NSNotFound)
	{
		c = 0x21E7;
		[menuItemStr appendString: [NSString stringWithCharacters: &c length: 1]];
	}
	c = 0x2318;
	[menuItemStr appendString: [NSString stringWithCharacters: &c length: 1]];
	[menuItemStr appendString: [[string substringToIndex: 1] uppercaseString]];
	return menuItemStr;
}

