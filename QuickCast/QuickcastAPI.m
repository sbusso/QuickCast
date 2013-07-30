//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import "QuickcastAPI.h"
#import <JSONKit.h>

@implementation QuickcastAPI


- (void)signup:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock{
    // Generate the URL
    NSString *requestUrl = [NSString stringWithFormat:@"http://quick.as/api/v1%@", @"/users/signup"];
    
    // Create the connection
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];
    
    
    NSString *email = [params objectForKey:@"email"];
    NSString *username = [params objectForKey:@"username"];
    NSString *password = [params objectForKey:@"password"];
    NSString *firstname = [params objectForKey:@"firstname"];
    NSString *lastname = [params objectForKey:@"lastname"];
    NSString *mailinglist = [params objectForKey:@"mailinglist"];
    
    [request setHTTPMethod: @"PUT"];
    
    [request setValue:email forHTTPHeaderField:@"email"];
    [request setValue:username forHTTPHeaderField:@"username"];
    [request setValue:password forHTTPHeaderField:@"password"];
    [request setValue:firstname forHTTPHeaderField:@"firstname"];
    [request setValue:lastname forHTTPHeaderField:@"lastname"];
    [request setValue:mailinglist forHTTPHeaderField:@"mailinglist"];
    
    // Make an NSOperationQueue
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setName:@"io.quickcast.signup"];
    
    // Send an asyncronous request on the queue
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // If there was an error getting the data
        if (error) {
           
            NSError *jsonErrorError;
            NSDictionary *errorDict = [data objectFromJSONData];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionBlock(errorDict, error,nil);
            });
            return;
        }
        
        // Decode the data
        NSError *jsonError;
        NSDictionary *responseDict = [data objectFromJSONData];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // If there was an error decoding the JSON
        if (jsonError) {
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                NSLog(@"json error");
            });
            return;
        }
        
        // All looks fine, lets call the completion block with the response data
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionBlock(responseDict, nil,httpResponse);
        });
    }];
}

- (void)signin:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock{
    
    // Generate the URL
    NSString *requestUrl = [NSString stringWithFormat:@"http://quick.as/api/v1%@", @"/users/signin"];
    
    // Create the connection
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];
    
    NSString *username = [params objectForKey:@"username"];
    NSString *password = [params objectForKey:@"password"];
    
    [request setHTTPMethod: @"POST"];
    
    [request setValue:username forHTTPHeaderField:@"username"];
    [request setValue:password forHTTPHeaderField:@"password"];
    
    // Make an NSOperationQueue
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setName:@"io.quickcast.signin"];
    
    // Send an asyncronous request on the queue
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // If there was an error getting the data
        if (error) {
            
            NSError *jsonErrorError;
            NSDictionary *errorDict = [data objectFromJSONData];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionBlock(errorDict, error,nil);
            });
            return;
        }
        
        // Decode the data
        NSError *jsonError;
        NSDictionary *responseDict = [data objectFromJSONData];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // If there was an error decoding the JSON
        if (jsonError) {
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                NSLog(@"json error");
            });
            return;
        }
        
        // All looks fine, lets call the completion block with the response data
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionBlock(responseDict, nil,httpResponse);
        });
    }];
}

- (void)userByToken:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock{
    
    // Generate the URL
    NSString *requestUrl = [NSString stringWithFormat:@"http://quick.as/api/v1%@", @"/users/userbytoken"];
    
    // Create the connection
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];
    
    
    NSString *token = [params objectForKey:@"token"];
    
    //ensure + are kept in
    //email = [email stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    //NSData *requestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    
    [request setHTTPMethod: @"GET"];
    
    [request setValue:token forHTTPHeaderField:@"token"];
    
    // Make an NSOperationQueue
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setName:@"io.quickcast.userByToken"];
    
    
    // Send an asyncronous request on the queue
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // If there was an error getting the data
        if (error) {
            //NSLog(@"data is %@",[[NSString alloc] initWithData:data
            //    encoding:NSUTF8StringEncoding]);
            NSError *jsonErrorError;
            NSDictionary *errorDict = [data objectFromJSONData];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionBlock(errorDict, error,nil);
            });
            return;
        }
        
        // Decode the data
        NSError *jsonError;
        NSDictionary *responseDict = [data objectFromJSONData];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        // If there was an error decoding the JSON
        if (jsonError) {
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                
            });
            return;
        }
        
        // All looks fine, lets call the completion block with the response data
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionBlock(responseDict, nil,httpResponse);
        });
    }];
}

