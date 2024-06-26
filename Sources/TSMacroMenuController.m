/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2005 Richard Koch
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
 * $Id: TSMacroMenuController.m 197 2006-05-29 21:19:33Z fingolfin $
 *
 * Created by Mitsuhiro Shishikura on Mon Dec 16 2002.
 *
 */

#import "TSMacroMenuController.h"

#import "TSTextEditorWindow.h"
#import "TSFullSplitWindow.h"
#import "globals.h"
#import "GlobalData.h"
#import "TSEncodingSupport.h"
// mistu 1.29
#import "TSWindowManager.h"
#import "TSTextView.h"
#import "TSFullSplitWindow.h"
// end mistu 1.29


@implementation TSMacroMenuController

static id sharedMacroMenuController = nil;

+ (id)sharedInstance
{
	if (sharedMacroMenuController == nil)
		sharedMacroMenuController = [[TSMacroMenuController alloc] init];
	return sharedMacroMenuController;
}

- (id)init
{
	if (!sharedMacroMenuController)
	{
		sharedMacroMenuController = [super init];
		self.macroDict = nil;
				// the next command was commented out by koch because it was moved to NSAppDelegate
		// [self loadMacros];
				// the next stuff was commented out by mitsu
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMacros:)
//			name:@"ReloadMacrosNotification" object:nil];
	}
	return sharedMacroMenuController;
}

/*
- (void)dealloc
{
	if (self != sharedMacroMenuController)
		[super dealloc];	// Don't free our shared instance
}
*/

/*

- (NSDictionary *)macroDictionary
{
	return macroDict;
}
*/

// load macros from Macros.plist
- (void)loadMacros
{
	NSString *pathStr, *defaultPathStr;
	NSData *myData;
	NSString *error = nil; // mitsu 1.29 (U) added
						   //    NSString *aString; // mitsu 1.29 (U) removed
	
	defaultPathStr = [MacrosPath stringByStandardizingPath];
	defaultPathStr = [defaultPathStr stringByAppendingPathComponent:@"Macros_Latex"];
	defaultPathStr = [defaultPathStr stringByAppendingPathExtension:@"plist"];
	
	pathStr = [MacrosPath stringByStandardizingPath];
	switch (g_macroType) {
		case TexEngine: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Tex"]; break;
		case LatexEngine: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Latex"]; break;
		case BibtexEngine: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Bibtex"]; break;
		case IndexEngine: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Index"]; break;
		case MetapostEngine: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Metapost"]; break;
		// case ContextEngine: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Context"]; break;
		default: pathStr = [pathStr stringByAppendingPathComponent:@"Macros_Latex"]; break;
	}
	pathStr = [pathStr stringByAppendingPathExtension:@"plist"];
	
	
	NS_DURING
		// macroDict = [NSDictionary dictionaryWithContentsOfFile: pathStr]; // this crashes when the file is not a proper UTF8
		if ([[NSFileManager defaultManager] fileExistsAtPath:pathStr])
			myData = [NSData dataWithContentsOfFile:pathStr];
		else
			myData = [NSData dataWithContentsOfFile:defaultPathStr];
		
		NSPropertyListFormat format;
		self.macroDict = [NSPropertyListSerialization propertyListFromData:myData
													 mutabilityOption:NSPropertyListImmutable
															   format:&format
													 errorDescription:&error];
	NS_HANDLER
		self.macroDict = nil;
	NS_ENDHANDLER
	
	if (!self.macroDict || ![self.macroDict isKindOfClass: [NSDictionary class]]) {
		// alert: failed to parse Macros.plist
		NSRunAlertPanel(@"Error", @"failed to parse ~/Library/TeXShop/Macros/Macros_??.plist file",
						nil, nil, nil);
//		if (error) [error release]; // mitsu 1.29 (U) added
        error = nil;
		self.macroDict = nil;
		return;
	}
	
//	[macroDict retain];
}


