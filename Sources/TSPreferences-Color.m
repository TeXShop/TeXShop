/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2007 Richard Koch
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
 * $Id: TSPreferences.m 254 2007-06-03 21:09:25Z fingolfin $
 *
 * Created by dirk on Thu Dec 07 2000.
 *
 */

#import "TSPreferences.h"
#import "globals.h"
#import "TSColorSupport.h"


@implementation TSPreferences (Color)

NSInteger stringSort(id s1, id s2, void *context)
{
    NSComparisonResult result;
    result =  [(NSString *)s1 localizedCaseInsensitiveCompare: (NSString *)s2];
    return result;
}


- (void)PrepareColorPane:(NSUserDefaults *)defaults;
{
    
    NSArray *contents, *originalContents;
    
  // Fill three menus with names of plist files in ~/Library/TeXShop/Colors
    
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    [colorSupport checkAndRestoreDefaults];
    
    oldLiteStyle = [SUD objectForKey: DefaultLiteThemeKey];
    oldDarkStyle = [SUD objectForKey: DefaultDarkThemeKey];

    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [ColorPath stringByExpandingTildeInPath];
    originalContents= [fileManager contentsOfDirectoryAtPath: filePath error: nil];
    contents = [originalContents sortedArrayUsingFunction: stringSort context: NULL ];
    
    NSUInteger i;
    NSString *theTitle;
    for (i = 0; i < [contents count]; i++)
    {
        if ([[contents[i] pathExtension] isEqualToString: @"plist"])
             {
                 theTitle = [contents[i] stringByDeletingPathExtension];
                 [LiteStyle addItemWithTitle: theTitle];
                 [DarkStyle addItemWithTitle: theTitle];
                 [EditingStyle addItemWithTitle: theTitle];
              }
    }
    NSString *liteTitle = [SUD stringForKey:DefaultLiteThemeKey];
    NSString *darkTitle = [SUD stringForKey:DefaultDarkThemeKey];
    
    // if this file doesn't exist, switch menu to LiteColors
    [LiteStyle selectItemWithTitle: liteTitle];
    [DarkStyle selectItemWithTitle: darkTitle];
    // if this file doesn't exist, switch menu to DarkColors
#ifdef MOJAVEORHIGHER
    if ((atLeastMojave) && (_prefsWindow.effectiveAppearance.name == NSAppearanceNameDarkAqua))
    {
        [EditingStyle selectItemWithTitle:darkTitle];
        EditingColors = [colorSupport dictionaryForColorFile: darkTitle];
    }
    else
#endif
    {
        [EditingStyle selectItemWithTitle: liteTitle];
        EditingColors = [colorSupport dictionaryForColorFile: liteTitle];
    }
    
    // Fill in all the color wells with the colors of these items
    
    [self FillInColorWells];
    
    
}


// OK button pressed in Preferences
// if the OK button is pressed, then the current editing changes for the currently chosen editing style are
// saved. Also the new choices for liteColor and darkColor are activated

- (void)okForColor
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    [self SaveEditedStyle:self];
    
    [SUD setObject:  [LiteStyle titleOfSelectedItem] forKey: DefaultLiteThemeKey];
    [SUD setObject: [DarkStyle titleOfSelectedItem] forKey: DefaultDarkThemeKey];
    [colorSupport     checkAndRestoreDefaults];
    [colorSupport initializeColors];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: nil];
    [[NSColorPanel sharedColorPanel] close];
  
}

// Cancel button pressed in Preferences
// if the cancel button is pressed, then all editing changes are lost EXCEPT those saved using the "Save" button
// also default lite and dark styles do not change

- (void)cancelForColor
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    [SUD setObject: oldLiteStyle forKey: DefaultLiteThemeKey];
    [SUD setObject: oldDarkStyle forKey: DefaultDarkThemeKey];
    [colorSupport checkAndRestoreDefaults];
    [colorSupport initializeColors];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: nil];
    [[NSColorPanel sharedColorPanel] close];
  
}

- (IBAction)LiteStyleChoice:sender
{
    
    // Make choice temporarily, but don't activate it until OK
    // Thus there is nothing to do here
    
}

- (IBAction)DarkStyleChoice:sender
{
    // Make choice temporarily, but don't activate it until OK
    // Thus there is nothing to do here
}

