#import "SystematizeController.h"
#import "TSMedia.h"
#import "TSMediaCollection.h"
#import "TSDictionaryAdditions.h"
#import "MUPhotoView.h"


@implementation SystematizeController


-(void) awakeFromNib
    {
    NSLog(@"awake from nib");
	[[window windowController] setShouldCascadeWindows:NO];
	[window setFrameAutosaveName:@"com.techshadow.Systematize"];
	
	[selectedImagesLabel setStringValue:@""];
	[creationDateLabel setStringValue:@""];
	[modificationDateLabel setStringValue:@""];
	[fileSizeLabel setStringValue:@""];
		
	currentDisplayMode = ThumbnailType;
	
	[imageView setAutoresizesSubviews:YES];
	[imageView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[imageView setFrameOrigin:NSMakePoint(0.0, 0.0)];

    [movieView setAutoresizesSubviews:YES];
    [movieView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [movieView setFrameOrigin:NSMakePoint(0.0, 0.0)];
       
	[photoSizeSlider bind:@"value" toObject:photoView withKeyPath:@"photoSize" options:nil];
	[photoView setUseShadowSelection:YES];
	[photoView setUseOutlineBorder:NO];
	[photoView setBackgroundColor:[NSColor colorWithDeviceRed:0.8 green:0.8 blue:0.8 alpha:1.0]];
	[photoView setPhotoSize:256.0];
	
    collection = [[TSMediaCollection alloc] init];
	selectedIndexes = [NSIndexSet indexSet];
    
	[self chooseSourceDirectory:self];    
    [window makeKeyAndOrderFront:self];
	[window setNextResponder:self];
    }




-(void) chooseSourceDirectory:(id)sender
    {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    //NSString* picturesDirectoryPath = [@"~/Pictures/Pictures" stringByExpandingTildeInPath];
    NSString* picturesDirectoryPath = [@"~/Programming/systematize/tests/videos/" stringByExpandingTildeInPath];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:picturesDirectoryPath]];
    
    NSModalResponse result = [openPanel runModal];
    
    if (result == NSModalResponseOK)
        {
        NSArray* filesToOpen = [openPanel URLs];
        NSURL* directoryURL = [[filesToOpen[0] retain] autorelease];
        NSLog(@"chose source directory %@", directoryURL);
        [collection setCurrentDirectory:directoryURL];
		[self loadFileListForDirectory:directoryURL];
        [collection filterForItemsWithSupportingFiles];
        }
    else
        {
        NSLog(@"cancelled from choose source directory");
		[NSApp terminate:self];
        }
    }



-(void) loadFileListForDirectory:(NSURL*)directoryURL
    {
    NSLog(@"loadFileListForDirectory");
	
	[progressBarPanel makeKeyAndOrderFront:self];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray* directoryContents = [fileManager contentsOfDirectoryAtURL:directoryURL includingPropertiesForKeys:nil options: NSDirectoryEnumerationSkipsHiddenFiles error:nil];
	unsigned long maxItems = [directoryContents count];
	unsigned long currentItem = 0;
	[progressBar setDoubleValue:0.0];
	[progressBar setMinValue:0];
	[progressBar setMaxValue:maxItems];
    NSEnumerator* e = [directoryContents objectEnumerator];

    NSURL *fileURL;
    while (fileURL = (NSURL*)[e nextObject])
        {
		[progressTextField setStringValue:[NSString stringWithFormat:@"Loading item %lu of %lu", currentItem, maxItems]];
		[progressTextField displayIfNeeded];
		[progressBar incrementBy:1];
		[progressBar displayIfNeeded];
		currentItem++;

        NSNumber *isDirectory;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
            
        NSError *err;
        if (![fileURL checkResourceIsReachableAndReturnError:&err])
            {
            [[NSAlert alertWithError:err] runModal];
            continue;
            }
        else if (![isDirectory boolValue])
            {
			TSMedia* media = [TSMedia initWithPath:directoryURL name:[fileURL lastPathComponent]];
			[media loadData];
            [collection addObject:media];
            }
        }
	
	[progressBarPanel orderOut:nil];
    }
    