// set up main macro menu on the menu bar
- (void)setupMainMacroMenu
{
    
	NSMenuItem *newItem;

	if (!self.macroDict)
		return;
	// remove old items
	while ([macroMenu numberOfItems] > 1) {
		[macroMenu removeItemAtIndex: 1];
	}
	// add top items --
	//newItem = [macroMenu addItemWithTitle: NSLocalizedString(@"Open Macro Editor...", @"Open Macro Editor...")
	//									action: nil keyEquivalent: @""];
	//[newItem setTarget: [TSMacroEditor sharedInstance]];

	[macroMenu addItem: [NSMenuItem separatorItem]];

	// check predefined key equivalents
	self.keyEquivalents = [NSMutableArray array];
	[self listKeyEquivalents: [NSApp mainMenu]];

	// now add macros from dictionary
	[self addItemsToMenu: macroMenu fromArray: [self.macroDict objectForKey: SUBMENU_KEY] withKey: YES];

	// set dummy actions to submenu items so that they can be disabled
	NSEnumerator *enumerator = [[macroMenu itemArray] objectEnumerator];
	while ((newItem = (NSMenuItem *)[enumerator nextObject])) {
		if ([newItem hasSubmenu]) {
			[newItem setTarget: self];
			[newItem setAction: @selector(doNothing:)];
		}
	}
}

// reload
- (void)reloadMacros: (id)sender
{
	[self reloadMacrosOnly];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ResetMacroButtonNotification" object:self];
}

- (void)reloadMacrosOnly
{
//	[macroDict release];
	self.macroDict = nil;
	[self loadMacros];
	[self setupMainMacroMenu];
}



