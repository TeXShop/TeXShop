/*
 * Name: OgreTextViewAdapter.m
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextViewAdapter.h>
#import <OgreKit/OgreTextViewPlainAdapter.h>
#import <OgreKit/OgreTextViewRichAdapter.h>
#import <OgreKit/OgreTextViewGraphicAllowedAdapter.h>


@implementation OgreTextViewAdapter

/* Creating and initializing */
- (id)initWithTarget:(id)aTextView
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -initWithTextView: of %@", [self className]);
#endif
    [super release];
	NSTextView	*textView = (NSTextView*)aTextView;
    if (![textView isRichText]) {
		return (OgreTextViewAdapter*)[[OgreTextViewPlainAdapter alloc] initWithTarget:textView];
	}
    if (![textView importsGraphics]) {
		return (OgreTextViewAdapter*)[[OgreTextViewRichAdapter alloc] initWithTarget:textView];
	}
	
    return (OgreTextViewAdapter*)[[OgreTextViewGraphicAllowedAdapter alloc] initWithTarget:textView];
}

- (OgreTextFindLeaf*)buildStackForSelectedLeafInThread:(OgreTextFindThread*)aThread
{
	/* dummy */
	return nil;
}

- (void)moveHomePosition
{
    /* dummy */
}

@end
