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
 * $Id$
 *
 * Created by lenglin on Sun Aug 26 2001.
 *
 */

#import "TSLaTeXPanelController.h"
#import "globals.h"

@implementation TSLaTeXPanelController

static id _sharedInstance = nil;

+ (id)sharedInstance
{
	if (_sharedInstance == nil)
	{
		_sharedInstance = [[TSLaTeXPanelController alloc] initWithWindowNibName:@"completionpanel1.2"];
	}
	return _sharedInstance;
}

- (id)init
{
	if ((self = [super init])) {
		shown = NO;
	}
	return self;
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
	[arrayCustomized release];

	[super dealloc];
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

	completionPath = [LatexPanelPath stringByStandardizingPath];
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
	if (i>29)
		i=i-14;
	[notifcenter postNotificationName:@"completionpanel" object:[arrayGreek objectAtIndex:i]];
}

- (IBAction)putintl:(id)sender
{
	int i=[[sender selectedCell] tag];
	if (i>34)
		i=i-9;
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

- (void)textWindowDidBecomeKey:(NSNotification *)note
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
	NSMenuItem *myItem = [[NSApp windowsMenu] itemWithTitle:NSLocalizedString(@"Close LaTeX Panel", @"Close LaTeX Panel")];
	[myItem  setTitle:NSLocalizedString(@"LaTeX Panel...", @"LaTeX Panel...")];
	[myItem setTag:0];
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


@end
