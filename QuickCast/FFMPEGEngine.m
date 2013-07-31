//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import "FFMPEGEngine.h"

@implementation FFMPEGEngine

- (NSString *)resizeVideo:(NSString *)inputPath output:(NSString *)outputPath width:(float)width height:(float)height{
    
    NSString *ffmpegPath = [[NSBundle mainBundle] pathForResource:@"ffmpeg" ofType:nil];
      
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: ffmpegPath];
        
    NSMutableArray *arguments = [NSMutableArray array];
        
    [arguments addObject:@"-i"];
    [arguments addObject:inputPath];
    [arguments addObject:@"-vf"];
    [arguments addObject:@"-sameq"];
    [arguments addObject:[NSString stringWithFormat:@"scale=%f:%f",width,height]];
    
    
    [arguments addObject:outputPath];
        
    [task setArguments: arguments];
    
    NSPipe *pipe, *errorPipe;
    pipe = [NSPipe pipe];
    errorPipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    [task setStandardError:errorPipe];
    
    NSFileHandle *file, *errorHandle;
    file = [pipe fileHandleForReading];
    errorHandle = [errorPipe fileHandleForReading];
    
    [task launch];
    
    NSMutableData *data = [NSMutableData dataWithCapacity:512];
    NSMutableData *errorData = [NSMutableData dataWithCapacity:512];
    
    while ([task isRunning]) {
        [data appendData:[file readDataToEndOfFile]];
        [errorData appendData:[errorHandle readDataToEndOfFile]];
    }
    [data appendData:[file readDataToEndOfFile]];
    [errorData appendData:[errorHandle readDataToEndOfFile]];
    
    
    NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
    NSString *errorString = [[NSString alloc] initWithData: errorData encoding: NSUTF8StringEncoding];
    
    if(errorString.length > 0){
        return errorString;
    }
    
    return nil;
        
}


@end
