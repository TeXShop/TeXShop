//
//  Autrecontroller.m
//  test3
//
//  Created by lenglin on Sun Aug 26 2001.
//  Copyright (c) 2001 __NorignalSoft__. All rights reserved.
//

#import "Autrecontroller.h"
#import "globals.h"

@implementation Autrecontroller

static id _sharedInstance = nil;

+ (id)sharedInstance
{
	if (_sharedInstance == nil)
	{
		_sharedInstance = [[Autrecontroller alloc] initWithWindowNibName:@"completionpanel1.2"];
	}
	return _sharedInstance;
}

- (void)init
{
    [super init];
    shown = NO;
}

- (void)windowDidLoad
{
    int		i;
    BOOL	result;
    NSPoint	aPoint;

NSBundle *myBundle=[NSBundle mainBundle];
NSDictionary *completionDictionary=[NSDictionary dictionaryWithContentsOfFile:
[myBundle pathForResource:@"completion" ofType:@"plist"]];

[super windowDidLoad];

[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(panelDidMove:)
        name:NSWindowDidMoveNotification object:[self window]];
[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(panelWillClose:)
        name:NSWindowWillCloseNotification object:[self window]];

// result = [[self window] setFrameAutosaveName:LatexPanelNameKey];
aPoint.x = [[NSUserDefaults standardUserDefaults] floatForKey:PanelOriginXKey];
aPoint.y = [[NSUserDefaults standardUserDefaults] floatForKey:PanelOriginYKey];
[[self window] setFrameOrigin: aPoint];
[[self window] setHidesOnDeactivate: YES];
[[self window] setBecomesKeyOnlyIfNeeded: YES];
arrayFunctions1=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"Functions1"]];
arrayEnvironments=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"Environments" ]];
arrayTypeface=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"Typeface" ]];
arrayInternational=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"International" ]];
arrayGreek=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"Greek" ]];
arrayMath=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"Math" ]];
arraySymbols=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"Symbols" ]];

notifcenter=[NSNotificationCenter defaultCenter];
if ([[NSUserDefaults standardUserDefaults] boolForKey:LPanelOutlinesKey]) {

    for (i=0;i<15;i++)
    {
    [[environbuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
    
    for (i=0;i<30;i++)
    {
    [[functionsbuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
    
    for (i=0;i<11;i++)
    {
    [[typefacebuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
    
    for (i=0;i<54;i++)
    {
    [[mathbuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
    
    for (i=0;i<55;i++)
    {
    [[symbolsbuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
    
    for (i=0;i<30;i++)
    {
    [[greekbuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
    for (i=44;i<55;i++)
    {
    [[greekbuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
    
    for (i=0;i<33;i++)
    {
    [[intlbuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
    for (i=44;i<55;i++)
    {
    [[intlbuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
}

// this adjust the look of buttons at startup
}

- (IBAction)putenvironments:(id)sender
{ 
[notifcenter postNotificationName:@"completionpanel" object:[arrayEnvironments objectAtIndex:[[sender selectedCell] tag]]];
}

- (IBAction)putfunctions1:(id)sender
{
[notifcenter postNotificationName:@"completionpanel" object:[arrayFunctions1 objectAtIndex:[[sender selectedCell] tag]]];
}

- (IBAction)putgreek:(id)sender
{
int i=[[sender selectedCell] tag];
if (i>29) i=i-14;
[notifcenter postNotificationName:@"completionpanel" object:[arrayGreek objectAtIndex:i]];
}

- (IBAction)putintl:(id)sender
{
int i=[[sender selectedCell] tag];
if (i>32) i=i-11;
[notifcenter postNotificationName:@"completionpanel" object:[arrayInternational objectAtIndex:i]];
}

- (IBAction)putmath:(id)sender
{
int i=[[sender selectedCell] tag];

[notifcenter postNotificationName:@"completionpanel" object:[arrayMath objectAtIndex:i]];
}

- (IBAction)putsymbols:(id)sender
{
int i=[[sender selectedCell] tag];

[notifcenter postNotificationName:@"completionpanel" object:[arraySymbols objectAtIndex:i]];
}

- (IBAction)puttypeface:(id)sender
{
[notifcenter postNotificationName:@"completionpanel" object:[arrayTypeface objectAtIndex:[[sender selectedCell] tag]]];
}

- (void)documentWindowDidBecomeKey:(NSNotification *)note
{    
    // if latex panel is hidden, show it
   if (shown)
        [[self window] orderFront:self];
}

- (void)pdfWindowDidBecomeKey:(NSNotification *)note
{    
    // if latex panel is visible, hide it
   if (shown)
        [[self window] orderOut:self];
}

- (IBAction)showWindow:(id)sender
{
    shown = YES;
    return [super showWindow:sender];
}

- (void)hideWindow:(id)sender
{
    shown = NO;
    [[self window] close];
}

- (void)panelWillClose:(NSNotification *)notification
{
    shown = NO;
    [[[NSApp windowsMenu] itemWithTitle:NSLocalizedString(@"Close LaTeX Panel", @"Close LaTeX Panel")]
        setTitle:NSLocalizedString(@"LaTeX Panel...", @"LaTeX Panel...")];
}

- (void)panelDidMove:(NSNotification *)notification
{
    NSRect	myFrame;
    float	x, y;
    
    myFrame = [[self window] frame];
    x = myFrame.origin.x; y = myFrame.origin.y;
    [[NSUserDefaults standardUserDefaults] setFloat:x forKey:PanelOriginXKey];
    [[NSUserDefaults standardUserDefaults] setFloat:y forKey:PanelOriginYKey];
    // [[self window] saveFrameUsingName:@"theLatexPanel"];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [arrayFunctions1 release];
    [arrayEnvironments release];
    [arrayTypeface release];
    [arrayGreek release];
    [arrayInternational release];
    [arrayMath release];
    [arraySymbols release];
    [super dealloc];
}


@end
