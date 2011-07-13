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
    NSInteger i, j;
    BOOL skip;
    
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
            if ([[(TSDocument *)obj pdfWindow] isVisible]) 
                [[(TSDocument *)obj pdfWindow]  performClose:self];
            else if ([[(TSDocument *)obj pdfKitWindow]  isVisible]) 
                [[(TSDocument *)obj pdfKitWindow] performClose: self];
            // [(TSDocument *)obj close];
           // NSLog(@"called close");
        }
    }

    [super terminate:sender];
}

@end
