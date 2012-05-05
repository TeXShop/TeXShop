#import "TeXTextView.h"
#import "TeXLayoutManager.h"

@implementation TeXTextView
- (void)awakeFromNib
{
	texshopPlistPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/TeXShop.plist"] retain];
	NSDictionary* texshopSettings = nil;
	if ([[NSFileManager defaultManager] fileExistsAtPath:texshopPlistPath]) {
		texshopSettings = [NSDictionary dictionaryWithContentsOfFile:texshopPlistPath];
	}
	
	if (texshopSettings && [[texshopSettings objectForKey:@"Encoding"] isEqualToString:@"MacJapanese"])
		texChar = YEN;
	else
		texChar = BACKSLASH;
	
	
	unichar esc = 0x001B;
	unichar tab = 0x0009;
	
	if (texshopSettings && [[texshopSettings objectForKey:@"CommandCompletionChar"] isEqualToString:@"ESCAPE"]) 
		g_commandCompletionChar = [[NSString stringWithCharacters: &esc length: 1] retain];
	else
		g_commandCompletionChar = [[NSString stringWithCharacters: &tab length: 1] retain];
	
	lastCursorLocation = 0;
	lastStringLength = 0;
	TeXLayoutManager *layoutManager = [[TeXLayoutManager alloc] init];
	[[self textContainer] replaceLayoutManager:layoutManager];
    
    NSData *fontData = nil;
    if (texshopSettings && (fontData = [texshopSettings objectForKey:@"DocumentFont"])) {
        [self setFont:[NSUnarchiver unarchiveObjectWithData:fontData]];
    }
    
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChangeSelection:) name:NSTextViewDidChangeSelectionNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:NSTextDidEndEditingNotification object:self];
	[self colorizeText:YES];
	coloringNow = NO;

	NSString* autoCompletionPath = [@"~/Library/TeXShop/Keyboard/autocompletion.plist" stringByStandardizingPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath: autoCompletionPath]){
		autocompletionDictionary = [[NSDictionary dictionaryWithContentsOfFile:autoCompletionPath] retain];
	}else {
		autocompletionDictionary = nil;
	}

	// CommandComepletion.txt のロード
	NSData 	*myData = nil;
	
	NSString *completionPath = [@"~/Library/TeXShop/CommandCompletion/CommandCompletion.txt" stringByStandardizingPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath: completionPath])
		myData = [NSData dataWithContentsOfFile:completionPath];
	
	if(myData)
	{
		NSStringEncoding myEncoding = NSUTF8StringEncoding;
		g_commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: myEncoding];
		if (! g_commandCompletionList) {
			g_commandCompletionList = [[NSMutableString alloc] initWithData:myData encoding: myEncoding];
		}
		
		[g_commandCompletionList insertString: @"\n" atIndex: 0];
		if ([g_commandCompletionList characterAtIndex: [g_commandCompletionList length]-1] != '\n')
			[g_commandCompletionList appendString: @"\n"];
	}
}

- (void) setAutoCompleting:(BOOL)flag 
{
	autoCompleting = flag;
}

- (void)registerUndoWithString:(NSString *)oldString location:(unsigned)oldLocation
						length: (unsigned)newLength key:(NSString *)key
{
	NSUndoManager	*myManager;
	NSMutableDictionary	*myDictionary;
	NSNumber		*theLocation, *theLength;
	
	// Create & register an undo action
	myManager = [self undoManager];
	myDictionary = [NSMutableDictionary dictionaryWithCapacity: 4];
	theLocation = [NSNumber numberWithUnsignedInt: oldLocation];
	theLength = [NSNumber numberWithUnsignedInt: newLength];
	[myDictionary setObject: oldString forKey: @"oldString"];
	[myDictionary setObject: theLocation forKey: @"oldLocation"];
	[myDictionary setObject: theLength forKey: @"oldLength"];
	[myDictionary setObject: key forKey: @"undoKey"];
	[myManager registerUndoWithTarget:self selector:@selector(undoSpecial:) object: myDictionary];
	[myManager setActionName:key];
}

