//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import <Foundation/Foundation.h>

@interface FFMPEGEngine : NSObject

- (NSString *)resizeVideo:(NSString *)inputPath output:(NSString *)outputPath width:(float)width height:(float)height;

@end
