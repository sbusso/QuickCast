//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVCaptureOutput.h>
#import "DrawMouseBoxView.h"
#import <SGHotKey.h>
#import <Growl/Growl.h>

extern NSString *kGlobalHotKey;

@class AVCaptureSession, AVCaptureScreenInput, AVCaptureMovieFileOutput, AVCaptureDeviceInput;

@interface AppDelegate : NSObject <NSApplicationDelegate,AVCaptureFileOutputDelegate,AVCaptureFileOutputRecordingDelegate,DrawMouseBoxViewDelegate,GrowlApplicationBridgeDelegate>{
    
    BOOL loggedIn;
    NSStatusItem *statusItem;
    BOOL retina;
    SGHotKey *hotKey;
    BOOL reachable;
    
    NSString *countdownNumberString;
    AVCaptureAudioDataOutput *audioDataOutput;
}

#pragma mark - Hotkeys
@property (nonatomic, retain) SGHotKey *hotKey;

#pragma mark Constants

FOUNDATION_EXPORT NSString *const MoviePath;

#pragma mark Preview Panel

@property (weak) IBOutlet NSButton *stopRecordingButton;
- (IBAction)stopRecordingClick:(id)sender;
@property (weak) IBOutlet NSView *previewView;
@property (unsafe_unretained) IBOutlet NSPanel *previewPanel;

#pragma mark Countdown
@property (weak) IBOutlet NSView *countdownView;


@property (weak) IBOutlet NSTextField *countdownNumber;


#pragma mark Actions

- (IBAction)startRecording:(id)sender;

@property (strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (strong) AVCaptureSession *captureSession;
@property (strong) AVCaptureScreenInput *captureScreenInput;
@property (strong) AVCaptureDeviceInput *captureAudioInput;
@property (weak) IBOutlet NSMenu *statusMenu;

#pragma mark Preview Panel
@property (weak) IBOutlet NSView *closeButtonView;
@property (weak) IBOutlet NSView *mirrorView;
@property (weak) IBOutlet NSView *resizeView;

#pragma mark Menu Items

@property (weak) IBOutlet NSMenuItem *recordItem;
@property (weak) IBOutlet NSMenuItem *myQuickCastsItem;
@property (weak) IBOutlet NSMenuItem *showInFinderItem;
@property (weak) IBOutlet NSMenuItem *signInItem;
@property (weak) IBOutlet NSMenuItem *quitItem;


- (IBAction)previewCloseClick:(id)sender;

- (IBAction)recordClick:(id)sender;
- (IBAction)myQuickCastsClick:(id)sender;
- (IBAction)showInFinderClick:(id)sender;
- (IBAction)signInClick:(id)sender;
- (IBAction)quitClick:(id)sender;
- (IBAction)mirrorButtonClick:(id)sender;


#pragma mark General Methods

- (void)updateSelectedDisplay:(NSString *)screenName;
- (void)setDisplayAndCropRect;
- (void)setFullScreen;
- (void)updateSelectedAudioDevice:(NSString *)audioDeviceName;
- (void)toggleCamera:(BOOL)on;
- (void)startCountdown;
- (void)goToSignIn:(BOOL)uploading;
- (void)goToSignUp:(BOOL)uploading;
- (void)completeLogIn:(BOOL)uploading;
- (void)complete:(NSString *)castId filesize:(NSString *)videoFilesize length:(NSString *)videoLength width:(NSString *)videoWidth height:(NSString *)videoHeight;
- (void)metaOk;
- (void)goToPublish;

#pragma mark General Variables

@property BOOL loggedIn;
@property (strong) NSStatusItem *statusItem;
@property BOOL retina;
@property (strong) NSView *invisibleView;
@property BOOL reachable;
@property (strong) NSString *countdownNumberString;


@end