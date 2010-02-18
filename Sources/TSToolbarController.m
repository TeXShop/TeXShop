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
 * $Id: TSToolbarController.m 254 2007-06-03 21:09:25Z fingolfin $
 *
 * Created by Anton Leuski on Sun Feb 03 2002.
 * Parts of this code are taken from Apple's example SimpleToolbar.
 *
 */

#import "UseMitsu.h"
#import "Globals.h"

#import "TSToolbarController.h"

#import "MyPDFView.h"
#import "MyPDFKitView.h"

// added by mitsu --(H) Macro menu; macroButton
#import "TSMacroMenuController.h"
// end addition


static NSString* 	kSourceToolbarIdentifier 	= @"Source Toolbar Identifier";
static NSString* 	kPDFToolbarIdentifier 		= @"PDF Toolbar Identifier";
static NSString*	kPDFKitToolbarIdentifier	= @"PDFKit Toolbar Identifier";
static NSString*	kSaveDocToolbarItemIdentifier 	= @"Save Document Item Identifier";

// Source window toolbar items
static NSString*	kTypesetTID			= @"Typeset";
static NSString*	kProgramTID			= @"Program";
static NSString*	kTeXTID 			= @"TeX";
static NSString*	kLaTeXTID 			= @"LaTeX";
static NSString*	kBibTeXTID 			= @"BibTeX";
static NSString*	kMakeIndexTID 		= @"MakeIndex";
static NSString*	kMetaPostTID 		= @"MetaPost";
static NSString*	kConTeXTID 			= @"ConTeX";
static NSString*	kMetaFontID			= @"MetaFont";
static NSString*	kTagsTID 			= @"Tags";
static NSString*	kTemplatesID 		= @"Templates";
static NSString*	kAutoCompleteID		= @"AutoComplete";  //warning: used in TSDocument's fixAutoMenu
static NSString*    kColorIndexTID		= @"ColorIndex";
// forsplit
static NSString*	kSplitID			= @"Split";
// end forsplit
// added by mitsu --(H) Macro menu; macroButton
static NSString*	kMacrosTID			= @"Macros";
// end addition


// PDF Window toolbar items
static NSString*	kTypesetEETID			= @"TypesetEE";
static NSString*	kProgramEETID			= @"ProgramEE";
static NSString*	kPreviousPageButtonTID 	= @"PreviousPageButton";
static NSString*	kPreviousPageTID 		= @"PreviousPage";
static NSString*	kNextPageButtonTID		= @"NextPageButton";
static NSString*	kNextPageTID 			= @"NextPage";
static NSString*	kGotoPageTID 			= @"GotoPage";
static NSString*	kMagnificationTID 		= @"Magnification";
#ifdef MITSU_PDF
static NSString*	kMouseModeTID 			= @"MouseMode";
static NSString*	kMacrosEETID			= @"MacrosEE";
static NSString*    kSyncMarksTID			= @"SyncMarks";
#endif

// PDFKit Window toolbar items
static NSString*	kPreviousPageButtonKKTID 	= @"PreviousPageButtonKIT";
static NSString*	kPreviousPageKKTID 		= @"PreviousPageKIT";
static NSString*	kNextPageButtonKKTID	= @"NextPageButtonKIT";
static NSString*	kNextPageKKTID 			= @"NextPageKIT";
static NSString*	kGotoPageKKTID 			= @"GotoPageKIT";
static NSString*	kMagnificationKKTID 	= @"MagnificationKIT";
#ifdef MITSU_PDF
static NSString*	kMouseModeKKTID 		= @"MouseModeKIT";
static NSString*	kBackForthKKTID			= @"BackForthKIT";
static NSString*	kDrawerKKTID			= @"DrawerKIT";
static NSString*	kSplitKKTID				= @"SplitKIT";
#endif


