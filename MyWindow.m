//
//  MyWindow.m
//  TeXShop
//
//  Originally part of MyDocument. Broken out by dirk on Tue Jan 09 2001.
//

#import "UseMitsu.h"

#import <AppKit/AppKit.h>
#import "MyWindow.h"
#import "MyDocument.h"
#ifdef MITSU_PDF
#import "MyPDFView.h"
#import "Globals.h"
extern NSPanel *pageNumberWindow;
#else
#import "MyView.h"
#endif

@implementation MyWindow

- (void) doTextMagnify: sender
{
    id	thePanel;
    
    thePanel = [myDocument magnificationPanel];
    [NSApp beginSheet: thePanel
            modalForWindow: self
            modalDelegate: self
            didEndSelector: @selector(magnificationDidEnd:returnCode:contextInfo:) 
            contextInfo: nil];
}

- (void)magnificationDidEnd:(NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
    [[myDocument magnificationPanel] orderOut: self];
}

- (void) doTextPage: sender      // for toolbar in text mode
{
        id	thePanel;
    
    thePanel = [myDocument pagenumberPanel];
    [NSApp beginSheet: thePanel
            modalForWindow: self
            modalDelegate: self
            didEndSelector:  @selector(pagenumberDidEnd:returnCode:contextInfo:)
            contextInfo: nil];
}

- (void)pagenumberDidEnd:(NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
    [[myDocument pagenumberPanel] orderOut: self];
}




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

- (void) doTypeset: sender;
{
    [myDocument doTypeset: sender];
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

- (void) doMetaFont: sender;
{
    [myDocument doMetaFont: sender];
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
#ifdef MITSU_PDF
    MyPDFView *theView;
#else
    MyView *theView;
#endif
    
    theView = [myDocument pdfView];
    if (theView != nil)
        [theView rotateClockwise: sender];
}

- (void) rotateCounterclockwise: sender;
{
#ifdef MITSU_PDF
    MyPDFView *theView;
#else
    MyView *theView;
#endif
    
    theView = [myDocument pdfView];
    if (theView != nil)
        [theView rotateCounterclockwise: sender];
}

- (void) up: sender;
{
#ifdef MITSU_PDF
    MyPDFView *theView;
#else
    MyView *theView;
#endif
    
    theView = [myDocument pdfView];
    if (theView != nil)
        [theView up: sender];
}

- (void) down: sender;
{
#ifdef MITSU_PDF
    MyPDFView *theView;
#else
    MyView *theView;
#endif
    
    theView = [myDocument pdfView];
    if (theView != nil)
        [theView down: sender];
}

- (void) top: sender;
{
#ifdef MITSU_PDF
    MyPDFView *theView;
#else
    MyView *theView;
#endif
    
    theView = [myDocument pdfView];
    if (theView != nil)
        [theView top: sender];
}

- (void) bottom: sender;
{
#ifdef MITSU_PDF
    MyPDFView *theView;
#else
    MyView *theView;
#endif
    
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
            
#ifdef MITSU_PDF

            case NSLeftArrowFunctionKey: [self left: self]; return;// mitsu 1.29 (O) changed from previousPage
            
            case NSRightArrowFunctionKey: [self right: self]; return;// mitsu 1.29 (O) changed from nextPage

#else
            
            case NSLeftArrowFunctionKey: [self previousPage: self]; return;
            
            case NSRightArrowFunctionKey: [self nextPage: self]; return;
            
#endif
            
            case NSPageUpFunctionKey: [self top:self]; return;
            
            case NSPageDownFunctionKey: [self bottom:self]; return;
            
            case NSHomeFunctionKey: [self firstPage: self]; return;
            
            case NSEndFunctionKey: [self lastPage: self]; return;
            
             case ' ':
                if (([theEvent modifierFlags] & NSShiftKeyMask) == 0)
                    [self nextPage: self];
                else
                    [self previousPage: self];
                return;


            
            }
       }
       
