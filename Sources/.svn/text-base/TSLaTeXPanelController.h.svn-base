/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2005 Richard Koch
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * $Id$
 *
 * Created by lenglin on Sun Aug 26 2001.
 *
 */

#import <AppKit/AppKit.h>


@interface TSLaTeXPanelController : NSWindowController
{
	IBOutlet id environbuttonmatrix;
	IBOutlet id functionsbuttonmatrix;
	IBOutlet id greekbuttonmatrix;
	IBOutlet id intlbuttonmatrix;
	IBOutlet id mathbuttonmatrix;
	IBOutlet id symbolsbuttonmatrix;
	IBOutlet id typefacebuttonmatrix;
	// added by Georg Klein
	IBOutlet id custombuttonmatrix;
	NSArray *arrayCustomized;
	// end add
	NSArray *arrayFunctions1,*arrayFunctions2,*arrayEnvironments,*arrayTypeface,*arrayInternational,*arrayGreek,*arrayMath,*arraySymbols;
	NSNotificationCenter *notifcenter;
	BOOL shown; //YES if user has chosen to display panel
}

+ (id)sharedInstance;
- (IBAction)putenvironments:(id)sender;
- (IBAction)putfunctions1:(id)sender;
- (IBAction)putgreek:(id)sender;
- (IBAction)putintl:(id)sender;
- (IBAction)putmath:(id)sender;
- (IBAction)putsymbols:(id)sender;
- (IBAction)puttypeface:(id)sender;
- (void)hideWindow:(id)sender;
@end
