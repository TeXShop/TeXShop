//
//  globals.m
//  TeXShop
//
//  Created by dirk on Thu Dec 07 2000.
//

#import "globals.h"

NSString *DefaultCommandKey = @"DefaultCommand";
NSString *DefaultScriptKey = @"DefaultScript";
NSString *ConsoleBehaviorKey = @"ConsoleBehavior";
NSString *DocumentFontKey = @"DocumentFont";
NSString *DocumentWindowFixedPosKey = @"DocumentWindowFixedPosition";
NSString *DocumentWindowNameKey = @"DocumentWindow";
NSString *DocumentWindowPosModeKey = @"DocumentWindowPositionMode";
NSString *MakeEmptyDocumentKey = @"MakeEmptyDocument";
NSString *LatexCommandKey = @"LatexCommand";
NSString *LatexGSCommandKey = @"LatexGSCommand";
NSString *SavePSEnabledKey = @"SavePSEnabled";
NSString *LatexScriptCommandKey = @"LatexScriptCommand";
NSString *ParensMatchingEnabledKey = @"ParensMatchingEnabled";
NSString *PdfMagnificationKey = @"PdfMagnification";
NSString *NoScrollEnabledKey = @"NoScrollEnabled";
NSString *PdfWindowFixedPosKey = @"PdfWindowFixedPosition";
NSString *PdfWindowNameKey = @"PdfWindow";
NSString *PdfWindowPosModeKey = @"PdfWindowPositionMode";
NSString *SaveDocumentFontKey = @"SaveDocumentFont";
NSString *SyntaxColoringEnabledKey = @"SyntaxColoringEnabled";
NSString *TetexBinPathKey = @"TetexBinPath";
NSString *TexCommandKey = @"TexCommand";
NSString *TexGSCommandKey = @"TexGSCommand";
NSString *TexScriptCommandKey = @"TexScriptCommand";
NSString *TexTemplatePathKey = @"~/Library/TeXShop/Templates";
NSString *TSHasBeenUsedKey = @"TSHasBeenUsed";
NSString *UserInfoPathKey = @"UserInfoPath";
NSString *commentredKey = @"commentred";
NSString *commentgreenKey = @"commentgreen";
NSString *commentblueKey = @"commentblue";
NSString *commandredKey = @"commandred";
NSString *commandgreenKey = @"commandgreen";
NSString *commandblueKey = @"commandblue";
NSString *markerredKey = @"markerred";
NSString *markergreenKey = @"markergreen";
NSString *markerblueKey = @"markerblue";
NSString *teTeXBinLocation = @"/usr/local/teTeX/bin/powerpc-apple-darwin1.3.3/";

// Exceptions
NSString *XDirectoryCreation = @"DirectoryCreationException";

// Notifications
NSString *SyntaxColoringChangedNotification = @"SyntaxColoringChangedNotification";
NSString *DocumentFontChangedNotification = @"DocumentFontChangedNotification";
NSString *DocumentFontRememberNotification = @"DocumentFontRememberNotification";
NSString *DocumentFontRevertNotification = @"DocumentFontRevertNotification";
NSString *MagnificationChangedNotification = @"MagnificationChangedNotification";
NSString *MagnificationRememberNotification = @"MagnificationRememberNotification";
NSString *MagnificationRevertNotification = @"MagnificationRevertNotification";
NSString *DocumentSyntaxColorNotification = @"DocumentSyntaxColorNotification";

/*" Other variables "*/
BOOL documentsHaveLoaded;
