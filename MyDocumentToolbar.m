// ================================================================================
//  MyDocumentToolbar.m
// ================================================================================
//	TeXShop
//
//  Created by Anton Leuski on Sun Feb 03 2002.
//  Copyright (c) 2002 Anton Leuski. 
//
//	This source is distributed under the terms of GNU Public License (GPL) 
//	see www.gnu.org for more info
//
//	Parts of this code are taken from Apple's example SimpleToolbar
//
// ================================================================================

#import "UseMitsu.h"

#import "MyDocumentToolbar.h"

#ifdef MITSU_PDF
#import "MyPDFView.h"
#else
#import "MyView.h"
#endif

// added by mitsu --(H) Macro menu; macroButton
#import "MacroMenuController.h"
// end addition


static NSString* 	kSourceToolbarIdentifier 	= @"Source Toolbar Identifier";
static NSString* 	kPDFToolbarIdentifier 		= @"PDF Toolbar Identifier";
static NSString*	kSaveDocToolbarItemIdentifier 	= @"Save Document Item Identifier";

// Source window toolbar items
static NSString*	kTypesetTID			= @"Typeset";
static NSString*	kProgramTID			= @"Program";
static NSString*	kTeXTID 			= @"TeX";
static NSString*	kLaTeXTID 			= @"LaTeX";
static NSString*	kBibTeXTID 			= @"BibTeX";
static NSString*	kMakeIndexTID 			= @"MakeIndex";
static NSString*	kMetaPostTID 			= @"MetaPost";
static NSString*	kConTeXTID 			= @"ConTeX";
static NSString*	kMetaFontID			= @"MetaFont";
static NSString*	kTagsTID 			= @"Tags";
static NSString*	kTemplatesID 			= @"Templates";
static NSString*	kAutoCompleteID			= @"AutoComplete";  //warning: used in MyDocument's fixAutoMenu
// forsplit
static NSString*	kSplitID			= @"Split";
// end forsplit
// added by mitsu --(H) Macro menu; macroButton
static NSString*	kMacrosTID			= @"Macros";
// end addition
	

// PDF Window toolbar items
static NSString*	kTypesetEETID			= @"TypesetEE";
static NSString*	kProgramEETID			= @"ProgramEE";
static NSString*	kPreviousPageButtonTID 		= @"PreviousPageButton";
static NSString*	kPreviousPageTID 		= @"PreviousPage";
static NSString*	kNextPageButtonTID		= @"NextPageButton";
static NSString*	kNextPageTID 			= @"NextPage";
static NSString*	kGotoPageTID 			= @"GotoPage";
static NSString*	kMagnificationTID 		= @"Magnification";
#ifdef MITSU_PDF
static NSString*	kMouseModeTID 			= @"MouseMode";
static NSString*	kMacrosEETID			= @"MacrosEE";
#endif


@implementation MyDocument (ToolbarSupport)

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
#ifdef MITSU_PDF
	[mouseModeMatrix retain];
	[mouseModeMatrix removeFromSuperview];
#endif
	[[self pdfWindow] setToolbar: [self makeToolbar: kPDFToolbarIdentifier]];
}

/* This is all done automatically by MyDocument. I've left it temporarily
    for amusement. Koch.
- (void)dealloc
{
        [typesetButton release];
        [programButton release];
        [typesetButtonEE release];
        [programButtonEE release];
        [tags release];
        [popupButton release];
        [previousButton release];
        [nextButton release];
        [gotopageOutlet release];
        [magnificationOutlet release];
        
        [super dealloc];
}
*/

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void)doPreviousPage:(id)sender
{
#ifdef MITSU_PDF
    [((MyPDFView*)[self pdfView]) previousPage: sender];
#else
    [((MyView*)[self pdfView]) previousPage: sender];
#endif
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void)doNextPage:(id)sender
{
#ifdef MITSU_PDF
    [((MyPDFView*)[self pdfView]) nextPage: sender];
#else
    [((MyView*)[self pdfView]) nextPage: sender];
#endif
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method   Given an item identifier, self method returns an item 
    // The toolbar will use self method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself

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
                NSToolbarItem* toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
				customView:typesetButton];
                NSMenuItem* menuFormRep = [[[NSMenuItem alloc] init] autorelease];
                NSMenu* submenu = [[[NSMenu alloc] init] autorelease];
		NSMenuItem* submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Typeset", @"Typeset") action: @selector(doTypeset:) keyEquivalent:@""] autorelease];
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
		NSToolbarItem*	toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:programButton];
		NSMenuItem*	menuFormRep = [[[NSMenuItem alloc] init] autorelease];

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
        
