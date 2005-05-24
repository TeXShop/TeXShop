//
//  EncodingSupport.h
//
//  Created by Mitsuhiro Shishikura on Fri Dec 13 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// #define filterNone	0	// others
// #define filterMacJ	1	// MacJapanese
// #define filterNSSJIS	2	// NSShiftJIS & EUCJapanese & JISJapanese

@interface EncodingSupport : NSObject {

}

+ (id)sharedInstance;

//- (void)controlTextDidChange:(NSNotification *)note;
// Delegate method for TextField; not necessary to declare here

- (void)setupForEncoding;
- (void)encodingChanged: (NSNotification *)note;
- (IBAction)toggleTeXCharConversion:(id)sender;
- (int)tagForEncodingPreference;
- (int)tagForEncoding: (NSString *)encoding;
- (NSString *)encodingForTag: (int)tag;
- (NSStringEncoding)stringEncodingForTag: (int)encoding;
- (BOOL)ptexUtfOutputCheck: (NSString *)dataString withEncoding: (int)tag;  // zenitani 1.35 (C)
- (NSData *)ptexUtfOutput: (NSTextView *)dataView withEncoding: (int)tag;   // zenitani 1.35 (C)
@end

NSMutableString *filterBackslashToYen(NSString *aString);
NSMutableString *filterYenToBackslash(NSString *aString);

