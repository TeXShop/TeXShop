/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This file drive the users interaction with PDFAnnotation Editor at the
         PDFView level. This includes: interacting with the menu bar such as saving the
         current document, printing the document, and adding new annotations to the view;
         interacting with annotations such as selecting, dragging and resizing the current
         annotation; and interacting with the font manager.
*/


#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "MyPDFKitView.h"


@interface MyPDFAnnotations : MyPDFKitView
{
	PDFAnnotation	*_activeAnnotation;
	NSPoint			_mouseDownLoc;
	NSPoint			_clickDelta;
	NSRect			_wasBounds;
	BOOL			_mouseDownInAnnotation;
	BOOL			_dragging;
	BOOL			_resizing;
	BOOL			_editMode;
}

// - (void) saveDocument: (id) sender;
// - (void) saveDocumentAs: (id) sender;
 - (void) transformContextForPage: (PDFPage *) page;
 - (void) selectAnnotation: (PDFAnnotation *) annotation;
 - (void) annotationChanged;

 - (void) setEditMode: (BOOL) edit;

// - (void) delete: (id) sender;

// - (void) reflectFont;
// - (NSRect) resizeThumbForRect: (NSRect) rect rotation: (NSInteger) rotation;

@end
