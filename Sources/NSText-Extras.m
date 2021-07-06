#import "NSText-Extras.h"

@implementation NSText (Extras)
- (void)setFontSafely:(NSFont *)aFont;
{
    if(aFont){
        if([[[NSFontManager sharedFontManager] availableFonts] containsObject:[aFont fontName]])
            [self setFont:aFont];
        else
          //  NSLog(@"Font %@ is missing.", [aFont fontName]);
            ;
    }
    else
      //  NSLog(@"The font is nil!");
        ;

}
@end
