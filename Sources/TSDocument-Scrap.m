/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2014 Richard Koch
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
 * $Id: TSDocument-Jobs.m 254 2014-06-28 21:09:25Z fingolfin $
 *
 */

#import "UseMitsu.h"

#import "TSDocument.h"
#import "TSTextView.h"

#import "MyPDFView.h"
#import "MyPDFKitView.h"

#import "globals.h"

#import "TSWindowManager.h"
#import "TSEncodingSupport.h"
#import "NSText-Extras.h"



@implementation TSDocument (Scrap)


- (NSString *)getFilePath
{
    NSDocument  *theDocument;
    NSURL       *sourceURL;
    
    if (self.rootDocument != nil)
        theDocument = self.rootDocument;
    else
        theDocument = self;
    sourceURL = theDocument.fileURL;
    if (sourceURL == nil)
        return nil;
    else
        return [sourceURL path];
}

- (void) tryScrap:(id)sender
{
    BOOL        spellExists;
    NSString    *newTitle;
    
    if ([self getFilePath] == nil)
        return;
    
    NSString *selectedStuff;
    NSArray *ranges = [textView selectedRanges];
    if ([ranges count] > 0)
        {
            selectedStuff = [[textView string] substringWithRange: [ranges[0] rangeValue]];
            if ([selectedStuff length] > 0)
              scrapTextView.string = selectedStuff;
        }
    
    scrapTextView.document = self;
    [scrapTextView setAllowsUndo: YES];
    [scrapTextView setRichText: NO];
    [scrapTextView setAutomaticQuoteSubstitutionEnabled:NO];
    [scrapTextView setAutomaticLinkDetectionEnabled:NO];
    [scrapTextView setAutomaticDashSubstitutionEnabled:NO];
    [scrapTextView setUsesRuler:NO];
 
    NS_DURING
    NSSpellChecker *myChecker = [NSSpellChecker sharedSpellChecker];
    spellExists = (myChecker != 0);
	NS_HANDLER
    spellExists = NO;
	NS_ENDHANDLER
    if (spellExists) {
		[scrapTextView setContinuousSpellCheckingEnabled:[SUD boolForKey:SpellCheckEnabledKey]];
        [scrapTextView setAutomaticSpellingCorrectionEnabled:[SUD boolForKey:AutomaticSpellingCorrectionEnabledKey]];
        }
    
    if ([SUD boolForKey:SaveDocumentFontKey] == YES)
        {
        NSData	*fontData;
        NSFont 	*font;
        
        fontData = [SUD objectForKey:DocumentFontKey];
        if (fontData != nil)
            {
            font = [NSUnarchiver unarchiveObjectWithData:fontData];
            [scrapTextView setFontSafely:font];
            }
        }

    if ([textWindow title])
        newTitle = [[textWindow title] stringByDeletingPathExtension];
    else
        newTitle = @"Experiment";
    [scrapWindow setTitle: newTitle];
    [scrapPDFWindow setTitle: newTitle];
    [scrapWindow setHidesOnDeactivate:YES];
    [scrapWindow makeKeyAndOrderFront:sender];
}


- (IBAction) typesetScrap:(id)sender
{
    NSString            *theSource, *theHeader, *newSource;
    NSRange             beginDoc, header, lineheader;
    NSData              *theData;
    NSError             *error;
    NSString            *filePath, *fileLocation;
    TSDocument          *theDocument;
    NSStringEncoding    encoding;

    filePath = [self getFilePath];
    if (filePath == nil)
        return;
    fileLocation = [filePath stringByDeletingLastPathComponent];
    
    if (self.rootDocument != nil)
        theDocument = self.rootDocument;
    else
        theDocument = self;
    self.scrapMenuEngine = [[theDocument programButton] titleOfSelectedItem];
    self.scrapDVI = [theDocument useDVI];
    
    theSource = [[theDocument textView] string];
    
     
    beginDoc = [theSource rangeOfString: @"\\begin{document}"];
    if (beginDoc.location == NSNotFound)
       return;
    
    header.location = 0;
    header.length = beginDoc.location - 1;
    lineheader = [theSource lineRangeForRange: header];
    theHeader = [theSource substringToIndex: lineheader.length];
    newSource = [theHeader stringByAppendingString:@"\\begin{document}\n"];
    newSource = [newSource stringByAppendingString: [scrapTextView string]];
    newSource = [newSource stringByAppendingString:@"\n\\end{document}\n"];
 
    // get encoding and use it to write the file
    [self searchFile: newSource];
    if (self.scrapEncoding != nil)
        encoding = [[TSEncodingSupport sharedInstance] stringEncodingForKey: self.scrapEncoding];
    else
        encoding = _encoding;
   theData = [newSource dataUsingEncoding:encoding];
    
 
// The following code comes from http://nshipster.com/nstemporarydirectory/
    
    self.scrapDirectoryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:self.scrapDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error];
    NSURL *fileURL = [self.scrapDirectoryURL URLByAppendingPathComponent:@"file.tex"];
    
    error = nil;
    [theData writeToURL:fileURL options:NSDataWritingAtomic error:&error];
    
    [self typesetFile: fileURL withAdditionalPath:fileLocation];
    
}

