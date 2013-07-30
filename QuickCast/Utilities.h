//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import <Foundation/Foundation.h>
#import "ScreenDetails.h"

@interface Utilities : NSObject

+ (NSSize)resize:(NSSize)old withMax:(float)max;
+ (NSString *)minutesSeconds:(int)seconds;
+ (NSImage *) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;
+ (ScreenDetails *)getScreenDetails:(NSScreen *)screen;
+ (ScreenDetails *)getMainDisplayDetails;
+ (ScreenDetails *)getDisplayByName:(NSString *)name;
+ (NSMutableArray *)getDisplays;
+ (NSArray *)getAudioInputs;

@end