//
// action targets
//
- (IBAction)processNow:(id)sender;
	{
	NSLog(@"processNow");

    
    NSAlert *alertPanel = [[[NSAlert alloc] init] autorelease];
    [alertPanel addButtonWithTitle:@"Proceed"];
    [alertPanel addButtonWithTitle:@"Cancel"];
    [alertPanel setMessageText:@"Proceed with processing?"];
    [alertPanel setInformativeText:@"Proceeding will cause the pictures to be renamed and reordered as specified, and will exit Systematize."];
    [alertPanel setAlertStyle:NSAlertStyleWarning];
	NSModalResponse result = [alertPanel runModal];

	if (result == NSAlertFirstButtonReturn)
		{
		unsigned long maxItems = [collection size];
		unsigned long i;
		[progressBar setDoubleValue:0.0];
		[progressBar setMinValue:0];
		[progressBar setMaxValue:maxItems];
		[progressBarPanel makeKeyAndOrderFront:self];
		for (i=0; i<maxItems; i++)
			{
			[progressTextField setStringValue:[NSString stringWithFormat:@"Processing item %lu of %lu", i, maxItems]];
			[progressTextField displayIfNeeded];
			[progressBar incrementBy:1];
			[progressBar displayIfNeeded];

			[[collection objectAtIndex:i] doRenameToDirectory:[collection currentDirectory] withIndex:(int)i+1 andMaxCount:(int)maxItems];
			}
		
		[progressBarPanel orderOut:nil];
        NSAlert *confirmPanel = [[[NSAlert alloc] init] autorelease];
        [confirmPanel addButtonWithTitle:@"Quit"];
        [confirmPanel setMessageText:@"Finished Processing"];
        [confirmPanel setInformativeText:[NSString stringWithFormat:@"Renamed %lu images to directory:\n%@", [collection size], [collection currentDirectory]]];
        [confirmPanel setAlertStyle:NSAlertStyleWarning];
		[confirmPanel runModal];
		[NSApp terminate:self];
		}
    else
        {
        NSLog(@"cancelled from process window");
        }
	}




- (IBAction)sortByTime:(id)sender;
	{
	[collection sortByTime];
	[photoView setNeedsDisplay:YES];
	}



	
- (IBAction)sortByName:(id)sender;
	{
	[collection sortByName];
	[photoView setNeedsDisplay:YES];
	}




- (IBAction)editingFinished:(id)sender;
	{
	NSString* newName = [sender stringValue];
	[self setLastUsedName:newName];
	[self renameSelectedImagesWithName:newName];
	[photoView nameEditingCompleted];
	}
	



- (IBAction)renameSelectedPhotos:(id)sender;
	{
	[photoView renamePhotos:selectedIndexes];
	}




- (IBAction)renameWithLastUsedName:(id)sender;
	{
	if (lastUsedName)
		{
		[self renameSelectedImagesWithName:[self lastUsedName]];
		}
	}




- (IBAction) copyNameOfCurrentSelection:(id)sender;
	{
	if ([selectedIndexes count] > 0)
		{
		unsigned long index = [selectedIndexes firstIndex];
		[self setLastUsedName:[[collection objectAtIndex:index] displayName]];
		}
	}




//
// Responder methods
//

- (BOOL)acceptsFirstResponder;
	{
	NSLog(@"acceptsFirstResponder");
	return YES;
	}

- (BOOL)resignFirstResponder;
	{
	NSLog(@"resignFirstResponder");
	return YES;
	}

- (BOOL)becomeFirstResponder;
	{
	NSLog(@"becomeFirstResponder");
	return YES;
	}

- (void)keyDown:(NSEvent *)theEvent;
	{
	NSLog(@"got a keyDown event");
	[self interpretKeyEvents:@[theEvent]];
	}


- (void) cancelOperation:(id)sender;
	{
	NSLog(@"cancelOperation");
	if (ThumbnailType == currentDisplayMode)
		{
		NSLog(@"wait, we shouldn't be here....");
		}
	if (ImageType == currentDisplayMode)
		{
		NSLog(@"Swapping out image view");
		[[imageView retain] removeFromSuperview];
		}
	if (MovieType == currentDisplayMode)
		{
		NSLog(@"Swapping out movie view");
		[[movieView retain] removeFromSuperview];
		}
	[swapView addSubview:thumbnailView];
	NSSize frameSize = [swapView frame].size;
	[thumbnailView setFrame:NSMakeRect(0.0, 0.0, frameSize.width, frameSize.height)];
	currentDisplayMode = ThumbnailType;
	}




//
// other action methods
//


-(void) displayImage:(TSMedia*)item
    {
    NSLog(@"displayImage:%@", [item name]);	
	
	if (ThumbnailType == currentDisplayMode)
        {
        NSLog(@"Swapping out thumbnail view");
        [[thumbnailView retain] removeFromSuperview];
        }
	if (MovieType == currentDisplayMode)
        {
        NSLog(@"Swapping out movie view");
        [[movieView retain] removeFromSuperview];
        }
    if (ImageType != currentDisplayMode)
        {
        NSLog(@"Swapping in image view");
        NSSize frameSize = [swapView frame].size;
        [imageView setFrame:NSMakeRect(0.0, 0.0, frameSize.width, frameSize.height)];
        [swapView addSubview:imageView];
        }
    currentDisplayMode = ImageType;
    [imageView setImage:[item image]];

	[window makeFirstResponder:self];
	}




