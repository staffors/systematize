@import Foundation;
@import Cocoa;
@import AVFoundation;
@import AppKit;
@import CoreMedia;
#import "TSConstants.h"

@interface TSMedia : NSObject 
    {
    NSURL* path;
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
    AVURLAsset* movie;
	NSImage* typeBadge;
	NSImage* infoBadge;
    
    BOOL loaded;
    }

+(TSMedia*) initWithPath:(NSURL*)p name:(NSString*)n;

-(BOOL) isLoaded;
-(void) loadData;
-(NSImage *) getOrientedImage:(NSImage *)image;
-(NSImage *) rotateRight:(NSImage *)image;
-(NSImage *) rotateLeft:(NSImage *)image;
-(void) addThumbnailInfo:(TSMedia*)item;


- (void)doRenameToDirectory:(NSURL*)destinationPath withIndex:(int)index andMaxCount:(int)maxCount;


// type info
-(BOOL) isMovie;
-(BOOL) isImage;
-(int) getMediaType;
-(NSImage*) typeBadge;


// image accessors
-(NSImage*) image;
-(NSImage*) fastImage;
-(NSImage*) thumbnail;
-(AVURLAsset*) movie;


// name and attribute accessors
-(NSURL*) path;
-(void) setPath:(NSURL*)str;
-(NSString*) name;
-(void) setName:(NSString*)str;
-(NSString*) newName;
-(void) setNewName:(NSString*)str;

// read only attributes
-(NSURL*) fullPath;
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