- (void)FillInColorWells
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    SourceTextColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"EditorText"];
    SourceBackgroundColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"EditorBackground"];
    SourceInsertionPointColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"EditorInsertionPoint"];
    PreviewBackgroundColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"PreviewBackground"];
    ConsoleTextColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"ConsoleText"];
    ConsoleBackgroundColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"ConsoleBackground"];
    LogTextColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"LogText"];
    LogBackgroundColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"LogBackground"];
    SyntaxCommentColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"SyntaxComment"];
    SyntaxCommandColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"SyntaxCommand"];
    SyntaxMarkerColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"SyntaxMarker"];
    SyntaxIndexColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"SyntaxIndex"];
    
    EditorHighlightBracesColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"EditorHighlightBraces"];
    EditorHighlightContentColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"EditorHighlightContent"];
    EditorInvisibleCharColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"EditorInvisibleChar"];
    EditorReverseSyncColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"EditorReverseSync"];
    PreviewDirectSyncColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"PreviewDirectSync"];
    SourceAlphaColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"SourceAlpha"];
    PreviewAlphaColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"PreviewAlpha"];
    ConsoleAlphaColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"ConsoleAlpha"];
    ImageForegroundColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"ImageForeground"];
    ImageBackgroundColorWell.color = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"ImageBackground"];
    
    
}

- (IBAction)EditingStyleChoice:sender
{
    NSString *newEditingItem = [EditingStyle titleOfSelectedItem];
    
    // Create a new dictionary with the colors of this style
    // Fill in all the color wells with the colors of these items
    
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    EditingColors = [colorSupport dictionaryForColorFile: newEditingItem ];
    // [colorSupport initializeColors];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    [self FillInColorWells];
}

- (IBAction)SaveEditedStyle:sender
{
    NSString *theTitle = [EditingStyle titleOfSelectedItem];
    
    NSString *newColorPath = [ColorPath stringByExpandingTildeInPath];
    NSString* ourColorPath = [[[newColorPath stringByAppendingString:@"/"] stringByAppendingString: theTitle] stringByAppendingString: @".plist"];
    
    [EditingColors writeToFile: ourColorPath atomically: YES];
    
    
}

