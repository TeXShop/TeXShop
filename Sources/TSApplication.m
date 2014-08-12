//
//  TSApplication.m
//  
//
//  Created by Richard Koch on 7/10/11.
//  Copyright 2011 University of Oregon. All rights reserved.
//

#import "TSApplication.h"
#import "TSDocumentController.h"
#import "TSDocument.h"

@implementation TSApplication

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)terminate:(id)sender;
{
    
/*
    
    NSArray *myDocuments = [[TSDocumentController sharedDocumentController]  documents];
    id obj;
    i = 0;
    while (i < [myDocuments count]) {
        j = i;
        obj = [myDocuments objectAtIndex:j];
        i++;
        skip = [(TSDocument *)obj skipTextWindow];
        // NSLog(@"considered");
        if (skip) {
            // NSLog(@"will close");
// Yusuke Terada patch to avoid crash at close
            id pdfWindow = [(TSDocument *)obj pdfWindow];
            id pdfKitWindow = [(TSDocument *)obj pdfKitWindow];
            
            if (pdfWindow && [pdfWindow respondsToSelector:@selector(isVisible)] && [pdfWindow isVisible] && [pdfWindow respondsToSelector:@selector(performClose:)])[pdfWindow performClose:self];
            else if (pdfKitWindow && [pdfKitWindow respondsToSelector:@selector(isVisible)] && [pdfKitWindow isVisible] && [pdfKitWindow respondsToSelector:@selector(performClose:)])
                [pdfKitWindow performClose:self];
// end of patch
            // [(TSDocument *)obj close];
            // NSLog(@"called close");
        }
    }
 
 */

    [super terminate:sender];
}

- (void)sendEvent:(NSEvent *)anEvent
{
    [super sendEvent:anEvent];
}

@end
