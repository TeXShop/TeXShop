//
//  TSMovie.h
//  TeXShop
//
//  Created by Richard Koch on 7/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <QTKit/QTMovieView.h>
#import	"TSMovieWindow.h"

@interface TSMovie : NSObject {
    
}

@property (retain) TSMovieWindow	*movieWindow;
@property (retain) QTMovieView		*myMovieView;
@property (retain) QTMovie			*myMovie;

- (void)doMovie:(NSString *)title;

@end