- (IBAction)NewStyleFromPrefs:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSInteger result;
    NSString *theTitle;
    NSMutableDictionary *prefsDictionary;
    
    result = [NSApp runModalForWindow: stylePanel];
    // [packageHelpPanel close];
    if (result == 0) {
        theTitle = [styleTitle stringValue];
        [stylePanel close];
    }
    else {
        [stylePanel close];
        return;
    }
    
    if ([theTitle isEqualToString:@""])
        return;
    theTitle = [theTitle stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([theTitle isEqualToString:@""])
        return;
    
    NSString *newColorPath = [ColorPath stringByExpandingTildeInPath];
    NSString* ourColorPath = [[[newColorPath stringByAppendingString:@"/"] stringByAppendingString: theTitle] stringByAppendingString: @".plist"];
    
    if ([fileManager fileExistsAtPath:ourColorPath])
    {
        // dialog asking if should overwrite existing file; return if NO; otherwise continue
        NSAlert *alert = [NSAlert alertWithMessageText:@"Alert" defaultButton:@"Continue" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:NSLocalizedString(@"File already exists", @"File already exists")];
        result = [alert runModal];
        if (! result)
            return;
    }
    
    
    prefsDictionary = [NSMutableDictionary dictionaryWithCapacity:19];
    [prefsDictionary setObject: theTitle forKey:@"Title"];
     
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"EditorText" withRed: [SUD floatForKey:foreground_RKey]
                                          Green: [SUD floatForKey:foreground_GKey] Blue: [SUD floatForKey:foreground_BKey] Alpha: 1.0];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"EditorBackground" withRed: [SUD floatForKey:background_RKey]
                                      Green: [SUD floatForKey:background_GKey] Blue: [SUD floatForKey:background_BKey] Alpha: [SUD floatForKey:backgroundAlphaKey]];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"LogText" withRed: [SUD floatForKey:foreground_RKey]
                                      Green: [SUD floatForKey:foreground_GKey] Blue: [SUD floatForKey:foreground_BKey] Alpha: 1.0];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"LogBackground" withRed: [SUD floatForKey:background_RKey]
                                      Green: [SUD floatForKey:background_GKey] Blue: [SUD floatForKey:background_BKey] Alpha: [SUD floatForKey:backgroundAlphaKey]];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"ConsoleText" withRed: [SUD floatForKey:ConsoleForegroundColor_RKey]
                                      Green: [SUD floatForKey:ConsoleForegroundColor_GKey] Blue: [SUD floatForKey:ConsoleForegroundColor_BKey] Alpha: 1.0];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"ConsoleBackground" withRed: [SUD floatForKey:ConsoleBackgroundColor_RKey]
                                      Green: [SUD floatForKey:ConsoleBackgroundColor_GKey] Blue: [SUD floatForKey:ConsoleBackgroundColor_BKey] Alpha: [SUD floatForKey:ConsoleBackgroundAlphaKey]];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"EditorInsertionPoint" withRed: [SUD floatForKey:insertionpoint_RKey]
                                      Green: [SUD floatForKey:insertionpoint_GKey] Blue: [SUD floatForKey:insertionpoint_BKey] Alpha: 1.0];
    
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"SyntaxComment" withRed: [SUD floatForKey:commentredKey]
                                      Green: [SUD floatForKey:commentgreenKey] Blue: [SUD floatForKey:commentblueKey] Alpha: 1.0];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"SyntaxCommand" withRed: [SUD floatForKey:commandredKey]
                                      Green: [SUD floatForKey:commandgreenKey] Blue: [SUD floatForKey:commandblueKey] Alpha: 1.0];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"SyntaxMarker" withRed: [SUD floatForKey:markerredKey]
                                      Green: [SUD floatForKey:markergreenKey] Blue: [SUD floatForKey:markerblueKey] Alpha: 1.0];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"SyntaxIndex" withRed: [SUD floatForKey:indexredKey]
                                      Green: [SUD floatForKey:indexgreenKey] Blue: [SUD floatForKey:indexblueKey] Alpha: 1.0];
    
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"EditorHighlightBraces" withRed: [SUD floatForKey:highlightBracesRedKey]
                                      Green: [SUD floatForKey:highlightBracesGreenKey] Blue: [SUD floatForKey:highlightBracesBlueKey] Alpha: 1.0];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"EditorHighlightContent" withRed: [SUD floatForKey:highlightContentRedKey]
                                      Green: [SUD floatForKey:highlightContentGreenKey] Blue: [SUD floatForKey:highlightContentBlueKey] Alpha: 1.0];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"EditorInvisibleChar" withRed: [SUD floatForKey:invisibleCharRedKey]
                                      Green: [SUD floatForKey:invisibleCharGreenKey] Blue: [SUD floatForKey:invisibleCharBlueKey] Alpha: 1.0];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"EditorReverseSync" withRed: [SUD floatForKey:reverseSyncRedKey]
                                      Green: [SUD floatForKey:reverseSyncGreenKey] Blue: [SUD floatForKey:reverseSyncBlueKey] Alpha: 1.0];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"PreviewDirectSync" withRed: 1.0 Green: 1.0 Blue: 0.0 Alpha: 1.0];
    
    
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"PreviewBackground" withRed: [SUD floatForKey:PdfPageBack_RKey]
                                      Green: [SUD floatForKey:PdfPageBack_GKey] Blue: [SUD floatForKey:PdfPageBack_BKey] Alpha: 1.0];
    
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"SourceAlpha" withRed: 1.0
                                      Green: 1.0 Blue: 1.0 Alpha: [SUD floatForKey: SourceWindowAlphaKey]];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"PreviewAlpha" withRed: 1.0
                                      Green: 1.0  Blue: 2.0 Alpha: [SUD floatForKey: PreviewWindowAlphaKey]];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"ConsoleAlpha" withRed: 1.0
                                      Green: 1.0 Blue: 1.0 Alpha: [SUD floatForKey: ConsoleWindowAlphaKey]];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"ImageForeground" withRed: [SUD floatForKey:PdfFore_RKey]
                                      Green: [SUD floatForKey:PdfFore_GKey] Blue: [SUD floatForKey:PdfFore_BKey]
                                      Alpha: [SUD floatForKey:PdfFore_AKey]];
    [colorSupport setColorValueInDictionary: prefsDictionary forKey: @"ImageBackground" withRed: [SUD floatForKey:PdfBack_RKey]
                                      Green: [SUD floatForKey:PdfBack_GKey] Blue: [SUD floatForKey:PdfBack_BKey]
                                      Alpha: [SUD floatForKey:PdfBack_AKey]];
    
    
    [prefsDictionary writeToFile: ourColorPath atomically: YES];
    
    [LiteStyle addItemWithTitle: theTitle];
    [DarkStyle addItemWithTitle: theTitle];
    [EditingStyle addItemWithTitle: theTitle];
    [EditingStyle selectItemWithTitle: theTitle];

    
}



