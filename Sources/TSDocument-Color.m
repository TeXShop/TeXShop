/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2014 Richard Koch
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
 * $Id: TSDocument-Jobs.m 254 2014-06-28 21:09:25Z fingolfin $
 *
 */


#import "TSDocument.h"
#import "globals.h"
#import "TSColorSupport.h"
#import "MyPDFKitView.h"


@implementation TSDocument (Color)

- (void)changeColors: (BOOL)toDark;
{
    NSDictionary *theDictionary;
    
    if (toDark)
        theDictionary = darkColors;
    else
        theDictionary = liteColors;
    
    [self changeColorsUsingDictionary: theDictionary];
    
}

- (void) changeColorsUsingDictionary: (NSDictionary *)colorDictionary
{
    NSColor *myBackgroundColor;
    NSColor *myTextColor;
    NSColor *mySyntaxColor;
    NSColor *myEntryColor;
    NSColor *myColor;
    NSArray *myArray;
    NSNumber *myNumber;
    BOOL    withDarkColors;
    
#ifdef MOJAVEORHIGHER
    if ((atLeastMojave) && (textWindow.effectiveAppearance.name == NSAppearanceNameDarkAqua))
        withDarkColors = YES;
    else
#endif
        withDarkColors = NO;
    
 /*
      flashColor = [colorSupport colorAndAlphaFromDictionary:EditingColors andKey: @"EditorFlash"];
    if (flashColor != nil)
        EditorFlashColorWell.color = flashColor;
    else if (withDarkColors)
        EditorFlashColorWell.color = [NSColor colorWithDeviceRed:0.00 green:0.20 blue:0.20 alpha:1.00];
    else
        EditorFlashColorWell.color = [NSColor colorWithDeviceRed:1 green:0.95 blue:1 alpha:1];
*/
    
    
    // EDITOR
    
    PreviewBackgroundColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"PreviewBackground"];
    
    myBackgroundColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"EditorBackground"];
    myTextColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"EditorText"];
    
  // [textView1 setTextColor: myTextColor];
  // [textView2 setTextColor: myTextColor];
    [textView1 setBackgroundColor: myBackgroundColor];
    [textView2 setBackgroundColor: myBackgroundColor];
  
/*
    NSParagraphStyle         *    paraStyle            = [NSParagraphStyle defaultParagraphStyle];
    NSMutableParagraphStyle    *    newStyle            = [paraStyle mutableCopy] ;
    
    NSMutableDictionary *theTypingAttributes = [[NSMutableDictionary alloc] initWithCapacity:1] ;
    [theTypingAttributes setObject:newStyle forKey:NSParagraphStyleAttributeName];
    [textView1 setTypingAttributes:theTypingAttributes];
    
    NSMutableDictionary *theTypingAttributes2 = [[NSMutableDictionary alloc] initWithCapacity:1];
    [theTypingAttributes2 setObject:newStyle forKey:NSParagraphStyleAttributeName];
    [textView2 setTypingAttributes:theTypingAttributes2];
    
    [textView1 setFontSafely:font];
    [textView1 setDefaultParagraphStyle: newStyle];
    [textView2 setFontSafely:font];
    [textView2 setDefaultParagraphStyle: newStyle];
*/
    
    
    [textView1 setTextColor: myTextColor];
    [textView2 setTextColor: myTextColor];

 
    // LOG WINDOW
    
    myBackgroundColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"LogBackground"];
    myTextColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"LogText"];
    
    [self.logTextView setTextColor: myTextColor];
    [self.logTextView setBackgroundColor: myBackgroundColor];
    
    // CONSOLE WINDOW
    
    myBackgroundColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"ConsoleBackground"];
    myTextColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"ConsoleText"];
    
    [outputText setTextColor: myTextColor];
    [outputText setBackgroundColor: myBackgroundColor];
    
    
    //SYNTAX COLORS
    
    // SyntaxComment,   SyntaxCommand,  SyntaxMarker,    SyntaxIndex
    
    // TEMPORARY