#ifdef MITSU_PDF

    else if ([theEvent type] == NSFlagsChanged) // mitsu 1.29 (S2)
	{
		[[myDocument pdfView] flagsChanged: theEvent];
		return;
	}
	else if ([theEvent type] == NSLeftMouseDown) // mitsu 1.29 (O) resize PDF view
	{
		// check if mouse was in vertical scroller's knob
		MyPDFView *pdfView = [myDocument pdfView];
		NSScroller *scroller = [[pdfView enclosingScrollView] verticalScroller];
		if (([scroller testPart: [theEvent locationInWindow]] == NSScrollerKnob) && 
			([myDocument imageType] == isTeX || [myDocument imageType] == isPDF) && 
			([pdfView pageStyle] == PDF_MULTI_PAGE_STYLE || 
				[pdfView pageStyle] == PDF_DOUBLE_MULTI_PAGE_STYLE) && 
			([pdfView rotationAmount] == 0 || [pdfView rotationAmount] == 180))
		{
			// create a small window displaying page number
			NSRect aRect = [scroller rectForPart: NSScrollerKnob];
			aRect = [scroller convertRect: aRect toView: nil]; // use rect not point
			aRect.origin = [self convertBaseToScreen: aRect.origin];
			aRect.origin.x -= PAGE_WINDOW_H_OFFSET;
			aRect.origin.y += aRect.size.height/2 + PAGE_WINDOW_V_OFFSET;
			aRect.size.width = PAGE_WINDOW_WIDTH;
			aRect.size.height = PAGE_WINDOW_HEIGHT;
			pageNumberWindow = [[NSPanel alloc] initWithContentRect: aRect 
					styleMask: NSBorderlessWindowMask | NSUtilityWindowMask 
					backing: NSBackingStoreBuffered //NSBackingStoreRetained 
					defer: NO];
                        [pageNumberWindow setHasShadow: PAGE_WINDOW_HAS_SHADOW];
			[pageNumberWindow orderFront: nil];
			[pageNumberWindow setFloatingPanel: YES];
			[[myDocument pdfView] updateCurrentPage]; // darw page number
			
			[super sendEvent: theEvent]; // let the scroller handle the situation

			[pageNumberWindow close];
			pageNumberWindow = nil;
			return;
		}
	}
        
#endif
        
    [super sendEvent: theEvent];
}


/*
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
*/

// Above code rewritten by Max Horn

- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
{
    if ([anItem action] == @selector(displayLatexPanel:))
        return NO;

#ifdef MITSU_PDF
#else
    if ([anItem action] == @selector(rotateClockwise:) || 
    	[anItem action] == @selector(rotateCounterclockwise:))
        return (([myDocument imageType] == isTeX) || ([myDocument imageType] == isPDF));
#endif

    if ([anItem action] == @selector(doError:) || 
    	[anItem action] == @selector(printSource:))
        return ((![myDocument externalEditor]) && ([myDocument imageType] == isTeX));

    if ([anItem action] == @selector(setProjectFile:))
        return ([myDocument imageType] == isTeX);

    if ([myDocument imageType] != isTeX) {
		if ([anItem action] == @selector(saveDocument:))
			return ([myDocument imageType] == isOther);
		if ([anItem action] == @selector(doTex:) ||
			[anItem action] == @selector(doLatex:) ||
			[anItem action] == @selector(doBibtex:) ||
			[anItem action] == @selector(doIndex:) ||
			[anItem action] == @selector(doMetapost:) ||
			[anItem action] == @selector(doContext:) ||
                        [anItem action] == @selector(doMetaFont:) ||
                        [anItem action] == @selector(doTypeset:)
                        )
			return NO;
		if ([anItem action] == @selector(printDocument:))
			return (([myDocument imageType] == isPDF) ||
					([myDocument imageType] == isJPG) ||
					([myDocument imageType] == isTIFF));
	}
        
#ifdef MITSU_PDF

    	// mitsu 1.29 (O)
    if ([anItem action] == @selector(changePageStyle:)) // @selector(changePDFViewSize:)) 
        return (([myDocument imageType] == isTeX) || ([myDocument imageType] == isPDF));

    if ([anItem action] == @selector(copy:) || [anItem action] == @selector(saveSelectionToFile:))
        return ([[myDocument pdfView] hasSelection]);
	// end mitsu 1.29 (O)

#endif
		
    return [super validateMenuItem: anItem];
}


- (MyDocument *)document;
{
    return myDocument;
}

#ifdef MITSU_PDF

// mitsu 1.29 (O)
- (void) left: sender;
{
    MyPDFView *theView; 
    
    theView = [myDocument pdfView];
    if (theView != nil)
        [theView left: sender];
}

- (void) right: sender;
{
    MyPDFView *theView; 
    
    theView = [myDocument pdfView];
    if (theView != nil)
        [theView right: sender];
}

// mitsu 1.29 (O)
- (void)changePageStyle: (id)sender
{
	[[myDocument pdfView] changePageStyle: sender];
}

- (void)changePDFViewSize: (id)sender
{
	[[myDocument pdfView] changePDFViewSize: sender];
}

- (void)copy: (id)sender
{
	[[myDocument pdfView] copy: sender];
}

-(void)saveSelectionToFile: (id)sender
{
	[[myDocument pdfView] saveSelectionToFile: sender];
}
// end mitsu 1.29 (O)
// end mitsu 1.29

#endif

@end
