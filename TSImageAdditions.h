#import <Cocoa/Cocoa.h>

@interface NSImage (TSImageAdditions)

//returns a copy of the image scaled to the passed size.
-(NSImage *)imageScaledToSize:(NSSize)newSize;

// returns a copy of the image scaled such that the larger dimension is scaled to specified size and the smaller dimension is scaled proportionately
-(NSImage *)imageScaledToMaxDimension:(int)maxDimension;

// draws the passed image into the passed rect, centered and scaled appropriately.
// note that this method doesn't know anything about the current focus, so the focus must be locked outside this method
- (void)drawCenteredinRect:(NSRect)inRect operation:(NSCompositingOperation)op fraction:(float)delta;


@end
