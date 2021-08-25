//
//  HelpDocuments.m
//  TeXShop
//
//  Created by Richard Koch on 7/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "HelpDocuments.h"
#import "TSDocumentController.h"
#import "globals.h"
#import "TSDocument.h"
#import "TSTextEditorWindow.h"
#import "TSPreviewWindow.h"

@interface HelpDocuments (Private)

- (void)mirrorPath:(NSString *)srcPath toPath:(NSString *)dstPath;

@end

@implementation HelpDocuments

- (id)init
{
	if ((self = [super init])) {
		displayPackageHelpTask = nil;
	}
	
	return self;
}

- (void)displayFile:(NSString *)fileName
{
	TSDocumentController	*myController;
	NSURL					*myURL;
	NSError					*outError;
	TSDocument				*myDocument;
 	
	myURL = [NSURL fileURLWithPath: fileName];
	myController = [TSDocumentController sharedDocumentController];
	myDocument = [myController documentForURL: myURL];
	if (myDocument != nil) {
        // NSLog(@"here");
		[myDocument.pdfKitWindow makeKeyAndOrderFront:self];
    }
	else {
        // NSLog(@"there");
		[myController listDocument:NO];
		[myController openDocumentWithContentsOfURL: myURL display: YES error:&outError];
        // [[myController openDocumentWithContentsOfURL: myURL display: YES completionHandler: nil];
		[myController listDocument:YES];
		}
}

- (IBAction)displayThisRelease:sender
{
	NSString				*fileName;
	
	fileName = [[NSBundle mainBundle] pathForResource:@"About This Release" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayChanges:sender
{
    NSString                *fileName;
    
    fileName = [[NSBundle mainBundle] pathForResource:@"Changes" ofType:@"pdf"];
    [self displayFile: fileName];
}

- (IBAction)displayTeXLiveDocumentation:sender
{
    NSString                *fileName;
    
    fileName = [[NSBundle mainBundle] pathForResource:@"TeXLiveDocumentation" ofType:@"pdf"];
    [self displayFile: fileName];
}


- (IBAction)displayCommentLines:sender
{
    NSString                *fileName;
    
    fileName = [[NSBundle mainBundle] pathForResource:@"CommentLines" ofType:@"pdf"];
    [self displayFile: fileName];
}



- (IBAction)displayGettingStartedTeXShop:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"First Steps with TeXShop" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayGPLLicense:sender
{
    NSString				*fileName;
    
    fileName = [[NSBundle mainBundle] pathForResource:@"GPLv2 License" ofType:@"pdf"];
    [self displayFile: fileName];
}

- (IBAction)displayFileEncoding:sender
{
    NSString				*fileName;
    
    fileName = [[NSBundle mainBundle] pathForResource:@"File Encoding" ofType:@"pdf"];
    [self displayFile: fileName];
}

- (IBAction)displayTipsandTricks:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"TeXShop Tips & Tricks" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayTeXShopConfusion:sender
{
    NSString				*fileName;
    
    fileName = [[NSBundle mainBundle] pathForResource:@"TeXShop Feature Confusion" ofType:@"pdf"];
    [self displayFile: fileName];
}


- (IBAction)displayRecentTeXFonts:sender;
{
    NSString				*fileName;
    
    fileName = [[NSBundle mainBundle] pathForResource:@"RecentTexFonts" ofType:@"pdf"];
	[self displayFile: fileName];
}


- (IBAction)displayNotesonApplescript:sender
{
    NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"Notes on Applescript in TeXShop" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayGettingStartedLatex:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"First Steps with Mathematical Typesetting" ofType:@"pdf"];
	[self displayFile: fileName];
}

// Currently not enabled in interface
- (IBAction)displayGettingStartedConTeXt:sender
{
}

- (IBAction)displayGettingStartedXeTeX:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"First Steps with General Typesetting" ofType:@"pdf"];
	[self displayFile: fileName];

}

