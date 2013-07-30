//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import "VideoView.h"

@implementation VideoView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)drawRect:(NSRect)dirtyRect
{
    [[NSColor clearColor] set];  // Using the default window colour,
    NSRectFill(dirtyRect);      // Only draw the part you need.
}

@end
