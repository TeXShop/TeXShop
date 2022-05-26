//
//  TSColorSupport.m
//  
//
//  Created by Richard Koch on 7/26/2018.
//  Copyright 2018 University of Oregon. All rights reserved.
//

#import "globals.h"
#import "TSColorSupport.h"

@implementation TSColorSupport

// Pointer to the TSColorSupport singleton
static id sharedColorSupport = nil;



+ (id)sharedInstance
{
    if (sharedColorSupport == nil) {
        sharedColorSupport = [[TSColorSupport alloc] init];
    }
    return sharedColorSupport;
}

// A user might remove ALL color styles from Library/TeXShop/Colors
// The routine below checks whether LiteTheme.plist and DarkTheme.plist exist in this directory
// If not, it restores them with default files
- (void)checkAndRestoreDefaults;
{
    NSString *reserveLitePath, *reserveDarkPath;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *newColorPath = [ColorPath stringByExpandingTildeInPath];
    NSString* liteColorPath = [[newColorPath stringByAppendingString:@"/"] stringByAppendingString: @"LiteTheme.plist"];
    NSString* darkColorPath = [[newColorPath stringByAppendingString:@"/"] stringByAppendingString: @"DarkTheme.plist"];
    
    if (! [fileManager fileExistsAtPath: liteColorPath])
    {
        reserveLitePath = [[NSBundle mainBundle] pathForResource:@"LiteTheme" ofType:@"plist"];
        [fileManager copyItemAtPath: reserveLitePath toPath: liteColorPath error: nil];
    }
    if (! [fileManager fileExistsAtPath: darkColorPath])
    {
        reserveDarkPath = [[NSBundle mainBundle] pathForResource:@"DarkTheme" ofType:@"plist"];
        [fileManager copyItemAtPath: reserveDarkPath toPath: darkColorPath error: nil];
    }
}

// This routine sets the Lite and Dark color dictionaries. It also checks to make sure the default color plist exists.
// If not, it switches to LiteColors and/or DarkColors and changes the default values for these items.

- (void)initializeColors
{
    
    NSString *lite = [SUD stringForKey: DefaultLiteThemeKey];
    NSString *dark = [SUD stringForKey: DefaultDarkThemeKey];
    
    NSString *newColorPath = [ColorPath stringByExpandingTildeInPath];
    NSString* liteThemePath = [[[newColorPath stringByAppendingString:@"/"] stringByAppendingString: lite] stringByAppendingString: @".plist"];
    NSString* darkThemePath = [[[newColorPath stringByAppendingString:@"/"] stringByAppendingString: dark] stringByAppendingString: @".plist"];
    NSString* defaultLiteThemePath = [[newColorPath stringByAppendingString:@"/"] stringByAppendingString: @"LiteTheme.plist"];
    NSString* defaultDarkThemePath = [[newColorPath stringByAppendingString:@"/"] stringByAppendingString: @"DarkTheme.plist"];
    
    
    [self checkAndRestoreDefaults];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (! [fileManager fileExistsAtPath: liteThemePath])
    {
        [SUD setObject: @"LiteTheme" forKey: DefaultLiteThemeKey];
        liteThemePath = defaultLiteThemePath;
    }
    if (! [fileManager fileExistsAtPath: darkThemePath])
    {
        [SUD setObject: @"DarkTheme" forKey: DefaultDarkThemeKey];
        darkThemePath = defaultDarkThemePath;
    }
    
    liteColors = [NSDictionary dictionaryWithContentsOfFile:liteThemePath];
    darkColors = [NSDictionary dictionaryWithContentsOfFile:darkThemePath];
}

- (NSMutableDictionary *) dictionaryForColorFile: (NSString *) fileTitle
{
    
    NSString *newColorPath = [ColorPath stringByExpandingTildeInPath];
    NSString *colorFilePath = [[[newColorPath stringByAppendingString:@"/"] stringByAppendingString: fileTitle] stringByAppendingString: @".plist"];
    return [NSMutableDictionary dictionaryWithContentsOfFile:colorFilePath];
}


- (NSColor *) colorFromDictionary:(NSDictionary *)theDictionary andKey: (NSString *)theKey
{
    NSArray *theColorArray = [theDictionary objectForKey: theKey];
    if (theColorArray == nil)
        return nil;
    NSColor *theColor = [NSColor colorWithRed: [theColorArray[0] doubleValue]  green: [theColorArray[1] doubleValue]  blue: [theColorArray[2] doubleValue]  alpha:1.00];
    
    return theColor;
}


- (NSColor *) colorAndAlphaFromDictionary:(NSDictionary *)theDictionary andKey: (NSString *)theKey
{
    NSArray *theColorArray = [theDictionary objectForKey: theKey];
    if (theColorArray == nil)
        return nil;
    NSColor *theColor = [NSColor colorWithRed: [theColorArray[0] doubleValue]  green: [theColorArray[1] doubleValue]  blue: [theColorArray[2] doubleValue]  alpha: [theColorArray[3] doubleValue]];
    
    return theColor;
}

