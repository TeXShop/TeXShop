/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The implementation file for PDFViewEdit.
*/ 



#import "MyPDFAnnotations.h"


static NSRect RectPlusScale (NSRect aRect, float scale);


@implementation MyPDFAnnotations

//-------------------------------------------------------------------------------------------------------- saveDocument

/*
- (void) saveDocument: (id) sender
{
	[self saveDocumentAs: sender];
}

// ------------------------------------------------------------------------------------------------------ saveDocumentAs

- (void) saveDocumentAs: (id) sender
{
	NSSavePanel	*panel;
	
	panel = [NSSavePanel savePanel];
    [panel setAllowedFileTypes: @[ @"pdf" ]];
	
	// Run.
	if ([panel runModal] == NSModalResponseOK)
	{
		PDFDocument	*document;
		
		// Save file.
		[[self document] writeToURL: [panel URL]];
		
		// Clear active annotation.
		_activeAnnotation = NULL;
		
		// Set new file.
		document = [[[PDFDocument alloc] initWithURL: [panel URL]] autorelease];
		[self setDocument: document];
	}
}

// ------------------------------------------------------------------------------------------------------- printDocument

- (void) printDocument: (id) sender
{
	// Pass to PDF view.
	[self printWithInfo: [[[[self window] windowController] document] printInfo] autoRotate: YES];
}
 
*/


- (void) drawPage: (PDFPage *) pdfPage
{
	NSArray			*annotations;
	NSUInteger		annotCount;
	NSUInteger		i;
	
	// Let PDFView do most of the hard work.
	[super drawPage: pdfPage];
	
	// Skip out unless we are in 'edit mode'.
	// if (_editMode == NO)
	//	return;
    _editMode = YES;
	
	// Save.
	[NSGraphicsContext saveGraphicsState];
	
	// Tranform.
	[self transformContextForPage: pdfPage];
	
	// Frame all annotations in gray.
	[[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.3] set];
	
	// Walk array of annotations.
	annotations = [pdfPage annotations];
	annotCount = [annotations count];
	for (i = 0; i < annotCount; i++)
         NSFrameRectWithWidthUsingOperation([[annotations objectAtIndex: i] bounds], 1.0, NSCompositeSourceOver);
	
	// Handle the selected annotation.
	if ((_activeAnnotation) && ([_activeAnnotation page] == pdfPage))
	{
		NSRect			bounds;
		NSBezierPath	*path;
		
		bounds = [_activeAnnotation bounds];
		
		path = [NSBezierPath bezierPathWithRect: bounds];
		[path setLineJoinStyle: NSRoundLineJoinStyle];
		[[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 0.1] set];
		[path fill];
		[[NSColor redColor] set];
		[path stroke];
		
		// Draw resize handle.
		NSRectFill(NSIntegralRect([self resizeThumbForRect: bounds rotation: [pdfPage rotation]]));
	}
	
	// Restore.
	[NSGraphicsContext restoreGraphicsState];
}

// --------------------------------------------------------------------------------------------- transformContextForPage

- (void) transformContextForPage: (PDFPage *) page
{
	NSAffineTransform   *transform;
	NSRect              boxRect;
	NSInteger           rotation;
	
	// Identity.
	transform = [NSAffineTransform transform];
	
	// Bounds for page.
	boxRect = [page boundsForBox: [self displayBox]];
	
	// Handle rotation.
	rotation = [page rotation];
	switch (rotation)
	{
		case 90:
		[transform rotateByDegrees: -90];
		[transform translateXBy: -boxRect.size.width yBy: 0.0];
		break;
		
		case 180:
		[transform rotateByDegrees: 180];
		[transform translateXBy: -boxRect.size.height yBy: -boxRect.size.width];
		break;
		
		case 270:
		[transform rotateByDegrees: 90];
		[transform translateXBy: 0.0 yBy: -boxRect.size.height];
		break;
	}
	
	// Origin.
	[transform translateXBy: -boxRect.origin.x yBy: -boxRect.origin.y];
	
	// Concatenate.
	[transform concat];
}

// ---------------------------------------------------------------------------------------------------- selectAnnotation

- (void) selectAnnotation: (PDFAnnotation *) annotation
{
	// Deselect old annotation when appropriate.
	if ((_activeAnnotation != NULL) && (_activeAnnotation != annotation))
	{
		[self setNeedsDisplayInRect: RectPlusScale([self convertRect: [_activeAnnotation bounds]
				fromPage: [_activeAnnotation page]], [self scaleFactor])];
	}
	
	// Assign.
	_activeAnnotation = annotation;
	
	// Display in panel.
//	[[AnnotationPanel sharedAnnotationPanel] setAnnotation: _activeAnnotation];
	
	if (_activeAnnotation)
	{
		// Old (current) annotation location.
		_wasBounds = [_activeAnnotation bounds];
		
		// Force redisplay.
		[self setNeedsDisplayInRect: RectPlusScale([self convertRect: [_activeAnnotation bounds] 
				fromPage: [_activeAnnotation page]], [self scaleFactor])];
	}
}

