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
 * $Id: globals.h 260 2007-08-08 22:51:09Z richard_koch $
 *
 * Created by dirk on Thu Dec 07 2000.
 *
 */

/*
 Compile options. Comment out to compile on earlier versions of macOS, with limited facilities
*/

// This provides short names in tabs
#define HIGHSIERRAORHIGHER

// This provides dark mode
#define MOJAVEORHIGHER

/*
 End
*/


#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// This nifty macro computes the size of a static array.
#define ARRAYSIZE(x) ((NSInteger)(sizeof(x) / sizeof(x[0])))

// The yen and backslash characters are both used to start LaTeX commands. Used
// frequently throughout the code to detect commands.
#define	YEN			0x00a5
#define	BACKSLASH	'\\'
#define COMMENT     '%'


// Shortcut to access the standard user defaults more easily.
#define SUD [NSUserDefaults standardUserDefaults]

// Used to be NSMacOSRomanStringEncoding, which is in the headers
// #define NSISOLatin9StringEncoding 0x8000020f

// The following block defines constants used in the PDF code. 
// TODO: Move this to a more appropriate header file.
#if 1

#define PAGE_SPACE_H	10
#define PAGE_SPACE_V	10

#define HORIZONTAL_SCROLL_AMOUNT	60
#define VERTICAL_SCROLL_AMOUNT	60
#define HORIZONTAL_SCROLL_OVERLAP	60
#define VERTICAL_SCROLL_OVERLAP		60
#define SCROLL_TOLERANCE 0.5

#define PAGE_WINDOW_H_OFFSET	60
#define PAGE_WINDOW_V_OFFSET	-10
#define PAGE_WINDOW_WIDTH		55
#define PAGE_WINDOW_HEIGHT		20
#define PAGE_WINDOW_DRAW_X		7
#define PAGE_WINDOW_DRAW_Y		3
#define PAGE_WINDOW_HAS_SHADOW	NO

#define SIZE_WINDOW_H_OFFSET	75
#define SIZE_WINDOW_V_OFFSET	-10
#define SIZE_WINDOW_WIDTH		70
#define SIZE_WINDOW_HEIGHT		20
#define SIZE_WINDOW_DRAW_X		5
#define SIZE_WINDOW_DRAW_Y		3
#define SIZE_WINDOW_HAS_SHADOW	NO

#define JPEG_COMPRESSION_HIGH	1.0
#define JPEG_COMPRESSION_MEDIUM	0.95
#define JPEG_COMPRESSION_LOW	0.85

#define PDF_MAX_SCALE           2000


#endif


/*" Symbolic constants for the matrix used in 'Source window Position' of the TSPreferences. "*/
enum DocumentWindowPosition
{
	DocumentWindowPosFixed = 0,
	DocumentWindowPosSave = 1
};

/*" Symbolic constants for the matrix used in 'PDF window Position' of the TSPreferences. "*/
enum PdfWindowPosition
{
	PdfWindowPosFixed = 0,
	PdfWindowPosSave = 1
};

/*" Symbolic constants for the matrix used in 'Console Position' of the TSPreferences. "*/
enum ConsoleWindowPosition
{
    ConsoleWindowPosFixed = 0,
    ConsoleWindowPosSave = 1
};


/*" Symbolic constants for the display mode to use "*/
enum PdfDisplayMode
{
	PdfDisplayModeApple = 0,
	PdfDisplayModeGhostscript = 1
};

/*" Symbolic constants for the Ghostscript color mode. "*/
enum GsColorMode
{
	GsColorModeGrayscale = 0,
	GsColorMode256 = 1,
	GsColorModeThousands = 2
};

/*" Symbolic constants for Japanese conversion "*/
typedef enum
{
	kNoFilterMode = 0,
	kMacJapaneseFilterMode = 1,			// MacJapanese
	kOtherJapaneseFilterMode = 2		// NSShiftJIS & EUCJapanese & JISJapanese
} TSFilterMode;

/*" Symbolic constants to determine TeX engine "*/
/*" These are also tags on the typeset menu and the pulldown toolbar menus "*/
enum EngineCommand
{
	TexEngine = 1,
	LatexEngine = 2,
	BibtexEngine = 3,
	IndexEngine = 4,
	MetapostEngine = 5,
	ContextEngine = 6,
	UserEngine = 7
};

