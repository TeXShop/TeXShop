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
extern NSString *DocumentFontKey;
extern NSString *DocumentWindowFixedPosKey;
extern NSString *DocumentWindowNameKey;
extern NSString *DocumentWindowPosModeKey;
extern NSString *MakeEmptyDocumentKey;
extern NSString *LatexCommandKey;
extern NSString *LatexGSCommandKey;
extern NSString *SavePSEnabledKey;
extern NSString *LatexScriptCommandKey;
extern NSString *ParensMatchingEnabledKey;
extern NSString *PdfMagnificationKey;
extern NSString *NoScrollEnabledKey;
extern NSString *PdfWindowFixedPosKey;
extern NSString *PdfWindowNameKey;
extern NSString *PdfWindowPosModeKey;
extern NSString *SaveDocumentFontKey;
extern NSString *SyntaxColoringEnabledKey;
extern NSString *TetexBinPathKey;
extern NSString *TexCommandKey;
extern NSString *TexGSCommandKey;
extern NSString *TexScriptCommandKey;
extern NSString *TexTemplatePathKey;
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
extern NSString *teTeXBinLocation;

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

/*" Other variables "*/
extern BOOL documentsHaveLoaded;


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
