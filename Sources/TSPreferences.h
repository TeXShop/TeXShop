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
 * $Id: TSPreferences.h 133 2006-05-21 11:52:24Z fingolfin $
 *
 * Created by dirk on Thu Dec 07 2000.
 *
 */

#import "UseMitsu.h"
#import "UseSparkle.h"

#import <AppKit/AppKit.h>

@interface TSPreferences : NSObject
{
	IBOutlet NSWindow	*_prefsWindow;			/*" connected to the window "*/
	IBOutlet NSTextField	*_documentFontTextField;	/*" connected to "Document Font" "*/
    IBOutlet NSTextField	*_consoleFontTextField;     /*" connected to "Console Font" */
	IBOutlet NSMatrix	*_sourceWindowPosMatrix;	/*" connected to "Source Window Position" "*/
	IBOutlet NSButton	*_docWindowPosButton;		/* connected to set current position button */
    IBOutlet NSButton	*_consoleWindowPosButton;		/* connected to set current position button */
    IBOutlet NSMatrix	*_consoleWindowPosMatrix;		/* connected to set current position button */
	IBOutlet NSMatrix		*_commandCompletionMatrix; /* select ESCAPE or TAB */
	IBOutlet NSMatrix       *_findMatrix;                   /* connected to Find Panel */
    IBOutlet NSMatrix       *_lineSizeMatrix;               /* connected to Line Number Size */
    IBOutlet NSMatrix       *_wrapMatrix;                    /* connected to Wrap Panel */
    IBOutlet NSPanel    *_samplePanel;
    IBOutlet NSTextView *_fontTextView;
    IBOutlet NSPanel    *stylePanel;
    // for Color
    IBOutlet NSTextField *styleTitle;
    NSString *oldLiteStyle;
    NSString *oldDarkStyle;