// mitsu 1.29 (O)
/*" Page style for MyPDFView"*/
typedef enum _PDFPageStyle
{
	PDF_SINGLE_PAGE_STYLE = 1,
	PDF_TWO_PAGE_STYLE = 2,
	PDF_MULTI_PAGE_STYLE = 3,
	PDF_DOUBLE_MULTI_PAGE_STYLE = 4
} _PDFPageStyle;

typedef enum _PDFFirstPageStyle
{
		PDF_FIRST_LEFT = 1,
		PDF_FIRST_RIGHT = 2
} _PDFFirstPageStyle;

/*" Size option for MyPDFView"*/
typedef enum _PDFSizeOption
{
	PDF_ACTUAL_SIZE = -100,
	PDF_FIT_TO_NONE = -101,
	PDF_FIT_TO_WIDTH = -102,
	PDF_FIT_TO_HEIGHT = -103,
	PDF_FIT_TO_WINDOW = -104
} _PDFSizeOption;

/*" Mouse mode for MyPDFView"*/
typedef enum _MouseMode
{
	MOUSE_MODE_NULL = 0,
	MOUSE_MODE_SCROLL = 1,
	MOUSE_MODE_MAG_GLASS = 2,
	MOUSE_MODE_MAG_GLASS_L = 3,
	MOUSE_MODE_SELECT = 4
} _MouseMode;

/*" Size option for MyPDFKitView"*/
typedef enum _NewPDFSizeOption
{
	NEW_PDF_ACTUAL_SIZE = 1, // PDF_ACTUAL_SIZE = -100,
	NEW_PDF_FIT_TO_NONE = 2, // PDF_FIT_TO_NONE = -101,
	NEW_PDF_FIT_TO_WINDOW = 3, // PDF_FIT_TO_WINDOW = -104
	NEW_PDF_FIT_TO_WIDTH = 4, // PDF_FIT_TO_WIDTH = -102,
	NEW_PDF_FIT_TO_HEIGHT = 5 // PDF_FIT_TO_HEIGHT = -103,

} _NewPDFSizeOption;

/*" Mouse mode for MyPDFKitView"*/
typedef enum _NewMouseMode
{
	NEW_MOUSE_MODE_SCROLL = 1,
	NEW_MOUSE_MODE_SELECT_TEXT = 2,
	NEW_MOUSE_MODE_MAG_GLASS = 3,
	NEW_MOUSE_MODE_MAG_GLASS_L = 4,
	NEW_MOUSE_MODE_SELECT_PDF = 5
} _NewMouseMode;

/*" Image copy/export types for MyPDFView"*/
enum ImageCopyType
{
	IMAGE_TYPE_TIFF_NC = 1, // no compresion
	IMAGE_TYPE_TIFF_LZW = 2, // LZW compression
	IMAGE_TYPE_TIFF_PB = 3, // PackBits compression
	IMAGE_TYPE_JPEG_HIGH = 11,
	IMAGE_TYPE_JPEG_MEDIUM = 13,
	IMAGE_TYPE_JPEG_LOW = 15,
		IMAGE_TYPE_PICT = 20,
	IMAGE_TYPE_PNG = 21,
	IMAGE_TYPE_GIF = 22, // not suitable for our purpose?
	IMAGE_TYPE_BMP = 23, // does not work?
	IMAGE_TYPE_PDF = 31,
	IMAGE_TYPE_EPS = 32
};

// end mitsu 1.29

/*" Sync Methods"*/
typedef enum _SyncMethodType
{
	PDFSYNC = 0, // original PDF sync
	SEARCHONLY = 1, // new pdf search method
	SEARCHFIRST = 2, // new pdf search first, but fall back on PDF sync if necessary
	SYNCTEXFIRST = 3 // synctex, but fall back on pdf search if necessary
} _SyncMethodType;

/*" Comment and Indent Methods"*/
typedef enum _CommentIndentType
{
	Mcomment = 1,
	Muncomment = 2,
	Mindent = 3,
	Munindent = 4
} _CommentIndentType;


