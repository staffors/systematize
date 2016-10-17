#import "TSImageAdditions.h"

@implementation NSImage (TSAdditions)

-(NSImage *)imageScaledToSize:(NSSize)newSize;
	{
	NSImage *scaledImage = [self copy];

	[scaledImage setSize:newSize];

	return [scaledImage autorelease];
	}
	
	
	
-(NSImage *)imageScaledToMaxDimension:(int)maxDimension;
	{
	NSImage *scaledImage = [self copy];

	NSSize currentSize = [self size];
    CGFloat longSide = currentSize.width;
    if (longSide < currentSize.height)
        longSide = currentSize.height;

	CGFloat scale = maxDimension / longSide;
    
    NSSize scaledSize;
    scaledSize.width = currentSize.width * scale;
    scaledSize.height = currentSize.height * scale;

	[scaledImage setSize:scaledSize];

	return [scaledImage autorelease];
	}
	
	
	
- (void)drawCenteredinRect:(NSRect)inRect operation:(NSCompositingOperation)op fraction:(float)delta;
	{
	NSRect srcRect = NSZeroRect;
	srcRect.size = [self size];

	// create a destination rect scaled to fit inside the frame
	NSRect drawnRect = srcRect;
	if (drawnRect.size.width > inRect.size.width)
		{
		drawnRect.size.height *= inRect.size.width/drawnRect.size.width;
		drawnRect.size.width = inRect.size.width;
		}

	if (drawnRect.size.height > inRect.size.height)
		{
		drawnRect.size.width *= inRect.size.height/drawnRect.size.height;
		drawnRect.size.height = inRect.size.height;
		}

	drawnRect.origin = inRect.origin;

	// center it in the frame
	drawnRect.origin.x += (inRect.size.width - drawnRect.size.width)/2;
	drawnRect.origin.y += (inRect.size.height - drawnRect.size.height)/2;

	[self drawInRect:drawnRect fromRect:srcRect operation:op fraction:delta];
	}

@end