    IBOutlet NSButton       *_tabIndentButton;		    /*" connected to "Use Tab" "*/
    IBOutlet NSButton       *_syntaxColorLineButton;    /*" connected to "Syntax Active Line Coloring" "*/
	IBOutlet NSButtonCell	*_syntaxColorButton;		/*" connected to "Syntax Coloring" "*/
    IBOutlet NSButton       *_blockCursorButton;        /*" connected to "Block Cursor" "*/
    IBOutlet NSButton       *_macroButton;              /*" connected to "Font for Log and Macro" "*/
	IBOutlet NSButtonCell   *_selectActivateButton;     /*" connected to "Select on Activate" "*/
	IBOutlet NSButtonCell	*_parensMatchButton;		/*" connected to "Parens Matching "*/
	IBOutlet NSButtonCell	*_spellCheckButton;		    /*" connected to "SpellChecking "*/
    IBOutlet NSButtonCell   *_autoSpellCorrectButton;   /*" connect to "Auto Spell Correcting "*/
    IBOutlet NSButtonCell   *_editorAddBracketsButton;  /*" connect to "Editor Can Add Brackets "*/
	IBOutlet NSButtonCell	*_autoCompleteButton;		/*" connected to "Auto Completion "*/
	IBOutlet NSButtonCell	*_bibDeskCompleteButton;	/*" connected to BibDesk Completions "*/
	IBOutlet NSButtonCell	*_lineNumberButton;			/*" connected to Line Number "*/
    IBOutlet NSButtonCell	*_tagMenuButton;			/*" connected to Line Number "*/
	IBOutlet NSButtonCell	*_midEastButton; /*" connected to Arabic, Persian, Hebrew "*/
    IBOutlet NSButtonCell   *_autoSaveButton; /*" connected to AutoSave "*/
	IBOutlet NSButton		*_openEmptyButton;		/*" open empty document on start "*/
	IBOutlet NSButton		*_externalEditorButton;		/*" use external editor "*/
	IBOutlet NSPopUpButton	*_defaultEncodeMatrix;		/*" text encoding "*/
    IBOutlet NSPopUpButton  *_openAsTabsMatrix;     /*" windows opening behavior "*/
	IBOutlet NSMatrix	*_pdfWindowPosMatrix;		/*" connected to "PDF Window Position" "*/
	IBOutlet NSButton	*_pdfWindowPosButton;		/* connected to current position button */
    IBOutlet NSMatrix    *_htmlWindowPosMatrix;        /*" connected to "HTML Window Position" "*/
    IBOutlet NSButton    *_htmlWindowPosButton;        /* connected to current position button */
    IBOutlet NSButton       *_antialiasButton;      /* connect to antialias checkbox */
    IBOutlet NSButton       *oneWindowButton;
	IBOutlet NSTextField	*_magTextField;			/*" connected to magnification text field "*/
	IBOutlet NSButton	*_scrollButton;			/*" connected to scroll button "*/
	IBOutlet NSTextField	*_texCommandTextField;		/*" connected to "TeX program" "*/
	IBOutlet NSTextField	*_latexCommandTextField;	/*" connected to "Latex program" "*/
	IBOutlet NSButton	*_escapeWarningButton;		/*" connected to "Shell Escape Warning" "*/
	IBOutlet NSTextField	*_texGSCommandTextField;	/*" connected to "Tex + GS" "*/
	IBOutlet NSTextField	*_latexGSCommandTextField;	/*" connected to "Latex + GS" "*/
	IBOutlet NSButton	*_savePSButton;			/*" connect to save postscript "*/
	IBOutlet NSTextField	*_tetexBinPathField;		/*" connected to tetex bin path "*/
    IBOutlet NSTextField    *_altPathField;             /*" connected to alternate path "*/
	IBOutlet NSTextField	*_gsBinPathField;		/*" connected to tetex bin path "*/
	IBOutlet NSTextField	*_texScriptCommandTextField;	/*" connected to "Personal Tex" "*/
	IBOutlet NSTextField	*_latexScriptCommandTextField; /*" connected to Personal Latex" "*/
    IBOutlet NSTextField    *_alternateEngineTextField;    /*" connected to "Personal Tex" "*/
	IBOutlet NSMatrix	*_defaultScriptMatrix;		/*" connected to "Default Script" "*/
	IBOutlet NSMatrix       *_defaultMetaPostMatrix;        /*" connected to "MetaPost" "*/
	IBOutlet NSMatrix       *_defaultBibtexMatrix;          /*" connected to "Bibtex" "*/ // comment out by Terada
	IBOutlet NSMatrix	*_syncMatrix;			/*" connected to "Sync Method" "*/
	IBOutlet NSMatrix	*_defaultCommandMatrix;		/*" connected to "Default Program" "*/
	IBOutlet NSTextField    *_engineTextField;
	IBOutlet NSMatrix       *_distillerMatrix;              /*" connected to "Distiller" "*/
	IBOutlet NSMatrix	*_consoleMatrix;		/*" connected to "Show Console" "*/
	IBOutlet NSFormCell	*_tabsTextField;		/*" connected to tab size text field "*/
    IBOutlet NSTextField *tabIndentField;
    IBOutlet NSTextField *firstParagraphIndentField;
    IBOutlet NSTextField *remainingParagraphIndentField;
    IBOutlet NSTextField *interlineSpacingField;
	IBOutlet NSButton	*_saveRelatedButton;		/*" connected to Save Related Files "*/
    IBOutlet NSButton    *_useTransparencyButton; /*" connected to use -dALLOWPSTRANSPARENCY "*/
    IBOutlet NSButton   *_syncTabButton;
	IBOutlet NSButton       *_autoPDFButton;
	IBOutlet NSButton       *_ptexUtfOutputButton;          // zenitani 1.35 (C)
	IBOutlet NSButton		*_convertUTFButton;
    IBOutlet NSButton       *_openRootFileButton;
    IBOutlet NSButton       *_miniaturizeRootFileButton;
//	IBOutlet NSColorWell	*_sourceBackgroundColorWell;
 //   IBOutlet NSColorWell	*_sourceTextColorWell;
//	IBOutlet NSColorWell	*_previewBackgroundColorWell;
//	IBOutlet NSColorWell	*_consoleBackgroundColorWell;
//	IBOutlet NSColorWell	*_consoleForegroundColorWell;
//	IBOutlet NSColorWell	*_highlightBracesColorWell;
	IBOutlet NSTabView		*_tabView;
	IBOutlet NSMatrix		*_consoleResizeMatrix;
    IBOutlet NSMatrix       *_blockWidthMatrix;
    IBOutlet NSMatrix       *_blockSideMatrix;
 