- (void)castEncode:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock{
    
    // Generate the URL
    NSString *requestUrl = [NSString stringWithFormat:@"http://quick.as/api/v1%@", @"/casts/publish/encode"];
    
    // Create the connection
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];
    
    
    NSString *token = [params objectForKey:@"token"];
    NSString *castid = [params objectForKey:@"castid"];
    
    [request setHTTPMethod: @"GET"];
    
    [request setValue:token forHTTPHeaderField:@"token"];
    [request setValue:castid forHTTPHeaderField:@"castid"];
    
    // Make an NSOperationQueue
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setName:@"io.quickcast.castencode"];
    
    
    // Send an asyncronous request on the queue
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // If there was an error getting the data
        if (error) {
            //NSLog(@"data is %@",[[NSString alloc] initWithData:data
            //    encoding:NSUTF8StringEncoding]);
            NSError *jsonErrorError;
            NSDictionary *errorDict = [data objectFromJSONData];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionBlock(errorDict, error,nil);
            });
            return;
        }
        
        // Decode the data
        NSError *jsonError;
        NSDictionary *responseDict = [data objectFromJSONData];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        // If there was an error decoding the JSON
        if (jsonError) {
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                
            });
            return;
        }
        
        // All looks fine, lets call the completion block with the response data
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionBlock(responseDict, nil,httpResponse);
        });
    }];
}


- (void)usercasts:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock{
    
    // Generate the URL
    NSString *requestUrl = [NSString stringWithFormat:@"http://quick.as/api/v1%@", @"/users/usercasts"];
    
    // Create the connection
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];
    
    
    NSString *token = [params objectForKey:@"token"];
    
    [request setHTTPMethod: @"GET"];
    
    [request setValue:token forHTTPHeaderField:@"token"];
    
    // Make an NSOperationQueue
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setName:@"io.quickcast.usercasts"];
    
    
    // Send an asyncronous request on the queue
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // If there was an error getting the data
        if (error) {
            //NSLog(@"data is %@",[[NSString alloc] initWithData:data
            //    encoding:NSUTF8StringEncoding]);
            NSError *jsonErrorError;
            NSDictionary *errorDict = [data objectFromJSONData];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionBlock(errorDict, error,nil);
            });
            return;
        }
        
        // Decode the data
        NSError *jsonError;
        NSDictionary *responseDict = [data objectFromJSONData];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        // If there was an error decoding the JSON
        if (jsonError) {
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                
            });
            return;
        }
        
        // All looks fine, lets call the completion block with the response data
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionBlock(responseDict, nil,httpResponse);
        });
    }];
}

- (void)castPublish:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock{
    
    // Generate the URL
    NSString *requestUrl = [NSString stringWithFormat:@"http://quick.as/api/v1%@", @"/casts/publish"];
    
    // Create the connection
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];
    
    
    NSString *token = [params objectForKey:@"token"];
    
    [request setHTTPMethod: @"PUT"];
    
    [request setValue:token forHTTPHeaderField:@"token"];
    
    //send these as blank fields in the body (until api is updated)
    NSString *myRequestString = @"description=&name=&tags=&intro=&outro=";
    
    NSData *requestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    [request setHTTPBody: requestData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
       
    // Make an NSOperationQueue
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setName:@"io.quickcast.castPublish"];
    
    
    // Send an asyncronous request on the queue
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // If there was an error getting the data
        if (error) {
            
            NSDictionary *errorDict = [data objectFromJSONData];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionBlock(errorDict, error,nil);
            });
            return;
        }
        
        // Decode the data
        NSError *jsonError;
        NSDictionary *responseDict = [data objectFromJSONData];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        // If there was an error decoding the JSON
        if (jsonError) {
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                
            });
            return;
        }
        
        // All looks fine, lets call the completion block with the response data
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionBlock(responseDict, nil,httpResponse);
        });
    }];
}