- (IBAction)SaveNewStyle:sender
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSInteger result;
    NSString *theTitle;
    
    result = [NSApp runModalForWindow: stylePanel];
    // [packageHelpPanel close];
    if (result == 0) {
        theTitle = [styleTitle stringValue];
        [stylePanel close];
    }
    else {
        [stylePanel close];
        return;
    }
    
    if ([theTitle isEqualToString:@""])
        return;
    theTitle = [theTitle stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([theTitle isEqualToString:@""])
        return;
    
    NSString *newColorPath = [ColorPath stringByExpandingTildeInPath];
    NSString* ourColorPath = [[[newColorPath stringByAppendingString:@"/"] stringByAppendingString: theTitle] stringByAppendingString: @".plist"];
    
    if ([fileManager fileExistsAtPath:ourColorPath])
    {
        // dialog asking if should overwrite existing file; return if NO; otherwise continue
        NSAlert *alert = [NSAlert alertWithMessageText:@"Alert" defaultButton:@"Continue" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:NSLocalizedString(@"File already exists", @"File already exists")];
        result = [alert runModal];
        if (! result)
            return;
    }
    
    
    [EditingColors setObject: theTitle forKey: @"Title"];
    [EditingColors writeToFile: ourColorPath atomically: YES];
    
    [LiteStyle addItemWithTitle: theTitle];
    [DarkStyle addItemWithTitle: theTitle];
    [EditingStyle addItemWithTitle: theTitle];
    [EditingStyle selectItemWithTitle: theTitle];
    
}

- (void) okForStylePanel: sender
{
    [NSApp stopModalWithCode: 0];
}

- (void) cancelForStylePanel: sender
{
    [NSApp stopModalWithCode:1];
}



// Actual Colors
- (IBAction)SourceTextColorChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"EditorText"];
        ((NSColorWell *)sender).color = oldColor;
    }

    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"EditorText" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)SourceBackgroundColorChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"EditorBackground"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"EditorBackground" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)SourceInsertionPointColorChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"EditorInsertionPoint"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"EditorInsertionPoint" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)PreviewBackgroundColorChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"PreviewBackground"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"PreviewBackground" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object: self userInfo:EditingColors];
    
}

- (IBAction)ConsoleTextColorChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"ConsoleText"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"ConsoleText" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)ConsoleBackgroundColorChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"ConsoleBackground"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"ConsoleBackground" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)LogTextColorChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"LogText"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"LogText" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)LogBackgroundColorChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"LogBackground"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"LogBackground" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}


- (IBAction)SyntaxCommentColorChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"SyntaxComment"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"SyntaxComment" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)SyntaxCommandColorChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"SyntaxCommand"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"SyntaxCommand" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)SyntaxMarkerColorChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"SyntaxMarker"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"SyntaxMarker" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)SyntaxIndexColorChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"SyntaxIndex"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"SyntaxIndex" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)EditorReverseSyncChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"EditorReverseSync"];
        ((NSColorWell *)sender).color = oldColor;
    }
   [colorSupport changeColorValueInDictionary: EditingColors forKey: @"EditorReverseSync" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)PreviewDirectSyncChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"PreviewDirectSync"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"PreviewDirectSync" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}


- (IBAction)EditorHighlightBracesChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"EditorHighlightBraces"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"EditorHighlightBraces" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)EditorHighlightContentChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"EditorHighlightContent"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"EditorHighlightContent" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)EditorInvisibleCharChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"EditorInvisibleChar"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"EditorInvisibleChar" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)SourceAlphaChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"SourceAlpha"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"SourceAlpha" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)PreviewAlphaChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"PreviewAlpha"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"PreviewAlpha" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)ConsoleAlphaChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"ConsoleAlpha"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"ConsoleAlpha" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)ImageForegroundChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"ImageForeground"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"ImageForeground" fromColorWell:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}

- (IBAction)ImageBackgroundChanged:sender
{
    TSColorSupport *colorSupport = [TSColorSupport sharedInstance];
    
    if (! _prefsWindow.keyWindow )
    {
        [[NSColorPanel sharedColorPanel] close];
        NSColor *oldColor = [colorSupport colorFromDictionary:EditingColors andKey: @"ImageBackground"];
        ((NSColorWell *)sender).color = oldColor;
    }
    [colorSupport changeColorValueInDictionary: EditingColors forKey: @"ImageBackground" fromColorWell:sender];
     [[NSNotificationCenter defaultCenter] postNotificationName:SourceColorChangedNotification object:self userInfo: EditingColors];
    
}


@end
