//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import <Foundation/Foundation.h>

@interface QuickcastAPI : NSObject

- (void)signup:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock;
- (void)signin:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock;
- (void)userByToken:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock;
- (void)castPublish:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock;
- (void)castUpdate:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock;
- (void)castPublishComplete:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock;
- (void)castEncode:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock;
- (void)usercasts:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock;

@end