// forsplit        
    if ([itemIdent isEqual: kSplitID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
				imageName:@"split1" target:self action:@selector(splitWindow:)];
	}
// end forsplit

        
    if ([itemIdent isEqual: kMetaFontID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
				imageName:@"MetaFontAction" target:self action:@selector(doMetaFontTemp:)];
	}

    if ([itemIdent isEqual: kTagsTID]) {
		NSToolbarItem*	toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:tags];
		NSMenuItem*		menuFormRep = [[[NSMenuItem alloc] init] autorelease];

		[menuFormRep setSubmenu: [tags menu]];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}

    if ([itemIdent isEqual: kTemplatesID]) {
		NSToolbarItem*	toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:popupButton];
		NSMenuItem*		menuFormRep = [[[NSMenuItem alloc] init] autorelease];

		[menuFormRep setSubmenu: [popupButton menu]];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}
        
    if ([itemIdent isEqual: kAutoCompleteID]) {
                NSToolbarItem*	toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
				customView:autoCompleteButton];
		NSMenuItem* menuFormRep = [[[NSMenuItem alloc] init] autorelease];
                NSMenu* submenu = [[[NSMenu alloc] init] autorelease];
		NSMenuItem* submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"AutoComplete", @"AutoComplete")
                    action: @selector(changeAutoComplete:) keyEquivalent:@""] autorelease];
                [submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
                return toolbarItem;
        }
        
// added by mitsu --(H) Macro menu; macroButton
    if ([itemIdent isEqual: kMacrosTID]) {
		NSToolbarItem*	toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:macroButton];
		NSMenuItem*		menuFormRep = [[[NSMenuItem alloc] init] autorelease];

		[menuFormRep setSubmenu: [macroButton menu]];
		[[MacroMenuController sharedInstance] addItemsToPopupButton: macroButton];
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
                NSToolbarItem* toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
				customView:typesetButtonEE];
                NSMenuItem* menuFormRep = [[[NSMenuItem alloc] init] autorelease];
                NSMenu* submenu = [[[NSMenu alloc] init] autorelease];
		NSMenuItem* submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Typeset", @"Typeset") action: @selector(doTypeset:) 				keyEquivalent:@""] autorelease];
                [submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
                return toolbarItem;
	}

/*
    if ([itemIdent isEqual: kProgramEETID]) {
                return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
				customView:programButtonEE];
	}
*/
        
    if ([itemIdent isEqual: kProgramEETID]) {
		NSToolbarItem*	toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:programButtonEE];
		NSMenuItem*	menuFormRep = [[[NSMenuItem alloc] init] autorelease];

		[menuFormRep setSubmenu: [programButtonEE menu]];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}
        
    if ([itemIdent isEqual: kMacrosEETID]) {
		NSToolbarItem*	toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:macroButtonEE];
		NSMenuItem*		menuFormRep = [[[NSMenuItem alloc] init] autorelease];

		[menuFormRep setSubmenu: [macroButtonEE menu]];
		[[MacroMenuController sharedInstance] addItemsToPopupButton: macroButtonEE];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}


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
                NSToolbarItem* toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
				customView:previousButton];
                NSMenuItem* menuFormRep = [[[NSMenuItem alloc] init] autorelease];
                [menuFormRep setTitle: [toolbarItem label]];
                [menuFormRep setAction: @selector(previousPage:)];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
                return toolbarItem;
	}
        
    if ([itemIdent isEqual: kNextPageButtonTID]) {
                NSToolbarItem* toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
				customView:nextButton];
                NSMenuItem* menuFormRep = [[[NSMenuItem alloc] init] autorelease];
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

