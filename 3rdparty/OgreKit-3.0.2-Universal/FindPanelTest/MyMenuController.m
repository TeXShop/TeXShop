/*
 * Name: MyMenuController.m
 * Project: OgreKit
 *
 * Creation Date: Oct 16 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyMenuController.h"
#import "MyDocument.h"

@implementation MyMenuController

/* 改行コードの変更をmain windowのdelegateに伝える (非常に手抜き) */
- (IBAction)selectCr:(id)sender
{
	[(MyDocument*)[[NSApp mainWindow] delegate] setNewlineCharacter:OgreCrNewlineCharacter];
}

- (IBAction)selectCrLf:(id)sender
{
	[(MyDocument*)[[NSApp mainWindow] delegate] setNewlineCharacter:OgreCrLfNewlineCharacter];
}

- (IBAction)selectLf:(id)sender
{
	[(MyDocument*)[[NSApp mainWindow] delegate] setNewlineCharacter:OgreLfNewlineCharacter];
}

/* 新規ドキュメント */
- (IBAction)newTextDocument:(id)sender
{
    NSDocument* document = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"MyTextDocumentType" error:nil];
    [document makeWindowControllers];
    [document showWindows];
}

- (IBAction)newRTFDocument:(id)sender
{
    NSDocument* document = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"MyRTFDocumentType" error:nil];
    [document makeWindowControllers];
    [document showWindows];
}

- (IBAction)newTableDocument:(id)sender
{
    NSDocument* document = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"MyTableDocumentType" error:nil];
    [document makeWindowControllers];
    [document showWindows];
}

- (IBAction)newOutlineDocument:(id)sender
{
    NSDocument* document = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"MyOutlineDocumentType" error:nil];
    [document makeWindowControllers];
    [document showWindows];
}

- (IBAction)newTableDocumentWithCocoaBinding:(id)sender
{
    NSDocument* document = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"MyTableDocumentWithCocoaBindingType" error:nil];
    [document makeWindowControllers];
    [document showWindows];
}


- (void)awakeFromNib
{
    [NSApp setDelegate:self];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication*)sender
{
    return NO;
}

- (void)ogreKitWillHackFindMenu:(OgreTextFinder*)textFinder
{
	[textFinder setShouldHackFindMenu:YES];
}

- (void)ogreKitShouldUseStylesInFindPanel:(OgreTextFinder*)textFinder
{
	[textFinder setUseStylesInFindPanel:YES];
}

@end
