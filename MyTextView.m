#import "MyTextView.h"

// added by mitsu --(A) TeXChar filtering
#import "EncodingSupport.h"
#import "globals.h"

#define SUD [NSUserDefaults standardUserDefaults]

// end addition

@implementation MyTextView


- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
{
    NSRange	replacementRange;
    NSString	*textString;
    int		length, i, j;
    BOOL	done;
    int		leftpar, rightpar, count, uchar;

    replacementRange = [super selectionRangeForProposedRange: proposedSelRange granularity: granularity];
    if ((proposedSelRange.length != 0) || (granularity != 2)) 
        return replacementRange;
    textString = [self string];
    if (textString == nil) return replacementRange;
    length = [textString length];
    i = proposedSelRange.location;
    if (i >= length) return replacementRange;
    rightpar = [textString characterAtIndex: i];
    
    if ((rightpar == 0x007D) || (rightpar == 0x0029) || (rightpar == 0x005D)) {
           j = i;
            if (rightpar == 0x007D) 
                leftpar = 0x007B;
            else if (rightpar == 0x0029) 
                leftpar = 0x0028;
            else 
                leftpar = 0x005B;
            count = 1;
            done = NO;
            while ((i > 0) && (! done)) {
                i--;
                uchar = [textString characterAtIndex:i];
                if (uchar == rightpar)
                    count++;
                else if (uchar == leftpar)
                    count--;
                if (count == 0) {
                    done = YES;
                    replacementRange.location = i;
                    replacementRange.length = j - i + 1;
                    return replacementRange;
                    }
                }
            return replacementRange;
            }
            
    else if ((rightpar == 0x007B) || (rightpar == 0x0028) || (rightpar == 0x005B)) {
            j = i;
            leftpar = rightpar;
            if (leftpar == 0x007B) 
                rightpar = 0x007D;
            else if (leftpar == 0x0028) 
                rightpar = 0x0029;
            else 
                rightpar = 0x005D;
            count = 1;
            done = NO;
            while ((i < (length - 1)) && (! done)) {
                i++;
                uchar = [textString characterAtIndex:i];
                if (uchar == leftpar)
                    count++;
                else if (uchar == rightpar)
                    count--;
                if (count == 0) {
                    done = YES;
                    replacementRange.location = j;
                    replacementRange.length = i - j + 1;
                    return replacementRange;
                    }
                }
            return replacementRange;
            }

    else return replacementRange;
}

// added by mitsu --(A) TeXChar filtering
- (void)insertText:(id)aString
{
	if (shouldFilter == filterMacJ)
	{
		aString = filterBackslashToYen(aString);
	}
	else if (shouldFilter == filterNSSJIS)
	{
		aString = filterYenToBackslash(aString);
	}
	[super insertText: aString];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
	NSMutableString *newString;
	
	BOOL returnValue = [super writeSelectionToPasteboard:pboard type:type];
	if ((shouldFilter == filterMacJ) && returnValue && 
			[SUD boolForKey:@"ConvertToBackslash"] && [type isEqualToString: NSStringPboardType])
	{
		newString = filterYenToBackslash([pboard stringForType: NSStringPboardType]);
		returnValue = [pboard setString: newString forType: NSStringPboardType];
	}
	else if ((shouldFilter == filterNSSJIS) && returnValue && 
			[SUD boolForKey:@"ConvertToYen"] && [type isEqualToString: NSStringPboardType])
	{
		newString = filterBackslashToYen([pboard stringForType: NSStringPboardType]);
		returnValue = [pboard setString: newString forType: NSStringPboardType];
	}
	return returnValue;
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
	if(shouldFilter && [type isEqualToString: NSStringPboardType])
	{
		NSString *string = [pboard stringForType: NSStringPboardType];
		if (string)
		{
			[self insertText: string];
			return YES; 
		}
		else
			return NO; 
	}
	return [super readSelectionFromPasteboard: pboard type: type];
}

// end addition

        
@end
