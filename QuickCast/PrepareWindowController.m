//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import "PrepareWindowController.h"
#import <IOKit/graphics/IOGraphicsLib.h>
#import "AppDelegate.h"
#import "Utilities.h"
#import "ScreenDetails.h"
#import <AVFoundation/AVFoundation.h>

@interface PrepareWindowController ()

@end

@implementation PrepareWindowController{
    
    NSArray *displays;
    NSArray *audioInputs;
    
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    
    if (self) {
        
    }
    
    return self;
}

//if (audioLevelTimer)
//[audioLevelTimer invalidate];

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self listDisplays];
    [self listAudioInputs];
    
    //select the default audio input
    [_availableAudioDevices selectItemWithTitle:[Utilities defaultAudioInputName]];
    [_availableScreens selectItemWithTitle:[Utilities getMainDisplayDetails].screenName];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *quickcastPath = [prefs objectForKey:@"quickcastNewSavePath"];
    
    if(quickcastPath.length > 0)
    {
        [_pathControl setURL: [NSURL fileURLWithPath: quickcastPath ]];
    }
    else
    {
        [_pathControl setURL: [NSURL fileURLWithPath: [NSHomeDirectory() stringByAppendingPathComponent:MoviePath] ]];
    }
    
    // Registers the esc key to cancel screen selection
    NSEvent* (^handler)(NSEvent*) = ^(NSEvent *theEvent) {
        
        AppDelegate *app = (AppDelegate *)[NSApp delegate];
        NSWindow *targetWindow = theEvent.window;
        
        if (targetWindow != self.window) {
            return theEvent;
        }

        NSEvent *result = theEvent;

        if (_recordPartWindowButton.state == NSOnState && theEvent.keyCode == 53) {
            [app setFullScreen];
            [_recordPartWindowButton setState:NSOffState];
            result = nil;
        }

        return result;
    };
    
    eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:handler];
    
    // setup audio level timer
    audioLevelTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateAudioLevels:) userInfo:nil repeats:YES];
}

#pragma mark UI updating

- (void)updateAudioLevels:(NSTimer *)timer
{
	NSInteger channelCount = 0;
    float decibels = 0.f;
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    
    NSArray *connections = app.audioDataOutput.connections;
    if ([connections count] > 0) {
        // There should be only one connection to an AVCaptureAudioDataOutput.
        AVCaptureConnection *connection = [connections objectAtIndex:0];
        
        NSArray *audioChannels = connection.audioChannels;
        
        for (AVCaptureAudioChannel *channel in audioChannels) {
            decibels = channel.averagePowerLevel;
            //float peak = channel.peakHoldLevel;
            // Update the level meter user interface.
            
        }
    }
    //NSLog(@"decibels is %f",decibels);
    //NSLog(     @"power is %f",pow(10.f, 0.05f * decibels) * 20.0f  );
    [[self audioLevelIndicator] setFloatValue:(pow(10.f, 0.05f * decibels) * 20.0f)];
    
	
}

- (void)windowWillClose:(NSNotification *)notification {
    
    //kill the timer
    [audioLevelTimer invalidate];
    audioLevelTimer = nil;
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    [app toggleCamera:NO];
    [app setFullScreen];
    
}

- (void)listDisplays
{
    
    if(!displays)
        displays = [NSArray array];
    
    displays = [Utilities getDisplays];
    for(ScreenDetails *sd in displays)
    {
        [_availableScreens addItemWithTitle:sd.screenName];
    }
    
}

- (void)listAudioInputs
{
    
    if(!audioInputs)
        audioInputs = [NSArray array];
    
    audioInputs = [Utilities getAudioInputs];
    
    for (AVCaptureDevice *device in audioInputs) {
    
        [_availableAudioDevices addItemWithTitle:device.localizedName];
    }
    
    [_availableAudioDevices addItemWithTitle:@"No sound"];
    
}

- (IBAction)cameraOnClick:(id)sender {
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    
    if(((NSButton *)sender).state == NSOnState){
        
        [app toggleCamera:YES];
    }
    else{
        
        [app toggleCamera:NO];
    }
}

- (IBAction)recordPartOfScreenClick:(id)sender {
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    
    if(((NSButton *)sender).state == NSOnState){
        [app setDisplayAndCropRect];
    }
    else{
        
        [app setFullScreen];
    }
    
}

- (IBAction)chooseScreenClick:(id)sender {
    
    NSString *key = [_availableScreens titleOfSelectedItem];
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    [app updateSelectedDisplay:key];
    
}

- (IBAction)startCountdownClick:(id)sender {
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    [app startCountdown];
}

- (IBAction)selectPath:(id)sender {
    
    NSURL *pathURL = [_pathControl URL];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:pathURL.path forKey:@"quickcastNewSavePath"];
    [prefs synchronize];
}

- (IBAction)chooseAudioDevice:(id)sender {
    
    NSString *key = [_availableAudioDevices titleOfSelectedItem];
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    [app updateSelectedAudioDevice:key];
    
}
@end
