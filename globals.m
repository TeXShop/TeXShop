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
NSString *PdfPageStyleKey = @"PdfPageStyle"; // mitsu 1.29 (O)
NSString *PdfFirstPageStyleKey = @"PdfFirstPageStyle"; 
NSString *PdfFitSizeKey = @"PdfFitSize"; // mitsu 1.29 (O)
NSString *PdfCopyTypeKey = @"PdfCopyType"; // mitsu 1.29 (O) 
NSString *PdfExportTypeKey = @"PdfExportType"; // mitsu 1.29 (O) 
NSString *PdfMouseModeKey = @"PdfMouseMode"; // mitsu 1.29 (O)
NSString *PdfQuickDragKey = @"PdfQuickDrag"; // mitsu 1.29 drag & drop
NSString *SaveDocumentFontKey = @"SaveDocumentFont";
NSString *SyntaxColoringEnabledKey = @"SyntaxColoringEnabled";
NSString *FastColoringKey = @"FastColor";
NSString *KeepBackupKey = @"KeepBackup";
NSString *TetexBinPathKey = @"TetexBinPath";
NSString *GSBinPathKey = @"GSBinPath";
NSString *TexCommandKey = @"TexCommand";
NSString *TexGSCommandKey = @"TexGSCommand";
NSString *TexScriptCommandKey = @"TexScriptCommand";
NSString *TexTemplatePathKey = @"~/Library/TeXShop/Templates";
NSString *MetaPostCommandKey = @"MetaPostCommand";
NSString *BibtexCommandKey = @"BibtexCommand";
NSString *LatexPanelPathKey = @"~/Library/TeXShop/LatexPanel";
NSString *AutoCompletionPathKey = @"~/Library/TeXShop/Keyboard";
NSString *MenuShortcutsPathKey = @"~/Library/TeXShop/Menus";
NSString *MacrosPathKey = @"~/Library/TeXShop/Macros";
NSString *CommandCompletionPathKey = @"~/Library/TeXShop/CommandCompletion/CommandCompletion.txt"; // mitsu 1.29 (P)
NSString *DraggedImagePathKey = @"~/Library/TeXShop/DraggedImages/texshop_image"; // mitsu 1.29 drag & drop
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
NSString *WarnForShellEscapeKey = @"WarnForShellEscape";
// mitsu 1.29 (O)
NSString *PdfColorMapKey = @"PdfColorMap";
NSString *PdfFore_RKey = @"PdfFore_R";
NSString *PdfFore_GKey = @"PdfFore_G";
NSString *PdfFore_BKey = @"PdfFore_B";
NSString *PdfFore_AKey = @"PdfFore_A";
NSString *PdfBack_RKey = @"PdfBack_R";
NSString *PdfBack_GKey = @"PdfBack_G";
NSString *PdfBack_BKey = @"PdfBack_B";
NSString *PdfBack_AKey = @"PdfBack_A";
NSString *PdfColorParam1Key = @"PdfColorParam1";
NSString *PdfColorParam2Key = @"PdfColorParam2";
NSString *PdfPageBack_RKey = @"Pdfbackground_R";
NSString *PdfPageBack_GKey = @"Pdfbackground_G";
NSString *PdfPageBack_BKey = @"Pdfbackground_B";
// end mitsu 1.29

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

// mitsu 1.29 (P)-- command completion
NSString *commandCompletionChar = nil;
NSMutableString *commandCompletionList = nil;
BOOL canRegisterCommandCompletion = NO;
// end mitsu 1.29
//int imageCopyType; // was defined in MyPDFView.m // mitsu 1.29b not used

// Koch 8/24/03
int	macroType;