// --------------------------------------------------------------------------------------------------- annotationChanged

- (void) annotationChanged
{
	// NOP.
	if (_activeAnnotation == NULL)
		return;
	
	// Get bounds.
	NSRect bounds = [_activeAnnotation bounds];
    
    NSString* type = [_activeAnnotation valueForAnnotationKey:PDFAnnotationKeySubtype];
	
	// Handle line start and end points.
	if ([type isEqualToString:PDFAnnotationSubtypeLine])
	{
		PDFBorder	*border = [_activeAnnotation border];
		float		inset = 1.0;
		
		if (border)
			inset = ceilf([border lineWidth] * 2.2);
		[_activeAnnotation setStartPoint: NSMakePoint(inset, inset)];
		[_activeAnnotation setEndPoint: NSMakePoint(bounds.size.width - inset, bounds.size.height - inset)];
	}
    else if ([type isEqualToString:PDFAnnotationSubtypeHighlight] ||
             [type isEqualToString:PDFAnnotationSubtypeUnderline] ||
             [type isEqualToString:PDFAnnotationSubtypeStrikeOut])
	{
        [_activeAnnotation setQuadrilateralPoints: [NSArray arrayWithObjects:
                [NSValue valueWithPoint: NSMakePoint(0.0, bounds.size.height)],
                [NSValue valueWithPoint: NSMakePoint(bounds.size.width, bounds.size.height)],
                [NSValue valueWithPoint: NSMakePoint(0.0, 0.0)],
                [NSValue valueWithPoint: NSMakePoint(bounds.size.width, 0.0)],
                NULL]];
	}
}

// --------------------------------------------------------------------------------------------------------- setEditMode


#pragma mark -------- event overrides
// ------------------------------------------------------------------------------------------ setCursorForAreaOfInterest
//
// - (void) setCursorForAreaOfInterest: (PDFAreaOfInterest) area
// {
// 	[[NSCursor arrowCursor] set];
//}
//
// ----------------------------------------------------------------------------------------------------------- mouseDown

- (void) mouseDown: (NSEvent *) theEvent
{
	PDFPage			*activePage;
	PDFAnnotation	*newActiveAnnotation = NULL;
	NSArray			*annotations;
	NSInteger       numAnnotations, i;
	NSPoint			pagePoint;
	
	// Defer to super for locked PDF or if not in 'edit mode'.
	if (([[self document] isLocked]) || (_editMode == NO))
	{
		[super mouseDown: theEvent];
		return;
	}
	
	// Mouse in display view coordinates.
	_mouseDownLoc = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
	
	// Page we're on.
	activePage = [self pageForPoint: _mouseDownLoc nearest: YES];
	
	// Get mouse in "page space".
	pagePoint = [self convertPoint: _mouseDownLoc toPage: activePage];
	
	// Hit test for annotation.
	annotations = [activePage annotations];
	numAnnotations = [annotations count];
	for (i = 0; i < numAnnotations; i++)
	{
		NSRect		annotationBounds;
		
		// Hit test annotation.
		annotationBounds = [[annotations objectAtIndex: i] bounds];
		if (NSPointInRect(pagePoint, annotationBounds))
		{
			// New annotation.
			newActiveAnnotation = [annotations objectAtIndex: i];
			
			// Update font panel.
			[self reflectFont];
			
			// Remember click point relative to annotation origin.
			_clickDelta.x = pagePoint.x - annotationBounds.origin.x;
			_clickDelta.y = pagePoint.y - annotationBounds.origin.y;
			break;
		}
	}
	
	// Select annotation.
	[self selectAnnotation: newActiveAnnotation];
	
	if (_activeAnnotation == NULL)
	{
		[super mouseDown: theEvent];
	}
	else
	{
		_mouseDownInAnnotation = YES;
		
		// Hit-test for resize box.
		_resizing = NSPointInRect(pagePoint, [self resizeThumbForRect: _wasBounds 
				rotation: [[_activeAnnotation page] rotation]]);
	}
}

// -------------------------------------------------------------------------------------------------------- mouseDragged