- (IBAction)displayShortCourse:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"ShortCourse" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayHelpForPackage:sender
{
	NSDate				*myDate;
	NSString			*packageString;
	NSMutableArray		*args;
	NSMutableDictionary	*env;
	NSString		*path, *enginePath;
	NSInteger					result;
    
	result = [NSApp runModalForWindow: packageHelpPanel];
	// [packageHelpPanel close];
	if (result == 0) {
		packageString = [packageResult stringValue];
        [packageHelpPanel close];
    }
	else {
        [packageHelpPanel close];
        return;
    }
    
	if ([packageString isEqualToString:@""])
		return;
    
    packageString = [packageString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([packageString isEqualToString:@""])
        return;
	
	if (displayPackageHelpTask != nil) {
		[displayPackageHelpTask terminate];
		myDate = [NSDate date];
		while (([displayPackageHelpTask isRunning]) && ([myDate timeIntervalSinceDate:myDate] < 0.5)) ;
	//	[displayPackageHelpTask release];
		displayPackageHelpTask = nil;
	}
	
	enginePath = [[NSString stringWithString:[SUD stringForKey:TetexBinPath]] stringByExpandingTildeInPath];
	enginePath = [enginePath stringByAppendingString:@"/texdoc"];
	
	// get copy of environment and add the preferences paths
	env = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
	path = [NSString stringWithString: [env objectForKey:@"PATH"]];
	path = [path stringByAppendingString:@":"];
	// [path appendString:[SUD stringForKey:TetexBinPath]];
	path = [path stringByAppendingString:[[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath]];
 	[env setObject: path forKey: @"PATH"];
	
	
	displayPackageHelpTask = [[NSTask alloc] init];
	[displayPackageHelpTask setLaunchPath:enginePath];
	args = [NSMutableArray array];
	[args addObject: packageString];
	[displayPackageHelpTask setArguments:args];
	[displayPackageHelpTask setEnvironment:env];
	[displayPackageHelpTask launch];
}

- (IBAction)displayStyleFile:sender
{
	// added by Terada (- (void) displayStyleFile:)
		
		NSString			*target;

/*
		NSSize dialogSize = NSMakeSize(340, 120);
		NSRect dialogRect = NSMakeRect(0, 0, dialogSize.width, dialogSize.height);
		
		NSWindow *dialog = [[[NSWindow alloc] initWithContentRect:dialogRect
														styleMask:(NSTitledWindowMask|NSResizableWindowMask)
														  backing:NSBackingStoreBuffered 
															defer:NO] autorelease];
		[dialog setFrame:dialogRect display:NO];
		[dialog setMinSize:NSMakeSize(250, dialogSize.height)];
		[dialog setMaxSize:NSMakeSize(10000, dialogSize.height)];
		[dialog setTitle:NSLocalizedString(@"Input Stylefile Name to Open", @"Input Stylefile Name to Open")];
		
		NSTextField *input = [[[NSTextField alloc] init] autorelease];
		[input setFrame:NSMakeRect(17, 54, dialogSize.width - 40, 25)];
		NSString *lastStyName = [SUD stringForKey:LastStyNameKey];
		lastStyName = (!lastStyName || [lastStyName isEqualToString:@""]) ? @"latex.ltx" : lastStyName;
		[input setStringValue:lastStyName];
		[input setAutoresizingMask:NSViewWidthSizable];
		[[dialog contentView] addSubview:input];
		
		NSButton* cancelButton = [[[NSButton alloc] init] autorelease];
		[cancelButton setTitle:NSLocalizedString(@"Cancel", @"Cancel")];
		[cancelButton setFrame:NSMakeRect(dialogSize.width - 206, 12, 96, 32)];
		[cancelButton setBezelStyle:NSRoundedBezelStyle];
		[cancelButton setAutoresizingMask:NSViewMinXMargin];
		[cancelButton setKeyEquivalent:@"\033"];
		[cancelButton setTarget:self];
		[cancelButton setAction:@selector(dialogCancel:)];
		[[dialog contentView] addSubview:cancelButton];
		
		NSButton* okButton = [[[NSButton alloc] init] autorelease];
		[okButton setTitle:@"OK"];
		[okButton setFrame:NSMakeRect(dialogSize.width - 110, 12, 96, 32)];
		[okButton setBezelStyle:NSRoundedBezelStyle];
		[okButton setAutoresizingMask:NSViewMinXMargin];
		[okButton setKeyEquivalent:@"\r"];
		[okButton setTarget:self];
		[okButton setAction:@selector(dialogOk:)];
		[[dialog contentView] addSubview:okButton];
		
		BOOL returnCode = [NSApp runModalForWindow:dialog];
		[dialog orderOut:self];
*/
	
		NSString *lastStyName = [SUD stringForKey:LastStyNameKey];
		lastStyName = (!lastStyName || [lastStyName isEqualToString:@""]) ? @"latex.ltx" : lastStyName;
		[styleFileResult setStringValue:lastStyName];
	
		BOOL returnCode = [NSApp runModalForWindow: openStyleFilePanel];
		[openStyleFilePanel close];
		if (returnCode == 0) 
			target = [styleFileResult stringValue];
		else
			return;
		
		if ([target isEqualToString:@""])
			return;
    
        target = [target stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
        if ([target isEqualToString:@""])
            return;
		
		{
			NSWindow *theWindow = [NSApp mainWindow];
			NSString *cd;
			if ([theWindow isKindOfClass:[TSTextEditorWindow class]])
				cd = [[[[(TSTextEditorWindow *)theWindow document] fileURL] path] stringByDeletingLastPathComponent];
			else if ([theWindow isKindOfClass:[TSPreviewWindow class]]) 
				cd = [[[[(TSPreviewWindow *)theWindow document] fileURL] path] stringByDeletingLastPathComponent];
			else 
				cd = @"";
			

//			NSString* cd = [[self fileName] stringByDeletingLastPathComponent];
			cd = cd ? [NSString stringWithFormat:@"cd \"%@\";", cd] : @"";
			
			NSString* kpsetool = [SUD objectForKey:KpsetoolKey];
			if(!kpsetool || [kpsetool isEqualToString:@""]){
				kpsetool = @"kpsetool -w -n latex tex";
			}
			[SUD setObject:target forKey:LastStyNameKey];
			NSString* cmdLine = [NSString stringWithFormat:@"%@ PATH=%@:$PATH; open `%@ \"%@\"`", cd, [[SUD stringForKey:TetexBinPath] stringByExpandingTildeInPath], kpsetool, target];
			
			char str[1024];
			FILE *fp;
			
			if((fp=popen([[cmdLine stringByAppendingString:@" >/dev/null 2>&1"] UTF8String], "r")) == NULL){
				NSBeep();
				NSRunAlertPanel(NSLocalizedString(@"Error", @"Error"), @"An error has occurred.", @"OK", nil, nil);
				return;
			}
			while(YES){
				if(fgets(str, 1024, fp) == NULL) break;
			}
			if(pclose(fp) != 0) {
				NSBeep();
				NSRunAlertPanel(NSLocalizedString(@"Error", @"Error"), [NSString stringWithFormat:NSLocalizedString(@"%@ does not exist.", @"%@ does not exist."), target], @"OK", nil, nil);
			}
		}
}
	



- (IBAction)displayHG:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"HG" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayBinary:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"Binary" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayMoreBinary:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"MoreBinary" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayNegatedBinary:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"NegatedBinary" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayBinaryOperations:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"BinaryOperations" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayArrows:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"Arrows" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayMiscSymbols:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"MiscSymbols" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayDelimiters:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"Delimiters" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayOperators:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"Operators" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayLargeOperators:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"LargeOperators" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayMathAccents:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"MathAccents" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayMathSpacing:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"MathSpacing" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayEuropean:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"European" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayTextAccents:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"TextAccents" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayTextSizes:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"TextSizes" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayTextSymbols:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"TextSymbols" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayTextSpacing:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"TextSpacing" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)displayTables:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"Tables" ofType:@"pdf"];
	[self displayFile: fileName];
}

