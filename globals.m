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
NSString *SaveRelatedKey = @"SaveRelated";
NSString *DocumentFontKey = @"DocumentFont";
NSString *DocumentWindowFixedPosKey = @"DocumentWindowFixedPosition";
NSString *DocumentWindowNameKey = @"DocumentWindow";
NSString *DocumentWindowPosModeKey = @"DocumentWindowPositionMode";
NSString *LatexPanelNameKey = @"LatexPanel";
NSString *MakeEmptyDocumentKey = @"MakeEmptyDocument";
NSString *UseExternalEditorKey = @"UseExternalEditor";
NSString *EncodingKey = @"Encoding";
NSString *TagSectionsKey = @"TagSections";
NSString *LPanelOutlinesKey = @"LPanelOutlines";
NSString *PanelOriginXKey = @"PanelOriginX";
NSString *PanelOriginYKey = @"PanelOriginY";
NSString *LatexCommandKey = @"LatexCommand";
NSString *LatexGSCommandKey = @"LatexGSCommand";
NSString *SavePSEnabledKey = @"SavePSEnabled";
NSString *LatexScriptCommandKey = @"LatexScriptCommand";
NSString *ParensMatchingEnabledKey = @"ParensMatchingEnabled";
NSString *SpellCheckEnabledKey = @"SpellCheckEnabled";
NSString *AutoCompleteEnabledKey = @"AutoCompleteEnabled";
NSString *PdfMagnificationKey = @"PdfMagnification";
NSString *NoScrollEnabledKey = @"NoScrollEnabled";
NSString *PdfWindowFixedPosKey = @"PdfWindowFixedPosition";
NSString *PdfWindowNameKey = @"PdfWindow";
NSString *PdfWindowPosModeKey = @"PdfWindowPositionMode";
NSString *SaveDocumentFontKey = @"SaveDocumentFont";
NSString *SyntaxColoringEnabledKey = @"SyntaxColoringEnabled";
NSString *TetexBinPathKey = @"TetexBinPath";
NSString *GSBinPathKey = @"GSBinPath";
NSString *TexCommandKey = @"TexCommand";
NSString *TexGSCommandKey = @"TexGSCommand";
NSString *TexScriptCommandKey = @"TexScriptCommand";
NSString *TexTemplatePathKey = @"~/Library/TeXShop/Templates";
NSString *LatexPanelPathKey = @"~/Library/TeXShop/LatexPanel";
NSString *AutoCompletionPathKey = @"~/Library/TeXShop/Keyboard";
NSString *MenuShortcutsPathKey = @"~/Library/TeXShop/Menus";
NSString *MacrosPathKey = @"~/Library/TeXShop/Macros";
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
NSString *tabsKey = @"tabs";
NSString *background_RKey = @"background_R";
NSString *background_GKey = @"background_G";
NSString *background_BKey = @"background_B";

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
NSString *DocumentAutoCompleteNotification = @"DocumentAutoCompleteNotification";
NSString *ExternalEditorNotification = @"ExternalEditorNotification";

/*" Other variables "*/
// BOOL documentsHaveLoaded;
NSMutableDictionary 	*TSEnvironment;
int			shouldFilter;
int			texChar;
NSDictionary		*autocompletionDictionary;  // added by Greg Landweber
/* Code by Anton Leuski */
NSArray*		kTaggedTeXSections; 
NSArray*		kTaggedTagSections; 


