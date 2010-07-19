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
 * $Id$
 *
 */

#import "UseMitsu.h"

#import "TSDocument.h"

#import "MyPDFView.h"
#import "MyPDFKitView.h"

#import "globals.h"

#import "TSWindowManager.h"
#import "TSEncodingSupport.h"


@implementation TSDocument (JobProcessing)

- (NSDictionary *)environmentForSubTask
{
	NSMutableDictionary *env;


	// get copy of environment and add the preferences paths
	env = [[NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]] retain];


	// Customize 'PATH'
	NSMutableString *path;
	path = [NSMutableString stringWithString: [env objectForKey:@"PATH"]];
	[path appendString:@":"];
	[path appendString:[SUD stringForKey:TetexBinPath]];
	[path appendString:@":"];
	[path appendString:[SUD stringForKey:GSBinPath]];
	[env setObject: path forKey: @"PATH"];


	// Set 'TEXEDIT' env var (see the 'tex' man page for details). We construct a simple shell
	// command, which first (re)opens the document, and then uses osascript to run an AppleScript
	// which selects the right line. The AppleScript looks like this:
	//   tell application "TeXShop"
	//       goto document 1 line %d
	//       activate
	//   end tell
	NSMutableString *script = [NSMutableString string];

	[script appendFormat:@"open -a '%@' '%%s' &&", [[NSBundle mainBundle] bundlePath]];
	[script appendString:@" osascript"];
	[script appendString:@" -e 'tell application \"TeXShop\"'"];
	[script appendString:@" -e     'goto document 1 line %d'"];
	[script appendString:@" -e     'activate'"];
	[script appendString:@" -e 'end tell'"];

	[env setObject: script forKey:@"TEXEDIT"];
	
	return env;
}