/*" global defines for TeXShop.app "*/
extern NSString *DefaultCommandKey;
extern NSString *DefaultEngineKey;
extern NSString *DefaultScriptKey;
extern NSString *ConsoleBehaviorKey;
extern NSString *SaveRelatedKey;
extern NSString *DocumentFontKey;
extern NSString *DocumentFontAttributesKey;
extern NSString *DocumentWindowFixedPosKey;
extern NSString *PortableDocumentWindowFixedPosKey;
extern NSString *DocumentWindowNameKey;
extern NSString *DocumentWindowPosModeKey;
extern NSString *LatexPanelNameKey;
extern NSString *MakeEmptyDocumentKey;
extern NSString *UseExternalEditorKey;
extern NSString *EncodingKey;
extern NSString *LineBreakModeKey;
extern NSString *TagSectionsKey;
extern NSString *LPanelOutlinesKey;
extern NSString *PanelOriginXKey;
extern NSString *PanelOriginYKey;
extern NSString *MPanelOriginXKey; //  MatrixPanel Addition by Jonas 1.32 Nov 28 03
extern NSString *MPanelOriginYKey; //  MatrixPanel Addition by Jonas 1.32 Nov 28 03
extern NSString *LatexCommandKey;
extern NSString *LatexGSCommandKey;
extern NSString *SavePSEnabledKey;
extern NSString *LatexScriptCommandKey;
extern NSString *ParensMatchingEnabledKey;
extern NSString *SpellCheckEnabledKey;
extern NSString *LineNumberEnabledKey;
extern NSString *ShowInvisibleCharactersEnabledKey; // added by Terada
extern NSString *AutoCompleteEnabledKey;
extern NSString *AlwaysHighlightEnabledKey; // added by Terada
extern NSString *HighlightContentEnabledKey; // added by Terada
extern NSString *ShowFullPathEnabledKey; // added by Terada
extern NSString *ShowIndicatorForMoveEnabledKey; // added by Terada
extern NSString *BeepEnabledKey; // added by Terada
extern NSString *FlashBackgroundEnabledKey; // added by Terada
extern NSString *CheckBraceEnabledKey; // added by Terada
extern NSString *CheckBracketEnabledKey; // added by Terada
extern NSString *CheckSquareBracketEnabledKey; // added by Terada
extern NSString *CheckParenEnabledKey; // added by Terada
extern NSString *MakeatletterEnabledKey; // added by Terada
extern NSString *PdfMagnificationKey;
extern NSString *NoScrollEnabledKey;
extern NSString *PdfWindowFixedPosKey;
extern NSString *PortablePdfWindowFixedPosKey;
extern NSString *PdfWindowNameKey;
extern NSString *PdfKitWindowNameKey;
extern NSString *PdfWindowPosModeKey;
extern NSString *PdfPageStyleKey; // mitsu 1.29 (O)
extern NSString *PdfRefreshKey;
extern NSString *AntiAliasKey;
extern NSString *RefreshTimeKey;
extern NSString *PdfFileRefreshKey;
extern NSString *PdfFirstPageStyleKey;
extern NSString *PdfFitSizeKey; // mitsu 1.29 (O)
extern NSString *PdfKitFitSizeKey; // mitsu 1.29 (O)
extern NSString *PdfCopyTypeKey; // mitsu 1.29 (O)
extern NSString *PdfExportTypeKey; // mitsu 1.29 (O)
extern NSString *PdfMouseModeKey; // mitsu 1.29 (O)
extern NSString *PdfKitMouseModeKey; // mitsu 1.29 (O)
extern NSString *PdfQuickDragKey; // mitsu 1.29 drag & drop
extern NSString *SaveDocumentFontKey;
extern NSString *SyntaxColoringEnabledKey;
extern NSString *KeepBackupKey;
extern NSString *TetexBinPath;
extern NSString *GSBinPath;
extern NSString *TexCommandKey;
extern NSString *TexGSCommandKey;
extern NSString *TexScriptCommandKey;
extern NSString *MetaPostCommandKey;
extern NSString *BibtexCommandKey; // comment out by Terada (added back in, but unused; Koch)
extern NSString *DistillerCommandKey;
extern NSString *MatrixSizeKey; // Jonas' Matrix addition
extern NSString *TSHasBeenUsedKey;
extern NSString *UserInfoPath;

extern NSString *commentredKey;
extern NSString *commentgreenKey;
extern NSString *commentblueKey;
extern NSString *commandredKey;
extern NSString *commandgreenKey;
extern NSString *commandblueKey;
extern NSString *markerredKey;
extern NSString *markergreenKey;
extern NSString *markerblueKey;
extern NSString *indexredKey;
extern NSString *indexgreenKey;
extern NSString *indexblueKey;

extern NSString *background_RKey;
extern NSString *background_GKey;
extern NSString *background_BKey;
extern NSString *backgroundAlphaKey; // added by Terada
extern NSString *foreground_RKey;
extern NSString *foreground_BKey;
extern NSString *foreground_GKey;
extern NSString *insertionpoint_RKey;
extern NSString *insertionpoint_GKey;
extern NSString *insertionpoint_BKey;

