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

/*
 * Revised on August 1, 2018 by Richard Koch
 */

#import "UseMitsu.h"
#import "globals.h"

#import "TSToolbarController.h"

#import "MyPDFView.h"
#import "MyPDFKitView.h"
#import "TSToolbar.h"

// added by mitsu --(H) Macro menu; macroButton
#import "TSMacroMenuController.h"
// end addition


static NSString* 	kSourceToolbarIdentifier 	= @"Source Toolbar Identifier";
static NSString* 	kPDFToolbarIdentifier 		= @"PDF Toolbar Identifier";
static NSString*	kPDFKitToolbarIdentifier	= @"PDFKit Toolbar Identifier";
static NSString*    kFullWindowToolbarIdentifier = @"Full Window Toolbar Identifier";
static NSString*    kHtmlWindowToolbarIdentifier = @"HTML Window Toolbar Identifier";

// Source window toolbar items
static NSString*	kTypesetTID			= @"Typeset";
static NSString*	kProgramTID			= @"Program";
static NSString*	kTeXTID 			= @"TeX";
static NSString*	kLaTeXTID 			= @"LaTeX";
static NSString*	kBibTeXTID 			= @"BibTeX";
static NSString*	kMakeIndexTID 		= @"MakeIndex";
static NSString*	kMetaPostTID 		= @"MetaPost";
//static NSString*	kConTeXTID 			= @"ConTeX";
static NSString*	kMetaFontID			= @"MetaFont";
static NSString*    kTagsTID             = @"Tags";
static NSString*    kLabelsTID           = @"Labels";        //NDS added dropdown for going to a label
static NSString*    kUpdateTID           = @"Update";       // Koch to update tags and labels
static NSString*	kTemplatesID 		= @"Templates";
static NSString*	kAutoCompleteID		= @"AutoComplete";  //warning: used in TSDocument's fixAutoMenu
static NSString*	kShowFullPathID		= @"ShowFullPath";  // added by Terada
static NSString* kColorIndexTID		= @"ColorIndex";
static NSString* kSharingTID          = @"Sharing";
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
static NSString*    kSearchKKTID             = @"SearchKIT";
static NSString*    kSharingKKTID          = @"SharingKIT";
static NSString*	kSplitKKTID				= @"SplitKIT";

static NSString*    kHandKKTID              = @"HandKIT";
static NSString*    kTextKKTID              = @"TextKIT";
static NSString*    kGlassKKTID             = @"GlassKit";
static NSString*    kDashKKTID              = @"DashKit";
static NSString*    kToolsKKTID             = @"ToolsKit";
#endif

// FullSplitWindow special toolbar items
static NSString*    skTypesetTID        = @"TypesetSplit";
static NSString*	skProgramTID		= @"ProgramSplit";
static NSString*	skMacrosTID			= @"MacrosSplit";
static NSString*    skTemplatesID       = @"TemplatesSplit";
static NSString*	skTagsTID 			= @"TagsSplit";
static NSString*    skLabelsTID           = @"LabelsSplit";        //NDS added dropdown for going to a label
static NSString*    skUpdateTID           = @"UpdateSplit";
static NSString*	skGotoPageKKTID 	= @"GotoPageSplit";
static NSString*    skMagnificationKKTID = @"MagnificationSplit";
static NSString*	skAutoCompleteID	 = @"AutoCompleteSplit";
static NSString*    skColorIndexTID		= @"ColorIndexSplit";
static NSString *   skSharingTID       = @"SharingSplit";
static NSString*    skSearchTID          = @"SearchKITSplit";
static NSString*    skMouseModeTID         = @"MouseModeKITSplit";
static NSString*    skBackForthKKTID       = @"BackForthKITSplit";

// HtmlWindow special toolbar items
static NSString*    kHtmlPreviousPageButtonTID  = @"HtmlPreviousPageButton";
static NSString*    kHtmlNextPageButtonTID      = @"HtmlNextPageButton";
static NSString*    kHtmlURLFieldTID            = @"HtmlURLField";
static NSString*    kHtmlSearchTID              = @"HtmlSearch";

@implementation TSDocument (ToolbarSupport)

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (BOOL)sharingExists {
if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_7)
    return YES;
else
    return NO;
}

- (NSToolbar*)makeToolbar:(NSString*)inID
{
	// Create a new toolbar instance, and attach it to our document window
	TSToolbar *toolbar = [[TSToolbar alloc] initWithIdentifier: inID];
	[toolbar turnVisibleOff:NO];

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
	NSToolbarItem*	toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] ;
	NSString*	labelKey = [NSString stringWithFormat:@"tiLabel%@", itemKey];
	NSString*	paletteLabelKey	= [NSString stringWithFormat:@"tiPaletteLabel%@", itemKey];
	NSString*	toolTipKey = [NSString stringWithFormat:@"tiToolTip%@", itemKey];

	[toolbarItem setLabel: NSLocalizedStringFromTable(labelKey, @"ToolbarItems", itemKey)];
	[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(paletteLabelKey, @"ToolbarItems", 		[toolbarItem label])];
	[toolbarItem setToolTip: NSLocalizedStringFromTable(toolTipKey, @"ToolbarItems", [toolbarItem 	label])];

	return toolbarItem;
}

- (NSToolbarItem*) makeToolbarSearchItemWithItemIdentifier:(NSString*)itemIdent key:(NSString*)itemKey
{
    NSSearchToolbarItem*    toolbarItem = [[NSSearchToolbarItem alloc] initWithItemIdentifier: itemIdent] ;

    NSString*    labelKey = [NSString stringWithFormat:@"tiLabel%@", itemKey];
    NSString*    paletteLabelKey    = [NSString stringWithFormat:@"tiPaletteLabel%@", itemKey];
    NSString*    toolTipKey = [NSString stringWithFormat:@"tiToolTip%@", itemKey];

    [toolbarItem setLabel: NSLocalizedStringFromTable(labelKey, @"ToolbarItems", itemKey)];
    [toolbarItem setPaletteLabel: NSLocalizedStringFromTable(paletteLabelKey, @"ToolbarItems",         [toolbarItem label])];
    [toolbarItem setToolTip: NSLocalizedStringFromTable(toolTipKey, @"ToolbarItems", [toolbarItem     label])];
    
    toolbarItem.searchField.sendsWholeSearchString = YES;
    
   
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

- (NSToolbarItem*) makeToolbarItemWithItemIdentifier:(NSString*)itemIdent key:(NSString*)itemKey image:(NSImage *)theImage target:(id)target action:(SEL)action
{
    NSToolbarItem*    toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemKey];
    [toolbarItem setImage:theImage];

    // Tell the item what message to send when it is clicked
    [toolbarItem setTarget: target];
    [toolbarItem setAction: action];
    return toolbarItem;
}

