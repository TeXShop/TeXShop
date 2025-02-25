//
//  NoodleLineNumberView.m
//  NoodleKit
//
//  Created by Paul Kim on 9/28/08.
//  Copyright (c) 2008 Noodlesoft, LLC. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"
#import <tgmath.h>
// FIX RULER SCROLL
#import "globals.h"
// END FIX RULER SCROLL

#define DEFAULT_THICKNESS	22.0
#define RULER_MARGIN		5.0

@interface NoodleLineNumberView (Private)

- (NSMutableArray *)lineIndices;
- (void)invalidateLineIndices;
- (void)calculateLines;
- (NSUInteger)lineNumberForCharacterIndex:(NSUInteger)index inText:(NSString *)text;
- (NSDictionary *)textAttributes;
- (NSDictionary *)markerTextAttributes;

@end

@implementation NoodleLineNumberView

- (id)initWithScrollView: (NSScrollView *)aScrollView
{
    if ((self = [super initWithScrollView:aScrollView orientation:NSVerticalRuler]) != nil)
    {
		_linesToMarkers = [[NSMutableDictionary alloc] init];
		
        [self setClientView:[aScrollView documentView]];
        
        // In Monterey, a bug causes many line numbers to be omitted during scrolling. Below is a fix. 8/8/2021 Koch
        
        if (atLeastMonterey)
            
            self.myScrollView = aScrollView;
        
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollEnded:) name:NSScrollViewDidEndLiveScrollNotification object:(NSScrollView *)aScrollView];
    }
    return self;
}

- (void)awakeFromNib
{
	_linesToMarkers = [[NSMutableDictionary alloc] init];
	[self setClientView:[[self scrollView] documentView]];
}

/*
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_lineIndices release];
	[_linesToMarkers release];
    [_font release];
    
    [super dealloc];
}
*/

- (void)setFont:(NSFont *)aFont
{
    if (_font != aFont)
    {
//		[_font autorelease];
//		_font = [aFont retain];
        _font = aFont;
    }
}

- (NSFont *)font
{
    NSInteger lineSize;
    
    lineSize = [SUD integerForKey: LineNumberSizeKey];
        
	if (_font == nil)
    {
        if (lineSize == 0)
            return [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]];
        else if (lineSize == 1)
            return [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeRegular]];
        else
            return [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]];
    }
        
    return _font;
}

- (void)setTextColor:(NSColor *)color
{
	if (_textColor != color)
	{
//		[_textColor autorelease];
//		_textColor  = [color retain];
	}
}

- (NSColor *)textColor
{
	if (_textColor == nil)
	{
		return [NSColor colorWithCalibratedWhite:0.42 alpha:1.0];
	}
	return _textColor;
}

- (void)setAlternateTextColor:(NSColor *)color
{
	if (_alternateTextColor != color)
	{
//		[_alternateTextColor autorelease];
//		_alternateTextColor = [color retain];
	}
}

- (NSColor *)alternateTextColor
{
	if (_alternateTextColor == nil)
	{
		return [NSColor whiteColor];
	}
	return _alternateTextColor;
}

- (void)setBackgroundColor:(NSColor *)color
{
	if (_backgroundColor != color)
	{
//		[_backgroundColor autorelease];
//		_backgroundColor = [color retain];
	}
}

- (NSColor *)backgroundColor
{
	return _backgroundColor;
}

- (void)setClientView:(NSView *)aView
{
	id		oldClientView;
	
	oldClientView = [self clientView];
	
    if ((oldClientView != aView) && [oldClientView isKindOfClass:[NSTextView class]])
    {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTextStorageDidProcessEditingNotification object:[(NSTextView *)oldClientView textStorage]];
    }
    [super setClientView:aView];
    if ((aView != nil) && [aView isKindOfClass:[NSTextView class]])
    {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextStorageDidProcessEditingNotification object:[(NSTextView *)aView textStorage]];

		[self invalidateLineIndices];
    }
}

- (NSMutableArray *)lineIndices
{
	if (_lineIndices == nil)
	{
		[self calculateLines];
	}
	return _lineIndices;
}

- (void)invalidateLineIndices
{
//	[_lineIndices release];
	_lineIndices = nil;
}

- (void)textDidChange:(NSNotification *)notification
{
  //  if (notification.object == [self.clientView textStorage])
    {
        // Invalidate the line indices. They will be recalculated and recached on demand.
        [self invalidateLineIndices];
	
        [self setNeedsDisplay:YES];
    }
}