- (void)undoSpecial:(id)theDictionary
{
	NSRange		undoRange;
	NSString	*oldString, *newString, *undoKey;
	unsigned	from, to;
	
	// Retrieve undo info
	undoRange.location = [[theDictionary objectForKey: @"oldLocation"] unsignedIntValue];
	undoRange.length = [[theDictionary objectForKey: @"oldLength"] unsignedIntValue];
	newString = [theDictionary objectForKey: @"oldString"];
	undoKey = [theDictionary objectForKey: @"undoKey"];
	
	if (undoRange.location+undoRange.length > [[self string] length])
		return; // something wrong happened
	
	oldString = [[self string] substringWithRange: undoRange];
	
	// Replace the text
	[self replaceCharactersInRange:undoRange withString:newString];
	[self registerUndoWithString:oldString location:undoRange.location
						  length:[newString length] key:undoKey];
	
	from = undoRange.location;
	to = from + [newString length];
	[self colorizeText:YES];
}


// to be used in AutoCompletion
- (void)insertSpecialNonStandard:(NSString *)theString undoKey:(NSString *)key
{
	NSRange		oldRange, searchRange;
	NSMutableString	*stringBuf;
	NSString *oldString, *newString;
	unsigned from, to;
	
	// mutably copy the replacement text
	stringBuf = [NSMutableString stringWithString: theString];
	
	// Determine the curent selection range and text
	oldRange = [self selectedRange];
	oldString = [[self string] substringWithRange: oldRange];
	
	// Substitute all occurances of #SEL# with the original text
	[stringBuf replaceOccurrencesOfString: @"#SEL#" withString: oldString
								  options: 0 range: NSMakeRange(0, [stringBuf length])];
	
	// Now search for #INS#, remember its position, and remove it. We will
	// Later position the insertion mark there. Defaults to end of string.
	searchRange = [stringBuf rangeOfString:@"#INS#" options:NSLiteralSearch];
	if (searchRange.location != NSNotFound)
		[stringBuf replaceCharactersInRange:searchRange withString:@""];
	
	// Filtering for Japanese
	//newString = [self filterBackslashes:stringBuf];
	newString = stringBuf;
	
	// Insert the new text
	[self replaceCharactersInRange:oldRange withString:newString];
	
	// register undo
	[self registerUndoWithString:oldString location:oldRange.location
						  length:[newString length] key:key];
	//[textView registerUndoWithString:oldString location:oldRange.location
	//					length:[newString length] key:key];
	
	from = oldRange.location;
	to = from + [newString length];
	[self colorizeText:YES];
	
	// Place insertion mark
	if (searchRange.location != NSNotFound) {
		searchRange.location += oldRange.location;
		searchRange.length = 0;
		[self setSelectedRange:searchRange];
	}
}

- (void)insertText:(id)aString
{
	NSDictionary* texshopSettings = [NSDictionary dictionaryWithContentsOfFile:texshopPlistPath];
	
	if ([aString length] == 1 && texshopSettings && [[texshopSettings objectForKey:@"AutoCompleteEnabled"] boolValue] && autocompletionDictionary) {
		if ([aString characterAtIndex:0] >= 128 ||
			[self selectedRange].location == 0 ||
			[[self string] characterAtIndex:[self selectedRange].location - 1 ] != texChar )
		{
			NSString *completionString = [autocompletionDictionary objectForKey:aString];
			if ( completionString )
			{
				[self setAutoCompleting:YES];
				[self insertSpecialNonStandard:completionString
									   undoKey: @"Autocompletion"];
				[self setAutoCompleting:NO];
				return;
			}
		}
	}	
	
	// Filtering for Japanese
	if([aString isEqualToString:@"¥"])
	{
		[super insertText:@"\\"];
	}
	else
	{
		[super insertText:aString];
	}
	[self colorizeText:YES];
}


- (BOOL)readSelectionFromPasteboard:(NSPasteboard*)pboard type:(NSString*)type
{
	if([type isEqualToString:NSStringPboardType])
	{
		NSMutableString *string = [NSMutableString stringWithString:[pboard stringForType:NSStringPboardType]];
		if (string)
		{
			// Replace the text--imitate what happens in ordinary editing
			NSRange	selectedRange = [self selectedRange];
			if ([self shouldChangeTextInRange:selectedRange replacementString:string])
			{
				[self replaceCharactersInRange:selectedRange withString:string];
				[self didChangeText];
			}
			// by returning YES, "Undo Paste" menu item will be set up by system
			[self colorizeText:YES];
			return YES;
		}
		else
		{
			return NO;
		}
	}
	return [super readSelectionFromPasteboard:pboard type:type];
}
@end
