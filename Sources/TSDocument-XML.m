/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2019 Richard Koch
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
 * $Id: TSDocument-Jobs.m 254 2014-06-28 21:09:25Z fingolfin $
 *
 */


#import "TSDocument.h"
#import "globals.h"
#import "GlobalData.h"
#import "TSColorSupport.h"
#import "MyPDFKitView.h"
#import "TSAppDelegate.h"


@implementation TSDocument (XML)

- (BOOL) isValidLetter: (char) c
{
  if (('A' <= c) && (c <= 'Z'))
      return TRUE;
  else if (('a' <= c) && (c <= 'z'))
        return TRUE;
  else if (c == '/')
      return TRUE;
  else
      return FALSE;
}

- (void) syntaxColorXMLCommentsfrom: (NSUInteger) aLineStart to: (NSUInteger) aLineEnd using: (NSString *) textString
                               with: (NSLayoutManager *) layoutManager
{
    //    @property (retain)  NSDictionary        *commentXMLColorAttribute;
    //   @property (retain)  NSDictionary        *tagXMLColorAttribute;
    //   @property (retain)  NSDictionary        *propertyXMLColorAttribute;
    //   @property (retain)  NSDictionary        *stringXMLColorAttribute;
    //   @property (retain)  NSDictionary        *limitedXMLColorAttribute;
    

    NSRange colorRange, searchRange, search1Range, myRange;
    NSUInteger  location;
    BOOL        done;
    
    location = aLineStart;
    myRange.location = location;
    myRange.length = aLineEnd - location;
    searchRange = [textString rangeOfString: @"<!--" options: NSLiteralSearch  range: myRange];
    search1Range = [textString rangeOfString: @"-->" options: NSLiteralSearch  range: myRange];
    
    if ((search1Range.location != NSNotFound)  && ((searchRange.location == NSNotFound) || (searchRange.location > search1Range.location)))
    {
        colorRange.location = aLineStart;
        colorRange.length = search1Range.location - colorRange.location + 3;
        [layoutManager addTemporaryAttributes:self.commentXMLColorAttribute forCharacterRange:colorRange];
        location = search1Range.location + 4;
    }
    
    
    done = FALSE;
     while ((location < aLineEnd) && (! done))
    {
        myRange.location = location;
        myRange.length = aLineEnd - location;
        searchRange = [textString rangeOfString: @"<!--" options: NSLiteralSearch  range: myRange];
        search1Range = [textString rangeOfString: @"-->" options: NSLiteralSearch  range: myRange];
        if ((searchRange.location != NSNotFound) && (search1Range.location != NSNotFound)
            && (searchRange.location < search1Range.location))
        {
            colorRange.location = searchRange.location;
            colorRange.length = search1Range.location - colorRange.location + 3;
            [layoutManager addTemporaryAttributes:self.commentXMLColorAttribute forCharacterRange:colorRange];
            location = search1Range.location + 4;
        }
        else
            done = TRUE;
        
    }
    
    if (location < aLineEnd)
    {
        myRange.location = location;
        myRange.length = aLineEnd - location;
        searchRange = [textString rangeOfString: @"<!--" options: NSLiteralSearch  range: myRange];
        search1Range = [textString rangeOfString: @"-->" options: NSLiteralSearch  range: myRange];
        
        if ((searchRange.location != NSNotFound)  && ((search1Range.location == NSNotFound) || (search1Range.location < search1Range.location)))
        {
            colorRange.location = searchRange.location;
            colorRange.length = aLineEnd - colorRange.location + 3;
            [layoutManager addTemporaryAttributes:self.commentXMLColorAttribute forCharacterRange:colorRange];
            location = search1Range.location + 4;
        }
        
    }
    
    
}



