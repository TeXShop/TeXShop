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
extern NSString *SaveDocumentFontKey;
extern NSString *SyntaxColoringEnabledKey;
extern NSString *TetexBinPathKey;
extern NSString *GSBinPathKey;
extern NSString *TexCommandKey;
extern NSString *TexGSCommandKey;
extern NSString *TexScriptCommandKey;
extern NSString *TexTemplatePathKey;
extern NSString *LatexPanelPathKey;
extern NSString *AutoCompletionPathKey;
extern NSString *MenuShortcutsPathKey;
extern NSString *MacrosPathKey;
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
extern NSString *ExternalEditorNotification;


/*" Other variables "*/
// extern BOOL documentsHaveLoaded;
extern NSMutableDictionary 	*TSEnvironment;	/*" Store for environment for subtasks, set in TSPreferences "*/
extern int			shouldFilter;   /*" Used for Japanese yen conversion "*/
extern int			texChar;	/*" The tex command character; usually \ but yen in Japanese yen "*/
extern NSDictionary		*autocompletionDictionary;  // added by Greg Landweber
/* Code by Anton Leuski */
extern NSArray*			kTaggedTeXSections; /*" Used by Tag menu; modified slightly for Japanese yen "*/
extern NSArray*			kTaggedTagSections; /*" Used by Tag menu; "*/




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

