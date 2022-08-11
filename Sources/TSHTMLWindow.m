/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2022 Richard Koch
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
 */


#import <AppKit/AppKit.h>
#import "TSHTMLWindow.h"
#import "TSDocument.h"
#import "globals.h"


@implementation TSHTMLWindow 


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	id		result;

	result = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];

	self.willClose = NO;
    
    return result;
    
}


- (void)close
{
    TSDocument *theDocument = self.myDocument;
    
	self.willClose = YES;
    if ([theDocument skipTextWindow]) {
        self.myDocument = nil;
        [theDocument close];
        }
    
	[super close];
}

- (void)resignMainWindow
{
     [super resignMainWindow];
}


- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)defaultFrame
{
	NSRect	newFrame;
	
	newFrame = defaultFrame;
	newFrame.origin.x = newFrame.origin.x + 200;
	
	newFrame.size.width = newFrame.size.width - 200;
	return newFrame;
}


- (void) becomeMainWindow
{
    
   self.willClose = NO;
	if([self.myDocument fileURL] != nil ) [self setTitle:[[[self.myDocument fileTitleName] stringByDeletingPathExtension] stringByAppendingString: @".html"]]; // added by Terada
	[super becomeMainWindow];

	[self.myDocument fixMacroMenuForWindowChange];
}

- (void) saveHTMLPosition: sender
{
    [self.myDocument saveHTMLPosition:self];
}

- (void) showHTMLWindow: sender
{
    [self.myDocument showHTMLWindow: sender];
}


- (void) displayLog: sender
{
	[self.myDocument displayLog: sender];
}

- (void) displayConsole: sender
{
	[self.myDocument displayConsole: sender];
}

- (void) abort: sender
{
	[self.myDocument abort: sender];
}

- (void) trashAUXFiles: sender
{
	[self.myDocument trashAUXFiles: sender];
}

- (void) toggleSyntaxColor: (id)sender
{
    [self.myDocument toggleSyntaxColor: sender];
}


- (void) runPageLayout: sender
{
	[self.myDocument runPageLayout: sender];
}

- (void) printDocument: sender
{
	[self.myDocument printDocument: sender];
}

- (void) printSource: sender
{
	[self.myDocument printSource: sender];
}

- (void) doTypeset: sender
{
	[self.myDocument doTypeset: sender];
}

- (void) doAlternateTypeset: sender
{
    [self.myDocument doAlternateTypeset: sender];
}

- (void) flipShowSync: sender
{
	[self.myDocument flipShowSync: sender];
}

- (void) doTex: sender
{
	[self.myDocument doTex: sender];
}

- (void) doLatex: sender
{
	[self.myDocument doLatex: sender];
}

- (void) doBibtex: sender
{
	[self.myDocument doBibtex: sender];
}

- (void) doIndex: sender
{
	[self.myDocument doIndex: sender];
}

- (void) doMetapost: sender
{
	[self.myDocument doMetapost: sender];
}

- (void) doMetaFont: sender
{
	[self.myDocument doMetaFont: sender];
}

- (void) previousPage: sender
{
    ;
}

- (void) nextPage: sender;
{	
    ;
}


- (void) doChooseMethod: sender
{
	[self.myDocument doChooseMethod: sender];
}

- (void) doError: sender
{
	[self.myDocument doError: sender];
}

- (void) setProjectFile: sender
{
	[self.myDocument setProjectFile: sender];
}

////////////////////// key movement ///////////////////////////////////

- (void) firstPage: sender;
{
    ;
}
    

- (void) lastPage: sender
{
    ;
}

- (void) up: sender
{
    ;
}

- (void) down: sender
{
    ;
}

- (void) top: sender
{
    ;
}

- (void) bottom: sender
{
    ;
}

- (void) left: sender
{
    ;
}

- (void) right: sender
{
    ;
}



- (void)doMove: (id)sender
{
    [self.myDocument doMove:sender];
}


////////// end key movement /////////////////////////

- (void) orderOut:sender
{
	self.willClose = YES;
	if ([self.myDocument externalEditor]) {
		if (! [self.myDocument getWillClose]) {
			[self.myDocument setWillClose: YES];
			[self.myDocument close];
		}
	}
	else if (([self.myDocument documentType] != isTeX) && ([self.myDocument documentType] != isOther)) {
		if (! [self.myDocument getWillClose]) {
			[self.myDocument setWillClose: YES];
			[self.myDocument close];
		}		
	}
	else
		[super orderOut: sender];
}

- (void)associatedWindow:(id)sender
{
    if ([self.myDocument externalEditor])
        return;
 	if ([self.myDocument documentType] == isTeX) {
 		if ([self.myDocument getCallingWindow] == nil) {
            [[self.myDocument textWindow] makeKeyAndOrderFront: self];
            }
		else
			[[self.myDocument getCallingWindow] makeKeyAndOrderFront: self];

		}
}

- (void)sendEvent:(NSEvent *)theEvent
{

    
	 if (self.willClose) {
		[super sendEvent: theEvent];
		return;
	}
	
 	[super sendEvent: theEvent];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
  
    
    if ([anItem action] == @selector(displayLatexPanel:))
		return NO;
	if ([anItem action] == @selector(displayMatrixPanel:))
		return NO;

	if ([anItem action] == @selector(doError:) ||
		[anItem action] == @selector(printSource:))
		return ((![self.myDocument externalEditor]) && ([self.myDocument documentType] == isTeX));

	if ([anItem action] == @selector(setProjectFile:))
		return ([self.myDocument documentType] == isTeX);

	if ([self.myDocument documentType] != isTeX) {
		if ([anItem action] == @selector(saveDocument:))
			return ([self.myDocument documentType] == isOther);
		if ([anItem action] == @selector(doTex:) ||
			[anItem action] == @selector(doLatex:) ||
			[anItem action] == @selector(doBibtex:) ||
			[anItem action] == @selector(doIndex:) ||
			[anItem action] == @selector(doMetapost:) ||
			[anItem action] == @selector(doContext:) ||
			[anItem action] == @selector(doMetaFont:) ||
			[anItem action] == @selector(doTypeset:))
			return NO;
		if ([anItem action] == @selector(printDocument:))
			return (([self.myDocument documentType] == isPDF) ||
					([self.myDocument documentType] == isJPG) ||
					([self.myDocument documentType] == isTIFF));
	}

	return [super validateMenuItem: anItem];
}


- (TSDocument *)document
{
	return self.myDocument;
}




- (void)copy: (id)sender
{
/*
 if ([self.myDocument fromKit])
		[[self.myDocument pdfKitView] copy: sender];
	else
		[[self.myDocument pdfView] copy: sender];
 */
}


- (void) doFind: sender
{
  //  [self makeFirstResponder: [self.myDocument pdfKitSearchField]];
}



@end
