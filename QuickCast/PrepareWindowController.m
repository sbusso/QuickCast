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

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self listDisplays];
    [self listAudioInputs];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *quickcastPath = [prefs objectForKey:@"quickcastSavePath"];
    
    if(quickcastPath.length > 0){
        
        [_pathControl setURL: [NSURL URLWithString: quickcastPath ]];
    }
    else{
        [_pathControl setURL: [NSURL URLWithString: [@"~/Movies/QuickCasts" stringByExpandingTildeInPath] ]];
    }
    
    NSEvent* (^handler)(NSEvent*) = ^(NSEvent *theEvent) {
        
        AppDelegate *app = (AppDelegate *)[NSApp delegate];
        NSWindow *targetWindow = theEvent.window;
        
        if (targetWindow != self.window) {
            return theEvent;
        }

        NSEvent *result = theEvent;
        //NSLog(@"event monitor: %@", theEvent);

        if (_recordPartWindowButton.state == NSOnState && theEvent.keyCode == 53) {
            [app setFullScreen];
            [_recordPartWindowButton setState:NSOffState];
            result = nil;
        }

        return result;
    };
    
    eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:handler];
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
    [prefs setObject:pathURL.path forKey:@"quickcastSavePath"];
    [prefs synchronize];
}

- (IBAction)chooseAudioDevice:(id)sender {
    
    NSString *key = [_availableAudioDevices titleOfSelectedItem];
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    [app updateSelectedAudioDevice:key];
    
}
@end