	IBOutlet NSButton *_showInvisibleCharactersButton; // added by Terada
	IBOutlet NSButton *_showTabCharacterButton; // added by Terada
	IBOutlet NSButton *_showSpaceCharacterButton; // added by Terada
	IBOutlet NSButton *_showNewLineCharacterButton; // added by Terada
	IBOutlet NSButton *_showFullwidthSpaceCharacterButton; // added by Terada
	IBOutlet NSMatrix *_TabCharacterKindMatrix; // added by Terada
	IBOutlet NSMatrix *_SpaceCharacterKindMatrix; // added by Terada
	IBOutlet NSMatrix *_NewLineCharacterKindMatrix; // added by Terada
	IBOutlet NSMatrix *_FullwidthSpaceCharacterKindMatrix; // added by Terada
	IBOutlet NSButton *_alwaysHighlightButton; // added by Terada
	IBOutlet NSButton *_highlightContentButton; // added by Terada
	IBOutlet NSButton *_showIndicatorForMoveButton; // added by Terada
	IBOutlet NSButton *_beepButton; // added by Terada
	IBOutlet NSButton *_flashBackgroundButton; // added by Terada
	IBOutlet NSButton *_checkBraceButton; // added by Terada
	IBOutlet NSButton *_checkBracketButton; // added by Terada
	IBOutlet NSButton *_checkSquareBracketButton; // added by Terada
	IBOutlet NSButton *_checkParenButton; // added by Terada
	IBOutlet NSTextField *_kpsetoolField; // added by Terada
	IBOutlet NSTextField *_bibTeXengineField; // added by Terada
//	IBOutlet NSButton *_makeatletterButton; // added by Terada
    
    IBOutlet NSTextField *_HtmlHomeField;
    
    IBOutlet NSButton  *_sparkleAutomaticButton;
    IBOutlet NSMatrix  *_sparkleIntervalMatrix;
    
    IBOutlet NSButton  *_useNewToolbarButton;
    IBOutlet NSButton  *_useNewToolbarIconsButton;
    
    IBOutlet NSButtonCell   *_spellCheckCommands;
    IBOutlet NSButtonCell   *_spellCheckParameters;
    IBOutlet NSButtonCell   *_spellCheckComments;

	NSUndoManager		*_undoManager;			/*" used for discarding all changes when the cancel button was pressed "*/
//	NSFont			*_documentFont;			/*" used to track the font that the user has selected for the document window "*/
//	NSFont			*_consoleFont;			/*" used to track the font that the user has selected for the console window "*/
	BOOL			fontTouched;			/*" if user fiddled with fonts and then cancelled,
																we restore the old one "*/
	BOOL			consoleFontTouched;
	BOOL			consoleBackgroundColorTouched;
	BOOL			consoleForegroundColorTouched;
	BOOL			sourceBackgroundColorTouched;
    BOOL            sourceTextColorTouched;
	BOOL			previewBackgroundColorTouched;
	BOOL			syntaxColorTouched;		/*" if user fiddled with syntax and then cancelled,
																we restore the old one "*/
    BOOL            syntaxColorLineTouched;        /*" if user fiddled with syntax and then cancelled,
                                                                we restore the old one "*/
	BOOL			oldSyntaxColor;			/*" value when preferences shown "*/
    BOOL            oldSyntaxLineColor;
	BOOL			autoCompleteTouched;
	BOOL			bibDeskCompleteTouched;
    BOOL            HtmlHomeTouched;
	BOOL			oldAutoComplete;
	BOOL			oldBibDeskComplete;
    BOOL            oldSparkleAutomaticUpdate;
    NSInteger       oldSparkleInterval;
    BOOL            oldNewToolbarIcons;
	BOOL			magnificationTouched;
	BOOL			externalEditorTouched;
	BOOL			encodingTouched;
	BOOL			commandCompletionCharTouched;
	BOOL            invisibleCharacterTouched; // added by Terada
	BOOL            highlightTouched; // added by Terada
	BOOL            kpsetoolTouched; // added by Terada
	BOOL            bibTeXengineTouched; // added by Terada
//	BOOL            makeatletterTouched; // added by Terada
    BOOL            sparkleTouched;
    BOOL            newToolbarIconsTouched;
    BOOL            xmlTagsTouched;
   
