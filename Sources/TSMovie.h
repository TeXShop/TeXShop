//
//  TSMovie.h
//  TeXShop
//
//  Created by Richard Koch on 7/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import <AVKit/AVPlayerView.h>
#import <AVFoundation/AVPlayer.h>

#import	"TSMovieWindow.h"
#import <Foundation/Foundation.h>

@interface TSMovie : NSObject <NSURLDownloadDelegate>   {
    
    
IBOutlet TSMovieWindow	*movieWindow;
IBOutlet AVPlayerView   *myPLayerView;
 
}
// @property (retain) QTMovie		*myMovie;
@property (retain) AVPlayer         *myMovie;
@property (retain) NSString			*myTitle;

- (void)doMovie:(NSString *)title;
- (void)bringUpMovie;

@end
