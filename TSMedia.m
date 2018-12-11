#import "TSMedia.h"
#import "TSImageAdditions.h"
#import "TSStringAdditions.h"

@implementation TSMedia


+(TSMedia*) initWithPath:(NSURL*)p name:(NSString*)n
    {
    TSMedia* photo = [[[TSMedia alloc] init] autorelease];
    [photo setPath:p];
    [photo setName:n];
    return photo;
    }



-(id) init
    {
    self = [super init];
    loaded = NO;
    return self;
    }



-(void) dealloc
    {
    if (sourceImage)
        {
        [sourceImage release];
        }
    if (movie)
        {
        [movie release];
        }
    [fastImage release];
    [thumbnail release];
    [path release];
    [name release];
    [super dealloc];
    }




-(BOOL) isLoaded;
    {
    return loaded;
    }




-(void) loadData;
    {
    if (!loaded)
        {
        NSLog(@" - loading %@", [self name]);

        // load attributes
        NSFileManager* fileManager = [NSFileManager defaultManager];
        NSDictionary* fileAttributes = [fileManager attributesOfItemAtPath:[[self fullPath] absoluteString] error:nil];
        creationDate = [[fileAttributes fileCreationDate] retain];
        modificationDate = [[fileAttributes fileModificationDate] retain];
        fileSize = [fileAttributes fileSize];

        if ([self isImage])
            {
            [self loadImageData];
            }
        else
            {
            [self loadMovieData];
            }
        loaded = YES;
        }
    }




- (void) loadImageData
    {
    // use ImageIO to get a CGImageRef for a file at a given path which we can use to load exif data
    NSURL * url = [self fullPath];
    NSDictionary* options = @{
            (id) kCGImageSourceShouldCache: (id) kCFBooleanTrue,
            (id) kCGImageSourceShouldAllowFloat: (id) kCFBooleanTrue
    };
    CGImageSourceRef sourceRef = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    meta = (NSDictionary*)CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, (CFDictionaryRef)options);
    [meta retain];

    /*
    NSLog(@"Meta information for file: %@", [self fullPath]);
    NSEnumerator *enumerator = [meta keyEnumerator];
    id key;
    while ((key = [enumerator nextObject]))
        {
        NSLog(@"%@=%@", key, [meta objectForKey:key]);
        }
    */


    //Could we use CoreGraphics to load the thumbnail and would it be faster?
    NSDictionary* thumbOpts = @{
            (id) kCGImageSourceCreateThumbnailWithTransform: (id) kCFBooleanTrue,
            (id) kCGImageSourceCreateThumbnailFromImageAlways: (id) kCFBooleanTrue,
            (id) kCGImageSourceThumbnailMaxPixelSize: @512
    };
    CGImageRef cgImageRef = CGImageSourceCreateThumbnailAtIndex(sourceRef, 0, (CFDictionaryRef)thumbOpts);

    // make image thumbnail
    CIImage *ciImage = [CIImage imageWithCGImage:cgImageRef];
    CGRect extent = [ciImage extent];
    //Be careful here.  A CIImage can have infinite extent.  The following is OK only if you know your CIImage is of finite extent.
    thumbnail = [[NSImage alloc] initWithSize:NSMakeSize(extent.size.width, extent.size.height)];
    NSCIImageRep *ciImageRep = [NSCIImageRep imageRepWithCIImage:ciImage];
    [thumbnail addRepresentation:ciImageRep];

    CFRelease(sourceRef);


    // now load the image and generate scaled versions
    //sourceImage = [[NSImage alloc] initWithContentsOfFile:[self fullPath]];
    //fastImage = [[self getOrientedImage:[sourceImage imageScaledToMaxDimension:800]] retain];
    //thumbnail = [[fastImage imageScaledToMaxDimension:200] retain];
    //thumbnail = [[self getOrientedImage:[sourceImage imageScaledToMaxDimension:200]] retain];
    fastImage = [thumbnail retain];
    }