- (void)killRunningTasks
{
	NSDate	*myDate;

	/* The lines of code below kill previously running tasks. This is
		necessary because otherwise the source file will be open when the
		system tries to save a new version. If the source file is open,
		NSDocument makes a backup in /tmp which is never removed. */

	if (texTask != nil) {
		if (theScript == kTypesetViaGhostScript) {
			kill( -[texTask processIdentifier], SIGTERM);
		} else
			[texTask terminate];
		myDate = [NSDate date];
		while (([texTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5))
			;
		[texTask release];
		texTask = nil;
	}

	if (bibTask != nil) {
		[bibTask terminate];
		myDate = [NSDate date];
		while (([bibTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5))
			;
		[bibTask release];
		bibTask = nil;
	}

	if (indexTask != nil) {
		[indexTask terminate];
		myDate = [NSDate date];
		while (([indexTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5))
			;
		[indexTask release];
		indexTask = nil;
	}

	if (metaFontTask != nil) {
		[metaFontTask terminate];
		myDate = [NSDate date];
		while (([metaFontTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5))
			;
		[metaFontTask release];
		metaFontTask = nil;
	}
}


- (void) doJobForScript:(int)type withError:(BOOL)error runContinuously:(BOOL)continuous
{
	if (! fileIsTex)
		return;

	useTempEngine = YES;
	tempEngine = type;

	typesetContinuously = continuous;
	
	[self killRunningTasks];

	errorNumber = 0;
	whichError = 0;
	makeError = error;

	if (!_externalEditor)
		[self checkFileLinksA];

	if (_externalEditor || (! [self isDocumentEdited])) {
		[self saveFinished: self didSave:YES contextInfo:nil];
	} else {
		[self saveDocumentWithDelegate: self didSaveSelector: @selector(saveFinished:didSave:contextInfo:) contextInfo: nil];
	}
}


- (void) doJob:(int)type withError:(BOOL)error runContinuously:(BOOL)continuous
{
	SEL		saveFinished;

	useTempEngine = NO;

	if (! fileIsTex)
		return;

	typesetContinuously = continuous;

	[self killRunningTasks];

	errorNumber = 0;
	whichError = 0;
	makeError = error;

	//  whichEngine = type;

	// added by mitsu --(J+) check mark in "Typeset" menu
	[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
	whichEngine = type;
	[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
	[self fixMacroMenu];
	// end addition

	if (!_externalEditor)
		[self checkFileLinksA];


	if (_externalEditor || (! [self isDocumentEdited])) {
		[self saveFinished: self didSave:YES contextInfo:nil];
	} else {
		saveFinished = @selector(saveFinished:didSave:contextInfo:);
		[self saveDocumentWithDelegate: self didSaveSelector: saveFinished contextInfo: nil];
	}
}


- (NSString *) separate: (NSString *)myEngine into:(NSMutableArray *)args
{
	NSArray		*myList;
	NSString		*myString, *middleString = 0;
	int			size, i, pos;
	BOOL		programFound, inMiddle;
	NSString		*theEngine = 0;
	NSRange		aRange;

	if (myEngine != nil) {
		myList = [myEngine componentsSeparatedByString:@" "];
		programFound = NO;
		inMiddle = NO;
		size = [myList count];
		i = 0;
		while (i < size) {
			myString = [myList objectAtIndex:i];
			if ((myString != nil) && ([myString length] > 0)) {
				if (! programFound) {
					theEngine = myString;
					programFound = YES;
				}
				else if (inMiddle) {
					middleString = [middleString stringByAppendingString:@" "];
					middleString = [middleString stringByAppendingString:myString];
					pos = [myString length] - 1;
					if ([myString characterAtIndex:pos] == '"') {
						aRange.location = 1;
						aRange.length = [middleString length] - 2;
						middleString = [middleString substringWithRange: aRange];
						[args addObject: middleString];
						inMiddle = NO;
					}
				}
				else if ([myString characterAtIndex:0] == '"') {
					pos = [myString length] - 1;
					if ([myString characterAtIndex:pos] == '"') {
						aRange.location = 1;
						aRange.length = [myString length] - 2;
						myString = [myString substringWithRange: aRange];
						[args addObject: myString];
					}
					else {
						middleString = [NSString stringWithString: myString];
						inMiddle = YES;
					}
				} else {
					[args addObject: myString];
				}
			}
			i = i + 1;
		}
		if (! programFound)
			theEngine = nil;
	}

	return (theEngine);
}

- (void) testGSCommandKey;
{
    NSString	    *gsTeXCommand, *path;
    NSRange			theRange;
    NSString	    *binaryLocation;
    NSFileManager   *fileManager;
    NSString	    *newGSTeXCommand;
    BOOL			changed;
	int				locationOfRest;
    
    changed = NO;
    gsTeXCommand = [SUD stringForKey:TexGSCommandKey];
    theRange = [gsTeXCommand rangeOfString: @"altpdftex"];
    if (theRange.location != NSNotFound) { // && (theRange.location == 0)) {
    locationOfRest = theRange.location + 9;
	binaryLocation = [SUD stringForKey:TetexBinPath];
	path = [binaryLocation stringByAppendingString:@"/simpdftex"];
	fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:path]) {
		newGSTeXCommand = [NSString stringWithString: @"simpdftex tex"];
		if ([gsTeXCommand length] > locationOfRest)
		    newGSTeXCommand = [newGSTeXCommand stringByAppendingString: [gsTeXCommand substringFromIndex: locationOfRest]];
		[SUD setObject:newGSTeXCommand forKey:TexGSCommandKey];
		changed = YES;
		}
	}
	
    gsTeXCommand = [SUD stringForKey:LatexGSCommandKey];
    theRange = [gsTeXCommand rangeOfString: @"altpdflatex"];
    if (theRange.location != NSNotFound) { // && (theRange.location == 0)) {
    locationOfRest = theRange.location + 11;
	binaryLocation = [SUD stringForKey:TetexBinPath];
	path = [binaryLocation stringByAppendingString:@"/simpdftex"];
	fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:path]) {
		newGSTeXCommand = [NSString stringWithString: @"simpdftex latex"];
		if ([gsTeXCommand length] > locationOfRest)
		    newGSTeXCommand = [newGSTeXCommand stringByAppendingString: [gsTeXCommand substringFromIndex: locationOfRest]];
		[SUD setObject:newGSTeXCommand forKey:LatexGSCommandKey];
		changed = YES;
		}
	}
	
    if (changed)
	[SUD synchronize];
    
}

- (void) convertDocument
{
	NSFileManager	*fileManager;
	NSString		*myFileName;
	NSMutableArray	*args;
	NSDictionary	*myAttributes;
	NSString		*imagePath;
	NSString		*sourcePath;
	NSString		*directoryPath;
	NSString		*enginePath = 0;
	NSString		*gsPath;
	NSString		*tetexBinPath;
	NSString		*epstopdfPath;
	BOOL			writeable, result;
	NSString		*argumentString;
	NSString           *tempDestinationString;

	myFileName = [self fileName];
	if ([myFileName length] > 0) {

		fileManager = [NSFileManager defaultManager];
		directoryPath = [myFileName stringByDeletingLastPathComponent];
		writeable = [fileManager isWritableFileAtPath: directoryPath];
		if (! writeable) {
			// put converted file in folder named TempOutputKey; create that folder now
			if (!([fileManager fileExistsAtPath: TempOutputKey]))
			{
				NSString		*reason = 0;

				// create the necessary directories
				NS_DURING
					result = [fileManager createDirectoryAtPath:TempOutputKey attributes:nil];
				NS_HANDLER
					result = NO;
					reason = [localException reason];
				NS_ENDHANDLER
				if (!result) {
					NSRunAlertPanel(@"Error", reason, @"Couldn't Create Temp Folder", nil, nil);
					return;
				}
			}
			if (! [[myFileName pathExtension] isEqualToString:@"dvi"]) {
				tempDestinationString = [[TempOutputKey stringByAppendingString:@"/"]
								stringByAppendingString: [myFileName lastPathComponent]];
				if ([fileManager fileExistsAtPath: tempDestinationString])
					[fileManager removeFileAtPath:tempDestinationString handler: nil];
				[fileManager copyPath:myFileName toPath:tempDestinationString handler:nil];
			}
		}

		imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];

		if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) {
			myAttributes = [[NSFileManager defaultManager] fileAttributesAtPath: imagePath traverseLink:NO];
			startDate = [[myAttributes objectForKey:NSFileModificationDate] retain];
		}
		else
			startDate = nil;

		args = [NSMutableArray array];
		sourcePath = myFileName;

		texTask = [[NSTask alloc] init];
		if ((! writeable) && (! [[myFileName pathExtension] isEqualToString:@"dvi"]))
			[texTask setCurrentDirectoryPath: TempOutputKey];
		else
			[texTask setCurrentDirectoryPath: [sourcePath stringByDeletingLastPathComponent]];
		[texTask setEnvironment: [self environmentForSubTask]];

		if ([[myFileName pathExtension] isEqualToString:@"dvi"]) {
			[self testGSCommandKey];
			enginePath = [[SUD stringForKey:LatexGSCommandKey] stringByExpandingTildeInPath];

			if (([SUD integerForKey:DistillerCommandKey] == 1) && (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2))
				enginePath = [enginePath stringByAppendingString: @" --distiller /usr/bin/pstopdf"];
			if (! writeable) {
				argumentString = [[NSString stringWithString:@" --outdir "] stringByAppendingString: TempOutputKey];
				enginePath = [enginePath stringByAppendingString: argumentString];
			}
			enginePath = [self separate:enginePath into: args];
			if ([SUD boolForKey:SavePSEnabledKey])
				[args addObject: [NSString stringWithString:@"--keep-psfile"]];
		} else if ([[myFileName pathExtension] isEqualToString:@"ps"]) {
			enginePath = [[NSBundle mainBundle] pathForResource:@"ps2pdfwrap" ofType:nil];
			if (([SUD integerForKey:DistillerCommandKey] == 1) && (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2))
				[args addObject: [NSString stringWithString:@"Panther"]];
			else
				[args addObject: [NSString stringWithString:@"Ghostscript"]];
			gsPath = [[SUD stringForKey:GSBinPath] stringByExpandingTildeInPath];
			[args addObject: gsPath];
		} else if  ([[myFileName pathExtension] isEqualToString:@"eps"]) {
			enginePath = [[NSBundle mainBundle] pathForResource:@"epstopdfwrap" ofType:nil];
			if (([SUD integerForKey:DistillerCommandKey] == 1) && (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2))
				[args addObject: [NSString stringWithString:@"Panther"]];
			else
				[args addObject: [NSString stringWithString:@"Ghostscript"]];
			gsPath = [[SUD stringForKey:GSBinPath] stringByExpandingTildeInPath];
			[args addObject: gsPath];
			tetexBinPath = [[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath] stringByAppendingString:@"/"];
			epstopdfPath = [tetexBinPath stringByAppendingString:@"epstopdf"];
			[args addObject: epstopdfPath];
			// [args addObject: [[NSBundle mainBundle] pathForResource:@"epstopdf" ofType:nil]];
		}

		if ((! writeable) && ([[myFileName pathExtension] isEqualToString:@"dvi"])) {
			/*
			 NSString *fixedPathString = [NSString stringWithString:@""];
			 NSArray *myArray = [[myFileName stringByStandardizingPath] componentsSeparatedByString:@"/"];
			 NSEnumerator *myEnumerator = [myArray objectEnumerator];
			 id anObject;
			 int i = 0;
			 int j = [myArray count];

			 while (anObject = [myEnumerator nextObject]) {
				 i++;
				 if ((i > 1) && (i < j))
					 fixedPathString =[[[fixedPathString stringByAppendingString: @"/'"] stringByAppendingString:anObject]
										stringByAppendingString:@"'"];
				 if (i == j)
					 fixedPathString = [[fixedPathString stringByAppendingString: @"/"] stringByAppendingString:anObject];
			 }
			 [args addObject: fixedPathString];
			 */
			[args addObject: [myFileName  stringByStandardizingPath]]; // this seems to be required when the directory isn't writable
		} else
			[args addObject: [sourcePath lastPathComponent]]; //this allows spaces in folder names

		if (enginePath != nil) {
			if ([enginePath characterAtIndex:0] != '/') {
				tetexBinPath = [[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath] stringByAppendingString:@"/"];
				enginePath = [tetexBinPath stringByAppendingString:enginePath];
			}
		}
		inputPipe = [[NSPipe pipe] retain];
		[texTask setStandardInput: inputPipe];
		if ((enginePath != nil) && ([[NSFileManager defaultManager] fileExistsAtPath: enginePath])) {
			[texTask setLaunchPath:enginePath];
			[texTask setArguments:args];
			[texTask launch];
		} else {
			[inputPipe release];
			[texTask release];
			texTask = nil;
		}
	}
}