extern NSString *tabsKey;
extern NSString *WarnForShellEscapeKey;
extern NSString *ptexUtfOutputEnabledKey; // zenitani 1.35 (C)
// mitsu 1.29 (O)
extern NSString *PdfColorMapKey;
extern NSString *PdfFore_RKey;
extern NSString *PdfFore_GKey;
extern NSString *PdfFore_BKey;
extern NSString *PdfFore_AKey;
extern NSString *PdfBack_RKey;
extern NSString *PdfBack_GKey;
extern NSString *PdfBack_BKey;
extern NSString *PdfBack_AKey;
extern NSString *PdfColorParam1Key;
extern NSString *PdfColorParam2Key;
extern NSString *PdfPageBack_RKey;
extern NSString *PdfPageBack_GKey;
extern NSString *PdfPageBack_BKey;
extern NSString *ExternalEditorTypesetAtStartKey;
extern NSString *ConvertLFKey;
extern NSString *UseOgreKitKey;
extern NSString *FindMethodKey;
extern NSString *BringPdfFrontOnAutomaticUpdateKey;
extern NSString *BringPdfFrontOnTypesetKey;
extern NSString *SourceWindowAlphaKey;
extern NSString *PreviewWindowAlphaKey;
extern NSString *ConsoleWindowAlphaKey;
extern NSString *OtherTrashExtensionsKey;
extern NSString *AggressiveTrashAUXKey;
extern NSString *ShowSyncMarksKey;
extern NSString *AcceptFirstMouseKey;
extern NSString *UseOldHeadingCommandsKey;
extern NSString *SyncMethodKey;
extern NSString *UseOutlineKey;
extern NSString *LeftRightArrowsAlwaysPageKey;
extern NSString *ReleaseDocumentClassesKey;
extern NSString *RedConsoleAfterErrorKey;
extern NSString *PreviewDrawerOpenKey;
extern NSString *ConTeXtTagsKey;
extern NSString *RevisePathKey;
extern NSString *OtherTeXExtensionsKey;
extern NSString *ReleaseDocumentOnLeopardKey;
extern NSString *BibDeskCompletionKey;
extern NSString *SyncTeXOnlyKey;
extern NSString *ConsoleBackgroundColor_RKey;
extern NSString *ConsoleBackgroundColor_GKey;
extern NSString *ConsoleBackgroundColor_BKey;
extern NSString *ConsoleBackgroundAlphaKey; // added by Terada
extern NSString *ConsoleForegroundColor_RKey;
extern NSString *ConsoleForegroundColor_GKey;
extern NSString *ConsoleForegroundColor_BKey;
extern NSString *ConsoleFontNameKey;
extern NSString *ConsoleFontSizeKey;
extern NSString *ConsoleWidthResizeKey;
extern NSString *RightJustifyKey;
extern NSString *CommandCompletionCharKey;
extern NSString *CommandCompletionAlternateMarkShortcutKey;
extern NSString *showSpaceCharacterKey; // added by Terada
extern NSString *showFullwidthSpaceCharacterKey; // added by Terada
extern NSString *showTabCharacterKey; // added by Terada
extern NSString *showNewLineCharacterKey; // added by Terada
extern NSString *SpaceCharacterKindKey; // added by Terada
extern NSString *FullwidthSpaceCharacterKindKey; // added by Terada
extern NSString *TabCharacterKindKey; // added by Terada
extern NSString *NewLineCharacterKindKey; // added by Terada
extern NSString *LastStyNameKey; // added by Terada
extern NSString *KpsetoolKey; // added by Terada
extern NSString *BibTeXengineKey; // added by Terada

// end mitsu 1.29