- (void) loadMovieData
    {
    NSLog(@"Loading movie data");
    NSURL * url = [self fullPath];
    self->movie = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator* imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:self->movie];
    [self->movie loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:
            ^
                {
                NSError *loadingError = nil;
                if ([self->movie statusOfValueForKey:@"tracks" error:&loadingError] != AVKeyValueStatusLoaded)
                    {
                    NSLog(@"failed to load movie description: %@", [loadingError localizedDescription]);
                    NSLog(@"failed to load movie reason: %@", [loadingError localizedFailureReason]);
                    return;
                    }

                NSArray *visualTracks = [self->movie tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
                if ([visualTracks count] > 0)
                    {
                    NSLog(@"Found more than one visualTrack");
                    // Grab the first frame from the asset and display it
                    [imageGenerator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:kCMTimeZero]] completionHandler:
                            ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error)
                                {
                                if (result == AVAssetImageGeneratorSucceeded)
                                    {
                                    NSLog(@"using iniTWithCGImage");
                                    self->fastImage = [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
                                    }
                                else
                                    {
                                    NSLog(@"error loading 2x");
                                    self->fastImage = [NSImage imageNamed:@"ErrorLoading2x"];
                                    }
                                }];
                    }
                else if ([[self->movie tracksWithMediaCharacteristic:AVMediaCharacteristicAudible] count] > 0)
                    {
                    NSLog(@"audio only 2x");
                    self->fastImage = [NSImage imageNamed:@"AudioOnly2x"];
                    }
                else
                    {
                    NSLog(@"error loading 2x timestwo");
                    self->fastImage = [NSImage imageNamed:@"ErrorLoading2x"];
                    }
                NSLog(@"retain on fastImage");
                self->thumbnail = [self->fastImage retain];
                }];

    }





-(NSImage *) getOrientedImage:(NSImage *)image;
    {
    NSNumber* orientationNumber = meta[@"Orientation"];
    int orientation = 1;
    if (orientationNumber)
        {
        orientation = [orientationNumber intValue];
        if (orientation < 1 || orientation > 8)
            {
            orientation = 1;
            }
        }

    if (orientation == 6)
        {
        return [self rotateLeft:image];
        }
    else if (orientation == 8)
        {
        return [self rotateRight:image];
        }
    else
        {
        return image;
        }
    }




-(NSImage *) rotateRight:(NSImage *)image;
    {
    NSImage* tmpImage = [image copy];

    CGFloat width = [tmpImage size].width;
    CGFloat height = [tmpImage size].height;
    NSImage* targetImage = [[[NSImage alloc] initWithSize:[tmpImage size]] autorelease];
    [targetImage setSize:NSMakeSize(height, width)];

    [targetImage lockFocus];
    NSAffineTransform* rotationTransform = [NSAffineTransform transform];
    NSAffineTransform* locationTransform = [NSAffineTransform transform];
    NSAffineTransform* transform = [NSAffineTransform transform];
    [rotationTransform rotateByDegrees:-90];
    [locationTransform translateXBy:0 yBy:width];
    [transform appendTransform:rotationTransform];
    [transform appendTransform:locationTransform];
    [transform concat];
    [tmpImage drawAtPoint:NSMakePoint(0,0) fromRect:NSMakeRect(0,0,width,height) operation:NSCompositingOperationCopy fraction:1.0];
    [targetImage unlockFocus];

    [tmpImage release];
    [transform release];
    return targetImage;
    }




-(NSImage *) rotateLeft:(NSImage *)image;
    {
    NSImage* tmpImage = [image copy];

    CGFloat width = [tmpImage size].width;
    CGFloat height = [tmpImage size].height;
    NSImage* targetImage = [[[NSImage alloc] initWithSize:[tmpImage size]] autorelease];
    [targetImage setSize:NSMakeSize(height, width)];

    [targetImage lockFocus];
    NSAffineTransform* rotationTransform = [NSAffineTransform transform];
    NSAffineTransform* locationTransform = [NSAffineTransform transform];
    NSAffineTransform* transform = [NSAffineTransform transform];
    [rotationTransform rotateByDegrees:90];
    [locationTransform translateXBy:height yBy:0];
    [transform appendTransform:rotationTransform];
    [transform appendTransform:locationTransform];
    [transform concat];
    [tmpImage drawAtPoint:NSMakePoint(0,0) fromRect:NSMakeRect(0,0,width,height) operation:NSCompositingOperationCopy fraction:1.0];
    [targetImage unlockFocus];

    [tmpImage release];
    [transform release];
    return targetImage;
    }




-(void) addThumbnailInfo:(TSMedia*)item;
    {
    thumbnailName = [[item name] retain];
    [fastImage release];
    [thumbnail release];
    fastImage = [[item fastImage] retain];
    thumbnail = [[item thumbnail] retain];
    }







