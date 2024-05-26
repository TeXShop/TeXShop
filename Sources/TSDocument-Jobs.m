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
 * $Id: TSDocument-Jobs.m 254 2007-06-03 21:09:25Z fingolfin $
 *
 */

/* Note: NDS stands for Neil Sims, from The University of Sheffield, who added four features for version 4.18 */

#import "UseMitsu.h"

#import "TSDocument.h"

#import "MyPDFView.h"
#import "MyPDFKitView.h"

#import "globals.h"

#import "TSWindowManager.h"
#import "TSEncodingSupport.h"


@implementation TSDocument (JobProcessing)

- (BOOL)TestGSVersion
{
    
    NSString        *enginePath, *gsPath;
    NSMutableArray  *args;
    NSDate          *myDate;
    NSString        *tetexBinPath;
    int             status;
    
    status = 1;
    
    self.gsversionTask = [[NSTask alloc] init];
    [self.gsversionTask setEnvironment: [self environmentForSubTask]];
    enginePath = [[NSBundle mainBundle] pathForResource:@"gstestwrap" ofType:nil];
    tetexBinPath = [[SUD stringForKey:GSBinPath] stringByExpandingTildeInPath];
    args = [NSMutableArray array];
    [args addObject:tetexBinPath];
    if ((enginePath != nil) && ([[NSFileManager defaultManager] fileExistsAtPath: enginePath])) {
        [self.gsversionTask setLaunchPath:enginePath];
        [self.gsversionTask setArguments:args];
        [self.gsversionTask launch];
        [self.gsversionTask waitUntilExit];
        status = [self.gsversionTask terminationStatus];
        self.gsversionTask = nil;
        }
    else
       self.gsversionTask = nil;
    
    if (status == 0)
        return YES;
    else
        return NO;
    
 }
    
    
    
    


- (NSDictionary *)environmentForSubTask
{
	NSMutableDictionary *env;


	// get copy of environment and add the preferences paths
	env = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];

// NSEnumerator *enu = [env keyEnumerator];
/*
for(NSString *key in enu)
    { // NSLog(@"key : %@", key);
   //     NSLog(@"value : %@",[[env valueForKey:key] string]);
        
    }
 */
    
	// Customize 'PATH'
	NSMutableString *path;
	path = [NSMutableString stringWithString: [env objectForKey:@"PATH"]];
	[path appendString:@":"];
	[path appendString:[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath]];
	[path appendString:@":"];
	[path appendString:[SUD stringForKey:GSBinPath]];
	[env setObject: path forKey: @"PATH"];
    
//    enu = [dict keyEnumerator]; for(NSString *key in enu) {         NSLog(@"key : %@",key);         NSLog(@"value : %@",[[dic // //valueForKey:keystring]);  }
    
    //  NDS - add the current file location as a new env variable called TS_CHAR.
    // this allows custom engines to operate based upon the current location in the file.
    // the corresponding line number can be calculated from the bash script ('engine') using:
    //     line=`head -c $TS_CHAR $1 | wc -l`; line = `expr $line + 1`
    NSMutableString *envtschar;
    NSRange sel;
    sel=[[[textView selectedRanges] objectAtIndex:0] rangeValue];
    envtschar = [NSMutableString stringWithString: [NSString stringWithFormat: @"%lu",sel.location]];
    [env setObject:envtschar forKey: @"TS_CHAR"];
    // End NDS


	// Set 'TEXEDIT' env var (see the 'tex' man page for details). We construct a simple shell
	// command, which first (re)opens the document, and then uses osascript to run an AppleScript
	// which selects the right line. The AppleScript looks like this:
	//   tell application "TeXShop"
	//       goto document 1 line %d
	//       activate
	//   end tell
	// NSMutableString *script = [NSMutableString string];

/*
	[script appendFormat:@"open -a '%@' '%%s' &&", [[NSBundle mainBundle] bundlePath]];
	[script appendString:@" osascript"];
	[script appendString:@" -e 'tell application \"TeXShop\"'"];
	[script appendString:@" -e     'goto document 1 line %d'"];
	[script appendString:@" -e     'activate'"];
	[script appendString:@" -e 'end tell'"];

	[env setObject: script forKey:@"TEXEDIT"];
 */
	
	return env;
}


    
    
    