// Triggered by <
- (void) syntaxColorXML: (NSUInteger *)location from: (NSUInteger) lineStart to: (NSUInteger) lineEnd
                  using: (NSString *)textString with: (NSLayoutManager *) layoutManager
{
    NSUInteger limit;
    NSRange colorRange, myRange, searchRange;
    char c;
    int mode;
 
    (*location)++;
    if ((*location) < lineEnd) {
        colorRange.location = *location;
        colorRange.length = 1;
      //  (*location)++;
        if (((*location) < lineEnd) && (![self isValidLetter:[textString characterAtIndex: (*location)]])) {
            (*location)++;
            colorRange.length = *location - colorRange.location;
            //    commandString = [textString substringWithRange: colorRange];
        } else {
            while ((*location < lineEnd) && ([self isValidLetter:[textString characterAtIndex: (*location)]])) {
                (*location)++;
                colorRange.length = *location - colorRange.location;
            }
        }
        //abcString = [textString substringWithRange: colorRange];
        [layoutManager addTemporaryAttributes:self.tagXMLColorAttribute forCharacterRange:colorRange];
    }
        myRange.location = *location;
        myRange.length = lineEnd - myRange.location;
        searchRange = [textString rangeOfString: @">" options: NSLiteralSearch  range: myRange];
        if (searchRange.location == NSNotFound)
            return;
        limit = searchRange.location;
    
            do
            {
                mode = 1; // looking for nonblank character
                
                do {
                    c = [textString characterAtIndex: (*location)];
                    (*location)++;
                    if (c == '>')
                        return;
                    }
                while ((c == ' ') || (c == '?'));
                
                colorRange.location = *location -1;
                mode = 2; // constructing property string
                
                do {
                    c = [textString characterAtIndex: (*location)];
                    (*location)++;
                    if (c == '>')
                        return;
                }
                while (c != '=');
                
                colorRange.length = *location - colorRange.location - 1;
                [layoutManager addTemporaryAttributes:self.parameterXMLColorAttribute forCharacterRange:colorRange];
                mode = 4; // constructing string; there was no mode 3
                
                do {
                    c = [textString characterAtIndex: (*location)];
                    (*location)++;
                    if (c == '>')
                        return;
                    if ((c == '\"') && (mode == 4))
                         {
                             mode = 5;
                             colorRange.location = *location;
                             c = 'x';
                         }
                     if ((c == '\"') && (mode == 5))
                          {
                              mode = 6;
                              colorRange.length = *location - colorRange.location - 1;
                               [layoutManager addTemporaryAttributes:self.valueXMLColorAttribute forCharacterRange:colorRange];
                          }
                }
                while (c != '\"');
                  
            }
    while ((*location) < limit);
       }
        


- (void) syntaxColorLimitedXML: (NSUInteger *)location and: (NSUInteger) lineEnd
                         using: (NSString *)textString with: (NSLayoutManager *) layoutManager
{
    NSRange searchRange, myRange, colorRange;
    
    myRange.location = *location + 1;
    myRange.length = lineEnd - myRange.location;
    searchRange = [textString rangeOfString: @";" options: NSLiteralSearch  range: myRange];
    if (searchRange.location != NSNotFound)
    {
        colorRange.location = (*location) + 1;
        colorRange.length = searchRange.location - colorRange.location;
        [layoutManager addTemporaryAttributes:self.specialXMLColorAttribute forCharacterRange:colorRange];
        (*location) = colorRange.location + 1;
    }
    else
 
    (*location)++;
}

