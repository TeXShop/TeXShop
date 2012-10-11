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
 * $Id: globals.m 260 2007-08-08 22:51:09Z richard_koch $
 *
 * Created by dirk on Thu Dec 07 2000.
 *
 */

#import "globals.h"

NSString *DefaultCommandKey = @"DefaultCommand";
NSString *DefaultEngineKey = @"DefaultEngine";
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
NSString *LineBreakModeKey = @"LineBreakMode";
NSString *TagSectionsKey = @"TagSections";
NSString *LPanelOutlinesKey = @"LPanelOutlines";
NSString *PanelOriginXKey = @"PanelOriginX";
NSString *PanelOriginYKey = @"PanelOriginY";
NSString *MPanelOriginXKey = @"MPanelOriginX"; //  MatrixPanel Addition by Jonas 1.32 Nov 28 03
NSString *MPanelOriginYKey = @"MPanelOriginY"; //  MatrixPanel Addition by Jonas 1.32 Nov 28 03
NSString *LatexCommandKey = @"LatexCommand";
NSString *LatexGSCommandKey = @"LatexGSCommand";
NSString *SavePSEnabledKey = @"SavePSEnabled";
NSString *LatexScriptCommandKey = @"LatexScriptCommand";
NSString *ParensMatchingEnabledKey = @"ParensMatchingEnabled";
NSString *SpellCheckEnabledKey = @"SpellCheckEnabled";
NSString *LineNumberEnabledKey = @"LineNumberEnabled";
NSString *ShowInvisibleCharactersEnabledKey = @"ShowInvisibleChractersEnabled"; // added by Terada
NSString *AutoCompleteEnabledKey = @"AutoCompleteEnabled";
NSString *AlwaysHighlightEnabledKey = @"AlwaysHighlightEnabled"; // added by Terada
NSString *HighlightContentEnabledKey = @"HighlightContentEnabled"; // added by Terada
NSString *ShowFullPathEnabledKey = @"ShowFullPathEnabled"; // added by Terada
NSString *ShowIndicatorForMoveEnabledKey = @"ShowIndicatorForMoveEnabled"; // added by Terada
NSString *BeepEnabledKey = @"BeepEnabled"; // added by Terada
NSString *FlashBackgroundEnabledKey = @"FlashBackgroundEnabled"; // added by Terada
NSString *CheckBraceEnabledKey = @"CheckBraceEnabled"; // added by Terada
NSString *CheckBracketEnabledKey = @"CheckBracketEnabled"; // added by Terada
NSString *CheckSquareBracketEnabledKey = @"CheckSquareBracketEnabled"; // added by Terada
NSString *CheckParenEnabledKey = @"CheckParenEnabled"; // added by Terada
NSString *MakeatletterEnabledKey = @"MakeatletterEnabled"; // added by Terada
NSString *PdfMagnificationKey = @"PdfMagnification";
NSString *NoScrollEnabledKey = @"NoScrollEnabled";
NSString *PdfWindowFixedPosKey = @"PdfWindowFixedPosition";
NSString *PdfWindowNameKey = @"PdfWindow";
NSString *PdfKitWindowNameKey = @"PdfKitWindow";
NSString *PdfWindowPosModeKey = @"PdfWindowPositionMode";
NSString *PdfPageStyleKey = @"PdfPageStyle"; // mitsu 1.29 (O)
NSString *PdfRefreshKey = @"PdfRefresh";
NSString *RefreshTimeKey = @"RefreshTime";
NSString *PdfFileRefreshKey = @"PdfFileRefresh";
NSString *PdfFirstPageStyleKey = @"PdfFirstPageStyle";
NSString *PdfFitSizeKey = @"PdfFitSize"; // mitsu 1.29 (O)
NSString *PdfKitFitSizeKey = @"PdfKitFitSize"; // mitsu 1.29 (O)
NSString *PdfCopyTypeKey = @"PdfCopyType"; // mitsu 1.29 (O)
NSString *PdfExportTypeKey = @"PdfExportType"; // mitsu 1.29 (O)
NSString *PdfMouseModeKey = @"PdfMouseMode"; // mitsu 1.29 (O)
NSString *PdfKitMouseModeKey = @"PdfKitMouseMode"; // mitsu 1.29 (O)
NSString *PdfQuickDragKey = @"PdfQuickDrag"; // mitsu 1.29 drag & drop
NSString *SaveDocumentFontKey = @"SaveDocumentFont";
NSString *SyntaxColoringEnabledKey = @"SyntaxColoringEnabled";
NSString *KeepBackupKey = @"KeepBackup";
NSString *TetexBinPath = @"TetexBinPath";
NSString *GSBinPath = @"GSBinPath";
NSString *TexCommandKey = @"TexCommand";
NSString *TexGSCommandKey = @"TexGSCommand";
NSString *TexScriptCommandKey = @"TexScriptCommand";
NSString *MetaPostCommandKey = @"MetaPostCommand";
NSString *BibtexCommandKey = @"BibtexCommand"; // comment out by Terada (added back in, but unused: Koch)
NSString *DistillerCommandKey = @"DistillerCommand";
NSString *MatrixSizeKey = @"matrixsize"; // Jonas' Matrix addition
NSString *TSHasBeenUsedKey = @"TSHasBeenUsed";
NSString *UserInfoPath = @"UserInfoPath";

