#import "TSMediaCollection.h"
#import "TSMedia.h"

@implementation TSMediaCollection

-(id) init 
    {
	if (![super init])
		return nil;
    mediaList = [[NSMutableArray alloc] initWithCapacity:50];
    return self;
    }
    
    
    


- (void)setCurrentDirectory:(NSURL*)path;
    {
	if (rootPath)
        {
        [rootPath release];
        }
    rootPath = [path retain];
	if (mediaList)
		{
		[mediaList release];
		}
    mediaList = [[NSMutableArray alloc] initWithCapacity:50];
    }
	
	
    
- (NSURL *)currentDirectory;
	{
	return [[rootPath retain] autorelease];
	}



    
    
- (void)filterForMoviesWithThumbnailImages;
	{
	NSLog(@"filterForMoviesWithThumbnailImages");

	NSMutableIndexSet *indexesToDelete = [[[NSMutableIndexSet alloc] init] autorelease];
	NSUInteger i;
	for (i=0; i<[mediaList count]; i++)
		{
		TSMedia* movie = mediaList[i];
		if ([movie isMovie])
			{
			NSUInteger j;
			for (j=0; j<[mediaList count]; j++)
				{
				// if we're not looking at the same item as the movie, then see if it has the same basename
				if (j != i)
					{
					TSMedia* item = mediaList[j];
					if ([[movie baseName] caseInsensitiveCompare:[item baseName]] == NSOrderedSame)
						{
						// we found a match so remember its index and add its info to the movie item
						NSLog(@" - adding thumbnail from index %tu for movie %tu", j, i);
						[movie addThumbnailInfo:item];
						[indexesToDelete addIndex:j];
						}
					}
				}
			}
		}
	NSLog(@" - found %d matches", (int) [indexesToDelete count]);
	// iterate down through the indexesToDelete, removing them as we go
	unsigned long index = [indexesToDelete lastIndex];
	while (index != NSNotFound)
		{
		[mediaList removeObjectAtIndex:index];
		index = [indexesToDelete indexLessThanIndex:index];
		}
	}

	
	




- (unsigned long)size;
	{
	return [mediaList count];
	}
	
	
- (void)addObject:(TSMedia*)item;
	{
	[mediaList addObject:item];
	}
	
	
- (TSMedia *)objectAtIndex:(unsigned long)index;
	{
	return mediaList[index];
	}

- (void)removeObjectAtIndex:(unsigned long)index;
	{
	[mediaList removeObjectAtIndex:index];
	}
	
- (void)insertObject:(TSMedia*)mediaItem atIndex:(unsigned long)index;
	{
	[mediaList insertObject:mediaItem atIndex:index];
	}
	
- (void)sortByTime;
	{
	[mediaList sortUsingSelector:@selector(compareByTime:)];
	}

- (void)sortByName;
	{
	[mediaList sortUsingSelector:@selector(compareByName:)];
	}
@end
