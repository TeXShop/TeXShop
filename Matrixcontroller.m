//
//  Matrixcontroller.m
//
//  Created by Jonas Zimmermann on Fri Nov 28 2003.
//  Copyright (c) 2001 __NorignalSoft__. All rights reserved.
//

#import "Matrixcontroller.h"
#import "globals.h"


@implementation Matrixcontroller


static id _sharedInstance = nil;

+ (id)sharedInstance
{
    if (_sharedInstance == nil)
    {
        _sharedInstance = [[Matrixcontroller alloc] initWithWindowNibName:@"matrixpanel"];
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
    NSPoint		aPoint;
    NSString		*matrixPath;
    NSDictionary	*matrixDictionary;
    // added by G.K. (Georg Klein)
    //int			aButtons;
    //
    
    NSBundle *myBundle=[NSBundle mainBundle];
    
    matrixPath = [MatrixPanelPathKey stringByStandardizingPath];
    matrixPath = [matrixPath stringByAppendingPathComponent:@"matrixpanel"];
    matrixPath = [matrixPath stringByAppendingPathExtension:@"plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath: matrixPath]) 
        matrixDictionary=[NSDictionary dictionaryWithContentsOfFile:matrixPath];
    else
        matrixDictionary=[NSDictionary dictionaryWithContentsOfFile:
            [myBundle pathForResource:@"matrixpanel" ofType:@"plist"]];
    
    [super windowDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(panelDidMove:)
                                                 name:NSWindowDidMoveNotification object:[self window]];
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(panelWillClose:)
                                                 name:NSWindowWillCloseNotification object:[self window]];
    
    // result = [[self window] setFrameAutosaveName:LatexPanelNameKey];
    aPoint.x = [[NSUserDefaults standardUserDefaults] floatForKey:MPanelOriginXKey];
    aPoint.y = [[NSUserDefaults standardUserDefaults] floatForKey:MPanelOriginYKey];
    [[self window] setFrameOrigin: aPoint];
    [[self window] setHidesOnDeactivate: YES];
    // [self window] is actually an NSPanel, so it responds to the message below
    [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded: YES];
    
    arrayMatrix=[[NSArray alloc] initWithArray:[matrixDictionary objectForKey:@"Matrix" ]];
    
    notifcenter=[NSNotificationCenter defaultCenter];
}


- (IBAction)putmatrix:(id)sender
{
    
    int hsize,vsize,i,j,k,
    brstyleop=[[brselop selectedCell] tag],
    brstylecl=[[brselcl selectedCell] tag];
    hsize =(int) [hslider intValue];
    vsize =(int) 9-[vslider intValue];
    if ((brstyleop==4)&&(brstylecl==4)) {
    }else{
        [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:6]];
        if (brstyleop==0) {
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:8]];
        } else if (brstyleop==1) {
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:10]];
        } else if (brstyleop==2) {
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:12]];
        } else if (brstyleop==3) {
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:14]];
        } else if (brstyleop==5) {
            //if ((brstylecl!=5)&&(brstylecl!=4))
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:15]];
            [notifcenter postNotificationName:@"matrixpanel" object:[brtfop stringValue]];
        } else if (brstyleop==4) {
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:15]];
        } else if (brstylecl==6) {
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:16]];
        }
        
    }
    
    [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:0]];
    for (i=0;i<hsize;i++)  [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:1]];
    [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:2]];
    for (j=0;j<vsize;j++) {
        for (i=0;i<hsize;i++) {
            k=(j*8+i);
            [notifcenter postNotificationName:@"matrixpanel" object:[[matrixmatrix cellWithTag:k] stringValue]];
            if (i<hsize-1) [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:3]];
        }
        if (j<vsize-1)[notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:4]];
    }
    [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:5]];
    
    if ((brstyleop==4)&&(brstylecl==4)) {
    }else{
        [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:7]];
        if (brstylecl==0) {
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:9]];
        } else if (brstylecl==1) {
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:11]];
        } else if (brstylecl==2) {
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:13]];
        } else if (brstylecl==3) {
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:14]];
        } else if (brstylecl==5) {
            //if ((brstyleop!=4)&&(brstyleop!=5))
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:15]];
            [notifcenter postNotificationName:@"matrixpanel" object:[brtfcl stringValue]];
        } else if (brstylecl==4) {
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:15]];
        } else if (brstylecl==6) {
            [notifcenter postNotificationName:@"matrixpanel" object:[arrayMatrix objectAtIndex:16]];
        }
    }
    
    
    
}

- (IBAction)setmatrix:(id)sender
{
    
    int i,j;
    int hpos,vpos;
    hpos=[hslider intValue];
    vpos=[vslider intValue];
    
    if (sender==matmod) {
        j=[[sender selectedCell] tag];
        if (j==0) {
            for (i=0; i<64;i++)
            {
                if (((i % 8) <hpos) && (i  < 8*(9-vpos))) [[matrixmatrix cellWithTag:i] setStringValue:@""];
            }
        } else if (j==1) {
            for (i=0; i<64;i++)
            {
                [vslider setIntValue:9-hpos];
                vpos=[vslider intValue];

                if (((i % 8) <hpos) && (i  < 8*(9-vpos)))
                {
                    if (i%9==0) {
                        [[matrixmatrix cellWithTag:i] setStringValue:@"1"];
                    }else{
                        [[matrixmatrix cellWithTag:i] setStringValue:@"0"];
                    }
                }
            }
        } else if (j==2) {
            for (i=0; i<64;i++)
            {
                if (((i % 8) <hpos) && (i  < 8*(9-vpos))) [[matrixmatrix cellWithTag:i] setStringValue:@"0"];
                
            }
        }
        
    }
    
    for (i=0; i<64;i++)
    {
        if (((i % 8) <hpos) && (i  < 8*(9-vpos)))
        {
            [[matrixmatrix cellWithTag:i] setEnabled:YES];
            [[matrixmatrix cellWithTag:i] setEditable:YES];
        } else {
            [[matrixmatrix cellWithTag:i] setEnabled:NO];
            [[matrixmatrix cellWithTag:i] setEditable:NO];
        }
        
        
    };
    [matrixmatrix setNeedsDisplay];
}

- (void)documentWindowDidBecomeKey:(NSNotification *)note
{    
    // if matrix panel is hidden, show it
    if (shown)
        [[self window] orderFront:self];
}

- (void)pdfWindowDidBecomeKey:(NSNotification *)note
{    
    // if matrix panel is visible, hide it
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
    [[[NSApp windowsMenu] itemWithTitle:NSLocalizedString(@"Close Matrix Panel", @"Close Matrix Panel")]
        setTitle:NSLocalizedString(@"Matrix Panel...", @"Matrix Panel...")];
}

- (void)panelDidMove:(NSNotification *)notification
{
    NSRect	myFrame;
    float	x, y;
    
    myFrame = [[self window] frame];
    x = myFrame.origin.x; y = myFrame.origin.y;
    [[NSUserDefaults standardUserDefaults] setFloat:x forKey:MPanelOriginXKey];
    [[NSUserDefaults standardUserDefaults] setFloat:y forKey:MPanelOriginYKey];
    // [[self window] saveFrameUsingName:@"theLatexPanel"];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}


@end