- (void)killRunningTasks
{
	NSDate	*myDate;
    BOOL    MainLogs;
    
    //MainLogs = [SUD boolForKey: DisplayLogInfoKey];
    // Not needed since "sudden halt" bug is fixed
    MainLogs = NO;
    
    if (MainLogs)
     //   NSLog(@"killRunningTasks");
    
	/* The lines of code below kill previously running tasks. This is
		necessary because otherwise the source file will be open when the
		system tries to save a new version. If the source file is open,
		NSDocument makes a backup in /tmp which is never removed. */

	if (self.texTask != nil) {
		if (theScript == kTypesetViaGhostScript) {
			kill( -[self.texTask processIdentifier], SIGTERM);
		} else {
			[self.texTask terminate];
			}
		myDate = [NSDate date];
		while (([self.texTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5))
			;
	//	[self.texTask release];
		self.texTask = nil;
	}

	if (self.bibTask != nil) {
		[self.bibTask terminate];
		myDate = [NSDate date];
		while (([self.bibTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5))
			;
	//	[self.bibTask release];
		self.bibTask = nil;
	}

	if (self.indexTask != nil) {
		[self.indexTask terminate];
		myDate = [NSDate date];
		while (([self.indexTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5))
			;
	//	[self.indexTask release];
		self.indexTask = nil;
	}

	if (self.metaFontTask != nil) {
		[self.metaFontTask terminate];
		myDate = [NSDate date];
		while (([self.metaFontTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5))
			;
	//	[self.metaFontTask release];
		self.metaFontTask = nil;
	}
}



- (void) doJobForScript:(NSInteger)type withError:(BOOL)error runContinuously:(BOOL)continuous
{
    SEL saveFinished;
    
    if (! fileIsTex)
		return;

	useTempEngine = YES;
	tempEngine = type;

	typesetContinuously = continuous;
	
	[self killRunningTasks];

	errorNumber = 0;
	whichError = 0;
	makeError = error;
    
// KOCH
    
    if (! doAutoSave) {
    


	if (!_externalEditor)
		[self checkFileLinksA];

	if (_externalEditor || (! [self isDocumentEdited])) {
		[self saveFinished: self didSave:YES contextInfo:nil];
	} else {
		[self saveDocumentWithDelegate: self didSaveSelector: @selector(saveFinished:didSave:contextInfo:) contextInfo: nil];
	}
    }
    
    else {
    
// patch by Ulrich Bauer; remove commented lines above and replace with
    
    if (!_externalEditor) {
            id wlist = [NSApp orderedDocuments];
            id en = [wlist objectEnumerator];
            id obj;
            while (obj = [en nextObject]) {
                if (([[obj windowNibName] isEqualToString:@"TSDocument"]) && (obj != self) && ([obj hasUnautosavedChanges])) 
                    {
                        [obj autosaveDocumentWithDelegate: self didAutosaveSelector: @selector(autosaveFinished:didSave:contextInfo:) contextInfo: nil];
                    }
                }
                
            saveFinished = @selector(saveFinished:didSave:contextInfo:);
            if ([self fileURL])
                    [self autosaveDocumentWithDelegate: self didAutosaveSelector: saveFinished contextInfo: nil];
            else
                    [self saveDocumentWithDelegate: self didSaveSelector: saveFinished contextInfo: nil];
                
            } 
        else {
            [self saveFinished: self didSave:YES contextInfo:nil];
        }

    }
    
}


- (void) doJob:(NSInteger)type withError:(BOOL)error runContinuously:(BOOL)continuous
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
	// [[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
	// whichEngine = type;
	// [[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
	if ((type == BibtexEngine) || (type == IndexEngine)) {
		useTempEngine = YES;
		tempEngine = type;
		}
	else {
		[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
		whichEngine = type;
		[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
		}
	
	[self fixMacroMenu];
	// end addition

// KOCH
    
    
    if (! doAutoSave) {
	if (!_externalEditor)
		[self checkFileLinksA];


	if (_externalEditor || ([self fileURL] && (! [self isDocumentEdited])) ) {
		[self saveFinished: self didSave:YES contextInfo:nil];
	} else {
		saveFinished = @selector(saveFinished:didSave:contextInfo:);
		[self saveDocumentWithDelegate: self didSaveSelector: saveFinished contextInfo: nil];
	}
    }
    
    else
 
    
 {

    
// bug fix by Ulrich Bauer; remove above lines and add
    
    	if (!_externalEditor) {
            id wlist = [NSApp orderedDocuments];
            id en = [wlist objectEnumerator];
            id obj;
            while (obj = [en nextObject]) {
                if (([[obj windowNibName] isEqualToString:@"TSDocument"]) && (obj != self) && ([obj hasUnautosavedChanges])) 
                    {
                    [obj autosaveDocumentWithDelegate: self didAutosaveSelector: @selector(autosaveFinished:didSave:contextInfo:) contextInfo: nil];
                    }
                }
         
        
        
 		saveFinished = @selector(saveFinished:didSave:contextInfo:);
        if ([self fileURL])
                [self autosaveDocumentWithDelegate: self didAutosaveSelector: saveFinished contextInfo: nil];
        else
                [self saveDocumentWithDelegate: self didSaveSelector: saveFinished contextInfo: nil];
        
        } else {
            [self saveFinished: self didSave:YES contextInfo:nil];
        }
    }
}

    
- (void) autosaveFinished: (NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo
{
    if(showFullPath) [textWindow performSelector:@selector(refreshTitle) withObject:nil afterDelay:0.2]; // added by Terada
}

    


- (NSString *) separate: (NSString *)myEngine into:(NSMutableArray *)args
{
	NSArray		*myList;
	NSString		*myString, *middleString = 0;
	NSInteger			size, i, pos;
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
	NSInteger				locationOfRest;
    
    changed = NO;
    gsTeXCommand = [SUD stringForKey:TexGSCommandKey];
    theRange = [gsTeXCommand rangeOfString: @"altpdftex"];
    if (theRange.location != NSNotFound) { // && (theRange.location == 0)) {
    locationOfRest = theRange.location + 9;
	binaryLocation = [[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath];
	path = [binaryLocation stringByAppendingString:@"/simpdftex"];
	fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:path]) {
		newGSTeXCommand = @"simpdftex tex";
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
	binaryLocation = [[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath];
	path = [binaryLocation stringByAppendingString:@"/simpdftex"];
	fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:path]) {
		newGSTeXCommand = @"simpdftex latex";
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
    
   // NSLog(@"convertDocument");
	myFileName = [[self fileURL] path];
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
                result = [fileManager createDirectoryAtPath:TempOutputKey withIntermediateDirectories:NO attributes:nil error:NULL];
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
					[fileManager removeItemAtPath:tempDestinationString error:NULL];
				[fileManager copyItemAtPath:myFileName toPath:tempDestinationString error:NULL];
			}
		}

		imagePath = [[[[self fileURL] path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];

		if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) {
			myAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath: imagePath error:NULL];
			self.startDate = [myAttributes objectForKey:NSFileModificationDate];
		}
		else
			self.startDate = nil;

		args = [NSMutableArray array];
		sourcePath = myFileName;

		self.texTask = [[NSTask alloc] init];
		if ((! writeable) && (! [[myFileName pathExtension] isEqualToString:@"dvi"]))
			[self.texTask setCurrentDirectoryPath: TempOutputKey];
		else
			[self.texTask setCurrentDirectoryPath: [sourcePath stringByDeletingLastPathComponent]];
		[self.texTask setEnvironment: [self environmentForSubTask]];

		if ([[myFileName pathExtension] isEqualToString:@"dvi"]) {
			[self testGSCommandKey];
			enginePath = [[SUD stringForKey:LatexGSCommandKey] stringByExpandingTildeInPath];

			if (([SUD integerForKey:DistillerCommandKey] == 1) && (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2))
				enginePath = [enginePath stringByAppendingString: @" --distiller /usr/bin/pstopdf"];
			if (! writeable) {
				argumentString = [@" --outdir " stringByAppendingString: TempOutputKey];
				enginePath = [enginePath stringByAppendingString: argumentString];
			}
			enginePath = [self separate:enginePath into: args];
			if ([SUD boolForKey:SavePSEnabledKey])
				[args addObject: @"--keep-psfile"];
		} else if ([[myFileName pathExtension] isEqualToString:@"ps"]) {
            if ([SUD boolForKey:UseTransparencyKey])
                enginePath = [[NSBundle mainBundle] pathForResource:@"ps2pdftransparencywrap" ofType:nil];
            else
                enginePath = [[NSBundle mainBundle] pathForResource:@"ps2pdfwrap" ofType:nil];
			if (([SUD integerForKey:DistillerCommandKey] == 1) && (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2))
				[args addObject: @"Panther"];
			else
				[args addObject: @"Ghostscript"];
			gsPath = [[SUD stringForKey:GSBinPath] stringByExpandingTildeInPath];
			[args addObject: gsPath];
		} else if  ([[myFileName pathExtension] isEqualToString:@"eps"]) {
			enginePath = [[NSBundle mainBundle] pathForResource:@"epstopdfwrap" ofType:nil];
			if (([SUD integerForKey:DistillerCommandKey] == 1) && (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2))
				[args addObject: @"Panther"];
			else
				[args addObject: @"Ghostscript"];
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
		self.inputPipe = [NSPipe pipe];
		[self.texTask setStandardInput: self.inputPipe];
		if ((enginePath != nil) && ([[NSFileManager defaultManager] fileExistsAtPath: enginePath])) {
			[self.texTask setLaunchPath:enginePath];
			[self.texTask setArguments:args];
			[self.texTask launch];
            [self.texTask waitUntilExit];
		} else {
	//		[self.inputPipe release];
	//		[self.texTask release];
			self.texTask = nil;
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
	NSUInteger      mystart, myend;
	NSUInteger      start, end, irrelevant;
	NSInteger             whichEngineLocal;
	NSInteger             i, j;
	BOOL            done;
	NSUInteger        length;
	NSInteger             linesTested, offset;
	NSData          *myData;
    BOOL            fromAlternateTemp;
    
    [self RescanMagicComments: self];
    if (self.automaticCorrection)
        {
        self.numberingCorrection = 0;
        }
    

    fromAlternateTemp = fromAlternate;
    fromAlternate = NO;

	whichEngineLocal = (useTempEngine ? tempEngine : whichEngine);

	if (whichEngineLocal == LatexEngine)
		withLatex = YES;
	else if (whichEngineLocal == TexEngine)
		withLatex = NO;
	theScript = whichScript;

	if (!_externalEditor)
		theSource = [[self textView] string];
	else {
		myData = [NSData dataWithContentsOfFile:[[self fileURL] path]];
		theSource = [[NSString alloc] initWithData:myData encoding:NSISOLatin9StringEncoding];
	}

	if ([self checkMasterFile:theSource forTask:RootForTexing]) {
		useTempEngine = NO;
		return;
	}
	if ([self checkRootFile_forTask:RootForTexing]) {
		useTempEngine = NO;
		return;
	}

/* // Ulrich Bauer patch
	if (!_externalEditor)
		[self checkFileLinks:theSource];
*/

	// New Stuff
    
    
	length = [theSource length];
	done = NO;
	linesTested = 0;
	myRange.location = 0;
	myRange.length = 1;
    
    
if ((whichEngineLocal != 3) && (whichEngineLocal != 4) && (! fromMenu)) { //don't use TS-program for BibTeX and MakeIndex or Menu Command
    
    
    length = [theSource length];
    done = NO;
    linesTested = 0;
    myRange.location = 0;
    myRange.length = 1;
    parameterExists = NO;


    while ((myRange.location < length) && (!done) && (linesTested < 20)) {
        [theSource getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
        myRange.location = end;
        myRange.length = 1;
        linesTested++;
        
        theRange.location = start; theRange.length = (end - start);
        testString = [theSource substringWithRange: theRange];
        
        programRange = [testString rangeOfString:@"%!TEX TS-parameter ="];
        offset = 20;
        if (programRange.location == NSNotFound) {
            programRange = [testString rangeOfString:@"% !TEX TS-parameter ="];
            offset = 21;
        }
        if (programRange.location == NSNotFound) {
            programRange = [testString rangeOfString:@"% !TEX parameter ="];
            offset = 18;
        }
        if (programRange.location == NSNotFound) {
            programRange = [testString rangeOfString:@"%!TEX parameter ="];
            offset = 17;
        }
        if (programRange.location != NSNotFound) {
            newProgramRange.location = programRange.location + offset;
            newProgramRange.length = [testString length] - newProgramRange.location;
            if (newProgramRange.length > 0) {
                parameterExists = YES;
                parameterString = [[testString substringWithRange: newProgramRange]
                                   stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
    }

    
    length = [theSource length];
    done = NO;
    linesTested = 0;
    myRange.location = 0;
    myRange.length = 1;
    
    
   
		
	while ((myRange.location < length) && (!done) && (linesTested < 20)) {
		[theSource getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
		myRange.location = end;
		myRange.length = 1;
		linesTested++;

		theRange.location = start; theRange.length = (end - start);
		testString = [theSource substringWithRange: theRange];

		programRange = [testString rangeOfString:@"%!TEX TS-program ="];
		offset = 18;
		if (programRange.location == NSNotFound) {
			programRange = [testString rangeOfString:@"% !TEX TS-program ="];
			offset = 19;
			}
        if (programRange.location == NSNotFound) {
			programRange = [testString rangeOfString:@"% !TEX program ="];
			offset = 16;
            }
        if (programRange.location == NSNotFound) {
			programRange = [testString rangeOfString:@"%!TEX program ="];
			offset = 15;
        }
		if (programRange.location != NSNotFound) {
			newProgramRange.location = programRange.location + offset;
			newProgramRange.length = [testString length] - newProgramRange.location;
			if (newProgramRange.length > 0) {
				programString = [[testString substringWithRange: newProgramRange]
						stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
				programString = [programString lowercaseString];
				if ([programString isEqualToString:@"pdftex"]) {
					useTempEngine = YES;
					tempEngine = TexEngine;
					withLatex = NO;
					theScript = kTypesetViaPDFTeX;
					done = YES;
				} else if ([programString isEqualToString:@"pdflatex"]) {
					useTempEngine = YES;
					tempEngine = LatexEngine;
					withLatex = YES;
					theScript = kTypesetViaPDFTeX;
					done = YES;
				} else if ([programString isEqualToString:@"tex"]) {
					useTempEngine = YES;
					tempEngine = TexEngine;
					withLatex = NO;
					theScript = kTypesetViaGhostScript;
					done = YES;
				} else if ([programString isEqualToString:@"latex"]) {
					useTempEngine = YES;
					tempEngine = LatexEngine;
					withLatex = YES;
					theScript = kTypesetViaGhostScript;
					done = YES;
				} else if ([programString isEqualToString:@"personaltex"]) {
					useTempEngine = YES;
					tempEngine = TexEngine;
					withLatex = NO;
					theScript = kTypesetViaPersonalScript;
					done = YES;
				} else if ([programString isEqualToString:@"personallatex"]) {
					useTempEngine = YES;
					tempEngine = LatexEngine;
					withLatex = YES;
					theScript = kTypesetViaPersonalScript;
					done = YES;
				} else if ([programString isEqualToString:@"bibtex"]) {
					[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
					useTempEngine = YES;
					tempEngine = BibtexEngine;
					// whichEngine = BibtexEngine;
					// [[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
					// [self fixMacroMenu];
					done = YES;
				} else if ([programString isEqualToString:@"makeindex"]) {
					// [[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
					useTempEngine = YES;
					tempEngine = IndexEngine;
					// whichEngine = IndexEngine;
					// [[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
					// [self fixMacroMenu];
					done = YES;
				} else if ([programString isEqualToString:@"metapost"]) {
					[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
					whichEngine = MetapostEngine;
					[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
					[self fixMacroMenu];
					done = YES;
        /*
				} else if ([programString isEqualToString:@"context"]) {
					[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
					whichEngine = ContextEngine;
					[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
					[self fixMacroMenu];
                    done = YES;
         */
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
    
    if ((!done) && (fromAlternateTemp))
    {
        
        programString = [SUD stringForKey: AlternateEngineKey];
        programString = [programString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        programString = [programString lowercaseString];
        
        if ([programString isEqualToString:@"pdftex"]) {
            useTempEngine = YES;
            tempEngine = TexEngine;
            withLatex = NO;
            theScript = kTypesetViaPDFTeX;
            done = YES;
        } else if ([programString isEqualToString:@"pdflatex"]) {
            useTempEngine = YES;
            tempEngine = LatexEngine;
            withLatex = YES;
            theScript = kTypesetViaPDFTeX;
            done = YES;
        } else if ([programString isEqualToString:@"tex"]) {
            useTempEngine = YES;
            tempEngine = TexEngine;
            withLatex = NO;
            theScript = kTypesetViaGhostScript;
            done = YES;
        } else if ([programString isEqualToString:@"latex"]) {
            useTempEngine = YES;
            tempEngine = LatexEngine;
            withLatex = YES;
            theScript = kTypesetViaGhostScript;
            done = YES;
        } else if ([programString isEqualToString:@"personaltex"]) {
            useTempEngine = YES;
            tempEngine = TexEngine;
            withLatex = NO;
            theScript = kTypesetViaPersonalScript;
            done = YES;
        } else if ([programString isEqualToString:@"personallatex"]) {
            useTempEngine = YES;
            tempEngine = LatexEngine;
            withLatex = YES;
            theScript = kTypesetViaPersonalScript;
            done = YES;
        } else if ([programString isEqualToString:@"bibtex"]) {
            [[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
            useTempEngine = YES;
            tempEngine = BibtexEngine;
            // whichEngine = BibtexEngine;
            // [[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
            // [self fixMacroMenu];
            done = YES;
        } else if ([programString isEqualToString:@"makeindex"]) {
            // [[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
            useTempEngine = YES;
            tempEngine = IndexEngine;
            // whichEngine = IndexEngine;
            // [[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
            // [self fixMacroMenu];
            done = YES;
        } else if ([programString isEqualToString:@"metapost"]) {
            [[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
            whichEngine = MetapostEngine;
            [[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
            [self fixMacroMenu];
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
				} else if ([lowerprogramName isEqualToString:@"metapost"]) {
					[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
					whichEngine = MetapostEngine;
					[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
					[self fixMacroMenu];
				} else if ([lowerprogramName isEqualToString:@"bibtex"]) {
					[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
					whichEngine = BibtexEngine;
					[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
					[self fixMacroMenu];
				} else if ([lowerprogramName isEqualToString:@"makeindex"]) {
					[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
					whichEngine = IndexEngine;
					[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
					[self fixMacroMenu];
				}
                
            /*      else if ([lowerprogramName isEqualToString:@"context"]) {
					[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: NO];
					whichEngine = ContextEngine;
					[[TSWindowManager sharedInstance] checkProgramMenuItem: whichEngine checked: YES];
					[self fixMacroMenu];
				}
             */
                    else {
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
	
	fromMenu = NO;

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
			NSBeginCriticalAlertSheet (nil, nil, NSLocalizedString(@"Omit Shell Escape", @"Omit Shell Escape"), NSLocalizedString(@"Cancel", @"Cancel"),
									  textWindow, self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, nil,
									  NSLocalizedString(@"Warning: Using Shell Escape", @"Warning: Using Shell Escape"));
			useTempEngine = NO;
			return;
		}
	}

	[self completeSaveFinished];
}

-(void)repeatTypeset
{
    BOOL DisplayLogs;
    
    // DisplayLogs = ([SUD boolForKey: DisplayLogInfoKey] && [SUD boolForKey: UseTerminationHandlerKey]);
    // Not needed since "sudden halt" bug is fixed
    DisplayLogs = NO;
    
    if (DisplayLogs)
    //    NSLog(@"Repeating Job");
        ;
    if ([SUD boolForKey: DoNotFixTeXCrashKey])
        return;
    
    [self trashAUXFiles: self];
    [self doTypeset:self];
//    result = [self startTask: self.texTask running: oldLeafName withArgs: oldArgs inDirectoryContaining: oldSourcePath withEngine: oldTheEngine];
}

- (BOOL) startTask: (NSTask*) task running: (NSString*) leafname withArgs: (NSMutableArray*) args inDirectoryContaining: (NSString*) sourcePath withEngine: (NSInteger)theEngine
{
	BOOL            isFile;
	BOOL            isExecutable;
    NSDictionary    *myAttributes;
    NSURL           *myFileURL, *myCurrentDirectoryURL;
    BOOL            result;
    NSError         *error = nil;
    BOOL            DisplayLogs, MainLogs;
    
    // MainLogs = [SUD boolForKey: DisplayLogInfoKey];
    // DisplayLogs = ([SUD boolForKey: DisplayLogInfoKey] && [SUD boolForKey: UseTerminationHandlerKey]);
    // Not needed since "sudden halt" bug is fixed
    MainLogs = NO;
    DisplayLogs = NO;
    
    if (MainLogs)
        NSLog(@"startTask");
    
    doAbort = NO;
	
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

        
        BOOL standardPath = NO;
        BOOL linkBad = NO;
         
        NSString* binPath = [[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath];
        if (([binPath isEqualToString: @"/usr/texbin"]) || ([binPath isEqualToString: @"/Library/TeX/texbin"]))
            standardPath = YES;
        
        NSFileManager *myManager = [NSFileManager defaultManager];
        myAttributes = [myManager attributesOfItemAtPath: @"/Library/TeX/texbin" error: nil];
        if (myAttributes == nil)
            linkBad = YES;
        else if ([myAttributes objectForKey: NSFileType ] != NSFileTypeSymbolicLink)
            linkBad = YES;
        
        if (standardPath && linkBad && atLeastElCapitan)
            {
            NSBeginAlertSheet(NSLocalizedString(@"Can't find required tool.", @"Can't find required tool."),
                          nil, nil, nil, [textView window], nil, nil, nil, nil,
                          NSLocalizedString(@"The link /Library/TeX/texbin does not exist. To fix this, go to https://tug.org/mactex and install MacTeX or Basic TeX (2015 or later).",
                            @"The link /Library/TeX/texbin does not exist. To fix this, go to https://tug.org/mactex and install MacTeX or Basic TeX (2015 or later)."),
                          filename);
                return FALSE;
            }
        else
            {
            NSBeginAlertSheet(NSLocalizedString(@"Can't find required tool.", @"Can't find required tool."),
						  nil, nil, nil, [textView window], nil, nil, nil, nil,
						  NSLocalizedString(@"%@ does not exist. TeXShop is a front end for TeX, but you also need a TeX distribution. Perhaps such a distribution was not installed or was removed during a system upgrade. If so, go to https://tug.org/mactex and follow the instructions to install MacTeX or BasicTeX.",
                            @"%@ does not exist. TeXShop is a front end for TeX, but you also need a TeX distribution. Perhaps such a distribution was not installed or was removed during a system upgrade. If so, go to https://tug.org/mactex and follow the instructions to install MacTeX or BasicTeX."),
						  filename);
                return FALSE;
            }
    }
	
	// We know the executable is okay, so give it a go...

    [task setArguments: args];
    [task setEnvironment: [self environmentForSubTask]];
    [task setStandardOutput: self.outputPipe];
    [task setStandardError: self.outputPipe];
    [task setStandardInput: self.inputPipe];

   //  if ((task != self.indexTask) && ([SUD boolForKey: UseTerminationHandlerKey]))
    // last part not needed since "sudden halt" bug is fixed
    
    if (task != self.indexTask)
    {
    
    if (MainLogs)
        NSLog(@"got to using termination Handler");
        
    task.terminationHandler = ^(NSTask *myTask){
    
        id stdoutString = nil;
        id stderrString = nil;
    @try {
        id stdoutData = [[myTask.standardOutput fileHandleForReading] readDataToEndOfFile];
        stdoutString = [[NSString alloc] initWithData:stdoutData encoding:NSUTF8StringEncoding];
        id stderrData = [[myTask.standardError fileHandleForReading] readDataToEndOfFile];
        stderrString = [[NSString alloc] initWithData:stderrData encoding:NSUTF8StringEncoding];
        }
    @catch (NSException *exception) {
            ;
            }
    @finally {
            ;
        }
        int theReason = myTask.terminationReason;
        int theStatus = [myTask terminationStatus];
        if (DisplayLogs)
            NSLog(@"The status is %d:", theStatus);
        BOOL doAbort1 = doAbort;
        doAbort = NO;
        
        
        if (myTask.terminationReason == NSTaskTerminationReasonExit && myTask.terminationStatus == 0)
            ;
        else
            {
            id cmd = [NSMutableArray arrayWithObject:myTask.launchPath];
            [cmd addObjectsFromArray:myTask.arguments];
            cmd = [cmd componentsJoinedByString:@" "];
            NSString *mainString = [NSString stringWithFormat:@"Failed executing: %@.", cmd];
            if (DisplayLogs)
                NSLog(mainString);
              if (DisplayLogs)
                NSLog(@"The status is %d.", [myTask terminationStatus]);
                
            if (! (stdoutString == nil)) {
                NSString *aString = [NSString stringWithFormat: @"Standard output: %@.", stdoutString];
                if (DisplayLogs)
                   NSLog(aString);
                }
            
            if (! (stderrString == nil)) {
                NSString *bString = [NSString stringWithFormat: @"Standard error: %@.", stderrString];
                if (DisplayLogs)
                    NSLog(bString);
                }
            
                
            NSString *cString = [NSString stringWithFormat: @"Termination Reason: %d.", theReason];
            if (DisplayLogs)
                NSLog(cString);
            
            }
         
      //  BOOL repeatTypesetOnError13 = [SUD boolForKey: RepeatTypesetOnError13Key];
      //  Not needed since "sudden halt" bug is fixed
     BOOL   repeatTypesetOnError13 = NO;
        
        if ((! doAbort1) && (myTask.terminationReason == 2) && (myTask == self.texTask) && (theStatus == 13) && (repeatTypesetOnError13))
            {
            if (myTask.running)
            [myTask terminate];
            [self performSelectorOnMainThread: @selector(repeatTypeset) withObject:nil waitUntilDone:NO];
            }
          else
          {
              [self performSelectorOnMainThread: @selector(checkATaskStatusFromTerminationRoutine:) withObject:myTask waitUntilDone:NO];
          }
    };
    }
        
#ifdef HIGHSIERRAORHIGHER
    if (atLeastHighSierra) // && (task != self.indexTask))
        {
            myFileURL = [NSURL fileURLWithPath:filename isDirectory:NO];
            task.executableURL = myFileURL;
            myCurrentDirectoryURL = [NSURL fileURLWithPath:[sourcePath stringByDeletingLastPathComponent] isDirectory:YES];
            task.currentDirectoryURL = myCurrentDirectoryURL;
            if (DisplayLogs)
                NSLog(@"Start task");
            result = [task launchAndReturnError:&error];
        }
    else
#endif
        {
            [task setLaunchPath: filename];
            [task setCurrentDirectoryPath: [sourcePath stringByDeletingLastPathComponent]];
            [task launch];
        }
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
	NSUInteger		here;
	BOOL                continuous;
	BOOL                fixPath;
	NSInteger                 whichEngineLocal;
    BOOL        MainLogs;
    BOOL        KeepConsoleClosed;
    NSString   *userEngineName1, *userEnginePath1, *normalizedEnginePath1, *textOfEngine1;
    
    KeepConsoleClosed = NO;

    self.PreviewType = 0;
    
	whichEngineLocal = useTempEngine ? tempEngine : whichEngine;
    
    if (whichEngineLocal >= UserEngine)
    {
        userEngineName1 = [[[programButton itemAtIndex:(whichEngineLocal - 1)] title] stringByAppendingString:@".engine"];
        userEnginePath1 = [[EnginePath stringByAppendingString:@"/"] stringByAppendingString: userEngineName1];
        normalizedEnginePath1 = [userEnginePath1 stringByExpandingTildeInPath];
        textOfEngine1 = [NSString stringWithContentsOfFile: normalizedEnginePath1 encoding:NSISOLatin9StringEncoding  error: NULL];
        if ([textOfEngine1 containsString: @"!TEX-noConsole"])
             KeepConsoleClosed = YES;
    }
         
    
    
    
    
    // MainLogs = [SUD boolForKey: DisplayLogInfoKey];
    // Not needed since "sudden halt" bug is fixed
    MainLogs = NO;
    
    if (MainLogs)
        NSLog(@"completeSaveFinished");
    
	fixPath = YES;
	continuous = typesetContinuously;
	typesetContinuously = NO;

	myFileName = [[self fileURL] path];
	if ([myFileName length] > 0) {
		
		if (self.startDate != nil) {
	//		[self.startDate release];
			self.startDate = nil;
		}
		
		imagePath = [[[[self fileURL] path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) {
			myAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath: imagePath error:NULL];
			self.startDate = [myAttributes objectForKey:NSFileModificationDate];
		} else
			self.startDate = nil;
		
		sourcePath = myFileName;
		
		
		
		args = [NSMutableArray array];
		
		self.outputPipe = [NSPipe pipe];
		self.readHandle = [self.outputPipe fileHandleForReading];
		// [self.readHandle readInBackgroundAndNotify];
        [self.readHandle waitForDataInBackgroundAndNotify];
		self.inputPipe = [NSPipe pipe];
		self.writeHandle = [self.inputPipe fileHandleForWriting];
		
		consoleCleanStart = YES;
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
		
		
		[outputWindow setTitle: [[[imagePath lastPathComponent] stringByDeletingPathExtension]
			stringByAppendingString:@" console"]];
		if ([SUD boolForKey:ConsoleBehaviorKey]) {
			if (![outputWindow isVisible])
				[outputWindow orderBack: self];
				// BOOL front = [SUD boolForKey: BringPdfFrontOnTypesetKey];
				//if (front)
				//		[outputWindow makeKeyWindow];
		} else if (! KeepConsoleClosed)
            {
			if ([SUD boolForKey: BringPdfFrontOnTypesetKey])
				[outputWindow makeKeyAndOrderFront: self];
			else
				[outputWindow orderFront: self];
            }
        
		
		
		
		//   if (whichEngine < 5)
        if ((whichEngineLocal == TexEngine) || (whichEngineLocal == LatexEngine) || (whichEngineLocal == MetapostEngine)) { //} || (whichEngineLocal == ContextEngine)) {
			NSString* enginePath = 0;
			NSString* myEngine = 0;
/*
			if ((theScript == kTypesetViaGhostScript) && ([SUD boolForKey:SavePSEnabledKey])
				//        && (whichEngine != 2)   && (whichEngine != 4))
				&& (whichEngineLocal != MetapostEngine) && (whichEngineLocal != ContextEngine))
					[args addObject: [NSString stringWithString:@"--keep-psfile"]];
*/			
			if (self.texTask != nil) {
				[self.texTask terminate];
		//		[self.texTask release];
				self.texTask = nil;
			}
			self.texTask = [[NSTask alloc] init];
			
    /*
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
			} else
     */
            if (whichEngineLocal == MetapostEngine) {
				NSString* mpEngineString;
				switch ([SUD integerForKey:MetaPostCommandKey]) {
					case 0: mpEngineString = @"metapostwrap"; break;
					case 1: mpEngineString = @"metapostwrap"; break;
					default: mpEngineString = @"metapostwrap"; break;
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
						
						
						if (([SUD integerForKey:DistillerCommandKey] == 1) && (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2))
							myEngine = [myEngine stringByAppendingString: @" --distiller /usr/bin/pstopdf"];
                        
                        //KOCH2023
                        else {
                            
                            BOOL versionOK = true;
                            
                            if ([SUD boolForKey:UseTransparencyKey])
                               versionOK = [self TestGSVersion];
                                
                        
                            if ( (versionOK) && (! [myEngine containsString:@"--distiller"]) && ([SUD boolForKey:UseTransparencyKey]))
                            
                                myEngine = [myEngine stringByAppendingString: @" --distilleropts \"-dALLOWPSTRANSPARENCY\" "];
                   
                                  
                            }
                        
                        }
						
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
            if ((whichEngineLocal != MetapostEngine)) { //} && (whichEngineLocal != ContextEngine)) {
				
				enginePath = [self separate:myEngine into:args];

				if ((theScript == kTypesetViaGhostScript) && ([SUD boolForKey:SavePSEnabledKey])) 
					[args addObject: @"--keep-psfile"];
          
               
                
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
			if ([self startTask: self.texTask running: enginePath withArgs: args inDirectoryContaining: sourcePath withEngine:whichEngineLocal] == FALSE) {
		//		[self.inputPipe release];
		//		[self.outputPipe release];
		//		[self.texTask release];
				self.texTask = nil;
			}
			 } else if (whichEngineLocal == BibtexEngine) {
                 
                 // New Stuff
                 NSUInteger length;
                 BOOL       done;
                 NSUInteger linesTested, offset;
                 NSRange    myRange, theRange, bibRange, newBibRange;
                 NSString   *theSource, *testString, *bibString;
                 NSUInteger start, end, irrelevant;
                 
                 theSource = [[self textView] string];
                 
                 length = [theSource length];
                 done = NO;
                 linesTested = 0;
                 myRange.location = 0;
                 myRange.length = 1;
                 
                 
                 while ((myRange.location < length) && (!done) && (linesTested < 20)) {
                         [theSource getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
                         myRange.location = end;
                         myRange.length = 1;
                         linesTested++;
                         
                         theRange.location = start; theRange.length = (end - start);
                         testString = [theSource substringWithRange: theRange];
                         
                         bibRange = [testString rangeOfString:@"% !BIB TS-program ="];
                         offset = 19;
                         if (bibRange.location == NSNotFound) {
                             bibRange = [testString rangeOfString:@"%!BIB TS-program ="];
                             offset = 18;
                         }
                         if (bibRange.location == NSNotFound) {
                             bibRange = [testString rangeOfString:@"% !BIB program ="];
                             offset = 16;
                         }
                         if (bibRange.location == NSNotFound) {
                             bibRange = [testString rangeOfString:@"%!BIB program ="];
                             offset = 15;
                         }
                         if (bibRange.location != NSNotFound) {
                             newBibRange.location = bibRange.location + offset;
                             newBibRange.length = [testString length] - newBibRange.location;
                             if (newBibRange.length > 0) {
                                 bibString = [[testString substringWithRange: newBibRange]
                                                  stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                 done = YES;
                             }
                         }
                 }
                    
				 NSString* bibPath = [sourcePath stringByDeletingPathExtension];
				 // Koch: ditto; allow spaces in path
				 [args addObject: [bibPath lastPathComponent]];
				 
				 if (self.bibTask != nil) {
					 [self.bibTask terminate];
			//		 [self.bibTask release];
					 self.bibTask = nil;
				 }
				
                 
                 NSMutableArray *bibtexArgs;
                 NSString *bibtexEngineString;
                 NSString *bibProgramPath, *tetexBinPath;;
                 
                 if (done) {
                     bibtexArgs = [NSMutableArray arrayWithCapacity:0];
                     bibtexEngineString = [self separate: bibString into:bibtexArgs];
                     [bibtexArgs addObjectsFromArray:args];
                     
                     tetexBinPath = [[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath] stringByAppendingString:@"/"];
                     bibProgramPath = [tetexBinPath stringByAppendingString: bibtexEngineString];
                    }
                 
                
                 else {
                 
                 // modified by Terada
                 bibtexArgs = [NSMutableArray arrayWithCapacity:0];
                 bibtexEngineString = [self separate:[SUD objectForKey:BibTeXengineKey] into:bibtexArgs];
                 [bibtexArgs addObjectsFromArray:args];
                 }
                 
                 
                 tetexBinPath = [[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath] stringByAppendingString:@"/"];
                 bibProgramPath = [tetexBinPath stringByAppendingString: bibtexEngineString];
                 
                 if ( ! [[NSFileManager defaultManager] fileExistsAtPath: bibProgramPath]) {
                     NSString *message = NSLocalizedString(@"The program ", @"The program ");
                     message = [[message stringByAppendingString: bibtexEngineString] stringByAppendingString: NSLocalizedString(@" does not exist.", @" does not exist.")];
                     
                     NSRunAlertPanel(NSLocalizedString(@"Error", @"Error"), message, 
                                  nil,
                                     nil, nil);
                 }
                 else {
                     
                     
                     self.bibTask = [[NSTask alloc] init];
                     [self startTask: self.bibTask running: bibtexEngineString withArgs: bibtexArgs inDirectoryContaining: sourcePath withEngine:whichEngineLocal];
                 }
             
        
		 
                 
                  /*
				 NSString* bibtexEngineString;
				
				  switch ([SUD integerForKey:BibtexCommandKey]) {
				  case 0: bibtexEngineString = @"bibtex"; break;
				  case 1: bibtexEngineString = @"jbibtex"; break;
				  default: bibtexEngineString = @"bibtex"; break;
				  } // comment out by Terada
				 bibtexEngineString = [SUD objectForKey:BibTeXengineKey]; // modified by Terada
                 [self startTask: bibTask running: bibtexEngineString withArgs: args inDirectoryContaining: sourcePath withEngine:whichEngineLocal];
                 */
                 
             }  else if (whichEngineLocal == IndexEngine) {
				 NSString* indexPath = [sourcePath stringByDeletingPathExtension];
				 // Koch: ditto, spaces in path
                 [args addObject: [[indexPath lastPathComponent] stringByAppendingPathExtension: @"idx"]];
				 
				 if (self.indexTask != nil) {
					 [self.indexTask terminate];
			//		 [self.indexTask release];
					 self.indexTask = nil;
				 }
				 self.indexTask = [[NSTask alloc] init];
				 [self startTask: self.indexTask running: @"makeindex" withArgs: args inDirectoryContaining: sourcePath withEngine:whichEngineLocal];
			  } else if (whichEngineLocal >= UserEngine) {
				 NSString* userEngineName = [[[programButton itemAtIndex:(whichEngineLocal - 1)] title] stringByAppendingString:@".engine"];
				 NSString* userEnginePath = [[EnginePath stringByAppendingString:@"/"] stringByAppendingString: userEngineName];
                  
                  NSString* normalizedEnginePath;
                  NSString* textOfEngine;
                  
                  normalizedEnginePath = [userEnginePath stringByExpandingTildeInPath];
                  textOfEngine = [NSString stringWithContentsOfFile: normalizedEnginePath encoding:NSISOLatin9StringEncoding  error: NULL];
                  if ([textOfEngine containsString: @"!TEX-noPreview"])
                      self.PreviewType = 1;
                  else if ([textOfEngine containsString: @"!TEX-bothPreview"])
                      self.PreviewType = 4;
                  else if ([textOfEngine containsString: @"!TEX-pdfPreview"])
                      self.PreviewType = 2;
                  else if ([textOfEngine containsString: @"!TEX-htmlPreview"])
                      self.PreviewType = 3;
                  
                   // NSLog(@"This is the spot to consult the engine script");
                  
                  
				 // NSString* userPath = [sourcePath stringByDeletingPathExtension];
				 // Koch: ditto, spaces in path
				 // [args addObject: [userPath lastPathComponent]];
				 [args addObject: [sourcePath lastPathComponent]];
                  
                  if (parameterExists)
                      [args addObject: parameterString];
                  else
                      [args addObject: @" "];
                  
                  NSString *tetexBinPath = [[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath];
                  NSString *alternateBinPath = [[SUD stringForKey:AltPathKey] stringByExpandingTildeInPath];
                  if ( self.useAlternatePath )
                      [args addObject: alternateBinPath];
                  else
                      [args addObject: tetexBinPath];

				 
				 if (self.texTask != nil) {
					 [self.texTask terminate];
		//			 [self.texTask release];
					 self.texTask = nil;
				 }
				 self.texTask = [[NSTask alloc] init];
				 
				 if ([self startTask: self.texTask running: userEnginePath withArgs: args inDirectoryContaining: sourcePath withEngine:whichEngineLocal] == FALSE) {
		//			 [self.inputPipe release];
		//			 [self.outputPipe release];
		//			 [self.texTask release];
					 self.texTask = nil;
				 }
			 }
			}
	useTempEngine = NO;
}


-(void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
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
	fromMenu = YES;
	[self doTex1: sender];
}

- (void) doTex1: sender
{
    
// added by mitsu --(J++) Program popup button indicating Program name
	[programButton selectItemWithTitle: @"Plain TeX"];
    [sprogramButton selectItemWithTitle: @"Plain TeX"];
	[programButtonEE selectItemWithTitle: @"Plain TeX"];
// end addition

	[self doJob:TexEngine withError:YES runContinuously:NO];
}

- (void) doLatex: sender
{
	fromMenu = YES;
	[self doLatex1: sender];
}

- (void) doLatex1: sender
{
    
// added by mitsu --(J++) Program popup button indicating Program name
	[programButton selectItemWithTitle: @"LaTeX"];
    [sprogramButton selectItemWithTitle: @"LaTeX"];
	[programButtonEE selectItemWithTitle: @"LaTeX"];
// end addition
	[self doJob:LatexEngine withError:YES runContinuously:NO];
}

- (void) doUser: (NSInteger)theEngine
{
	fromMenu = NO;
	[programButton selectItemAtIndex:(theEngine - 1)];
    [sprogramButton selectItemAtIndex:(theEngine - 1)];
	[programButtonEE selectItemAtIndex:(theEngine - 1)];
	whichEngine = theEngine;

	[self doJob:whichEngine withError:YES runContinuously:NO];
}

/*
- (void) doContext: sender
{
	fromMenu = YES;
	[self doContext1: sender];
}

- (void) doContext1: sender
{
// added by mitsu --(J++) Program popup button indicating Program name
	[programButton selectItemWithTitle: @"ConTeXt"];
    [sprogramButton selectItemWithTitle: @"ConTeXt"];
	[programButtonEE selectItemWithTitle: @"ConTeXt"];
// end addition
	[self doJob:ContextEngine withError:YES runContinuously:NO];
}
*/

- (void) doMetapost: sender
{
	fromMenu = YES;
	[self doMetapost1: sender];
}

- (void) doMetapost1: sender
{
    
    
// added by mitsu --(J++) Program popup button indicating Program name
	[programButton selectItemWithTitle: @"MetaPost"];
    [sprogramButton selectItemWithTitle: @"MetaPost"];
	[programButtonEE selectItemWithTitle: @"MetaPost"];
// end addition

	[self doJob:MetapostEngine withError:YES runContinuously:NO];
}

- (void) doBibtex: sender
{
    
// added by mitsu --(J++) Program popup button indicating Program name
	// [programButton selectItemWithTitle: @"BibTeX"];
    // [sprogramButton selectItemWithTitle: @"BibTeX"];
	// [programButtonEE selectItemWithTitle: @"BibTeX"];
// end addition
	fromMenu = NO;
	[self doJob:BibtexEngine withError:NO runContinuously:NO];
}

- (void) doIndex: sender
{
    
// added by mitsu --(J++) Program popup button indicating Program name
	// [programButton selectItemWithTitle: @"MakeIndex"];
    // [sprogramButton selectItemWithTitle: @"MakeIndex"];
	// [programButtonEE selectItemWithTitle: @"MakeIndex"];
// end addition
	fromMenu = NO;
	[self doJob:IndexEngine withError:NO runContinuously:NO];
}

- (void) doMetaFont: sender
{
	// fromMenu = YES;
	// [self doMetaFont1: sender];
}

- (void) doMetaFont1: sender
{
// added by mitsu --(J++) Program popup button indicating Program name
	// [programButton selectItemWithTitle: @"MetaFont"];
    // [sprogramButton selectItemWithTitle: @"MetaFont"];
	// [programButtonEE selectItemWithTitle: @"MetaFont"];
// end addition
	// [self doJob:MetafontEngine withError:NO runContinuously:NO];
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
/*
- (void) doContextTemp: sender
{
	[self doJobForScript:ContextEngine withError:YES runContinuously:NO];
}
*/

- (void) doIndexTemp: sender
{
    [self doJobForScript:IndexEngine withError:YES runContinuously:NO];
}

- (void) doMetaFontTemp: sender
{
	// [self doJobForScript:MetafontEngine withError:YES runContinuously:NO];
}

- (void) doTypesetEE: sender
{
    [self doTypeset: sender];
}

- (void) doTypesetForScriptContinuously:(BOOL)method
{
	BOOL	useError;

    fromMenu = NO;
	useError = NO;
	if ((whichEngine == TexEngine) || (whichEngine == LatexEngine) || (whichEngine == MetapostEngine)) // || (whichEngine == ContextEngine))
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
   
    
   if (([sender respondsToSelector: @selector(tag)]) && ([sender tag] == -2))
   {
        [self trashAUXFiles:self];
       
   }

   
   fromMenu = NO;
   useError = NO;
	if ((whichEngine == TexEngine) || (whichEngine == LatexEngine) || (whichEngine == MetapostEngine)) // || (whichEngine == ContextEngine))
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

- (void)doAlternateTypeset: sender
{
    BOOL    useError;

    
    fromAlternate = YES;
    fromMenu = NO;
    useError = NO;
    if ((whichEngine == TexEngine) || (whichEngine == LatexEngine) || (whichEngine == MetapostEngine)) // || (whichEngine == ContextEngine))
        useError = YES;
    if (whichEngine >= UserEngine)
        useError = YES;
// changed by mitsu --(J) Typeset commmand
    [self doJob: whichEngine withError:useError runContinuously:NO];
// end change


}

- (void) doTexCommand: sender
{
	NSData *myData;
	NSString *command;
    
 
	if ((typesetStart) && (self.inputPipe)) {
		command = [[texCommand stringValue] stringByAppendingString:@"\n"];
		command = [self filterBackslashes:command];

		myData = [command dataUsingEncoding: NSISOLatin9StringEncoding allowLossyConversion:YES];
		[self.writeHandle writeData: myData];
		// added by mitsu --(L) reflect tex input and clear tex input field in console window
		NSRange selectedRange = [outputText selectedRange];
		
		selectedRange.location += selectedRange.length;
		selectedRange.length = 0;
		// in the next two lines, replace "command" by "old command" after Japanese modification made -- koch
		[outputText replaceCharactersInRange: selectedRange withString: command];
		selectedRange.length = [command length];
		
		if ([SUD boolForKey: RedConsoleAfterErrorKey]) {
			[outputText setTextColor: [NSColor redColor] range: selectedRange];
			consoleCleanStart = NO;
		}
		
		[outputText scrollRangeToVisible: selectedRange];
		[texCommand setStringValue: @""];
		// end addition

	}
}

- (void)abort:(id)sender
{
    doAbort = YES;
    
	if (! fileIsTex)
		return;
	
    NSEvent *currentEvent = [NSApp currentEvent];
    NSInteger optionKeyPressed = [currentEvent modifierFlags] & NSEventModifierFlagOption;
    
    if (optionKeyPressed)
    {
        // NSLog(@"option pressed in abort");
        [outputText replaceCharactersInRange: [outputText selectedRange] withString:@"\nConsole output killed.\n"];
        [outputText scrollRangeToVisible:[outputText selectedRange]];
        
        [self.readHandle closeFile];
        self.readHandle = nil;
        return;
       // [self.readHandle waitForDataInBackgroundAndNotify];
    }

	/* The lines of code below kill previously running tasks. This is
	necessary because otherwise the source file will be open when the
	system tries to save a new version. If the source file is open,
	NSDocument makes a backup in /tmp which is never removed. */


   // [outputText setSelectable: YES];
   // [outputText selectAll:self];
	[outputText replaceCharactersInRange: [outputText selectedRange] withString:@"\nProcess aborted\n"];
	[outputText scrollRangeToVisible:[outputText selectedRange]];
	
	// NSString *theString = @"very strange\n"; 
	// NSData *theData = [theString dataUsingEncoding: NSASCIIStringEncoding];
	// [[inputPipe fileHandleForWriting] writeData: theData ];
	
    [outputText setSelectable: YES];

	taskDone = YES;

	[self killRunningTasks];

//	[self.inputPipe release];
	self.inputPipe = 0;
}


// The two routines below run after each Task exits. The crucial tasks are texTask, indexTask, bibTask, metafontTask. For these
// the system uses the new NSTask API for High Sierra and above, including a TerminationHandler. This handler then calls
// "checkATaskStatusFromTerminationRoutine" to clean up for texTask, indexTask, bibTask, and metafontTask.
//
// Until 2018, we did not use a TerminationHandler, and instead relied on NSTaskDidTerminateNotification, which was handled by
// "checkATaskStatus", one routine below. This still holds for many tasks: displayPackageHelpTask (calling texdoc to display
// documentation, scrapTask (to handle the "Experiment" menu item, detexTask (to find statistics for a source), convertTask (to
// convert tiff to pdf), and scriptTask (to run Applescript). All of these tasks still use the old NSTask API and call "checkATaskStatus".
// However, in most cases "checkATaskStatus" does nothing or very little. It only directly handles scrapTask and thus "Experiment".
// All other tasks are sent to checkATaskStatusFromTerminationRoutine, but this routine really does something significant only
// for the key tasks sent there directly from the TerminationHandler.

- (void)checkATaskStatusFromTerminationRoutine: (NSTask *)theTask
{
    NSString        *imagePath, *htmlImagePath;
    NSString        *alternatePath;
    NSDictionary    *myAttributes;
    NSDate            *endDate;
    NSInteger                status;
    BOOL            alreadyFound;
    BOOL            front;
    BOOL            DisplayLogs, MainLogs;
    BOOL            doPDF, doHTML;
    NSString        *newURL, *theRevisedURL;
    NSURL           *theURL;
    NSURLRequest    *theRequest;
    NSURL           *existingURL;
    
    // Crucial note: I now know that when the bug occurs, this routine is called,
    // possibly with terminationStatus = 13
    
    // MainLogs = [SUD boolForKey: DisplayLogInfoKey];
    // Not needed since "sudden halt" bug is fixed
    MainLogs = NO;
    
    if (MainLogs)
        NSLog(@"checkATaskStatusFromTerminationRoutine");
    if (theTask != nil){
        if (MainLogs)
            NSLog(theTask.launchPath);
        if (MainLogs)
            NSLog(@"The status is %d:", [theTask terminationStatus]);
 //       if ([theTask terminationStatus] == 13)
 //           return;
    }
    
    // DisplayLogs = ([SUD boolForKey: DisplayLogInfoKey] && [SUD boolForKey: UseTerminationHandlerKey]);
    // Not needed since "sudden halt" bug is fixed
    DisplayLogs = NO;

//    if (DisplayLogs)
//    {
//        NSLog(@"CheckATaskStatusNew");
//        if (theTask != nil)
//            NSLog(theTask.launchPath);
//    }
    
//    status = [theTask terminationStatus];
//    [outputText setSelectable: YES];
//    taskDone = YES;  // for Applescript
    
    // Key Point: This routine does nothing else except for bibTask, indexTask, metaFontTask, and texTask
    
    if ((theTask == self.bibTask) || (theTask == self.indexTask) || (theTask == self.metaFontTask)) {
        if (self.inputPipe == [theTask standardInput]) {
            //        [self.outputPipe release];
            [self.writeHandle closeFile];
            //        [self.inputPipe release];
            self.inputPipe = 0;
        }
            if (theTask == self.bibTask) {
                [self.bibTask terminate];
                //            [self.bibTask release];
                self.bibTask = nil;
            } else if (theTask == self.indexTask) {
                [self.indexTask terminate];
                //            [self.indexTask release];
                self.indexTask = nil;
            } else if (theTask == self.metaFontTask) {
                [self.metaFontTask terminate];
                //            [self.metaFontTask release];
                self.metaFontTask = nil;
            }
        }
    
    if (theTask == self.backwardSyncTask)
        [self finishBackwardContextSync];
    
    if (theTask == self.backwardSyncTaskExternal)
        [self finishBackwardContextSyncExternal];
    
    if (theTask == self.forwardSyncTask)
        [self finishForwardContextSync];
   
    [outputText setSelectable: YES];
    taskDone = YES; // for Applescript
    
    if (theTask != self.texTask)
    { //  NSLog(@"not tex task, %l and %l", theTask, self.texTask);
        return;
    }
    
 //   [outputText setSelectable: YES];
 //   taskDone = YES;  // for Applescript
    
    if (self.inputPipe == [theTask standardInput]) {
        status = [theTask terminationStatus];
        
        if ((status == 0) || (status == 1))  {
            
            doPDF = NO; doHTML = NO;
            if ((self.PreviewType == 0) || (self.PreviewType == 2) || (self.PreviewType == 4))
                doPDF = YES;
            if ((self.PreviewType == 3) || (self.PreviewType == 4))
                doHTML = YES;
            
            imagePath = [[[[self fileURL] path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
            htmlImagePath = [[[[self fileURL] path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"html"];
            if (doPDF)
            {
            alreadyFound = NO;
            if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) {
                myAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath: imagePath error:NULL];
                endDate = [myAttributes objectForKey:NSFileModificationDate];
                if ((self.startDate == nil) || ! [self.startDate isEqualToDate: endDate]) {
                    alreadyFound = YES;
                    PDFfromKit = YES;
                    [self.myPDFKitView reShowWithPath: imagePath];
                    [self.myPDFKitView2 prepareSecond];
                    // [[self.myPDFKitView document] retain];
                    [self.myPDFKitView2 setDocument: [self.myPDFKitView document]];
                    [self.myPDFKitView2 reShowForSecond];
                    if (! useFullSplitWindow) {
                        [self.pdfKitWindow setRepresentedFilename: imagePath];
                        //[pdfKitWindow setTitle: [imagePath lastPathComponent]]; // removed by Terada
                        [self.pdfKitWindow setTitle: [[[self fileTitleName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"]]; // removed by Terada
                        [self fillLogWindowIfVisible];
                        front = [SUD boolForKey: BringPdfFrontOnTypesetKey];
                        if ((front) || (! [self.pdfKitWindow isVisible]))
                            [self.pdfKitWindow makeKeyAndOrderFront: self];
                        {
                            if (self.useOldSyncParser)
                                [self allocateSyncScannerOld];
                            else if (! self.useConTeXtSyncParser)
                                [self allocateSyncScanner];
                        }
                    }
                    else {
                        [self fillLogWindowIfVisible];
                        front = [SUD boolForKey: BringPdfFrontOnTypesetKey];
                        if (front) {
                            [fullSplitWindow makeKeyAndOrderFront: self];
                            [fullSplitWindow makeFirstResponder:self.myPDFKitView];
                        }
                        {
                            if (self.useOldSyncParser)
                                [self allocateSyncScannerOld];
                            else if (! self.useConTeXtSyncParser)
                                [self allocateSyncScanner];
                        }
                        
                    }
                   
            // Koch 2022 The following is a fix for VoiceOver in the Preview Window on Monterey
                  
                    if (self.activateVoiceOverFix)
                    {
                        SEL fixSelector = @selector(voiceOverFix);
                        [self performSelector: fixSelector withObject: self afterDelay: 1];
                    }
                   
                }
            }
            
            if (! alreadyFound)  { // see if there is a temporary file
                alternatePath = [[TempOutputKey stringByAppendingString:@"/"] stringByAppendingString:[imagePath lastPathComponent]];
                if ([[NSFileManager defaultManager] fileExistsAtPath: alternatePath]) {
                    self.texRep = [NSPDFImageRep imageRepWithContentsOfFile: alternatePath] ;
                    [[NSFileManager defaultManager] removeItemAtPath: alternatePath error:NULL];
                    if (self.texRep) {
                        [pdfWindow setTitle: [imagePath lastPathComponent]];
                        [pdfView setImageRep: self.texRep];
                        [pdfView setNeedsDisplay:YES];
                        [pdfWindow makeKeyAndOrderFront: self];
                    }
                }
                
            }
            }
            
            if (doHTML)
            {
                alreadyFound = NO;
                NSString *htmlImagePath1 = [htmlImagePath stringByAppendingString:@"'"];
                newURL = [@"file://'" stringByAppendingString: htmlImagePath1];
                 
               //  NSLog(htmlImagePath);
               //  NSLog(newURL);
                
                // theURL = [NSURL URLWithString: newURL];
                theURL = [NSURL fileURLWithPath: htmlImagePath isDirectory: NO];
                
                existingURL = [self.htmlView URL];
                
                 
                if ((existingURL != nil) && ([theURL isEqual: existingURL]))
                        
                        {
                        [self.htmlView reload];
                        [self.htmlWindow makeKeyAndOrderFront: self];
                        }
                    else
                    {
                        theRequest = [NSURLRequest requestWithURL: theURL];
                        [self.htmlView loadRequest: theRequest];
                        self.htmlView.allowsMagnification = YES;
                        [self.htmlWindow makeKeyAndOrderFront: self];
                    }
                }
                
 
                    
            
            [self.texTask terminate];
            //        [self.texTask release];
        }
        
        //    [self.outputPipe release];
        [self.writeHandle closeFile];
        //    [self.inputPipe release];
        self.inputPipe = 0;
        self.texTask = nil;
        
    }
    self.PreviewType = 0;
}

- (void)checkATaskStatus:(NSNotification *)aNotification
{
	NSInteger		status;
   NSError         *error;
    BOOL            DisplayLogs, MainLogs;
    
    // MainLogs = [SUD boolForKey: DisplayLogInfoKey];
    // Not needed since "sudden halt" bug is fixed
    MainLogs = NO;
    
    if (MainLogs)
        NSLog(@"checkATaskStatus");
    
    // DisplayLogs = ([SUD boolForKey: DisplayLogInfoKey] && [SUD boolForKey: UseTerminationHandlerKey]);
    // Not needed since "sudden halt" bug is fixed
    DisplayLogs = NO;
    
    if (DisplayLogs)
        NSLog(@"CheckATaskStatus");
    
    
   if ([aNotification object] == self.scrapTask)
    {
    if (DisplayLogs)
        NSLog(@"Doing Scrap Task");
    error = nil;
    //  [[NSFileManager defaultManager] removeItemAtURL:self.scrapDirectoryURL error:&error];
    self.scrapDirectoryURL = nil;
    [outputText setSelectable: YES];
    status = [[aNotification object] terminationStatus];
    [self.writeHandle closeFile];
    self.inputPipe = 0;
    self.scrapTask = nil;
    
    if ((status == 0) || (status == 1)) {
        
        if ([[NSFileManager defaultManager] fileExistsAtPath: self.scrapImagePath])
            [scrapPDFKitView reShowWithPath: self.scrapImagePath];
        
        [scrapPDFWindow setHidesOnDeactivate:YES];
        [scrapPDFWindow makeKeyAndOrderFront:self];
        
    }
    
    self.scrapImagePath = nil;
    }

else
       [self checkATaskStatusFromTerminationRoutine: [aNotification object]];
    
    
/*
    
    status = [[aNotification object] terminationStatus];
    // NSLog(@"The termination status is %d", (int) status);

	[outputText setSelectable: YES];
    // [texCommand setSelectable: NO];
    // [outputText setEditable: YES];
    
    // [outputText setEditable: YES];

	if (([aNotification object] == self.bibTask) || ([aNotification object] == self.indexTask) || ([aNotification object] == self.metaFontTask)) {
		if (self.inputPipe == [[aNotification object] standardInput]) {
	//		[self.outputPipe release];
			[self.writeHandle closeFile];
	//		[self.inputPipe release];
			self.inputPipe = 0;
			if ([aNotification object] == self.bibTask) {
				[self.bibTask terminate];
	//			[self.bibTask release];
				self.bibTask = nil;
			} else if ([aNotification object] == self.indexTask) {
				[self.indexTask terminate];
	//			[self.indexTask release];
				self.indexTask = nil;
			} else if ([aNotification object] == self.metaFontTask) {
				[self.metaFontTask terminate];
	//			[self.metaFontTask release];
				self.metaFontTask = nil;
			}
		}
	}

	taskDone = YES;  // for Applescript

	if ([aNotification object] != self.texTask)
		return;

	if (self.inputPipe == [[aNotification object] standardInput]) {
		status = [[aNotification object] terminationStatus];

		if ((status == 0) || (status == 1))  {
			imagePath = [[[[self fileURL] path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];

			alreadyFound = NO;
			if ([[NSFileManager defaultManager] fileExistsAtPath: imagePath]) {
				myAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath: imagePath error:NULL];
				endDate = [myAttributes objectForKey:NSFileModificationDate];
				if ((self.startDate == nil) || ! [self.startDate isEqualToDate: endDate]) {
					alreadyFound = YES;
					PDFfromKit = YES;
					[self.myPDFKitView reShowWithPath: imagePath];
					[self.myPDFKitView2 prepareSecond];
					// [[self.myPDFKitView document] retain];
					[self.myPDFKitView2 setDocument: [self.myPDFKitView document]];
					[self.myPDFKitView2 reShowForSecond];
                    if (! useFullSplitWindow) {
                        [self.pdfKitWindow setRepresentedFilename: imagePath];
                        //[pdfKitWindow setTitle: [imagePath lastPathComponent]]; // removed by Terada
                        [self.pdfKitWindow setTitle: [[[self fileTitleName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"]]; // removed by Terada
                        [self fillLogWindowIfVisible];
                        front = [SUD boolForKey: BringPdfFrontOnTypesetKey];
                        if ((front) || (! [self.pdfKitWindow isVisible]))
                            [self.pdfKitWindow makeKeyAndOrderFront: self];
                        {
                            if (self.useOldSyncParser)
                                [self allocateSyncScannerOld];
                            else if (! self.useConTeXtParser)
                                [self allocateSyncScanner];
                        }
                        }
                    else {
                        [self fillLogWindowIfVisible];
                        front = [SUD boolForKey: BringPdfFrontOnTypesetKey];
                        if (front) {
                            [fullSplitWindow makeKeyAndOrderFront: self];
                            [fullSplitWindow makeFirstResponder:self.myPDFKitView];
                        }
                        {
                            if (self.useOldSyncParser)
                                [self allocateSyncScannerOld];
                            else if (! self.useConTeXtSyncParser)
                                [self allocateSyncScanner];
                        }
                        
                    }
				}
			}

			if (! alreadyFound)  { // see if there is a temporary file
				alternatePath = [[TempOutputKey stringByAppendingString:@"/"] stringByAppendingString:[imagePath lastPathComponent]];
				if ([[NSFileManager defaultManager] fileExistsAtPath: alternatePath]) {
					self.texRep = [NSPDFImageRep imageRepWithContentsOfFile: alternatePath] ;
					[[NSFileManager defaultManager] removeItemAtPath: alternatePath error:NULL];
					if (self.texRep) {
						[pdfWindow setTitle: [imagePath lastPathComponent]];
						[pdfView setImageRep: self.texRep];
						[pdfView setNeedsDisplay:YES];
						[pdfWindow makeKeyAndOrderFront: self];
					}
				}

			}
			[self.texTask terminate];
	//		[self.texTask release];
		}

	//	[self.outputPipe release];
		[self.writeHandle closeFile];
	//	[self.inputPipe release];
		self.inputPipe = 0;
		self.texTask = nil;
	}
*/
}

- (BOOL) getWillClose
{
	return willClose;
}

- (void) setWillClose: (BOOL)value
{
	willClose = value;
}



@end
