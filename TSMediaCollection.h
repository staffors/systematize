#import <Foundation/Foundation.h>

@class TSMedia;

@interface TSMediaCollection : NSObject 
    {
    NSURL* rootPath;
    NSMutableArray* mediaList;
	NSMutableArray* imageList;
	NSMutableArray* fastImageList;
    }


- (void)setCurrentDirectory:(NSURL*)path;
- (NSURL *)currentDirectory;
- (void)filterForMoviesWithThumbnailImages;

- (unsigned long)size;
- (void)addObject:(TSMedia*)item;
- (TSMedia *)objectAtIndex:(unsigned long)index;
- (void)removeObjectAtIndex:(unsigned long)index;
- (void)insertObject:(TSMedia*)mediaItem atIndex:(unsigned long)index;
- (void)sortByTime;
- (void)sortByName;

@end


