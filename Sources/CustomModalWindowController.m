//
//  CustomModalWindowViewController.m
//  CustomModalWindow
//
//  Based on Nick Kuh, 16/01/2015.
//

#import <AppKit/AppKit.h>
#import "TSDocument.h"
#import "TSEncodingSupport.h"
#import "CustomModalWindowController.h"


@interface CustomModalWindowController ()

@end

@implementation CustomModalWindowController


- (IBAction)didTapCancelButton:(id)sender {
    NSStringEncoding theCode;
    
    [myDocument initializeTempEncoding];
 //   theCode = [myDocument temporaryEncoding];
 //    NSLog(@"The current temporary encoding is %ld", theCode);
   [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (IBAction)didTapDoneButton:(id)sender {
    
    [myDocument activateTempEncoding];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (IBAction) itemChosen:(id)sender
{
    
    [myDocument chooseTempEncoding:sender];
    
}

// Create the contents of the encoding menu on the fly & select the active encoding
- (void)initializeEncodingMatrix: (TSDocument *)theDocument;
{
    TSTextEditorWindow *myWindow;
    TSDocument      *myDocumentA;
    
    NSStringEncoding currentEncoding;

    myDocument = theDocument;
    
    
//    NSLog(@"Initializing");
    
    myWindow = (TSTextEditorWindow *)self.window.sheetParent;
    myDocumentA = [myWindow document];
    
    
    currentEncoding = [myDocument currentDocumentEncoding];
    
//  NSLog(@"The current encoding is %ld", currentEncoding);
    
    currentEncoding = [[TSEncodingSupport sharedInstance] defaultEncoding];
    [myDocument initializeTempEncoding];
    
//    NSLog(@"The current encoding is %ld", currentEncoding);

    [self.theEncodings removeAllItems];
    [[TSEncodingSupport sharedInstance] addEncodingsToMenu:self.theEncodings.menu withTarget:0 action:0];
    [self.theEncodings selectItemWithTag: currentEncoding];
    
}


@end
