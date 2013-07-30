//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import "TransparentWindow.h"

@implementation TransparentWindow

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)windowStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)deferCreation
{
    
    self = [super
            initWithContentRect:contentRect
            styleMask:NSBorderlessWindowMask
            backing:bufferingType
            defer:deferCreation];
    if (self)
    {
        [self setOpaque:NO];
        NSColor *semiTransparentBlue =
        [NSColor colorWithDeviceRed:0.1 green:0.1 blue:0.1 alpha:0.6];
        [self setBackgroundColor:semiTransparentBlue];
        [self setContentBorderThickness:2 forEdge:NSMinYEdge];
        [self setIgnoresMouseEvents:YES];
        [self setLevel:NSScreenSaverWindowLevel + 1];
        
    }
    
    
    return self;
}

@end
