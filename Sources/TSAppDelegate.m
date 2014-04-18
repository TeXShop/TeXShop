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
#import "TSTextEditorWindow.h"
#import "GlobalData.h"



#import "OgreKit/OgreTextFinder.h"
#import "TextFinder.h"

#include <sys/sysctl.h>     // for testForIntel
#include <mach/machine.h>   // for testForIntel


#define NSAppKitVersionNumber10_8 1187

@class TSTextEditorWindow;


@interface TSAppDelegate (Private)

- (void)mirrorPath:(NSString *)srcPath toPath:(NSString *)dstPath;

@end


/*" This class is registered as the delegate of the TeXShop NSApplication object. We do various stuff here, e.g. registering factory defaults, dealing with keyboard shortcuts etc.
"*/
@implementation TSAppDelegate

/*
- (void)dealloc
{
	[g_autocompletionDictionary release];
	[defaultLanguage release];
	[super dealloc];
}
*/


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
#warning 64BIT: Inspect use of sizeof
		size_t s = sizeof cputype;
		if (sysctlbyname("hw.cputype", &cputype, &s, NULL, 0) == 0 && cputype == CPU_TYPE_I386) {
			[SUD setObject:@"/usr/local/teTeX/bin/i386-apple-darwin-current" forKey:TetexBinPath];
			[SUD synchronize];
		}
	}
}

/*
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    NSLog(@"called");
    return NO;
}
*/


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    
    NSString *spellingLanguage = [[NSSpellChecker sharedSpellChecker] language];
    BOOL    spellingAutomatic = [[NSSpellChecker sharedSpellChecker] automaticallyIdentifiesLanguages];
    [SUD setBool: spellingAutomatic forKey: SpellingAutomaticLanguageKey];
    [SUD setObject: spellingLanguage forKey: SpellingLanguageKey];
    [SUD synchronize];
    
    NSString *folderPath, *filename;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	folderPath = [[DraggedImagePath stringByStandardizingPath]
								stringByDeletingLastPathComponent];
	NSEnumerator *enumerator = [[fileManager contentsOfDirectoryAtPath: folderPath error:NULL]
								objectEnumerator];
	while ((filename = [enumerator nextObject])) {
		if ([filename characterAtIndex: 0] != '.')
			[fileManager removeItemAtPath:[folderPath stringByAppendingPathComponent:
                                           filename] error: NULL];
	}
}


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return [SUD boolForKey:MakeEmptyDocumentKey];
}


- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    
     
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8)
        atLeastMavericks = YES;
    else
        atLeastMavericks = NO;
    
	NSString *fileName, *currentVersion, *versionString, *myVersion;
	NSDictionary *factoryDefaults;
