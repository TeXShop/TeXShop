//
//  TSMovieWindow.h
//  TeXShop
//
//  Created by Richard Koch on 7/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h> 



@interface TSMovieWindow : NSWindow {

}

@property (retain) QTMovieView	*myMovieView;

- (void)close;


@end
