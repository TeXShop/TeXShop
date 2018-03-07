//
//  HelpDocuments.h
//  TeXShop
//
//  Created by Richard Koch on 7/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HelpDocuments : NSObject {
	
	NSTask					*displayPackageHelpTask;
	IBOutlet NSPanel		*packageHelpPanel;
	IBOutlet NSPanel		*openStyleFilePanel;
	IBOutlet NSTextField	*packageResult;
	IBOutlet NSTextField	*styleFileResult;

}

- (IBAction)displayGettingStartedTeXShop:sender;
- (IBAction)displayGettingStartedLatex:sender;
- (IBAction)displayGettingStartedConTeXt:sender;
- (IBAction)displayGettingStartedXeTeX:sender;
- (IBAction)displayHelpForPackage:sender;
- (IBAction)displayStyleFile:sender;
- (IBAction)displayFileEncoding:sender;
- (IBAction)displayTipsandTricks:sender;
- (IBAction)displayTeXShopConfusion:sender;
- (IBAction)displayNotesonApplescript:sender;
- (IBAction)displayRecentTeXFonts:sender;
- (IBAction)displayGPLLicense:sender;

- (IBAction)displayShortCourse:sender;
- (IBAction)displayHG:sender;
- (IBAction)displayBinary:sender;
- (IBAction)displayMoreBinary:sender;
- (IBAction)displayNegatedBinary:sender;
- (IBAction)displayBinaryOperations:sender;
- (IBAction)displayArrows:sender;
- (IBAction)displayMiscSymbols:sender;
- (IBAction)displayDelimiters:sender;
- (IBAction)displayOperators:sender;
- (IBAction)displayLargeOperators:sender;
- (IBAction)displayMathAccents:sender;
- (IBAction)displayMathSpacing:sender;
- (IBAction)displayEuropean:sender;
- (IBAction)displayTextAccents:sender;
- (IBAction)displayTextSizes:sender;
- (IBAction)displayTextSymbols:sender;
- (IBAction)displayTextSpacing:sender;
- (IBAction)supplementsToDesktop:sender;
- (IBAction)displayTables:sender;
- (IBAction)displayThisRelease:sender;
- (IBAction)displayChanges:sender;
- (IBAction)displayCommentLines:sender;

- (void)okForPanel:sender;
- (void)cancelForPanel:sender;

@end
