#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "TSConstants.h"

@interface TSMedia : NSObject 
    {
    NSString* path;
    NSString* name;
	NSString* newName;
	NSDictionary* meta;
	
	NSDate* creationDate;
	NSDate* modificationDate;
	NSDate* exifDate;
	NSNumber* fileSize;
	
	NSString* thumbnailName;
	
    NSImage* sourceImage;
	NSImage* fastImage;
	NSImage* thumbnail;
    QTMovie* movie;
	NSImage* typeBadge;
	NSImage* infoBadge;
    
    BOOL loaded;
    }

+(TSMedia*) initWithPath:(NSString*)p name:(NSString*)n;

-(BOOL) isLoaded;
-(void) loadData;
-(NSImage *) getOrientedImage:(NSImage *)image;
-(NSImage *) rotateRight:(NSImage *)image;
-(NSImage *) rotateLeft:(NSImage *)image;
-(void) addThumbnailInfo:(TSMedia*)item;


- (void)doRenameToDirectory:destinationPath withIndex:(int)index andMaxCount:(int)maxCount;


// type info
-(BOOL) isMovie;
-(BOOL) isImage;
-(int) getMediaType;
-(NSImage*) typeBadge;


// image accessors
-(NSImage*) image;
-(NSImage*) fastImage;
-(NSImage*) thumbnail;
-(QTMovie*) movie;


// name and attribute accessors
-(NSString*) path;
-(void) setPath:(NSString*)str;
-(NSString*) name;
-(void) setName:(NSString*)str;
-(NSString*) newName;
-(void) setNewName:(NSString*)str;

// read only attributes
-(NSString*) fullPath;
-(NSString*) baseName;
-(NSString*) extension;
-(NSString*) displayName;
-(NSString*) displayNameWithNoPrefix;
-(NSDate *) creationDate;
-(NSDate *) modificationDate;
-(NSNumber *) fileSize;
-(NSString *) fileSizeAsString;
-(NSDate *) date;
-(NSDictionary *)metadata;

// sorting methods
-(NSComparisonResult) compareByTime:(TSMedia*)other;
-(NSComparisonResult) compareByName:(TSMedia*)other;

@end