- (void)scrollEnded:(NSNotification *)notification
{
    // This was introduced to fix a bug in an earlier system.
    // It is not needed in Sonoma because Apple fixed that bug.
    
    if (atLeastSonoma)
        return;
    
    // Invalidate the line indices. They will be recalculated and recached on demand.
   // [self invalidateLineIndices];
    if (notification.object == self.myScrollView)
        [self setNeedsDisplay:YES];
}

- (NSUInteger)lineNumberForLocation:(CGFloat)location
{
	NSUInteger		line, count, index, rectCount, i;
	NSRectArray		rects;
	NSRect			visibleRect;
	NSLayoutManager	*layoutManager;
	NSTextContainer	*container;
	NSRange			nullRange;
	NSMutableArray	*lines;
	id				view;
		
	view = [self clientView];
	visibleRect = [[[self scrollView] contentView] bounds];
	
	lines = [self lineIndices];

	location += NSMinY(visibleRect);
	
	if ([view isKindOfClass:[NSTextView class]])
	{
		nullRange = NSMakeRange(NSNotFound, 0);
		layoutManager = [view layoutManager];
		container = [view textContainer];
		count = [lines count];
		
		for (line = 0; line < count; line++)
		{
			index = [[lines objectAtIndex:line] unsignedIntegerValue];
			
			rects = [layoutManager rectArrayForCharacterRange:NSMakeRange(index, 0)
								 withinSelectedCharacterRange:nullRange
											  inTextContainer:container
													rectCount:&rectCount];
			
			for (i = 0; i < rectCount; i++)
			{
				if ((location >= NSMinY(rects[i])) && (location < NSMaxY(rects[i])))
				{
					return line + 1;
				}
			}
		}	
	}
	return NSNotFound;
}

- (NoodleLineNumberMarker *)markerAtLine:(NSUInteger)line
{
	return [_linesToMarkers objectForKey:[NSNumber numberWithUnsignedInteger:line - 1]];
}


- (void)calculateLines
{
    id              view;

    view = [self clientView];
    
    if ([view isKindOfClass:[NSTextView class]])
    {
        NSUInteger      index, numberOfLines, stringLength, lineEnd, contentEnd;
        NSString        *text;
        CGFloat         oldThickness, newThickness;
        
        text = [view string];
        stringLength = [text length];
//        [_lineIndices release];
        _lineIndices = [[NSMutableArray alloc] init];
        
        index = 0;
        numberOfLines = 0;
        
        do
        {
            [_lineIndices addObject:[NSNumber numberWithUnsignedInteger:index]];
            
            index = NSMaxRange([text lineRangeForRange:NSMakeRange(index, 0)]);
            numberOfLines++;
        }
        while (index < stringLength);

        // Check if text ends with a new line.
        [text getLineStart:NULL end:&lineEnd contentsEnd:&contentEnd forRange:NSMakeRange([[_lineIndices lastObject] unsignedIntegerValue], 0)];
        if (contentEnd < lineEnd)
        {
            [_lineIndices addObject:[NSNumber numberWithUnsignedInteger:index]];
        }

        oldThickness = [self ruleThickness];
        newThickness = [self requiredThickness];
        /*
        if (fabs(oldThickness - newThickness) > 1)
        {
			NSInvocation			*invocation;
			
			// Not a good idea to resize the view during calculations (which can happen during
			// display). Do a delayed perform (using NSInvocation since arg is a float).
			invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(setRuleThickness:)]];
			[invocation setSelector:@selector(setRuleThickness:)];
			[invocation setTarget:self];
			[invocation setArgument:&newThickness atIndex:2];
			// The following line was suggested by Martin Hairer to avoid a crash on x86_64 Big Sur. Nobody else reported such a crash.
            [invocation retainArguments];
			[invocation performSelector:@selector(invoke) withObject:nil afterDelay:0.0];
        }
    */
    // Later Martin Hairer proposed the following safer and shorter fix
        
        if (fabs(oldThickness - newThickness) > 1)
              {
                  dispatch_async(dispatch_get_main_queue(), ^{
                      [self setRuleThickness:newThickness];
                  });
              }
         
	}
}

- (NSUInteger)lineNumberForCharacterIndex:(NSUInteger)index inText:(NSString *)text
{
    NSUInteger			left, right, mid, lineStart;
	NSMutableArray		*lines;

	lines = [self lineIndices];
	
    // Binary search
    left = 0;
    right = [lines count];

    while ((right - left) > 1)
    {
        mid = (right + left) / 2;
        lineStart = [[lines objectAtIndex:mid] unsignedIntegerValue];
        
        if (index < lineStart)
        {
            right = mid;
        }
        else if (index > lineStart)
        {
            left = mid;
        }
        else
        {
            return mid;
        }
    }
    return left;
}

