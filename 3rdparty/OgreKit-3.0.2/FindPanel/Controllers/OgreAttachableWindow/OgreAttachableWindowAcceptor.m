/*
 * Name: OgreAttachableWindowAcceptor.m
 * Project: OgreKit
 *
 * Creation Date: Aug 30 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2004-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreAttachableWindowAcceptor.h>
#import <OgreKit/OgreAttachableWindowMediator.h>


@implementation OgreAttachableWindowAcceptor

- (void)awakeFromNib
{
	[[OgreAttachableWindowMediator sharedMediator] addAcceptor:self];	// 必須
	
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(windowWillMove:)
		name:NSWindowWillMoveNotification
		object:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:self];
	[[OgreAttachableWindowMediator sharedMediator] removeAcceptor:self];	// 必須
    [super dealloc];
}

- (BOOL)isAttachableAcceptorEdge:(NSRectEdge)edge toAcceptee:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee
{
	return YES;
}

/* notifications */
- (void)windowWillMove:(id)notification
{
//    [[self childWindows] makeObjectsPerformSelector:@selector(setDragging:) withObject:NO];
    [[self childWindows] enumerateObjectsUsingBlock:^(__kindof NSWindow * _Nonnull childWindow, NSUInteger idx, BOOL * _Nonnull stop) {
        [childWindow setDragging:NO];
    }];
}

- (void)didAttachWindow:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee
{
	/* do nothing */
}

- (void)didDetachWindow:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee
{
	/* do nothing */
}

@end
