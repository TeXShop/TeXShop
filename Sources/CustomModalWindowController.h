//
//  CustomModalWindowViewController.h
//  CustomModalWindow
//
//  Based on Nick Kuh, 16/01/2015.
//

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import "TSTextEditorWindow.h"
#import "TSDocument.h"

@interface CustomModalWindowController : NSWindowController

{
   TSDocument *myDocument;
}

 @property (nonatomic, strong) IBOutlet NSPopUpButton *theEncodings;

- (void)initializeEncodingMatrix: (TSDocument *)theDocument;
- (IBAction) itemChosen: sender;



@end
