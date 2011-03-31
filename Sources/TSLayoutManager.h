/*
 TSLayoutManager.h 
 Created by Terada on Feb 2011.
 
 ------------
 TSLayoutManager is based on CotEditor - CELayoutManager (written by nakamuxu – http://www.aynimac.com/)
 CotEditor Copyright (c) 2004-2007 nakamuxu, All rights reserved.
 CotEditor is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html
 arranged by Terada, Feb 2011.
 -------------------------------------------------
 
 ------------
 CELayoutManager is based on Smultron - SMLLayoutManager (written by Peter Borg – http://smultron.sourceforge.net)
 Smultron Copyright (c) 2004 Peter Borg, All rights reserved.
 Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html
 arranged by nakamuxu, Jan 2005.
 -------------------------------------------------
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 
 
 =================================================
 */

#import <Cocoa/Cocoa.h>

@interface TSLayoutManager : NSLayoutManager {
    NSArray *tabCharacters;
    NSArray *newLineCharacters;
    NSArray *fullwidthSpaceCharacters;
    NSArray *spaceCharacters;
	BOOL invisibleCharactersShowing;
}
- (void)setInvisibleCharactersEnabled:(BOOL)enabled;
@end
