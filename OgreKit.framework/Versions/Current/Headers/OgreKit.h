/*
 * Name: OgreKit.h
 * Project: OgreKit
 *
 * Creation Date: Sep 7 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>

#ifndef NOT_RUBY
#	define NOT_RUBY
#endif
#ifndef HAVE_CONFIG_H
#	define HAVE_CONFIG_H
#endif
#import <OgreKit/oniguruma.h>

// Regular Expressions
#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionFormatter.h>
#import <OgreKit/OGReplaceExpression.h>
#import <OgreKit/NSString_OgreKitAdditions.h>
// Find Panel
#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreTextFindThread.h>
#import <OgreKit/OgreTextFindThreadCenter.h>
#import <OgreKit/OgreTextFindProgressSheet.h>
#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreFindResult.h>
#import <OgreKit/OgreFindPanelController.h>
#import <OgreKit/OgreTextView.h>