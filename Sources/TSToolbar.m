//
//  TSToolbar.m
//  TeXShop
//
//  Created by Richard Koch on 3/27/11.
//  Copyright 2011 University of Oregon. All rights reserved.
//

#import "TSToolbar.h"


@implementation TSToolbar

- (NSArray *)visibleItems
{
	if (visibleOff)
		return ([NSArray array]);
	else
		return ([super visibleItems]);
} 

- (void)turnVisibleOff:(BOOL)value;
{
	visibleOff = value;
}

@end