@implementation TSDocument (ToolbarSupport)

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSToolbar*)makeToolbar:(NSString*)inID
{
	// Create a new toolbar instance, and attach it to our document window
	NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: inID] autorelease];

	// Set up toolbar properties: Allow customization, give a default display mode, and remember state 		in user defaults
	[toolbar setAllowsUserCustomization: YES];
	[toolbar setAutosavesConfiguration: YES];
	[toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];

	// We are the delegate
	[toolbar setDelegate: self];

	return toolbar;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSToolbarItem*) makeToolbarItemWithItemIdentifier:(NSString*)itemIdent key:(NSString*)itemKey
{
	NSToolbarItem*	toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] 	autorelease];
	NSString*	labelKey = [NSString stringWithFormat:@"tiLabel%@", itemKey];
	NSString*	paletteLabelKey	= [NSString stringWithFormat:@"tiPaletteLabel%@", itemKey];
	NSString*	toolTipKey = [NSString stringWithFormat:@"tiToolTip%@", itemKey];

	[toolbarItem setLabel: NSLocalizedStringFromTable(labelKey, @"ToolbarItems", itemKey)];
	[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(paletteLabelKey, @"ToolbarItems", 		[toolbarItem label])];
	[toolbarItem setToolTip: NSLocalizedStringFromTable(toolTipKey, @"ToolbarItems", [toolbarItem 	label])];

	return toolbarItem;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSToolbarItem*) makeToolbarItemWithItemIdentifier:(NSString*)itemIdent key:(NSString*)itemKey imageName:(NSString*)imageName target:(id)target action:(SEL)action
{
	NSToolbarItem*	toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemKey];
	[toolbarItem setImage: [NSImage imageNamed:imageName]];

	// Tell the item what message to send when it is clicked
	[toolbarItem setTarget: target];
	[toolbarItem setAction: action];
	return toolbarItem;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSToolbarItem*) makeToolbarItemWithItemIdentifier:(NSString*)itemIdent key:(NSString*)itemKey customView:(id)customView
{
	NSToolbarItem*	toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemKey];
	[toolbarItem setView: customView];

	[toolbarItem setMinSize:NSMakeSize(NSWidth([customView frame]), NSHeight([customView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([customView frame]), NSHeight([customView frame]))];

	return toolbarItem;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void) setupToolbar
{
	[typesetButton retain];
	[typesetButton removeFromSuperview];
	[programButton retain];
	[programButton removeFromSuperview];
	[typesetButtonEE retain];
	[typesetButtonEE removeFromSuperview];
	[programButtonEE retain];
	[programButtonEE removeFromSuperview];
	[tags retain];
	[tags removeFromSuperview];
	[popupButton retain];
	[popupButton removeFromSuperview];
	[autoCompleteButton retain];
	[autoCompleteButton removeFromSuperview];
	// added by mitsu --(H) Macro menu; macroButton
	[macroButton retain];
	[macroButton removeFromSuperview];
	[macroButtonEE retain];
	[macroButtonEE removeFromSuperview];
	[indexColorBox retain];
	[indexColorBox removeFromSuperview];
	// end addition
	[[self textWindow] setToolbar: [self makeToolbar: kSourceToolbarIdentifier]];


	[previousButton retain];
	[previousButton removeFromSuperview];
	[nextButton retain];
	[nextButton removeFromSuperview];
	[gotopageOutlet retain];
	[gotopageOutlet removeFromSuperview];
	[magnificationOutlet retain];
	[magnificationOutlet removeFromSuperview];
	[gotopageOutletKK retain];
	[gotopageOutletKK removeFromSuperview];
	[magnificationOutletKK retain];
	[magnificationOutletKK removeFromSuperview];
#ifdef MITSU_PDF
	[mouseModeMatrix retain];
	[mouseModeMatrix removeFromSuperview];
	[mouseModeMatrixKK retain];
	[mouseModeMatrixKK removeFromSuperview];
	// WARNING: this must be called now, because calling it when the matrix is active but offscreen causes defective toolbar display
	int mouseMode = [SUD integerForKey: PdfKitMouseModeKey];
	[mouseModeMatrixKK selectCellWithTag: mouseMode];
	
	

#endif
	[syncBox retain];
	[syncBox removeFromSuperview];
	[backforthKK retain];
	[backforthKK removeFromSuperview];

	// HACK: The following is a trick to get the NSSegmentedControl to display correctly
	// (i.e. the same way as in Preview.app). There seems to be a bug (or misfeature?) in
	// this control that causes it to display differently when its label is an empty string
	// than when its label is "not set", i.e. when we pass 0 instead of a NSString.
	[backforthKK setLabel:0 forSegment:0];
	[backforthKK setLabel:0 forSegment:1];

	[drawerKK retain];
	[drawerKK removeFromSuperview];

	[[self pdfWindow] setToolbar: [self makeToolbar: kPDFToolbarIdentifier]];
	[[self pdfKitWindow] setToolbar: [self makeToolbar: kPDFKitToolbarIdentifier]];
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void)doPreviousPage:(id)sender
{
	[[self pdfView] previousPage: sender];
}

- (void)doPreviousPageKK:(id)sender
{
	[[self pdfKitView] previousPage: sender];
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void)doNextPage:(id)sender
{
	[[self pdfView] nextPage: sender];
}

- (void)doNextPageKK:(id)sender
{
	[[self pdfKitView] nextPage: sender];
}

- (void)toggleTheDrawer:(id)sender
{
	[[self pdfKitView] toggleDrawer: sender];
}



// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
	// Required delegate method   Given an item identifier, self method returns an item
	// The toolbar will use self method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself

	NSToolbarItem *toolbarItem = 0;
	NSMenuItem *menuFormRep;
	NSMenu *submenu;
	id <NSMenuItem> submenuItem;

	//    if ([itemIdent isEqual: kSaveDocToolbarItemIdentifier]) {
	//		return [self makeToolbarItemWithItemIdentifier:itemIdent key:@"Save"
	//				imageName:@"SaveDocumentItemImage" target:self action:@selector(saveDocument:)];
	//	}

	// Source toolbar

	/*
	 if ([itemIdent isEqual: kTypesetTID]) {
		 return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 customView:typesetButton];
	 }
	 */

	if ([itemIdent isEqual: kTypesetTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:typesetButton];

		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		submenu = [[[NSMenu alloc] init] autorelease];
		submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Typeset", @"Typeset") action: @selector(doTypeset:) keyEquivalent:@""] autorelease];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}


	/*
	 if ([itemIdent isEqual: kProgramTID]) {
		 return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 customView:programButton];
	 }
	 */

	if ([itemIdent isEqual: kProgramTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:programButton];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];

		[menuFormRep setSubmenu: [programButton menu]];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}

	if ([itemIdent isEqual: kTeXTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"TeXAction" target:self action:@selector(doTexTemp:)];
	}

	if ([itemIdent isEqual: kLaTeXTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"LaTeXAction" target:self action:@selector(doLatexTemp:)];
	}

	if ([itemIdent isEqual: kBibTeXTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"BibTeXAction" target:self action:@selector(doBibtexTemp:)];
	}

	if ([itemIdent isEqual: kMakeIndexTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"MakeIndexAction" target:self action:@selector(doIndexTemp:)];
	}

	if ([itemIdent isEqual: kMetaPostTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"MetaPostAction" target:self action:@selector(doMetapostTemp:)];
	}

	if ([itemIdent isEqual: kConTeXTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"ConTeXAction" target:self action:@selector(doContextTemp:)];
	}

	if ([itemIdent isEqual: kSplitID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"split1" target:self action:@selector(splitWindow:)];
	}
	
	if ([itemIdent isEqual: kSplitKKTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"split1" target:self action:@selector(splitPreviewWindow:)];
	}

	if ([itemIdent isEqual: kDrawerKKTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"DrawerToggleToolbarImage" target:self action:@selector(toggleTheDrawer:)];
	}


	if ([itemIdent isEqual: kMetaFontID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"MetaFontAction" target:self action:@selector(doMetaFontTemp:)];
	}

	if ([itemIdent isEqual: kTagsTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:tags];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];

		[menuFormRep setSubmenu: [tags menu]];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}

	if ([itemIdent isEqual: kTemplatesID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:popupButton];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];

		[menuFormRep setSubmenu: [popupButton menu]];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}

	if ([itemIdent isEqual: kAutoCompleteID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
												   customView:autoCompleteButton];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		submenu = [[[NSMenu alloc] init] autorelease];
		submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"AutoComplete", @"AutoComplete")
												  action: @selector(changeAutoComplete:) keyEquivalent:@""] autorelease];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}

	// added by mitsu --(H) Macro menu; macroButton
	if ([itemIdent isEqual: kMacrosTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:macroButton];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];

		[menuFormRep setSubmenu: [macroButton menu]];
		[[TSMacroMenuController sharedInstance] addItemsToPopupButton: macroButton];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}
	// end addition


	// PDF toolbar

	/*
	 if ([itemIdent isEqual: kTypesetEETID]) {
		 return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 customView:typesetButtonEE];
	 }
	 */

	if ([itemIdent isEqual: kTypesetEETID]) {
		toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
													customView:typesetButtonEE];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		submenu = [[[NSMenu alloc] init] autorelease];
		submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Typeset", @"Typeset") action: @selector(doTypeset:) 				keyEquivalent:@""] autorelease];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}

	/*
		if ([itemIdent isEqual: kTypesetKKTID]) {
			toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
														customView:TypesetButtonKK];
			menuFormRep = [[[NSMenuItem alloc] init] autorelease];

			submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Typeset", @"Typeset") action: @selector(doTypeset:) 				keyEquivalent:@""] autorelease];
			[submenu addItem: submenuItem];
			[menuFormRep setSubmenu: submenu];
			[menuFormRep setTitle: [toolbarItem label]];
			[toolbarItem setMenuFormRepresentation: menuFormRep];
			return toolbarItem;
		}
	 */

	/*
	 if ([itemIdent isEqual: kProgramEETID]) {
		 return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 customView:programButtonEE];
	 }
	 */

	if ([itemIdent isEqual: kProgramEETID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:programButtonEE];

		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		[menuFormRep setTitle: [toolbarItem label]];

		submenu = [[[NSMenu alloc] init] autorelease];
		id <NSMenuItem> tempsubmenuItem;
		NSString *tempString;
		id tempTarget;
		SEL tempAction;
		int i;
		int j = [[programButtonEE menu] numberOfItems];
		for (i = 0; i < j; i++) {
			tempsubmenuItem = [[programButtonEE menu] itemAtIndex: i];
			tempString = [tempsubmenuItem title];
			tempTarget = [tempsubmenuItem target];
			tempAction = [tempsubmenuItem action];
			submenuItem = [[[NSMenuItem alloc] initWithTitle: tempString action:@selector(chooseProgramFF:)  keyEquivalent:@""] autorelease];
			[submenuItem setTarget: self];
			[submenuItem setTag: i];
			[submenu addItem: submenuItem];
		}


		[menuFormRep setSubmenu: submenu];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}

	/*
		if ([itemIdent isEqual: kProgramKKTID]) {
			toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:ProgramButtonKK];
			NSMenuItem*	menuFormRep = [[[NSMenuItem alloc] init] autorelease];

			[menuFormRep setSubmenu: [ProgramButtonKK menu]];
			[menuFormRep setTitle: [toolbarItem label]];
			[toolbarItem setMenuFormRepresentation: menuFormRep];

			return toolbarItem;
		}
	 */


	if ([itemIdent isEqual: kMacrosEETID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:macroButtonEE];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];

		[menuFormRep setSubmenu: [macroButtonEE menu]];
		[[TSMacroMenuController sharedInstance] addItemsToPopupButton: macroButtonEE];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}

	/*
	 if ([itemIdent isEqual: kMacrosKKTID]) {
		 toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:macroButtonKK];
		 menuFormRep = [[[NSMenuItem alloc] init] autorelease];

		 [menuFormRep setSubmenu: [macroButtonKK menu]];
		 [[TSMacroMenuController sharedInstance] addItemsToPopupButton: macroButtonKK];
		 [menuFormRep setTitle: [toolbarItem label]];
		 [toolbarItem setMenuFormRepresentation: menuFormRep];

		 return toolbarItem;
	 }
	 */


	/*
	 if ([itemIdent isEqual: kPreviousPageButtonTID]) {
		 return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 customView:previousButton];
	 }

	 if ([itemIdent isEqual: kNextPageButtonTID]) {
		 return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 customView:nextButton];
	 }
	 */

	if ([itemIdent isEqual: kPreviousPageButtonTID]) {
		toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
													customView:previousButton];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		[menuFormRep setTitle: [toolbarItem label]];
		[menuFormRep setAction: @selector(previousPage:)];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}

	if ([itemIdent isEqual: kNextPageButtonTID]) {
		toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
													customView:nextButton];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		[menuFormRep setTitle: [toolbarItem label]];
		[menuFormRep setAction: @selector(nextPage:)];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}


	if ([itemIdent isEqual: kPreviousPageTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
							 imageName:@"PreviousPageAction" target:self action:@selector(doPreviousPage:)];
	}

	if ([itemIdent isEqual: kNextPageTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
							 imageName:@"NextPageAction" target:self action:@selector(doNextPage:)];
	}

	if ([itemIdent isEqual: kBackForthKKTID]) {
		toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
													customView:backforthKK];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		[menuFormRep setTitle: [toolbarItem label]];

		submenu = [[[NSMenu alloc] init] autorelease];
		submenuItem = [[[NSMenuItem alloc] initWithTitle: @"Back" action: @selector(doBack:) keyEquivalent:@""] autorelease];
		[submenuItem setTarget: self];
		[submenu addItem: submenuItem];
		submenuItem = [[[NSMenuItem alloc] initWithTitle: @"Forward" action: @selector(doForward:) keyEquivalent:@""] autorelease];
		[submenuItem setTarget: self];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];



		// [menuFormRep setAction: @selector(doBackForth:)];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}


	if ([itemIdent isEqual: kPreviousPageButtonKKTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"PreviousPageAlternateAction" target:self action:@selector(doPreviousPageKK:)];
	}

	if ([itemIdent isEqual: kNextPageButtonKKTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"NextPageAlternateAction" target:self action:@selector(doNextPageKK:)];
	}


	if ([itemIdent isEqual: kPreviousPageKKTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"PreviousPageAction" target:self action:@selector(doPreviousPageKK:)];
	}

	if ([itemIdent isEqual: kNextPageKKTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"NextPageAction" target:self action:@selector(doNextPageKK:)];
	}

	/*
	 if ([itemIdent isEqual: kGotoPageTID]) {
		 return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:gotopageOutlet];
	 }

	 if ([itemIdent isEqual: kMagnificationTID]) {
		 return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:magnificationOutlet];
	 }
	 */
	if ([itemIdent isEqual: kGotoPageTID]) {
		toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
													customView:gotopageOutlet];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		/*
		 submenu = [[[NSMenu alloc] init] autorelease];
		 submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Page Number Panel", @"Page Number Panel") action: 				@selector(doTextPage:) 	keyEquivalent:@""] autorelease];
		 [submenu addItem: submenuItem];
		 [menuFormRep setSubmenu: submenu];*/
		[menuFormRep setTitle: NSLocalizedString(@"Page Number", @"Page Number")];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		[menuFormRep setAction: @selector(doTextPage:)];
		[menuFormRep setTarget: pdfWindow];
		return toolbarItem;
	}

	if ([itemIdent isEqual: kGotoPageKKTID]) {
		toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
													customView:gotopageOutletKK];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		/*
		 submenu = [[[NSMenu alloc] init] autorelease];
		 submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Page Number Panel", @"Page Number Panel") action: 				@selector(doTextPage:) 	keyEquivalent:@""] autorelease];
		 [submenu addItem: submenuItem];
		 [menuFormRep setSubmenu: submenu];*/
		[menuFormRep setTitle: NSLocalizedString(@"Page Number", @"Page Number")];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		[menuFormRep setAction: @selector(doTextPage:)];
		[menuFormRep setTarget: pdfKitWindow];
		return toolbarItem;
	}


	if ([itemIdent isEqual: kMagnificationTID]) {
		toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
													customView:magnificationOutlet];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		/* submenu = [[[NSMenu alloc] init] autorelease];
		submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Magnification Panel", @"Magnification Panel") action: 			@selector(doTextMagnify:) keyEquivalent:@""] autorelease];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];*/
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		[menuFormRep setAction: @selector(doTextMagnify:)];
		[menuFormRep setTarget: pdfWindow];
		return toolbarItem;
	}


	if ([itemIdent isEqual: kMagnificationKKTID]) {
		toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
													customView:magnificationOutletKK];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		/* submenu = [[[NSMenu alloc] init] autorelease];
		submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Magnification Panel", @"Magnification Panel") action: 			@selector(doTextMagnify:) keyEquivalent:@""] autorelease];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];*/
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		[menuFormRep setAction: @selector(doTextMagnify:)];
		[menuFormRep setTarget: pdfKitWindow];
		return toolbarItem;
	}