// build menu from property list
- (void)addItemsToMenu: (NSMenu *)menu fromArray: (NSArray *)array withKey: (BOOL)flag
{
	NSDictionary *dict;
	NSEnumerator *enumerator = [array objectEnumerator];
	id newItem;
	NSMenu *submenu;
	NSString *nameStr;
	
	while ((dict = (NSDictionary *)[enumerator nextObject])) {
		nameStr = [dict objectForKey: NAME_KEY];
		NSArray *childlenArray = [dict objectForKey: SUBMENU_KEY];
		if (childlenArray) {	// submenu item
			newItem = [menu addItemWithTitle: nameStr action: nil keyEquivalent: @""];
			submenu = [[NSMenu alloc] init];
			[self addItemsToMenu: submenu fromArray: childlenArray withKey: flag];
			[newItem setSubmenu: submenu];
		} else if ([nameStr isEqualToString: SEPARATOR]) {	// separator item
			[menu addItem: [NSMenuItem separatorItem]];
		} else {	// standard item
			newItem = [menu addItemWithTitle: nameStr action: @selector(doMacro:) keyEquivalent: @""];
			[newItem setTarget: self];
			[newItem setRepresentedObject: [dict objectForKey: CONTENT_KEY]];
			if (flag) {
				NSString *keyEquiv = (NSString *)[dict objectForKey: KEYEQUIV_KEY];
				NSUInteger modifier = getKeyModifierMaskFromString(keyEquiv);
				keyEquiv = getKeyEquivalentFromString(keyEquiv);
				if (keyEquiv && ![self isAlreadyDefined: keyEquiv modifier: modifier]) {
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
	id newItem;
	NSMenu *submenu;
	NSString *nameStr;
	
	if (!self.macroDict)
		return;
	[popupButton removeAllItems];
	[popupButton addItemWithTitle: NSLocalizedString(@"Macros", @"Macros")];
	
	NSArray *array = [self.macroDict objectForKey: SUBMENU_KEY];
	NSEnumerator *enumerator = [array objectEnumerator];
	while ((dict = (NSDictionary *)[enumerator nextObject])) {
		nameStr = [dict objectForKey: NAME_KEY];
		NSArray *childlenArray = [dict objectForKey: SUBMENU_KEY];
		if (childlenArray) {	// submenu item
								// [popupButton addItemWithTitle: nameStr]; // this method does not return the item
								// newItem = [popupButton lastItem];
								// Revision on January 28 by Mitsuhiro Shishikura
			[popupButton addItemWithTitle: @""]; // this method does not return the item
			newItem = [popupButton lastItem];
			[newItem setTitle: nameStr];
			
			submenu = [[NSMenu alloc] init];
			[self addItemsToMenu: submenu fromArray: childlenArray withKey: NO];
			[newItem setSubmenu: submenu];
		} else if ([nameStr isEqualToString: SEPARATOR]) {	// separator item
			[popupButton addItemWithTitle: @""];
			newItem = [popupButton lastItem];
			[newItem setState: NSOffState];
		} else {	// standard item
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
	BOOL            result;
	NSString        *reason = 0;
	NSMutableArray  *args;
	NSString        *macroString;
    NSString        *filePath, *folderPath, *displayName;
    TSFullSplitWindow *mySplitWindow;
	
	if ([sender isKindOfClass: [NSMenuItem class]])
		macroString = [(NSMenuItem *)sender representedObject];
	else if ([sender isKindOfClass: [NSString class]])
		macroString = sender;
	else
		return;
	
	if (macroString == nil)
		return;    // zenitani 1.33
	
	if ([macroString length] <14 ||
		(![[[macroString substringToIndex: 13] lowercaseString] isEqualToString:@"--applescript"]
		 && ![[[macroString substringToIndex: 14] lowercaseString] isEqualToString:@"-- applescript"]))
		
	{
		// do ordinary macro
		// mitsu 1.29 (T2)
        NSWindow *activeDocWindow = [[TSWindowManager sharedInstance] activeTextWindow];
		if (activeDocWindow != nil) {
            if ([activeDocWindow isKindOfClass:[TSTextEditorWindow class]])
            {
                [[(TSTextEditorWindow *)activeDocWindow document] insertSpecial: macroString
																	undoKey: NSLocalizedString(@"Macro", @"Macro")];
            }
            else if ([activeDocWindow isKindOfClass:[TSFullSplitWindow class]])
                {
                    TSFullSplitWindow *activeWindow = (TSFullSplitWindow *)activeDocWindow;
                    [activeWindow.myDocument insertSpecial: macroString
                                                                        undoKey: NSLocalizedString(@"Macro", @"Macro")];
                 }
			//[(TSTextView *)[[(TSTextEditorWindow *)activeDocWindow document] textView]
			//			insertSpecial: macroString
			//			undoKey: NSLocalizedString(@"Macro", @"Macro")];
		}
		// original was:
		//[[NSNotificationCenter defaultCenter] postNotificationName: @"completionpanel"
		//								object: macroString];
		// end mitsu 1.29
	} else {
		
		// do AppleScript
		NSMutableString *newString = [NSMutableString stringWithString: macroString];
        if ([[NSApp mainWindow] isKindOfClass: [TSTextEditorWindow class]]) {
            filePath = [[[(TSTextEditorWindow *)[NSApp mainWindow] document] fileURL] path];
            displayName = [[(TSTextEditorWindow *)[NSApp mainWindow] document] displayName];
        }
        else if ([[NSApp mainWindow] isKindOfClass: [TSFullSplitWindow class]]) {
            mySplitWindow = (TSFullSplitWindow *)[NSApp mainWindow];
            filePath = [[mySplitWindow.myDocument fileURL] path];
            displayName = [mySplitWindow.myDocument displayName];
            }
        else {
            filePath = [[[(TSTextEditorWindow *)[NSApp mainWindow] document] fileURL] path];
           displayName = [[(TSTextEditorWindow *)[NSApp mainWindow] document] displayName];
        }
		if (!filePath)
			filePath = @"";
		[newString replaceOccurrencesOfString: @"#FILEPATH#" withString:
			[NSString stringWithFormat: @"\"%@\"", filePath]
									  options: 0 range: NSMakeRange(0, [newString length])];
		filePath = [filePath stringByDeletingPathExtension];
        folderPath = [[filePath stringByDeletingLastPathComponent] stringByAppendingString:@"/"];
		[newString replaceOccurrencesOfString: @"#PDFPATH#" withString:
			[NSString stringWithFormat: @"\"%@.pdf\"", filePath]
									  options: 0 range: NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString: @"#DVIPATH#" withString:
			[NSString stringWithFormat: @"\"%@.dvi\"", filePath]
									  options: 0 range: NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString: @"#PSPATH#" withString:
			[NSString stringWithFormat: @"\"%@.ps\"", filePath]
									  options: 0 range: NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString: @"#LOGPATH#" withString:
			[NSString stringWithFormat: @"\"%@.log\"", filePath]
									  options: 0 range: NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString: @"#AUXPATH#" withString:
			[NSString stringWithFormat: @"\"%@.aux\"", filePath]
									  options: 0 range: NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString: @"#INDPATH#" withString:
			[NSString stringWithFormat: @"\"%@.ind\"", filePath]
									  options: 0 range: NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString: @"#BBLPATH#" withString:
			[NSString stringWithFormat: @"\"%@.bbl\"", filePath]
									  options: 0 range: NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString: @"#HTMLPATH#" withString:
			[NSString stringWithFormat: @"\"%@.html\"", filePath]
									  options: 0 range: NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString: @"#NAMEPATH#" withString:
			[NSString stringWithFormat: @"\"%@\"", filePath]
									  options: 0 range: NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString: @"#TEXPATH#" withString:
			[NSString stringWithFormat: @"\"%@.tex\"", filePath]
									  options: 0 range: NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString: @"#DOCUMENTNAME#" withString:
			[NSString stringWithFormat: @"\"%@\"", displayName]
									  options: 0 range: NSMakeRange(0, [newString length])];
        
        [newString replaceOccurrencesOfString: @"#FOLDERPATH#" withString:
            [NSString stringWithFormat: @"\"%@\"", folderPath] options: 0 range: NSMakeRange(0, [newString length])];
		
		
		if (([macroString length] >= 20) &&
			( ([[[macroString substringToIndex: 20] lowercaseString] isEqualToString:@"--applescript direct"]) ||
			  ([[[macroString substringToIndex: 21] lowercaseString] isEqualToString:@"-- applescript direct"])))
			
		{
			
			NSAppleScript *aScript = [[NSAppleScript alloc] initWithSource: newString];
			NSDictionary *errorInfo;
			NSAppleEventDescriptor *returnValue = [aScript executeAndReturnError: &errorInfo];
			if (returnValue) { // successful?
				// show the result only if the return value is a text
				if ([returnValue descriptorType] == kAETextSuite)	//kAETextSuite='TEXT'
					NSRunAlertPanel(@"AppleScript Result", [returnValue stringValue], nil, nil, nil);
			} else {	// show error message
				NSRunAlertPanel(@"AppleScript Error",
								[errorInfo objectForKey: NSAppleScriptErrorMessage], nil, nil, nil);
			}
		//	[aScript release];
			
		} else {
			
			// save newScript in file named scriptFileName in directory scriptFilePath
			NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *tmpScriptPath = [GlobalData sharedGlobalData].tempAppleScriptPath;
            if (tmpScriptPath == nil)
                {
                    [GlobalData sharedGlobalData].tempAppleScriptPath = NSTemporaryDirectory();
                    // tmpScriptPath = [GlobalData sharedGlobalData].tempAppleScriptPath;
                    // NSLog(tmpScriptPath);
                }
               
            /*
			if (!([fileManager fileExistsAtPath: [TempPath stringByStandardizingPath]])) {
				// create the necessary directories
				NS_DURING
					// create ~/Library/TeXShop/Temp
                result = [fileManager createDirectoryAtPath:[TempPath stringByStandardizingPath] withIntermediateDirectories:NO attributes:nil error:NULL];
				NS_HANDLER
					result = NO;
					reason = [localException reason];
				NS_ENDHANDLER
				if (!result) {
					NSRunAlertPanel(@"Error", reason, @"Couldn't Create Temp Folder", nil, nil);
					return;
				}
			}
            NSString *scriptFilePath = [TempPath stringByStandardizingPath];
            NSString *scriptFileName = [scriptFilePath stringByAppendingString: @"/tempscript"];
            */
            
            NSString *scriptFilePath = [[GlobalData sharedGlobalData].tempAppleScriptPath stringByStandardizingPath];
            NSString *globallyUniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
			NSString *scriptFileName = [scriptFilePath stringByAppendingString: globallyUniqueString];
			
			NS_DURING
                [newString writeToFile: scriptFileName atomically: NO encoding:NSUTF8StringEncoding error:NULL]; // modified by Terada
            NS_HANDLER
				return;
			NS_ENDHANDLER
			
			NSTask *scriptTask =  [[NSTask alloc] init];
			NSString *runnerPath = [[NSBundle mainBundle] pathForResource:@"ScriptRunner" ofType:nil inDirectory:@"ScriptRunner.app/Contents/MacOS"];
			//  runnerPath = [runnerPath stringByAppendingString:@"/Contents/MacOS/ScriptRunner"];
			args = [NSMutableArray array];
			[args addObject: scriptFileName];
			
			[scriptTask setLaunchPath: runnerPath];
			[scriptTask setArguments: args];
			[scriptTask setCurrentDirectoryPath: scriptFilePath];
			// [scriptTask setEnvironment: nil];
			// [scriptTask setStandardOutput: nil];
			// [scriptTask setStandardError: nil];
			// [scriptTask setStandardInput: nil];
			[scriptTask launch];
			
		}
	}
}

// dummy action for submenu items-- by assigning this to submenu items, they can be disabled
- (void)doNothing: (id)sender
{
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
    
	if ([anItem action] == @selector(reloadMacros:))
		return YES;
	
	NSString *macroString = [anItem representedObject];
	if (macroString == nil)
		return YES;
    
	if ([macroString length] <14 ||
		(![[[macroString substringToIndex: 13] lowercaseString] isEqualToString:@"--applescript"]
		 && ![[[macroString substringToIndex: 14] lowercaseString] isEqualToString:@"-- applescript"]))
		return ([[NSApp mainWindow] isMemberOfClass: [TSTextEditorWindow class]] ||
                [[NSApp mainWindow] isMemberOfClass: [TSFullSplitWindow class]]);
	else
		return YES;
	
}

// list key equivalents which are already assigned
- (void)listKeyEquivalents: (NSMenu *)menu
{
	NSArray *menuitems = [menu itemArray];
	NSEnumerator *enumerator = [menuitems objectEnumerator];
	NSMenuItem *item;
	while ((item = (NSMenuItem *)[enumerator nextObject])) {
		if (![[item keyEquivalent] isEqualToString: @""]) {
			NSString *keyEquiv = [item keyEquivalent];
			NSUInteger modifier = [item keyEquivalentModifierMask];
			if (![keyEquiv isEqualToString: [keyEquiv lowercaseString]]) {
				keyEquiv = [keyEquiv lowercaseString];
				modifier |= NSShiftKeyMask;
			}
			NSArray *keyPair = [NSArray arrayWithObjects: keyEquiv,
				[NSNumber numberWithUnsignedInteger:modifier], nil];
			[self.keyEquivalents addObject: keyPair];
		}
		if ([item hasSubmenu]) {
			[self listKeyEquivalents: [item submenu]];
		}
	}
}

// check with the list of key equivalents which are already assigned
- (BOOL)isAlreadyDefined: (NSString *)keyEquiv modifier: (NSUInteger)modifier
{
	NSEnumerator *enumerator = [self.keyEquivalents objectEnumerator];
	NSArray *item;
	keyEquiv = [keyEquiv lowercaseString];
	while ((item = (NSArray *)[enumerator nextObject])) {
		if ([[item objectAtIndex: 0] isEqualToString: keyEquiv]
			&& [[item objectAtIndex: 1] unsignedIntegerValue] == modifier)
		{
			NSArray *keyPair = [NSArray arrayWithObjects: keyEquiv,
				[NSNumber numberWithUnsignedInteger:modifier], nil];
			[self.keyEquivalents addObject: keyPair];	// add to our list of predefined key equivalents
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
	if ([string length] >= 1)
		return [[string substringToIndex: 1] lowercaseString];
	else
		return @"";
}

NSUInteger getKeyModifierMaskFromString(NSString *string)
{
	NSUInteger mask = NSCommandKeyMask;
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
	if ([key length] == 0)
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

// make a string which is to be displayed in TSMacroEditor
NSString *getMenuItemString(NSString *string)
{
    
	unichar c;	// command 0x2318  shift 0x21E7  option 0x2325  control 0x005E '^'
	NSRange range;
	if ([string length] == 0)
		return @"";
	NSMutableString *menuItemStr = [NSMutableString string];
	NSString *modifiersStr = ([string length]>1)?[string substringFromIndex: 1]:@"";
	range = [modifiersStr rangeOfString: @"ControlKey"];
	if (range.location != NSNotFound) {
		[menuItemStr appendString: @"^"];
	}
	range = [modifiersStr rangeOfString: @"OptionKey"];
	if (range.location != NSNotFound) {
		c = 0x2325;
		[menuItemStr appendString: [NSString stringWithCharacters: &c length: 1]];
	}
	range = [modifiersStr rangeOfString: @"ShiftKey"];
	if (range.location != NSNotFound) {
		c = 0x21E7;
		[menuItemStr appendString: [NSString stringWithCharacters: &c length: 1]];
	}
	c = 0x2318;
	[menuItemStr appendString: [NSString stringWithCharacters: &c length: 1]];
	[menuItemStr appendString: [[string substringToIndex: 1] uppercaseString]];
	return menuItemStr;
}

