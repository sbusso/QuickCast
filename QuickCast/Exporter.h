//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Uploader.h"


@interface Exporter : NSObject {
    
    Uploader *uploader;
}

@property (strong) Uploader *uploader;

- (void)startUpload:(NSDictionary *)details width:(NSString *)width height:(NSString *)height;


@end