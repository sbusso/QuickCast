//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import "Exporter.h"
#import "AppDelegate.h"
#import "AmazonS3Client.h"
#import "AmazonCredentials.h"
#import <AVFoundation/AVAssetExportSession.h>
#import "Uploader.h"
#import <ApplicationServices/ApplicationServices.h>
#import "TransparentWindow.h"
#import "VideoView.h"
#import "Utilities.h"

@implementation Exporter{
    
    NSString *filename;
    NSURL *tempUrl;
    NSURL *finishedUrl;
    AVAsset *videoAsset;
   
}

@synthesize uploader;

#pragma mark Capture


- (NSString *)saveThumbnail:(NSSize)newSize thumb:(NSImage *)thumb suffix:(NSString *)suffix{
    
    NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
    [smallImage lockFocus];
    [thumb setSize: newSize];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [thumb drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    [smallImage unlockFocus];
    // Write to JPG
    NSData *imageData = [smallImage  TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    NSString *filepath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"quickcast%@.jpg",suffix]];
    [imageData writeToFile:filepath atomically:NO];
    
    return filepath;
}

- (void)thumbnailAndUpload:(NSDictionary *)details length:(NSString *)length width:(NSString *)width height:(NSString *)height{
    
    NSImage *thumb = [Utilities thumbnailImageForVideo:finishedUrl atTime:(NSTimeInterval)0.5];
    
    [thumb setScalesWhenResized:YES];
    
    // Report an error if the source isn't a valid image
    if (![thumb isValid])
    {
        NSLog(@"Invalid Image");
    } else
    {
        NSSize newSize = [Utilities resize:thumb.size withMax:160];
        [self saveThumbnail:newSize thumb:thumb suffix:@"_thumb"];
    }
    
    self.uploader = [[Uploader alloc] init];
    
    [self.uploader performUpload:filename video:finishedUrl thumbnail:[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"quickcast_thumb.jpg"]] details:details length:length width:width height:height];

}