- (NSToolbarItem*) makeToolbarSymbolsItemWithItemIdentifier:(NSString *)itemIdent key:(NSString *)itemKey symbolName: (NSString *)symbolName accessibility: (NSString *)accessibility imageName:(NSString *)imageName newImageName:(NSString *)newImageName target:(id)target action:(SEL)action
{
    if ([SUD boolForKey: NewToolbarIconsKey])
        {
             if (@available(macOS 11.0, *)) {
                NSImage *symbolImage = [NSImage imageWithSystemSymbolName: symbolName
                                                accessibilityDescription: accessibility];
                return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                                     image:symbolImage target:self action:action];
                }
            else
             
                return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemKey
                                            imageName:imageName target:target action:action];
        }
    else
         return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemKey
                                            imageName:imageName target:target action:action];
}
    

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (NSToolbarItem*) makeToolbarItemWithItemIdentifier:(NSString*)itemIdent key:(NSString*)itemKey customView:(id)customView
{
	NSToolbarItem*	toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemKey];
	[toolbarItem setView: customView];
    if ([SUD boolForKey: NewToolbarIconsKey]) {
        NSButton *myButton = customView;
        if ([[customView class] isSubclassOfClass: [NSButton class]])
            myButton.bezelStyle = NSBezelStyleTexturedRounded;
    }
    else {
	    [toolbarItem setMinSize:NSMakeSize(NSWidth([customView frame]), NSHeight([customView frame]))];
	    [toolbarItem setMaxSize:NSMakeSize(NSWidth([customView frame]), NSHeight([customView frame]))];
    }
  
	return toolbarItem;
}

- (NSToolbarItem*) makeToolbarItemFixedWithItemIdentifier:(NSString*)itemIdent key:(NSString*)itemKey customView:(id)customView
{
    NSToolbarItem*    toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemKey];
    [toolbarItem setView: customView];
    [toolbarItem setMinSize:NSMakeSize(NSWidth([customView frame]), NSHeight([customView frame]))];
    [toolbarItem setMaxSize:NSMakeSize(NSWidth([customView frame]), NSHeight([customView frame]))];
  
    return toolbarItem;
}

- (NSToolbarItem*) makeMouseModeItemWithItemIdentifier: (NSString *)itemIdent key:(NSString *)itemKey customView: (NSView *)theView
{
    NSToolbarItem *theToolbarItem;
    
    if ([SUD boolForKey: NewToolbarIconsKey])
    {
        if (@available(macOS 11.0, *)) {
            NSImage *firstImage = [NSImage imageWithSystemSymbolName: @"hand.point.up.left"
                                            accessibilityDescription: @"Move Tool"];
            NSImage *secondImage = [NSImage imageWithSystemSymbolName: @"a"
                                             accessibilityDescription: @"Text Tool"];
            NSImage *thirdImage = [NSImage imageWithSystemSymbolName: @"text.magnifyingglass"
                                             accessibilityDescription: @"Smaller Magnifying Glass"];
            NSImage *fourthImage = [NSImage imageWithSystemSymbolName: @"magnifyingglass"
                                            accessibilityDescription: @"Magnifying Glass"];
            NSImage *fifthImage = [NSImage imageWithSystemSymbolName: @"rectangle.dashed"
                                             accessibilityDescription: @"Choose Tool"];
            NSArray *myArray = @[firstImage, secondImage, thirdImage, fourthImage, fifthImage ];
            NSSegmentedControl *mySegmentedControl = [NSSegmentedControl segmentedControlWithImages: myArray trackingMode:NSSegmentSwitchTrackingSelectOne target: self action:@selector(changeMouseMode:)];
            [mySegmentedControl setTag: 1 forSegment: 0];
            [mySegmentedControl setTag: 2 forSegment: 1];
            [mySegmentedControl setTag: 3 forSegment: 2];
            [mySegmentedControl setTag: 4 forSegment: 3];
            [mySegmentedControl setTag: 5 forSegment: 4];
            theToolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:mySegmentedControl];
            }
                
        else
            theToolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:theView];

    }
else
    theToolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:theView];
    
    return theToolbarItem;
}

- (NSToolbarItem*) makeBackForthItemWithItemIdentifier: (NSString *)itemIdent key:(NSString *)itemKey customView: (NSView *)theView
{
    NSToolbarItem *theToolbarItem;
    
    if ([SUD boolForKey: NewToolbarIconsKey])
    {
        if (@available(macOS 11.0, *)) {
            NSImage *firstImage = [NSImage imageWithSystemSymbolName: @"arrowtriangle.left.fill"
                                            accessibilityDescription: @"Left Move"];
            NSImage *secondImage = [NSImage imageWithSystemSymbolName: @"arrowtriangle.right.fill"
                                             accessibilityDescription: @"Right Move"];
             NSArray *myArray = @[firstImage, secondImage];
            NSSegmentedControl *mySegmentedControl = [NSSegmentedControl segmentedControlWithImages: myArray trackingMode:NSSegmentSwitchTrackingSelectOne target: self action:@selector(doBackForward:)];
             theToolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:mySegmentedControl];
            }
        else
            theToolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:theView];
    }
else
    theToolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:theView];
    
    return theToolbarItem;
}


// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void) setupToolbar
{
    NSWindow *tempWindow;
    
	// end addition
    
    if (@available(macOS 11.0, *))
        {
            tempWindow = (NSWindow *)[self textWindow];
            tempWindow.toolbarStyle = NSWindowToolbarStyleExpanded;
        }
	[[self textWindow] setToolbar: [self makeToolbar: kSourceToolbarIdentifier]];

#ifdef MITSU_PDF
	// WARNING: this must be called now, because calling it when the matrix is active but offscreen causes defective toolbar display
	NSInteger mouseMode = [SUD integerForKey: PdfKitMouseModeKey];
	[mouseModeMatrixKK selectCellWithTag: mouseMode];
    [mouseModeMatrixFull selectCellWithTag: mouseMode];
	
	

#endif

	// HACK: The following is a trick to get the NSSegmentedControl to display correctly
	// (i.e. the same way as in Preview.app). There seems to be a bug (or misfeature?) in
	// this control that causes it to display differently when its label is an empty string
	// than when its label is "not set", i.e. when we pass 0 instead of a NSString.
	[backforthKK setLabel:0 forSegment:0];
	[backforthKK setLabel:0 forSegment:1];


if (@available(macOS 11.0, *))
    {
        tempWindow = (NSWindow *)[self pdfWindow];
        tempWindow.toolbarStyle = NSWindowToolbarStyleExpanded;
        self.pdfKitWindow.toolbarStyle = NSWindowToolbarStyleExpanded;
        tempWindow = (NSWindow *)[self fullSplitWindow];
        tempWindow.toolbarStyle = NSWindowToolbarStyleExpanded;
    }
    
	[[self pdfWindow] setToolbar: [self makeToolbar: kPDFToolbarIdentifier]];
	[self.pdfKitWindow setToolbar: [self makeToolbar: kPDFKitToolbarIdentifier]];
    [[self fullSplitWindow] setToolbar: [self makeToolbar: kFullWindowToolbarIdentifier]];
   [[self htmlWindow] setToolbar: [self makeToolbar: kHtmlWindowToolbarIdentifier]];
}

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

- (void)doPreviousPage:(id)sender
{
	[[self pdfView] previousPage: sender];
}