    IBOutlet NSPopUpButton  *dictionaryPopup;
	IBOutlet NSPopUpButton	*_pageStylePopup;// mitsu 1.29 (O) /*" connected to page style popup button "*/
	IBOutlet NSMatrix       *_firstPageMatrix;// /*" radio buttons for first page left or right in multipage display "*/
	IBOutlet NSPopUpButton	*_resizeOptionPopup;// mitsu 1.29 (O) /*" connected to resize option popup button "*/
	IBOutlet NSPopUpButton	*_imageCopyTypePopup;// mitsu 1.29 (O) /*" connected to image copy type popup button "*/
	IBOutlet NSPopUpButton	*_mouseModePopup;// mitsu 1.29 (O) /*" connected to default mouse mode popup button "*/
	IBOutlet NSButton	*_colorMapButton;// mitsu 1.29 (O)
	// IBOutlet NSColorWell	*_copyForeColorWell;// mitsu 1.29 (O)
	// IBOutlet NSColorWell	*_copyBackColorWell;// mitsu 1.29 (O)
	IBOutlet NSPopUpButton	*_colorParam1Popup;// mitsu 1.29 (O)
	IBOutlet NSMatrix	*_afterTypesettingMatrix;
    IBOutlet NSButton *useTwoWindowsButton;
    IBOutlet NSButton *useOneWindowButton;
    IBOutlet NSButton *useLeftSourceButton;
    IBOutlet NSButton *useRightSourceButton;
    
    // Color Tab
    IBOutlet NSPopUpButton  *LiteStyle;
    IBOutlet NSPopUpButton  *DarkStyle;
    IBOutlet NSPopUpButton  *EditingStyle;
    //Actual Colors
    IBOutlet NSColorWell    *SourceTextColorWell;
    IBOutlet NSColorWell    *SourceBackgroundColorWell;
    IBOutlet NSColorWell    *SourceInsertionPointColorWell;
    IBOutlet NSColorWell    *PreviewBackgroundColorWell;
    IBOutlet NSColorWell    *ConsoleTextColorWell;
    IBOutlet NSColorWell    *ConsoleBackgroundColorWell;
    IBOutlet NSColorWell    *LogTextColorWell;
    IBOutlet NSColorWell    *LogBackgroundColorWell;
    IBOutlet NSColorWell    *SyntaxCommentColorWell;
    IBOutlet NSColorWell    *SyntaxCommandColorWell;
    IBOutlet NSColorWell    *SyntaxMarkerColorWell;
    IBOutlet NSColorWell    *SyntaxIndexColorWell;
    IBOutlet NSColorWell    *FootnoteColorWell;
    IBOutlet NSColorWell    *EntryColorWell;
    
