@import Cocoa;
@import AVKit;
@import AVFoundation;

@class TSMediaCollection;
@class TSMedia;
@class MUPhotoView;

@interface SystematizeController : NSResponder
{
    IBOutlet NSWindow* window;
	IBOutlet NSSlider* photoSizeSlider;
	IBOutlet MUPhotoView* photoView;
	
	IBOutlet NSView* swapView;
	IBOutlet NSView* thumbnailView;
	IBOutlet NSImageView* imageView;
	IBOutlet AVPlayerView* movieView;

	IBOutlet NSTextField* selectedImagesLabel;
	IBOutlet NSTextField* creationDateLabel;
	IBOutlet NSTextField* modificationDateLabel;
	IBOutlet NSTextField* fileSizeLabel;
	
	IBOutlet NSPanel* progressBarPanel;
	IBOutlet NSProgressIndicator* progressBar;
	IBOutlet NSTextField* progressTextField;
	
	NSString* lastUsedName;
	
    TSMediaCollection* collection;
	NSIndexSet* selectedIndexes;
        
    NSWindow* fullScreenWindow;
	
	int currentDisplayMode;
}

-(void) awakeFromNib;
-(void) chooseSourceDirectory:(id)sender;
-(void) loadFileListForDirectory:(NSURL*)directoryPath;


// action targets
- (IBAction) processNow:(id)sender;
- (IBAction) sortByTime:(id)sender;
- (IBAction) sortByName:(id)sender;
- (IBAction) renameSelectedPhotos:(id)sender;
- (IBAction) editingFinished:(id)sender;
- (IBAction) renameWithLastUsedName:(id)sender;
- (IBAction) copyNameOfCurrentSelection:(id)sender;


// responder methods
- (BOOL)acceptsFirstResponder;
- (BOOL)resignFirstResponder;
- (BOOL)becomeFirstResponder;
- (void)keyDown:(NSEvent *)theEvent;
- (void)cancelOperation:(id)sender;


// other action methods
- (void) displayImage:(TSMedia*)item;
- (void) displayMovie:(TSMedia*)item;
- (void) displayInfo:(TSMedia*)item;
- (void) renameSelectedImagesWithName:(NSString*)str;


// accessors
- (NSString*) lastUsedName;
- (void) setLastUsedName:(NSString*)str;


// MUPhotoView delegate methods
- (unsigned int) photoCountForPhotoView:(MUPhotoView *)view;
- (NSImage *) photoView:(MUPhotoView *)view photoAtIndex:(unsigned int)index;
- (NSImage *) photoView:(MUPhotoView *)view fastPhotoAtIndex:(unsigned int)index;
- (TSMedia *) photoView:(MUPhotoView *)view objectAtIndex:(unsigned int)index;
- (NSIndexSet *) selectionIndexesForPhotoView:(MUPhotoView *)view;
- (NSIndexSet *) photoView:(MUPhotoView *)view willSetSelectionIndexes:(NSIndexSet *)indexes;
- (void) photoView:(MUPhotoView *)view didSetSelectionIndexes:(NSIndexSet *)indexes;
- (unsigned int) photoView:(MUPhotoView *)view draggingSourceOperationMaskForLocal:(BOOL)isLocal;
- (NSArray *) pasteboardDragTypesForPhotoView:(MUPhotoView *)view;
- (NSData *) photoView:(MUPhotoView *)view pasteboardDataForPhotoAtIndex:(unsigned int)index dataType:(NSString *)type;
- (void) photoView:(MUPhotoView *)view didDragSelection:(NSIndexSet *)selectedPhotoIndexes toIndex:(unsigned int)insertionIndex;
- (void) photoView:(MUPhotoView *)view doubleClickOnPhotoAtIndex:(unsigned int)index;
- (NSIndexSet *) photoView:(MUPhotoView *)view willRemovePhotosAtIndexes:(NSIndexSet *)indexes;
- (void) photoView:(MUPhotoView *)view didRemovePhotosAtIndexes:(NSIndexSet *)indexes;
- (void) showInfoForSelectedPhotos;


@end
