/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2005 Richard Koch
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
 * $Id: TSDocument-RootFile.m 260 2007-08-08 22:51:09Z richard_koch $
 *
 */

#import "UseMitsu.h"

#import "TSDocument.h"
#import "globals.h"
#import "TSEncodingSupport.h"


@implementation TSDocument (RootFile)

- (id) rootDocument
{
	return rootDocument;
}

- (BOOL) checkRootFile: (NSString *)nameString forTask:(int)task
{
	NSArray 			*wlist;
	NSEnumerator 		*en;
	id                      obj;
	NSDocumentController    *dc;
	int                         theEngine;

	// is the document open?
	wlist = [NSApp orderedDocuments];
	en = [wlist objectEnumerator];
	while ((obj = [en nextObject])) {
		// TODO: Consider using [obj isMemberOfClass:[TSDocument class]] here
		if ([[obj windowNibName] isEqualToString:@"TSDocument"]) {
			if ([[obj fileName] isEqualToString:nameString]) {
				if (obj == self)
					return NO;
				rootDocument = obj;
				if (task == RootForConsole){
					[obj displayConsole:nil];
				} else if (task == RootForLogFile){
					[obj displayLog:nil];
				} else if (task == RootForPrinting) {
					[obj printDocument:nil];
				} else if (task == RootForPdfSync) {
					[obj doPreviewSyncWithFilename:[self fileName] andLine:pdfSyncLine andCharacterIndex:pdfCharacterIndex andTextView: textView];
				} else if (task == RootForSwitchWindow) {
					[obj setCallingWindow: textWindow];
					[obj bringPdfWindowFront];
				} else if (task == RootForTexing) {
					// FIXME: The following code block exists twice in this function
					theEngine = useTempEngine ? tempEngine : whichEngine;
					if (whichEngine >= UserEngine) {
						[obj doUser:whichEngine];
					} else {
						switch (theEngine) {
							case TexEngine: [obj doTex1:nil]; break;
							case LatexEngine: [obj doLatex1:nil]; break;
							case ContextEngine: [obj doContext1:nil]; break;
							case MetapostEngine: [obj doMetapost1:nil]; break;
							case BibtexEngine: [obj doBibtex:nil]; break;
							case IndexEngine: [obj doIndex:nil]; break;
							default: NSBeginAlertSheet(NSLocalizedString(@"Typesetting engine cannot be found.", @"Typesetting engine cannot be found."),
													   nil,nil,nil,[textView window],nil,nil,nil,nil,
													   @"Path Name: %@",nameString);
						}
					}
				} else if (task == RootForOpening) {
					/* This section was moved lower down for version 2.40
					 
					// added by Terada (from this line)
					NSRect activeWindowFrame = [[obj textWindow] frame];
					NSRect newFrame;
					NSScreen *screen = [NSScreen mainScreen];
					if(NSMinY(activeWindowFrame) + NSHeight([screen visibleFrame]) - NSHeight([screen frame]) + 20 < 0)
					{
						newFrame = NSMakeRect(NSMinX(activeWindowFrame) + 20, NSHeight([screen frame]), NSWidth(activeWindowFrame), NSHeight(activeWindowFrame));
					}
					else
					{
						newFrame = NSMakeRect(NSMinX(activeWindowFrame) + 20, NSMinY(activeWindowFrame) + 20, NSWidth(activeWindowFrame), NSHeight(activeWindowFrame));
					}
					
					[[obj textWindow] setFrame:newFrame display:YES];
					// added by Terada (until this line)
					*/
				} else if (task == RootForTrashAUX) {
					[obj trashAUX];
				}
				return YES;
			}
		}
	}

	// document not found, open document and typeset
	dc = [NSDocumentController sharedDocumentController];
	obj = [dc openDocumentWithContentsOfFile:nameString display:YES];
	if (obj) {
		if (obj == self)
			return NO;
		if (task == RootForPrinting) {
			[obj printDocument:nil];
		} else if (task == RootForPdfSync) {
			[obj doPreviewSyncWithFilename:[self fileName] andLine:pdfSyncLine andCharacterIndex:pdfCharacterIndex andTextView: textView];
		} else if (task == RootForTexing) {
			// FIXME: The following code block exists twice in this function
			theEngine = useTempEngine ? tempEngine : whichEngine;
			if (whichEngine >= UserEngine) {
				[obj doUser:whichEngine];
			} else {
				switch (theEngine) {
					case TexEngine: [obj doTex1:nil]; break;
					case LatexEngine: [obj doLatex1:nil]; break;
					case ContextEngine: [obj doContext1:nil]; break;
					case MetapostEngine: [obj doMetapost1:nil]; break;
					case BibtexEngine: [obj doBibtex:nil]; break;
					case IndexEngine: [obj doIndex:nil]; break;
					default: NSBeginAlertSheet(NSLocalizedString(@"Typesetting engine cannot be found.", @"Typesetting engine cannot be found."),
											   nil,nil,nil,[textView window],nil,nil,nil,nil,
											   @"Path Name: %@",nameString);
				}
			}
		} else if (task == RootForOpening) {
			// added by Terada (from this line) // This was moved here for version 2.40
			if([SUD integerForKey:DocumentWindowPosModeKey] == DocumentWindowPosSave){
				NSRect activeWindowFrame = [[obj textWindow] frame];
				NSScreen *screen = [NSScreen mainScreen];
				float minX = 20 + ((NSMinX(activeWindowFrame) + NSWidth(activeWindowFrame) + 20 > NSWidth([screen frame])) ? 0 : NSMinX(activeWindowFrame));
				float minY = (NSMinY(activeWindowFrame) + NSHeight([screen visibleFrame]) - NSHeight([screen frame]) + 20 < 0) ? NSHeight([screen frame]) : NSMinY(activeWindowFrame) - 20;
				NSRect newFrame = NSMakeRect(minX, minY, NSWidth(activeWindowFrame), NSHeight(activeWindowFrame));
				[[obj textWindow] setFrame:newFrame display:YES];
			}
			// added by Terada (until this line)
			[[obj textWindow] miniaturize:self];
		} else if (task == RootForTrashAUX) {
			[obj trashAUX];
		}
		return YES;
	} else {
		NSBeginAlertSheet(NSLocalizedString(@"The source LaTeX document cannot be found.", @"The source LaTeX document cannot be found."),
						  nil,nil,nil,nil,nil,nil,nil,nil,
						  @"Path Name: %@",nameString);
	}
	return YES;
}

