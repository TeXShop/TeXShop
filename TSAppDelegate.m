//
//  TSAppDelegate.m
//  TeXShop
//
//  Created by dirk on Tue Jan 23 2001.
//


#import <Foundation/Foundation.h>
#import "TSAppDelegate.h"
#import "TSPreferences.h"
#import "globals.h"
#import "TSWindowManager.h"

#define SUD [NSUserDefaults standardUserDefaults]

/*" This class is registered as the delegate of the TeXShop NSApplication object. We do various stuff here, e.g. registering factory defaults, dealing with keyboard shortcuts etc.
"*/
@implementation TSAppDelegate

- (id)init
{
    return [super init];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    NSString *fileName;
    NSMutableString *path;
    NSDictionary *factoryDefaults;

    // if this is the first time the app is used, register a set of defaults to make sure
    // that the app is useable.
    if (([[NSUserDefaults standardUserDefaults] boolForKey:TSHasBeenUsedKey] == NO) ||
        ([[NSUserDefaults standardUserDefaults] objectForKey:TetexBinPathKey] == nil)) {
        [[TSPreferences sharedInstance] registerFactoryDefaults];
    }
    
    else {
	// register defaults
	fileName = [[NSBundle mainBundle] pathForResource:@"FactoryDefaults" ofType:@"plist"];
	NSParameterAssert(fileName != nil);
	factoryDefaults = [[NSString stringWithContentsOfFile:fileName] propertyList];
        [SUD registerDefaults:factoryDefaults];
    }
    
    // get copy of environment and add the preferences paths
    TSEnvironment = [[NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]] retain];
    path = [NSMutableString stringWithString: [TSEnvironment objectForKey:@"PATH"]];
    [path appendString:@":"];
    [path appendString:[SUD stringForKey:TetexBinPathKey]];
    [path appendString:@":"];
    [path appendString:[SUD stringForKey:GSBinPathKey]];
    [TSEnvironment setObject: path forKey: @"PATH"];
    
    [self configureExternalEditor];
	
    // documentsHaveLoaded = NO;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return [SUD boolForKey:MakeEmptyDocumentKey];
}

- (void)configureExternalEditor
{
    NSString	*menuTitle;
    
    forPreview =  [SUD boolForKey:UseExternalEditorKey];
    if (forPreview)
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
        forPreview = NO;
    else
        forPreview = YES;
        
/* This code restricts files to tex files */
    myArray = [[NSArray alloc] initWithObjects:@"tex",
                                        @"TEX",
                                        @"txt",
                                        @"TXT",
                                        @"bib",
                                        @"mp",
                                        @"ins",
                                        @"dtx",
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
        forPreview = YES;
    else
        forPreview = NO;
}

- (BOOL)forPreview
{
    return forPreview;
}

- (IBAction)displayLatexPanel:(id)sender
{
    if ([[sender title] isEqualToString:NSLocalizedString(@"LaTeX Panel...", @"LaTeX Panel...")]) {
        [[Autrecontroller sharedInstance] showWindow:self];
        [sender setTitle:NSLocalizedString(@"Close LaTeX Panel", @"Close LaTeX Panel")];
        }
    else {
        [[Autrecontroller sharedInstance] hideWindow:self];
        [sender setTitle:NSLocalizedString(@"LaTeX Panel...", @"LaTeX Panel...")];
        }
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
{
    id		documentWindow;
    
    if ([[anItem title] isEqualToString:NSLocalizedString(@"LaTeX Panel...", @"LaTeX Panel...")]) {
        documentWindow = [[TSWindowManager sharedInstance] activeDocumentWindow];
        if (documentWindow == nil)
            return NO;
        else if ([documentWindow isKeyWindow])
            return YES;
        else
            return NO;
        }
    else 
        return YES;
}


/* I interprete comments from Anton Leuski as saying that this is not
necessary */
/*
- (void)dealloc
{
    [super dealloc];
}
*/



@end