    IBOutlet NSColorWell    *EditorHighlightBracesColorWell;
    IBOutlet NSColorWell    *EditorHighlightContentColorWell;
    IBOutlet NSColorWell    *EditorInvisibleCharColorWell;
    IBOutlet NSColorWell    *EditorFlashColorWell;
    IBOutlet NSColorWell    *EditorReverseSyncColorWell;
    IBOutlet NSColorWell    *PreviewDirectSyncColorWell;
    IBOutlet NSColorWell    *SourceAlphaColorWell;
    IBOutlet NSColorWell    *PreviewAlphaColorWell;
    IBOutlet NSColorWell    *ConsoleAlphaColorWell;
    IBOutlet NSColorWell    *ImageForegroundColorWell;
    IBOutlet NSColorWell    *ImageBackgroundColorWell;
    
    IBOutlet NSColorWell    *BlockCursorColorWell;
    
    IBOutlet NSColorWell    *XMLCommentColorWell;
    IBOutlet NSColorWell    *XMLTagColorWell;
    IBOutlet NSColorWell    *XMLSpecialColorWell;  // for &
    IBOutlet NSColorWell    *XMLParameterColorWell;
    IBOutlet NSColorWell    *XMLValueColorWell;
    
    IBOutlet NSButton       *XMLchapter;
    IBOutlet NSButton       *XMLsection;
    IBOutlet NSButton       *XMLsubsection;
    IBOutlet NSButton       *XMLsubsubsection;
    IBOutlet NSButton       *XMLintroduction;
    IBOutlet NSButton       *XMLconclusion;
    IBOutlet NSButton       *XMLexercises;
    IBOutlet NSButton       *XMLproject;
    IBOutlet NSButton       *XMLfigure;
    IBOutlet NSButton       *XMLtable;
    IBOutlet NSButton       *XMLmark;
    
    NSMutableDictionary     *EditingColors;
    
}

@property (retain) NSFont		*documentFont;			/*" used to track the font that the user has selected for the document window "*/
@property (retain) NSFont		*consoleFont;			/*" used to track the font that the user has selected for the console window "*/
@property (retain) NSDictionary *fontAttributes;         /*" used to track the font attributes that the user has selected for the document window "*/

+ (id)sharedInstance;

//------------------------------------------------------------------------------
// target/action methods
//------------------------------------------------------------------------------
- (IBAction)showPreferences:sender;

- (IBAction)changeDocumentFont:sender;
- (IBAction)changeConsoleFont:sender;
- (IBAction)sourceWindowPosChanged:sender;
- (IBAction)currentDocumentWindowPosDefault:sender;
- (IBAction)syntaxColorPressed:sender;
- (IBAction)syntaxColorLinePressed:sender;
- (IBAction)blockCursorPressed:sender;
- (IBAction)MacroPressed:sender;
- (IBAction)blockWidthPressed:sender;
- (IBAction)blockSidePressed:sender;
- (IBAction)selectActivatePressed:sender;
- (IBAction)parensMatchPressed:sender;
- (IBAction)spellCheckPressed:sender;
- (IBAction)spellCorrectPressed:sender;
- (IBAction)editorAddBracketsPressed:sender;
- (IBAction)autoCompletePressed:sender;
- (IBAction)bibDeskCompletePressed:sender;
- (IBAction)tagMenuButtonPressed:sender;
- (IBAction)showInvisibleCharacterButtonPressed:sender; // added by Terada
- (IBAction)midEastButtonPressed:sender;
- (IBAction)autoSaveButtonPressed:sender;
- (IBAction)emptyButtonPressed:sender;
- (IBAction)externalEditorButtonPressed:sender;
- (IBAction)encodingChanged:sender;
- (IBAction)openAsTabsChanged:sender;
- (IBAction)tabsChanged:sender;
- (IBAction)useTabPressed:sender;
- (IBAction)tabIndentPressed:sender;
- (IBAction)firstParagraphIndentPressed:sender;
- (IBAction)remainingParagraphIndentPressed:sender;
- (IBAction)interlineSpacingPressed:sender;
- (IBAction)commandCompletionChanged:sender;
- (IBAction)findPanelChanged:sender;
- (IBAction)lineSizeChanged:sender;
- (IBAction)defaultEngineCall:sender;
- (IBAction)wrapPanelChanged:sender;


