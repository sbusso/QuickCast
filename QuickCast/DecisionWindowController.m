//
//  DecisionWindowController.m
//  QuickCast
//
//  Created by Pete Nelson on 29/07/2013.
//  Copyright (c) 2013 Reissued Ltd. All rights reserved.
//

#import "DecisionWindowController.h"
#import "AppDelegate.h"
#import "FFMPEGEngine.h"

@interface DecisionWindowController ()

@end

@implementation DecisionWindowController

- (id)initWithWindow:(NSWindow *)window{
    
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad{
    
    [super windowDidLoad];
    [_publishButton setEnabled:NO];
    [_progress startAnimation:self];
    
    
}

- (void)compress{
    
    [self completedProcessing:NO];
    NSString *input = [[NSHomeDirectory() stringByAppendingPathComponent:MoviePath] stringByAppendingPathComponent:@"quickcast.mov"];
    NSString *output = [[NSHomeDirectory() stringByAppendingPathComponent:MoviePath] stringByAppendingPathComponent:@"quickcast-compressed.mp4"];
    NSError *error;
    // Delete any existing movie file first
    if ([[NSFileManager defaultManager] fileExistsAtPath:output]){
        
        if (![[NSFileManager defaultManager] removeItemAtPath:output error:&error]){
            NSLog(@"Error deleting compressed movie %@",[error localizedDescription]);
        }
    }
    
    FFMPEGEngine *engine = [[FFMPEGEngine alloc] init];
    NSString *err = [engine resizeVideo:input output:output width:0 height:0];
    [self completedProcessing:YES];
}

- (IBAction)previewButtonClick:(id)sender {
    NSString *quickcast = [[NSHomeDirectory() stringByAppendingPathComponent:MoviePath] stringByAppendingPathComponent:@"quickcast-compressed.mp4"];
    [[NSWorkspace sharedWorkspace] openFile:quickcast];
}

- (IBAction)publishButtonClick:(id)sender {
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    [app goToPublish];
}

- (IBAction)cancelButtonClick:(id)sender {
    
    [self.window orderOut:nil];
    
}

- (IBAction)recordAgainButtonClick:(id)sender {
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    [app startCountdown];
    [self.window orderOut:nil];
}

- (void)updateImage:image{
    
    self.previewImageView.image = image;
    [self.previewImageView setNeedsDisplay:YES];
    
}

- (void)completedProcessing:(BOOL)finished{
    
    if(finished)
    {
        _previewButton.title = @"Preview";
        [_previewButton setEnabled:YES];
        [_progress setHidden:YES];
        [_progress stopAnimation:self];
        [_publishButton setEnabled:YES];
        
    }
    else{
        _previewButton.title = @"Processing";
        [_previewButton setEnabled:NO];
        [_progress setHidden:NO];
        [_progress startAnimation:self];
        [_publishButton setEnabled:NO];
    }
}

@end
