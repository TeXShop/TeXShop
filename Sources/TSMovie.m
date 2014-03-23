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
	CGFloat		fixedHeight;
	NSString	*fileName;
	
	if (self.movieWindow == nil) {
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
	self.myMovie = [QTMovie movieWithData: myData error:nil];
	[self.myMovieView setMovie: self.myMovie];
	
	
	currWindowBounds = [[self.myMovieView window] frame];
    topLeft.x = currWindowBounds.origin.x;
    topLeft.y = currWindowBounds.origin.y + currWindowBounds.size.height;
	
    // QTMovieCurrentSizeAttribute is deprecated, but no replacement is given in the
    // documentation. Since currently there are only two movies, we hard code their size
    // for now
    
    NSSize contentSize; // = [[myMovie attributeForKey:QTMovieCurrentSizeAttribute] sizeValue];
    contentSize.width = 635;
    contentSize.height = 406;
    
	fixedHeight = [self.myMovieView movieControllerBounds].size.height;
	contentSize.height += fixedHeight;

    if (contentSize.width == 0)
        contentSize.width = currWindowBounds.size.width;
	
    newWindowBounds = [[self.myMovieView window] frameRectForContentRect:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
    [[self.myMovieView window] setFrame:NSMakeRect(topLeft.x, topLeft.y - newWindowBounds.size.height, newWindowBounds.size.width, newWindowBounds.size.height) display:NO];
	
	[self.myMovieView setPreservesAspectRatio: YES];

	[self.movieWindow makeKeyAndOrderFront:self];
	
	[self.myMovieView play:self];
}


@end
