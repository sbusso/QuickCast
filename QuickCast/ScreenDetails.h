//
//  ScreenDetails.h
//  QuickCast
//
//  Created by Pete Nelson on 19/07/2013.
//  Copyright (c) 2013 Reissued Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScreenDetails : NSObject{
    
    CGDirectDisplayID screenId;
    NSString *screenName;
    BOOL retina;
    NSScreen *screen;

}

@property CGDirectDisplayID screenId;
@property (strong) NSString *screenName;
@property BOOL retina;
@property (strong) NSScreen *screen;

@end
