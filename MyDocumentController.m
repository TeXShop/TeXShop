// ================================================================================
//  MyDocumentController.m
// ================================================================================
//	TeXShop
//
//  Created by Richard Koch on Feb 17, 2003.
//  Copyright (c) 2003 Richard Koch. 
//
//	This source is distributed under the terms of GNU Public License (GPL) 
//	see www.gnu.org for more info
//
//	Parts of this code are taken from Apple's example SimpleToolbar
//
// ================================================================================

#import "MyDocumentController.h"
#import "EncodingSupport.h"


@implementation MyDocumentController : NSDocumentController

- (void)initializeEncoding  // the idea is that this is called after preferences is set up
{
    encoding = [[EncodingSupport sharedInstance] tagForEncodingPreference];
}

- (int) encoding
{
    return encoding;
}

- (IBAction)openDocument:(id)sender{
    [super openDocument: sender];
    encoding = [[EncodingSupport sharedInstance] tagForEncodingPreference]; 
}


- (int)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions
{
    int		result;
    int		theCode;
    
    theCode = [[EncodingSupport sharedInstance] tagForEncodingPreference];
    [openPanel setAccessoryView: encodingView ];
    [encodingView retain];
    [encodingMenu selectItemAtIndex: theCode];
    result = [super runModalOpenPanel: openPanel forTypes: extensions];
    if (result == YES) {
        encoding = [[encodingMenu selectedCell] tag];
        }
    return result;
}

@end