extern NSString *SmartInsertDeleteKey; // Koch
extern NSString *AutomaticDataDetectionKey; // Koch
extern NSString *AutomaticLinkDetectionKey; // Koch
extern NSString *AutomaticTextReplacementKey; // Koch
extern NSString *AutomaticDashSubstitutionKey; // Koch
extern NSString *AutomaticQuoteSubstitutionKey; // Koch
extern NSString *AutomaticUTF8MACtoUTF8ConversionKey; //Koch
extern NSString *AutoOpenRootFileKey;
extern NSString *MiniaturizeRootFileKey;
extern NSString *highlightBracesRedKey; //Koch
extern NSString *highlightBracesBlueKey; //Koch
extern NSString *highlightBracesGreenKey; //Koch
extern NSString *highlightContentRedKey; //Koch
extern NSString *highlightContentGreenKey; //Koch
extern NSString *highlightContentBlueKey; //Koch
extern NSString *invisibleCharRedKey; //Koch
extern NSString *invisibleCharGreenKey; //Koch
extern NSString *invisibleCharBlueKey; //Koch
extern NSString *brieflyFlashYellowForMatchKey; //Koch
extern NSString *syncWithRedOvalsKey;
extern NSString *AutoSaveKey;
extern NSString *FixLineNumberScrollKey;
extern NSString *RightJustifyIfAnyKey; //Koch; right justify lines containing Persian anywhere in the line
extern NSString *AutoSaveEnabledKey;
extern NSString *fullscreenPageStyleKey;
extern NSString *fullscreenResizeOptionKey;
extern NSString *ScreenFontForLogAndConsoleKey;
extern NSString *WatchServerKey;
extern NSString *SourceInterlineSpaceKey;
extern NSString *SpellingLanguageKey;
extern NSString *SpellingAutomaticLanguageKey;
extern NSString *TagMenuInMenuBarKey;
extern NSString *ResetSourceTextColorEachTimeKey;
extern NSString *SourceAndPreviewInSameWindowKey;
extern NSString *DocumentSplitWindowPositionKey;
extern NSString *TabIndentKey;
extern NSString *SwitchSidesKey;
extern NSString *SourceScrollElasticityKey;
extern NSString *FixPreviewBlurKey;
extern NSString *InterpolationValueKey;
extern NSString *ConsoleWindowFixedPosKey;
extern NSString *ConsoleWindowPosModeKey;
extern NSString *YosemiteScrollBugKey;
extern NSString *SparkleAutomaticUpdateKey;
extern NSString *SparkleIntervalKey;
extern NSString *reverseSyncRedKey;
extern NSString *reverseSyncGreenKey;
extern NSString *reverseSyncBlueKey;
extern NSString *AutomaticSpellingCorrectionEnabledKey;
extern NSString *FixSplitBlankPagesKey;
extern NSString *IndexColorStartKey;
extern NSString *spellingLanguageDefaultKey;
extern NSString *spellingAutomaticDefaultKey;
extern NSString *originalSpellingKey;
extern NSString *continuousHighSierraFixKey;
extern NSString *tabsAlsoForInputFilesKey;
extern NSString *FlashFixKey;
extern NSString *FlashDelayKey;
extern NSString *DefaultLiteThemeKey;
extern NSString *DefaultDarkThemeKey;
extern NSString *EditorCanAddBracketsKey;
extern NSString *ColorImmediatelyKey;
extern NSString *OpenWithSourceInFrontKey;
extern NSString *SourceFirstLineHeadIndentKey;
extern NSString *SourceHeadIndentKey;
extern NSString *expl3SyntaxColoringKey;
extern NSString *SyntaxColorFootnoteKey;
extern NSString *CreateLabelListKey;
extern NSString *CreateTagListKey;
extern NSString *UseNewTagsAndLabelsKey;
extern NSString *TurnOffCommandSpellCheckKey;
extern NSString *TurnOffCommentSpellCheckKey;
extern NSString *TurnOffParameterSpellCheckKey;
extern NSString *ExceptionListExcludesParametersKey; // if YES while turning off command spell checking, list of words to spell check parameters
extern NSString *ExtraCommandsToCheckParametersKey; // array of keywords whose parameters should be spell checked
extern NSString *ExtraCommandsNotToCheckParametersKey; // array of keywhords whose parameters should not be spell checked
extern NSString *DoNotFixTeXCrashKey;
extern NSString *DisplayLogInfoKey;
extern NSString *UseTerminationHandlerKey;
extern NSString *TextMateSyncKey;
extern NSString *OtherEditorSyncKey;



// end defaults


/*" Paths "*/
extern NSString *DesktopPath;
extern NSString *MoviesPath;
extern NSString *DocumentsPath;
extern NSString *TeXShopPath;
extern NSString *TexTemplatePath;
extern NSString *TexTemplateMorePath;
extern NSString *StationeryPath;
extern NSString *LatexPanelPath;
extern NSString *MatrixPanelPath; // Jonas' Matrix addition
extern NSString *BinaryPath;
extern NSString *EnginePath;
extern NSString *EngineInactivePath;
extern NSString *ScriptsPath;
extern NSString *NewPath;
extern NSString *TempPath;
extern NSString *TempOutputKey;
extern NSString *AutoCompletionPath;
extern NSString *MenuShortcutsPath;
extern NSString *MacrosPath;
extern NSString *CommandCompletionFolderPath;
extern NSString *CommandCompletionPath; // mitsu 1.29 (P)
extern NSString *DraggedImageFolderPath;
extern NSString *DraggedImagePath; // mitsu 1.29 drag & drop
extern NSString *ColorPath;


