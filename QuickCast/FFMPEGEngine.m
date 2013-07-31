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
    
    // running: ./ffmpeg -i quickcast.mov -c:v libx264 -preset veryfast -crf 22 output.mp4
    [arguments addObject:@"-i"];
    [arguments addObject:inputPath];
    [arguments addObject:@"-c:v"];
    [arguments addObject:@"libx264"];
    [arguments addObject:@"-preset"];
    [arguments addObject:@"veryfast"];
    [arguments addObject:@"-crf"];
    [arguments addObject:@"22"];
    
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
    
    if(string.length > 0){
        NSLog(@"-------------------string-------------------%@",string);
    }
    if(errorString.length > 0){
         NSLog(@"-------------------errorstring-------------------%@",errorString);
        NSLog(@"-------------------enderrorstring-------------------");
        return errorString;
    }
    
    return nil;
        
}


@end