- (void)doHtmlPreviousPage:(id)sender
{
   [[self htmlView] goBack] ;
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

- (void)doHtmlNextPage:(id)sender
{
    
    [[self htmlView] goForward] ;
}

- (void)doNextPageKK:(id)sender
{
	[[self pdfKitView] nextPage: sender];
}

- (void)toggleTheDrawer:(id)sender
{
	[[self pdfKitView] toggleDrawer: sender];
}

- (void)doNothing:(id)sender
{
    ;
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
	id submenuItem;
    NSSearchToolbarItem  *mySearchToolbarItem;

    
    if ([itemIdent isEqual: kSharingTID]) {
        [[shareButton cell] setImageScaling: NSImageAlignCenter];
        [shareButton setImage: [NSImage imageNamed: @"NSShareTemplate"]];
        [shareButton sendActionOn: NSLeftMouseDownMask];
        [shareButton setTarget: self];
        [shareButton setAction:@selector(doShareSource:)];
        toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView: shareButton];
        menuFormRep = [[NSMenuItem alloc] init];
        [menuFormRep setTitle: [toolbarItem label]];
        [menuFormRep setTarget: self];
        [menuFormRep setAction:@selector(doShareSource:)];
        [toolbarItem setMenuFormRepresentation: menuFormRep];
        return toolbarItem;
    }

    
    if ([itemIdent isEqual: skSharingTID]) {
        [[shareButtonFull cell] setImageScaling: NSImageAlignCenter];
        [shareButtonFull setImage: [NSImage imageNamed: @"NSShareTemplate"]];
        [shareButtonFull sendActionOn: NSLeftMouseDownMask];
        [shareButtonFull setTarget: self];
        [shareButtonFull setAction:@selector(doShareSource:)];
        toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView: shareButtonFull];
        menuFormRep = [[NSMenuItem alloc] init];
        [menuFormRep setTitle: [toolbarItem label]];
        [menuFormRep setTarget: self];
        [menuFormRep setAction:@selector(doShareSource:)];
        [toolbarItem setMenuFormRepresentation: menuFormRep];
        return toolbarItem;
    }
     
    
    if ([itemIdent isEqual: kSharingKKTID]) {
        [[shareButtonEE cell] setImageScaling: NSImageAlignCenter];
        [shareButtonEE setImage: [NSImage imageNamed: @"NSShareTemplate"]];
        [shareButtonEE sendActionOn:NSLeftMouseDownMask];
        [shareButtonEE setTarget: self];
        [shareButtonEE setAction:@selector(doSharePreview:)];
        toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:shareButtonEE];
        menuFormRep = [[NSMenuItem alloc] init];
        [menuFormRep setTitle: [toolbarItem label]];
        [menuFormRep setTarget: self];
        [menuFormRep setAction:@selector(doSharePreview:)];
        [toolbarItem setMenuFormRepresentation: menuFormRep];
        return toolbarItem;
    }

    
	if ([itemIdent isEqual: kTypesetTID]) {
         toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                                   customView: typesetButton];
        menuFormRep = [[NSMenuItem alloc] init];
		submenu = [[NSMenu alloc] init];
		submenuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Typeset", @"Typeset") action: @selector(doTypeset:) keyEquivalent:@""];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}
    
    if ([itemIdent isEqual: skTypesetTID]) {
        toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                                   customView: stypesetButton];
        menuFormRep = [[NSMenuItem alloc] init];
        submenu = [[NSMenu alloc] init];
        submenuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Typeset", @"Typeset") action: @selector(doTypeset:) keyEquivalent:@""];
        [submenu addItem: submenuItem];
        [menuFormRep setSubmenu: submenu];
        [menuFormRep setTitle: [toolbarItem label]];
        [toolbarItem setMenuFormRepresentation: menuFormRep];
        return toolbarItem;
    }


	if ([itemIdent isEqual: kProgramTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:programButton];
        
		menuFormRep = [[NSMenuItem alloc] init];

		[menuFormRep setSubmenu: [programButton menu]];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}
    
    if ([itemIdent isEqual: skProgramTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:sprogramButton];
		menuFormRep = [[NSMenuItem alloc] init];
        
		[menuFormRep setSubmenu: [sprogramButton menu]];
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


	if ([itemIdent isEqual: kSplitID]) {
        
        return [self makeToolbarSymbolsItemWithItemIdentifier:itemIdent key:itemIdent symbolName: @"rectangle.grid.1x2" accessibility: @"Split Window" imageName:@"split1" newImageName:@"fakesplit" target:self action:@selector(splitWindow:)];
    }
    
if ([itemIdent isEqual: kSplitKKTID]) {
    
    return [self makeToolbarSymbolsItemWithItemIdentifier:itemIdent key:itemIdent symbolName: @"rectangle.grid.1x2" accessibility: @"Split Preview Window" imageName:@"split1" newImageName:@"fakesplit" target:self action:@selector(splitPreviewWindow:)];
}
  

	if ([itemIdent isEqual: kDrawerKKTID])
    {
        return [self makeToolbarSymbolsItemWithItemIdentifier:itemIdent key:itemIdent symbolName: @"rectangle.portrait" accessibility: @"ToggleDrawer" imageName:@"DrawerToggleToolbarImage" newImageName:@"fakedrawer" target:self action:@selector(toggleTheDrawer:)];
    }
    


	if ([itemIdent isEqual: kMetaFontID]) {
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"MetaFontAction" target:self action:@selector(doMetaFontTemp:)];
	}

	if ([itemIdent isEqual: kTagsTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:tags];
		menuFormRep = [[NSMenuItem alloc] init];

		[menuFormRep setSubmenu: [tags menu]];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}
    
    if ([itemIdent isEqual: skTagsTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:stags];
		menuFormRep = [[NSMenuItem alloc] init];
        
		[menuFormRep setSubmenu: [stags menu]];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
        
  		return toolbarItem;
	}
    
    //NDS added dropdown for going to a label
    if ([itemIdent isEqual: kLabelsTID]) {
        toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:labels];
         menuFormRep = [[NSMenuItem alloc] init] ;
        
        [menuFormRep setSubmenu: [labels menu]];
        [menuFormRep setTitle: [toolbarItem label]];
        
        [toolbarItem setMenuFormRepresentation: menuFormRep];
        theLabels = toolbarItem;
        
        return toolbarItem;
    }
    //NDS added dropdown for going to a label
    if ([itemIdent isEqual: skLabelsTID]) {
        toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:slabels];
         menuFormRep = [[NSMenuItem alloc] init] ;
        
        [menuFormRep setSubmenu: [slabels menu]];
        [menuFormRep setTitle: [toolbarItem label]];
        [toolbarItem setMenuFormRepresentation: menuFormRep];
        theSLabels = toolbarItem;
        return toolbarItem;
    }
    
    if ([itemIdent isEqual: kUpdateTID]) {
    
        return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                         imageName:@"UpdateAction.png" target:self action:@selector(doUpdate:)];
    }
    
    
    if ([itemIdent isEqual: skUpdateTID]) {
        
        return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                             imageName:@"UpdateAction.png" target:self action:@selector(doUpdate:)];
    }


	if ([itemIdent isEqual: kTemplatesID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:popupButton];
		menuFormRep = [[NSMenuItem alloc] init];

		[menuFormRep setSubmenu: [popupButton menu]];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}
    
    if ([itemIdent isEqual: skTemplatesID]) {
        toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:spopupButton];
        menuFormRep = [[NSMenuItem alloc] init];
        
        [menuFormRep setSubmenu: [spopupButton menu]];
        [menuFormRep setTitle: [toolbarItem label]];
        [toolbarItem setMenuFormRepresentation: menuFormRep];
        
        return toolbarItem;
    }

	if ([itemIdent isEqual: kAutoCompleteID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
												   customView:autoCompleteButton];
		menuFormRep = [[NSMenuItem alloc] init];
		submenu = [[NSMenu alloc] init];
		submenuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"AutoComplete", @"AutoComplete")
												  action: @selector(changeAutoComplete:) keyEquivalent:@""];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}
    
    if ([itemIdent isEqual: skAutoCompleteID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
												   customView:autoCompleteSplitButton];
		menuFormRep = [[NSMenuItem alloc] init];
		submenu = [[NSMenu alloc] init];
		submenuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"AutoComplete", @"AutoComplete")
                                                 action: @selector(changeAutoComplete:) keyEquivalent:@""];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}


	// added by Terada (from this line) ////////////////
	if ([itemIdent isEqual: kShowFullPathID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
												   customView:showFullPathButton];
		menuFormRep = [[NSMenuItem alloc] init];
		submenu = [[NSMenu alloc] init];
		submenuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"ShowFullPath", @"ShowFullPath")
												  action: @selector(changeShowFullPath:) keyEquivalent:@""];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}
	///////////// added by Terada (until this line) ////////////////
	
	// added by mitsu --(H) Macro menu; macroButton
	if ([itemIdent isEqual: kMacrosTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:macroButton];
		menuFormRep = [[NSMenuItem alloc] init];

		[menuFormRep setSubmenu: [macroButton menu]];
		[[TSMacroMenuController sharedInstance] addItemsToPopupButton: macroButton];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}
    
    if ([itemIdent isEqual: skMacrosTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:smacroButton];
		menuFormRep = [[NSMenuItem alloc] init];
        
		[menuFormRep setSubmenu: [smacroButton menu]];
		[[TSMacroMenuController sharedInstance] addItemsToPopupButton: smacroButton];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
        
		return toolbarItem;
	}

	// end addition


	// PDF toolbar
    
    /* TeXShop used to provide "Typeset Buttons" for the Source, Preview, and Single Window modes.
     At first all three tools used the same interface builder button. Eventually systems broke that
     design and three buttons were provided for the tools. In the 4.50 release, one of the buttons
     was incorrectly created in Interface Builder. In addition, the button broke in "Big Sur Tools"
     mode. Rather than fixing this problem, I decided to remove the button as a Preview Window tool.
     It was originally provided for users with an external editor, but they can use command-T or
     the Typesetting menu item instead.
     */
    
    /*
	if (([itemIdent isEqual: kTypesetEETID]) && ! ([SUD boolForKey: NewToolbarIconsKey])) {
		toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
													customView:typesetButtonEE];
		menuFormRep = [[NSMenuItem alloc] init];
		submenu = [[NSMenu alloc] init];
		submenuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Typeset", @"Typeset") action: @selector(doTypeset:) 				keyEquivalent:@""];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}
    */
 


	if ([itemIdent isEqual: kProgramEETID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:programButtonEE];
        
		menuFormRep = [[NSMenuItem alloc] init];
		[menuFormRep setTitle: [toolbarItem label]];

		submenu = [[NSMenu alloc] init];
		id tempsubmenuItem;
		NSString *tempString;
		id tempTarget;
		SEL tempAction;
		NSInteger i;
		NSInteger j = [[programButtonEE menu] numberOfItems];
		for (i = 0; i < j; i++) {
			tempsubmenuItem = [[programButtonEE menu] itemAtIndex: i];
			tempString = [tempsubmenuItem title];
			tempTarget = [tempsubmenuItem target];
			tempAction = [tempsubmenuItem action];
  
        }


		[menuFormRep setSubmenu: submenu];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}


	if ([itemIdent isEqual: kMacrosEETID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent customView:macroButtonEE];
  		menuFormRep = [[NSMenuItem alloc] init];

		[menuFormRep setSubmenu: [macroButtonEE menu]];
		[[TSMacroMenuController sharedInstance] addItemsToPopupButton: macroButtonEE];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}


    if ([itemIdent isEqual: kPreviousPageButtonTID]){

        if ([SUD boolForKey: NewToolbarIconsKey])
        {
            if (@available(macOS 11.0, *)) {
                NSString *theName = @"arrow.up";
                NSImage *previousImage = [NSImage imageWithSystemSymbolName: theName
                                                accessibilityDescription: @"Previous Page"];
                [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                                    customView:previousImage];
                }
            else
                 [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                             customView:previousButton];
        }
    else

         [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                             customView:previousButton];

           
		menuFormRep = [[NSMenuItem alloc] init];
		[menuFormRep setTitle: [toolbarItem label]];
		[menuFormRep setAction: @selector(previousPage:)];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}

	if ([itemIdent isEqual: kNextPageButtonTID]) {
        
        if ([SUD boolForKey: NewToolbarIconsKey])
        {
            if (@available(macOS 11.0, *)) {
                NSString *theName = @"arrow.down";
                NSImage *previousImage = [NSImage imageWithSystemSymbolName: theName
                                                accessibilityDescription: @"Next Page"];
                [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                                    customView:previousImage];
                }
            else
                [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                         customView:nextButton];
        }
    else

         [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                             customView:nextButton];

		menuFormRep = [[NSMenuItem alloc] init];
		[menuFormRep setTitle: [toolbarItem label]];
		[menuFormRep setAction: @selector(nextPage:)];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
 
		return toolbarItem;
	}


	if ([itemIdent isEqual: kPreviousPageTID])
    {
        return [self makeToolbarSymbolsItemWithItemIdentifier:itemIdent key:itemIdent symbolName: @"arrow.up" accessibility: @"Previous Page" imageName:@"PreviousPageAction" newImageName:@"arrow.up" target:self action:@selector(doPreviousPage:)];
     }
	if ([itemIdent isEqual: kNextPageTID])
    {
        return [self makeToolbarSymbolsItemWithItemIdentifier:itemIdent key:itemIdent symbolName: @"arrow.down" accessibility: @"Next Page" imageName:@"NextPageAction" newImageName:@"arrow.down" target:self action:@selector(doNextPage:)];
     }
    
    if ([itemIdent isEqual: kHtmlPreviousPageButtonTID])
    {
        return [self makeToolbarSymbolsItemWithItemIdentifier:itemIdent key:itemIdent symbolName: @"chevron.left" accessibility: @"Previous Page" imageName:@"PreviousPageAction" newImageName:@"chevron.left" target:self action:@selector(doHtmlPreviousPage:)];
     }
    if ([itemIdent isEqual: kHtmlNextPageButtonTID])
    {
        return [self makeToolbarSymbolsItemWithItemIdentifier:itemIdent key:itemIdent symbolName: @"chevron.right" accessibility: @"Next Page" imageName:@"NextPageAction" newImageName:@"chevron.right" target:self action:@selector(doHtmlNextPage:)];
     }

	if ([itemIdent isEqual: kBackForthKKTID]) {
        
        toolbarItem = [self makeBackForthItemWithItemIdentifier: itemIdent key:itemIdent customView: backforthKK];
        
  		//toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
		//											customView:backforthKK];
		menuFormRep = [[NSMenuItem alloc] init];
		[menuFormRep setTitle: [toolbarItem label]];

		submenu = [[NSMenu alloc] init];
		submenuItem = [[NSMenuItem alloc] initWithTitle: @"Back" action: @selector(doBack:) keyEquivalent:@""];
		[submenuItem setTarget: self];
		[submenu addItem: submenuItem];
		submenuItem = [[NSMenuItem alloc] initWithTitle: @"Forward" action: @selector(doForward:) keyEquivalent:@""];
		[submenuItem setTarget: self];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];



		// [menuFormRep setAction: @selector(doBackForth:)];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}
    
    if ([itemIdent isEqual: skBackForthKKTID]) {
        
        toolbarItem = [self makeBackForthItemWithItemIdentifier: itemIdent key:itemIdent customView: sbackforthKK];
        
         
        menuFormRep = [[NSMenuItem alloc] init];
        [menuFormRep setTitle: [toolbarItem label]];

        submenu = [[NSMenu alloc] init];
        submenuItem = [[NSMenuItem alloc] initWithTitle: @"Back" action: @selector(doBack:) keyEquivalent:@""];
        [submenuItem setTarget: self];
        [submenu addItem: submenuItem];
        submenuItem = [[NSMenuItem alloc] initWithTitle: @"Forward" action: @selector(doForward:) keyEquivalent:@""];
        [submenuItem setTarget: self];
        [submenu addItem: submenuItem];
        [menuFormRep setSubmenu: submenu];

       [toolbarItem setMenuFormRepresentation: menuFormRep];
        return toolbarItem;
    }


	if ([itemIdent isEqual: kPreviousPageButtonKKTID])
    {
        /*
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"PreviousPageAlternateAction" target:self action:@selector(doPreviousPageKK:)];
        */
        
        return [self makeToolbarSymbolsItemWithItemIdentifier:itemIdent key:itemIdent symbolName: @"arrow.up.doc" accessibility: @"Previous Page" imageName:@"PreviousPageAlternateAction" newImageName:@"PreviousPageAlternateAction" target:self action:@selector(doPreviousPageKK:)];
	}
 

	if ([itemIdent isEqual: kNextPageButtonKKTID]) {
        /*
		return [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
											 imageName:@"NextPageAlternateAction" target:self action:@selector(doNextPageKK:)];
        */
        return [self makeToolbarSymbolsItemWithItemIdentifier:itemIdent key:itemIdent symbolName: @"arrow.down.doc" accessibility: @"Next Page" imageName:@"NextPageAlternateAction" newImageName:@"NextPageAlternateAction" target:self action:@selector(doNextPageKK:)];
        
	}


	if ([itemIdent isEqual: kPreviousPageKKTID])
    {
        return [self makeToolbarSymbolsItemWithItemIdentifier:itemIdent key:itemIdent symbolName: @"arrow.up" accessibility: @"Previous Page" imageName:@"PreviousPageAction" newImageName:@"arrow.up" target:self action:@selector(doPreviousPageKK:)];
     }
        

	if ([itemIdent isEqual: kNextPageKKTID])
    {
        return [self makeToolbarSymbolsItemWithItemIdentifier:itemIdent key:itemIdent symbolName: @"arrow.down" accessibility: @"Next Page" imageName:@"NextPageAction" newImageName:@"arrow.down" target:self action:@selector(doNextPageKK:)];
     }
    
	if ([itemIdent isEqual: kGotoPageTID]) {
		toolbarItem =  [self makeToolbarItemFixedWithItemIdentifier:itemIdent key:itemIdent
													customView:gotopageOutlet];
		menuFormRep = [[NSMenuItem alloc] init];
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
		toolbarItem =  [self makeToolbarItemFixedWithItemIdentifier:itemIdent key:itemIdent
													customView:gotopageOutletKK];
		menuFormRep = [[NSMenuItem alloc] init];
		[menuFormRep setTitle: NSLocalizedString(@"Page Number", @"Page Number")];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		[menuFormRep setAction: @selector(doTextPage:)];
		[menuFormRep setTarget:self.pdfKitWindow];
		return toolbarItem;
	}

     if ([itemIdent isEqual: kSearchKKTID]) {
        
        if ([SUD boolForKey: NewToolbarIconsKey])
            
        {
              if (@available(macOS 11.0, *)) {
                
              //  toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent        customView: mySearchField];
                
            
                   toolbarItem =
                    [self  makeToolbarSearchItemWithItemIdentifier:itemIdent key:itemIdent];
                  
                  mySearchToolbarItem = (NSSearchToolbarItem *)toolbarItem;
                  mySearchField = mySearchToolbarItem.searchField;
                  
                  [toolbarItem setTarget: self];
                  [toolbarItem setAction: @selector(doPDFSearch:)];
            
                }
            else
                toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent        customView: mySearchField];
            }
        else
             
            toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent        customView: mySearchField];
        
        return toolbarItem;
    }
    
    if ([itemIdent isEqual: skSearchTID]) {
        if ([SUD boolForKey: NewToolbarIconsKey])
            
        {
            
             if (@available(macOS 11.0, *)) {
                
                toolbarItem =  [self  makeToolbarSearchItemWithItemIdentifier:itemIdent key:itemIdent];
                
                mySearchToolbarItem = (NSSearchToolbarItem *)toolbarItem;
                myFullSearchField = mySearchToolbarItem.searchField;
                
              [toolbarItem setTarget: self];
              [toolbarItem setAction: @selector(doPDFSearchFullWindow:)];
                    
                }
            else
            
        
                toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent        customView: myFullSearchField];
            }
        else
             
            toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent        customView: myFullSearchField];
        
        return toolbarItem;
    }
        
    
    if ([itemIdent isEqual: skGotoPageKKTID]) {
		toolbarItem =  [self makeToolbarItemFixedWithItemIdentifier:itemIdent key:itemIdent
													customView:sgotopageOutletKK];
		menuFormRep = [[NSMenuItem alloc] init];
		[menuFormRep setTitle: NSLocalizedString(@"Page Number", @"Page Number")];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		[menuFormRep setAction: @selector(doTextPage:)];
		[menuFormRep setTarget: fullSplitWindow];
		return toolbarItem;
	}
    
    if ([itemIdent isEqual: skMagnificationKKTID]) {
		toolbarItem =  [self makeToolbarItemFixedWithItemIdentifier:itemIdent key:itemIdent
													customView:smagnificationOutletKK];
		menuFormRep = [[NSMenuItem alloc] init];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		[menuFormRep setAction: @selector(doTextMagnify:)];
		[menuFormRep setTarget: fullSplitWindow];
		return toolbarItem;
	}




	if ([itemIdent isEqual: kMagnificationTID]) {
		toolbarItem =  [self makeToolbarItemFixedWithItemIdentifier:itemIdent key:itemIdent
													customView:magnificationOutlet];
		menuFormRep = [[NSMenuItem alloc] init];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		[menuFormRep setAction: @selector(doTextMagnify:)];
		[menuFormRep setTarget: pdfWindow];
		return toolbarItem;
	}


	if ([itemIdent isEqual: kMagnificationKKTID]) {
		toolbarItem =  [self makeToolbarItemFixedWithItemIdentifier:itemIdent key:itemIdent
													customView:magnificationOutletKK];
		menuFormRep = [[NSMenuItem alloc] init];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		[menuFormRep setAction: @selector(doTextMagnify:)];
		[menuFormRep setTarget: self.pdfKitWindow];
		return toolbarItem;
	}

