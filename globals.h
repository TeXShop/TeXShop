//
//  globals.h
//  TeXShop
//
//  Created by dirk on Thu Dec 07 2000.
//

#import <Foundation/Foundation.h>

/*" global defines for TeXShop.app "*/
extern NSString *DefaultCommandKey;
extern NSString *DefaultScriptKey;
extern NSString *ConsoleBehaviorKey;
extern NSString *SaveRelatedKey;
extern NSString *DocumentFontKey;
extern NSString *DocumentWindowFixedPosKey;
extern NSString *DocumentWindowNameKey;
extern NSString *DocumentWindowPosModeKey;
extern NSString *LatexPanelNameKey;
extern NSString *MakeEmptyDocumentKey;
extern NSString *UseExternalEditorKey;
extern NSString *EncodingKey;
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
extern NSString *AutoCompleteEnabledKey;
extern NSString *PdfMagnificationKey;
extern NSString *NoScrollEnabledKey;
extern NSString *PdfWindowFixedPosKey;
extern NSString *PdfWindowNameKey;
extern NSString *PdfWindowPosModeKey;
extern NSString *PdfPageStyleKey; // mitsu 1.29 (O)
extern NSString *PdfRefreshKey; 
extern NSString *RefreshTimeKey;
extern NSString *PdfFileRefreshKey; 
extern NSString *PdfFirstPageStyleKey;
extern NSString *PdfFitSizeKey; // mitsu 1.29 (O)
extern NSString *PdfCopyTypeKey; // mitsu 1.29 (O) 
extern NSString *PdfExportTypeKey; // mitsu 1.29 (O) 
extern NSString *PdfMouseModeKey; // mitsu 1.29 (O)
extern NSString *PdfQuickDragKey; // mitsu 1.29 drag & drop
extern NSString *SaveDocumentFontKey;
extern NSString *SyntaxColoringEnabledKey;
extern NSString *FastColoringKey;
extern NSString *KeepBackupKey;
extern NSString *TetexBinPathKey;
extern NSString *GSBinPathKey;
extern NSString *TexCommandKey;
extern NSString *TexGSCommandKey;
extern NSString *TexScriptCommandKey;
extern NSString *TexTemplatePathKey;
extern NSString *MetaPostCommandKey;
extern NSString *BibtexCommandKey;
extern NSString *DistillerCommandKey;
extern NSString *LatexPanelPathKey;
extern NSString *MatrixPanelPathKey; // Jonas' Matrix addition
extern NSString *BinaryPathKey;
extern NSString *ScriptsPathKey;
extern NSString *TempPathKey;
extern NSString *AutoCompletionPathKey;
extern NSString *MenuShortcutsPathKey;
extern NSString *MacrosPathKey;
extern NSString *CommandCompletionPathKey; // mitsu 1.29 (P)
extern NSString *DraggedImagePathKey; // mitsu 1.29 drag & drop
extern NSString *TSHasBeenUsedKey;
extern NSString *UserInfoPathKey;
extern NSString *commentredKey;
extern NSString *commentgreenKey;
extern NSString *commentblueKey;
extern NSString *commandredKey;
extern NSString *commandgreenKey;
extern NSString *commandblueKey;
extern NSString *markerredKey;
extern NSString *markergreenKey;
extern NSString *markerblueKey;
extern NSString *tabsKey;
extern NSString *background_RKey;
extern NSString *background_GKey;
extern NSString *background_BKey;
extern NSString *WarnForShellEscapeKey;
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
// end mitsu 1.29


/*" Exceptions "*/
extern NSString *XDirectoryCreation;

/*" Notifications "*/
extern NSString *SyntaxColoringChangedNotification;
extern NSString *DocumentFontChangedNotification;
extern NSString *DocumentFontRememberNotification;
extern NSString *DocumentFontRevertNotification;
extern NSString *MagnificationChangedNotification;
extern NSString *MagnificationRememberNotification;
extern NSString *MagnificationRevertNotification;
extern NSString *DocumentSyntaxColorNotification;
extern NSString *DocumentAutoCompleteNotification;
extern NSString *ExternalEditorNotification;


/*" Other variables "*/
// extern BOOL documentsHaveLoaded;
extern NSMutableDictionary 	*TSEnvironment;	/*" Store for environment for subtasks, set in TSPreferences "*/
extern int			shouldFilter;   /*" Used for Japanese yen conversion "*/
extern int			texChar;	/*" The tex command character; usually \ but yen in Japanese yen "*/
extern NSDictionary		*autocompletionDictionary;  // added by Greg Landweber
extern int			macroType; // = EngineCommand for current window
/* Code by Anton Leuski */
extern NSArray*			kTaggedTeXSections; /*" Used by Tag menu; modified slightly for Japanese yen "*/
extern NSArray*			kTaggedTagSections; /*" Used by Tag menu; "*/
// mitsu 1.29 (P)-- command completion
extern NSString *commandCompletionChar;
extern NSMutableString *commandCompletionList;
extern BOOL canRegisterCommandCompletion;
// end mitsu 1.29
// mitsu 1.29 (O)
//extern int imageCopyType; // defined in MyPDFView.m // mitsu 1.29b not used 
// end mitsu 1.29



/*" Symbolic constants for the matrix used in 'Source window Position' of the TSPreferences. "*/
typedef enum _DocumentWindowPosition 
{
    DocumentWindowPosFixed = 0,
    DocumentWindowPosSave = 1
} DocumentWindowPosition;

/*" Symbolic constants for the matrix used in 'PDF window Position' of the TSPreferences. "*/
typedef enum _PdfWindowPosition 
{
    PdfWindowPosFixed = 0,
    PdfWindowPosSave = 1
} PdfWindowPosition;

/*" Symbolic constants for the display mode to use "*/
typedef enum _PdfDisplayMode
{
    PdfDisplayModeApple = 0,
    PdfDisplayModeGhostscript = 1
} PdfDisplayMode;

/*" Symbolic constants for the Ghostscript color mode. "*/
typedef enum _GsColorMode
{
    GsColorModeGrayscale = 0,
    GsColorMode256 = 1,
    GsColorModeThousands = 2
} GsColorMode;

/*" Symbolic constants for the default Typeset program to use. "*/
typedef enum _DefaultCommand
{
    DefaultCommandTeX = 0,
    DefaultCommandLaTeX = 1,
    DefaultCommandConTEXt = 2,
    DefaultCommandOmega = 3
} _DefaultCommand;


/*" Symbolic constants for Japanese conversion "*/
typedef enum _ShiftCommand
{
    filterNone = 0,
    filterMacJ = 1,
    filterNSSJIS = 2
} _ShiftCommand;

/*" Symbolic constants to determine TeX engine "*/
/*" These are also tags on the typeset menu and the pulldown toolbar menus "*/
typedef enum _EngineCommand
{
    TexEngine = 1,
    LatexEngine = 2,
    BibtexEngine = 3,
    IndexEngine = 4,
    MetapostEngine = 5,
    ContextEngine = 6,
    MetafontEngine = 7
} _EngineCommand;

/*" Symbolic constants for Root File tests "*/
typedef enum _RootCommand
{
    RootForOpening = 1,
    RootForTexing = 2,
    RootForPrinting = 3,
    RootForSwitchWindow = 4,
    RootForPdfSync = 5
} _RootCommand;

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

/*" Image copy/export types for MyPDFView"*/
typedef enum _ImageCopyType
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
} _ImageCopyType;

// end mitsu 1.29

