//
//  MacroMenuController.h
//
//  Created by Mitsuhiro Shishikura on Mon Dec 16 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// #define MACRO_DATA_PATH		@"~/Library/TeXShop/Macros/Macros.plist"		// should go to globals?

#define NAME_KEY	@"name"
#define CONTENT_KEY @"content"
#define SUBMENU_KEY @"submenu"
#define KEYEQUIV_KEY @"key"

#define SEPARATOR @"Separator"

@interface MacroMenuController : NSObject 
{
	IBOutlet NSMenu *macroMenu;
	NSDictionary *macroDict;
	NSMutableArray *keyEquivalents;
}

+ (id)sharedInstance;

- (NSDictionary *)macroDictionary;
- (void)loadMacros;
- (void)setupMainMacroMenu;
- (void)reloadMacros: (id)sender;
- (void)addItemsToMenu: (NSMenu *)menu fromArray: (NSArray *)array withKey: (BOOL)flag;
- (void)addItemsToPopupButton: (NSPopUpButton *)popupButton;
- (void)doMacro: (id)sender;
- (void)doNothing: (id)sender;

- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

- (void)listKeyEquivalents: (NSMenu *)menu;
- (BOOL)isAlreadyDefined: (NSString *)keyEquiv modifier: (unsigned int)modifier;
@end

NSString *getKeyEquivalentFromString(NSString *string);
unsigned int getKeyModifierMaskFromString(NSString *string);
NSString *getStringFormKeyEquivalent(NSString *key, BOOL shift, BOOL option, BOOL control);
NSString *getMenuItemString(NSString *string);