- (IBAction)pdfWindowPosChanged:sender;
- (IBAction)currentPdfWindowPosDefault:sender;
- (IBAction)htmlWindowPosChanged:sender;
- (IBAction)currentHtmlWindowPosDefault:sender;
- (IBAction)magChanged:sender;
- (IBAction)scrollPressed:sender;
- (IBAction)firstDoublePageChanged:sender;
- (IBAction)dictionaryPressed: sender;
- (IBAction)texProgramChanged:sender;
- (IBAction)latexProgramChanged:sender;
- (IBAction)escapeWarningChanged:sender;
- (IBAction)texGSProgramChanged:sender;
- (IBAction)latexGSProgramChanged:sender;
- (IBAction)savePSPressed:sender;
- (IBAction)tetexBinPathChanged:sender;
- (IBAction)altPathChanged:sender;
- (IBAction)gsBinPathChanged:sender;
- (IBAction)texScriptProgramChanged:sender;
- (IBAction)latexScriptProgramChanged:sender;
- (IBAction)alternateEngineChanged:sender;
- (IBAction)defaultScriptChanged:sender;
- (IBAction)syncChanged:sender;
// - (IBAction)defaultMetaPostChanged:sender;
//- (IBAction)defaultBibtexChanged:sender; // comment out by Terada
- (IBAction)distillerChanged:sender;
- (IBAction)defaultProgramChanged:sender;
- (IBAction)setEngine:sender;
- (IBAction)consoleBehaviorChanged:sender;
- (IBAction)saveRelatedButtonPressed:sender;
- (IBAction)syncTabButtonPressed:sender;
- (IBAction)autoPDFChanged:sender;
- (IBAction)antialiasChanged:sender;
- (IBAction)ptexUtfOutputPressed:sender; // zenitani 1.35 (C)
- (IBAction)convertUTFPressed:sender;
- (IBAction)openRootFilePressed:sender;
- (IBAction)miniaturizeRootFilePressed:sender;
- (IBAction)afterTypesettingChanged:sender;
- (IBAction)setSourceBackgroundColor:sender;
 - (IBAction)setSourceTextColor:sender;
 - (IBAction)setPreviewBackgroundColor:sender;
- (IBAction)setHighlightBracesColor:sender;
 - (IBAction)setConsoleBackgroundColor:sender;
 - (IBAction)setConsoleForegroundColor:sender;
- (IBAction)changeConsoleResize:sender;
- (IBAction)sourceAndPreviewInSameWindowChanged:sender;
- (IBAction)sourceOnLeftChanged:sender;
- (IBAction)closeSamplePanel:sender;




#ifdef MITSU_PDF
- (IBAction)pageStyleChanged:sender; // mitsu 1.29 (O)
- (IBAction)resizeOptionChanged:sender; // mitsu 1.29 (O)
- (IBAction)imageCopyTypeChanged:sender; // mitsu 1.29 (O)
- (NSPopUpButton *)imageCopyTypePopup; // mitsu 1.29b
- (IBAction)mouseModeChanged:sender; // mitsu 1.29 (O)
- (IBAction)colorMapChanged:sender; // mitsu 1.29 (O)
- (IBAction)copyForeColorChanged:sender; // mitsu 1.29 (O)
- (IBAction)copyBackColorChanged:sender; // mitsu 1.29 (O)
- (IBAction)colorParam1Changed:sender; // mitsu 1.29 (O)
#endif

- (IBAction)okButtonPressed:sender;
- (IBAction)cancelButtonPressed:sender;
- (IBAction)setDefaults:sender;

- (IBAction)highlightChanged:sender; // added by Terada
- (IBAction)invisibleCharacterChanged:sender; // added by Terada
- (IBAction)kpsetoolChanged:sender; // added by Terada
- (IBAction)bibTeXengineChanged:sender; // added by Terada
// - (IBAction)makeatletterChanged:sender; // added by Terada

- (IBAction)HtmlHomeChanged:sender;