- (void) mouseDragged: (NSEvent *) theEvent
{
	// Defer to super for locked PDF or if not in 'edit mode'.
	if (([[self document] isLocked]) || (_editMode == NO))
	{
		[super mouseDragged: theEvent];
		return;
	}
	
	_dragging = YES;
	
	// Handle link-edit mode.
	if (_mouseDownInAnnotation)
	{
		NSRect		newBounds;
		NSRect		currentBounds;
		NSRect		dirtyRect;
		NSPoint		mouseLoc;
		NSPoint		endPt;
		
		// Where is annotation now?
		currentBounds = [_activeAnnotation bounds];
		
		// Mouse in display view coordinates.
		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
		
		// Convert end point to page space.
		endPt = [self convertPoint: mouseLoc toPage: [_activeAnnotation page]];
		
		if (_resizing)
		{
			NSPoint		startPoint;
			
			// Convert start point to page space.
			startPoint = [self convertPoint: _mouseDownLoc toPage: [_activeAnnotation page]];
			
			// Resize the annotation.
			switch ([[_activeAnnotation page] rotation])
			{
				case 0:
				newBounds.origin.x = _wasBounds.origin.x;
				newBounds.origin.y = _wasBounds.origin.y + (endPt.y - startPoint.y);
				newBounds.size.width = _wasBounds.size.width + (endPt.x - startPoint.x);
				newBounds.size.height = _wasBounds.size.height - (endPt.y - startPoint.y);
				break;
				
				case 90:
				newBounds.origin.x = _wasBounds.origin.x;
				newBounds.origin.y = _wasBounds.origin.y;
				newBounds.size.width = _wasBounds.size.width + (endPt.x - startPoint.x);
				newBounds.size.height = _wasBounds.size.height + (endPt.y - startPoint.y);
				break;
				
				case 180:
				newBounds.origin.x = _wasBounds.origin.x + (endPt.x - startPoint.x);
				newBounds.origin.y = _wasBounds.origin.y;
				newBounds.size.width = _wasBounds.size.width - (endPt.x - startPoint.x);
				newBounds.size.height = _wasBounds.size.height + (endPt.y - startPoint.y);
				break;
				
				case 270:
				newBounds.origin.x = _wasBounds.origin.x + (endPt.x - startPoint.x);
				newBounds.origin.y = _wasBounds.origin.y + (endPt.y - startPoint.y);
				newBounds.size.width = _wasBounds.size.width - (endPt.x - startPoint.x);
				newBounds.size.height = _wasBounds.size.height - (endPt.y - startPoint.y);
				break;
			}
			
			// Keep integer.
			newBounds = NSIntegralRect(newBounds);
		}
		else
		{
			// Move annotation.
			// Hit test, is mouse still within page bounds?
			if (NSPointInRect([self convertPoint: mouseLoc toPage: [_activeAnnotation page]], 
					[[_activeAnnotation page] boundsForBox: [self displayBox]]))
			{
				// Calculate new bounds for annotation.
				newBounds = currentBounds;
				newBounds.origin.x = roundf(endPt.x - _clickDelta.x);
				newBounds.origin.y = roundf(endPt.y - _clickDelta.y);
			}
			else
			{
				// Snap back to initial location.
				newBounds = _wasBounds;
			}
		}
		
		// Change annotation's location.
		[_activeAnnotation setBounds: newBounds];
		
		// Call our method to handle updating annotation geometry.
		[self annotationChanged];
		
		// Force redraw.
		dirtyRect = NSUnionRect(currentBounds, newBounds);
		[self setNeedsDisplayInRect: 
				RectPlusScale([self convertRect: dirtyRect fromPage: [_activeAnnotation page]], [self scaleFactor])];
	}
	else
	{
		[super mouseDragged: theEvent];
	}
}

// ------------------------------------------------------------------------------------------------------------- mouseUp

- (void) mouseUp: (NSEvent *) theEvent
{
	// Defer to super for locked PDF or if not in 'edit mode'.
	if (([[self document] isLocked]) || (_editMode == NO))
	{
		[super mouseUp: theEvent];
		return;
	}
	
	_dragging = NO;
	
	// Handle link-edit mode.
	if (_mouseDownInAnnotation)
	{
		_mouseDownInAnnotation = NO;
	}
	else
	{
		[super mouseUp: theEvent];
	}
}

// ------------------------------------------------------------------------------------------------------------- keyDown