#ifdef MITSU_PDF
	// mitsu 1.29 (O)
	if ([itemIdent isEqual: kMouseModeTID]) {
       
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
       customView:mouseModeMatrix];
      
         
		menuFormRep = [[NSMenuItem alloc] init];
		[menuFormRep setSubmenu: mouseModeMenu];


		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}


	// mitsu 1.29 (O)
	if ([itemIdent isEqual: kMouseModeKKTID]) {
           
            NSToolbarItem *myToolbarItem;
            
            myToolbarItem = [self makeMouseModeItemWithItemIdentifier: kMouseModeKKTID key:kMouseModeKKTID
                                                           customView: mouseModeMatrixKK];
            
            
            menuFormRep = [[NSMenuItem alloc] init];
            [menuFormRep setSubmenu: mouseModeMenuKit];


            [menuFormRep setTitle: [myToolbarItem label]];
            [myToolbarItem setMenuFormRepresentation: menuFormRep];

            return myToolbarItem;
        }
        
    
    if ([itemIdent isEqual: skMouseModeTID])
   
    {
           
            NSToolbarItem *myToolbarItem;
            
            myToolbarItem = [self makeMouseModeItemWithItemIdentifier: skMouseModeTID key:skMouseModeTID
                                                           customView: mouseModeMatrixFull];
            
            
            menuFormRep = [[NSMenuItem alloc] init];
            [menuFormRep setSubmenu: mouseModeMenuKit];


            [menuFormRep setTitle: [myToolbarItem label]];
            [myToolbarItem setMenuFormRepresentation: menuFormRep];

            return myToolbarItem;
        }
    

	// end mitsu 1.29