- (IBAction)sparkleAutomaticCheck:sender;
- (IBAction)sparkleInterval:sender;

- (IBAction)NewToolbarIconsCheck:sender;

- (IBAction)spellCheckCommandPressed:sender;
- (IBAction)spellCheckParameterPressed:sender;
- (IBAction)spellCheckCommentPressed:sender;


//------------------------------------------------------------------------------
// API used by other TeXShop classes
//------------------------------------------------------------------------------
- (NSString *)relativePath: (NSString *)path fromFile: (NSString *)file; // added by zenitani, Feb 13, 2003

- (void)registerFactoryDefaults;

//------------------------------------------------------------------------------
// private API
//------------------------------------------------------------------------------
- (void)updateControlsFromUserDefaults:(NSUserDefaults *)defaults;
- (void)updateDocumentFontTextField;
- (void)updateConsoleFontTextField;

@end

@interface TSPreferences (Color)

- (void)PrepareColorPane:(NSUserDefaults *)defaults;

- (IBAction)LiteStyleChoice:sender;
- (IBAction)DarkStyleChoice:sender;
- (IBAction)EditingStyleChoice:sender;
- (IBAction)SaveEditedStyle:sender;
- (IBAction)SaveNewStyle:sender;
- (IBAction)NewStyleFromPrefs:sender;
// Actual Colors
- (IBAction)SourceTextColorChanged:sender;
- (IBAction)SourceBackgroundColorChanged:sender;
- (IBAction)SourceInsertionPointColorChanged:sender;
- (IBAction)PreviewBackgroundColorChanged:sender;
- (IBAction)ConsoleTextColorChanged:sender;
- (IBAction)ConsoleBackgroundColorChanged:sender;
- (IBAction)LogTextColorChanged:sender;
- (IBAction)LogBackgroundColorChanged:sender;
- (IBAction)SyntaxCommentColorChanged:sender;
- (IBAction)SyntaxCommandColorChanged:sender;
- (IBAction)SyntaxMarkerColorChanged:sender;
- (IBAction)SyntaxIndexColorChanged:sender;
- (IBAction)FootnoteColorChanged:sender;
- (IBAction)EntryColorChanged:sender;

- (IBAction)EditorReverseSyncChanged:sender;
- (IBAction)PreviewDirectSyncChanged:sender;
- (IBAction)EditorHighlightBracesChanged:sender;
- (IBAction)EditorHighlightContentChanged:sender;
- (IBAction)EditorInvisibleCharChanged:sender;
- (IBAction)EditorFlashChanged:sender;
- (IBAction)SourceAlphaChanged:sender;
- (IBAction)PreviewAlphaChanged:sender;
- (IBAction)ConsoleAlphaChanged:sender;
- (IBAction)ImageForegroundChanged:sender;
- (IBAction)ImageBackgroundChanged:sender;
- (IBAction)BlockCursorColorChanged:sender;

- (IBAction)XMLCommentChanged:sender;
- (IBAction)XMLTagChanged:sender;
- (IBAction)XMLSpecialChanged:sender;
- (IBAction)XMLParameterChanged:sender;
- (IBAction)XMLValueChanged:sender;

- (IBAction)XMLChapterButtonChanged:sender;
- (IBAction)XMLSectionButtonChanged:sender;
- (IBAction)XMLSubsectionButtonChanged:sender;
- (IBAction)XMLSubsubsectionButtonChanged:sender;
- (IBAction)XMLIntroductionButtonChanged:sender;
- (IBAction)XMLConclusionButtonChanged:sender;
- (IBAction)XMLExercisesButtonChanged:sender;
- (IBAction)XMLProjectButtonChanged:sender;
- (IBAction)XMLFigureButtonChanged:sender;
- (IBAction)XMLTableButtonChanged:sender;
- (IBAction)XMLMarkButtonChanged:sender;

- (IBAction)okForStylePanel:sender;
- (IBAction)cancelForStylePanel:sender;
- (void)okForColor;
- (void)cancelForColor;



@end
