//
//  Autrecontroller.m
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

- (id)init
{
    id result;
    result = [super init];
    shown = NO;
    return result;
}

- (void)windowDidLoad
{
    int			i;
    NSPoint		aPoint;
    NSString		*completionPath;
    NSDictionary	*completionDictionary;
    // added by G.K. (Georg Klein)
    int			aButtons;
    //

NSBundle *myBundle=[NSBundle mainBundle];

completionPath = [LatexPanelPathKey stringByStandardizingPath];
completionPath = [completionPath stringByAppendingPathComponent:@"completion"];
completionPath = [completionPath stringByAppendingPathExtension:@"plist"];
if ([[NSFileManager defaultManager] fileExistsAtPath: completionPath]) 
    completionDictionary=[NSDictionary dictionaryWithContentsOfFile:completionPath];
else
    completionDictionary=[NSDictionary dictionaryWithContentsOfFile:
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
// [self window] is actually an NSPanel, so it responds to the message below
[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded: YES];

arrayFunctions1=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"Functions1"]];
arrayEnvironments=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"Environments" ]];
arrayTypeface=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"Typeface" ]];
arrayInternational=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"International" ]];
arrayGreek=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"Greek" ]];
arrayMath=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"Math" ]];
arraySymbols=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"Symbols" ]];
// added by G.K.
arrayCustomized=[[NSArray alloc] initWithArray:[completionDictionary objectForKey:@"Customized" ]];
// end add

notifcenter=[NSNotificationCenter defaultCenter];
if ([[NSUserDefaults standardUserDefaults] boolForKey:LPanelOutlinesKey]) {

    for (i=0;i<16;i++)
    {
    [[environbuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
    
    for (i=0;i<30;i++)
    {
    [[functionsbuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
    
    for (i=0;i<15;i++)
    {
    [[typefacebuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
    
    for (i=0;i<55;i++)
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
    
    for (i=0;i<35;i++)
    {
    [[intlbuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
    for (i=44;i<55;i++)
    {
    [[intlbuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
    }
    
    // added by G.K.
    aButtons = [arrayCustomized count]/2;
    for (i=0;i<aButtons;i++) {
        [[custombuttonmatrix cellWithTag:i] setEnabled:YES];   
        [[custombuttonmatrix cellWithTag:i] setBordered:YES];
        [[custombuttonmatrix cellWithTag:i] setTitle:[arrayCustomized objectAtIndex:(i*2)]];
        [[custombuttonmatrix cellWithTag:i] setShowsBorderOnlyWhileMouseInside:YES];
        }
    [custombuttonmatrix setNeedsDisplay:YES];
// end add    
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
if (i>34) i=i-9;
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

// added by G.K.
- (IBAction)putcustomized:(id)sender
{
[notifcenter postNotificationName:@"completionpanel" object:[arrayCustomized objectAtIndex:([[sender selectedCell] tag]*2)+1]];
}
// end add

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
    [super showWindow:sender];
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
    // added by G.K.
    [arrayCustomized release];
    // end add
    [super dealloc];
}


@end