#ifdef MITSU_PDF
	// mitsu 1.29 (O)
	if ([itemIdent isEqual: kMouseModeTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:mouseModeMatrix];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		[menuFormRep setSubmenu: mouseModeMenu];

		/* or one can set up menu by hand
			NSMenu *		menu = [[[NSMenu alloc] initWithTitle: [toolbarItem label]] autorelease];
		[menuFormRep setTarget: pdfView];
		[menuFormRep setAction: @selector(changeMouseMode:)];
		NSMenuItem*	item = [menu addItemWithTitle: NSLocalizedString(@"Scroll", @"Scroll")
										   action: @selector(changeMouseMode:) keyEquivalent:@""];
		[item setTarget: pdfView];
		[item setTag: MOUSE_MODE_SCROLL];

		item = [menu addItemWithTitle: NSLocalizedString(@"MagnifyingGlass", @"MagnifyingGlass")
							   action: @selector(changeMouseMode:) keyEquivalent:@""];
		[item setTarget: pdfView];
		[item setTag: MOUSE_MODE_MAG_GLASS];

		item = [menu addItemWithTitle: NSLocalizedString(@"MagnifyingGlass Large", @"MagnifyingGlass Large")
							   action: @selector(changeMouseMode:) keyEquivalent:@""];
		[item setTarget: pdfView];
		[item setTag: MOUSE_MODE_MAG_GLASS_L];

		item = [menu addItemWithTitle: NSLocalizedString(@"Select", @"Select")
							   action: @selector(changeMouseMode:) keyEquivalent:@""];
		[item setTarget: pdfView];
		[item setTag: MOUSE_MODE_SELECT];

		[menuFormRep setSubmenu: menu];*/

		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}


	// mitsu 1.29 (O)
	if ([itemIdent isEqual: kMouseModeKKTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:mouseModeMatrixKK];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		[menuFormRep setSubmenu: mouseModeMenuKit];

		/* or one can set up menu by hand
			NSMenu *		menu = [[[NSMenu alloc] initWithTitle: [toolbarItem label]] autorelease];
		[menuFormRep setTarget: pdfView];
		[menuFormRep setAction: @selector(changeMouseMode:)];
		NSMenuItem*	item = [menu addItemWithTitle: NSLocalizedString(@"Scroll", @"Scroll")
										   action: @selector(changeMouseMode:) keyEquivalent:@""];
		[item setTarget: pdfView];
		[item setTag: MOUSE_MODE_SCROLL];

		item = [menu addItemWithTitle: NSLocalizedString(@"MagnifyingGlass", @"MagnifyingGlass")
							   action: @selector(changeMouseMode:) keyEquivalent:@""];
		[item setTarget: pdfView];
		[item setTag: MOUSE_MODE_MAG_GLASS];

		item = [menu addItemWithTitle: NSLocalizedString(@"MagnifyingGlass Large", @"MagnifyingGlass Large")
							   action: @selector(changeMouseMode:) keyEquivalent:@""];
		[item setTarget: pdfView];
		[item setTag: MOUSE_MODE_MAG_GLASS_L];

		item = [menu addItemWithTitle: NSLocalizedString(@"Select", @"Select")
							   action: @selector(changeMouseMode:) keyEquivalent:@""];
		[item setTarget: pdfView];
		[item setTag: MOUSE_MODE_SELECT];

		[menuFormRep setSubmenu: menu];*/

		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		

		return toolbarItem;
		// return nil;
	}

	// end mitsu 1.29
