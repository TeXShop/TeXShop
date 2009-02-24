//
//  HelpDocuments.m
//  TeXShop
//
//  Created by Richard Koch on 7/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "HelpDocuments.h"
#import "TSDocumentController.h"
#import "Globals.h"
#import "TSDocument.h"

@interface HelpDocuments (Private)

- (void)mirrorPath:(NSString *)srcPath toPath:(NSString *)dstPath;

@end

@implementation HelpDocuments

- (void)displayFile:(NSString *)fileName
{
	TSDocumentController	*myController;
	NSURL					*myURL;
	NSError					*outError;
	TSDocument				*myDocument;
 	
	myURL = [NSURL fileURLWithPath: fileName];
	myController = [TSDocumentController sharedDocumentController];
	myDocument = [myController documentForURL: myURL];
	if (myDocument != nil) 
		[[myDocument pdfKitWindow] makeKeyAndOrderFront:self];
	else {
		[myController listDocument:NO];
		[myController openDocumentWithContentsOfURL: myURL display: YES error:&outError];
		[myController listDocument:YES];
		}
}

- (IBAction)displayGettingStartedTeXShop:sender
{
	NSString				*fileName;
 	
	fileName = [[NSBundle mainBundle] pathForResource:@"First Steps with TeXShop" ofType:@"pdf"];
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
				result = [fileManager createDirectoryAtPath:dstPath attributes:nil];
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
		fileEnumerator = [[fileManager directoryContentsAtPath:srcPath] objectEnumerator];
		while ((fileName = [fileEnumerator nextObject])) {
			[self mirrorPath:[srcPath stringByAppendingPathComponent:fileName]
					  toPath:[dstPath stringByAppendingPathComponent:fileName]];
		}
	} else {
		// Copy source to destination
		if (!dstExists) {
			NS_DURING
				// file doesn't exist -> copy it
				result = [fileManager copyPath:srcPath toPath:dstPath handler:nil];
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

