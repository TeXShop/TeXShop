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
 * $Id: TSAppDelegate.m 262 2007-08-17 01:33:24Z richard_koch $
 *
 * Created by dirk on Tue Jan 23 2001.
 *
 */

#import "TSAppDelegate.h"

#import "globals.h"

#import "TSDocumentController.h"
#import "TSEncodingSupport.h"
#import "MyPDFView.h"
#import "TSLaTeXPanelController.h"
#import "TSMacroMenuController.h"
#import "TSMatrixPanelController.h"
#import "TSPreferences.h"
#import "TSWindowManager.h"

#import "OgreKit/OgreTextFinder.h"
#import "TextFinder.h"

#include <sys/sysctl.h>     // for testForIntel
#include <mach/machine.h>   // for testForIntel


@class TSTextEditorWindow;


@interface TSAppDelegate (Private)

- (void)mirrorPath:(NSString *)srcPath toPath:(NSString *)dstPath;

@end


/*" This class is registered as the delegate of the TeXShop NSApplication object. We do various stuff here, e.g. registering factory defaults, dealing with keyboard shortcuts etc.
"*/
@implementation TSAppDelegate

- (void)dealloc
{
	[g_autocompletionDictionary release];
	[super dealloc];
}


- (void)testForIntel;
{	
	// The default value for the preference is now /usr/texbin as of Jan 11, 2007.
	// I make this change unless a hidden preference says not to.
	// 
	// if the processor is intel and the path variable preference is /usr/local/tetex/bin/powerpc-apple-darwin-current,
	// then change that preference permanently to /usr/local/tetex/bin/i386-apple-darwin-current
	
	BOOL canRevisePath = [SUD boolForKey:RevisePathKey];
    NSString *binPath = [SUD stringForKey:TetexBinPath];
	
	if (canRevisePath) {
		if ( [binPath isEqualToString:@"/usr/local/teTeX/bin/powerpc-apple-darwin-current"] ||
			[binPath isEqualToString:@"/usr/local/teTeX/bin/i386-apple-darwin-current"] ) {
			
			[SUD setObject:@"/usr/texbin" forKey:TetexBinPath];
			[SUD setObject:@"NO" forKey:RevisePathKey];
			[SUD synchronize];
			
			}
		}
		
	else {

			
		if (! [binPath isEqualToString:@"/usr/local/teTeX/bin/powerpc-apple-darwin-current"])
			return;
	
		// Determine CPU type
		cpu_type_t cputype;
		size_t s = sizeof cputype;
		if (sysctlbyname("hw.cputype", &cputype, &s, NULL, 0) == 0 && cputype == CPU_TYPE_I386) {
			[SUD setObject:@"/usr/local/teTeX/bin/i386-apple-darwin-current" forKey:TetexBinPath];
			[SUD synchronize];
		}
	}
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	NSString *folderPath, *filename;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	folderPath = [[DraggedImagePath stringByStandardizingPath]
								stringByDeletingLastPathComponent];
	NSEnumerator *enumerator = [[fileManager directoryContentsAtPath: folderPath]
								objectEnumerator];
	while ((filename = [enumerator nextObject])) {
		if ([filename characterAtIndex: 0] != '.')
			[fileManager removeFileAtPath:[folderPath stringByAppendingPathComponent:
								filename] handler: nil];
	}
}


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return [SUD boolForKey:MakeEmptyDocumentKey];
}


- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	NSString *fileName;
	NSDictionary *factoryDefaults;
