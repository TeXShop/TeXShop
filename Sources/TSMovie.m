//
//  TSMovie.m
//  TeXShop
//
//  Created by Richard Koch on 7/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Globals.h"
#import "TSMovie.h"



@implementation TSMovie

- (void)doMovie:(NSString *)title;
{
	NSRect		currWindowBounds, newWindowBounds;
    NSPoint		topLeft;
	float		fixedHeight;
	NSString	*fileName;
	
	if (movieWindow == nil) {
		// we need to load the nib
		if ([NSBundle loadNibNamed:@"Movie" owner:self] == NO) {
			NSRunAlertPanel(@"Error", @"Could not load Movie.nib", @"shit happens", nil, nil);
		}

		// fill in all the values here since the window will be brought up for the first time
		/* koch: I moved this command two lines below, so it will ALWAYS be called
		when showing preferences: [self updateControlsFromUserDefaults:SUD]; */
	}
	
	fileName = [[[MoviesPath stringByAppendingString:@"/TeXShop/"] stringByAppendingString: title] stringByStandardizingPath];
	NSData	*myData =  [NSData dataWithContentsOfFile:fileName];
	myMovie = [QTMovie movieWithData: myData error:nil];
	[myMovieView setMovie: myMovie];
	
	
	currWindowBounds = [[myMovieView window] frame];
    topLeft.x = currWindowBounds.origin.x;
    topLeft.y = currWindowBounds.origin.y + currWindowBounds.size.height;
	
    NSSize contentSize = [[myMovie attributeForKey:QTMovieCurrentSizeAttribute] sizeValue];
	fixedHeight = [myMovieView movieControllerBounds].size.height;
	contentSize.height += fixedHeight;

    if (contentSize.width == 0)
        contentSize.width = currWindowBounds.size.width;
	
    newWindowBounds = [[myMovieView window] frameRectForContentRect:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
    [[myMovieView window] setFrame:NSMakeRect(topLeft.x, topLeft.y - newWindowBounds.size.height, newWindowBounds.size.width, newWindowBounds.size.height) display:NO];
	
	[myMovieView setPreservesAspectRatio: YES];

	[movieWindow makeKeyAndOrderFront:self];
	
	[myMovieView play:self];
}


@end
