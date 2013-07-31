//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import <Cocoa/Cocoa.h>

@interface PrepareWindowController : NSWindowController<NSWindowDelegate> {
    id eventMonitor;
    
    NSTimer	*audioLevelTimer;
}

- (IBAction)recordSoundClick:(id)sender;
- (IBAction)cameraOnClick:(id)sender;
- (IBAction)recordPartOfScreenClick:(id)sender;
- (IBAction)chooseScreenClick:(id)sender;
- (IBAction)startCountdownClick:(id)sender;
- (IBAction)selectPath:(id)sender;
- (IBAction)chooseAudioDevice:(id)sender;



@property (strong) IBOutlet NSLevelIndicator *audioLevelIndicator;

@property (strong) IBOutlet NSPopUpButton *availableScreens;
@property (strong) IBOutlet NSButton *startCountdownButton;
@property (strong) IBOutlet NSButton *recordPartWindowButton;
@property (strong) IBOutlet NSPathControl *pathControl;
@property (strong) IBOutlet NSButton *cameraOnButton;
@property (strong) IBOutlet NSPopUpButton *availableAudioDevices;

@end