#endif

	if ([itemIdent isEqual: kSyncMarksTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
												   customView:self.syncBox];
		menuFormRep = [[NSMenuItem alloc] init];
		submenu = [[NSMenu alloc] init];
		submenuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Sync Marks", @"Sync Marks")
							   //                 action: @selector(changeShowSync:) keyEquivalent:@""] autorelease];
												  action: @selector(flipShowSync:) keyEquivalent:@""];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}
	
	if ([itemIdent isEqual: kColorIndexTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
												   customView:self.indexColorBox];
		menuFormRep = [[NSMenuItem alloc] init];
		submenu = [[NSMenu alloc] init];
		submenuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Color Index", @"Color Index")
												  action: @selector(flipIndexColorState:) keyEquivalent:@""];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}
    
    if ([itemIdent isEqual: skColorIndexTID]) {
		toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
												   customView:indexColorSplitBox];
		menuFormRep = [[NSMenuItem alloc] init];
		submenu = [[NSMenu alloc] init];
		submenuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Color Index", @"Color Index")
                                                 action: @selector(flipIndexColorState:) keyEquivalent:@""];
		[submenu addItem: submenuItem];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];
		return toolbarItem;
	}
    
    
    
     if ([itemIdent isEqual: kHtmlPreviousPageButtonTID]) {
         
         if ([SUD boolForKey: NewToolbarIconsKey])
         {
             if (@available(macOS 11.0, *)) {
                 NSString *theName = @"chevron.left";
                 NSImage *previousImage = [NSImage imageWithSystemSymbolName: theName
                                                 accessibilityDescription: @"Previous Page"];
                 [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                                     customView:previousImage];
                 }
             else
                  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                              customView:previousButton];
         }
     else

          [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                              customView:previousButton];

         /*
         menuFormRep = [[NSMenuItem alloc] init];
         [menuFormRep setTitle: [toolbarItem label]];
         [menuFormRep setAction: @selector(previousPage:)];
         [toolbarItem setMenuFormRepresentation: menuFormRep];
          */
        return toolbarItem;
    }
    
    if ([itemIdent isEqual: kHtmlNextPageButtonTID]) {
        
        if ([SUD boolForKey: NewToolbarIconsKey])
        {
            if (@available(macOS 11.0, *)) {
                NSString *theName = @"chevron.right";
                NSImage *previousImage = [NSImage imageWithSystemSymbolName: theName
                                                accessibilityDescription: @"Next Page"];
                [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                                    customView:previousImage];
                }
            else
                [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                         customView:nextButton];
        }
    else

         [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
                                             customView:nextButton];
        /*
        menuFormRep = [[NSMenuItem alloc] init];
        [menuFormRep setTitle: [toolbarItem label]];
        [menuFormRep setAction: @selector(nextPage:)];
        [toolbarItem setMenuFormRepresentation: menuFormRep];
        */
        return toolbarItem;
    }
    
    if ([itemIdent isEqual: kHtmlURLFieldTID]) {
        
        // TEMPORARY //
        
        toolbarItem =  [self makeToolbarItemFixedWithItemIdentifier:itemIdent key:itemIdent
                                                    customView:myURLField];
       // toolbarItem = [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent];
       // [toolbarItem setView: myURLField];
        // [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent
        //                                    customView:myURLField];
        return toolbarItem;
    }