- (NSDictionary *)textAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [self font], NSFontAttributeName, 
            [self textColor], NSForegroundColorAttributeName,
            nil];
}

- (NSDictionary *)markerTextAttributes
{
	    return [NSDictionary dictionaryWithObjectsAndKeys:
            [self font], NSFontAttributeName, 
            [self alternateTextColor], NSForegroundColorAttributeName,
				nil];
}

- (CGFloat)requiredThickness
{
    NSUInteger			lineCount, digits, i;
    NSMutableString     *sampleString;
    NSSize              stringSize;
    
    lineCount = [[self lineIndices] count];
    digits = (NSUInteger)log10(lineCount) + 1;
	sampleString = [NSMutableString string];
    for (i = 0; i < digits; i++)
    {
        // Use "8" since it is one of the fatter numbers. Anything but "1"
        // will probably be ok here. I could be pedantic and actually find the fattest
		// number for the current font but nah.
        [sampleString appendString:@"8"];
    }
    
    stringSize = [sampleString sizeWithAttributes:[self textAttributes]];

	// Round up the value. There is a bug on 10.4 where the display gets all wonky when scrolling if you don't
	// return an integral value here.
    return ceil(MAX(DEFAULT_THICKNESS, stringSize.width + RULER_MARGIN * 2));
}

// FIX RULER SCROLL
/*
- (void)setDocument:(TSDocument*)document  // added by Terada (for Lion bug)
{
    _document = document;    
}
*/
// END FIX RULER SCROLL

- (void)drawHashMarksAndLabelsInRect:(NSRect)aRect
{
    id			view;
	NSRect		bounds;
    
    
 	bounds = [self bounds];
    view = [self clientView];

// FIX RULER SCROLL
    if ([SUD boolForKey:FixLineNumberScrollKey])
        [self.document redrawLineNumbers:view];
// END FIX RULER SCROLL

	if (_backgroundColor != nil)
	{
		[_backgroundColor set];
		NSRectFill(bounds);
        
		[[NSColor colorWithCalibratedWhite:0.58 alpha:1.0] set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(bounds) - 0/5, NSMinY(bounds)) toPoint:NSMakePoint(NSMaxX(bounds) - 0.5, NSMaxY(bounds))];
	}
	
    // view = [self clientView];
	
    if ([view isKindOfClass:[NSTextView class]])
    {
        NSLayoutManager			*layoutManager;
        NSTextContainer			*container;
        NSRect					visibleRect, markerRect;
        NSRange					range, glyphRange, nullRange;
        NSString				*text, *labelText;
        NSUInteger				rectCount, index, line, count;
        NSRectArray				rects;
        CGFloat					ypos, yinset;
        NSDictionary			*textAttributes, *currentTextAttributes;
        NSSize					stringSize, markerSize;
		NoodleLineNumberMarker	*marker;
		NSImage					*markerImage;
		NSMutableArray			*lines;

        layoutManager = [view layoutManager];
        container = [view textContainer];
        text = [view string];
        nullRange = NSMakeRange(NSNotFound, 0);
		
		yinset = [view textContainerInset].height;        
        visibleRect = [[[self scrollView] contentView] bounds];

        textAttributes = [self textAttributes];
		
		lines = [self lineIndices];

        // Find the characters that are currently visible
        glyphRange = [layoutManager glyphRangeForBoundingRect:visibleRect inTextContainer:container];
        range = [layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
        
        // Fudge the range a tad in case there is an extra new line at end.
        // It doesn't show up in the glyphs so would not be accounted for.
        range.length++;
        
        count = [lines count];
        
        
        for (line = [self lineNumberForCharacterIndex:range.location inText:text]; line < count; line++)
        {
            index = [[lines objectAtIndex:line] unsignedIntegerValue];
            
            if (NSLocationInRange(index, range))
            {
                rects = [layoutManager rectArrayForCharacterRange:NSMakeRange(index, 0)
                                     withinSelectedCharacterRange:nullRange
                                                  inTextContainer:container
                                                        rectCount:&rectCount];
				
                if (rectCount > 0)
                {
                    // Note that the ruler view is only as tall as the visible
                    // portion. Need to compensate for the clipview's coordinates.
                    ypos = yinset + NSMinY(rects[0]) - NSMinY(visibleRect);
					
					marker = [_linesToMarkers objectForKey:[NSNumber numberWithUnsignedInteger:line]];
					
					if (marker != nil)
					{
						
                        markerImage = [marker image];
						markerSize = [markerImage size];
						markerRect = NSMakeRect(0.0, 0.0, markerSize.width, markerSize.height);

						// Marker is flush right and centered vertically within the line.
						markerRect.origin.x = NSWidth(bounds) - [markerImage size].width - 1.0;
						markerRect.origin.y = ypos + NSHeight(rects[0]) / 2.0 - [marker imageOrigin].y;

                        [markerImage drawInRect:markerRect fromRect:NSMakeRect(0, 0, markerSize.width, markerSize.height) operation:NSCompositeSourceOver fraction:1.0];
					}
                    
                    // Line numbers are internally stored starting at 0
                    labelText = [NSString stringWithFormat:@"%jd", (intmax_t)line + 1];
                    
                    stringSize = [labelText sizeWithAttributes:textAttributes];

					if (marker == nil)
					{
						currentTextAttributes = textAttributes;
					}
					else
					{
						currentTextAttributes = [self markerTextAttributes];
					}
					
                    // Draw string flush right, centered vertically within the line
                    [labelText drawInRect:
                       NSMakeRect(NSWidth(bounds) - stringSize.width - RULER_MARGIN,
                                  ypos + (NSHeight(rects[0]) - stringSize.height) / 2.0,
                                  NSWidth(bounds) - RULER_MARGIN * 2.0, NSHeight(rects[0]))
                           withAttributes:currentTextAttributes];
                }
            }
			if (index > NSMaxRange(range))
			{
				break;
			}
        }
    }
}

