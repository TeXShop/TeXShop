//
//  MyWindow.m
//  TeXShop
//
//  Originally part of MyDocument. Broken out by dirk on Tue Jan 09 2001.
//

#import <AppKit/AppKit.h>
#import "MyWindow.h"
#import "MyDocument.h"
#import "MyView.h"

@implementation MyWindow

- (void) runPageLayout: sender;
{
    [myDocument runPageLayout: sender];
}

- (void) printDocument: sender;
{
    [myDocument printDocument: sender];
}

- (void) printSource: sender;
{
    [myDocument printSource: sender];
}

- (void) doTex: sender;
{
    [myDocument doTex: sender];
}

- (void) doLatex: sender;
{
    [myDocument doLatex: sender];
}

- (void) doBibtex: sender;
{
    [myDocument doBibtex: sender];
}

- (void) doIndex: sender;
{
    [myDocument doIndex: sender];
}

- (void) doMetapost: sender;
{
    [myDocument doMetapost: sender];
}

- (void) doContext: sender;
{
    [myDocument doContext: sender];
}

- (void) previousPage: sender;
{
    [[myDocument pdfView] previousPage: sender];
}

- (void) nextPage: sender;
{
    [[myDocument pdfView] nextPage: sender];
}

- (void) firstPage: sender;
{
    [[myDocument pdfView] firstPage: sender];
}

- (void) lastPage: sender;
{
    [[myDocument pdfView] lastPage: sender];
}


- (void) doChooseMethod: sender;
{
    [myDocument doChooseMethod: sender];
}

- (void) doError: sender;
{
    [myDocument doError: sender];
}

- (void) setProjectFile: sender;
{
    [myDocument setProjectFile: sender];
}

- (void) rotateClockwise: sender;
{
    MyView *theView;
    
    theView = [myDocument pdfView];
    if (theView != nil)
        [theView rotateClockwise: sender];
}

- (void) rotateCounterclockwise: sender;
{
    MyView *theView;
    
    theView = [myDocument pdfView];
    if (theView != nil)
        [theView rotateCounterclockwise: sender];
}

- (void) up: sender;
{
    MyView *theView;
    
    theView = [myDocument pdfView];
    if (theView != nil)
        [theView up: sender];
}

- (void) down: sender;
{
    MyView *theView;
    
    theView = [myDocument pdfView];
    if (theView != nil)
        [theView down: sender];
}

- (void) top: sender;
{
    MyView *theView;
    
    theView = [myDocument pdfView];
    if (theView != nil)
        [theView top: sender];
}

- (void) bottom: sender;
{
    MyView *theView;
    
    theView = [myDocument pdfView];
    if (theView != nil)
        [theView bottom: sender];
}



- (void) orderOut:sender;
{
    if ([myDocument externalEditor])
        [myDocument close];
    else if (([myDocument imageType] != isTeX) && ([myDocument imageType] != isOther)) {
        [myDocument close];
        }
    else
        [super orderOut: sender];
}

- (void)sendEvent:(NSEvent *)theEvent
{
    unichar	theChar;
    
    if ([theEvent type] == NSKeyDown) {
    
        if (([theEvent modifierFlags] & NSControlKeyMask) &&
         ([myDocument imageType] == isTeX) &&
         ([[theEvent charactersIgnoringModifiers] isEqualToString:@"1"])) {
         
            [[myDocument textWindow] makeKeyAndOrderFront: self];
            return;
            }
    
        theChar = [[theEvent characters] characterAtIndex:0];
        
        switch (theChar) {
        
            case NSUpArrowFunctionKey: [self up:self]; return;
            
            case NSDownArrowFunctionKey: [self down:self]; return;
            
            case NSLeftArrowFunctionKey: [self previousPage: self]; return;
            
            case NSRightArrowFunctionKey: [self nextPage: self]; return;
            
            case NSPageUpFunctionKey: [self top:self]; return;
            
            case NSPageDownFunctionKey: [self bottom:self]; return;
            
            case NSHomeFunctionKey: [self firstPage: self]; return;
            
            case NSEndFunctionKey: [self lastPage: self]; return;

            
            }
       } 
        
    [super sendEvent: theEvent];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
{
    BOOL  result;
    
    result = [super validateMenuItem: anItem];
    if ([[anItem title] isEqualToString:
                NSLocalizedString(@"Latex Panel...", @"Latex Panel...")])
            return NO;
    if (([[anItem title] isEqualToString:
                NSLocalizedString(@"Rotate Clockwise", @"Rotate Clockwise")]) ||
        ([[anItem title] isEqualToString:
                NSLocalizedString(@"Rotate Counterclockwise", @"Rotate Counterclockwise")])) {
            if (([myDocument imageType] == isTeX) || ([myDocument imageType] == isPDF))
                return YES;
            else
                return NO;
            }
    if (([[anItem title] isEqualToString:
                NSLocalizedString(@"Goto Error", @"Goto Error")]) ||
        ([[anItem title] isEqualToString:
                NSLocalizedString(@"Print Source...", @"Print Source...")])) {
        if ((![myDocument externalEditor]) && ([myDocument imageType] == isTeX))
            return YES;
        else
            return NO;
        }
    if ([[anItem title] isEqualToString:
                NSLocalizedString(@"Set Project Root...", @"Set Project Root...")]) {
        if ([myDocument imageType] == isTeX)
            return YES;
        else
            return NO;
        }
    if ([myDocument imageType] == isTeX)
        return result;
    else if ([[anItem title] isEqualToString:NSLocalizedString(@"Save", @"Save")]) {
        if ([myDocument imageType] == isOther)
            return YES;
        else
            return NO;
        }
    else if([[anItem title] isEqualToString:NSLocalizedString(@"Print Source...", @"Print Source...")]) {
        if ([myDocument imageType] == isOther)
            return YES;
        else
            return NO;
        }
    else if ([[anItem title] isEqualToString:@"TeX"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"Plain TeX"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"LaTeX"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"BibTeX"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"MakeIndex"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"MetaPost"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString:@"ConTeXt"]) {
        return NO;
        }
    else if ([[anItem title] isEqualToString: NSLocalizedString(@"Print...", @"Print...")]) {
        if (([myDocument imageType] == isPDF) || ([myDocument imageType] == isJPG) ||
        ([myDocument imageType] == isTIFF)) 
            return YES;
        else
            return NO;
        }
    else if ([[anItem title] 
            isEqualToString: NSLocalizedString(@"Set Project Root...", @"Set Project Root...")]) {
        return NO;
        }
    else return result;
}

- (MyDocument *)document;
{
    return myDocument;
}

@end
