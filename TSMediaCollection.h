#import <Foundation/Foundation.h>

@class TSMedia;

@interface TSMediaCollection : NSObject 
    {
    NSString* rootPath;
    NSMutableArray* mediaList;
	NSMutableArray* imageList;
	NSMutableArray* fastImageList;
    }


- (void)setCurrentDirectory:(NSString*)name;
- (NSString *)currentDirectory;
- (void)filterForMoviesWithThumbnailImages;

- (unsigned)size;
- (void)addObject:(TSMedia*)item;
- (TSMedia *)objectAtIndex:(unsigned)index;
- (void)removeObjectAtIndex:(unsigned)index;
- (void)insertObject:(TSMedia*)mediaItem atIndex:(unsigned)index;
- (void)sortByTime;
- (void)sortByName;

@end