- (void)setMarkers:(NSArray *)markers
{
	NSEnumerator		*enumerator;
	NSRulerMarker		*marker;
	
	[_linesToMarkers removeAllObjects];
	[super setMarkers:nil];

	enumerator = [markers objectEnumerator];
	while ((marker = [enumerator nextObject]) != nil)
	{
		[self addMarker:marker];
	}
}

- (void)addMarker:(NSRulerMarker *)aMarker
{
	if ([aMarker isKindOfClass:[NoodleLineNumberMarker class]])
	{
		[_linesToMarkers setObject:aMarker
							forKey:[NSNumber numberWithUnsignedInteger:[(NoodleLineNumberMarker *)aMarker lineNumber] - 1]];
	}
	else
	{
		[super addMarker:aMarker];
	}
}

- (void)removeMarker:(NSRulerMarker *)aMarker
{
	if ([aMarker isKindOfClass:[NoodleLineNumberMarker class]])
	{
		[_linesToMarkers removeObjectForKey:[NSNumber numberWithUnsignedInteger:[(NoodleLineNumberMarker *)aMarker lineNumber] - 1]];
	}
	else
	{
		[super removeMarker:aMarker];
	}
}

#pragma mark NSCoding methods

#define NOODLE_FONT_CODING_KEY				@"font"
#define NOODLE_TEXT_COLOR_CODING_KEY		@"textColor"
#define NOODLE_ALT_TEXT_COLOR_CODING_KEY	@"alternateTextColor"
#define NOODLE_BACKGROUND_COLOR_CODING_KEY	@"backgroundColor"

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder]) != nil)
	{
		if ([decoder allowsKeyedCoding])
		{
			_font = [decoder decodeObjectForKey:NOODLE_FONT_CODING_KEY];
			_textColor = [decoder decodeObjectForKey:NOODLE_TEXT_COLOR_CODING_KEY];
			_alternateTextColor = [decoder decodeObjectForKey:NOODLE_ALT_TEXT_COLOR_CODING_KEY];
			_backgroundColor = [decoder decodeObjectForKey:NOODLE_BACKGROUND_COLOR_CODING_KEY];
		}
		else
		{
			_font = [decoder decodeObject];
			_textColor = [decoder decodeObject];
			_alternateTextColor = [decoder decodeObject];
			_backgroundColor = [decoder decodeObject];
		}
		
		_linesToMarkers = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	
	if ([encoder allowsKeyedCoding])
	{
		[encoder encodeObject:_font forKey:NOODLE_FONT_CODING_KEY];
		[encoder encodeObject:_textColor forKey:NOODLE_TEXT_COLOR_CODING_KEY];
		[encoder encodeObject:_alternateTextColor forKey:NOODLE_ALT_TEXT_COLOR_CODING_KEY];
		[encoder encodeObject:_backgroundColor forKey:NOODLE_BACKGROUND_COLOR_CODING_KEY];
	}
	else
	{
		[encoder encodeObject:_font];
		[encoder encodeObject:_textColor];
		[encoder encodeObject:_alternateTextColor];
		[encoder encodeObject:_backgroundColor];
	}
}

@end