/*
    float r, g, b;
    NSColor *color;
    r = 0.5;
    g = 0.5;
    b = 0.5;
    color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
    self.commentXMLColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];

    r = 1.0;
    g = 0.0;
    b = 0.2;
    color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
    self.tagXMLColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];

    r = 0.0;
    g = 0.3;
    b = 1.0;
    color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
    self.specialXMLColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];

    r = 0.0;
    g = 1.0;
    b = 0.0;
    color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
    self.parameterXMLColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];

    r = 0.6;
    g = 0.6;
    b = 0.2;
    color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
    self.valueXMLColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];
*/
   
    mySyntaxColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"XMLComment"];
    if (mySyntaxColor == nil) {
        if (withDarkColors)
            mySyntaxColor = [[TSColorSupport sharedInstance] darkColorAndAlphaWithKey: @"XMLComment"];
        else
            mySyntaxColor = [[TSColorSupport sharedInstance] liteColorAndAlphaWithKey: @"XMLComment"];
        }
    self.commentXMLColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:mySyntaxColor, NSForegroundColorAttributeName, nil];
    
    
    mySyntaxColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"XMLTag"];
    if (mySyntaxColor == nil) {
        if (withDarkColors)
            mySyntaxColor = [[TSColorSupport sharedInstance] darkColorAndAlphaWithKey: @"XMLTag"];
        else
            mySyntaxColor = [[TSColorSupport sharedInstance] liteColorAndAlphaWithKey: @"XMLTag"];
    }
    self.tagXMLColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:mySyntaxColor, NSForegroundColorAttributeName, nil];
    
    mySyntaxColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"XMLSpecial"];
    if (mySyntaxColor == nil) {
        if (withDarkColors)
            mySyntaxColor = [[TSColorSupport sharedInstance] darkColorAndAlphaWithKey: @"XMLSpecial"];
        else
            mySyntaxColor = [[TSColorSupport sharedInstance] liteColorAndAlphaWithKey: @"XMLSpecial"];
    }
    self.specialXMLColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:mySyntaxColor, NSForegroundColorAttributeName, nil];
    
    mySyntaxColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"XMLParameter"];
    if (mySyntaxColor == nil) {
        if (withDarkColors)
            mySyntaxColor = [[TSColorSupport sharedInstance] darkColorAndAlphaWithKey: @"XMLParameter"];
        else
            mySyntaxColor = [[TSColorSupport sharedInstance] liteColorAndAlphaWithKey: @"XMLParameter"];
    }
    self.parameterXMLColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:mySyntaxColor, NSForegroundColorAttributeName, nil];
    
    mySyntaxColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"XMLValue"];
    if (mySyntaxColor == nil) {
        if (withDarkColors)
            mySyntaxColor = [[TSColorSupport sharedInstance] darkColorAndAlphaWithKey: @"XMLValue"];
        else
            mySyntaxColor = [[TSColorSupport sharedInstance] liteColorAndAlphaWithKey: @"XMLValue"];
    }
    self.valueXMLColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:mySyntaxColor, NSForegroundColorAttributeName, nil];
   

    // END OF TEMPORARY
    
    mySyntaxColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"SyntaxComment"];
    self.commentColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:mySyntaxColor, NSForegroundColorAttributeName, nil];
    
    mySyntaxColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"SyntaxCommand"];
    self.commandColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:mySyntaxColor, NSForegroundColorAttributeName, nil];
    
    mySyntaxColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"SyntaxMarker"];
    self.markerColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:mySyntaxColor, NSForegroundColorAttributeName, nil];
    
    mySyntaxColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"SyntaxIndex"];
    if (mySyntaxColor == nil) {
        if (withDarkColors)
            mySyntaxColor = [NSColor colorWithRed: 1.0 green: 1.0 blue: 0.00 alpha: 1.00];
        else
            mySyntaxColor = [NSColor colorWithRed: 1.0 green: 1.0 blue: 0.00 alpha: 1.00];
        }
    self.indexColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:mySyntaxColor, NSForegroundColorAttributeName, nil];
    
    mySyntaxColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"FootnoteColor"];
    if (mySyntaxColor == nil)
        mySyntaxColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"SyntaxCommand"];
    /*
        {
        if (withDarkColors)
            // mySyntaxColor = [NSColor colorWithRed: 0.75 green: 0.75 blue: 0.75 alpha: 1.00];
            mySyntaxColor = [[TSColorSupport sharedInstance] darkColorWithKey: @"FootnoteColor"];
        else
            // mySyntaxColor = [NSColor colorWithRed: 0.35 green: 0.35 blue: 0.35 alpha: 1.00];
            mySyntaxColor = [[TSColorSupport sharedInstance] liteColorWithKey: @"FootnoteColor"];
        }
     */
    self.footnoteColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:mySyntaxColor, NSForegroundColorAttributeName, nil];
    
    myEntryColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"EntryColor"];
    if (myEntryColor == nil)
        myEntryColor = [[TSColorSupport sharedInstance] liteColorAndAlphaWithKey: @"EntryColor"];
    
    self.EntryColorAttribute = [[NSDictionary alloc] initWithObjectsAndKeys: myEntryColor, NSBackgroundColorAttributeName, nil];
   
    myColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"EditorHighlightBraces"];
    highlightBracesColorDict = [NSDictionary dictionaryWithObjectsAndKeys: myColor, NSForegroundColorAttributeName, nil ] ;
    
    myColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"EditorHighlightContent"];
    highlightContentColorDict = [NSDictionary dictionaryWithObjectsAndKeys: myColor, NSBackgroundColorAttributeName, nil ];
    
    myColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"EditorReverseSync"];
    ReverseSyncColor = myColor;
    
    myColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"EditorInsertionPoint"];
    [textView1 setInsertionPointColor: myColor];
    [textView2 setInsertionPointColor: myColor];
    
    myColor = [[TSColorSupport sharedInstance] colorFromDictionary:colorDictionary andKey: @"EditorInvisibleChar"];
    InvisibleColor = myColor;
    
    myArray = [colorDictionary objectForKey:@"PreviewAlpha"];
    myNumber = myArray[3];
    self.pdfKitWindow.alphaValue = [myNumber floatValue];
    
    myArray = [colorDictionary objectForKey:@"SourceAlpha"];
    myNumber = myArray[3];
    textWindow.alphaValue = [myNumber floatValue];
    fullSplitWindow.alphaValue = [myNumber floatValue];
    
    myArray = [colorDictionary objectForKey:@"ConsoleAlpha"];
    myNumber = myArray[3];
    outputWindow.alphaValue = [myNumber floatValue];
    
    myColor = [[TSColorSupport sharedInstance] colorAndAlphaFromDictionary:colorDictionary andKey: @"ImageForeground"];
    ImageForegroundColor = myColor;
    
    myColor = [[TSColorSupport sharedInstance] colorAndAlphaFromDictionary:colorDictionary andKey: @"ImageBackground"];
    ImageBackgroundColor = myColor;
    
    myColor = [[TSColorSupport sharedInstance] colorAndAlphaFromDictionary:colorDictionary andKey: @"PreviewDirectSync"];
    PreviewDirectSyncColor = myColor;
    
   
    [self.myPDFKitView setNeedsDisplay: YES];
    [self.myPDFKitView2 setNeedsDisplay: YES];

    // update console and log
    [outputWindow display];
    [self.logWindow display];
    
    [self colorizeVisibleAreaInTextView:textView1];
    [self colorizeVisibleAreaInTextView:textView2];
    
}

- (void) changeColorsFromNotification:(NSNotification *)notification
{
    NSDictionary *colorDictionary;
    
    colorDictionary = notification.userInfo;
    
    // next code is case when color change didn't really come from a notification
    
    if (colorDictionary == nil)
    {
        colorDictionary = liteColors;
#ifdef MOJAVEORHIGHER
       if (atLeastMojave)
       {
        if (textView1.effectiveAppearance.name == NSAppearanceNameDarkAqua)
            colorDictionary = darkColors;
       }
#endif
    }
    
    [self changeColorsUsingDictionary: colorDictionary];
    
}


@end