/*	
-(NSImage *) getTransformedImageForImage:(NSImage *)image withMetadata:(NSDictionary *)foo targetSize:(NSSize)targetSize;
	{
	float xdpi = targetSize.width;
    float ydpi = targetSize.height;
    int orientation = 1;
	NSNumber* orientationNumber = [foo objectForKey:@"Orientation"];
	if (orientationNumber)
		{
		orientation = [orientationNumber intValue];
		if (orientation < 1 || orientation > 8)
			{
			orientation = 1;
			}
		}
		
    float x = (ydpi>xdpi) ? ydpi/xdpi : 1;
    float y = (xdpi>ydpi) ? xdpi/ydpi : 1;
    float w = x * [image size].width;
    float h = y * [image size].height;

	NSAffineTransformStruct orientationTransforms[8] = {
        { x, 0, 0, y, 0, 0},  //  1 =  row 0 top, col 0 lhs  =  normal
        {-x, 0, 0, y, w, 0},  //  2 =  row 0 top, col 0 rhs  =  flip horizontal
        {-x, 0, 0,-y, w, h},  //  3 =  row 0 bot, col 0 rhs  =  rotate 180
        { x, 0, 0,-y, 0, h},  //  4 =  row 0 bot, col 0 lhs  =  flip vertical
        { 0,-x,-y, 0, h, w},  //  5 =  row 0 lhs, col 0 top  =  rot -90, flip vert
        { 0,-x, y, 0, 0, w},  //  6 =  row 0 rhs, col 0 top  =  rot 90
        { 0, x, y, 0, 0, 0},  //  7 =  row 0 rhs, col 0 bot  =  rot 90, flip vert
        { 0, x,-y, 0, h, 0}   //  8 =  row 0 lhs, col 0 bot  =  rotate -90
    };
	
	NSAffineTransform* transform = [NSAffineTransform transform];
	[transform setTransformStruct:orientationTransforms[orientation-1]];
	
    NSImage* targetImage = [[NSImage alloc] initWithSize:targetSize];
	[targetImage lockFocus];
	[transform concat];
    [image drawAtPoint:NSMakePoint(0,0) fromRect:NSMakeRect(0,0,[image size].width,[image size].height) operation:NSCompositeCopy fraction:1.0];
    [targetImage unlockFocus];
	
	return targetImage;	
	}
*/




- (void)doRenameToDirectory:(NSURL*)destinationPath withIndex:(int)index andMaxCount:(int)maxCount;
    {
    NSString* targetName;

    if (maxCount < 100)
        {
        targetName = [NSString stringWithFormat:@"%02d_%@", index, [self displayNameWithNoPrefix]];
        }
    else if (maxCount < 1000)
        {
        targetName = [NSString stringWithFormat:@"%03d_%@", index, [self displayNameWithNoPrefix]];
        }
    else
        {
        targetName = [NSString stringWithFormat:@"%04d_%@", index, [self displayNameWithNoPrefix]];
        }



    NSURL* newPath = [NSURL fileURLWithPath: [NSString stringWithFormat:@"%@/%@.%@", destinationPath, targetName, [self extension]] relativeToURL:nil];
    if ([[self fullPath] isEqualTo:newPath])
        {
        NSLog(@"No need to move %@", [self name]);
        return;
        }

    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (! [fileManager fileExistsAtPath:[destinationPath absoluteString] isDirectory:&isDir] && isDir)
        {
        NSLog(@"creating destination directory: %@", destinationPath);
        [fileManager createDirectoryAtURL:destinationPath withIntermediateDirectories:TRUE attributes:nil error:nil];
        }
    else if (!isDir)
        {
        NSLog(@"Aborting because there is a file where the systematized directory ought to be");
        }

    NSError* error = nil;
    if ([fileManager moveItemAtURL:[self fullPath] toURL:newPath error:&error])
        {
        NSLog(@"moved %@ to %@", [self fullPath], newPath);
        }
    else
        {
        NSLog(@"failed to move %@ to %@", [self fullPath], newPath);
        }

    if (thumbnailName)
        {
        NSURL* newThumbnailPath = [NSURL fileURLWithPath:[targetName trim] relativeToURL:destinationPath];
        NSURL* oldThumbnailPath = [NSURL fileURLWithPath:[[self name] trim] relativeToURL:[self path]];

        error = nil;
        if ([fileManager moveItemAtURL:oldThumbnailPath toURL:newThumbnailPath error:&error])
            {
            NSLog(@"thumbnail image moved successfully");
            }
        else
            {
            NSLog(@"failed to move thumbnail image %@ to %@", oldThumbnailPath, newThumbnailPath);
            }
        }
    }





//
// type info
//
-(BOOL) isImage;
    {
    return [self getMediaType] == ImageType;
    }



-(BOOL) isMovie;
    {
    return [self getMediaType] == MovieType;
    }



-(int) getMediaType;
    {
    if ([[[name pathExtension] lowercaseString] isEqualToString:@"jpg"])
        {
        return ImageType;
        }
    else
        {
        return MovieType;
        }
    }