/*
    if ([itemIdent isEqual: kGotoPageTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:gotopageOutlet];
	}

    if ([itemIdent isEqual: kMagnificationTID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:magnificationOutlet];
	}
*/
    if ([itemIdent isEqual: kGotoPageTID]) {
                NSToolbarItem* toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
				customView:gotopageOutlet];
                NSMenuItem* menuFormRep = [[[NSMenuItem alloc] init] autorelease];
				/*
                NSMenu* submenu = [[[NSMenu alloc] init] autorelease];
		NSMenuItem* submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Page Number Panel", @"Page Number Panel") action: 				@selector(doTextPage:) 	keyEquivalent:@""] autorelease];
                [submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];*/
                [menuFormRep setTitle: NSLocalizedString(@"Page Number", @"Page Number")];
               [toolbarItem setMenuFormRepresentation: menuFormRep];
				[menuFormRep setAction: @selector(doTextPage:)];
				[menuFormRep setTarget: pdfWindow];
                return toolbarItem;
                }
                
    if ([itemIdent isEqual: kMagnificationTID]) {
                NSToolbarItem* toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
				customView:magnificationOutlet];
                NSMenuItem* menuFormRep = [[[NSMenuItem alloc] init] autorelease];
                /* NSMenu* submenu = [[[NSMenu alloc] init] autorelease];
		NSMenuItem* submenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Magnification Panel", @"Magnification Panel") action: 			@selector(doTextMagnify:) keyEquivalent:@""] autorelease];
                [submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];*/
                [menuFormRep setTitle: [toolbarItem label]];
                [toolbarItem setMenuFormRepresentation: menuFormRep];
				[menuFormRep setAction: @selector(doTextMagnify:)];
				[menuFormRep setTarget: pdfWindow];
                return toolbarItem;
                }
                
#ifdef MITSU_PDF
// mitsu 1.29 (O)
    if ([itemIdent isEqual: kMouseModeTID]) {
		NSToolbarItem*	toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:mouseModeMatrix];
		NSMenuItem*		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
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
// end mitsu 1.29
#endif


//	if ([itemIdent isEqual: SearchDocToolbarItemIdentifier]) {
	
//		NSToolbarItem*	toolbarItem 	= [self makeToolbarItemWithItemIdentifier:itemIdent key:@"Search"];

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
                                        // added by mitsu --(H) Macro menu; macroButton
					kMacrosTID,
                                        // end addition
					kTagsTID,
					kTemplatesID,
                                         // forsplit
					NSToolbarFlexibleSpaceItemIdentifier, 
					kSplitID,
                                        // forsplit
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
#ifdef MITSU_PDF
                                        kMouseModeTID, // mitsu 1.29 (O)
#endif
					NSToolbarFlexibleSpaceItemIdentifier, 
					NSToolbarSpaceItemIdentifier, 
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
                                         // forsplit
                                        kSplitID,
                                        // end forsplit
                                        // added by mitsu --(H) Macro menu; macroButton
					kMacrosTID,
                                        // end addition
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
#ifdef MITSU_PDF
                                        kMouseModeTID, // mitsu 1.29 (O)
#endif
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
	NSString*	toolbarID	= [[toolbarItem toolbar] identifier];
	
	if (fileIsTex) {

		enable = YES;
		
		if ([[toolbarItem itemIdentifier] isEqual: kSaveDocToolbarItemIdentifier]) {
		// We will return YES (ie  the button is enabled) only when the document is dirty and needs saving 
			enable = [self isDocumentEdited];
		} else if ([[toolbarItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {
			enable = YES;
		}	

		return enable;
	}
	
	if ([[toolbarItem itemIdentifier] isEqual: kSaveDocToolbarItemIdentifier]) {

		enable = (myImageType == isOther);
		
	} else if ([[toolbarItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {

		if ([toolbarID isEqual:kSourceToolbarIdentifier]) {
			enable = (myImageType == isOther);
		} else if ([toolbarID isEqual:kPDFToolbarIdentifier]) {
			enable = ((myImageType == isPDF) || (myImageType == isJPG) || (myImageType == isTIFF));
		}

	}
        
        else if (([[toolbarItem itemIdentifier] isEqual: kPreviousPageButtonTID]) ||
                ([[toolbarItem itemIdentifier] isEqual: kPreviousPageTID]) ||
                ([[toolbarItem itemIdentifier] isEqual: kNextPageButtonTID]) ||
                ([[toolbarItem itemIdentifier] isEqual: kNextPageTID])) 
                        enable = (myImageType == isPDF);  

    return enable;
}


@end