- (void)startUpload:(NSDictionary *)details width:(NSString *)width height:(NSString *)height{
    
    dispatch_async(dispatch_get_main_queue(),^ {
        
        NSDate *time = [NSDate date];
        NSDateFormatter* df = [NSDateFormatter new];
        [df setDateFormat:@"dd-MM-yyyy-hh-mm-ss"];
        NSString *timeString = [df stringFromDate:time];
        
        filename = [NSString stringWithFormat:@"quickcast-%@.%@", timeString, @"mp4"];
        
        NSString *quickcast = [NSHomeDirectory() stringByAppendingPathComponent:@"Movies/quickcast"];
        
        tempUrl = [NSURL fileURLWithPath:[quickcast stringByAppendingPathComponent:@"quickcast-compressed.mov"]];
        
        videoAsset = [AVAsset assetWithURL:tempUrl];
        //CMTime totalTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(videoAsset.duration), videoAsset.duration.timescale);
        NSString *length = [NSString stringWithFormat:@"%f",CMTimeGetSeconds(videoAsset.duration)];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *quickcastPath = [prefs objectForKey:@"quickcastSavePath"];
        
        if(quickcastPath.length > 0){
            
            finishedUrl = [NSURL fileURLWithPath:[quickcastPath stringByAppendingPathComponent:filename]];
        }
        else{
            
            finishedUrl = [NSURL fileURLWithPath:[quickcast stringByAppendingPathComponent:filename]];
        
        }
        
        
        NSError *error;
        //copy temp to finished
        [[NSFileManager defaultManager] copyItemAtURL:tempUrl toURL:finishedUrl error:&error];
        
        if (error) {
            NSLog(@"%@", error);
        }
        
        [self thumbnailAndUpload:details length:length width:width height:height];
//        //
//        videoAsset = [AVAsset assetWithURL:tempUrl];
//        
//        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
//        
//        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
//        preferredTrackID:kCMPersistentTrackID_Invalid];
//        
//        int starting = 0;
//        int ending = 0;
//        if(intro.length > 0){
//            starting =  5;
//            // 5 second intro
//            [videoTrack  insertTimeRange:CMTimeRangeMake(kCMTimeZero,CMTimeMakeWithSeconds(5,1))
//                                ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
//                                 atTime:kCMTimeZero error:nil];
//        }
//        
//        // the actual video
//        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
//                            ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
//                             atTime:CMTimeMakeWithSeconds(starting,1) error:nil];
//        
//        //if(outro.length > 0){
//        //always add ending whatever
//        ending = 5;
//        // 5 second outro
//        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,CMTimeMakeWithSeconds(5,1))
//                            ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
//                             atTime:CMTimeMakeWithSeconds(CMTimeGetSeconds(videoAsset.duration) + starting, videoAsset.duration.timescale) error:nil];
//        //}
//        
//        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
//                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
//        
//            
//        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
//                            ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
//                             atTime:CMTimeMakeWithSeconds(starting,1) error:nil];
//        
//        NSInteger i;
//        NSArray *tracksToDuck = [mixComposition tracksWithMediaType:AVMediaTypeAudio]; 
//        
//        NSMutableArray *trackMixArray = [NSMutableArray array];
//        CMTime rampDuration = CMTimeMake(1, 16); // one sixteenth of a second ramps
//        for (i = 0; i < [tracksToDuck count]; i++) {
//            AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:[tracksToDuck objectAtIndex:i]];
//            [trackMix setVolumeRampFromStartVolume:0.0 toEndVolume:1.0 timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(starting,1), rampDuration)];
//            [trackMix setVolumeRampFromStartVolume:1.0 toEndVolume:0.0 timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(CMTimeGetSeconds(videoAsset.duration)+starting, videoAsset.duration.timescale), rampDuration)];
//            [trackMixArray addObject:trackMix];
//        }
//        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
//        audioMix.inputParameters = trackMixArray;
//              
//        // 3.1 - Create AVMutableVideoCompositionInstruction
//        AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//        
//        CMTime totalTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(videoAsset.duration) + starting + ending, videoAsset.duration.timescale);
//        NSString *totalLength = [NSString stringWithFormat:@"%f",CMTimeGetSeconds(videoAsset.duration) + starting + ending];
//        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,totalTime);
//        
//        // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
//        AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
//        AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//        
//        
//        /*CGFloat FirstAssetScaleToFitRatio = 1280 / videoAssetTrack.naturalSize.width;
//        CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
//        [videolayerInstruction setTransform:CGAffineTransformConcat(CGAffineTransformConcat(videoAssetTrack.preferredTransform, FirstAssetScaleFactor),CGAffineTransformMakeTranslation(0, 160)) atTime:kCMTimeZero];
//        */
//        [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
//        [videolayerInstruction setOpacity:0.0 atTime:totalTime];
//        
//        // 3.3 - Add instructions
//        mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
//        
//        
//        AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
//        
//        CGSize naturalSize;
//        naturalSize = videoAssetTrack.naturalSize;
//        
//        float renderWidth, renderHeight;
//        renderWidth = naturalSize.width;
//        renderHeight = naturalSize.height;
//        
//        NSString *width =  [NSString stringWithFormat:@"%0.0f", round(renderWidth)];
//        NSString *height = [NSString stringWithFormat:@"%0.0f", round(renderHeight)];
//        
//        mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
//        
//        mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
//        mainCompositionInst.frameDuration = CMTimeMake(1, 30);
//        
//        
//        CATextLayer *introText = [[CATextLayer alloc] init];
//        [introText setFont:@"Helvetica-Neue"];
//        [introText setWrapped:YES];
//        [introText setFontSize:120];
//        [introText setFrame:CGRectMake(50, 0, naturalSize.width-100, (naturalSize.height/2)+100)];
//        [introText setString:intro];
//        [introText setAlignmentMode:kCAAlignmentCenter];
//        
//        [introText setForegroundColor:CGColorCreateGenericRGB(1.0, 1.0, 1.0,1.0)];
//        
//        //outro
//        CATextLayer *outroText = [[CATextLayer alloc] init];
//        [outroText setFont:@"Helvetica-Neue"];
//        [outroText setWrapped:YES];
//        [outroText setFontSize:120];
//        [outroText setFrame:CGRectMake(50, 0, naturalSize.width-100, (naturalSize.height/2)+100)];
//        [outroText setString:outro];
//        [outroText setAlignmentMode:kCAAlignmentCenter];
//        
//        [outroText setForegroundColor:CGColorCreateGenericRGB(1.0, 1.0, 1.0,1.0)];
//               
//        // 2 - The usual overlay
//        CALayer *overlayIntroLayer = [CALayer layer];
//        
//        [overlayIntroLayer addSublayer:introText];
//        CALayer *introImageLayer = [CALayer layer];
//        [introImageLayer setFrame:CGRectMake(naturalSize.width - 50 - 346, 50, 346, 50)];
//        
//        
//        NSImage* introImage = [NSImage imageNamed:@"qcast"];
//        NSRect iiRect = NSMakeRect(0, 0,346,50);
//        CGImageRef cgIntroImage = [introImage CGImageForProposedRect:&iiRect context:[NSGraphicsContext currentContext] hints:nil];
//        introImageLayer.contents = (__bridge id)cgIntroImage;
//        [overlayIntroLayer addSublayer:introImageLayer];
//        [overlayIntroLayer setBackgroundColor:CGColorCreateGenericRGB(0.26, 0.67, 0.45,1.0)];
//        overlayIntroLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
//        [overlayIntroLayer setMasksToBounds:YES];
//        
//        CALayer *overlayOutroLayer = [CALayer layer];
//        
//        [overlayOutroLayer addSublayer:outroText];
//        CALayer *outroImageLayer = [CALayer layer];
//        
//        
//        //////
//        if(naturalSize.width > 370 && naturalSize.height > 70){
//            
//            if(outro.length > 0)
//                [outroImageLayer setFrame:CGRectMake(naturalSize.width - 50 - 346, 50, 346, 50)];
//            else{
//                [outroImageLayer setFrame:CGRectMake((naturalSize.width/2)-173 , (naturalSize.height/2)-25, 346, 50)];
//            }
//
//            
//            NSImage* outroImage = [NSImage imageNamed:@"qcast"];
//            NSRect ooRect = NSMakeRect(0, 0,346,50);
//            CGImageRef cgOutroImage = [outroImage CGImageForProposedRect:&ooRect context:[NSGraphicsContext currentContext] hints:nil];
//            outroImageLayer.contents = (__bridge id)cgOutroImage;
//            [overlayOutroLayer addSublayer:outroImageLayer];
//        }
//        else{
//            //resize it down
//            NSSize smaller = [Utilities resize:NSMakeSize(346, 50) withMax:naturalSize.width - 20];
//            
//            
//            if(outro.length > 0)
//                [outroImageLayer setFrame:CGRectMake(naturalSize.width - smaller.width, smaller.height, smaller.width, smaller.height)];
//            else{
//                [outroImageLayer setFrame:CGRectMake((naturalSize.width/2) - (smaller.width/2), naturalSize.height/2, smaller.width, smaller.height)];
//            }
//
//            
//            NSImage* outroImage = [NSImage imageNamed:@"qcast"];
//            NSRect ooRect = NSMakeRect(0, 0,smaller.width,smaller.height);
//            CGImageRef cgOutroImage = [outroImage CGImageForProposedRect:&ooRect context:[NSGraphicsContext currentContext] hints:nil];
//            outroImageLayer.contents = (__bridge id)cgOutroImage;
//            [overlayOutroLayer addSublayer:outroImageLayer];
//        }
//
//        
//        //////
//        
//                
//        
//        NSImage* outroImage = [NSImage imageNamed:@"qcast"];
//        NSRect ooRect = NSMakeRect(0, 0,346,50);
//        CGImageRef cgOutroImage = [outroImage CGImageForProposedRect:&ooRect context:[NSGraphicsContext currentContext] hints:nil];
//        outroImageLayer.contents = (__bridge id)cgOutroImage;
//        [overlayOutroLayer addSublayer:outroImageLayer];
//
//        [overlayOutroLayer setBackgroundColor:CGColorCreateGenericRGB(0.26, 0.67, 0.45,1.0)];
//        overlayOutroLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
//        [overlayOutroLayer setMasksToBounds:YES];
//        
//        
//        
//        CALayer *parentLayer = [CALayer layer];
//        CALayer *videoLayer = [CALayer layer];
//        parentLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
//        videoLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
//        [parentLayer addSublayer:videoLayer];
//        if(intro.length > 0)
//            [parentLayer addSublayer:overlayIntroLayer];
//        [parentLayer addSublayer:overlayOutroLayer];
//        
//        
//        if(starting != 0){
//            CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//            fadeAnimation.fromValue = [NSNumber numberWithFloat:1.0];
//            fadeAnimation.toValue = [NSNumber numberWithFloat:0.0];
//            fadeAnimation.additive = NO;
//            fadeAnimation.removedOnCompletion = NO;
//            fadeAnimation.beginTime = 5.0;
//            fadeAnimation.duration = 0.5;
//            fadeAnimation.fillMode = kCAFillModeBoth;
//            [overlayIntroLayer addAnimation:fadeAnimation forKey:nil];
//        }
//        
//        
//        CABasicAnimation *fadeOutroAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//        fadeOutroAnimation.fromValue = [NSNumber numberWithFloat:0.0];
//        fadeOutroAnimation.toValue = [NSNumber numberWithFloat:1.0];
//        fadeOutroAnimation.additive = NO;
//        fadeOutroAnimation.removedOnCompletion = NO;
//        float beginTime = ((videoAsset.duration.value/videoAsset.duration.timescale) + starting + ending) - 5.0; //video is 10 seconds longer - start fade at 5 before end
//        fadeOutroAnimation.beginTime = beginTime;
//        fadeOutroAnimation.duration = 0.5;
//        fadeOutroAnimation.fillMode = kCAFillModeBoth;
//        [overlayOutroLayer addAnimation:fadeOutroAnimation forKey:nil];
//        
//        
//        mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool
//                                     videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
//        
//        // 5 - Create exporter
//        
//        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
//                                                                          presetName:AVAssetExportPreset1920x1080];
//        exporter.outputURL = finishedUrl;
//        exporter.outputFileType = AVFileTypeQuickTimeMovie;
//        //exporter set
//        
//        //exporter.audioMix = audioMix;
//        exporter.shouldOptimizeForNetworkUse = NO;
//        exporter.videoComposition = mainCompositionInst;
//        [exporter exportAsynchronouslyWithCompletionHandler:^{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                
//                [app stopAnimating];
//                [self exportDidFinish:exporter details:details length:totalLength width:width height:height];
//            });
//        }];
    });
}

//- (void)exportDidFinish:(AVAssetExportSession*)session details:(NSDictionary *)details length:(NSString *)length width:(NSString *)width height:(NSString *)height{
//    
//    if(session.error){
//        
//        NSLog(@"it is error in exportDidFinish %@ ",session.error.description);
//        //auto try again
//        AppDelegate *app = (AppDelegate *)[NSApp delegate];
//        //[app getReadyAndUpload:self];
//        
//    }
//    else if (session.status == AVAssetExportSessionStatusCompleted) {
//        NSURL *outputURL = session.outputURL;
//        NSLog(@"complete at %@",outputURL.path);
//        [self thumbnailAndUpload:details length:length width:width height:height];
//        //[self justUpload:details ];
//    }
//}





@end