// TODO/FIXME: The following method is badly named. What it really does: perform (La)TeX
// taks/job processing (or any other engine).
// The only reason for its current name seems to be that before we typeset a document,
// we always first save it. And at the end of that save process, we perform the
// typesetting.
- (void) saveFinished: (NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo
{
	NSArray			*myList;
	NSString		*theSource, *theKey, *myEngine, *testString, *programString;
	NSRange			aRange, myRange, theRange, programRange, newProgramRange;
	unsigned int	mystart, myend;
	unsigned int    start, end, irrelevant;
	int             whichEngineLocal;
	int             i, j;
	BOOL            done;
	unsigned        length;
	int             linesTested;
	NSData          *myData;


	whichEngineLocal = (useTempEngine ? tempEngine : whichEngine);

	if (whichEngineLocal == LatexEngine)
		withLatex = YES;
	else if (whichEngineLocal == TexEngine)
		withLatex = NO;
	theScript = whichScript;

	if (!_externalEditor)
		theSource = [[self textView] string];
	else {
		myData = [NSData dataWithContentsOfFile:[self fileName]];
		theSource = [[[NSString alloc] initWithData:myData encoding:NSMacOSRomanStringEncoding] autorelease];
	}

	if ([self checkMasterFile:theSource forTask:RootForTexing]) {
		useTempEngine = NO;
		return;
	}
	if ([self checkRootFile_forTask:RootForTexing]) {
		useTempEngine = NO;
		return;
	}

	if (!_externalEditor)
		[self checkFileLinks:theSource];

	// New Stuff
	length = [theSource length];
	done = NO;
	linesTested = 0;
	myRange.location = 0;
	myRange.length = 1;
	
	
if ((whichEngineLocal != 3) && (whichEngineLocal != 4)) { //don't use TS-program for BibTeX and MakeIndex
	
	while ((myRange.location < length) && (!done) && (linesTested < 20)) {
		[theSource getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
		myRange.location = end;
		myRange.length = 1;
		linesTested++;

		theRange.location = start; theRange.length = (end - start);
		testString = [theSource substringWithRange: theRange];

		programRange = [testString rangeOfString:@"%!TEX TS-program ="];
		if (programRange.location != NSNotFound) {
			newProgramRange.location = programRange.location + 18;
			newProgramRange.length = [testString length] - newProgramRange.location;
			if (newProgramRange.length > 0) {
				programString = [[testString substringWithRange: newProgramRange]
						stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
				programString = [programString lowercaseString];
				if ([programString isEqualToString:@"pdftex"]) {
					withLatex = NO;
					theScript = kTypesetViaPDFTeX;
					done = YES;
				} else if ([programString isEqualToString:@"pdflatex"]) {
					withLatex = YES;
					theScript = kTypesetViaPDFTeX;
					done = YES;
				} else if ([programString isEqualToString:@"tex"]) {
					withLatex = NO;
					theScript = kTypesetViaGhostScript;
					done = YES;
				} else if ([programString isEqualToString:@"latex"]) {
					withLatex = YES;
					theScript = kTypesetViaGhostScript;
					done = YES;
				} else if ([programString isEqualToString:@"personaltex"]) {
					withLatex = NO;
					theScript = kTypesetViaPersonalScript;
					done = YES;
				} else if ([programString isEqualToString:@"personallatex"]) {
					withLatex = YES;
					theScript = kTypesetViaPersonalScript;
					done = YES;
				} else {
					i = UserEngine;
					j = [programButton numberOfItems];
					while ((i <= j) && (! done)) {
						i++;
						if ([[[[programButton itemAtIndex: (i - 2)] title] lowercaseString] isEqualToString:programString]) {
							done = YES;
							useTempEngine = YES;
							tempEngine = i - 1;
						}
					}
				}
			}
		}
	}

	// Old Stuff
	if ((! done) && ([SUD boolForKey:UseOldHeadingCommandsKey])) {
		myRange.length = 1;
		myRange.location = 0;
		[theSource getLineStart:&mystart end: &myend contentsEnd: nil forRange:myRange];
		if (myend > (mystart + 2)) {
			myRange.location = 0;
			myRange.length = myend - mystart - 1;
			theKey = [theSource substringWithRange:myRange];
			myList = [theKey componentsSeparatedByString:@" "];
			if ((theKey) && ([myList count] > 0))
				theKey = [myList objectAtIndex:0];
		}
		else
			theKey = nil;

		if ((theKey) && ([theKey isEqualToString:@"%&pdftex"])) {
			withLatex = NO;
			theScript = kTypesetViaPDFTeX;
		} else if ((theKey) && ([theKey isEqualToString:@"%&pdflatex"])) {
			withLatex = YES;
			theScript = kTypesetViaPDFTeX;
		} else if ((theKey) && ([theKey isEqualToString:@"%&tex"])) {
			withLatex = NO;
			theScript = kTypesetViaGhostScript;
		} else if ((theKey) && ([theKey isEqualToString:@"%&latex"])) {
			withLatex = YES;
			theScript = kTypesetViaGhostScript;
		} else if ((theKey) && ([theKey isEqualToString:@"%&personaltex"])) {
			withLatex = NO;
			theScript = kTypesetViaPersonalScript;
		} else if ((theKey) && ([theKey isEqualToString:@"%&personallatex"])) {
			withLatex = YES;
			theScript = kTypesetViaPersonalScript;
		} else if (theKey) {
			length = [theKey length];
			theRange.location = 0;
			theRange.length = 10;
			if ((length > 10) && ([[theKey substringWithRange:theRange] isEqualToString:@"%&program="])) {
				theRange.location = 10;
				theRange.length = length - 10;
				NSString *programName = [theKey substringWithRange: theRange];
				NSString *lowerprogramName = [programName lowercaseString];

				if ([lowerprogramName isEqualToString:@"pdftex"]) {
					withLatex = NO;
					theScript = kTypesetViaPDFTeX;
				} else if ([lowerprogramName isEqualToString:@"pdflatex"]) {
					withLatex = YES;
					theScript = kTypesetViaPDFTeX;
				} else if ([lowerprogramName isEqualToString:@"tex"]) {
					withLatex = NO;
					theScript = kTypesetViaGhostScript;
				} else if ([lowerprogramName isEqualToString:@"latex"]) {
					withLatex = YES;
					theScript = kTypesetViaGhostScript;
				} else if ([lowerprogramName isEqualToString:@"personaltex"]) {
					withLatex = NO;
					theScript = kTypesetViaPersonalScript;
				} else if ([lowerprogramName isEqualToString:@"personallatex"]) {
					withLatex = YES;
					theScript = kTypesetViaPersonalScript;
				} else {
					i = UserEngine;
					j = [programButton numberOfItems];
					done = NO;
					while ((i <= j) && (! done)) {
						i++;
						if ([[[[programButton itemAtIndex: (i - 2)] title] lowercaseString] isEqualToString:[programName lowercaseString]]) {
							done = YES;
							useTempEngine = YES;
							tempEngine = i - 1;
						}
					}
				}
			}
		}
	}
	
	}

	// End Old Stuff

	if ((! warningGiven) && ((whichEngineLocal == TexEngine) || (whichEngineLocal == LatexEngine)) && (theScript == kTypesetViaPDFTeX) && ([SUD boolForKey:WarnForShellEscapeKey])) {
		if (withLatex)
			myEngine = [[SUD stringForKey:LatexCommandKey] stringByExpandingTildeInPath]; // 1.35 (D)
		else
			myEngine = [[SUD stringForKey:TexCommandKey] stringByExpandingTildeInPath]; // 1.35 (D)
		
		// search for --shell-escape
		aRange = [myEngine rangeOfString:@"--shell-escape"];
		if (aRange.location == NSNotFound)
			warningGiven = YES;
		else {
			NSBeginCriticalAlertSheet(nil, nil, NSLocalizedString(@"Omit Shell Escape", @"Omit Shell Escape"), NSLocalizedString(@"Cancel", @"Cancel"),
									  textWindow, self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, nil,
									  NSLocalizedString(@"Warning: Using Shell Escape", @"Warning: Using Shell Escape"));
			useTempEngine = NO;
			return;
		}
	}

	[self completeSaveFinished];
}


- (BOOL) startTask: (NSTask*) task running: (NSString*) leafname withArgs: (NSMutableArray*) args inDirectoryContaining: (NSString*) sourcePath withEngine: (int)theEngine
{
	BOOL    isFile;
	BOOL    isExecutable;
	
	// Ensure we have an absolute filename for the executable, prepending  the teTeX bin path if need be.
	NSString* filename = leafname;
	if (filename != nil && [filename length] > 0 && ([filename characterAtIndex: 0] != '/') && ([filename characterAtIndex: 0] != '~')) {
		NSString* tetexBinPath = [[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath] stringByAppendingString:@"/"];
		filename = [tetexBinPath stringByAppendingString: leafname];
	}
	
	// If the executable doesn't exist, we can't launch it.
	filename = [filename stringByExpandingTildeInPath];
	
	if (theEngine >= UserEngine) {
		isFile = [[NSFileManager defaultManager] fileExistsAtPath: filename];
		if (! isFile) {
			NSBeginAlertSheet(NSLocalizedString(@"Can't find required tool.", @"Can't find required tool."),
							  nil, nil, nil,[textView window], nil, nil, nil, nil,
							  NSLocalizedString(@"%@ does not exist.", @"%@ does not exist."), filename);
			return FALSE;
		} else
			isExecutable = [[NSFileManager defaultManager] isExecutableFileAtPath: filename];
		if (! isExecutable) {
			NSBeginAlertSheet(NSLocalizedString(@"Can't find required tool.", @"Can't find required tool."),
							  nil,nil,nil,[textView window],nil,nil,nil,nil,
							  NSLocalizedString(@"%@ does not have the executable bit set.", @"%@ does not have the executable bit set."), filename);
			return FALSE;
		}
	}
	else
		isExecutable = [[NSFileManager defaultManager] isExecutableFileAtPath: filename];
	if (filename == nil || [filename length] == 0 || isExecutable == FALSE) {
		NSBeginAlertSheet(NSLocalizedString(@"Can't find required tool.", @"Can't find required tool."),
						  nil, nil, nil, [textView window], nil, nil, nil, nil,
						  NSLocalizedString(@"%@ does not exist. Perhaps TeXLive was not installed or was removed during a system upgrade. If so, go to the TeXShop web site and follow the instructions to (re)install TeXLive. Another possibility is that a tool path is incorrectly configured in TeXShop preferences. This can happen if you are using the fink teTeX distribution.",
											@"%@ does not exist. Perhaps TeXLive was not installed or was removed during a system upgrade. If so, go to the TeXShop web site and follow the instructions to (re)install TeXLive. Another possibility is that a tool path is incorrectly configured in TeXShop preferences. This can happen if you are using the fink teTeX distribution."),
						  filename);
		return FALSE;
	}
	
	// We know the executable is okay, so give it a go...
	[task setLaunchPath: filename];
	[task setArguments: args];
	[task setCurrentDirectoryPath: [sourcePath stringByDeletingLastPathComponent]];
	[task setEnvironment: [self environmentForSubTask]];
	[task setStandardOutput: outputPipe];
	[task setStandardError: outputPipe];
	[task setStandardInput: inputPipe];
	[task launch];
	return TRUE;
}


- (void) completeSaveFinished
{
	NSString		*myFileName;
	NSMutableArray	*args;
	NSDictionary	*myAttributes;
	NSString		*imagePath;
	NSString		*sourcePath;
	NSString            *gsPath;
	NSRange		aRange;
	unsigned		here;
	BOOL                continuous;
	BOOL                fixPath;
	int                 whichEngineLocal;

	whichEngineLocal = useTempEngine ? tempEngine : whichEngine;

	fixPath = YES;
	continuous = typesetContinuously;
	typesetContinuously = NO;

	myFileName = [self fileName];
	if ([myFileName length] > 0) {
		
		if (startDate != nil) {
			[startDate release];
			startDate = nil;
		}
		
		imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) {
			myAttributes = [[NSFileManager defaultManager] fileAttributesAtPath: imagePath traverseLink:NO];
			startDate = [[myAttributes objectForKey:NSFileModificationDate] retain];
		} else
			startDate = nil;
		
		sourcePath = myFileName;
		
		
		
		args = [NSMutableArray array];
		
		outputPipe = [[NSPipe pipe] retain];
		readHandle = [outputPipe fileHandleForReading];
		[readHandle readInBackgroundAndNotify];
		inputPipe = [[NSPipe pipe] retain];
		writeHandle = [inputPipe fileHandleForWriting];
		
		[outputText setSelectable: YES];
		[outputText selectAll:self];
		[outputText replaceCharactersInRange: [outputText selectedRange] withString:@""];
		[texCommand setStringValue:@""];
		[outputText setSelectable: NO];
		typesetStart = NO;
		// The following command produces an unwanted tex input event for reasons
		//     I do not understand; the event will be discarded because typesetStart = NO
		//     and it is received before tex output to the console occurs.
		//     RMK; 7/3/2001.
		[outputWindow makeFirstResponder: texCommand];
		
		
		// [outputWindow setTitle: [[[[self fileName] lastPathComponent] stringByDeletingPathExtension]
		//         stringByAppendingString:@" console"]];
		[outputWindow setTitle: [[[imagePath lastPathComponent] stringByDeletingPathExtension]
			stringByAppendingString:@" console"]];
		if ([SUD boolForKey:ConsoleBehaviorKey]) {
			if (![outputWindow isVisible])
				[outputWindow orderBack: self];
			[outputWindow makeKeyWindow];
		} else
			[outputWindow makeKeyAndOrderFront: self];
		
		
		
		//   if (whichEngine < 5)
		if ((whichEngineLocal == TexEngine) || (whichEngineLocal == LatexEngine) || (whichEngineLocal == MetapostEngine) || (whichEngineLocal == ContextEngine)) {
			NSString* enginePath = 0;
			NSString* myEngine = 0;
/*
			if ((theScript == kTypesetViaGhostScript) && ([SUD boolForKey:SavePSEnabledKey])
				//        && (whichEngine != 2)   && (whichEngine != 4))
				&& (whichEngineLocal != MetapostEngine) && (whichEngineLocal != ContextEngine))
					[args addObject: [NSString stringWithString:@"--keep-psfile"]];
*/			
			if (texTask != nil) {
				[texTask terminate];
				[texTask release];
				texTask = nil;
			}
			texTask = [[NSTask alloc] init];
			
			if (whichEngineLocal == ContextEngine) {
				if (theScript == kTypesetViaPDFTeX) {
					enginePath = [[NSBundle mainBundle] pathForResource:@"contextwrap" ofType:nil];
					[args addObject: [[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath] stringByAppendingString:@"/"]];
					if (continuous)
						[args addObject:@"YES"];
					else
						[args addObject:@"NO"];
				} else {
					enginePath = [[NSBundle mainBundle] pathForResource:@"contextdviwrap" ofType:nil];
					if (continuous)
						[args addObject:@"YES"];
					else
						[args addObject:@"NO"];
					gsPath = [[SUD stringForKey:GSBinPath] stringByExpandingTildeInPath]; // 1.35 (D)
					[args addObject: gsPath];
					if (([SUD integerForKey:DistillerCommandKey] == 1) && (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2))
						[args addObject: @"Panther"];
					else
						[args addObject: @"Ghostscript"];
					[args addObject: [[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath] stringByAppendingString:@"/"]];
					if ((theScript == kTypesetViaGhostScript) && ([SUD boolForKey:SavePSEnabledKey]))
						[args addObject: @"yes"];
					else
						[args addObject: @"no"];
					// if ([SUD boolForKey:SavePSEnabledKey])
					//     [args addObject: [NSString stringWithString:@"--keep-psfile"]];
				}
			} else if (whichEngineLocal == MetapostEngine) {
				NSString* mpEngineString;
				switch ([SUD integerForKey:MetaPostCommandKey]) {
					case 0: mpEngineString = @"mptopdfwrap"; break;
					case 1: mpEngineString = @"metapostwrap"; break;
					default: mpEngineString = @"mptopdfwrap"; break;
				}
				enginePath = [[NSBundle mainBundle] pathForResource:mpEngineString ofType:nil];
				if (continuous)
					[args addObject: @"YES"];
				else
					[args addObject: @"NO"];
				gsPath = [[SUD stringForKey:GSBinPath] stringByExpandingTildeInPath]; // 1.35 (D)
				[args addObject: gsPath];
				[args addObject: [[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath] stringByAppendingString:@"/"]];
			} else {
				switch (theScript) {
					case kTypesetViaPDFTeX:
						if (withLatex)
							myEngine = [[SUD stringForKey:LatexCommandKey] stringByExpandingTildeInPath]; // 1.35 (D)
						else
							myEngine = [[SUD stringForKey:TexCommandKey] stringByExpandingTildeInPath]; // 1.35 (D)
						
						if (continuous) {
							myEngine = [myEngine stringByAppendingString:@" --interaction=nonstopmode "];
						}
							
							if (omitShellEscape) {
								aRange = [myEngine rangeOfString:@"--shell-escape"];
								if (aRange.location == NSNotFound)
									warningGiven = YES;
								else {
									NSString* myEngineFirst = [myEngine substringToIndex: aRange.location];
									here = aRange.location + aRange.length;
									NSString* myEngineLast = [myEngine substringFromIndex: here];
									myEngine = [myEngineFirst stringByAppendingString: myEngineLast];
								}
							}
							break;
						
					case kTypesetViaGhostScript:
						if (continuous) {
							if (withLatex) {
								enginePath = [[NSBundle mainBundle] pathForResource:@"altpdflatex" ofType:nil];
								myEngine = [enginePath stringByAppendingString:@" --maxpfb --tex-path "];
								myEngine = [myEngine stringByAppendingString: [[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath]]; // 1.35 (D)
																																				  // fixPath = NO;
							} else {
								enginePath = [[NSBundle mainBundle] pathForResource:@"altpdftex" ofType:nil];
								myEngine = [enginePath stringByAppendingString:@" --maxpfb --tex-path "];
								myEngine = [myEngine stringByAppendingString: [[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath]]; // 1.35 (D)
																																				  // fixPath = NO;
							}
						} else {
							[self testGSCommandKey];
							if (withLatex)
								myEngine = [[SUD stringForKey:LatexGSCommandKey] stringByExpandingTildeInPath]; // 1.35 (D)
							else
								myEngine = [[SUD stringForKey:TexGSCommandKey] stringByExpandingTildeInPath]; // 1.35 (D)
						}
						
						if (([SUD integerForKey:DistillerCommandKey] == 1) && (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2))
							myEngine = [myEngine stringByAppendingString: @" --distiller /usr/bin/pstopdf"];
						
						break;
						
					case kTypesetViaPersonalScript:
						
						if (withLatex)
							myEngine = [[SUD stringForKey:LatexScriptCommandKey] stringByExpandingTildeInPath]; // 1.35 (D)
						else
							myEngine = [[SUD stringForKey:TexScriptCommandKey] stringByExpandingTildeInPath]; // 1.35 (D;
						
						if ([myEngine length] == 0) {
							if (withLatex)
								myEngine = [[SUD stringForKey:LatexCommandKey] stringByExpandingTildeInPath]; // 1.35 (D)
							else
								myEngine = [[SUD stringForKey:TexCommandKey] stringByExpandingTildeInPath]; // 1.35 (D)
						}
							
						break;
						
				}
			}
			
			
			//  if ((whichEngine != 2) && (whichEngine != 3) && (whichEngine != 4)) {
			if ((whichEngineLocal != MetapostEngine) && (whichEngineLocal != ContextEngine)) {
				
				enginePath = [self separate:myEngine into:args];

				if ((theScript == kTypesetViaGhostScript) && ([SUD boolForKey:SavePSEnabledKey])) 
					[args addObject: [NSString stringWithString:@"--keep-psfile"]];
			}
			
			// Koch: Feb 20; this allows spaces everywhere in path except
			// file name itself
			[args addObject: [sourcePath lastPathComponent]];
			
			/*
			 if ((enginePath != nil) && ([[NSFileManager defaultManager] fileExistsAtPath: enginePath])) {
				 [texTask setCurrentDirectoryPath: [sourcePath stringByDeletingLastPathComponent]];
				 [texTask setEnvironment: [self environmentForSubTask]];
				 [texTask setLaunchPath:enginePath];
				 [texTask setArguments:args];
				 [texTask setStandardOutput: outputPipe];
				 [texTask setStandardError: outputPipe];
				 [texTask setStandardInput: inputPipe];
				 [texTask launch];
				 
			 }
			 else {
				 */
			if ([self startTask: texTask running: enginePath withArgs: args inDirectoryContaining: sourcePath withEngine:whichEngineLocal] == FALSE) {
				[inputPipe release];
				[outputPipe release];
				[texTask release];
				texTask = nil;
			}
			 } else if (whichEngineLocal == BibtexEngine) {
				 NSString* bibPath = [sourcePath stringByDeletingPathExtension];
				 // Koch: ditto; allow spaces in path
				 [args addObject: [bibPath lastPathComponent]];
				 
				 if (bibTask != nil) {
					 [bibTask terminate];
					 [bibTask release];
					 bibTask = nil;
				 }
				 bibTask = [[NSTask alloc] init];
				 
				 NSString* bibtexEngineString;
				 switch ([SUD integerForKey:BibtexCommandKey]) {
					 case 0: bibtexEngineString = @"bibtex"; break;
					 case 1: bibtexEngineString = @"jbibtex"; break;
					 default: bibtexEngineString = @"bibtex"; break;
				 }
				 [self startTask: bibTask running: bibtexEngineString withArgs: args inDirectoryContaining: sourcePath withEngine:whichEngineLocal];
			 } else if (whichEngineLocal == IndexEngine) {
				 NSString* indexPath = [sourcePath stringByDeletingPathExtension];
				 // Koch: ditto, spaces in path
				 [args addObject: [indexPath lastPathComponent]];
				 
				 if (indexTask != nil) {
					 [indexTask terminate];
					 [indexTask release];
					 indexTask = nil;
				 }
				 indexTask = [[NSTask alloc] init];
				 [self startTask: indexTask running: @"makeindex" withArgs: args inDirectoryContaining: sourcePath withEngine:whichEngineLocal];
			 } else if (whichEngineLocal == MetafontEngine) {
				 NSString* metaFontPath = [sourcePath stringByDeletingPathExtension];
				 // Koch: ditto, spaces in path
				 [args addObject: [metaFontPath lastPathComponent]];
				 
				 if (metaFontTask != nil) {
					 [metaFontTask terminate];
					 [metaFontTask release];
					 metaFontTask = nil;
				 }
				 metaFontTask = [[NSTask alloc] init];
				 [self startTask: metaFontTask running: @"mf" withArgs: args inDirectoryContaining: sourcePath withEngine:whichEngineLocal];
			 } else if (whichEngineLocal >= UserEngine) {
				 NSString* userEngineName = [[[programButton itemAtIndex:(whichEngineLocal - 1)] title] stringByAppendingString:@".engine"];
				 NSString* userEnginePath = [[EnginePath stringByAppendingString:@"/"] stringByAppendingString: userEngineName];
				 // NSString* userPath = [sourcePath stringByDeletingPathExtension];
				 // Koch: ditto, spaces in path
				 // [args addObject: [userPath lastPathComponent]];
				 [args addObject: [sourcePath lastPathComponent]];
				 
				 if (texTask != nil) {
					 [texTask terminate];
					 [texTask release];
					 texTask = nil;
				 }
				 texTask = [[NSTask alloc] init];
				 
				 if ([self startTask: texTask running: userEnginePath withArgs: args inDirectoryContaining: sourcePath withEngine:whichEngineLocal] == FALSE) {
					 [inputPipe release];
					 [outputPipe release];
					 [texTask release];
					 texTask = nil;
				 }
			 }
			}
	useTempEngine = NO;
}


-(void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	switch (returnCode) {
		case NSAlertDefaultReturn:
			warningGiven = YES;
			[self completeSaveFinished];
			break;
			
		case NSAlertAlternateReturn: // this says omit --shell-escape
			warningGiven = YES;
			omitShellEscape = YES;
			[self completeSaveFinished];
			break;
			
		case NSAlertOtherReturn:
			break;
	}
}

- (void) doTex: sender
{
// added by mitsu --(J++) Program popup button indicating Program name
	[programButton selectItemWithTitle: @"Plain TeX"];
	[programButtonEE selectItemWithTitle: @"Plain TeX"];
// end addition

	[self doJob:TexEngine withError:YES runContinuously:NO];
}

- (void) doLatex: sender
{
// added by mitsu --(J++) Program popup button indicating Program name
	[programButton selectItemWithTitle: @"LaTeX"];
	[programButtonEE selectItemWithTitle: @"LaTeX"];
// end addition

	[self doJob:LatexEngine withError:YES runContinuously:NO];
}

- (void) doUser: (int)theEngine
{
	[programButton selectItemAtIndex:(theEngine - 1)];
	[programButtonEE selectItemAtIndex:(theEngine - 1)];
	whichEngine = theEngine;

	[self doJob:whichEngine withError:YES runContinuously:NO];
}

- (void) doContext: sender
{
// added by mitsu --(J++) Program popup button indicating Program name
	[programButton selectItemWithTitle: @"ConTeXt"];
	[programButtonEE selectItemWithTitle: @"ConTeXt"];
// end addition

	[self doJob:ContextEngine withError:YES runContinuously:NO];
}

- (void) doMetapost: sender
{
// added by mitsu --(J++) Program popup button indicating Program name
	[programButton selectItemWithTitle: @"MetaPost"];
	[programButtonEE selectItemWithTitle: @"MetaPost"];
// end addition

	[self doJob:MetapostEngine withError:YES runContinuously:NO];
}

- (void) doBibtex: sender
{
// added by mitsu --(J++) Program popup button indicating Program name
	[programButton selectItemWithTitle: @"BibTeX"];
	[programButtonEE selectItemWithTitle: @"BibTeX"];
// end addition

	[self doJob:BibtexEngine withError:NO runContinuously:NO];
}

- (void) doIndex: sender
{
// added by mitsu --(J++) Program popup button indicating Program name
	[programButton selectItemWithTitle: @"MakeIndex"];
	[programButtonEE selectItemWithTitle: @"MakeIndex"];
// end addition

	[self doJob:IndexEngine withError:NO runContinuously:NO];
}

- (void) doMetaFont: sender
{
// added by mitsu --(J++) Program popup button indicating Program name
	[programButton selectItemWithTitle: @"MetaFont"];
	[programButtonEE selectItemWithTitle: @"MetaFont"];
// end addition

	[self doJob:MetafontEngine withError:NO runContinuously:NO];
}

// The temp forms which follow do not reset the default typeset buttons
- (void) doTexTemp: sender
{
	[self doJob:TexEngine withError:YES runContinuously:NO];
}

- (void) doLatexTemp: sender
{
	[self doJobForScript:LatexEngine withError:YES runContinuously:NO];
}

- (void) doBibtexTemp: sender
{
	[self doJobForScript:BibtexEngine withError:YES runContinuously:NO];
}

- (void) doMetapostTemp: sender
{
	[self doJobForScript:MetapostEngine withError:YES runContinuously:NO];
}
- (void) doContextTemp: sender
{
	[self doJobForScript:ContextEngine withError:YES runContinuously:NO];
}

- (void) doIndexTemp: sender
{
	[self doJobForScript:IndexEngine withError:YES runContinuously:NO];
}

- (void) doMetaFontTemp: sender
{
	[self doJobForScript:MetafontEngine withError:YES runContinuously:NO];
}

- (void) doTypesetEE: sender
{
	[self doTypeset: sender];
}

- (void) doTypesetForScriptContinuously:(BOOL)method
{
	BOOL	useError;

   useError = NO;
   if ((whichEngine == TexEngine) || (whichEngine == LatexEngine) || (whichEngine == MetapostEngine) || (whichEngine == ContextEngine))
	useError = YES;
   if (whichEngine >= UserEngine)
	useError = YES;
// changed by mitsu --(J) Typeset commmand
	[self doJob: whichEngine withError:useError runContinuously:method];
// end change
}

- (void) doTypeset: sender
{
//    NSString	*titleString;
	BOOL	useError;

   useError = NO;
	if ((whichEngine == TexEngine) || (whichEngine == LatexEngine) || (whichEngine == MetapostEngine) || (whichEngine == ContextEngine))
		useError = YES;
	if (whichEngine >= UserEngine)
		useError = YES;
// changed by mitsu --(J) Typeset commmand
	[self doJob: whichEngine withError:useError runContinuously:NO];
// end change

/*
	titleString = [sender title];
	if ([titleString isEqualToString: @"TeX"])
		[self doTex:self];
	else if ([titleString isEqualToString: @"LaTeX"])
		[self doLatex: self];
	else if ([titleString isEqualToString: @"MetaPost"])
		[self doMetapost: self];
	else if ([titleString isEqualToString: @"ConTeXt"])
		[self doContext: self];
	else if ([titleString isEqualToString: @"BibTeX"])
		[self doBibtex: self];
	else if ([titleString isEqualToString: @"Index"])
		[self doIndex: self];
	else if ([titleString isEqualToString: @"MetaFont"])
		[self doMetaFont: self];
*/
}

- (void) doTexCommand: sender
{
	NSData *myData;
	NSString *command;

	if ((typesetStart) && (inputPipe)) {
		command = [[texCommand stringValue] stringByAppendingString:@"\n"];
		command = [self filterBackslashes:command];

		myData = [command dataUsingEncoding: NSMacOSRomanStringEncoding allowLossyConversion:YES];
		[writeHandle writeData: myData];
		// added by mitsu --(L) reflect tex input and clear tex input field in console window
		NSRange selectedRange = [outputText selectedRange];
		selectedRange.location += selectedRange.length;
		selectedRange.length = 0;
		// in the next two lines, replace "command" by "old command" after Japanese modification made -- koch
		[outputText replaceCharactersInRange: selectedRange withString: command];
		selectedRange.length = [command length];
		if ([SUD boolForKey: RedConsoleAfterErrorKey])
			[outputText setTextColor: [NSColor redColor] range: selectedRange];
		[outputText scrollRangeToVisible: selectedRange];
		[texCommand setStringValue: @""];
		// end addition

	}
}

- (void)abort:(id)sender
{
	if (! fileIsTex)
		return;

	/* The lines of code below kill previously running tasks. This is
	necessary because otherwise the source file will be open when the
	system tries to save a new version. If the source file is open,
	NSDocument makes a backup in /tmp which is never removed. */


   // [outputText setSelectable: YES];
   // [outputText selectAll:self];
	[outputText replaceCharactersInRange: [outputText selectedRange] withString:@"\nProcess aborted\n"];
	[outputText scrollRangeToVisible:[outputText selectedRange]];
   // [outputText setSelectable: NO];

	taskDone = YES;

	[self killRunningTasks];

	[inputPipe release];
	inputPipe = 0;
}

- (void)checkATaskStatus:(NSNotification *)aNotification
{
	NSString		*imagePath;
	NSString		*alternatePath;
	NSDictionary	*myAttributes;
	NSDate			*endDate;
	int				status;
	BOOL			alreadyFound;

	[outputText setSelectable: YES];

	if (([aNotification object] == bibTask) || ([aNotification object] == indexTask) || ([aNotification object] == metaFontTask)) {
		if (inputPipe == [[aNotification object] standardInput]) {
			[outputPipe release];
			[writeHandle closeFile];
			[inputPipe release];
			inputPipe = 0;
			if ([aNotification object] == bibTask) {
				[bibTask terminate];
				[bibTask release];
				bibTask = nil;
			} else if ([aNotification object] == indexTask) {
				[indexTask terminate];
				[indexTask release];
				indexTask = nil;
			} else if ([aNotification object] == metaFontTask) {
				[metaFontTask terminate];
				[metaFontTask release];
				metaFontTask = nil;
			}
		}
	}

	taskDone = YES;  // for Applescript

	if ([aNotification object] != texTask)
		return;

	if (inputPipe == [[aNotification object] standardInput]) {
		status = [[aNotification object] terminationStatus];

		if ((status == 0) || (status == 1))  {
			imagePath = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];

			alreadyFound = NO;
			if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) {
				myAttributes = [[NSFileManager defaultManager] fileAttributesAtPath: imagePath traverseLink:NO];
				endDate = [myAttributes objectForKey:NSFileModificationDate];
				if ((startDate == nil) || ! [startDate isEqualToDate: endDate]) {
					alreadyFound = YES;
					PDFfromKit = YES;
					[myPDFKitView reShowWithPath: imagePath];
					[pdfKitWindow setRepresentedFilename: imagePath];
					[pdfKitWindow setTitle: [imagePath lastPathComponent]];
					[pdfKitWindow makeKeyAndOrderFront: self];



				}
			}

			if (! alreadyFound)  { // see if there is a temporary file
				alternatePath = [[TempOutputKey stringByAppendingString:@"/"] stringByAppendingString:[imagePath lastPathComponent]];
				if ([[NSFileManager defaultManager] fileExistsAtPath: alternatePath]) {
					texRep = [[NSPDFImageRep imageRepWithContentsOfFile: alternatePath] retain];
					[[NSFileManager defaultManager] removeFileAtPath: alternatePath handler:nil];
					if (texRep) {
						[pdfWindow setTitle: [imagePath lastPathComponent]];
						[pdfView setImageRep: texRep];
						[pdfView setNeedsDisplay:YES];
						[pdfWindow makeKeyAndOrderFront: self];
					}
				}

			}
			[texTask terminate];
			[texTask release];
		}

		[outputPipe release];
		[writeHandle closeFile];
		[inputPipe release];
		inputPipe = 0;
		texTask = nil;
	}
}


@end