/*" Notifications "*/
extern NSString *SyntaxColoringChangedNotification;
extern NSString *DocumentFontChangedNotification;
extern NSString *DocumentFontRememberNotification;
extern NSString *DocumentFontRevertNotification;
extern NSString *ConsoleFontChangedNotification;
extern NSString *ConsoleBackgroundColorChangedNotification;
extern NSString *ConsoleForegroundColorChangedNotification;
extern NSString *SourceBackgroundColorChangedNotification;
extern NSString *SourceTextColorChangedNotification;
extern NSString *SourceColorChangedNotification;
extern NSString *PreviewColorChangedNotification;
extern NSString *PreviewBackgroundColorChangedNotification;
extern NSString *MagnificationChangedNotification;
extern NSString *MagnificationRememberNotification;
extern NSString *MagnificationRevertNotification;
extern NSString *DocumentSyntaxColorNotification;
extern NSString *DocumentAutoCompleteNotification;
extern NSString *DocumentBibDeskCompleteNotification;
extern NSString *ExternalEditorNotification;
extern NSString *CommandCompletionCharNotification;



/*" Other variables "*/
extern TSFilterMode			g_shouldFilter;		/*" Used for Japanese yen conversion "*/
extern NSInteger			g_texChar;			/*" The tex command character; usually \ but yen in Japanese yen "*/
extern NSInteger            g_commentChar;


extern NSStringEncoding    NSISOLatin9StringEncoding;

extern NSInteger					g_macroType; // = EngineCommand for current window

extern NSArray*			g_taggedTeXSections; /*" Used by Tag menu; modified slightly for Japanese yen "*/
extern NSArray*			g_taggedTagSections; /*" Used by Tag menu; "*/
extern NSArray*         fileExtensions; /*" Used by SaveAs Panel; "*/
extern NSArray*         commandsToSpellCheck; /*"Used by Syntax Coloring; their parameters should all be spell checked"*/
extern NSArray*         commandsNotToSpellCheck; /*"Used by Syntax Coloring; their parameters should all be spell checked"*/
extern NSArray*         userCommandsToSpellCheck;
extern NSArray*         userCommandsNotToSpellCheck;

extern BOOL				fromMenu;
extern BOOL             doAutoSave;
extern BOOL             activateBauerPatch; // this is set in TSAppDelegate and turns on or off Bauer's patch to watch servers and catch file changes
extern BOOL             atLeastMavericks;
extern BOOL             atLeastElCapitan;
extern BOOL             atLeastSierra;
extern BOOL             atLeastHighSierra;
extern BOOL             atLeastMojave;
extern BOOL             BuggyHighSierra;
extern BOOL             editorCanAddBrackets;

// Command completion
extern NSString *g_commandCompletionChar;	/*" The key triggering completion. Always set to ESC in finishCommandCompletionConfigure "*/
extern NSMutableString *g_commandCompletionList;/*" The list of completions, read from CommandCompletion.txt "*/
extern BOOL g_canRegisterCommandCompletion;	/*" This is set to NO while e.g. CommandCompletion.txt is open "*/

// Below are colors which tend to be set just as they are needed
// We make them globals, and thus set them from the new Color Preferences

extern NSColor *InvisibleColor;
extern NSColor *ReverseSyncColor;
extern NSColor *PreviewBackgroundColor; /*" The background color for all Preview window PDFKitView pages "*/
extern NSDictionary *highlightBracesColorDict; // added by Terada
extern NSDictionary *highlightContentColorDict; // added by Terada
extern NSColor *ImageForegroundColor;
extern NSColor *ImageBackgroundColor;
extern NSColor *PreviewDirectSyncColor;

#define LEOPARD 568 // added by Terada

extern NSString *placeholderString;
extern NSString *startcommentString;
extern NSString *endcommentString;
extern NSString *ConsoleWindowNameKey;

extern NSDictionary *liteColors;
extern NSDictionary *darkColors;

extern NSArray *userCommandsToSpellCheck;

extern NSPoint menuPoint;
// extern double ppx, ppy;

