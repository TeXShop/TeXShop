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

    // get the entire contents of the file
    NSData *data = [NSData dataWithContentsOfFile:(NSString *)pathToFile];
	
	if (data == nil) {
		// if we failed to read the file, abort
        [pool release]; // everyone out of the pool
		return FALSE;
	}

    // guess the encoding is UTF-8
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    if(str == nil){
        // bad encoding choice
        str = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
	}
	
    if(str == nil){
        // bad encoding choice
        str = [[NSString alloc] initWithData:data encoding:NSMacOSRomanStringEncoding]; 
    }

    if(str == nil){
        // catastrophic failure; run like hell
        [pool release]; // everyone out of the pool
        return FALSE;
    }

    // check MDItem.h for the appropriate constant
    [(NSMutableDictionary *)attributes setObject:str forKey:(NSString *)kMDItemTextContent];

    // insert cool scanner code here
	NSScanner *scanner = [[NSScanner alloc] initWithString:str];
	
	NSString *tmp = nil;
	NSString *authorTag = @"\\author{";
	NSString *titleTag = @"\\title{";
	NSString *endTag = @"}\n";

	// find author tag
	if ([scanner scanUpToString:authorTag intoString:nil]) {
		[scanner scanString:authorTag intoString:nil]; // skip over the start tag we found
		[scanner scanUpToString:endTag intoString:&tmp]; // then scan up to the end tag in the result
		// see if the end tag actually exists, if so store, if not start next scan
		if ([scanner scanString:endTag intoString:nil])
			if(tmp) [(NSMutableDictionary *)attributes setObject:[tmp componentsSeparatedByString:@" \\and "] forKey:(NSArray *)kMDItemAuthors];
	}
	
	// restart scan for next tag
	[scanner setScanLocation:0];
	tmp = nil;
	
	// find title tag
	if ([scanner scanUpToString:titleTag intoString:nil]) {
		[scanner scanString:titleTag intoString:nil]; // skip over the start tag we found
		[scanner scanUpToString:endTag intoString:&tmp]; // then scan up to the end tag in the result
		// see if the end tag actually exists, if so store, if not start next scan
		if ([scanner scanString:endTag intoString:nil])
			if(tmp) [(NSMutableDictionary *)attributes setObject:tmp forKey:(NSString *)kMDItemTitle];	
	}
	
	[str release]; // don't forget this next time
	[scanner release];
	// end cool scanner code
	
    [pool release]; // everyone out of the pool

    return TRUE;
}