//
//  TSMovieWindow.h
//  TeXShop
//
//  Created by Richard Koch on 7/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import <AVKit/AVPlayerView.h>
#import <AVFoundation/AVPlayer.h>



@interface TSMovieWindow : NSWindow {

    
    
}

@property (nonatomic, strong) IBOutlet AVPlayerView   *myPlayerView;

- (void)close;


@end
