/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2019 Richard
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
 */

/*
 Variables for Annotations defined in MyPDFKitView.h
 
 PDFAnnotation    *_activeAnnotation;
 NSPoint            _mouseDownLoc;
 NSPoint            _clickDelta;
 NSRect            _wasBounds;
 NSPoint           _wasPoint;
 BOOL            _mouseDownInAnnotation;
 BOOL            _dragging;
 BOOL            _resizing;
 BOOL           _resizeLineUsingEnd;
 BOOL           _resizeLineUsingStart;
 BOOL            _editMode;
 NSRect         selectedBounds;
 PDFPage        selectedPage;
 BOOL           withBorder;
  
 also BOOL useAnnotationMenu is a property of MyPDFKitView
 */

// switch when disable Edit Mode
#undef EDITARROWMOD 0

// switch when activate
#define ARROWMOD 0  // later #undef ARROWMOD

#import "MyPDFKitView.h"
#import "globals.h"

@implementation MyPDFKitView (Annotations)

    
    - (void)strikeoutAnnotation: (id)sender
    {
        PDFSelection        *theSelection, *aSelection;
        PDFAnnotation       *theAnnotation;
        NSArray             *initialPages, *thePages;
        NSArray             *theSelections;
        NSInteger           theCount, i;
        PDFPage             *initialPage, *thePage;
        NSRect              theBounds;
        
        if (_editMode == NO)
            return;
        theSelection = self.currentSelection;
        if (theSelection != NULL)
        {
            
            theSelections = [theSelection selectionsByLine];
            theCount = [theSelections count];
            if (theCount > 0)
                for (i = 0; i < theCount; i++)
                     {
                         aSelection = (PDFSelection *)theSelections[i];
                         thePages = [aSelection pages];
                         thePage = (PDFPage *)thePages[0];
                         if (i == 0)
                             initialPage = thePage;
                         if (initialPage == thePage)
                         {
                             theBounds = [aSelection boundsForPage: thePage];
                             theAnnotation = [[PDFAnnotation alloc] initWithBounds: [aSelection boundsForPage: thePage] forType: PDFAnnotationSubtypeStrikeOut withProperties: nil];
                             [theAnnotation setColor: [NSColor redColor]];
                             [self deSelectAll];
                             [thePage addAnnotation: theAnnotation];
                         }
                }
            if ([self.myDocument useFullSplitWindow])
                [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
            else
                [self.myPDFWindow makeKeyAndOrderFront:self];
                    
        }
       
    }
   
 




- (void)highlightAnnotation: (id)sender
{
    PDFSelection        *theSelection, *aSelection;
    PDFAnnotation       *theAnnotation;
    NSArray             *initialPages, *thePages;
    NSArray             *theSelections;
    NSInteger           theCount, i;
    PDFPage             *initialPage, *thePage;
    NSRect              theBounds;
    
    if (_editMode == NO)
        return;
    theSelection = self.currentSelection;
    if (theSelection != NULL)
    {
        
        theSelections = [theSelection selectionsByLine];
        theCount = [theSelections count];
        if (theCount > 0)
            for (i = 0; i < theCount; i++)
                 {
                     aSelection = (PDFSelection *)theSelections[i];
                     thePages = [aSelection pages];
                     thePage = (PDFPage *)thePages[0];
                     if (i == 0)
                         initialPage = thePage;
                     if (initialPage == thePage)
                     {
                         theBounds = [aSelection boundsForPage: thePage];
                         theAnnotation = [[PDFAnnotation alloc] initWithBounds: [aSelection boundsForPage: thePage] forType: PDFAnnotationSubtypeHighlight withProperties: nil];
                         [self deSelectAll];
                        [thePage addAnnotation: theAnnotation];
                     }
            }
        if ([self.myDocument useFullSplitWindow])
            [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
        else
            [self.myPDFWindow makeKeyAndOrderFront:self];
    }
   
}

- (void)underlineAnnotation: (id)sender
{
    PDFSelection        *theSelection, *aSelection;
    PDFAnnotation       *theAnnotation;
    NSArray             *initialPages, *thePages;
    NSArray             *theSelections;
    NSInteger           theCount, i;
    PDFPage             *initialPage, *thePage;
    NSRect              theBounds;
    
    if (_editMode == NO)
        return;
    
    theSelection = self.currentSelection;
    if (theSelection != NULL)
    {
        
        theSelections = [theSelection selectionsByLine];
        theCount = [theSelections count];
        if (theCount > 0)
            for (i = 0; i < theCount; i++)
                 {
                     aSelection = (PDFSelection *)theSelections[i];
                     thePages = [aSelection pages];
                     thePage = (PDFPage *)thePages[0];
                     if (i == 0)
                         initialPage = thePage;
                     if (initialPage == thePage)
                     {
                         theBounds = [aSelection boundsForPage: thePage];
                         theAnnotation = [[PDFAnnotation alloc] initWithBounds: [aSelection boundsForPage: thePage] forType: PDFAnnotationSubtypeUnderline withProperties: nil];
                         [theAnnotation setColor: [NSColor redColor]];
                         [self deSelectAll];
                         [thePage addAnnotation: theAnnotation];
                     }
            }
        if ([self.myDocument useFullSplitWindow])
            [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
        else
            [self.myPDFWindow makeKeyAndOrderFront:self];
    }
   
}

- (void)squareAnnotation: (id)sender
{
    PDFSelection        *theSelection;
    PDFAnnotation       *theAnnotation;
    NSArray             *thePages;
    PDFPage             *thePage;
    NSRect              theBounds;
    
    if (_editMode == NO)
        return;
    
    theSelection = self.currentSelection;
    if (theSelection != NULL)
    {
        
        thePages = [theSelection pages];
        
        thePage = (PDFPage *)thePages[0];
        
        theBounds = [theSelection boundsForPage: thePage];
        
        theBounds.size.width = 100; theBounds.size.height = 100;
    }
    
    else
    {
        thePage = self.currentPage;
        theBounds.origin.x = 200; theBounds.origin.y = 200;
        theBounds.size.width = 100; theBounds.size.height = 100;
     }
         
        theAnnotation = [[PDFAnnotation alloc] initWithBounds: theBounds forType: PDFAnnotationSubtypeSquare withProperties: nil];
        [self deSelectAll];
        [thePage  addAnnotation: theAnnotation];
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
    
   
}

- (void)bsquareAnnotation: (id)sender
{
    PDFSelection        *theSelection;
    PDFAnnotation       *theAnnotation;
    NSArray             *thePages;
    PDFPage             *thePage;
    NSRect              theBounds;
    
    if (_editMode == NO)
        return;
    
    theSelection = self.currentSelection;
    if (theSelection != NULL)
    {
        
        thePages = [theSelection pages];
        
        thePage = (PDFPage *)thePages[0];
        
        theBounds = [theSelection boundsForPage: thePage];
        
        theBounds.size.width = 100; theBounds.size.height = 100;
    }
    
    else
    {
        thePage = self.currentPage;
        theBounds.origin.x = 200; theBounds.origin.y = 200;
        theBounds.size.width = 100; theBounds.size.height = 100;
     }
    
  
         
        theAnnotation = [[PDFAnnotation alloc] initWithBounds: theBounds forType: PDFAnnotationSubtypeSquare withProperties: nil];
        [[theAnnotation border] setLineWidth: 7.0];
        [theAnnotation setColor: [NSColor greenColor]];
        [self deSelectAll];
        [thePage  addAnnotation: theAnnotation];
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
   
   
}


- (void)circleAnnotation: (id)sender
{
    PDFSelection        *theSelection;
    PDFAnnotation       *theAnnotation;
    NSArray             *thePages;
    PDFPage             *thePage;
    NSRect              theBounds;
    
    if (_editMode == NO)
        return;
    
    theSelection = self.currentSelection;
    if (theSelection != NULL)
    {
        
        thePages = [theSelection pages];
        
        thePage = (PDFPage *)thePages[0];
        
        theBounds = [theSelection boundsForPage: thePage];
        
        theBounds.size.width = 100; theBounds.size.height = 100;
    }
    
    else
    {
        thePage = self.currentPage;
        theBounds.origin.x = 200; theBounds.origin.y = 200;
        theBounds.size.width = 100; theBounds.size.height = 100;
     }
    

         theAnnotation = [[PDFAnnotation alloc] initWithBounds: theBounds forType: PDFAnnotationSubtypeCircle withProperties: nil];
        [self deSelectAll];
        [thePage  addAnnotation: theAnnotation];
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
    }
   


- (void)bcircleAnnotation: (id)sender
{
    PDFSelection        *theSelection;
    PDFAnnotation       *theAnnotation;
    NSArray             *thePages;
    PDFPage             *thePage;
    NSRect              theBounds;
    
    if (_editMode == NO)
        return;
    
    theSelection = self.currentSelection;
    if (theSelection != NULL)
    {
        
        thePages = [theSelection pages];
        
        thePage = (PDFPage *)thePages[0];
        
        theBounds = [theSelection boundsForPage: thePage];
        
        theBounds.size.width = 100; theBounds.size.height = 100;
    }
    
    else
    {
        thePage = self.currentPage;
        theBounds.origin.x = 200; theBounds.origin.y = 200;
        theBounds.size.width = 100; theBounds.size.height = 100;
     }
    

        theAnnotation = [[PDFAnnotation alloc] initWithBounds: theBounds forType: PDFAnnotationSubtypeCircle withProperties: nil];
        [[theAnnotation border] setLineWidth: 7.0];
        [theAnnotation setColor: [NSColor greenColor]];
        [self deSelectAll];
        [thePage  addAnnotation: theAnnotation];
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
    

}




- (void)arrowAnnotation: (id)sender
{
    PDFSelection        *theSelection;
    PDFAnnotation       *theAnnotation;
    NSArray             *thePages;
    PDFPage             *thePage;
    NSRect              theBounds;
    
    if (_editMode == NO)
        return;
    
    theSelection = self.currentSelection;
    if (theSelection != NULL)
    {
        
        thePages = [theSelection pages];
        
        thePage = (PDFPage *)thePages[0];
        
        theBounds = [theSelection boundsForPage: thePage];
        
        theBounds.size.width = 100; theBounds.size.height = 100;
    }
    
    else
    {
        thePage = self.currentPage;
        theBounds.origin.x = 200; theBounds.origin.y = 200;
        theBounds.size.width = 100; theBounds.size.height = 100;
     }

    
        theAnnotation = [[PDFAnnotation alloc] initWithBounds: theBounds forType: PDFAnnotationSubtypeLine withProperties: nil];
        [[theAnnotation border] setLineWidth: 3.0];
        [theAnnotation setEndLineStyle: kPDFLineStyleClosedArrow];
        [theAnnotation setColor: [NSColor purpleColor]];
        [theAnnotation setStartPoint: NSMakePoint(0, 0)];
        [theAnnotation setEndPoint: NSMakePoint(theBounds.size.width, theBounds.size.height)];
        [self deSelectAll];
        [thePage  addAnnotation: theAnnotation];
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
  
 }




- (void)textAnnotation: (id)sender
{
    PDFSelection        *theSelection;
    PDFAnnotation       *theAnnotation;
    NSArray             *thePages;
    PDFPage             *thePage;
    NSRect              theBounds;
    NSInteger           rotation;
    
    if (_editMode == NO)
        return;
    
    theSelection = self.currentSelection;
    if (theSelection != NULL)
    {
        
        thePages = [theSelection pages];
        
        thePage = (PDFPage *)thePages[0];
        
        rotation = [thePage rotation];
        
        theBounds = [theSelection boundsForPage: thePage];
        
        // theBounds.size.width = 100; theBounds.size.height = 24;
        if ((rotation == 90) || (rotation == 270))
            {theBounds.size.width = 24; theBounds.size.height = 100;}
        else
        {   theBounds.size.width = 100; theBounds.size.height = 24;}
    }
    
    else
    {
        thePage = self.currentPage;
        rotation = [thePage rotation];
        theBounds.origin.x = 200; theBounds.origin.y = 200;
        // theBounds.size.width = 100; theBounds.size.height = 24;
        if ((rotation == 90) || (rotation == 270))
            {theBounds.size.width = 24; theBounds.size.height = 100;}
        else
        {   theBounds.size.width = 100; theBounds.size.height = 24;}
     }

    selectedBounds = theBounds;
    selectedPage = thePage;
    withBorder = NO;
    

    

  
         
        theAnnotation = [[PDFAnnotation alloc] initWithBounds: theBounds forType: PDFAnnotationSubtypeFreeText withProperties: nil];
        [theAnnotation setColor: [NSColor clearColor]];
        [theAnnotation setAlignment: NSTextAlignmentCenter];
        [theAnnotation setContents: @"Strange, world"];
        [theAnnotation setFontColor: [NSColor redColor]];
        [self deSelectAll];
        [thePage  addAnnotation: theAnnotation];


    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
   
}
 


- (void)btextAnnotation: (id)sender
{
    PDFSelection        *theSelection;
    PDFAnnotation       *theAnnotation;
    NSArray             *thePages;
    PDFPage             *thePage;
    NSRect              theBounds;
    NSInteger           rotation;
    
    if (_editMode == NO)
        return;
    
    theSelection = self.currentSelection;
    if (theSelection != NULL)
    {
        
        thePages = [theSelection pages];
        
        thePage = (PDFPage *)thePages[0];
        
        rotation = [thePage rotation];
        
        theBounds = [theSelection boundsForPage: thePage];
        
       // theBounds.size.width = 100; theBounds.size.height = 24;
        if ((rotation == 90) || (rotation == 270))
            {theBounds.size.width = 24; theBounds.size.height = 100;}
        else
        {   theBounds.size.width = 100; theBounds.size.height = 24;}
    }
    
    else
    {
        thePage = self.currentPage;
        rotation = [thePage rotation];
        theBounds.origin.x = 200; theBounds.origin.y = 200;
        if ((rotation == 90) || (rotation == 270))
            {theBounds.size.width = 24; theBounds.size.height = 100;}
        else
        {   theBounds.size.width = 100; theBounds.size.height = 24;}
     }
    
    selectedBounds = theBounds;
    selectedPage = thePage;
    withBorder = YES;
   
    

        theAnnotation = [[PDFAnnotation alloc] initWithBounds: theBounds forType: PDFAnnotationSubtypeFreeText withProperties: nil];
        [theAnnotation setAlignment: NSTextAlignmentCenter];  // could be Left, Center, Right
        [theAnnotation setContents: @"Hello, world"];
        [theAnnotation setColor: [NSColor greenColor]];
        [self deSelectAll];
        [thePage  addAnnotation: theAnnotation];

    if ([self.myDocument useFullSplitWindow])
        [[self.myDocument fullSplitWindow] endSheet: [self.myDocument getStringWindow]];
    else
        [self.myPDFWindow endSheet: [self.myDocument getStringWindow]];
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
   
}

- (void)popupAnnotation: (id)sender
{
    PDFSelection        *theSelection;
    PDFAnnotation       *theAnnotation;
    NSArray             *thePages;
    PDFPage             *thePage;
    NSRect              theBounds;
    
    if (_editMode == NO)
        return;
    
    [self deSelectAll];
    
    theSelection = self.currentSelection;
    if (theSelection != NULL)
    {
        
        thePages = [theSelection pages];
        
        thePage = (PDFPage *)thePages[0];
        
        theBounds = [theSelection boundsForPage: thePage];
        
        theBounds.size.width = 20.0; theBounds.size.height = 20.0;
    }
    
    else
    {
        thePage = self.currentPage;
        theBounds.origin.x = 200; theBounds.origin.y = 200;
        theBounds.size.width = 20.00; theBounds.size.height = 20.0;
     }
    
    /*
    PDFAnnotation *textAnnotation = [[PDFAnnotation alloc] initWithBounds:theBounds forType:PDFAnnotationSubtypeText withProperties:nil];
        [theAnnotation setIconType:0];
        [theAnnotation setColor: [NSColor greenColor]];
        [textAnnotation setContents:@"Hello world!"];

        // Create a popup annotation
        CGRect annotationRect = CGRectMake(100, 100, 200, 50);
        PDFAnnotation *popupAnnotation = [[PDFAnnotation alloc] initWithBounds:annotationRect forType:PDFAnnotationSubtypePopup withProperties:nil];
        [popupAnnotation setBackgroundColor: [NSColor whiteColor]];

    // Set the default font and text size for the popup annotation
        NSDictionary *textAttributes = @{NSFontAttributeName: [NSFont systemFontOfSize:14]};
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"Hello, world" attributes:textAttributes];
       // [textAnnotation setAttributedContents:attributedString];
    
    [textAnnotation setPopup:popupAnnotation];
    
    [thePage addAnnotation:textAnnotation];
    [thePage addAnnotation:popupAnnotation];
    
    [self delete: popupAnnotation];

    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
   */
    

        theAnnotation = [[PDFAnnotation alloc] initWithBounds:theBounds forType:PDFAnnotationSubtypeText withProperties:nil];
        [theAnnotation setIconType:0];
       // [theAnnotation setContents: @"Goodbye, world!"];
        [theAnnotation setColor: [NSColor greenColor]];
        //if  (theAnnotation.popup.shouldDisplay)
        //    NSLog(@"yes, should display");
        [self delete: theAnnotation.popup];
        
        [thePage  addAnnotation: theAnnotation];
        [thePage removeAnnotation: theAnnotation.popup];
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
   
}



/*
- (void)popupAnnotation: (id)sender
{
    PDFSelection        *theSelection;
    PDFAnnotation       *theAnnotation;
    NSArray             *thePages;
    PDFPage             *thePage;
    NSRect              theBounds;
    
    if (_editMode == NO)
        return;
    
    [self deSelectAll];
    
    theSelection = self.currentSelection;
    if (theSelection != NULL)
    {
        
        thePages = [theSelection pages];
        
        thePage = (PDFPage *)thePages[0];
        
        theBounds = [theSelection boundsForPage: thePage];
        
        theBounds.size.width = 20.0; theBounds.size.height = 20.0;
    }
    
    else
    {
        thePage = self.currentPage;
        theBounds.origin.x = 200; theBounds.origin.y = 200;
        theBounds.size.width = 20.00; theBounds.size.height = 20.0;
     }
    
       
        theAnnotation = [[PDFAnnotation alloc] initWithBounds:theBounds forType:PDFAnnotationSubtypeText withProperties:nil];
        [theAnnotation setIconType:0];
       // [theAnnotation setContents: @"Goodbye, world!"];
        [theAnnotation setColor: [NSColor greenColor]];
        //if  (theAnnotation.popup.shouldDisplay)
        //    NSLog(@"yes, should display");
        [self delete: theAnnotation.popup];
        
        [thePage  addAnnotation: theAnnotation];
        [thePage removeAnnotation: theAnnotation.popup];
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
}
*/
        
- (BOOL) isArrow: (PDFAnnotation *)theAnnotation
{
    NSString    *theType;
    
    theType = theAnnotation.type;
    theType = [@"/" stringByAppendingString: theType];
    return [theType isEqualToString: PDFAnnotationSubtypeLine];
}

- (BOOL) isPopup: (PDFAnnotation *) theAnnotation
{
    NSString    *theType;
    
    theType = _activeAnnotation.type;
    theType = [@"/" stringByAppendingString: theType];
    return [theType isEqualToString: PDFAnnotationSubtypeText];
}

- (BOOL) isTextLine: (PDFAnnotation *) theAnnotation
{
    NSString    *theType;
    
    theType = _activeAnnotation.type;
    theType = [@"/" stringByAppendingString: theType];
    return (([theType isEqualToString: PDFAnnotationSubtypeHighlight]) ||
            ([theType isEqualToString: PDFAnnotationSubtypeStrikeOut]) ||
            ([theType isEqualToString: PDFAnnotationSubtypeUnderline]));
}

- (BOOL) isCircleOrSquare: (PDFAnnotation *) theAnnotation
{
    NSString    *theType;
    
    theType = _activeAnnotation.type;
    theType = [@"/" stringByAppendingString: theType];
    return (([theType isEqualToString: PDFAnnotationSubtypeCircle]) || ([theType isEqualToString: PDFAnnotationSubtypeSquare]));
}

- (BOOL) isFreeText: (PDFAnnotation *) theAnnotation
{
    NSString    *theType;
    
    theType = _activeAnnotation.type;
    theType = [@"/" stringByAppendingString: theType];
    return ([theType isEqualToString: PDFAnnotationSubtypeFreeText]);
}


// Note: The arrow annotation will be treated in a special way. The bounds rect for this
// annotation always has origin at the start of the arrow and opposite vertex at the end
// of the arrow. In this case only, we allow bounds.size.width and bounds.size.height to
// be positive or negative. Below are two procedures useful for dealing with arrow annotations.

- (NSRect) lineEndRect: (PDFAnnotation *)theAnnotation
{
    NSPoint     startPoint, endPoint, originPoint;
    
    endPoint = theAnnotation.endPoint;
    originPoint = [theAnnotation bounds].origin;
    endPoint.x = endPoint.x + originPoint.x;  endPoint.y = endPoint.y + originPoint.y;
    return [self resizeThumbForPoint: endPoint rotation: [theAnnotation.page rotation]];
}

- (NSRect) lineEndRectFromBounds: (NSRect)bounds
{
    NSPoint originPoint, endPoint;
    NSRect  theRect;
    
    originPoint = bounds.origin;
    endPoint.x = originPoint.x + bounds.size.width;
    endPoint.y = originPoint.y + bounds.size.height;
    theRect.origin.x = endPoint.x - 8;
    theRect.origin.y = endPoint.y - 8;
    theRect.size.width = 16;
    theRect.size.height = 16;

    return theRect;
}


- (NSRect) lineEndRectFromBoundsRestricted: (NSRect)bounds
{
    NSPoint originPoint, endPoint;
    NSRect  theRect;
    
    originPoint = bounds.origin;
    endPoint.x = originPoint.x + bounds.size.width;
    endPoint.y = originPoint.y + bounds.size.height;
    theRect.origin.x = endPoint.x - 8;
    theRect.origin.y = endPoint.y - 8;
    theRect.size.width = 8;
    theRect.size.height = 8;
    
    
    if ((bounds.size.width >= 0) && (bounds.size.height >= 0))
    {
        theRect.origin.x = endPoint.x - 8;
        theRect.origin.y = endPoint.y - 8;
    }
    else if ((bounds.size.width >= 0) && (bounds.size.height < 0))
    {
        theRect.origin.x = endPoint.x - 8;
        theRect.origin.y = endPoint.y ;
    }
    else if ((bounds.size.width < 0) && (bounds.size.height >= 0))
    {
        theRect.origin.x = endPoint.x ;
        theRect.origin.y = endPoint.y - 8;
    }
    else if ((bounds.size.width < 0) && (bounds.size.height < 0))
    {
        theRect.origin.x = endPoint.x ;
        theRect.origin.y = endPoint.y ;
    }
    
    
    return theRect;
}



- (BOOL) specialPointInRect: (NSPoint)point : (NSRect)bounds
{
    BOOL xOK, yOK;
    float a, b, c, d, x, y;
    
    xOK = NO; yOK = NO;
    x = point.x - bounds.origin.x;
    y = point.y - bounds.origin.y;
    a = bounds.size.width;
    b = bounds.size.height;
    
    if (((a <= x) && (x <= 0)) || ((0 <= x) && (x <= a)))
        xOK = YES;
    if (((b <= y) && (y <= 0)) || ((0 <= y) && (y <= b)))
        yOK = YES;
    if (xOK && yOK)
        return YES;
    else
        return NO;
}



    
- (void) setEditMode: (id)sender
{
    [self setEditModeInternal: YES andClosePanels:YES];
}

- (void) removeStreams: (id)sender
{
    // Walk array of annotations.
      NSArray           *annotations;
      NSUInteger        annotCount;
      NSUInteger        i;
      PDFPage           *thePage;
      PDFAnnotation     *theAnnotation;
      
      thePage = self.currentPage;
      annotations = [thePage annotations];
      annotCount = [annotations count];
      for (i = 0; i < annotCount; i++)
      {
          theAnnotation = [annotations objectAtIndex: i];
          [theAnnotation removeAllAppearanceStreams];
      }

    
    [self setNeedsDisplay: YES];
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
}

- (void) setRunMode: (id)sender
{
    [self setEditModeInternal: NO andClosePanels:YES];
}

- (void)closePanels
{
    [[NSColorPanel sharedColorPanel] close];
    [[NSFontPanel sharedFontPanel] close];
    [[self.myDocument getStringWindow] close];
}

- (void) setEditModeInternal: (BOOL)edit andClosePanels: (BOOL)doClose
{
    PDFPage *aPage, *firstPage;
    
    firstPage = [[self document] pageAtIndex: 0];
    aPage = self.currentPage;
    
    if ((self.firstTime) && (aPage == firstPage))
    {
        self.firstTime = NO;
        [self goToPage: aPage];
    }
    
    
    if (edit) {
        [self.myDocument setToggleEditModeCheck: 1];
        //self.useAnnotationMenu = YES;
        self.myDocument.docUseAnnotationMenu = YES;
        }
    else {
        [self.myDocument setToggleEditModeCheck: 0];
        //self.useAnnotationMenu = NO;
        self.myDocument.docUseAnnotationMenu = NO;
        }
    
    
    if (_editMode == edit)
        return;
    
    _editMode = edit;
    
    if ((! _editMode) && (doClose))
        [self closePanels];
    
#ifdef EDITARROWMOD
    // Walk array of annotations.
    NSArray           *annotations;
    NSUInteger        annotCount;
    NSUInteger        i;
    PDFPage           *thePage;
    PDFAnnotation     *theAnnotation;
    
    thePage = self.currentPage;
    annotations = [thePage annotations];
    annotCount = [annotations count];
    for (i = 0; i < annotCount; i++)
    {
        theAnnotation = [annotations objectAtIndex: i];
        if ([self isArrow: theAnnotation])
        {
            if (edit == YES)
                [self specializeArrowAnnotation: theAnnotation];
            else
                [self normalizeArrowAnnotation: theAnnotation];
        }
    }
#endif
    
     
    [self setNeedsDisplay: YES];
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
   
}





static NSRect RectPlusScale (NSRect aRect, float scale)
{
    float        maxX;
    float        maxY;
    NSPoint        origin;
    
    // Determine edges.
    maxX = ceilf(aRect.origin.x + aRect.size.width) + scale;
    maxY = ceilf(aRect.origin.y + aRect.size.height) + scale;
    origin.x = floorf(aRect.origin.x) - scale;
    origin.y = floorf(aRect.origin.y) - scale;
    
    return NSMakeRect(origin.x, origin.y, maxX - origin.x, maxY - origin.y);
}

- (void) saveAnnotations: (id)sender
{
    NSSavePanel     *panel;
    NSString    *filePath;
    NSString    *rawPath;
    NSString    *writePath, *writeDirectory;
    PDFDocument *theDocument;
    
    NSUInteger modifiers = ([NSEvent modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask);
    
    [self setEditModeInternal: NO andClosePanels:NO];
    
    [self deSelectAll];
    
    filePath = [[self.myDocument fileURL] path];
    
    if (filePath)
        {
            rawPath = [filePath stringByDeletingPathExtension];
            writePath = [[rawPath stringByAppendingString:@"-Annotated"] stringByAppendingPathExtension:@"pdf"];
            // [self.document writeToFile: writePath];
            
            theDocument = self.document;
            if (modifiers == NSAlternateKeyMask)
                {
                   theDocument =  [self constructOutput];
                }
            panel = [NSSavePanel savePanel];
            [panel setAllowedFileTypes: @[ @"pdf" ]];
            writeDirectory = [filePath stringByDeletingLastPathComponent];
            [panel setDirectoryURL: [NSURL URLWithString: writeDirectory]];
            [panel setNameFieldStringValue: [writePath lastPathComponent]];
             
            if ([panel runModal] == NSModalResponseOK)
                 {
                    [theDocument writeToURL: [panel URL]];
                 }
            
        }
}

- (PDFDocument *)constructOutput
{
    BOOL pagesExist, desiredType;
    NSString    *theType;
    pagesExist = NO;
    NSString    *theLabel;
    
    PDFDocument *originalDocument = self.document;
    PDFDocument *modifiedDocument = [[PDFDocument alloc] init];
    
    for (NSInteger i = 0; i < [originalDocument pageCount]; i++) {
        PDFPage *originalPage = [originalDocument pageAtIndex:i];
        NSArray<PDFAnnotation *> *annotations = [originalPage annotations];
        
        // Check if the page contains annotations
        if (annotations.count > 0) {
            desiredType = NO;
            for (NSInteger j = 0; j < annotations.count; j++)
            {
                theType = annotations[j].type;
                 if (([theType isEqualToString: @"StrikeOut"]) ||
                    ([theType isEqualToString: @"Highlight"]) ||
                    ([theType isEqualToString: @"Underline"]) ||
                    ([theType isEqualToString: @"Circle"]) ||
                    ([theType isEqualToString: @"Square"]) ||
                    ([theType isEqualToString: @"Line"])||
                    ([theType isEqualToString: @"FreeText"]) ||
                    ([theType isEqualToString: @"Text"]))
                {
                    desiredType = YES;
                    pagesExist = YES;
                }
              }
            
             if (desiredType)
            {
                
                // If annotations exist, add the page to the modified document
                PDFPage *copiedPage = [originalPage copy];
                
                // Optionally, you can copy the annotations if needed
                for (PDFAnnotation *annotation in annotations) {
                    PDFAnnotation *copiedAnnotation = [annotation copy];
                    [copiedPage addAnnotation:copiedAnnotation];
                }
                
                [modifiedDocument insertPage:copiedPage atIndex:[modifiedDocument pageCount]];
            }
        }
    }
          
    if (pagesExist)
        return modifiedDocument;
    else
        return self.document;
}

/*
// --------------------------------------------------- printDocument

- (void) printDocument: (id) sender
{
    // Pass to PDF view.
    [self printWithInfo: [[[[self window] windowController] document] printInfo] autoRotate: YES];
}
 
*/



- (BOOL) annotationDrawPage: (PDFPage *)page
{
    NSArray            *annotations;
    NSUInteger        annotCount;
    NSUInteger        i;
    
    // Let PDFView do most of the hard work.
   //  [super drawPage: pdfPage];
    
    // Skip out unless we are in 'edit mode'.
    if (_editMode == NO)
        return NO;
    
    // Save.
    [NSGraphicsContext saveGraphicsState];
    
    // Tranform.
    [self transformContextForPage: page];
    
    // Frame all annotations in gray.
    [[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.3] set];
    
    // Walk array of annotations.
    annotations = [page annotations];
    annotCount = [annotations count];
   // for (i = 0; i < annotCount; i++)
   //     NSFrameRectWithWidthUsingOperation([[annotations objectAtIndex: i] bounds], 1.0, NSCompositeSourceOver);
    
    // Handle the selected annotation.
    if ((_activeAnnotation) && ([_activeAnnotation page] == page))
    {
        NSRect            bounds;
        NSBezierPath    *path;
        NSString        *theType;
        BOOL            isLine, isPopup;
        NSPoint         originPoint, thePoint;
        NSPoint         startPoint, endPoint;
        
      
        bounds = [_activeAnnotation bounds];
        path = [NSBezierPath bezierPathWithRect: bounds];
        [path setLineJoinStyle: NSRoundLineJoinStyle];
        [[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 0.1] set];
        [path fill];
        [[NSColor redColor] set];
        [path stroke];
            
        // Draw resize handle.
        if ((! [self isPopup: _activeAnnotation]) && (!  [self isArrow: _activeAnnotation]))
            NSRectFill(NSIntegralRect([self resizeThumbForRectSmall: bounds rotation: [page rotation]]));
        
        
        if ([self isArrow: _activeAnnotation])
        { ;
              //  [[NSColor redColor] set];
              //  NSRectFill([self lineEndRectFromBoundsRestricted: [_activeAnnotation bounds]]);
         // NSRectFill([self lineEndRectFromBounds: [_activeAnnotation bounds]]);
            }
        
     }
    
    // Restore.
    [NSGraphicsContext restoreGraphicsState];

    return NO;
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
       // [transform translateXBy: -boxRect.size.height yBy: -boxRect.size.width];
        [transform translateXBy: -boxRect.size.width yBy: -boxRect.size.height];
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

#ifdef ARROWMOD
        if ([self isArrow: _activeAnnotation])
            [self normalizeArrowAnnotation: _activeAnnotation];
#endif
        
        [self setNeedsDisplayInRect: RectPlusScale([self convertRect: [_activeAnnotation bounds]
                fromPage: [_activeAnnotation page]], [self scaleFactor])];
    }
    
    // Assign.
    _activeAnnotation = annotation;
    
    // Display in panel.
//    [[AnnotationPanel sharedAnnotationPanel] setAnnotation: _activeAnnotation];
    
    if (_activeAnnotation)
    {
        // Old (current) annotation location.
        _wasBounds = [_activeAnnotation bounds];
        _wasPoint = _wasBounds.origin;
        _wasPoint.x = _wasPoint.x + _wasBounds.size.width;
        _wasPoint.y =  _wasPoint.y + _wasBounds.size.height;
        
#ifdef ARROWMOD
        if ([self isArrow: _activeAnnotation])
            [self specializeArrowAnnotation: _activeAnnotation];
#endif
        
        if ([self isFreeText: _activeAnnotation])
           [self reflectText];
      
        
        // Force redisplay.
        [self setNeedsDisplayInRect: RectPlusScale([self convertRect: [_activeAnnotation bounds]
                fromPage: [_activeAnnotation page]], [self scaleFactor])];
    }
}


- (void)deSelectAll
{
   if (_activeAnnotation)
   {
       [self setNeedsDisplayInRect: [self convertRect: [_activeAnnotation bounds]
                                             fromPage: [_activeAnnotation page]]];
       _activeAnnotation = NULL;
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
    
    
    // Handle line start and end points.
    if ([self isArrow: _activeAnnotation])
    {
        //PDFBorder    *border = [_activeAnnotation border];
        float        inset = 0.0;
        
     }

    else if ([self isTextLine: _activeAnnotation])
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



- (BOOL)annotationMouseDown: (NSEvent *)theEvent
{
    PDFPage            *activePage;
    PDFAnnotation    *newActiveAnnotation = NULL;
    NSArray            *annotations;
    NSInteger       numAnnotations, i;
    NSPoint            pagePoint;
    NSString        *theType;
    BOOL            isLine;
    BOOL            optionPressed;
    NSUInteger     modifiers;
    
   // _rejectDrag = NO;
   // NSLog(@"mouse Down");
    
    modifiers = ([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
    optionPressed = (modifiers == NSAlternateKeyMask);
    
    if (optionPressed)
        return NO;
    
    // Defer to super for locked PDF or if not in 'edit mode'.
    if (([[self document] isLocked]) || (_editMode == NO))
    {
        return NO;
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
    if (numAnnotations == 0)
        return NO;
    
    newActiveAnnotation = NULL;
    
    for (i = 0; i < numAnnotations; i++)
    {
        NSRect        annotationBounds;
        
        // Hit test annotation.
        annotationBounds = [[annotations objectAtIndex: i] bounds];
       // if (NSPointInRect(pagePoint, annotationBounds))
         if ([self specialPointInRect: pagePoint : annotationBounds])
            
        {
             
            newActiveAnnotation = [annotations objectAtIndex: i];
            
            // Update font panel.
            [self reflectFont];
           
            
            // Remember click point relative to annotation origin.
            _clickDelta.x = pagePoint.x - annotationBounds.origin.x;
            _clickDelta.y = pagePoint.y - annotationBounds.origin.y;
            break;
        }
    }
    
   // if (newActiveAnnotation == NULL)
   //     return NO;
    
    // Select annotation.
    [self selectAnnotation: newActiveAnnotation];
    
    if (_activeAnnotation == NULL)
    {
        return NO;
    }
    else
    {
        _mouseDownInAnnotation = YES;
        
        // Hit-test for resize box.
        

        if ([self isPopup: _activeAnnotation])
            _resizing = NO;
        
        else if ([self isArrow: _activeAnnotation])
            {
                NSPoint     endPoint;
                NSRect      lineBounds;
                NSRect      theEndRect;
                
                
                lineBounds = _wasBounds;
                theEndRect = [self lineEndRect: _activeAnnotation];
                
                _resizing = NSPointInRect(pagePoint, [self lineEndRectFromBounds: _wasBounds]);
               
           }
         
        else
         
            _resizing = NSPointInRect(pagePoint, [self resizeThumbForRect: _wasBounds
                rotation: [[_activeAnnotation page] rotation]]);
        
        return YES;
    }
    

}



// -------------------------------------------------------------------------------------------------------- mouseDragged

- (BOOL) annotationMouseDragged: (NSEvent *)theEvent
{
    // Defer to super for locked PDF or if not in 'edit mode'.
    if (([[self document] isLocked]) || (_editMode == NO))
    {
        // _rejectDrag = NO;
        return NO;
    }
    
    _dragging = YES;
    
    // Handle link-edit mode.
    if (_mouseDownInAnnotation)
    {
        NSRect        newBounds;
        NSRect        currentBounds;
        NSRect        dirtyRect;
        NSPoint        mouseLoc;
        NSPoint        endPt;
        NSPoint        newPt, oldStart, newStart, oldEnd, newEnd, theEndPoint;
        BOOL           optionPressed;
        NSUInteger     modifiers;
        NSColor        *theColor, *aColor;
        
        /*
        if //((NSColorPanel.sharedColorPanelExists) &&
         ([NSColorPanel dragColor: aColor withEvent: theEvent fromView: [NSColorPanel sharedColorPanel]])
        {
            //(@"got here");
            return NO;
        }
        */
            
            
        modifiers = ([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
        optionPressed = (modifiers == NSAlternateKeyMask);
                
        // Where is annotation now?
        currentBounds = [_activeAnnotation bounds];
        
        // Mouse in display view coordinates.
        mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
        
        // Convert end point to page space.
        endPt = [self convertPoint: mouseLoc toPage: [_activeAnnotation page]];
        
        if (_resizing)
        {
            NSPoint     startPoint;
            // Convert start point to page space.
            startPoint = [self convertPoint: _mouseDownLoc toPage: [_activeAnnotation page]];
            
            if ([self isArrow: _activeAnnotation])
            {
                newBounds.origin = _wasBounds.origin;
                newBounds.size.width = _wasBounds.size.width + (endPt.x - startPoint.x);
                newBounds.size.height = _wasBounds.size.height + (endPt.y - startPoint.y);
                theEndPoint.x = newBounds.size.width;
                theEndPoint.y = newBounds.size.height;
                [_activeAnnotation setEndPoint: theEndPoint];
            }
            else
            {
                
                
                // Resize the annotation.
                switch ([[_activeAnnotation page] rotation])
                {
                    case 0:
                        newBounds.origin.x = _wasBounds.origin.x;
                        if ([self isTextLine: _activeAnnotation])
                            newBounds.origin.y = _wasBounds.origin.y;
                        else
                            newBounds.origin.y = _wasBounds.origin.y + (endPt.y - startPoint.y);
                        newBounds.size.width = _wasBounds.size.width + (endPt.x - startPoint.x);
                        if ([self isTextLine: _activeAnnotation])
                            newBounds.size.height = _wasBounds.size.height;
                        else if (([self isCircleOrSquare: _activeAnnotation]) && (optionPressed))
                        {
                            newBounds.size.height = _wasBounds.size.height - (endPt.y - startPoint.y);
                            newBounds.size.width = newBounds.size.height;
                        }
                        else
                            newBounds.size.height = _wasBounds.size.height - (endPt.y - startPoint.y);
                        break;
                        
                    case 90:
                       // newBounds.origin.x = _wasBounds.origin.x;
                       // newBounds.origin.y = _wasBounds.origin.y;
                       // newBounds.size.width = _wasBounds.size.width + (endPt.x - startPoint.x);
                       // newBounds.size.height = _wasBounds.size.height + (endPt.y - startPoint.y);
                       // break;
                        newBounds.origin.x = _wasBounds.origin.x;
                        if ([self isTextLine: _activeAnnotation])
                            newBounds.origin.y = _wasBounds.origin.y;
                        else
                           // newBounds.origin.y = _wasBounds.origin.y + (endPt.y - startPoint.y);
                            newBounds.origin.y = _wasBounds.origin.y;
                        newBounds.size.width = _wasBounds.size.width + (endPt.x - startPoint.x);
                        if ([self isTextLine: _activeAnnotation])
                            newBounds.size.height = _wasBounds.size.height;
                        else if (([self isCircleOrSquare: _activeAnnotation]) && (optionPressed))
                        {
                            newBounds.size.height = _wasBounds.size.height + (endPt.y - startPoint.y);
                            newBounds.size.width = newBounds.size.height;
                        }
                        else
                            newBounds.size.height = _wasBounds.size.height + (endPt.y - startPoint.y);
                        break;
                        
                    case 180:
                       // newBounds.origin.x = _wasBounds.origin.x + (endPt.x - startPoint.x);
                       // newBounds.origin.y = _wasBounds.origin.y;
                       // newBounds.size.width = _wasBounds.size.width - (endPt.x - startPoint.x);
                       // newBounds.size.height = _wasBounds.size.height + (endPt.y - startPoint.y);
                       // break;
                        newBounds.origin.x = _wasBounds.origin.x + (endPt.x - startPoint.x);;
                        if ([self isTextLine: _activeAnnotation])
                            newBounds.origin.y = _wasBounds.origin.y;
                        else
                            newBounds.origin.y = _wasBounds.origin.y;
                        
                        newBounds.size.width = _wasBounds.size.width - (endPt.x - startPoint.x);
                        if ([self isTextLine: _activeAnnotation])
                            newBounds.size.height = _wasBounds.size.height;
                        else if (([self isCircleOrSquare: _activeAnnotation]) && (optionPressed))
                        {
                            newBounds.size.height = _wasBounds.size.height + (endPt.y - startPoint.y);
                            newBounds.size.width = newBounds.size.height;
                        }
                        else
                            newBounds.size.height = _wasBounds.size.height + (endPt.y - startPoint.y);
                        break;
                        
                    case 270:
                        // newBounds.origin.x = _wasBounds.origin.x + (endPt.x - startPoint.x);
                        // newBounds.origin.y = _wasBounds.origin.y + (endPt.y - startPoint.y);
                        // newBounds.size.width = _wasBounds.size.width - (endPt.x - startPoint.x);
                        // newBounds.size.height = _wasBounds.size.height - (endPt.y - startPoint.y);
                        // break;
                        newBounds.origin.x = _wasBounds.origin.x + (endPt.x - startPoint.x);
                        if ([self isTextLine: _activeAnnotation])
                            newBounds.origin.y = _wasBounds.origin.y;
                        else
                            newBounds.origin.y = _wasBounds.origin.y + (endPt.y - startPoint.y);
                        newBounds.size.width = _wasBounds.size.width - (endPt.x - startPoint.x);
                        if ([self isTextLine: _activeAnnotation])
                            newBounds.size.height = _wasBounds.size.height;
                        else if (([self isCircleOrSquare: _activeAnnotation]) && (optionPressed))
                        {
                            newBounds.size.height = _wasBounds.size.height - (endPt.y - startPoint.y);
                            newBounds.size.width = newBounds.size.height;
                        }
                        else
                            newBounds.size.height = _wasBounds.size.height - (endPt.y - startPoint.y);
                        break;
                }
                
                // Keep integer.
                if (! [self isArrow: _activeAnnotation])
                {
                    newBounds = NSIntegralRect(newBounds);
                    /*
                    if ([self isFreeText: _activeAnnotation])
                    {
                        theColor = [_activeAnnotation color];
                        [_activeAnnotation setColor: theColor];
                    }
                    */
                }
                else
                {
                    //newBounds = NSIntegralRect(newBounds);
                    newEnd.x = newBounds.size.width;
                    newEnd.y = newBounds.size.height;
                    newBounds.origin = currentBounds.origin;
                    [_activeAnnotation setEndPoint: newEnd];
                }
                [self annotationChanged];
                // /abbitatuibreturn YES;
            }
        }
            else
       //    {
       //     { // Snap back to initial location.
        //        newBounds = _wasBounds;
        //    }
       // }
        //else
        {
            // Move annotation.
            // Hit test, is mouse still within page bounds?
            if (NSPointInRect([self convertPoint: mouseLoc toPage: [_activeAnnotation page]],
                    [[_activeAnnotation page] boundsForBox: [self displayBox]]))
            {
                // Calculate new bounds for annotation.
                newBounds = currentBounds;
                newBounds.origin.x = roundf(endPt.x - _clickDelta.x);
                if (! [self isTextLine: _activeAnnotation])
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
        return YES;
    }
    else
    {
        return NO;
    }

}


// ------------------------------------------------------------------------------------------------------------- mouseUp

- (BOOL) annotationMouseUp: (NSEvent *)theEvent
{
       // _rejectDrag = NO;
    
        // Defer to super for locked PDF or if not in 'edit mode'.
        if (([[self document] isLocked]) || (_editMode == NO))
            return NO;
        
        _dragging = NO;
        
        // Handle link-edit mode.
        if (_mouseDownInAnnotation)
        {
            _mouseDownInAnnotation = NO;
            return YES;
        }
        else
        {
            return NO;
        }
 
}



// ------------------------------------------------------------------------------------------------------------- keyDown

- (BOOL)annotationKeyDown: (NSEvent *)theEvent // return YES if the event was handled and nothing more need be done
{
    unichar            oneChar;
    unsigned int    theModifiers;
    BOOL            noModifier;
    
    // Skip out if not in 'edit mode'.
    if (_editMode == NO)
        return NO;
    
    // Get the character from the keyDown event.
    oneChar = [[theEvent charactersIgnoringModifiers] characterAtIndex: 0];
    theModifiers = [theEvent modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
    noModifier = ((theModifiers & (NSEventModifierFlagShift | NSEventModifierFlagControl | NSEventModifierFlagOption)) == 0);
    
    // Delete?
    if ((oneChar == NSDeleteCharacter) || (oneChar == NSDeleteFunctionKey))
    {
        [self delete: self];
        return YES;
    }
    
    else if (oneChar == NSTabCharacter) // JOEL NORVELL ADDITION
    {
        [self advanceFocus];            // JOEL NORVELL ADDITION
        return YES;
    }
    
    

    else
    {
       // _rejectDrag = YES;
        return NO;
    }
       
}



// -------------------------------------------------------------------------------------------------------------- advanceFocus - JOEL NORVELL ADDITION

// Tab key was hit; move focus to the next widget.
- (void) advanceFocus
{
    NSString    *theType;
    
    if (_activeAnnotation != NULL)
    {
        PDFPage * currentPage = [_activeAnnotation page];
        
        // Walk array of annotations.
        NSArray *annotations = [currentPage annotations];
        NSUInteger annotCount = [annotations count];
        
        NSUInteger activeIndex = [annotations indexOfObject: _activeAnnotation];
        
        NSUInteger newActiveIndex = [self nextAnnotIndex: activeIndex withinCount: annotCount];
        
        PDFAnnotation * newActiveAnnotation = [annotations objectAtIndex: newActiveIndex];
        if (newActiveAnnotation != NULL)
        {
            theType = newActiveAnnotation.type;
            //NSLog(theType);
        }
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
//        [[AnnotationPanel sharedAnnotationPanel] setAnnotation: NULL];

        // Set edited flag.
        [[self window] setDocumentEdited: YES];
    }
}

- (void) showColorPanel: (id) sender
{
    [[NSColorPanel sharedColorPanel] makeKeyAndOrderFront: self];
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
}

- (void) showFontPanel: (id) sender
{
    [[NSFontPanel sharedFontPanel] makeKeyAndOrderFront: self];
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
   [self reflectFont];
}

- (void) displayChoicesPanel: (id) sender
{
    [[self.myDocument getChoicesPanel] makeKeyAndOrderFront: self];
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
}

- (void) showTextPanel: (id) sender
{
    NSTextView  *theTextView;
    NSRange     theRange;
    NSInteger   theLength;
    NSInteger   value;
    
    [self.myDocument showStringWindow];
    
/*
    value = self.stringAlignment;
    
    theTextView = [self.myDocument getStringWindowTextView];
    theRange.location = 0;
    theLength = [[theTextView string] length];
    theRange.length = theLength;
    
     switch(value)
    {
        case 0:
            [theTextView setAlignment:NSTextAlignmentLeft range: theRange ];
            break;
            
        case 1:
            [theTextView setAlignment:NSTextAlignmentCenter range: theRange ];
            break;
            
        case 2:
            [theTextView setAlignment:NSTextAlignmentRight range: theRange ];
            break;
            
        default:
            [theTextView setAlignment:NSTextAlignmentCenter range: theRange ];
            
    }
 */
  
}

- (void) toggleEditMode: (id) sender
{
    BOOL value;
    
    value = !_editMode;
    
    if (_editMode)
        [self setEditModeInternal: NO andClosePanels:YES];
    else
        [self setEditModeInternal: YES andClosePanels:YES];
    
}

- (void) acceptString: (id) sender
{
    NSString *currentString;
    
    currentString = [self.myDocument getStringWindowString];
    // currentString = @"Hello, world";
    if ((_activeAnnotation != NULL) && ([self isFreeText: _activeAnnotation]))
    {
        [_activeAnnotation setContents: currentString];
        switch (self.stringAlignment)
        {   case 0: [_activeAnnotation setAlignment: NSTextAlignmentLeft];
                break;
        
            case 1: [_activeAnnotation setAlignment: NSTextAlignmentCenter];
                break;
                
            case 2: [_activeAnnotation setAlignment: NSTextAlignmentRight];
                break;
                
            default: [_activeAnnotation setAlignment: NSTextAlignmentCenter];
        }
     }
    
    // Lazy.
    [self setNeedsDisplay: YES];
    
    if ([self.myDocument useFullSplitWindow])
        [ [self.myDocument fullSplitWindow] makeKeyAndOrderFront:self];
    else
        [self.myPDFWindow makeKeyAndOrderFront:self];
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
    NSFont        *newFont;
    
     // Skip out if not in 'edit mode'.
    if (_editMode == NO)
        return;
    
    if (_activeAnnotation == NULL)
        return;
    
    NSString* type = [_activeAnnotation valueForAnnotationKey:PDFAnnotationKeySubtype];
    
    if ([type isEqualToString:PDFAnnotationSubtypeFreeText])
    {
        newFont = [sender convertFont: [_activeAnnotation font]];
        [_activeAnnotation setFont: newFont];
    }
    
    
//     if ([type isEqualToString:PDFAnnotationSubtypeText])
//    {
//        newFont = [sender convertFont: [_activeAnnotation font]];
//        [_activeAnnotation setFont: newFont];
//    }
    
    
    
    // Lazy.
    [self setNeedsDisplay: YES];
}


 
 


- (void) changeColor: (id) sender
{
    NSUInteger      modifiers;
    BOOL            optionPressed;
    NSColor         *theColor;
    
    // Skip out if not in 'edit mode'.
    if (_editMode == NO)
        return;
    
    if (_activeAnnotation == NULL)
        return;
    
    modifiers = ([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
    optionPressed = (modifiers == NSAlternateKeyMask);
    
    theColor = [(NSColorPanel *)sender color];
    
  
    NSString* type = [_activeAnnotation valueForAnnotationKey:PDFAnnotationKeySubtype];
    
    if ((optionPressed) && 
        (([type isEqualToString:PDFAnnotationSubtypeFreeText]) ||
         ([type isEqualToString:PDFAnnotationSubtypeText])))
    {
        [_activeAnnotation setFontColor: theColor];
    }
    else
        [_activeAnnotation setColor: theColor];
        
    // Lazy.
    [self setNeedsDisplay: YES];
}


- (void) reflectText
{
    NSString*   theString;
    
    if (_activeAnnotation == NULL)
        return;
    
    if (![self isFreeText: _activeAnnotation])
        return;
    
   
    
    theString = _activeAnnotation.contents;
        [self.myDocument setStringWindowString: theString];
    
    [self.myDocument setStringWindowAlignment: self.stringAlignment];
      
}

// ----------------------------------------------------------------------------------------------------------- changeFont

- (void) changeString: (id) sender
{
    NSString*   theString;
    
    if (_activeAnnotation == NULL)
        return;
    
    NSString* type = [_activeAnnotation valueForAnnotationKey:PDFAnnotationKeySubtype];
    if ((! [type isEqualToString:PDFAnnotationSubtypeFreeText]) &&
        (! [type isEqualToString:PDFAnnotationSubtypeText]))
        return;
    
    // theString = [_activeAnnotation stringValue];
    
  //  [_activeAnnotation setContents: theString];
    
   
    
    // Lazy.
    [self setNeedsDisplay: YES];
}



// --------------------------------------------------------------------------------------------------- resizeThumbForRect

- (NSRect) resizeThumbForRect: (NSRect) rect rotation: (NSInteger) rotation
{
    NSRect        thumb;
    
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
    
    thumb.size.width = 16.0;
    thumb.size.height = 16.0;
    
    return thumb;
}

- (NSRect) resizeThumbForRectSmall: (NSRect) rect rotation: (NSInteger) rotation
{
    NSRect        thumb;
    
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

- (NSRect) resizeThumbForPoint: (NSPoint) point rotation: (NSInteger) rotation
{
    NSRect        thumb;
    
    // Start with rect.
    // thumb = rect;
    thumb.origin.x = point.x - 8.0;
    thumb.origin.y = point.y - 8.0;
    
    /*
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
    */
    
    thumb.size.width = 8.0;
    thumb.size.height = 8.0;
    
    return thumb;
}

// The routine below starts with an arrow annotation with start at the origin
// and both width and height possibly negative, and produces the same annotation
// with a normal bounds rectangle haveing width and height non-negative, but
// start and end at different corners

- (void)normalizeArrowAnnotation: (PDFAnnotation *) theAnnotation
{
    float   width, height;
    NSRect  bounds, newbounds;
    NSPoint startPoint, endPoint;
    
    if (! [self isArrow: theAnnotation])
        return;
    
    bounds = theAnnotation.bounds;
    width = bounds.size.width;
    height = bounds.size.height;
    
    if ((width >= 0) && (height >= 0))
        ; //do nothing
    else if ((width >= 0) && (height < 0))
        {
            height = - height;
            newbounds = bounds;
            newbounds.origin.x = bounds.origin.x + 0; newbounds.origin.y = bounds.origin.y  -height;
            newbounds.size.height = height;
            startPoint.x = 0; startPoint.y = height;
            endPoint.x = width; endPoint.y = 0;
            [theAnnotation setBounds: newbounds];
            [theAnnotation setStartPoint: startPoint];
            [theAnnotation setEndPoint: endPoint];
         }
    else if ((width < 0) && (height >= 0))
    {
        width = - width;
        newbounds = bounds;
        newbounds.origin.x = bounds.origin.x - width ; newbounds.origin.y = bounds.origin.y;
        newbounds.size.width = width;
        startPoint.x = width; startPoint.y = 0;
        endPoint.x = 0; endPoint.y = height;
        [theAnnotation setBounds: newbounds];
        [theAnnotation setStartPoint: startPoint];
        [theAnnotation setEndPoint: endPoint];
    }
    else
    {
        width = - width; height = - height;
        newbounds = bounds;
        newbounds.origin.x = bounds.origin.x - width; newbounds.origin.y = bounds.origin.y - height;
        newbounds.size.width = width;
        newbounds.size.height = height;
        startPoint.x = width; startPoint.y = height;
        endPoint.x = 0; endPoint.y = 0;
        [theAnnotation setBounds: newbounds];
        [theAnnotation setStartPoint: startPoint];
        [theAnnotation setEndPoint: endPoint];
    }
}

// The routine below reverses the previous step. It starts with an arrow annotations with width and
// height non-negative, and produces an equivalent annotation with the start of the arrow at the
// origin, but possibly negative width, height, or both.

- (void)specializeArrowAnnotation: (PDFAnnotation *) theAnnotation
    {
        NSPoint oldStartPoint, oldEndPoint, newStartPoint, newEndPoint;
        NSRect  oldBounds, newBounds;
        float   width, height;
        
        if (! [self isArrow: theAnnotation])
            return;
        
        oldStartPoint = theAnnotation.startPoint;
        oldEndPoint = theAnnotation.endPoint;
        oldBounds = theAnnotation.bounds;
        width = oldEndPoint.x - oldStartPoint.x;
        height = oldEndPoint.y - oldStartPoint.y;
        newStartPoint.x = 0; newStartPoint.y = 0;
        newEndPoint.x = width; newEndPoint.y = height;
        newBounds.size.width = width; newBounds.size.height = height;
        
        if ((width >= 0) && (height >= 0))
        {
            newBounds.origin.x = oldBounds.origin.x; newBounds.origin.y = oldBounds.origin.y;
        }
        else if ((width < 0) && (height >= 0))
        {
            newBounds.origin.x = oldBounds.origin.x - width; newBounds.origin.y = oldBounds.origin.y;
         }
        else if ((width >= 0) && (height < 0))
        {
            newBounds.origin.x = oldBounds.origin.x; newBounds.origin.y = oldBounds.origin.y - height;
        }
        else
        {
            newBounds.origin.x = oldBounds.origin.x - width; newBounds.origin.y = oldBounds.origin.y- height;
        }
        
        [theAnnotation setBounds: newBounds];
        [theAnnotation setStartPoint: newStartPoint];
        [theAnnotation setEndPoint: newEndPoint];
        
    }

    
@end

