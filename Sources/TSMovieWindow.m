//
//  TSMovieWindow.m
//  TeXShop
//
//  Created by Richard Koch on 7/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TSMovieWindow.h"


@implementation TSMovieWindow

- (void)close
{
//	[[self.myMovieView movie] stop];
    
    [self.myPlayerView.player pause];
	[super close];
}

@end
