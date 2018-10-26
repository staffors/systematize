#import "TSDictionaryAdditions.h"


@implementation NSDictionary (TSDictionaryAdditions)


-(NSString *)asPlainStringWithPrefix:(NSString *)prefix;
	{
	NSMutableString* str = [[[NSMutableString alloc] init] autorelease];
	NSUInteger i;
	NSArray* keys = [self allKeys];
    for (i=0; i<[keys count]; i++)
		{
        NSString* key = keys[i];
        id value = self[key];

        if ([value isKindOfClass:[NSDictionary class]])
			{
			[str appendString:prefix];
			[str appendString:key];
			[str appendString:@"\n"];
			[str appendString:[value asPlainStringWithPrefix:[NSString stringWithFormat:@"%@    ", prefix]]];
			}
		else if ([value isKindOfClass:[NSNumber class]])
			{
			[str appendString:prefix];
			[str appendString:key];
			[str appendString:@"="];
			[str appendString:[value stringValue]];
			[str appendString:@"\n"];
			}
		else if ([value isKindOfClass:[NSString class]])
			{
			[str appendString:prefix];
			[str appendString:key];
			[str appendString:@"="];
			[str appendString:value];
			[str appendString:@"\n"];
			}
		else if ([value isKindOfClass:[NSArray class]])
			{
			[str appendString:prefix];
			[str appendString:key];
			[str appendString:@"\n"];
			NSUInteger j;
			for (j=0; j<[value count]; j++)
				{
				[str appendString:prefix];
				[str appendString:@"    "];
				id subValue = (id) [value objectAtIndex:j];
				if ([subValue isKindOfClass:[NSNumber class]])
					{
					[str appendString:[subValue stringValue]];
					}
				else
					{
					[str appendString:subValue];
					}
				[str appendString:@"\n"];
				}
			}
		else
			{
			[str appendString:prefix];
			[str appendString:key];
			[str appendString:@"="];
			[str appendString:[value stringValue]];
			[str appendString:@"\n"];
			}
		}
    return str;
	}
@end
