//
//  OgreTextView.h
//  OgreKit
//
//  Created by Isao Sonobe on Sun Jun 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface OgreTextView : NSTextView
{
    id          _observableControllerForDataBinding;
    NSString    *_keyPathForDataBinding;

    id          _observableControllerForValueBinding;
    NSString    *_keyPathForValueBinding;
}

- (void)ogreDidEndEditing;

@end