-(void) displayMovie:(TSMedia*)item
    {
    NSLog(@"displayMovie:%@", [item name]);    	
	
	if (ThumbnailType == currentDisplayMode)
        {
        NSLog(@"Swapping out thumbnail view");
        [[thumbnailView retain] removeFromSuperview];
        }
	if (ImageType == currentDisplayMode)
        {
        NSLog(@"Swapping out movie view");
        [[movieView retain] removeFromSuperview];
        }
    if (MovieType != currentDisplayMode)
        {
        NSLog(@"Swapping in image view");
        NSSize frameSize = [swapView frame].size;
        [movieView setFrame:NSMakeRect(0.0, 0.0, frameSize.width, frameSize.height)];
        [swapView addSubview:movieView];
        }
    currentDisplayMode = MovieType;
    [movieView setPlayer:[AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:[item movie]]]];
	[movieView setNextResponder:self];
	}




-(void) displayInfo:(TSMedia*)item
    {
    NSLog(@"displayInfo:%@", [item name]);    	
	NSWindow *detailWindow = [[[NSWindow alloc]
			initWithContentRect:NSMakeRect(50, 50, 200, 300)
					  styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
						backing:NSBackingStoreBuffered
						  defer:YES] autorelease];
	[detailWindow setTitle:[item baseName]];
	//[detailWindow setDelegate:self];

	NSSize frameSize = [[detailWindow contentView] frame].size;
	NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(0.0, 0.0, frameSize.width, frameSize.height)] autorelease];
	[scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[scrollView setFrameOrigin:NSMakePoint(0.0, 0.0)];
	[scrollView setAutohidesScrollers:YES];

	NSSize scrollViewFrameSize = [[scrollView contentView] frame].size;
	NSTextView *textView = [[[NSTextView alloc] initWithFrame:NSMakeRect(0.0, 0.0, scrollViewFrameSize.width, scrollViewFrameSize.height)] autorelease];
	[textView setFrameOrigin:NSMakePoint(0.0, 0.0)];
	[textView setEditable:NO];
	[textView setSelectable:NO];
	[textView setString:[[item metadata] asPlainStringWithPrefix:@""]];

	[scrollView setDocumentView:textView];
	[[detailWindow contentView] addSubview:scrollView];
    [detailWindow makeKeyAndOrderFront:nil];
	[detailWindow display];
	}
	
	





- (void) renameSelectedImagesWithName:(NSString*)str;
	{	
	unsigned long index = [selectedIndexes firstIndex];
	while (index != NSNotFound)
		{
		[[collection objectAtIndex:index] setNewName:str];
		index = [selectedIndexes indexGreaterThanIndex:index];
		}
	index = [selectedIndexes lastIndex];
	if (index < [collection size] - 1)
		{
		NSLog(@"setting selected index to %d", (int) (index+1));
		[selectedIndexes release];
		selectedIndexes = [[NSIndexSet indexSetWithIndex:index+1] retain];
		//[photoView setNeedsDisplay:YES];
		}
	}




//
// accessors
//
-(NSString*) lastUsedName;
	{
	return lastUsedName;
	}
	
-(void) setLastUsedName:(NSString*)str;
	{
	[lastUsedName release];
	lastUsedName = [str retain];
	}
	
	



//
// MUPhotoView delegate methods
//
- (unsigned int) photoCountForPhotoView:(MUPhotoView *)view;
	{
	return (unsigned int) [collection size];
	}
	
	
- (NSImage *)photoView:(MUPhotoView *)view photoAtIndex:(unsigned int)index;
	{
	return [[collection objectAtIndex:index] thumbnail];
	}
	

	
- (NSImage *)photoView:(MUPhotoView *)view fastPhotoAtIndex:(unsigned int)index;
	{
	return nil;
	//return [[collection objectAtIndex:index] thumbnail];
	}
	
	
- (TSMedia *)photoView:(MUPhotoView *)view objectAtIndex:(unsigned int)index;
	{
	return [collection objectAtIndex:index];
	}
	

- (NSIndexSet *)selectionIndexesForPhotoView:(MUPhotoView *)view
	{
    return selectedIndexes;
	}

- (NSIndexSet *)photoView:(MUPhotoView *)view willSetSelectionIndexes:(NSIndexSet *)indexes
	{
	if (selectedIndexes)
		{
		[selectedIndexes release];
		}
    selectedIndexes = [indexes copy];
	return selectedIndexes;
	}