#endif

	if ([itemIdent isEqual: kSyncMarksTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
												   customView:syncBox];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		submenu = [[[NSMenu alloc] init] autorelease];
		submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Sync Marks", @"Sync Marks")
							   //                 action: @selector(changeShowSync:) keyEquivalent:@""] autorelease];
												  action: @selector(flipShowSync:) keyEquivalent:@""] autorelease];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}
	
	if ([itemIdent isEqual: kColorIndexTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
												   customView:indexColorBox];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		submenu = [[[NSMenu alloc] init] autorelease];
		submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Color Index", @"Color Index")
												  action: @selector(flipIndexColorState:) keyEquivalent:@""] autorelease];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}




	//	if ([itemIdent isEqual: SearchDocToolbarItemIdentifier]) {

	//		toolbarItem 	= [self makeToolbarItemWithItemIdentifier:itemIdent key:@"Search"];

	//	NSMenu *submenu = nil;
	//	NSMenuItem *submenuItem = nil, *menuFormRep = nil;


	// Use a custom view, a text field, for the search item
	//	[toolbarItem setView: searchFieldOutlet];
	//	[toolbarItem setMinSize:NSMakeSize(30, NSHeight([searchFieldOutlet frame]))];
	//	[toolbarItem setMaxSize:NSMakeSize(400,NSHeight([searchFieldOutlet frame]))];

	// By default, in text only mode, a custom items label will be shown as disabled text, but you can provide a
	// custom menu of your own by using <item> setMenuFormRepresentation]

	/*
	 submenu = [[[NSMenu alloc] init] autorelease];
	 submenuItem = [[[NSMenuItem alloc] initWithTitle: @"Search Panel" action: @selector(searchUsingSearchPanel:) keyEquivalent: @""] autorelease];
	 menuFormRep = [[[NSMenuItem alloc] init] autorelease];

	 [submenu addItem: submenuItem];
	 [submenuItem setTarget: self];
	 [menuFormRep setSubmenu: submenu];
	 [menuFormRep setTitle: [toolbarItem label]];
	 [toolbarItem setMenuFormRepresentation: menuFormRep];
	 */
	//		return toolbarItem;
	//   }

	// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa
	// Returning nil will inform the toolbar self kind of item is not supported
	return nil;
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
	// Required delegate method   Returns the ordered list of items to be shown in the toolbar by default
	// If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
	// user chooses to revert to the default items self set will be used

	NSString*	toolbarID = [toolbar identifier];

	if ([toolbarID isEqual:kSourceToolbarIdentifier]) {

		return [NSArray arrayWithObjects:
					kTypesetTID,
					kProgramTID,
					NSToolbarPrintItemIdentifier,
					// NSToolbarSeparatorItemIdentifier,
					// kLaTeXTID,
					// kBibTeXTID,
					kMacrosTID,
					kTagsTID,
					kTemplatesID,
					NSToolbarFlexibleSpaceItemIdentifier,
					kSplitID,
					// NSToolbarFlexibleSpaceItemIdentifier,
					// NSToolbarSpaceItemIdentifier,
				nil];
	}

	if ([toolbarID isEqual:kPDFToolbarIdentifier]) {

		return [NSArray arrayWithObjects:
					// kPreviousPageButtonTID,
					// kNextPageButtonTID,
					kPreviousPageTID,
					kNextPageTID,
					kTypesetEETID,
					// kProgramEETID,
					NSToolbarPrintItemIdentifier,
					// NSToolbarSeparatorItemIdentifier,
					kMagnificationTID,
					kGotoPageTID,
					kMouseModeTID, // mitsu 1.29 (O)
					NSToolbarFlexibleSpaceItemIdentifier,
					NSToolbarSpaceItemIdentifier,
				nil];
	}

	if ([toolbarID isEqual:kPDFKitToolbarIdentifier]) {

		return [NSArray arrayWithObjects:
					// kPreviousPageButtonTID,
					// kNextPageButtonTID,
					kPreviousPageKKTID,
					kNextPageKKTID,
					kBackForthKKTID,
					kDrawerKKTID,
				   // kTypesetEETID,
					// kProgramEETID,
					NSToolbarPrintItemIdentifier,
					// NSToolbarSeparatorItemIdentifier,
					kMagnificationKKTID,
					kGotoPageKKTID,
					kMouseModeKKTID, // mitsu 1.29 (O)
					NSToolbarFlexibleSpaceItemIdentifier,
					kSplitKKTID,
					// NSToolbarSpaceItemIdentifier,
				nil];
	}


	return [NSArray array];
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
	// Required delegate method   Returns the list of all allowed items by identifier   By default, the toolbar
	// does not assume any items are allowed, even the separator   So, every allowed item must be explicitly listed
	// The set of allowed items is used to construct the customization palette

	NSString*	toolbarID = [toolbar identifier];

	if ([toolbarID isEqual:kSourceToolbarIdentifier]) {

		return [NSArray arrayWithObjects:
//					kSaveDocToolbarItemIdentifier,
					kTypesetTID,
					kProgramTID,
					kTeXTID,
					kLaTeXTID,
					kBibTeXTID,
					kMakeIndexTID,
					kMetaPostTID,
					kConTeXTID,
					kMetaFontID,
					kTagsTID,
					kTemplatesID,
					kAutoCompleteID,
					kSplitID,
					kMacrosTID,
					kColorIndexTID,
					NSToolbarPrintItemIdentifier,
					NSToolbarCustomizeToolbarItemIdentifier,
					NSToolbarFlexibleSpaceItemIdentifier,
					NSToolbarSpaceItemIdentifier,
					NSToolbarSeparatorItemIdentifier,
				nil];
	}

	if ([toolbarID isEqual:kPDFToolbarIdentifier]) {

		return [NSArray arrayWithObjects:
//					kSaveDocToolbarItemIdentifier,
					kPreviousPageButtonTID,
					kNextPageButtonTID,
					kPreviousPageTID,
					kNextPageTID,
					kTypesetEETID,
					kProgramEETID,
					kMacrosEETID,
					kTeXTID,
					kLaTeXTID,
					kBibTeXTID,
					kMakeIndexTID,
					kMetaPostTID,
					kConTeXTID,
					kMetaFontID,
					kGotoPageTID,
					kMagnificationTID,
					kMouseModeTID,
					kSyncMarksTID,
					NSToolbarPrintItemIdentifier,
					NSToolbarCustomizeToolbarItemIdentifier,
					NSToolbarFlexibleSpaceItemIdentifier,
					NSToolbarSpaceItemIdentifier,
					NSToolbarSeparatorItemIdentifier,
				nil];

	}

	if ([toolbarID isEqual:kPDFKitToolbarIdentifier]) {

		return [NSArray arrayWithObjects:
//					kSaveDocToolbarItemIdentifier,
					kPreviousPageButtonKKTID,
					kNextPageButtonKKTID,
					kPreviousPageKKTID,
					kNextPageKKTID,
					kBackForthKKTID,
					kDrawerKKTID,
					kTypesetEETID,
					kProgramEETID,
					kMacrosEETID,
					kTeXTID,
					kLaTeXTID,
					kBibTeXTID,
					kMakeIndexTID,
					kMetaPostTID,
					kConTeXTID,
					kMetaFontID,
					kGotoPageKKTID,
					kMagnificationKKTID,
					kMouseModeKKTID,
					kSyncMarksTID,
					kSplitKKTID,
					NSToolbarPrintItemIdentifier,
					NSToolbarCustomizeToolbarItemIdentifier,
					NSToolbarFlexibleSpaceItemIdentifier,
					NSToolbarSpaceItemIdentifier,
					NSToolbarSeparatorItemIdentifier,
				nil];

	}


	return [NSArray array];
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void) toolbarWillAddItem: (NSNotification *) notif {
	// Optional delegate method   Before an new item is added to the toolbar, self notification is posted
	// self is the best place to notice a new item is going into the toolbar   For instance, if you need to
	// cache a reference to the toolbar item or need to set up some initial state, self is the best place
	// to do it    The notification object is the toolbar to which the item is being added   The item being
	// added is found by referencing the @"item" key in the userInfo
	NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
//    if([[addedItem itemIdentifier] isEqual: SearchDocToolbarItemIdentifier]) {
//	activeSearchItem = [addedItem retain];
//	[activeSearchItem setTarget: self];
//	[activeSearchItem setAction: @selector(searchUsingToolbarTextField:)];
//    } else
	if ([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {

		NSString*	toolbarID = [[addedItem toolbar] identifier];

		if ([toolbarID isEqual:kSourceToolbarIdentifier]) {

			[addedItem setToolTip: NSLocalizedStringFromTable(@"tiToolTipPrintSource",
									@"ToolbarItems",  @"Print the source")];
			[addedItem setTarget: self];
			[addedItem setAction: @selector(printSource:)];

		} else if ([toolbarID isEqual:kPDFToolbarIdentifier]) {

			[addedItem setToolTip: NSLocalizedStringFromTable(@"tiToolTipPrint",
									@"ToolbarItems",  @"Print the document")];
			[addedItem setTarget: self];
		}

		 else if ([toolbarID isEqual:kPDFKitToolbarIdentifier]) {

			[addedItem setToolTip: NSLocalizedStringFromTable(@"tiToolTipPrint",
									@"ToolbarItems",  @"Print the document")];
			[addedItem setTarget: self];
		}

	}
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void) toolbarDidRemoveItem: (NSNotification *) notif {
	// Optional delegate method   After an item is removed from a toolbar the notification is sent   self allows
	// the chance to tear down information related to the item that may have been cached   The notification object
	// is the toolbar to which the item is being added   The item being added is found by referencing the @"item"
	// key in the userInfo
//    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
//	if (removedItem==activeSearchItem) {
//		[activeSearchItem autorelease];
//		activeSearchItem = nil;
//  }
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------
// this is based on validateMenuItem

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {
	// Optional method   self message is sent to us since we are the target of some toolbar item actions
	// (for example:  of the save items action)
	BOOL 		enable 		= NO;
	NSString	*toolbarID	= [[toolbarItem toolbar] identifier];
	NSString	*itemID		= [toolbarItem itemIdentifier];

	// FIXME: The following line of code is broken in two ways. First off, it shouldn't
	// invoke validateMenuItem on 'super' but rather it should use 'self'.
	// Secondly, even if one fixes that, this doesn't help (even if you fix the
	// resulting crash), because other methods are use -- e.g. doLatexTemp: instead
	// of doLatex:.
	// It might be possible to reunify the two methods again, but for the time being,
	// I disable it.  (Max Horn, Aug 07 2005)
	//enable =  [super validateMenuItem: toolbarItem];
	enable = YES;

	if (fileIsTex) {

		if ([itemID isEqual: kSaveDocToolbarItemIdentifier]) {
		// We will return YES (ie  the button is enabled) only when the document is dirty and needs saving
			enable = [self isDocumentEdited];
		} else if ([itemID isEqual: NSToolbarPrintItemIdentifier]) {
			enable = YES;
		}
	}
	else if ([itemID isEqual: kSaveDocToolbarItemIdentifier]) {

		enable = (_documentType == isOther);

	}
	else if ([itemID isEqual: NSToolbarPrintItemIdentifier]) {

		if ([toolbarID isEqual:kSourceToolbarIdentifier]) {
			enable = (_documentType == isOther);
		} else if ([toolbarID isEqual:kPDFToolbarIdentifier]) {
			enable = ((_documentType == isPDF) || (_documentType == isJPG) || (_documentType == isTIFF));
		} else if ([toolbarID isEqual:kPDFKitToolbarIdentifier]) {
			enable = ((_documentType == isPDF) || (_documentType == isJPG) || (_documentType == isTIFF));
		}

	}
	else if (([itemID isEqual: kPreviousPageButtonTID]) ||
			([itemID isEqual: kPreviousPageTID]) ||
			([itemID isEqual: kPreviousPageButtonKKTID]) ||
			([itemID isEqual: kPreviousPageKKTID])) {
						// TODO: Check whether we are on the first page
						enable = (_documentType == isPDF);
	}
	else if	(([itemID isEqual: kNextPageButtonTID]) ||
			([itemID isEqual: kNextPageTID]) ||
			([itemID isEqual: kNextPageButtonKKTID]) ||
			([itemID isEqual: kNextPageKKTID])) {
						// TODO: Check whether we are on the last page
						enable = (_documentType == isPDF);
	}

	return enable;
}


@end
