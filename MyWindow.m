//
//  MyWindow.m
//  TeXShop
//
//  Originally part of MyDocument. Broken out by dirk on Tue Jan 09 2001.
//

#import <AppKit/AppKit.h>
#import "MyWindow.h"
#import "MyDocument.h"

@implementation MyWindow

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

- (void) previousPage: sender;
{
    [[myDocument pdfView] previousPage: sender];
}

- (void) nextPage: sender;
{
    [[myDocument pdfView] nextPage: sender];
}

- (void) doError: sender;
{
    [myDocument doError: sender];
}

- (void) orderOut:sender;
{
    if ([myDocument imageType] != isTeX) {
        [myDocument close];
        }
    else
        [super orderOut: sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
{
  if ([myDocument imageType] == isTeX)
    return YES;
  else if ([[anItem title] isEqualToString:@"Tex"]) 
        return NO;
  else if ([[anItem title] isEqualToString:@"Latex"]) 
        return NO;
  else if ([[anItem title] isEqualToString:@"Bibtex"]) 
        return NO;
  else if ([[anItem title] isEqualToString:@"MakeIndex"]) 
        return NO;
  else if ([[anItem title] isEqualToString:@"Print..."]) 
        return NO;
  else
    return YES;
}

- (MyDocument *)document;
{
    return myDocument;
}

@end