//	OgreTextFinder *theFinder;
//	id theFinder;
	CGFloat oldVersion, newVersion;
	BOOL needsUpdating;
    id item;


	g_macroType = LatexEngine;

	
		
	// if this is the first time the app is used, register a set of defaults to make sure
	// that the app is useable.
	if (([[NSUserDefaults standardUserDefaults] boolForKey:TSHasBeenUsedKey] == NO) ||
		([[NSUserDefaults standardUserDefaults] objectForKey:TetexBinPath] == nil)) {
		[[TSPreferences sharedInstance] registerFactoryDefaults];
	} else {
		// register defaults
		fileName = [[NSBundle mainBundle] pathForResource:@"FactoryDefaults" ofType:@"plist"];
		NSParameterAssert(fileName != nil);
		factoryDefaults = [[NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL] propertyList];
		[SUD registerDefaults:factoryDefaults];
	}
    
    //Set value of NSISOLatin9StringEncoding   NSMacOSRomanStringEncoding
    NSISOLatin9StringEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin9);
	
	// Make sure the ~/Library/TeXShop/ directory exists and is populated.
	// To do this, we walk recursively through our private 'TeXShop' folder contained
	// in the .app bundle, and mirrors all files and folders found there which aren't
	// present inside ~/Library/TeXShop.
	//
	// This must come before dealing with TSEncodingSupport and MacoMenuController below
	
	// First see if we already updated.;
    
    BOOL spellingAutomatic = [[NSUserDefaults standardUserDefaults] boolForKey:SpellingAutomaticLanguageKey];
    NSString *spellingLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:SpellingLanguageKey];
    [[NSSpellChecker sharedSpellChecker] setAutomaticallyIdentifiesLanguages: spellingAutomatic];
    if (! spellingAutomatic)
        [[NSSpellChecker sharedSpellChecker] setLanguage: spellingLanguage];
    
 	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	oldVersion = 0.0;
	currentVersion = [[[NSBundle bundleForClass:[self class]]
					   infoDictionary] objectForKey:@"CFBundleVersion"];
	newVersion = [currentVersion doubleValue];

	if ([fileManager fileExistsAtPath: [NewPath stringByStandardizingPath]] ) {
		versionString = [[NewPath stringByAppendingPathComponent:@".Version"] stringByStandardizingPath];
		if ([fileManager fileExistsAtPath: versionString]) {
			myVersion = [NSString stringWithContentsOfFile:versionString encoding:NSASCIIStringEncoding error:nil];
			oldVersion = [myVersion doubleValue];
			}
		}
	if (newVersion > (oldVersion + 0.005))
		needsUpdating = TRUE;
	else 
		needsUpdating = FALSE;

		
	if (! [fileManager fileExistsAtPath: [TeXShopPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop"]
			  toPath:[TeXShopPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [CommandCompletionFolderPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/CommandCompletion"]
			  toPath:[CommandCompletionFolderPath stringByStandardizingPath]];
		}
    
    if (! [fileManager fileExistsAtPath: [DocumentsPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Documents"]
                  toPath:[DocumentsPath stringByStandardizingPath]];
    }
    else if (needsUpdating) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Documents"]
				  toPath:[DocumentsPath stringByStandardizingPath]];
	}
		
	if (! [fileManager fileExistsAtPath: [DraggedImageFolderPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/DraggedImages"]
			  toPath:[DraggedImageFolderPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [EnginePath stringByStandardizingPath]] ){
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Engines"]
			  toPath:[EnginePath stringByStandardizingPath]];
		}
	else if (needsUpdating) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Engines/Inactive"]
				  toPath:[EngineInactivePath stringByStandardizingPath]];
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
		
	if ((! [fileManager fileExistsAtPath: [ScriptsPath stringByStandardizingPath]] ) || needsUpdating) { 
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Scripts"]
			  toPath:[ScriptsPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [TexTemplatePath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Templates"]
			  toPath:[TexTemplatePath stringByStandardizingPath]];
		}
	
	if (! [fileManager fileExistsAtPath: [StationeryPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Stationery"]
				  toPath:[StationeryPath stringByStandardizingPath]];
	}
		
	if ((! [fileManager fileExistsAtPath: [BinaryPath stringByStandardizingPath]] ) || needsUpdating) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/bin"]
			  toPath:[BinaryPath stringByStandardizingPath]];
		}
		
	if (! [fileManager fileExistsAtPath: [MoviesPath stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/Movies"]
			  toPath:[MoviesPath stringByStandardizingPath]];
		}
	

		
	if (([fileManager fileExistsAtPath: [NewPath stringByStandardizingPath]]) && needsUpdating)
        [fileManager removeItemAtPath: [NewPath stringByStandardizingPath] error: NULL];
	
	if (needsUpdating)
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TeXShop/New"]
				  toPath:[NewPath stringByStandardizingPath]];

	
// Finish configuration of various pieces
    
    
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
		
        /*
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
         */
        
        g_taggedTeXSections = [[NSArray alloc] initWithObjects:@"\\chapter",
                               @"\\section",
                               @"\\subsection",
                               @"\\subsubsection",
                               @"% \\chapter",
                               @"% \\section",
                               @"% \\subsection",
                               @"% \\subsubsection",
                               @"% \\begin{macro}",
                               @"% \\begin{environment}",
                               nil];
        
		g_taggedTagSections = [[NSArray alloc] initWithObjects:@"chapter: ",
                               @"section: ",
                               @"subsection: ",
                               @"subsubsection: ",
                               @"chapter: ",
                               @"section: ",
                               @"subsection: ",
                               @"subsubsection: ",
                               @"macro: ",
                               @"environment: ",
                               nil];
	}

    doAutoSave = [SUD boolForKey:AutoSaveEnabledKey]; // this is a new hidden Preference, which can be used to turn it off
    
    activateBauerPatch = doAutoSave && [SUD boolForKey: WatchServerKey] && (( ! [SUD objectForKey:@"ApplePersistence"]) || [SUD boolForKey:@"ApplePersistence"] );
    
	[[TSMacroMenuController sharedInstance] loadMacros];
	[self finishAutoCompletionConfigure];
	[self configureExternalEditor];
	[self configureMovieMenu];
    
    if ( ![[NSUserDefaults standardUserDefaults] boolForKey:TagMenuInMenuBarKey])
    {   
       [[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Tags", @"Tags")] setHidden:YES];
        
    }
	

    
    
    
    

	if ([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"])
		g_texChar = YEN;
	else
		g_texChar = BACKSLASH;
    g_commentChar = COMMENT; 
	
// Configure Spelling
	spellLanguageChanged = NO;
	NSSpellChecker *theChecker = [NSSpellChecker sharedSpellChecker];
	defaultLanguage = [theChecker language];
	// NSLog(defaultLanguage);
	if ([theChecker respondsToSelector:@selector(automaticallyIdentifiesLanguages)])
		automaticLanguage = [theChecker automaticallyIdentifiesLanguages];
	else
		automaticLanguage = NO;
	

// added by mitsu --(H) Macro menu and (G) TSEncodingSupport
	[[TSEncodingSupport sharedInstance] setupForEncoding];        // this must come after
	[[TSMacroMenuController sharedInstance] setupMainMacroMenu];
   // NSLog(@"one");
   // TSDocumentController *myController = [TSDocumentController sharedDocumentController];
   //  NSLog(@"two");
    
 	[[TSDocumentController sharedDocumentController] initializeEncoding];  // so when first document is created, it has correct default
// end addition

	[self finishCommandCompletionConfigure]; // mitsu 1.29 (P) need to call after setupForEncoding

#ifdef MITSU_PDF
	// mitsu 1.29b check menu item for image format for copying and exporting
	NSInteger imageCopyType = [SUD integerForKey:PdfCopyTypeKey];
	if (!imageCopyType)
		imageCopyType = IMAGE_TYPE_JPEG_MEDIUM; // default PdfCopyTypeKey
	NSMenu *previewMenu = [[[NSApp mainMenu] itemWithTitle:
							NSLocalizedString(@"Preview", @"Preview")] submenu];
	item = [previewMenu itemWithTitle:
							NSLocalizedString(@"Copy Format", @"format")];
	if (item) {
		NSMenu *formatMenu = [item submenu];
		item = [formatMenu itemWithTag: imageCopyType];
		[item setState: NSOnState];
	}

	[NSColor setIgnoresAlpha:NO]; // it seesm necessary to call this to activate alpha
	// end mitsu 1.29b
#endif
    


	if ([SUD integerForKey:FindMethodKey] == 2) 
		[OgreTextFinder sharedTextFinder];  //this line modifies menus and hooks up the OgreTextFinder
	else 
        [TextFinder sharedInstance];
  
	    
	[self testForIntel];
	
	PreviewBackgroundColor = [NSColor colorWithCalibratedRed: [SUD floatForKey:PdfPageBack_RKey]
										  green: [SUD floatForKey:PdfPageBack_GKey] blue: [SUD floatForKey:PdfPageBack_BKey]
										  alpha: 1];
	// [PreviewBackgroundColor retain];
	[self finishMenuKeyEquivalentsConfigure];

}

/*

- (void)setForPreview: (BOOL)value
{
	self.forPreview = value;
}

- (BOOL)forPreview
{
	return self.forPreview;
}
*/

// Added by Greg Landweber to load the autocompletion dictionary
// This code is modified from the code to load the LaTeX panel
- (void) finishAutoCompletionConfigure
{
	NSString	*autocompletionPath;
	
	autocompletionPath = [AutoCompletionPath stringByStandardizingPath];
	autocompletionPath = [autocompletionPath stringByAppendingPathComponent:@"autocompletion"];
	autocompletionPath = [autocompletionPath stringByAppendingPathExtension:@"plist"];
	if ([[NSFileManager defaultManager] fileExistsAtPath: autocompletionPath])
		[GlobalData sharedGlobalData].g_autocompletionDictionary = [NSDictionary dictionaryWithContentsOfFile:autocompletionPath];
	else
		[GlobalData sharedGlobalData].g_autocompletionDictionary = [NSDictionary dictionaryWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource:@"autocompletion" ofType:@"plist"]];
//	[g_autocompletionDictionary retain];
	// end of code added by Greg Landweber
	
	// added by Terada
	autocompletionPath = [[[AutoCompletionPath stringByStandardizingPath] stringByAppendingPathComponent:@"autocompletionDisplayOrder"] stringByAppendingPathExtension:@"plist"];
	if ([[NSFileManager defaultManager] fileExistsAtPath: autocompletionPath]){
		[GlobalData sharedGlobalData].g_autocompletionKeys = [NSArray arrayWithContentsOfFile:autocompletionPath];
//		[g_autocompletionKeys retain];
	}
	
}


// This is further menuKey configuration assuming folder already created
- (void)finishMenuKeyEquivalentsConfigure
{
	NSString		*shortcutsPath, *theChar;
	NSDictionary	*shortcutsDictionary, *menuDictionary;
	NSEnumerator	*mainMenuEnumerator, *menuItemsEnumerator, *subMenuItemsEnumerator;
	NSMenu		*mainMenu, *theMenu, *subMenu;
	id 		theMenuItem;
	id			key, key1, key2, object;
	NSUInteger	mask;
	NSInteger			value;
	
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
		value = [key integerValue];
		if (value == 0)
			theMenu = [[mainMenu itemWithTitle: key] submenu];
		else
			theMenu = [[mainMenu itemAtIndex: (value - 1)] submenu];
		menuDictionary = [shortcutsDictionary objectForKey: key];
		
		if (theMenu && menuDictionary) {
			menuItemsEnumerator = [menuDictionary keyEnumerator];
			while ((key1 = [menuItemsEnumerator nextObject])) {
				value = [key1 integerValue];
				if (value == 0)
					theMenuItem = [theMenu itemWithTitle: key1];
				else
					theMenuItem = [theMenu itemAtIndex: (value - 1)];
				object = [menuDictionary objectForKey: key1];
				
				if (([object isKindOfClass: [NSDictionary class]]) && ([theMenuItem hasSubmenu])) {
					subMenu = [theMenuItem submenu];
					subMenuItemsEnumerator = [object keyEnumerator];
					while ((key2 = [subMenuItemsEnumerator nextObject])) {
						value = [key2 integerValue];
						if (value == 0)
							theMenuItem = [subMenu itemWithTitle: key2];
						else
							theMenuItem = [subMenu itemAtIndex: (value - 1)];
						object = [object objectForKey: key2];
						if ([object isKindOfClass: [NSArray class]]) {
							theChar = [object objectAtIndex: 0];
							if ([theChar isKindOfClass: [NSString class]]) {
								mask = (NSCommandKeyMask | NSFunctionKeyMask);
								if ([[object objectAtIndex: 1] boolValue])
									mask = (mask | NSAlternateKeyMask);
								if ([[object objectAtIndex: 2] boolValue])
									mask = (mask | NSControlKeyMask);
								[theMenuItem setKeyEquivalent: theChar];
								[theMenuItem setKeyEquivalentModifierMask: mask];
								}							}
						}
					} 
				
				else if ([object isKindOfClass: [NSArray class]]) {
					theChar = [object objectAtIndex: 0];
					if ([theChar isKindOfClass: [NSString class]]) {
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
	
}

// mitsu 1.29 (P)
- (void) finishCommandCompletionConfigure
{
	NSString            *completionPath;
	NSData              *myData;
    
	unichar esc = 0x001B; // configure the key in Preferences?
	unichar tab = 0x0009; // ditto
	if (!g_commandCompletionChar) {
		if ([[SUD stringForKey: CommandCompletionCharKey] isEqualToString:@"ESCAPE"]) 
			g_commandCompletionChar = [NSString stringWithCharacters: &esc length: 1];
		else
			g_commandCompletionChar = [NSString stringWithCharacters: &tab length: 1];
		
	}
			
	// [g_commandCompletionList release];
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
	NSInteger				i;
	NSArray			*myArray, *fileArray;
	NSDocumentController	*myController;
	BOOL			externalEditor;
	NSOpenPanel			*myPanel;
    NSURL               *myURL;
	
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
	[myController runModalOpenPanel: myPanel forTypes: myArray];
	fileArray = [myPanel URLs];
	if (fileArray) {
		for(i = 0; i < [fileArray count]; ++i) {
	//	NSString*  myName = [fileArray objectAtIndex:i];
    //  [myController openDocumentWithContentsOfURL: [NSURL fileURLWithPath:myName] display: YES error:NULL];
            
            myURL = [fileArray objectAtIndex:i];
    		[myController openDocumentWithContentsOfURL: myURL display: YES error:NULL];
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
	[self.myMovie doMovie:title];
}

- (void)configureMovieMenu
{
	NSFileManager *fm;
	NSString      *basePath, *path, *title;
	NSArray       *fileList;
	// NSMenu 	  *submenu;
	BOOL	   isDirectory;
	NSUInteger i;
	// unsigned lv = 3;
	
	NSMenu *helpMenu = [[[NSApp mainMenu] itemWithTitle:
					NSLocalizedString(@"Help", @"Help")] submenu];

	
	NSMenu *texshopDemosMenu = [[helpMenu itemWithTitle:
					NSLocalizedString(@"TeXShop Demos", @"TeXShop Demos")] submenu];
	
	if (!texshopDemosMenu)
		return;
		
	fm       = [ NSFileManager defaultManager ];
	basePath = [[ MoviesPath stringByAppendingString:@"/TeXShop"] stringByStandardizingPath ];
	fileList = [ fm contentsOfDirectoryAtPath: basePath error:NULL ];

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

// added by Terada (- (NSArray*)searchTeXWindows:)
- (NSArray*)searchTeXWindows:(NSInteger*)ptrToCurrentIndexInReturnedArray
{
	NSArray* windows = [NSApp windows];
	NSUInteger currentIndex = [windows indexOfObject:[NSApp keyWindow]];
	NSMutableArray *matchIndexes = [NSMutableArray arrayWithCapacity:0];
	*ptrToCurrentIndexInReturnedArray = -1;
	NSInteger count = 0;
	NSUInteger i;
	
	for(i=0; i<[windows count]; i++){
		if ([[windows objectAtIndex:i] isKindOfClass:[TSTextEditorWindow class]]) {
			[matchIndexes addObject:[NSNumber numberWithInteger:i]];
			if (currentIndex == i) *ptrToCurrentIndexInReturnedArray = count;
			count++;
		}
	}
	
	return (count == 0) ? nil : matchIndexes;
}

// added by Terada (- (IBAction)nextTeXWindow:)
- (IBAction)nextTeXWindow:(id)sender 
{
	NSInteger currentIndexInReturnedArray;
	NSArray* matchIndexes = [self searchTeXWindows:&currentIndexInReturnedArray];
	if (matchIndexes) {
		NSInteger nextIndex = (currentIndexInReturnedArray == -1 || currentIndexInReturnedArray == 0) ? [[matchIndexes objectAtIndex:[matchIndexes count]-1] integerValue] : [[matchIndexes objectAtIndex:currentIndexInReturnedArray-1] integerValue];
		[[[NSApp windows] objectAtIndex:nextIndex] makeKeyAndOrderFront:nil];
	}
//	[matchIndexes release];
}

// added by Terada (- (IBAction)previousTeXWindow:)
- (IBAction)previousTeXWindow:(id)sender 
{
	NSInteger currentIndexInReturnedArray;
	NSArray* matchIndexes = [self searchTeXWindows:&currentIndexInReturnedArray];
	if (matchIndexes) {
		NSInteger nextIndex = (currentIndexInReturnedArray == -1 || currentIndexInReturnedArray == [matchIndexes count]-1) ? [[matchIndexes objectAtIndex:0] integerValue] : [[matchIndexes objectAtIndex:currentIndexInReturnedArray+1] integerValue];
		[[[NSApp windows] objectAtIndex:nextIndex] makeKeyAndOrderFront:nil];
	}
//	[matchIndexes release];
}


// mitsu 1.29 (P)
- (void)openCommandCompletionList: (id)sender
{
      
	 [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:
       [NSURL fileURLWithPath:[CommandCompletionPath stringByStandardizingPath]] display:YES
                                                                   completionHandler: ^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
                                                                       if (document != nil) {
                                                                           g_canRegisterCommandCompletion = NO;
                                                                       }
                                                                   }];
	  // g_canRegisterCommandCompletion = NO;
}
// end mitsu 1.29

#ifdef MITSU_PDF
// mitsu 1.29 (O)
- (void)changeImageCopyType: (id)sender
{
	id  item;

	if ([sender isKindOfClass: [NSMenuItem class]]) {
		NSInteger imageCopyType;

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
			NSInteger idx = [popup indexOfItemWithTag: imageCopyType];
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
    if ([SUD integerForKey:FindMethodKey] == 2)
        [textFinder setShouldHackFindMenu:YES];
    else
        [textFinder setShouldHackFindMenu:NO];
}

// The routine below is no longer used; it has been replaced by Sparkle. Koch, 1/11/2009.

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
		[NSURL URLWithString:@"http://pages.uoregon.edu/koch/texshop/texshop-current.txt"]];

	NSString *latestVersion = [texshopVersionDictionary valueForKey:@"TeXShop"];
	
	NSInteger button;
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
#warning 64BIT: Check formatting arguments
									 [NSString stringWithFormat:
										 NSLocalizedString(@"A new version of TeXShop is available (version %@). Would you like to download it now?",
														   @"A new version of TeXShop is available (version %@). Would you like to download it now?"), latestVersion],
									 @"OK", @"Cancel", nil);
		if (button == NSOKButton) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://pages.uoregon.edu/koch/texshop/texshop.zip"]];
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
            result = [fileManager createDirectoryAtPath:dstPath withIntermediateDirectories:NO attributes:nil error: NULL];
			NS_HANDLER
				result = NO;
				reason = [localException reason];
			NS_ENDHANDLER
			if (!result) {
				NSRunAlertPanel(NSLocalizedString(@"Error", @"Error"), reason,
#warning 64BIT: Check formatting arguments
					[NSString stringWithFormat: NSLocalizedString(@"Couldn't create folder:\n%@", @"Message when creating a directory failed"), dstPath],
					nil, nil);
				return;
			}
		}
		
		// Iterate over the content of the source dir and copy it recursively
		NSEnumerator 	*fileEnumerator;
		NSString		*fileName;
		fileEnumerator = [[fileManager contentsOfDirectoryAtPath:srcPath error: NULL] objectEnumerator];
		while ((fileName = [fileEnumerator nextObject])) {
			[self mirrorPath:[srcPath stringByAppendingPathComponent:fileName]
					  toPath:[dstPath stringByAppendingPathComponent:fileName]];
		}
	} else {
		// Copy source to destination
		if (dstExists) {
			NS_DURING
			result = [fileManager removeItemAtPath: dstPath error: NULL];
			NS_HANDLER
				result = NO;
				reason = [localException reason];
			NS_ENDHANDLER
			if (!result) {
			}
		}
			
			
		
			NS_DURING
				// file doesn't exist -> copy it
        result = [fileManager copyItemAtPath:srcPath toPath:dstPath error:NULL];
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


@end

