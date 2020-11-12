/*!
    @header GetMetadataForFile.c
    @abstract   (Metadata Importer for TeX related user files)
    @discussion (Author(s): Norm Gall)
*/

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#include <Foundation/Foundation.h>

Boolean GetMetadataForFile(void* thisInterface,
    CFMutableDictionaryRef attributes,
    CFStringRef contentTypeUTI,
    CFStringRef pathToFile)

{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; //  we need an autorelease pool
    
    NSStringEncoding enc;
    
    /*
     As of 10.5, this method will at least
     - check com.apple.TextEncoding xattr
     - try UTF-8
     */
    NSString *str = [[NSString alloc] initWithContentsOfFile:(NSString *)pathToFile usedEncoding:&enc error:NULL];
	
    // try MacRoman as the fallback, since it's a gapless encoding
    if(str == nil)
        str = [[NSString alloc] initWithContentsOfFile:(NSString *)pathToFile encoding:NSMacOSRomanStringEncoding error:NULL];

    // !!! early return on failure to load the file
    if(str == nil){
        [pool release];
        return FALSE;
    }

    // check MDItem.h for the appropriate constant
    [(NSMutableDictionary *)attributes setObject:str forKey:(NSString *)kMDItemTextContent];

    // insert cool scanner code here
	NSScanner *scanner = [[NSScanner alloc] initWithString:str];
	
	NSString *tmp = nil;
    
#define AUTHOR_TOKEN @"\\author{"
#define TITLE_TOKEN  @"\\title{"
#define END_TOKEN    @"}\n"
    
	// find author tag
	if ([scanner scanUpToString:AUTHOR_TOKEN intoString:NULL]) {
		[scanner scanString:AUTHOR_TOKEN intoString:NULL]; // skip over the start tag we found
		[scanner scanUpToString:END_TOKEN intoString:&tmp]; // then scan up to the end tag in the result
		// see if the end tag actually exists, if so store, if not start next scan
		if ([scanner scanString:END_TOKEN intoString:NULL] && tmp)
			[(NSMutableDictionary *)attributes setObject:[tmp componentsSeparatedByString:@" \\and "]
                                                  forKey:(NSArray *)kMDItemAuthors];
	}
	
	// restart scan for next tag
	[scanner setScanLocation:0];
	tmp = nil;
	
	// find title tag
	if ([scanner scanUpToString:TITLE_TOKEN intoString:NULL]) {
		[scanner scanString:TITLE_TOKEN intoString:NULL]; // skip over the start tag we found
		[scanner scanUpToString:END_TOKEN intoString:&tmp]; // then scan up to the end tag in the result
		// see if the end tag actually exists, if so store, if not start next scan
		if ([scanner scanString:END_TOKEN intoString:NULL] && tmp)
			[(NSMutableDictionary *)attributes setObject:tmp
                                                  forKey:(NSString *)kMDItemTitle];
	}
	
	[str release]; // don't forget this next time
	[scanner release];
	// end cool scanner code
	
    [pool release]; // everyone out of the pool

    return TRUE;
}