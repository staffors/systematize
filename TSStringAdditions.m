#import "TSStringAdditions.h"


@implementation NSString (TSStringAdditions)


-(NSString*) trim;
	{ 
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	
	
@end