- (BOOL)checkMasterFile:(NSString *)theSource forTask:(int)task
{
	NSString                *home, *jobname;
	NSRange                 aRange, bRange;
	NSRange                 myRange, theRange, sourcedocRange, newSourceDocRange;
	NSString                *testString, *sourcedocString;
	NSString                *nameString;
	unsigned                length;
	BOOL                    done;
	int                     linesTested, offset;
	unsigned                start, end, irrelevant;

	if (theSource == nil)
		return NO;

	jobname=[[self fileName] stringByDeletingLastPathComponent];

	// load home path and jobname
	home = [[self fileName] stringByDeletingLastPathComponent];
	jobname = [[[self fileName] lastPathComponent] stringByDeletingPathExtension];

	// see if there is a parent document
	length = [theSource length];
	done = NO;
	linesTested = 0;
	myRange.location = 0;
	myRange.length = 1;
	sourcedocString = 0;

	while ((myRange.location < length) && (!done) && (linesTested < 20)) {
		[theSource getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
		myRange.location = end;
		myRange.length = 1;
		linesTested++;

		theRange.location = start; theRange.length = (end - start);
		testString = [theSource substringWithRange: theRange];
		sourcedocRange = [testString rangeOfString:@"%!TEX root ="];
		offset = 12;
		if (sourcedocRange.location == NSNotFound) {
			sourcedocRange = [testString rangeOfString:@"% !TEX root ="];
			offset = 13;
			}
		if (sourcedocRange.location != NSNotFound) {
			newSourceDocRange.location = sourcedocRange.location + offset;
			newSourceDocRange.length = [testString length] - newSourceDocRange.location;
			if (newSourceDocRange.length > 0) {
				done = YES;
				sourcedocString = [[testString substringWithRange: newSourceDocRange]
						stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
			}
		}
	}


	if (!done && [SUD boolForKey:UseOldHeadingCommandsKey]) {

		aRange = [theSource rangeOfString:@"%SourceDoc "];
		if (aRange.location != NSNotFound) {
			bRange = [theSource lineRangeForRange:aRange];
			if (bRange.length > 12 && aRange.location == bRange.location) {
				done = YES;
				sourcedocString = [theSource substringWithRange:NSMakeRange(bRange.location+11,bRange.length-12)];
			}
		}
	}

	if (done) {

		nameString = [self
			decodeFile:sourcedocString
			  homePath:home job:jobname];

		return [self checkRootFile:nameString forTask:task];
	}

	return NO;
}


- (BOOL) checkRootFile_forTask:(int)task
{
	NSString			*projectPath, *nameString;

	projectPath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"texshop"];
	if (![[NSFileManager defaultManager] fileExistsAtPath: projectPath])
		return NO;

	NSString *projectRoot = [NSString stringWithContentsOfFile: projectPath];
	projectRoot = [projectRoot stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([projectRoot length] == 0)
		return NO;

	if ([projectRoot isAbsolutePath]) {
		nameString = [NSString stringWithString:projectRoot];
	} else {
		nameString = [[self fileName] stringByDeletingLastPathComponent];
		nameString = [[nameString stringByAppendingString:@"/"]
		stringByAppendingString: [NSString stringWithContentsOfFile: projectPath]];
		nameString = [nameString stringByStandardizingPath];
	}

	return [self checkRootFile:nameString forTask:task];
}

- (void) checkFileLinksA
{
	NSArray *wlist;
	NSEnumerator *en;
	id obj;
	id theRoot;

	// first save all related, open, dirty files
	theRoot = rootDocument ? rootDocument : self;

	wlist = [NSApp orderedDocuments];
	en = [wlist objectEnumerator];
	while ((obj = [en nextObject])) {

		if (([[obj windowNibName] isEqualToString:@"TSDocument"]) &&
			(obj != self) &&
			(([obj rootDocument] == theRoot) || (obj == rootDocument)) &&
			([obj isDocumentEdited])) {
			[obj saveDocument:self];
		}
	}
}

- (void) checkFileLinks:(NSString *)theSource
{
	NSString *home,*jobname=[[self fileName] stringByDeletingLastPathComponent];
	NSRange aRange,bRange;
	NSString *saveName, *searchString;
	NSMutableArray *slist;
	NSArray *wlist;
	NSEnumerator *en;
	id obj;
	unsigned numFiles,i;
	
	if (![SUD boolForKey:SaveRelatedKey])
		return;

	// load home path and jobname
	home = [[self fileName] stringByDeletingLastPathComponent];
	jobname = [[[self fileName] lastPathComponent] stringByDeletingPathExtension];
	
	// create list of linked files from \input commands
	aRange = NSMakeRange(0, [theSource length]);
	slist = [[NSMutableArray alloc] init];
	searchString = @"\\input";
	searchString = [self filterBackslashes:searchString];

	while (YES) {
		aRange = [theSource rangeOfString:searchString options:NSLiteralSearch range:aRange];
		if (aRange.location == NSNotFound)
			break;
		bRange = [theSource lineRangeForRange:aRange];
		saveName = [self readInputArg:[theSource substringWithRange:bRange]
							  atIndex:aRange.location-bRange.location+6
							 homePath:home job:jobname];
		saveName = [saveName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if(saveName)
			[slist addObject:saveName];
		aRange.location += 6;
		aRange.length = [theSource length] - aRange.location;
	}
	
	numFiles = [slist count];

	if (numFiles==0) {
		[slist release];
		return;
	}

	// compare file list to current MyDocuments
	wlist = [NSApp orderedDocuments];
	en = [wlist objectEnumerator];

	while ((obj = [en nextObject])) {
		if ([[obj windowNibName] isEqualToString:@"TSDocument"]) {
			saveName = [obj fileName];
			for (i = 0; i < numFiles; i++) {
				if ([saveName isEqualToString:[slist objectAtIndex:i]]) {
					if ([obj isDocumentEdited])
						[obj saveDocument:self];
					break;
				}
			}
		}
	}

	// release file list
	[slist release];
}

// added by John A. Nairn
// read argument to \input command and resolve to full path name
// ignore \input commands that have been commented out
- (NSString *) readInputArg:(NSString *)fileLine atIndex:(unsigned)i
		homePath:(NSString *)home job:(NSString *)jobname
{
	unichar firstChar;
	NSRange aRange;

	// error if no command argument data
	if (i >= [fileLine length])
		return nil;

	// skip if commented out
	aRange = [fileLine rangeOfString:@"%" options:NSLiteralSearch];
	if (aRange.location != NSNotFound && aRange.location < i) {
		// exit unless % is escaped with back slash
		if (aRange.location == 0)
			return nil;
		firstChar = [fileLine characterAtIndex:aRange.location-1];
		if (firstChar != BACKSLASH)
			return nil;
	}
	
	// check if next character is { or ' '
	firstChar = [fileLine characterAtIndex:i];

	// argument in {}'s
	if (firstChar == '{') {
		// find ending brace
		aRange = [fileLine rangeOfString:@"}" options:NSLiteralSearch
								   range:NSMakeRange(i, [fileLine length]-i)];
		if (aRange.location==NSNotFound)
			return nil;
		return [self decodeFile:[fileLine substringWithRange:NSMakeRange(i+1, aRange.location-1-i)]
					   homePath:home job:jobname];
	} else if (firstChar==' ') {	// argument after space(s)
									// skip any number of spaces
		while (firstChar==' ') {
			// Koch, Aug 7, 2007, the next line was missing and caused a hang
			i++;
			if ( i>= [fileLine length])
				return nil;
			firstChar = [fileLine characterAtIndex:i];
		}

		// find next space or line end
		aRange=[fileLine rangeOfString:@" " options:NSLiteralSearch
								 range:NSMakeRange(i, [fileLine length]-i)];
		if (aRange.location == NSNotFound)
			aRange = NSMakeRange(i, [fileLine length]-i);
		else
			aRange = NSMakeRange(i,aRange.location-i);

		return [self decodeFile:[fileLine substringWithRange:aRange]
					   homePath:home job:jobname];
	}

	// not an input command
	return nil;
}

// added by John A. Nairn
// get full path name for possible relative file name in relFile
// relative is from home
- (NSString *) decodeFile:(NSString *)relFile homePath:(NSString *)home job:(NSString *)jobname
{
	NSString *saveName, *searchString;
	NSMutableString *saveTemp;
	unichar firstChar;
	NSRange aRange;

	// trim white space first
	relFile = [relFile stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

	// expand to full path
	firstChar = [relFile characterAtIndex:0];
	if (firstChar == '~')
		saveName = [relFile stringByExpandingTildeInPath];
	else if (firstChar == '/')
		saveName = relFile;
	else if (firstChar == '.') {
		while ([relFile hasPrefix:@"../"]) {
			home = [home stringByDeletingLastPathComponent];
			relFile = [relFile substringFromIndex:3];
		}
		saveName = [NSString stringWithFormat:@"%@/%@",home,relFile];
	}
	else
		saveName = [NSString stringWithFormat:@"%@/%@",home,relFile];

	// see if \jobname is there
	searchString = [self filterBackslashes:@"\\jobname"];
	aRange = [saveName rangeOfString:searchString options:NSLiteralSearch];
	if(aRange.location == NSNotFound)
		return saveName;

	// replace \jobname(s)
	saveTemp = [NSMutableString stringWithString:saveName];
	[saveTemp replaceOccurrencesOfString:searchString withString:jobname options:NSLiteralSearch
								   range:NSMakeRange(0,[saveName length])];
	return [NSString stringWithString:saveTemp];
}


@end