//	OgreTextFinder *theFinder;
	id theFinder;

	g_macroType = LatexEngine;
	
	// WARNING: g_taggedTeXSections may be reset in EncodingSupport
	
	if ([SUD boolForKey: ConTeXtTagsKey]) {

		g_taggedTeXSections = [[NSArray alloc] initWithObjects:@"\\chapter",
					@"\\section",
					@"\\subsection",
					@"\\subsubsection",
					@"\\subsubsubsection",
					@"\\subsubsubsubsection",
					@"\\part",
					@"\\title",
					@"\\subject",
					@"\\subsubject",
					@"\\subsubsubject",
					@"\\subsubsubsubject",
					@"\\subsubsubsubsubject",
					nil];
					
		g_taggedTagSections = [[NSArray alloc] initWithObjects:@"chapter: ",
					@"section: ",
					@"subsection: ",
					@"subsubsection: ",
					@"subsubsubsection: ",
					@"subsubsubsubsection: ",
					@"part: ",
					@"title: ",
					@"subject: ",
					@"subsubject: ",
					@"subsubsubject: ",
					@"subsubsubsubject: ",
					@"subsubsubsubsubject: ",
					nil];
	} else {
		
		g_taggedTeXSections = [[NSArray alloc] initWithObjects:@"\\chapter",
					@"\\section",
					@"\\subsection",
					@"\\subsubsection",
					nil];
					
		g_taggedTagSections = [[NSArray alloc] initWithObjects:@"chapter: ",
					@"section: ",
					@"subsection: ",
					@"subsubsection: ",
					nil];
	}
		
	// if this is the first time the app is used, register a set of defaults to make sure
	// that the app is useable.
	if (([[NSUserDefaults standardUserDefaults] boolForKey:TSHasBeenUsedKey] == NO) ||
		([[NSUserDefaults standardUserDefaults] objectForKey:TetexBinPath] == nil)) {
		[[TSPreferences sharedInstance] registerFactoryDefaults];
	} else {
		// register defaults
		fileName = [[NSBundle mainBundle] pathForResource:@"FactoryDefaults" ofType:@"plist"];
		NSParameterAssert(fileName != nil);
		factoryDefaults = [[NSString stringWithContentsOfFile:fileName] propertyList];
		[SUD registerDefaults:factoryDefaults];
	}

	// Make sure the ~/Library/TeXShop/ directory exists and is populated.
	// To do this, we walk recursively through our private 'TeXShop' folder contained
	// in the .app bundle, and mirrors all files and folders found there which aren't
	// present inside ~/Library/TeXShop.
	//
	// This must come before dealing with TSEncodingSupport and MacoMenuController below
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (! [fileManager fileExistsAtPath: [TeXShopPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop"]
			  toPath:[TeXShopPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [CommandCompletionFolderPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/CommandCompletion"]
			  toPath:[CommandCompletionFolderPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [DraggedImageFolderPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/DraggedImages"]
			  toPath:[DraggedImageFolderPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [EnginePath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Engines"]
			  toPath:[EnginePath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [AutoCompletionPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Keyboard"]
			  toPath:[AutoCompletionPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [LatexPanelPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/LatexPanel"]
			  toPath:[LatexPanelPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [MacrosPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Macros"]
			  toPath:[MacrosPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [MatrixPanelPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/MatrixPanel"]
			  toPath:[MatrixPanelPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [MenuShortcutsPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Menus"]
			  toPath:[MenuShortcutsPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [ScriptsPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Scripts"]
			  toPath:[ScriptsPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [TexTemplatePath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Templates"]
			  toPath:[TexTemplatePath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [BinaryPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/bin"]
			  toPath:[BinaryPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [MoviesPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Movies"]
			  toPath:[MoviesPath stringByStandardizingPath]];
		}

		
// Finish configuration of various pieces
	[[TSMacroMenuController sharedInstance] loadMacros];
	[self finishAutoCompletionConfigure];
	[self finishMenuKeyEquivalentsConfigure];
	[self configureExternalEditor];
	[self configureMovieMenu];

	if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"])
		g_texChar = YEN;
	else
		g_texChar = BACKSLASH;

// added by mitsu --(H) Macro menu and (G) TSEncodingSupport
	[[TSEncodingSupport sharedInstance] setupForEncoding];        // this must come after
	[[TSMacroMenuController sharedInstance] setupMainMacroMenu];
	[[TSDocumentController sharedDocumentController] initializeEncoding];  // so when first document is created, it has correct default
// end addition

	[self finishCommandCompletionConfigure]; // mitsu 1.29 (P) need to call after setupForEncoding

#ifdef MITSU_PDF
	// mitsu 1.29b check menu item for image format for copying and exporting
	int imageCopyType = [SUD integerForKey:PdfCopyTypeKey];
	if (!imageCopyType)
		imageCopyType = IMAGE_TYPE_JPEG_MEDIUM; // default PdfCopyTypeKey
	NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
							NSLocalizedString(@"Preview", @"Preview")] submenu];
	id <NSMenuItem> item = [previewMenu itemWithTitle:
							NSLocalizedString(@"Copy Format", @"format")];
	if (item) {
		NSMenu *formatMenu = [item submenu];
		item = [formatMenu itemWithTag: imageCopyType];
		[item setState: NSOnState];
	}

	[NSColor setIgnoresAlpha:NO]; // it seesm necessary to call this to activate alpha
	// end mitsu 1.29b
#endif

	if ([SUD boolForKey:UseOgreKitKey])
		theFinder = [OgreTextFinder sharedTextFinder];
	else
		theFinder = [TextFinder sharedInstance];
	    
	[self testForIntel];
}


- (void)setForPreview: (BOOL)value
{
	_forPreview = value;
}

- (BOOL)forPreview
{
	return _forPreview;
}

// Added by Greg Landweber to load the autocompletion dictionary
// This code is modified from the code to load the LaTeX panel
- (void) finishAutoCompletionConfigure
{
	NSString	*autocompletionPath;
	
	autocompletionPath = [AutoCompletionPath stringByStandardizingPath];
	autocompletionPath = [autocompletionPath stringByAppendingPathComponent:@"autocompletion"];
	autocompletionPath = [autocompletionPath stringByAppendingPathExtension:@"plist"];
	if ([[NSFileManager defaultManager] fileExistsAtPath: autocompletionPath])
		g_autocompletionDictionary = [NSDictionary dictionaryWithContentsOfFile:autocompletionPath];
	else
		g_autocompletionDictionary = [NSDictionary dictionaryWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource:@"autocompletion" ofType:@"plist"]];
	[g_autocompletionDictionary retain];
	// end of code added by Greg Landweber
}


// This is further menuKey configuration assuming folder already created
- (void)finishMenuKeyEquivalentsConfigure
{
	NSString		*shortcutsPath, *theChar;
	NSDictionary	*shortcutsDictionary, *menuDictionary;
	NSEnumerator	*mainMenuEnumerator, *menuItemsEnumerator, *subMenuItemsEnumerator;
	NSMenu		*mainMenu, *theMenu, *subMenu;
	id <NSMenuItem>		theMenuItem;
	id			key, key1, key2, object;
	unsigned int	mask;
	int			value;
	
	// The code below is copied from Sarah Chambers' code
	
	shortcutsPath = [MenuShortcutsPath stringByStandardizingPath];
	shortcutsPath = [shortcutsPath stringByAppendingPathComponent:@"KeyEquivalents"];
	shortcutsPath = [shortcutsPath stringByAppendingPathExtension:@"plist"];
	if ([[NSFileManager defaultManager] fileExistsAtPath: shortcutsPath])
		shortcutsDictionary = [NSDictionary dictionaryWithContentsOfFile:shortcutsPath];
	else
		return;
	mainMenu = [NSApp mainMenu];
	mainMenuEnumerator = [shortcutsDictionary keyEnumerator];
	while ((key = [mainMenuEnumerator nextObject])) {
		menuDictionary = [shortcutsDictionary objectForKey: key];
		value = [key intValue];
		if (value == 0)
			theMenu = [[mainMenu itemWithTitle: key] submenu];
		else
			theMenu = [[mainMenu itemAtIndex: (value - 1)] submenu];
		
		if (theMenu && menuDictionary) {
			menuItemsEnumerator = [menuDictionary keyEnumerator];
			while ((key1 = [menuItemsEnumerator nextObject])) {
				value = [key1 intValue];
				if (value == 0)
					theMenuItem = [theMenu itemWithTitle: key1];
				else
					theMenuItem = [theMenu itemAtIndex: (value - 1)];
				object = [menuDictionary objectForKey: key1];
				if (([object isKindOfClass: [NSDictionary class]]) && ([theMenuItem hasSubmenu])) {
					subMenu = [theMenuItem submenu];
					subMenuItemsEnumerator = [object keyEnumerator];
					while ((key2 = [subMenuItemsEnumerator nextObject])) {
						value = [key2 intValue];
						if (value == 0)
							theMenuItem = [subMenu itemWithTitle: key2];
						else
							theMenuItem = [subMenu itemAtIndex: (value - 1)];
						object = [object objectForKey: key2];
						if ([object isKindOfClass: [NSArray class]]) {
							theChar = [object objectAtIndex: 0];
							mask = NSCommandKeyMask;
							if ([[object objectAtIndex: 1] boolValue])
								mask = (mask | NSAlternateKeyMask);
							if ([[object objectAtIndex: 2] boolValue])
								mask = (mask | NSControlKeyMask);
							[theMenuItem setKeyEquivalent: theChar];
							[theMenuItem setKeyEquivalentModifierMask: mask];
						}
					}
				} else if ([object isKindOfClass: [NSArray class]]) {
					theChar = [object objectAtIndex: 0];
					mask = (NSCommandKeyMask | NSFunctionKeyMask);
					if ([[object objectAtIndex: 1] boolValue])
						mask = (mask | NSAlternateKeyMask);
					if ([[object objectAtIndex: 2] boolValue])
						mask = (mask | NSControlKeyMask);
					[theMenuItem setKeyEquivalent: theChar];
					[theMenuItem setKeyEquivalentModifierMask: mask];
				}
			}
		}
	}
	
}

// mitsu 1.29 (P)
- (void) finishCommandCompletionConfigure
{
	NSString            *completionPath;
	NSData              *myData;

	unichar esc = 0x001B; // configure the key in Preferences?
	if (!g_commandCompletionChar)
		g_commandCompletionChar = [[NSString stringWithCharacters: &esc length: 1] retain];

	[g_commandCompletionList release];
	g_commandCompletionList = nil;
	g_canRegisterCommandCompletion = NO;
	completionPath = [CommandCompletionPath stringByStandardizingPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath: completionPath])
		myData = [NSData dataWithContentsOfFile:completionPath];
	else
		myData = [NSData dataWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource:@"CommandCompletion" ofType:@"txt"]];
	if (!myData)
		return;

	NSStringEncoding myEncoding = NSUTF8StringEncoding;
	g_commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: myEncoding];
	if (! g_commandCompletionList) {
		myEncoding = [[TSEncodingSupport sharedInstance] defaultEncoding];
		g_commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: myEncoding];
	}

	if (!g_commandCompletionList)
		return;
	[g_commandCompletionList insertString: @"\n" atIndex: 0];
	if ([g_commandCompletionList characterAtIndex: [g_commandCompletionList length]-1] != '\n')
		[g_commandCompletionList appendString: @"\n"];
	g_canRegisterCommandCompletion = YES;
}
// end mitsu 1.29


- (void)configureExternalEditor
{
	NSString	*menuTitle;

	_forPreview =  [SUD boolForKey:UseExternalEditorKey];
	if (_forPreview)
		menuTitle = NSLocalizedString(@"Open for Editing...", @"Open for Editing...");
	else
		menuTitle = NSLocalizedString(@"Open for Preview...", @"Open for Preview...");
	[[[[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"File", @"File")] submenu]
		itemWithTag:110] setTitle:menuTitle];
}

- (IBAction)openForPreview:(id)sender
{
	int				i;
	NSArray			*myArray, *fileArray;
	NSDocumentController	*myController;
	BOOL			externalEditor;
	NSOpenPanel			*myPanel;
	
	externalEditor = [SUD boolForKey:UseExternalEditorKey];
	myController = [NSDocumentController sharedDocumentController];
	myPanel = [NSOpenPanel openPanel];
	
	if (externalEditor)
		_forPreview = NO;
	else
		_forPreview = YES;
	
	/* This code restricts files to tex files */
	myArray = [NSArray arrayWithObjects:
		@"tex",
		@"TEX",
		@"txt",
		@"TXT",
		@"bib",
		@"mp",
		@"ins",
		@"dtx",
		@"mf",
		nil];
	i = [myController runModalOpenPanel: myPanel forTypes: myArray];
	fileArray = [myPanel filenames];
	if (fileArray) {
		for(i = 0; i < [fileArray count]; ++i) {
			NSString*  myName = [fileArray objectAtIndex:i];
			[myController openDocumentWithContentsOfFile: myName display: YES];
		}
	}
	
	if (externalEditor)
		_forPreview = YES;
	else
		_forPreview = NO;
}


- (IBAction)displayLatexPanel:(id)sender
{
	if ([sender tag] == 0) {
		[[TSLaTeXPanelController sharedInstance] showWindow:self];
		[sender setTitle:NSLocalizedString(@"Close LaTeX Panel", @"Close LaTeX Panel")];
		[sender setTag:1];
	} else {
		[[TSLaTeXPanelController sharedInstance] hideWindow:self];
		[sender setTitle:NSLocalizedString(@"LaTeX Panel...", @"LaTeX Panel...")];
		[sender setTag:0];
	}
}

- (IBAction)displayMatrixPanel:(id)sender
{
	if ([sender tag] == 0) {
		[[TSMatrixPanelController sharedInstance] showWindow:self];
		[sender setTitle:NSLocalizedString(@"Close Matrix Panel", @"Close Matrix Panel")];
		[sender setTag:1];
	} else {
		[[TSMatrixPanelController sharedInstance] hideWindow:self];
		[sender setTitle:NSLocalizedString(@"Matrix Panel...", @"Matrix Panel...")];
		[sender setTag:0];
	}
}

- (IBAction)doMovie:(id)sender
{
	NSString *title = [[sender title] stringByAppendingString:@".mov"];
	[myMovie doMovie:title];
}

- (void)configureMovieMenu
{
	NSFileManager *fm;
	NSString      *basePath, *path, *title;
	NSArray       *fileList;
	// NSMenu 	  *submenu;
	BOOL	   isDirectory;
	unsigned i;
	// unsigned lv = 3;
	
	NSMenu *helpMenu = [[[NSApp mainMenu] itemWithTitle:
					NSLocalizedString(@"Help", @"Help")] submenu];

	
	NSMenu *texshopDemosMenu = [[helpMenu itemWithTitle:
					NSLocalizedString(@"TeXShop Demos", @"TeXShop Demos")] submenu];
	
	if (!texshopDemosMenu)
		return;
		
	fm       = [ NSFileManager defaultManager ];
	basePath = [[ MoviesPath stringByAppendingString:@"/TeXShop"] stringByStandardizingPath ];
	fileList = [ fm directoryContentsAtPath: basePath ];

	for (i = 0; i < [fileList count]; i++) {
		title = [ fileList objectAtIndex: i ];
		path  = [ basePath stringByAppendingPathComponent: title ];
		if ([fm fileExistsAtPath:path isDirectory: &isDirectory]) {
			if (isDirectory )
				{;
				// [popupButton addItemWithTitle: @""];
				// newItem = [popupButton lastItem];
				// [newItem setTitle: title];
				// submenu = [[[NSMenu alloc] init] autorelease];
				// [self makeMenuFromDirectory: submenu basePath: path
				//					 action: @selector(doTemplate:) level: lv];
				// [newItem setSubmenu: submenu];
				} 
			else if ([[[title pathExtension] lowercaseString] isEqualToString: @"mov"]) {
				title = [title stringByDeletingPathExtension];
				[texshopDemosMenu addItemWithTitle:title action: @selector(doMovie:) keyEquivalent:@"" ];
			}
		}
	}
}




- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	if ([anItem action] == @selector(displayLatexPanel:)) {
		return [[NSApp mainWindow] isKindOfClass:[TSTextEditorWindow class]];
	} else if ([anItem action] == @selector(displayMatrixPanel:)) {
		return [[NSApp mainWindow] isKindOfClass:[TSTextEditorWindow class]];
	} else
		return YES;
}

// mitsu 1.29 (P)
- (void)openCommandCompletionList: (id)sender
{
	if ([[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:
			[CommandCompletionPath stringByStandardizingPath] display: YES] != nil)
		g_canRegisterCommandCompletion = NO;
}
// end mitsu 1.29

#ifdef MITSU_PDF
// mitsu 1.29 (O)
- (void)changeImageCopyType: (id)sender
{
	id <NSMenuItem> item;

	if ([sender isKindOfClass: [NSMenuItem class]]) {
		int imageCopyType;

		imageCopyType = [SUD integerForKey:PdfCopyTypeKey]; // mitsu 1.29b
		item = [[sender menu] itemWithTag: imageCopyType];
		[item setState: NSOffState];

		imageCopyType = [sender tag];
		item = [[sender menu] itemWithTag: imageCopyType];
		[item setState: NSOnState];

		// mitsu 1.29b
		NSPopUpButton *popup = [[TSPreferences sharedInstance] imageCopyTypePopup];
		if (popup)
		{
			int idx = [popup indexOfItemWithTag: imageCopyType];
			if (idx != -1)
				[popup selectItemAtIndex: idx];
		}
		// end mitsu 1.29b
		// save this to User Defaults
		[SUD setInteger:imageCopyType forKey:PdfCopyTypeKey];
	}
}
// end mitsu 1.29
#endif

- (void)ogreKitWillHackFindMenu:(OgreTextFinder*)textFinder
{
	[textFinder setShouldHackFindMenu:[[NSUserDefaults standardUserDefaults] boolForKey:@"UseOgreKit"]];
}

// Update Checker Nov 05 04; Martin Kerz
// This code simply fixes a text file from a fixed URL, and parses it
// for the version of the latest TeXShop releae. It then compares it to
// the CFBundleVersion of the running application (the comparision is
// pretty dumb right now, just a simple case insensitive string compare).
// If the online TeXShop version is newer, we offer the user to
// fetch the new version, which is done by grabbing another fixed
// URL through the NSWorkSpaceManager.
//
// This approach is quite simple but also a bit limited. The version compare
// should be improved. Also, the remote file with the version (a plist)
// could also contain the URL of the new .dmg. That way we don't have
// to use a fixed filename for new TeXShop releases.
//
// We could also add a preference to do automatic checks at regular time intervals.
// And of course an fully automated in-place updated would be cool, too, but
// you got to ask yourself if it's really worth the whole effort ;-)
- (IBAction)checkForUpdate:(id)sender
{
	NSString *currentVersion = [[[NSBundle bundleForClass:[self class]]
		infoDictionary] objectForKey:@"CFBundleVersion"];
		
	NSDictionary *texshopVersionDictionary = [NSDictionary dictionaryWithContentsOfURL:
		[NSURL URLWithString:@"http://www.uoregon.edu/~koch/texshop/texshop-current.txt"]];

	NSString *latestVersion = [texshopVersionDictionary valueForKey:@"TeXShop"];
	
	int button;
	if(latestVersion == nil){
		NSRunAlertPanel(NSLocalizedString(@"Error",
										  @"Error"),
						NSLocalizedString(@"There was an error checking for updates.",
										  @"There was an error checking for updates."),
										  @"OK", nil, nil);
		return;
	}

	if([latestVersion caseInsensitiveCompare: currentVersion] != NSOrderedDescending)
	{
		NSRunAlertPanel(NSLocalizedString(@"Your copy of TeXShop is up-to-date",
										  @"Your copy of TeXShop is up-to-date"),
						NSLocalizedString(@"You have the most recent version of TeXShop.",
										  @"You have the most recent version of TeXShop."),
										  @"OK", nil, nil);
	}
	else
	{
		button = NSRunAlertPanel(NSLocalizedString(@"New version available",
													   @"New version available"),
									 [NSString stringWithFormat:
										 NSLocalizedString(@"A new version of TeXShop is available (version %@). Would you like to download it now?",
														   @"A new version of TeXShop is available (version %@). Would you like to download it now?"), latestVersion],
									 @"OK", @"Cancel", nil);
		if (button == NSOKButton) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.uoregon.edu/~koch/texshop/texshop.dmg"]];
		}
	}

}


@end


@implementation TSAppDelegate (Private)

// Recursively copy the file/folder at srcPath to dstPath.
// This creates target folders as needed, and will not overwrite
// existing files.
- (void)mirrorPath:(NSString *)srcPath toPath:(NSString *)dstPath
{
	NSFileManager	*fileManager;
	BOOL			srcExists, srcIsDir;
	BOOL			dstExists, dstIsDir;
	BOOL			result;
	NSString		*reason = 0;

	fileManager = [NSFileManager defaultManager];
	
	srcExists = [fileManager fileExistsAtPath:srcPath isDirectory:&srcIsDir];
	dstExists = [fileManager fileExistsAtPath:dstPath isDirectory:&dstIsDir];
	
	if (!srcExists)
		return;	// Source doesn't exist, abort (this shouldn't happen)
	
	if (dstExists && (srcIsDir != dstIsDir))
		return; // Both source and destination exist, but one is a file and the other a folder: abort!
	
	if (srcIsDir) {
		// Create destination directory if missing (and abort if this fails)
		if (!dstExists) {
			NS_DURING
				// create the missing directory
				result = [fileManager createDirectoryAtPath:dstPath attributes:nil];
			NS_HANDLER
				result = NO;
				reason = [localException reason];
			NS_ENDHANDLER
			if (!result) {
				NSRunAlertPanel(NSLocalizedString(@"Error", @"Error"), reason,
					[NSString stringWithFormat: NSLocalizedString(@"Couldn't create folder:\n%@", @"Message when creating a directory failed"), dstPath],
					nil, nil);
				return;
			}
		}
		
		// Iterate over the content of the source dir and copy it recursively
		NSEnumerator 	*fileEnumerator;
		NSString		*fileName;
		fileEnumerator = [[fileManager directoryContentsAtPath:srcPath] objectEnumerator];
		while ((fileName = [fileEnumerator nextObject])) {
			[self mirrorPath:[srcPath stringByAppendingPathComponent:fileName]
					  toPath:[dstPath stringByAppendingPathComponent:fileName]];
		}
	} else {
		// Copy source to destination
		if (!dstExists) {
			NS_DURING
				// file doesn't exist -> copy it
				result = [fileManager copyPath:srcPath toPath:dstPath handler:nil];
			NS_HANDLER
				result = NO;
				reason = [localException reason];
			NS_ENDHANDLER
			if (!result) {
				// Copying the file failed for some reason.
				// We might want to show an error alert here, but then the main
				// reason why this would fail is a write protected Library; and in that
				// case it doesn't seem clever to pop up a dozen or more error alerts.
				// Hence we only do so for directory creation failures for now.
				// Might want to revise this decision at a later point...
				// Like maybe just record the fact that an error occurred, and at the
				// end of the mirroring process, pop up a single error dialog 
				// stating something like "TeXShop failed to copy one or multiple files
				// from FOO to BAR, etc.".
			}
		}
	}
}

@end

