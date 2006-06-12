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
 * $Id: TSMacroMenuController.h 108 2006-02-10 13:50:25Z fingolfin $
 *
 * Created by Mitsuhiro Shishikura on Mon Dec 16 2002.
 *
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// #define MACRO_DATA_PATH		@"~/Library/TeXShop/Macros/Macros.plist"		// should go to globals?

#define NAME_KEY	@"name"
#define CONTENT_KEY @"content"
#define SUBMENU_KEY @"submenu"
#define KEYEQUIV_KEY @"key"

#define SEPARATOR @"Separator"

@interface TSMacroMenuController : NSObject
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
- (void)reloadMacrosOnly;
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