NSString *commentredKey = @"commentred";
NSString *commentgreenKey = @"commentgreen";
NSString *commentblueKey = @"commentblue";
NSString *commandredKey = @"commandred";
NSString *commandgreenKey = @"commandgreen";
NSString *commandblueKey = @"commandblue";
NSString *markerredKey = @"markerred";
NSString *markergreenKey = @"markergreen";
NSString *markerblueKey = @"markerblue";
NSString *indexredKey = @"indexred";
NSString *indexgreenKey = @"indexgreen";
NSString *indexblueKey = @"indexblue";
NSString *background_RKey = @"background_R";
NSString *background_GKey = @"background_G";
NSString *background_BKey = @"background_B";
NSString *backgroundAlphaKey = @"backgroundAlpha"; // added by Terada
NSString *foreground_RKey = @"foreground_R";
NSString *foreground_GKey = @"foreground_G";
NSString *foreground_BKey = @"foreground_B";
NSString *insertionpoint_RKey = @"insertionpoint_R";
NSString *insertionpoint_GKey = @"insertionpoint_G";
NSString *insertionpoint_BKey = @"insertionpoint_B";

NSString *tabsKey = @"tabs";
NSString *WarnForShellEscapeKey = @"WarnForShellEscape";
NSString *ptexUtfOutputEnabledKey = @"ptexUtfOutput"; // zenitani 1.35 (C)
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
NSString *ExternalEditorTypesetAtStartKey = @"ExternalEditorTypesetAtStart";
NSString *ConvertLFKey = @"ConvertLF";
NSString *UseOgreKitKey = @"UseOgreKit";
NSString *FindMethodKey = @"FindMethod";
NSString *BringPdfFrontOnAutomaticUpdateKey = @"BringPdfFrontOnAutomaticUpdate";
NSString *BringPdfFrontOnTypesetKey = @"BringPdfFrontOnTypeset";
NSString *SourceWindowAlphaKey = @"SourceWindowAlpha";
NSString *PreviewWindowAlphaKey = @"PreviewWindowAlpha";
NSString *ConsoleWindowAlphaKey = @"ConsoleWindowAlpha";
NSString *OtherTrashExtensionsKey = @"OtherTrashExtensions";
NSString *AggressiveTrashAUXKey = @"AggressiveTrashAUX";
NSString *ShowSyncMarksKey = @"ShowSyncMarks";
NSString *AcceptFirstMouseKey = @"AcceptFirstMouse";
NSString *UseOldHeadingCommandsKey = @"UseOldHeadingCommands";
NSString *SyncMethodKey = @"SyncMethod";
NSString *UseOutlineKey = @"UseOutline";
NSString *LeftRightArrowsAlwaysPageKey = @"LeftRightArrowsAlwaysPage";
NSString *ReleaseDocumentClassesKey = @"ReleaseDocumentClasses"; // 0 = if 10.4.3 or higher; 1 = no; 2 = yes
NSString *RedConsoleAfterErrorKey = @"RedConsoleAfterError"; // NO or YES
NSString *PreviewDrawerOpenKey = @"PreviewDrawerOpen"; // NO or YES
NSString *ConTeXtTagsKey = @"ConTeXtTags"; // NO or YES
NSString *RevisePathKey = @"RevisePath"; // NO or YES
NSString *OtherTeXExtensionsKey = @"OtherTeXExtensions";
NSString *ReleaseDocumentOnLeopardKey = @"ReleaseDocumentOnLeopard";
NSString *BibDeskCompletionKey = @"BibDeskCompletion";
NSString *SyncTeXOnlyKey = @"SyncTeXOnly";
NSString *ConsoleBackgroundColor_RKey = @"ConsoleBackgroundColor_R";
NSString *ConsoleBackgroundColor_GKey = @"ConsoleBackgroundColor_G";
NSString *ConsoleBackgroundColor_BKey = @"ConsoleBackgroundColor_B";
NSString *ConsoleBackgroundAlphaKey = @"ConsoleBackgroundAlpha"; // added by Terada
NSString *ConsoleForegroundColor_RKey = @"ConsoleForegroundColor_R";
NSString *ConsoleForegroundColor_GKey = @"ConsoleForegroundColor_G";
NSString *ConsoleForegroundColor_BKey = @"ConsoleForegroundColor_B";
NSString *ConsoleFontNameKey = @"ConsoleFontName";
NSString *ConsoleFontSizeKey = @"ConsoleFontSize";
NSString *ConsoleWidthResizeKey = @"ConsoleWidthResize";
NSString *RightJustifyKey = @"RightJustify";
NSString *CommandCompletionCharKey = @"CommandCompletionChar";
NSString *CommandCompletionAlternateMarkShortcutKey = @"CommandCompletionAlternateMarkShortcut";
NSString *showSpaceCharacterKey = @"ShowSpaceCharacter"; // added by Terada
NSString *showFullwidthSpaceCharacterKey = @"ShowFullwidthSpaceCharacter"; // added by Terada
NSString *showTabCharacterKey = @"ShowTabCharacter"; // added by Terada
NSString *showNewLineCharacterKey = @"ShowNewLineCharacter"; // added by Terada
NSString *SpaceCharacterKindKey = @"SpaceCharacterKind"; // added by Terada
NSString *FullwidthSpaceCharacterKindKey = @"FullwidthSpaceCharacterKind"; // added by Terada
NSString *TabCharacterKindKey = @"TabCharacterKind"; // added by Terada
NSString *NewLineCharacterKindKey = @"NewLineCharacterKind"; // added by Terada
NSString *LastStyNameKey = @"LastStyName"; // added by Terada
NSString *KpsetoolKey = @"Kpsetool"; // added by Terada
NSString *BibTeXengineKey = @"BibTeXengine"; // added by Terada