- (void)photoView:(MUPhotoView *)view didSetSelectionIndexes:(NSIndexSet *)indexes
	{
    NSLog(@"didSetSelectionIndexes %lu", [indexes count]);
	if ([indexes count] == 0) 
		{
		[selectedImagesLabel setStringValue:@""];
		[creationDateLabel setStringValue:@""];
		[modificationDateLabel setStringValue:@""];
		[fileSizeLabel setStringValue:@""];
		}
	else if ([indexes count] == 1)
		{
        NSLog(@" found one index");
        NSUInteger index = [indexes firstIndex];
		[selectedImagesLabel   setStringValue:[[collection objectAtIndex:index] name]];
		NSDate* creationDate = [[collection objectAtIndex:index] creationDate];
		NSString* creationDateString = @"";
		if (creationDate != nil) {
            creationDateString = [creationDate description];
		}
		[creationDateLabel     setStringValue:creationDateString];

		NSDate* modificationDate = [[collection objectAtIndex:index] modificationDate];
		NSString *modificationDateString = @"";
		if (modificationDate != nil) {
			modificationDateString = [modificationDate description];
		}
		[modificationDateLabel setStringValue:modificationDateString];
		[fileSizeLabel         setStringValue:[[collection objectAtIndex:index] fileSizeAsString]];
		}
	else
		{
		[selectedImagesLabel setStringValue:@"<multiple selections>"];
		[creationDateLabel setStringValue:@""];
		[modificationDateLabel setStringValue:@""];
		[fileSizeLabel setStringValue:@""];
		}
    return;
	}
	

- (unsigned int)photoView:(MUPhotoView *)view draggingSourceOperationMaskForLocal:(BOOL)isLocal
	{
	if (isLocal)
		{
		return NSDragOperationPrivate;
		}
	else
		{
		return NSDragOperationNone;
		}
	}

- (NSArray *)pasteboardDragTypesForPhotoView:(MUPhotoView *)view
	{
    return @[NSPasteboardTypeFileURL];
	}

- (NSData *)photoView:(MUPhotoView *)view pasteboardDataForPhotoAtIndex:(unsigned int)index dataType:(NSString *)type
	{
	TSMedia* selectedPhoto = [collection objectAtIndex:index];
	NSImage* image = [selectedPhoto thumbnail];
	NSData* imageData = [image TIFFRepresentation];
	return imageData;
	}


- (void)photoView:(MUPhotoView *)view didDragSelection:(NSIndexSet *)selectedPhotoIndexes toIndex:(unsigned int)insertionIndex;
	{
	// we need to ensure that we keep the indexes straight, removing an item from the array changes all indexes greater than it
	
	// starting with the max index, remove them into a tmp array, adjust the insertion index if necessary
	NSMutableArray* tmpArray = [[[NSMutableArray alloc] init] autorelease];
	unsigned long localInsertionIndex = insertionIndex;
	unsigned long index = [selectedPhotoIndexes lastIndex];
	while (index != NSNotFound)
		{
		if (index <= localInsertionIndex)
			{
			localInsertionIndex--;
			}
		[tmpArray addObject:[collection objectAtIndex:index]];
		[collection removeObjectAtIndex:index];
		index = [selectedPhotoIndexes indexLessThanIndex:index];
		}
	
	// now add them back at the new location
	unsigned long i;
	for (i=0; i<[tmpArray count]; i++)
		{
        [collection insertObject:tmpArray[i] atIndex:localInsertionIndex];
		}
	// to avoid leaking memory
	[tmpArray removeAllObjects];
	}
	


- (void)photoView:(MUPhotoView *)view doubleClickOnPhotoAtIndex:(unsigned int)index;
	{
    TSMedia* mediaItem = [collection objectAtIndex:index];
	if ([mediaItem getMediaType] == ImageType)
		{
		[self displayImage:mediaItem];
		}
	if ([mediaItem getMediaType] == MovieType)
		{
		[self displayMovie:mediaItem];
		}
	}

- (NSIndexSet *)photoView:(MUPhotoView *)view willRemovePhotosAtIndexes:(NSIndexSet *)indexes;
	{
    return indexes;
	}

- (void)photoView:(MUPhotoView *)view didRemovePhotosAtIndexes:(NSIndexSet *)indexes;
	{
    unsigned long index = [indexes lastIndex];
	while (index != NSNotFound)
		{
		[collection removeObjectAtIndex:index];
		index = [indexes indexLessThanIndex:index];
		}
	}

- (void) showInfoForSelectedPhotos;
	{
    unsigned long index = [selectedIndexes firstIndex];
	while (index != NSNotFound)
		{
		[self displayInfo:[collection objectAtIndex:index]];
		index = [selectedIndexes indexGreaterThanIndex:index];
		}
	}


	
@end