- (NSDictionary *)environmentWithNewPath: (NSString *)additionalPath;
{
	NSMutableDictionary *env;
    
    
	// get copy of environment and add the preferences paths
	env = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
    
    
	// Customize 'PATH'
    NSMutableString *inputs;
    NSMutableString *path;
	path = [NSMutableString stringWithString: [env objectForKey:@"PATH"]];
	[path appendString:@":"];
	[path appendString:[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath]];
	[path appendString:@":"];
	[path appendString:[SUD stringForKey:GSBinPath]];
    [path appendString:@":"];
    [path appendString:additionalPath];
	[env setObject: path forKey: @"PATH"];
    inputs = [NSMutableString stringWithString: @".:"];
    [inputs appendString:additionalPath];
    [inputs appendString:@":"];
    [env setObject: inputs forKey: @"TEXINPUTS"];
    
    
 /*
	// Set 'TEXEDIT' env var (see the 'tex' man page for details). We construct a simple shell
	// command, which first (re)opens the document, and then uses osascript to run an AppleScript
	// which selects the right line. The AppleScript looks like this:
	//   tell application "TeXShop"
	//       goto document 1 line %d
	//       activate
	//   end tell
	NSMutableString *script = [NSMutableString string];
    
#warning 64BIT: Check formatting arguments
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

- (void)searchFile: (NSString *)theSource
{
    NSUInteger  length, start, end, irrelevant, offset;
    BOOL        programDone, encodingDone;
    NSRange     myRange, theRange;
    NSRange     programRange, encodingRange, newProgramRange, newEncodingRange;
    NSUInteger  linesTested;
    NSString    *testString;
    
    self.scrapEncoding = nil;
    self.scrapProgram = nil;
    
    length = [theSource length];
    programDone = NO; encodingDone = NO;
    linesTested = 0;
    myRange.location = 0;
    myRange.length = 1;
   
    while ((myRange.location < length) && (linesTested < 20) && ((! programDone) || (! encodingDone))) {
        
        [theSource getLineStart: &start end: &end contentsEnd: &irrelevant forRange: myRange];
        myRange.location = end;
        myRange.length = 1;
        linesTested++;
        
        theRange.location = start; theRange.length = (end - start);
        testString = [theSource substringWithRange: theRange];
        
        if (! programDone) {
            
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
                    self.scrapProgram = [[[testString substringWithRange: newProgramRange]
                                          stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
                    programDone = YES;
                    }
                }
            }
        
        if (! encodingDone) {
            
            encodingRange = [testString rangeOfString:@"%!TEX encoding ="];
            offset = 16;
            if (encodingRange.location == NSNotFound) {
                encodingRange = [testString rangeOfString:@"% !TEX encoding ="];
                offset = 17;
			}
            
            if (encodingRange.location != NSNotFound) {
                NSLog(@"also got here");
                newEncodingRange.location = encodingRange.location + offset;
                newEncodingRange.length = [testString length] - newEncodingRange.location;
                if (newEncodingRange.length > 0) {
                    self.scrapEncoding = [[testString substringWithRange: newEncodingRange]
                                     stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    // encodingString = [programString lowercaseString];
                    encodingDone = YES;
                }
            }
        }
    }
	
    
    
    
}

- (NSString*)absoluteEnginePath:(NSString*)enginePath
{
    NSString *absolutePath = [enginePath stringByExpandingTildeInPath];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:absolutePath isDirectory:nil]){
        absolutePath = [[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath] stringByAppendingPathComponent:enginePath];
    }
    
    return absolutePath;
}






- (void)typesetFile: (NSURL *)fileURL withAdditionalPath: (NSString *)additionalPath
{
    
    NSString        *sourcePath;
    NSMutableArray  *args;
    NSString        *enginePath;
    NSDictionary    *env;
    NSString        *userEngine;
    NSString        *tetexBinPath;
    NSString        *argString;
    NSString        *tempPath;
    NSString        *theProgramWithFlags;
    
     [self killRunningTasks];
    
    env = [self environmentWithNewPath: additionalPath];
    
    sourcePath = [fileURL path];
    
    self.scrapImagePath = [[sourcePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
    
    args = [NSMutableArray array];
    
    self.outputPipe = [NSPipe pipe];
    self.readHandle = [self.outputPipe fileHandleForReading];
    [self.readHandle readInBackgroundAndNotify];
    self.inputPipe = [NSPipe pipe];
    self.writeHandle = [self.inputPipe fileHandleForWriting];
    
    consoleCleanStart = YES;
    [outputText setSelectable: YES];
    [outputText selectAll:self];
    [outputText replaceCharactersInRange: [outputText selectedRange] withString:@""];
    [texCommand setStringValue:@""];
    [outputText setSelectable: NO];
    typesetStart = NO;
    [outputWindow makeFirstResponder: texCommand];
    [outputWindow setTitle: [[[self.scrapImagePath lastPathComponent] stringByDeletingPathExtension]
                             stringByAppendingString:@" console"]];
    if ([SUD boolForKey:ConsoleBehaviorKey]) {
        if (![outputWindow isVisible])
            [outputWindow orderBack: self];
    } else {
        if ([SUD boolForKey: BringPdfFrontOnTypesetKey])
            [outputWindow makeKeyAndOrderFront: self];
        else
            [outputWindow orderFront: self]; 
    }
    
    // Note: the NSDocument variable whichScript is set to 100 for pdflatex, 101 for tex + dvi and 102 for personal script
    // Note: scrapMenuEngine is the engine in the pulldown menu next to Typeset in the source toolbar
    // Note; scrapProgram is the program set via "% !TeXShop program = "
    // Note: Therefore if scrapMenuEngine is active and "latex", then whichScript should set the typeset job to
    //       pdflatex, latex, or personallatex depending on whichScript
    
    // get program and use it to typeset the file
    // first get program selected in pulldown menu
    if (self.scrapProgram == nil)
        {
        userEngine = [[self.scrapMenuEngine stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
        if ([userEngine isEqualToString: @"latex"])
            {
            if (whichScript == 102)
                userEngine = @"personallatex";
            else if (whichScript == 101)
                userEngine = @"latex";
            else
                userEngine = @"pdflatex";
            }
        }
     else
        userEngine = self.scrapProgram;
            
         
    if ([userEngine isEqualToString: @"plaintex"])
                      return;
    else if ([userEngine isEqualToString: @"tex"])
                      return;
    else if ([userEngine isEqualToString: @"metapost"])
                      return;
    else if ([userEngine isEqualToString: @"context"])
                      return;
    else if ([userEngine isEqualToString: @"personaltex"])
                      return;
    // else if ([userEngine isEqualToString: @"personallatex"])
    //                  userEngine = @"pdflatex";
    else if ([userEngine isEqualToString: @"bibtex"])
                      userEngine = @"pdflatex";
    else if ([userEngine isEqualToString: @"makeindex"])
                      userEngine = @"pdflatex";
    
    self.scrapTask = [[NSTask alloc] init];
    
//  Fixed to use settings in Preferences RMK
    
//  LatexScriptCommandKey
    
    if ([userEngine isEqualToString:@"personallatex"]) {
        NSLog(@"got here");
        theProgramWithFlags = [[SUD stringForKey: LatexScriptCommandKey] stringByExpandingTildeInPath];
        enginePath = [self separate:theProgramWithFlags into:args];
        // [args addObject: [sourcePath lastPathComponent]];
        // tetexBinPath = [[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath] stringByAppendingString:@"/"];
        // enginePath = [tetexBinPath stringByAppendingString: enginePath];
        enginePath = [self absoluteEnginePath:enginePath];
        [args addObject: [sourcePath lastPathComponent]];
        }
    
// LatexCommandKey

    else if ([userEngine isEqualToString:@"pdflatex"]) {
        theProgramWithFlags = [[SUD stringForKey: LatexCommandKey] stringByExpandingTildeInPath];
        enginePath = [self separate:theProgramWithFlags into:args];
          //  [args addObject: [sourcePath lastPathComponent]];
          //   tetexBinPath = [[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath] stringByAppendingString:@"/"];
          //   enginePath = [tetexBinPath stringByAppendingString: enginePath];
        enginePath = [self absoluteEnginePath:enginePath];
        [args addObject: [sourcePath lastPathComponent]];
        }

// LatexGSCommandKey
    
    else if ([userEngine isEqualToString:@"latex"]) {
            theProgramWithFlags = [[SUD stringForKey: LatexGSCommandKey] stringByExpandingTildeInPath];
            enginePath = [self separate:theProgramWithFlags into:args];
            //tetexBinPath = [[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath] stringByAppendingString:@"/"];
            //enginePath = [tetexBinPath stringByAppendingString: enginePath];
            //[args addObject: sourcePath];;
            enginePath = [self absoluteEnginePath:enginePath];
            [args addObject: sourcePath];
            }
    
//  End of fix RMK
                      
    else {
            tempPath = [EnginePath stringByExpandingTildeInPath];
            enginePath = [[[tempPath stringByAppendingString:@"/"] stringByAppendingString: userEngine] stringByAppendingString:@".engine"];
            [args addObject: sourcePath];
            }

    [self.scrapTask setLaunchPath: enginePath];
	[self.scrapTask setArguments: args];
	[self.scrapTask setCurrentDirectoryPath: [sourcePath stringByDeletingLastPathComponent]];
	[self.scrapTask setEnvironment: env];
	[self.scrapTask setStandardOutput: self.outputPipe];
	[self.scrapTask setStandardError: self.outputPipe];
	[self.scrapTask setStandardInput: self.inputPipe];
	[self.scrapTask launch];

}

- (void)checkScrapTaskStatus:(NSNotification *)notification
{
     NSInteger		status;
     NSError         *error;
    
   // return;
    
    if ([notification object] != self.scrapTask)
        return;
    
    error = nil;
  //  [[NSFileManager defaultManager] removeItemAtURL:self.scrapDirectoryURL error:&error];
    self.scrapDirectoryURL = nil;
    [outputText setSelectable: YES];
    status = [[notification object] terminationStatus];
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


@end