NSString *SmartInsertDeleteKey = @"SmartInsertDelete"; // Koch
NSString *AutomaticDataDetectionKey = @"AutomaticDataDetection"; // Koch
NSString *AutomaticLinkDetectionKey = @"AutomaticLinkDetection"; // Koch
NSString *AutomaticTextReplacementKey = @"AutomaticTextReplacement"; // Koch
NSString *AutomaticDashSubstitutionKey = @"AutomaticDashSubstitution"; // Koch
NSString *AutomaticQuoteSubstitutionKey = @"AutomaticQuoteSubstitution"; // Koch
NSString *AutomaticUTF8MACtoUTF8ConversionKey = @"AutomaticUTF8MACtoUTF8Conversion"; //Koch
NSString *highlightBracesRedKey = @"highlightBracesRed"; //Koch (flashing color when braces first typed)
NSString *highlightBracesGreenKey = @"highlightBracesGreen"; //Koch
NSString *highlightBracesBlueKey = @"highlightBracesBlue"; //Koch
NSString *highlightContentRedKey = @"highlightContentRed"; //Koch (content between braces when braces first typed)
NSString *highlightContentGreenKey = @"highlightContentGreen"; //Koch
NSString *highlightContentBlueKey = @"highlightContentBlue"; //Koch
NSString *invisibleCharRedKey = @"invisibleCharRed"; //Koch
NSString *invisibleCharGreenKey = @"invisibleCharGreen"; //Koch
NSString *invisibleCharBlueKey = @"invisibleCharBlue"; //Koch
NSString *brieflyFlashYellowForMatchKey = @"brieflyFlashYellowForMatch"; //Koch
NSString *syncWithRedOvalsKey = @"syncWithRedOvals";
NSString *AutoSaveKey = @"AutoSave"; // inactive
NSString *FixLineNumberScrollKey = @"FixLineNumberScroll";
NSString *RightJustifyIfAnyKey = @"RightJustifyIfAny";
NSString *AutoSaveEnabledKey = @"AutoSaveEnabled";