// When colors are added later, dictionaries may not have them; the four calls below give default values until the user selects new
// colors for these keys and consequentlycolor adds entries to dictionaries
- (NSColor *)liteColorWithKey: (NSString *)theKey
{
    if ([theKey isEqualToString: @"EditorFlash"])
        return [NSColor colorWithRed: 1 green: 0.95 blue: 1 alpha:1.00];
    else if ([theKey isEqualToString: @"FootnoteColor"]) //not actually used
        return [NSColor colorWithRed: 0.35  green: 0.35  blue: 0.35 alpha:1.00];
    else if ([theKey isEqualToString: @"EntryColor"])
        return [NSColor colorWithRed: 0.9  green: 0.99  blue: 0.99 alpha:1.00];
    
    else if ([theKey isEqualToString: @"XMLComment"])
        return [NSColor colorWithRed: 0.50  green: 0.50  blue: 0.50 alpha:1.00];
    else if ([theKey isEqualToString: @"XMLTag"])
        return [NSColor colorWithRed: 1.00  green: 0.00  blue: 0.20 alpha:1.00];
    else if ([theKey isEqualToString: @"XMLSpecial"])
        return [NSColor colorWithRed: 0.00  green: 0.30  blue: 1.00 alpha:1.00];
    else if ([theKey isEqualToString: @"XMLParameter"])
        return [NSColor colorWithRed: 0.00  green: 1.00  blue: 0.00 alpha:1.00];
    else if ([theKey isEqualToString: @"XMLValue"])
        return [NSColor colorWithRed: 0.60  green: 0.60  blue: 0.20 alpha:1.00];
    
    else
        return [NSColor colorWithRed: 1.00  green: 1.00 blue: 1.00 alpha:1.00];
}

- (NSColor *)darkColorWithKey: (NSString *)theKey
{
    if ([theKey isEqualToString: @"EditorFlash"])
        return [NSColor colorWithRed: 0.00 green: 0.20  blue: 0.20 alpha:1.00];
    else if ([theKey isEqualToString: @"FootnoteColor"]) //not actually used
        return [NSColor colorWithRed: 0.75 green: 0.75 blue: 0.75 alpha:1.00];
    else if ([theKey isEqualToString: @"EntryColor"])
        return [NSColor colorWithRed: 0.1 green: 0.01 blue: 0.01 alpha:1.00];
    
    else if ([theKey isEqualToString: @"XMLComment"]) //not actually used
        return [NSColor colorWithRed: 0.50  green: 0.50  blue: 0.50 alpha:1.00];
    else if ([theKey isEqualToString: @"XMLTag"]) //not actually used
        return [NSColor colorWithRed: 1.00  green: 0.00  blue: 0.20 alpha:1.00];
    else if ([theKey isEqualToString: @"XMLSpecial"]) //not actually used
        return [NSColor colorWithRed: 0.00  green: 0.30  blue: 1.00 alpha:1.00];
    else if ([theKey isEqualToString: @"XMLParameter"]) //not actually used
        return [NSColor colorWithRed: 0.00  green: 1.00  blue: 0.00 alpha:1.00];
    else if ([theKey isEqualToString: @"XMLValue"]) //not actually used
        return [NSColor colorWithRed: 0.60  green: 0.60  blue: 0.20 alpha:1.00];

    
    else
        return [NSColor colorWithRed: 0.00  green: 0.00 blue: 0.00 alpha:1.00];
}


- (NSColor *)liteColorAndAlphaWithKey: (NSString *)theKey
{
    return [self liteColorWithKey: theKey];
}

- (NSColor *)darkColorAndAlphaWithKey: (NSString *)theKey
{
      return [self darkColorWithKey: theKey];
}


- (void)setColorValueInDictionary: (NSMutableDictionary *)theDictionary forKey: (NSString *)theKey withRed: (double)red
        Green: (double)green Blue: (double)blue Alpha: (double)alpha
{
    NSNumber *redNumber, *greenNumber, *blueNumber, *alphaNumber;
    
    redNumber = [NSNumber numberWithDouble: red];
    greenNumber = [NSNumber numberWithDouble: green];
    blueNumber = [NSNumber numberWithDouble: blue];
    alphaNumber = [NSNumber numberWithDouble: alpha];
    NSArray *theArray = @[redNumber, greenNumber, blueNumber, alphaNumber];
    [theDictionary setObject: theArray forKey:theKey];
}


- (void)changeColorValueInDictionary: (NSMutableDictionary *)theDictionary forKey: (NSString *)theKey fromColorWell: (id)theWell
{
    CGFloat aRed, aGreen, aBlue, anAlpha;
    NSNumber *redNumber, *greenNumber, *blueNumber, *alphaNumber;
    
    NSColor *newColor = ((NSColorWell *)theWell).color;
    NSColor *theColor = [newColor colorUsingColorSpace: NSColorSpace.genericRGBColorSpace];
    [theColor getRed: &aRed green: &aGreen blue: &aBlue alpha: &anAlpha];
    redNumber = [NSNumber numberWithDouble: aRed];
    greenNumber = [NSNumber numberWithDouble: aGreen];
    blueNumber = [NSNumber numberWithDouble: aBlue];
    alphaNumber = [NSNumber numberWithDouble: anAlpha];
    NSArray *theArray = @[redNumber, greenNumber, blueNumber, alphaNumber];
    [theDictionary setObject: theArray forKey:theKey];
}

@end