- (IBAction)supplementsToDesktop:sender
{
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if (! [fileManager fileExistsAtPath: [[DesktopPath stringByAppendingString:@"Course Supplements"] stringByStandardizingPath]] ) {
		[self mirrorPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Course Supplements"]
			  toPath:[[DesktopPath stringByAppendingString:@"Course Supplements"] stringByStandardizingPath]];
		}

}

- (void) okForPanel: sender
{
	[NSApp stopModalWithCode: 0];
}

- (void) cancelForPanel: sender
{
	[NSApp stopModalWithCode:1];
}


@end



@implementation HelpDocuments (Private)

// Recursively copy the file/folder at srcPath to dstPath.
// This creates target folders as needed, and will not overwrite
// existing files.
- (void)mirrorPath:(NSString *)srcPath toPath:(NSString *)dstPath
{
	NSFileManager	*fileManager;
	BOOL			srcExists, srcIsDir;
	BOOL			dstExists, dstIsDir;
	BOOL			result;
	NSString		*reason = 0;

	fileManager = [NSFileManager defaultManager];
	
	srcExists = [fileManager fileExistsAtPath:srcPath isDirectory:&srcIsDir];
	dstExists = [fileManager fileExistsAtPath:dstPath isDirectory:&dstIsDir];
	
	if (!srcExists)
		return;	// Source doesn't exist, abort (this shouldn't happen)
	
	if (dstExists && (srcIsDir != dstIsDir))
		return; // Both source and destination exist, but one is a file and the other a folder: abort!
	
	if (srcIsDir) {
		// Create destination directory if missing (and abort if this fails)
		if (!dstExists) {
			NS_DURING
				// create the missing directory
            result = [fileManager createDirectoryAtPath:dstPath withIntermediateDirectories:NO attributes:nil error:NULL];
			NS_HANDLER
				result = NO;
				reason = [localException reason];
			NS_ENDHANDLER
			if (!result) {
				NSRunAlertPanel(NSLocalizedString(@"Error", @"Error"), reason,
					[NSString stringWithFormat: NSLocalizedString(@"Couldn't create folder:\n%@", @"Message when creating a directory failed"), dstPath],
					nil, nil);
				return;
			}
		}
		
		// Iterate over the content of the source dir and copy it recursively
		NSEnumerator 	*fileEnumerator;
		NSString		*fileName;
		fileEnumerator = [[fileManager contentsOfDirectoryAtPath:srcPath error:NULL] objectEnumerator];
		while ((fileName = [fileEnumerator nextObject])) {
			[self mirrorPath:[srcPath stringByAppendingPathComponent:fileName]
					  toPath:[dstPath stringByAppendingPathComponent:fileName]];
		}
	} else {
		// Copy source to destination
		if (!dstExists) {
			NS_DURING
				// file doesn't exist -> copy it
            result = [fileManager copyItemAtPath:srcPath toPath:dstPath error:NULL];
			NS_HANDLER
				result = NO;
				reason = [localException reason];
			NS_ENDHANDLER
			if (!result) {
				// Copying the file failed for some reason.
				// We might want to show an error alert here, but then the main
				// reason why this would fail is a write protected Library; and in that
				// case it doesn't seem clever to pop up a dozen or more error alerts.
				// Hence we only do so for directory creation failures for now.
				// Might want to revise this decision at a later point...
				// Like maybe just record the fact that an error occurred, and at the
				// end of the mirroring process, pop up a single error dialog 
				// stating something like "TeXShop failed to copy one or multiple files
				// from FOO to BAR, etc.".
			}
		}
	}
}

@end