-(NSImage*) typeBadge;
    {
    if ([self isMovie] && typeBadge == nil)
        {
        typeBadge = [NSImage imageNamed:@"movie_badge.tiff"];
        }
    return [[typeBadge retain] autorelease];
    }




//
// image accessors
//
-(NSImage*) image;
    {
    if (!sourceImage)
        {
        sourceImage = [[NSImage alloc] initWithContentsOfURL:[self fullPath]];
        }
    return [[sourceImage retain] autorelease];
    }


-(NSImage*) fastImage;
    {
    return [[fastImage retain] autorelease];
    }


-(NSImage*) thumbnail;
    {
    return [[thumbnail retain] autorelease];
    }


-(AVURLAsset*) movie;
    {
    return [[movie retain] autorelease];
    }




//
// name and attribute accessors
//
-(NSURL*) path;
    {
    return [[path retain] autorelease];
    }

-(void) setPath:(NSURL*)url;
    {
    [path release];
    path = [url retain];
    }



-(NSString*) name;
    {
    return [[name retain] autorelease];
    }

-(void) setName:(NSString*)str;
    {
    [name release];
    name = [str retain];
    }



-(NSString*) newName;
    {
    return [[newName retain] autorelease];
    }

-(void) setNewName:(NSString*)str;
    {
    [newName release];
    newName = [str retain];
    }




//
// read only attributes
//
-(NSURL*) fullPath;
    {
    return [NSURL fileURLWithPath:[[self name] trim] relativeToURL:[self path]];
    }



-(NSString*) baseName;
    {
    unsigned long extLength = [[self extension] length] + 1;
    return [name substringToIndex:[name length]-extLength];
    }



-(NSString*) extension;
    {
    return [[name pathExtension] lowercaseString];
    }



-(NSString*) displayName;
    {
    if (newName && [newName length] > 0)
        {
        return [[newName retain] autorelease];
        }
    else
        {
        return [self baseName];
        }
    }



-(NSString*) displayNameWithNoPrefix;
    {
    NSArray* components = [[self displayName] componentsSeparatedByString:@"_"];
    if ([components count] == 1)
        {
        return components[0];
        }
    else
        {
        if ([[components[0] stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] length] == 0)
            {
            // first component of name has only numbers, so get rid of it
            return [[components subarrayWithRange:NSMakeRange(1, [components count]-1)] componentsJoinedByString:@"_"];
            }
        else
            {
            // displayname has _ but doesn't have numeric prefix so just return displayname
            return [self displayName];
            }
        }
    }



-(NSDate *) creationDate;
    {
    return [[creationDate retain] autorelease];
    }



-(NSDate *) modificationDate;
    {
    return [[modificationDate retain] autorelease];
    }



-(unsigned long long int) fileSize;
    {
    return fileSize;
    }



-(NSString *) fileSizeAsString;
    {
    if (fileSize > 999999)
        {
        return [NSString stringWithFormat:@"%.2f megabytes", fileSize/1000000.0];
        }
    else if (fileSize > 999)
        {
        return [NSString stringWithFormat:@"%.2f kilobytes", fileSize/1000.0];
        }
    else
        {
        return [NSString stringWithFormat:@"%llu bytes", fileSize];
        }
    }



-(NSDate *) date;
    {
    if (exifDate)
        {
        return [[exifDate retain] autorelease];
        }
    else
        {
        return [[creationDate retain] autorelease];
        }
    }



-(NSDictionary *)metadata;
    {
    return [[meta retain] autorelease];
    }


/*
- (NSArray *) buildTableData:(NSDictionary *)dictionary;
{
    NSMutableArray* tree = [[[NSMutableArray alloc] init] autorelease];
	unsigned int count = [dictionary count];
	int i;
	NSArray* keys = [dictionary allKeys];
    for (i=0; i<count; i++)
		{
        NSString* key = [keys objectAtIndex:i];
        id value = [dictionary objectForKey:key];

		NSMutableDictionary* tableEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:key, @"key", value, @"val", nil];
        if ([value isKindOfClass:[NSDictionary class]])
			{
			[tableEntry setObject:[self buildTableData:value] forKey:@"children"];
			}
                        
        [tree addObject:tableEntry];
		}
    return tree;
}
*/




//
// Sorting methods
//

-(NSComparisonResult) compareByTime:(TSMedia*)other;
    {
    return [[self date] compare:[other date]];
    }

-(NSComparisonResult) compareByName:(TSMedia*)other;
    {
    return [[self displayName] compare:[other displayName]];
    }

@end