// Paths
NSString *DesktopPath = @"~/Desktop/";
NSString *MoviesPath = @"~/Library/TeXShop/Movies";
NSString *DocumentsPath = @"~/Library/TeXShop/Documents";
NSString *TeXShopPath = @"~/Library/TeXShop";
NSString *TexTemplatePath = @"~/Library/TeXShop/Templates";
NSString *TexTemplateMorePath = @"~/Library/TeXShop/Templates/More";
NSString *StationeryPath = @"~/Library/TeXShop/Stationery";
NSString *LatexPanelPath = @"~/Library/TeXShop/LatexPanel";
NSString *MatrixPanelPath = @"~/Library/TeXShop/MatrixPanel";
NSString *BinaryPath = @"~/Library/TeXShop/bin";
NSString *EnginePath = @"~/Library/TeXShop/Engines";
NSString *EngineInactivePath = @"~/Library/TeXShop/Engines/Inactive";
NSString *ScriptsPath = @"~/Library/TeXShop/Scripts";
NSString *NewPath = @"~/Library/TeXShop/New";
NSString *AutoCompletionPath = @"~/Library/TeXShop/Keyboard";
NSString *MenuShortcutsPath = @"~/Library/TeXShop/Menus";
NSString *MacrosPath = @"~/Library/TeXShop/Macros";
NSString *CommandCompletionFolderPath = @"~/Library/TeXShop/CommandCompletion";
NSString *CommandCompletionPath = @"~/Library/TeXShop/CommandCompletion/CommandCompletion.txt";

// TODO: Shouldn't we use  NSTemporaryDirectory() (or a path based on it) rather than the following three paths?
NSString *TempPath = @"/tmp/TeXShop_Applescripts";
NSString *TempOutputKey = @"/tmp/TeXShop_Output";
NSString *DraggedImageFolderPath = @"~/Library/TeXShop/DraggedImages";
NSString *DraggedImagePath = @"~/Library/TeXShop/DraggedImages/texshop_image"; // mitsu 1.29 drag & drop


// Notifications
NSString *SyntaxColoringChangedNotification = @"SyntaxColoringChangedNotification";
NSString *DocumentFontChangedNotification = @"DocumentFontChangedNotification";
NSString *DocumentFontRememberNotification = @"DocumentFontRememberNotification";
NSString *DocumentFontRevertNotification = @"DocumentFontRevertNotification";
NSString *ConsoleFontChangedNotification = @"ConsoleFontChangedNotification";
NSString *ConsoleBackgroundColorChangedNotification = @"ConsoleBackgroundColorChangedNotification";
NSString *ConsoleForegroundColorChangedNotification = @"ConsoleForegroundColorChangedNotification";
NSString *SourceBackgroundColorChangedNotification = @"DocumentBackgroundColorChangedNotification";
NSString *SourceTextColorChangedNotification = @"DocumentTextColorChangedNotification";;
NSString *PreviewBackgroundColorChangedNotification = @"PreviewBackgroundColorChangedNotification";
NSString *MagnificationChangedNotification = @"MagnificationChangedNotification";
NSString *MagnificationRememberNotification = @"MagnificationRememberNotification";
NSString *MagnificationRevertNotification = @"MagnificationRevertNotification";
NSString *DocumentSyntaxColorNotification = @"DocumentSyntaxColorNotification";
NSString *DocumentAutoCompleteNotification = @"DocumentAutoCompleteNotification";
NSString *DocumentBibDeskCompleteNotification = @"DocumentBibDeskCompleteNotification";
NSString *ExternalEditorNotification = @"ExternalEditorNotification";
NSString *CommandCompletionCharNotification = @"CommandCompletionCharNotification";

/*" Other variables "*/
TSFilterMode		g_shouldFilter;
NSInteger			g_texChar;
NSInteger           g_commentChar;
NSDictionary		*g_autocompletionDictionary;
NSArray				*g_autocompletionKeys;  // added by Terada

NSArray				*g_taggedTeXSections;
NSArray				*g_taggedTagSections;
BOOL				fromMenu;	// by default, NO. Equals YES if menu items "TeX", "LaTeX", etc. are chosen, so "%!TEX program = ..." is ignored. Must be global to work with Root Files
BOOL                doAutoSave; // this is present so changes in AutoSave only take effect on restart

// command completion
NSString *g_commandCompletionChar = nil;
NSMutableString *g_commandCompletionList = nil;
BOOL g_canRegisterCommandCompletion = NO;
NSColor *PreviewBackgroundColor = nil;

// Spelling (defaults if not changed by document tag)
BOOL		spellLanguageChanged;
BOOL		automaticLanguage;
NSString	*defaultLanguage;

// Koch 8/24/03
NSInteger	g_macroType;	// FIXME: get rid of this