- (void)castUpdate:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock{
    
    // Generate the URL
    NSString *requestUrl = [NSString stringWithFormat:@"http://quick.as/api/v1%@", @"/casts/publish/update"];
    
    // Create the connection
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];
    
    NSString *token = [params objectForKey:@"token"];
    NSString *castId = [params objectForKey:@"castId"];
    NSString *description = [params objectForKey:@"description"];
    NSString *name = [params objectForKey:@"name"];
    NSString *tags = [params objectForKey:@"tags"];
    NSString *intro = [params objectForKey:@"intro"];
    NSString *outro = [params objectForKey:@"outro"];
    
    [request setHTTPMethod: @"POST"];
    
    [request setValue:token forHTTPHeaderField:@"token"];
    
    
    NSString *myRequestString = [NSString stringWithFormat:@"castid=%@&description=%@&name=%@&tags=%@&intro=%@&outro=%@", castId,description,name,tags,intro,outro];
    
    //ensure + are kept in
    myRequestString = [myRequestString stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    NSData *requestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    [request setHTTPBody: requestData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    
    // Make an NSOperationQueue
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setName:@"io.quickcast.castPublish"];
    
    
    // Send an asyncronous request on the queue
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // If there was an error getting the data
        if (error) {
            
            NSDictionary *errorDict = [data objectFromJSONData];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionBlock(errorDict, error,nil);
            });
            return;
        }
        
        // Decode the data
        NSError *jsonError;
        NSDictionary *responseDict = [data objectFromJSONData];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        // If there was an error decoding the JSON
        if (jsonError) {
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                
            });
            return;
        }
        
        // All looks fine, lets call the completion block with the response data
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionBlock(responseDict, nil,httpResponse);
        });
    }];
}

- (void)castPublishComplete:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *,NSHTTPURLResponse *))completionBlock{
    
    // Generate the URL
    NSString *requestUrl = [NSString stringWithFormat:@"http://quick.as/api/v1%@", @"/casts/publish/complete"];
    
    // Create the connection
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];
    
    NSString *token = [params objectForKey:@"token"];
    NSString *castId = [params objectForKey:@"castId"];
    NSString *length = [params objectForKey:@"length"];
    NSString *size = [params objectForKey:@"size"];
    NSString *width = [params objectForKey:@"width"];
    NSString *height = [params objectForKey:@"height"];
    
    [request setHTTPMethod: @"POST"];
    
    [request setValue:token forHTTPHeaderField:@"token"];
    [request setValue:castId forHTTPHeaderField:@"castId"];
    [request setValue:size forHTTPHeaderField:@"size"];
    [request setValue:length forHTTPHeaderField:@"length"];
    [request setValue:width forHTTPHeaderField:@"width"];
    [request setValue:height forHTTPHeaderField:@"height"];
    
    // Make an NSOperationQueue
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setName:@"io.quickcast.castPublishComplete"];
    
    
    // Send an asyncronous request on the queue
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // If there was an error getting the data
        if (error) {
            
            NSDictionary *errorDict = [data objectFromJSONData];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionBlock(errorDict, error,nil);
            });
            return;
        }
        
        // Decode the data
        NSError *jsonError;
        NSDictionary *responseDict = [data objectFromJSONData];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        // If there was an error decoding the JSON
        if (jsonError) {
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                
            });
            return;
        }
        
        // All looks fine, lets call the completion block with the response data
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionBlock(responseDict, nil,httpResponse);
        });
    }];
}


@end