- (void) keyDown: (NSEvent *) theEvent
{
	unichar			oneChar;
	unsigned int	theModifiers;
	BOOL			noModifier;
	
	// Skip out if not in 'edit mode'.
	if (_editMode == NO)
	{
		[super keyDown: theEvent];
		return;
	}
	
	// Get the character from the keyDown event.
	oneChar = [[theEvent charactersIgnoringModifiers] characterAtIndex: 0];
    theModifiers = [theEvent modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
    noModifier = ((theModifiers & (NSEventModifierFlagShift | NSEventModifierFlagControl | NSEventModifierFlagOption)) == 0);
	
	// Delete?
	if ((oneChar == NSDeleteCharacter) || (oneChar == NSDeleteFunctionKey))
		[self delete: self];
    
    else if (oneChar == NSTabCharacter) // JOEL NORVELL ADDITION
        [self advanceFocus];            // JOEL NORVELL ADDITION

	else
		[super keyDown: theEvent];
}



// -------------------------------------------------------------------------------------------------------------- advanceFocus - JOEL NORVELL ADDITION

// Tab key was hit; move focus to the next widget.
- (void) advanceFocus
{
    if (_activeAnnotation != NULL)
    {
        PDFPage * currentPage = [_activeAnnotation page];
        
        // Walk array of annotations.
        NSArray *annotations = [currentPage annotations];
        NSUInteger annotCount = [annotations count];
        
        NSUInteger activeIndex = [annotations indexOfObject: _activeAnnotation];
        
        NSUInteger newActiveIndex = [self nextAnnotIndex: activeIndex withinCount: annotCount];
        
        PDFAnnotation * newActiveAnnotation = [annotations objectAtIndex: newActiveIndex];
        
        [self selectAnnotation: newActiveAnnotation];
    }
}

// -------------------------------------------------------------------------------------------------------------- nextAnnotIndex - JOEL NORVELL ADDITION

- (NSUInteger) nextAnnotIndex: (NSUInteger) activeIndex withinCount: (NSUInteger) annotCountForPage
{
    NSUInteger nextIndex = -1;
    
    if (activeIndex +1 < annotCountForPage)
    {
        nextIndex = activeIndex + 1;
    }
    else
    {
        nextIndex = 0; // Wrap around on page.
    }
    
    return nextIndex;
}

// -------------------------------------------------------------------------------------------------------------- delete

- (void) delete: (id) sender
{
	if (_activeAnnotation != NULL)
	{
		// Remove annotation from page.
		[[_activeAnnotation page] removeAnnotation: _activeAnnotation];
		_activeAnnotation = NULL;
		
		// Lazy, redraw entire view.
		[self setNeedsDisplay: YES];
		
		// No annotation selected.
//		[[AnnotationPanel sharedAnnotationPanel] setAnnotation: NULL];

		// Set edited flag.
		[[self window] setDocumentEdited: YES];
	}
}

// ------------------------------------------------------------------------------------------------------- newAnnotation

- (void) newAnnotation: (id) sender
{
	PDFSelection	*selection;
	PDFAnnotation	*annotation;
	NSRect			annotationBounds;
	
	// Get bounds for selection if available, otherwise, create an arbitrary rectangle.
	selection = [self currentSelection];
	if (selection)
	{
		annotationBounds = [selection boundsForPage: [[selection pages] objectAtIndex: 0]];
		[self setCurrentSelection: NULL];
	}
	else
	{
		NSRect		pageBounds;
		
		pageBounds = [[self currentPage] boundsForBox: [self displayBox]];
		annotationBounds = NSMakeRect(pageBounds.origin.x + 20.0, pageBounds.origin.y + 20.0, 200.0, 80.0);
	}
	
	// Which annotation to create....
	switch ([sender tag])
	{
		case 0:
        annotation = [[PDFAnnotation alloc] initWithBounds:annotationBounds forType:PDFAnnotationSubtypeWidget withProperties:nil];
        [annotation setWidgetFieldType:PDFAnnotationWidgetSubtypeButton];
		break;
		
		case 1:
		annotation = [[PDFAnnotation alloc] initWithBounds:annotationBounds forType:PDFAnnotationSubtypeWidget withProperties:nil];
        [annotation setWidgetFieldType:PDFAnnotationWidgetSubtypeChoice];
		break;
		
		case 2:
		annotation = [[PDFAnnotation alloc] initWithBounds:annotationBounds forType:PDFAnnotationSubtypeCircle withProperties:nil];
		break;
		
		case 3:
		annotation = [[PDFAnnotation alloc] initWithBounds:annotationBounds forType:PDFAnnotationSubtypeFreeText withProperties:nil];
		break;
		
		case 4:
		annotation = [[PDFAnnotation alloc] initWithBounds:annotationBounds forType:PDFAnnotationSubtypeInk withProperties:nil];
		// CREATE INK
		break;
		
		case 5:
		annotation = [[PDFAnnotation alloc] initWithBounds:annotationBounds forType:PDFAnnotationSubtypeLine withProperties:nil];
		break;
		
		case 6:
		annotation = [[PDFAnnotation alloc] initWithBounds:annotationBounds forType:PDFAnnotationSubtypeLink withProperties:nil];
		break;
		
		case 7:
            // TODO: Take care of underline and strikeout.
		annotation = [[PDFAnnotation alloc] initWithBounds:annotationBounds forType:PDFAnnotationSubtypeHighlight withProperties:nil];
		break;
		
		case 8:
		annotation = [[PDFAnnotation alloc] initWithBounds:annotationBounds forType:PDFAnnotationSubtypeSquare withProperties:nil];
		break;
		
		case 9:
            // TODO: Use custom stamp or regular stamp annotation?
	//	annotation = [[MyStampAnnotation alloc] initWithBounds: annotationBounds forType:PDFAnnotationSubtypeStamp withProperties:nil];
		break;
		
		case 10:
		// Special case bounds for Text annotation - we want something small and icon-sized.
		annotationBounds.size.width = 20.0;
		annotationBounds.size.height = 20.0;
		annotation = [[PDFAnnotation alloc] initWithBounds:annotationBounds forType:PDFAnnotationSubtypeText withProperties:nil];
		break;
		
		case 11:
		annotation = [[PDFAnnotation alloc] initWithBounds:annotationBounds forType:PDFAnnotationSubtypeWidget withProperties:nil];
        [annotation setWidgetFieldType:PDFAnnotationWidgetSubtypeText];
		break;
	}
	
	[[self currentPage] addAnnotation: annotation];
	[self setNeedsDisplay: YES];
	
	// Select.
	[self selectAnnotation: annotation];
}

#pragma mark -------- font
// -------------------------------------------------------------------------------------------------------- showFontPanel

- (void) showFontPanel: (id) sender
{
	[[NSFontPanel sharedFontPanel] makeKeyAndOrderFront: self];
	[[NSFontManager sharedFontManager] fontMenu: YES];
	[self reflectFont];
}

// ---------------------------------------------------------------------------------------------------------- reflectFont

- (void) reflectFont
{
	if ([NSFontPanel sharedFontPanelExists] == NO)
		return;
	
	if (_activeAnnotation == NULL)
		return;
    
    NSString* type = [_activeAnnotation valueForAnnotationKey:PDFAnnotationKeySubtype];
	
	if ([type isEqualToString:PDFAnnotationSubtypeFreeText])
		[[NSFontPanel sharedFontPanel] setPanelFont: [_activeAnnotation font] isMultiple: NO];
}

// ----------------------------------------------------------------------------------------------------------- changeFont

- (void) changeFont: (id) sender
{
	NSFont		*newFont;
	
	if (_activeAnnotation == NULL)
		return;
	
    NSString* type = [_activeAnnotation valueForAnnotationKey:PDFAnnotationKeySubtype];
    
    if ([type isEqualToString:PDFAnnotationSubtypeFreeText])
	{
		newFont = [sender convertFont: [_activeAnnotation font]];
		[_activeAnnotation setFont: newFont];
	}
	
	// Lazy.
	[self setNeedsDisplay: YES];
}

// --------------------------------------------------------------------------------------------------- resizeThumbForRect

- (NSRect) resizeThumbForRect: (NSRect) rect rotation: (NSInteger) rotation
{
	NSRect		thumb;
	
	// Start with rect.
	thumb = rect;
	
	// Use rotation to determine thumb origin.
	switch (rotation)
	{
		case 0:
		thumb.origin.x += rect.size.width - 8.0;
		break;
		
		case 90:
		thumb.origin.x += rect.size.width - 8.0;
		thumb.origin.y += rect.size.height - 8.0;
		break;
		
		case 180:
		thumb.origin.y += rect.size.height - 8.0;
		break;
	}
	
	thumb.size.width = 8.0;
	thumb.size.height = 8.0;
	
	return thumb;
}



- (void) setEditMode: (BOOL) edit
{
    _editMode = edit;
    [self setNeedsDisplay: YES];
}


@end

// -------------------------------------------------------------------------------------------------------- RectPlusScale

static NSRect RectPlusScale (NSRect aRect, float scale)
{
	float		maxX;
	float		maxY;
	NSPoint		origin;
	
	// Determine edges.
	maxX = ceilf(aRect.origin.x + aRect.size.width) + scale;
	maxY = ceilf(aRect.origin.y + aRect.size.height) + scale;
	origin.x = floorf(aRect.origin.x) - scale;
	origin.y = floorf(aRect.origin.y) - scale;
	
	return NSMakeRect(origin.x, origin.y, maxX - origin.x, maxY - origin.y);
}
