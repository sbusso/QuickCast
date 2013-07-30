//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import <Foundation/Foundation.h>
#import "AmazonRequestDelegate.h"

@interface Uploader : NSObject <AmazonServiceRequestDelegate>{
    NSString *castId;
}

@property (strong) NSString *castId;

- (void)performUpload:(NSString *)filename video:(NSURL *)videoUrl thumbnail:(NSURL *)thumbnailUrl details:(NSDictionary *)details  length:(NSString *)length width:(NSString *)width height:(NSString *)height;

@end