// Note: the code below is temporary, because the html Search Field is not yet active.
// The commented out line "mySearchField = mySearchToolbarItem.searchField" is left as a hint about what should be done
// But the line itself is very dangerous, because "mySearchField" is a variable describing the Preview Search Field
// When the line is not commented out, the consequence is that command-F no longer activates the Preview Search Field
    
    if ([itemIdent isEqual: kHtmlSearchTID]) {
        
        if ([SUD boolForKey: NewToolbarIconsKey])
            
        {
              if (@available(macOS 11.0, *)) {
                
              //  toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent        customView: mySearchField];
                
            
                   toolbarItem =
                    [self  makeToolbarSearchItemWithItemIdentifier:itemIdent key:itemIdent];
                  
                  mySearchToolbarItem = (NSSearchToolbarItem *)toolbarItem;
                  //mySearchField = mySearchToolbarItem.searchField;
                  
                  [toolbarItem setTarget: self];
                  [toolbarItem setAction: @selector(doHtmlSearch:)];
            
                }
            else
                toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent        customView: mySearchField];
            }
        else
             
            toolbarItem =  [self makeToolbarItemWithItemIdentifier:itemIdent key:itemIdent        customView: mySearchField];
        
        return toolbarItem;
    }
    
    
    


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

    BOOL swapWindows = [SUD boolForKey:SwitchSidesKey];
    
	NSString*	toolbarID = [toolbar identifier];

	if ([toolbarID isEqual:kSourceToolbarIdentifier]) {
        
        if ([self sharingExists]) {
            
        return  [NSArray arrayWithObjects:
                           kTypesetTID,
                           kProgramTID,
                           NSToolbarPrintItemIdentifier,
                            kMacrosTID,
                           kTagsTID,
                           kLabelsTID,
                           kTemplatesID,
                           NSToolbarFlexibleSpaceItemIdentifier,
                           kSharingTID,
                           kSplitID,
                           nil];
        }
        else {

            

		return [NSArray arrayWithObjects:
					kTypesetTID,
					kProgramTID,
					NSToolbarPrintItemIdentifier,
						kMacrosTID,
					kTagsTID,
                    kLabelsTID,
					kTemplatesID,
					NSToolbarFlexibleSpaceItemIdentifier,
					kSplitID,
					nil];
        }
    }

	if ([toolbarID isEqual:kPDFToolbarIdentifier]) {

		return [NSArray arrayWithObjects:
					kPreviousPageTID,
					kNextPageTID,
					kTypesetEETID,
					NSToolbarPrintItemIdentifier,
					kMagnificationTID,
					kGotoPageTID,
					kMouseModeTID, // mitsu 1.29 (O)
					NSToolbarFlexibleSpaceItemIdentifier,
					NSToolbarSpaceItemIdentifier,
				nil];
	}

	if ([toolbarID isEqual:kPDFKitToolbarIdentifier]) {
        
        if ([self sharingExists]) {

		return [NSArray arrayWithObjects:
					kPreviousPageKKTID,
					kNextPageKKTID,
					kBackForthKKTID,
					kDrawerKKTID,
					NSToolbarPrintItemIdentifier,
					kMagnificationKKTID,
					kGotoPageKKTID,
					kMouseModeKKTID, // mitsu 1.29 (O)
					kSharingKKTID,
					kSplitKKTID,
                    NSToolbarFlexibleSpaceItemIdentifier,
                    kSearchKKTID,
                
				nil];
	}
        
        else {
     
        
		return [NSArray arrayWithObjects:
                kPreviousPageKKTID,
                kNextPageKKTID,
                kBackForthKKTID,
                kDrawerKKTID,
                NSToolbarPrintItemIdentifier,
                kMagnificationKKTID,
                kGotoPageKKTID,
                kMouseModeKKTID, // mitsu 1.29 (O)
                 kSplitKKTID,                // NSToolbarSpaceItemIdentifier,
                NSToolbarFlexibleSpaceItemIdentifier,
                kSearchKKTID,
				nil];
	}
}
  

    if (([toolbarID isEqual:kFullWindowToolbarIdentifier]) && (! swapWindows)) {
        
        
        if ([self sharingExists]) {
            
            return  [NSArray arrayWithObjects:
                     skTypesetTID,
                     skProgramTID,
                     skMacrosTID,
                     skTagsTID,
                     skLabelsTID, //NDS Added
                     skTemplatesID,
                     skSharingTID,
                     kSplitID,
                     NSToolbarSpaceItemIdentifier,
                     NSToolbarSpaceItemIdentifier,
                     kPreviousPageKKTID,
                     kNextPageKKTID,
                     kDrawerKKTID,
                     NSToolbarPrintItemIdentifier,
                     skGotoPageKKTID,
                     skMouseModeTID,
                     kSplitKKTID,
                     NSToolbarFlexibleSpaceItemIdentifier,
                     skSearchTID,
                      nil];
        }
        else {
            
            return [NSArray arrayWithObjects:
					skTypesetTID,
					skProgramTID,
                    skMacrosTID,
					skTagsTID,
                    skLabelsTID, //NDS Added
					skTemplatesID,
					kSplitID,
                    NSToolbarSpaceItemIdentifier,
                    NSToolbarSpaceItemIdentifier,
					kPreviousPageButtonKKTID,
					kNextPageButtonKKTID,
					kDrawerKKTID,
                    NSToolbarPrintItemIdentifier,
                    skGotoPageKKTID,
                    skMouseModeTID,
             		kSplitKKTID,
                    NSToolbarFlexibleSpaceItemIdentifier,
                    skSearchTID,
                    nil];
        }
    }

 
    if (([toolbarID isEqual:kFullWindowToolbarIdentifier]) && (swapWindows)) {
        
        
        if ([self sharingExists]) {
            
            return  [NSArray arrayWithObjects:
                     kPreviousPageKKTID,
                     kNextPageKKTID,
                     kDrawerKKTID,
                     NSToolbarPrintItemIdentifier,
                     skGotoPageKKTID,
                     skMouseModeTID,
                     kSplitKKTID,
                     NSToolbarFlexibleSpaceItemIdentifier,
                     skSearchTID,
                     NSToolbarSpaceItemIdentifier,
                     NSToolbarSpaceItemIdentifier,
                     skTypesetTID,
                     skProgramTID,
                     skMacrosTID,
                     skTagsTID,
                     skLabelsTID, //NDS Added
                     skTemplatesID,
                     kSplitID,
                     skSharingTID,
                     nil];
        }
        else {
            
            return [NSArray arrayWithObjects:
                    kPreviousPageButtonKKTID,
                    kNextPageButtonKKTID,
                    kDrawerKKTID,
                    NSToolbarPrintItemIdentifier,
                    skGotoPageKKTID,
                    skMouseModeTID,
                    kSplitKKTID,
                    NSToolbarFlexibleSpaceItemIdentifier,
                    skSearchTID,
                    NSToolbarSpaceItemIdentifier,
                    NSToolbarSpaceItemIdentifier,
                    skTypesetTID,
                    skProgramTID,
                    skMacrosTID,
                    skTagsTID,
                    skLabelsTID, //NDS Added
                    skTemplatesID,
                    kSplitID,
                    nil];
        }
    }

    if ([toolbarID isEqual:kHtmlWindowToolbarIdentifier]) {
   
        /*
        return  [NSArray arrayWithObjects:
                            khtmlPreviousPageButtonTID,
                            khtmlNextPageButtonTID,
                            khtmlURLFieldTID,
                            NSToolbarFlexibleSpaceItemIdentifier,
                            khtmlSearchTID,
                            nil];
         */
        return  [NSArray arrayWithObjects:
                            NSToolbarSpaceItemIdentifier,
                            kHtmlPreviousPageButtonTID,
                            NSToolbarSpaceItemIdentifier,
                            kHtmlNextPageButtonTID,
                            NSToolbarSpaceItemIdentifier,
                            NSToolbarSpaceItemIdentifier,
                            kHtmlURLFieldTID,
                            NSToolbarSpaceItemIdentifier,
                            NSToolbarFlexibleSpaceItemIdentifier,
                            kHtmlSearchTID,
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
        
        if ([self sharingExists]) {

		return [NSArray arrayWithObjects:
					kTypesetTID,
					kProgramTID,
					kTeXTID,
					kLaTeXTID,
					kBibTeXTID,
					kMakeIndexTID,
					kMetaPostTID,
					kMetaFontID,
					kTagsTID,
                    kLabelsTID, // NDS added
                    kUpdateTID,
					kTemplatesID,
					kAutoCompleteID,
					kShowFullPathID, // added by Terada
                     kSharingTID,
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
        
        else {
            
            return [NSArray arrayWithObjects:
                    kTypesetTID,
					kProgramTID,
					kTeXTID,
					kLaTeXTID,
					kBibTeXTID,
					kMakeIndexTID,
					kMetaPostTID,
					kMetaFontID,
					kTagsTID,
                    kLabelsTID, // NDS added
                    kUpdateTID,
					kTemplatesID,
					kAutoCompleteID,
					kShowFullPathID, // added by Terada
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

        }

	if ([toolbarID isEqual:kPDFToolbarIdentifier]) {

		return [NSArray arrayWithObjects:
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
        
        if ([self sharingExists]) {

		return [NSArray arrayWithObjects:
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
					kMetaFontID,
					kGotoPageKKTID,
					kMagnificationKKTID,
					kMouseModeKKTID,
					kSyncMarksTID,
                    kSearchKKTID,
                    kSharingKKTID,
					kSplitKKTID,
                    kToolsKKTID,
					NSToolbarPrintItemIdentifier,
					NSToolbarCustomizeToolbarItemIdentifier,
					NSToolbarFlexibleSpaceItemIdentifier,
					NSToolbarSpaceItemIdentifier,
					NSToolbarSeparatorItemIdentifier,
				nil];

	}
        
        else {
       
            return [NSArray arrayWithObjects:
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
					kMetaFontID,
					kGotoPageKKTID,
					kMagnificationKKTID,
					kMouseModeKKTID,
					kSyncMarksTID,
                    kSplitKKTID,
                    kToolsKKTID,
                    NSToolbarPrintItemIdentifier,
					NSToolbarCustomizeToolbarItemIdentifier,
					NSToolbarFlexibleSpaceItemIdentifier,
					NSToolbarSpaceItemIdentifier,
					NSToolbarSeparatorItemIdentifier,
                    nil];
            
        }
            
        }
 
    
  
    if ([toolbarID isEqual:kFullWindowToolbarIdentifier]) {
        
        if ([self sharingExists]) {
            
            return [NSArray arrayWithObjects:
 					skTypesetTID,
					skProgramTID,
                    skMacrosTID,
					skTagsTID,
                    skLabelsTID, //NDS Added
                    skUpdateTID,
					skTemplatesID,
					skSharingTID,
					kSplitID,
					kPreviousPageButtonKKTID,
					kNextPageButtonKKTID,
					kPreviousPageKKTID,
					kNextPageKKTID,
					skBackForthKKTID,
					kDrawerKKTID,
	                skGotoPageKKTID,
                    skMagnificationKKTID,
					skMouseModeTID,
                    skSearchTID,
					kSplitKKTID,
                    skColorIndexTID,
                    skAutoCompleteID,
					NSToolbarPrintItemIdentifier,
					NSToolbarCustomizeToolbarItemIdentifier,
					NSToolbarFlexibleSpaceItemIdentifier,
					NSToolbarSpaceItemIdentifier,
					NSToolbarSeparatorItemIdentifier,
                    nil];
        }
        
        else {
            
            return [NSArray arrayWithObjects:
 					skTypesetTID,
					skProgramTID,
                    skMacrosTID,
					skTagsTID,
                    skLabelsTID, //NDS Added
                    skUpdateTID,
					skTemplatesID,
					kSplitID,
					kPreviousPageButtonKKTID,
					kNextPageButtonKKTID,
					kPreviousPageKKTID,
					kNextPageKKTID,
					skBackForthKKTID,
					kDrawerKKTID,
	                skGotoPageKKTID,
                    skMagnificationKKTID,
					skMouseModeTID,
                    skSearchTID,
					kSplitKKTID,
                    skColorIndexTID,
 					skAutoCompleteID,
					NSToolbarPrintItemIdentifier,
					NSToolbarCustomizeToolbarItemIdentifier,
					NSToolbarFlexibleSpaceItemIdentifier,
					NSToolbarSpaceItemIdentifier,
					NSToolbarSeparatorItemIdentifier,
                    nil];
        }
        
    }

    if ([toolbarID isEqual:kHtmlWindowToolbarIdentifier]) {

        /*
        return [NSArray arrayWithObjects:
                   
                    kHtmlPreviousPageButtonTID,
                    kHtmlNextPageButtonTID,
                    kHtmlURLFieldTID,
                    kHtmlSearchTID,
                    NSToolbarCustomizeToolbarItemIdentifier,
                    NSToolbarFlexibleSpaceItemIdentifier,
                    NSToolbarSpaceItemIdentifier,
                    NSToolbarSeparatorItemIdentifier,
                nil];
         */
        return [NSArray arrayWithObjects:
                    kHtmlPreviousPageButtonTID,
                    kHtmlNextPageButtonTID,
                    kHtmlURLFieldTID,
                    kHtmlSearchTID,
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
        
         else if ([toolbarID isEqual:kFullWindowToolbarIdentifier]) {
             
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

        if ([itemID isEqual: NSToolbarPrintItemIdentifier]) {
			enable = YES;
		}
	}
    else if ([itemID isEqual: NSToolbarPrintItemIdentifier]) {

		if ([toolbarID isEqual:kSourceToolbarIdentifier]) {
			enable = (self.documentType == isOther);
		} else if ([toolbarID isEqual:kPDFToolbarIdentifier]) {
			enable = ((self.documentType == isPDF) || (self.documentType == isJPG) || (self.documentType == isTIFF));
		} else if ([toolbarID isEqual:kPDFKitToolbarIdentifier]) {
			enable = ((self.documentType == isPDF) || (self.documentType == isJPG) || (self.documentType == isTIFF));
		}

	}
	else if (([itemID isEqual: kPreviousPageButtonTID]) ||
			([itemID isEqual: kPreviousPageTID]) ||
			([itemID isEqual: kPreviousPageButtonKKTID]) ||
			([itemID isEqual: kPreviousPageKKTID])) {
						// TODO: Check whether we are on the first page
						enable = (self.documentType == isPDF);
	}
	else if	(([itemID isEqual: kNextPageButtonTID]) ||
			([itemID isEqual: kNextPageTID]) ||
			([itemID isEqual: kNextPageButtonKKTID]) ||
			([itemID isEqual: kNextPageKKTID])) {
						// TODO: Check whether we are on the last page
						enable = (self.documentType == isPDF);
	}
 

	return enable;
}


@end