- (NSInteger)xmlTag: (NSString *)line;
{
    NSInteger i, result;
    NSString *tag, *cleanline;
    
    result = -1;
    cleanline = [line stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    
    for (i = 0; i < [g_taggedXMLSections count]; ++i)
        if (g_activeXMLTags[i])
        {
        tag = [g_taggedXMLSections objectAtIndex:i];
        if ([cleanline hasPrefix:tag])
        {   result = i;
            break;
        }
    }
    return result;
}

- (NSString *)xmlGetTitle: (NSString *)titleLine
{
    NSString *cleanline;
    NSRange titleRange, closeTitleRange;
    NSString *returnString = @"";
    
    cleanline = [titleLine stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    if ([cleanline hasPrefix:@"<title>"])
    {
        titleRange.location = 7;
        titleRange.length = [cleanline length] - 7;
        cleanline = [cleanline substringWithRange: titleRange];
        if ([cleanline length] > 0)
        {
            closeTitleRange = [cleanline rangeOfString:@"</title>"];
            if (closeTitleRange.location != NSNotFound)
            {
                titleRange.location = 0;
                titleRange.length = closeTitleRange.location;
                cleanline = [cleanline substringWithRange: titleRange];
                if ([cleanline length] > 0)
                    returnString = cleanline;
            }
        }
   }
    else if ([cleanline hasPrefix:@"<caption>"])
    {
        titleRange.location = 9;
        titleRange.length = [cleanline length] - 9;
        cleanline = [cleanline substringWithRange: titleRange];
        if ([cleanline length] > 0)
        {
            closeTitleRange = [cleanline rangeOfString:@"</caption>"];
            if (closeTitleRange.location != NSNotFound)
            {
                titleRange.location = 0;
                titleRange.length = closeTitleRange.location;
                cleanline = [cleanline substringWithRange: titleRange];
                if ([cleanline length] > 0)
                    returnString = cleanline;
            }
        }
    }
    
    else if ([cleanline hasPrefix:@"<p>"])
    {
        titleRange.location = 3;
        titleRange.length = [cleanline length] - 3;
        cleanline = [cleanline substringWithRange: titleRange];
        if ([cleanline length] > 0)
        {
            closeTitleRange = [cleanline rangeOfString:@"</p>"];
            if (closeTitleRange.location != NSNotFound)
            {
                titleRange.location = 0;
                titleRange.length = closeTitleRange.location;
                cleanline = [cleanline substringWithRange: titleRange];
                if ([cleanline length] > 0)
                    returnString = cleanline;
            }
        }
    }
    
    else
        xmlNoParameter = true;
        
    
return returnString;
}

- (NSString *)xmlGetImageSource: (NSString *)titleLine
{
    NSString *cleanline;
    NSRange titleRange, closeTitleRange;
    NSString *firstSearch, *secondSearch;
    NSString *returnString = @"";
    
    cleanline = [titleLine stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    
    firstSearch = @"<image source=\"";
    if ([cleanline hasPrefix:firstSearch])
    {
        titleRange.location = 15;
        titleRange.length = [cleanline length] - 15;
        cleanline = [cleanline substringWithRange: titleRange];
        if ([cleanline length] > 0)
        {
            secondSearch = @"\"";
            closeTitleRange = [cleanline rangeOfString:secondSearch];
            if (closeTitleRange.location != NSNotFound)
            {
                titleRange.location = 0;
                titleRange.length = closeTitleRange.location;
                cleanline = [cleanline substringWithRange: titleRange];
                if ([cleanline length] > 0)
                {
                    returnString = cleanline;
                }
             
            }
        }
    }
         return returnString;
}
        
 - (IBAction) toggleXML: sender
{
    
    NSMenuItem *theItem;
    theItem = sender;
    if (theItem.state == YES)
    {
        self.fileIsXML = NO;
        theItem.state = NO;
    }
    else
    {
        self.fileIsXML = YES;
        theItem.state = YES;
    }
    [self colorizeVisibleAreaInTextView:textView1];
    [self colorizeVisibleAreaInTextView:textView2];
    
    if (self.fileIsXML)
    {
        if (! [[GlobalData sharedGlobalData].CommandCompletionPath isEqualToString: CommandCompletionPathXML])
        {
            [GlobalData sharedGlobalData].CommandCompletionPath = CommandCompletionPathXML;
            [(TSAppDelegate *)[[NSApplication sharedApplication] delegate] reReadCommandCompletionData];
        }
        
    }
    else
    {
        if (! [[GlobalData sharedGlobalData].CommandCompletionPath isEqualToString: CommandCompletionPathRegular])
        {
            [GlobalData sharedGlobalData].CommandCompletionPath = CommandCompletionPathRegular;
            [(TSAppDelegate *)[[NSApplication sharedApplication] delegate] reReadCommandCompletionData];
        }
    }


}

@end
