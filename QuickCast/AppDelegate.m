//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "PrepareWindowController.h"
#import "QuickcastAPI.h"
#import "Utilities.h"
#import "TransparentWindow.h"
#import "VideoView.h"
#import "FinishWindowController.h"
#import "SignInWindowController.h"
#import "SignUpWindowController.h"
#import "DecisionWindowController.h"
#import "Analytics.h"
#import "ScreenDetails.h"
#import "LaunchAtLoginController.h"
#import <Carbon/Carbon.h>
#import <SGHotKeyCenter.h>
#import <Sparkle/Sparkle.h>
#import <Growl/Growl.h>
#import <Reachability.h>
#import "FFMPEGEngine.h"

@interface AVCaptureInput (ConvenienceMethodsCategory)

- (AVCaptureInputPort *)portWithMediaType:(NSString *)mediaType;

@end

NSString *kGlobalHotKey = @"Global Hot Key";


@implementation AVCaptureInput (ConvenienceMethodsCategory)

// Find the input port with the target media type
- (AVCaptureInputPort *)portWithMediaType:(NSString *)mediaType
{
	for (AVCaptureInputPort *p in [self ports]) {
		if ([[p mediaType] isEqualToString:mediaType])
			return p;
	}
	return nil;
}

@end


@implementation AppDelegate
{
    AVCaptureMovieFileOutput    *captureMovieFileOutput;
   
    PrepareWindowController *prepareWindowController;
    TransparentWindow *transparentWindow;
    FinishWindowController *finishWindowController;
    SignUpWindowController *signUpWindowController;
    SignInWindowController *signInWindowController;
    DecisionWindowController *decisionWindowController;
    
    NSView *numberView;
    NSTextField *numberTextField ;
    
    BOOL countdown;
    int counter;
    NSTimer *countdownTimer;
    
    NSInteger currentFrame;
    NSTimer* animTimer;
    
    // for camera preview
    AVCaptureSession *session;
    AVCaptureConnection *connection;
    
    CGDirectDisplayID selectedDisplay;
    NSString *selectedDisplayName;
    
    NSWindow *testWindow;
    NSWindow *counterDownerWindow;
    
    NSSize movieSize;
    
    BOOL mirrored;
    
    NSDictionary *completePublishParams;
    BOOL metaCompleted;
    NSString *latestUrl;
    
}

NSString *const MoviePath = @"Movies/QuickCast";

@synthesize loggedIn;
@synthesize statusItem;
@synthesize retina;
@synthesize hotKey;
@synthesize reachable;
@synthesize countdownNumberString;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    
    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:_statusMenu];
    
    NSImage* image = [NSImage imageNamed:@"default"];
    [statusItem setImage:image];
    [statusItem setHighlightMode:YES];
        
    NSImage* clickImage = [NSImage imageNamed:@"click"];
    [statusItem setAlternateImage:clickImage];
    
    // when we startup we decide if the user has a valid token already
    [self checkToken];
    //[self setFormValid:NO];
    
    
    [self setupFolder];
    
    [Analytics sharedAnalyticsWithSecret:@"z8me0tz0xmyir1xkp6gr"];
    
    // set launch at login
    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
    BOOL launch = [launchController launchAtLogin];
    
    if(!launch){
        [launchController setLaunchAtLogin:YES];
    }
    
    [[SGHotKeyCenter sharedCenter] unregisterHotKey:hotKey];
    SGKeyCombo *keyCombo = [SGKeyCombo keyComboWithKeyCode:12
                                                 modifiers:controlKey+cmdKey+optionKey];
	hotKey = [[SGHotKey alloc] initWithIdentifier:kGlobalHotKey keyCombo:keyCombo target:self action:@selector(stopRecordingKeys:)];
	[[SGHotKeyCenter sharedCenter] registerHotKey:hotKey];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if([prefs objectForKey:@"mirror"] != nil){
        
        NSString *mir = [prefs objectForKey:@"mirror"];
        if([mir isEqualToString:@"mirror"]){
            mirrored = YES;
        }
        else{
            mirrored = NO;
        }
    }
    else {
        mirrored = NO;
    }
    
    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
    NSString *growlPath = [[myBundle privateFrameworksPath]
                           stringByAppendingPathComponent:@"Growl.framework"];
    NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
    if (growlBundle && [growlBundle load]) {
        // Register ourselves as a Growl delegate
        [GrowlApplicationBridge setGrowlDelegate:self];
    } else {
        NSLog(@"Could not load Growl.framework");
    }
    
    Reachability* reach = [Reachability reachabilityWithHostname:@"quick.as"];
    
    reach.reachableBlock = ^(Reachability*reach)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            reachable = YES;
        });
    };
    
    reach.unreachableBlock = ^(Reachability*reach)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            reachable = NO;
        });
    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
    
    
}



- (void)stopRecordingKeys:(id)sender {
	if([_recordItem.title isEqualToString:@"Stop"]){
        [self finishRecord];
    }
}

#pragma mark - Capture

- (BOOL)createCaptureSession{
    
    /* Create a capture session. */
    self.captureSession = [[AVCaptureSession alloc] init];
	if ([self.captureSession canSetSessionPreset:AVCaptureSessionPresetHigh])
    {
        /* Specifies capture settings suitable for high quality video and audio output. */
		[self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];
        
    }
    
    ScreenDetails *main = [Utilities getMainDisplayDetails];
    selectedDisplay = main.screenId;
    selectedDisplayName = main.screenName;
    movieSize = main.screen.frame.size;
    
    self.captureScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:selectedDisplay];
    
    if ([self.captureSession canAddInput:self.captureScreenInput])
    {
        
        [self.captureSession addInput:self.captureScreenInput];
        
    }
    else
    {
        return NO;
    }
    
    //use the first device we come to in the list
    for (AVCaptureDevice *aud in [Utilities getAudioInputs]){
        
        NSError *error;
        
        self.captureAudioInput = [AVCaptureDeviceInput deviceInputWithDevice:aud error:&error];
        
        if ([self.captureSession canAddInput:self.captureAudioInput])
        {
            [self.captureSession addInput:self.captureAudioInput];
        }
        else
        {
            return NO;
        }
        
        //use first
        break;
    }
    
    /* Add a movie file output + delegate. */
    captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    [captureMovieFileOutput setDelegate:self];
    if ([self.captureSession canAddOutput:captureMovieFileOutput])
    {
        [self.captureSession addOutput:captureMovieFileOutput];
    }
    else
    {
        return NO;
    }
	
	/* Register for notifications of errors during the capture session so we can display an alert. */
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionRuntimeErrorDidOccur:) name:AVCaptureSessionRuntimeErrorNotification object:self.captureSession];
    
    return YES;
}

/*
 AVCaptureVideoPreviewLayer is a subclass of CALayer that you use to display
 video as it is being captured by an input device.
 
 You use this preview layer in conjunction with an AV capture session.
 */
//-(void)addCaptureVideoPreview
//{
//    /* Create a video preview layer. */
//	AVCaptureVideoPreviewLayer *videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
//    
//    /* Configure it.*/
//	[videoPreviewLayer setFrame:[[self.captureView layer] bounds]];
//	[videoPreviewLayer setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
//    
//    /* Add the preview layer as a sublayer to the view. */
//    [[self.captureView layer] addSublayer:videoPreviewLayer];
//    /* Specify the background color of the layer. */
//	[[self.captureView layer] setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
//}

/*
 An AVCaptureScreenInput's minFrameDuration is the reciprocal of its maximum frame rate.  This property
 may be used to request a maximum frame rate at which the input produces video frames.  The requested
 rate may not be achievable due to overall bandwidth, so actual frame rates may be lower.
 */
- (float)maximumScreenInputFramerate{
    
	Float64 minimumVideoFrameInterval = CMTimeGetSeconds([self.captureScreenInput minFrameDuration]);
	return minimumVideoFrameInterval > 0.0f ? 1.0f/minimumVideoFrameInterval : 0.0;
}

/* Set the screen input maximum frame rate. */
- (void)setMaximumScreenInputFramerate:(float)maximumFramerate{
    
	CMTime minimumFrameDuration = CMTimeMake(1, (int32_t)maximumFramerate);
    /* Set the screen input's minimum frame duration. */
	[self.captureScreenInput setMinFrameDuration:minimumFrameDuration];
    //[self.captureScreenInput setScaleFactor:2.0];
}

/* Add a display as an input to the capture session. */
-(void)addDisplayInputToCaptureSession:(CGDirectDisplayID)newDisplay cropRect:(CGRect)cropRect{
    
    /* Indicates the start of a set of configuration changes to be made atomically. */
    [self.captureSession beginConfiguration];
    
    /* Is this display the current capture input? */
   // if ( newDisplay != selectedDisplay )
    //{
        /* Display is not the current input, so remove it. */
        [self.captureSession removeInput:self.captureScreenInput];
        AVCaptureScreenInput *newScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:newDisplay];
    
        self.captureScreenInput = newScreenInput;
    
        if ( [self.captureSession canAddInput:self.captureScreenInput] )
        {
            /* Add the new display capture input. */
            [self.captureSession addInput:self.captureScreenInput];
        }
    
        [self setMaximumScreenInputFramerate:[self maximumScreenInputFramerate]];
    //}
    /* Set the bounding rectangle of the screen area to be captured, in pixels. */
    [self.captureScreenInput setCropRect:cropRect];
    
    /* Commits the configuration changes. */
    [self.captureSession commitConfiguration];
}


/* Informs the delegate when all pending data has been written to the output file. */
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    
    if (error)
    {
        NSLog(@"Error: %@",error.description);
		return;
    }
    
    [decisionWindowController completedProcessing:NO];
    //[self resizeVideo:[NSHomeDirectory() stringByAppendingPathComponent:MoviePath]];
    
    NSString *input = [[NSHomeDirectory() stringByAppendingPathComponent:MoviePath] stringByAppendingPathComponent:@"quickcast.mov"];
    NSString *output = [[NSHomeDirectory() stringByAppendingPathComponent:MoviePath] stringByAppendingPathComponent:@"quickcast-compressed.mov"];
    // Delete any existing movie file first
    if ([[NSFileManager defaultManager] fileExistsAtPath:output]){
        
        if (![[NSFileManager defaultManager] removeItemAtPath:output error:&error]){
            NSLog(@"Error deleting compressed movie %@",[error localizedDescription]);
        }
    }
    FFMPEGEngine *engine = [[FFMPEGEngine alloc] init];
    NSString *err = [engine resizeVideo:input output:output width:movieSize.width height:movieSize.height];
    
    [self.captureSession stopRunning];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // prepare thumb for finish window
        NSString *quickcast = [[NSHomeDirectory() stringByAppendingPathComponent:MoviePath] stringByAppendingPathComponent:@"quickcast.mov"];
          
        finishWindowController = [[FinishWindowController alloc] initWithWindowNibName:@"FinishWindowController"];
        decisionWindowController = [[DecisionWindowController alloc] initWithWindowNibName:@"DecisionWindowController"];
        
        if(movieSize.height < 300 || movieSize.width < 300)
            [finishWindowController setMicroVideo:YES];
        else
            [finishWindowController setMicroVideo:NO];
        
        [finishWindowController setWidth:[NSString stringWithFormat:@"%0.0f", round(movieSize.width)]];
        [finishWindowController setHeight:[NSString stringWithFormat:@"%0.0f", round(movieSize.height)]];
        
        [decisionWindowController.window setLevel: NSNormalWindowLevel];
        [decisionWindowController.window makeKeyAndOrderFront:nil];
        
        // Ensure is at the front
        [NSApp activateIgnoringOtherApps:YES];    
        [_previewPanel orderOut:nil];
            
        
        NSImage *thumb = [Utilities thumbnailImageForVideo:[NSURL fileURLWithPath:quickcast] atTime:(NSTimeInterval)0.5];
        [thumb setScalesWhenResized:YES];
        
        // Report an error if the source isn't a valid image
        if (![thumb isValid])
        {
            NSLog(@"Invalid Image");
        }
        else
        {
            NSSize newSize = [Utilities resize:thumb.size withMax:200];
            NSString *thumbPath = [self saveThumbnail:newSize thumb:thumb suffix:@"_form"];
            
            NSImage *image = [[NSImage alloc] initWithContentsOfFile:thumbPath];
            
            dispatch_async(dispatch_get_main_queue(),^ {
                
                [decisionWindowController updateImage:image];
                
            });
            
            
        }
    });
    
    
}

- (BOOL)captureOutputShouldProvideSampleAccurateRecordingStart:(AVCaptureOutput *)captureOutput{
    
	// We don't require frame accurate start when we start a recording. If we answer YES, the capture output
    // applies outputSettings immediately when the session starts previewing, resulting in higher CPU usage
    // and shorter battery life.
	return NO;
}

- (void)updateSelectedAudioDevice:(NSString *)audioDeviceName{

    [self.captureSession beginConfiguration];
    
    if([audioDeviceName isEqualToString:@"No sound"]){
        
        [self.captureSession removeInput:self.captureAudioInput];
        
    }
    else{
        
        for (AVCaptureDevice *aud in [Utilities getAudioInputs]){
            
            if([aud.localizedName isEqualToString:audioDeviceName]){
                
                NSError *error;
                [self.captureSession removeInput:self.captureAudioInput];
                self.captureAudioInput = [AVCaptureDeviceInput deviceInputWithDevice:aud error:&error];
                
                if ([self.captureSession canAddInput:self.captureAudioInput])
                {
                    [self.captureSession addInput:self.captureAudioInput];
                }
            }
        }
        
    }
    
    [self.captureSession commitConfiguration];
    
}

- (void)toggleCamera:(BOOL)on{

    if(!on){
        if(_previewPanel){
            [_previewPanel orderOut:nil];
            [session stopRunning];
            
        }
    }
    else{
        if(_previewPanel){
            [_previewPanel makeKeyAndOrderFront:nil];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                
                session = [[AVCaptureSession alloc] init];
                // Set the session preset
                [session setSessionPreset:AVCaptureSessionPreset640x480];
                
                [self setupVideoPreview];
                
            });
        }
    }

}

- (void)goToPublish{
    
    if(reachable){
    
        if(decisionWindowController)
           [decisionWindowController.window orderOut:nil];
        
        // Finish Window Controller was instantiated when DecisionWindow was so is ready to go
        [finishWindowController.window setLevel: NSNormalWindowLevel];
        [finishWindowController.window makeKeyAndOrderFront:nil];
        [finishWindowController startUpload];
    }
    else{
        [GrowlApplicationBridge notifyWithTitle:@"No internet connection" description:@"Please try again when you have an internet connection" notificationName:@"Alert" iconData:nil priority:1 isSticky:NO clickContext:@"notify"];
    }
}

#pragma mark dealloc

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionRuntimeErrorNotification object:self.captureSession];
}


#pragma mark Crop Rect


/* Draws a crop rect on the display. */
- (void)drawMouseBoxView:(DrawMouseBoxView*)view didSelectRect:(NSRect)rect{
    
	/* Map point into global coordinates. */
    NSRect globalRect = rect;
    movieSize = rect.size;
    NSRect windowRect = [[view window] frame];
    globalRect = NSOffsetRect(globalRect, windowRect.origin.x, windowRect.origin.y);
	globalRect.origin.y = CGDisplayPixelsHigh(CGMainDisplayID()) - globalRect.origin.y;
	CGDirectDisplayID displayID = selectedDisplay;
	uint32_t matchingDisplayCount = 0;
    /* Get a list of online displays with bounds that include the specified point. */
	CGError e = CGGetDisplaysWithPoint(NSPointToCGPoint(globalRect.origin), 1, &displayID, &matchingDisplayCount);
	if ((e == kCGErrorSuccess) && (1 == matchingDisplayCount))
    {
        /* Add the display as a capture input. */
        [self addDisplayInputToCaptureSession:displayID cropRect:NSRectToCGRect(rect)];
    }
    
    if(testWindow)
       [testWindow orderOut:nil];
    
    transparentWindow = [[TransparentWindow alloc] initWithContentRect:windowRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    VideoView *video = [[VideoView alloc] init];
    
    transparentWindow.contentView = video;
    
    //for some reason in the wrong position vertically - probably the menu bar - this could well be 21 on a non retina mac - need to test
    //rect.origin.y = rect.origin.y - 42;
    [video setFrame:rect];
    [transparentWindow makeKeyAndOrderFront:nil];
    
	[[NSCursor currentCursor] pop];
}

/*
 Called when the user sets a Crop Rect for the display.
 
 First dims the display, then allows the user specify a rectangular
 area of the display to capture.
 */
- (void)setDisplayAndCropRect{
	
    // remove any overlay
    if(transparentWindow)
        [transparentWindow orderOut:nil];
    
    //get display from the one selected in the dropdown
    ScreenDetails *screenDetails = [Utilities getDisplayByName:prepareWindowController.availableScreens.selectedItem.title];
    NSRect frame = [screenDetails.screen frame];
    selectedDisplay = screenDetails.screenId;
    selectedDisplayName = screenDetails.screenName;
    
    testWindow = [[NSWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [testWindow setBackgroundColor:[NSColor blackColor]];
    [testWindow setAlphaValue:.5];
    [testWindow setLevel:NSScreenSaverWindowLevel + 1];
    [testWindow setReleasedWhenClosed:NO];
    DrawMouseBoxView* drawMouseBoxView = [[DrawMouseBoxView alloc] initWithFrame:frame];
    drawMouseBoxView.delegate = self;
    [testWindow setContentView:drawMouseBoxView];
    [testWindow makeKeyAndOrderFront:self];
	
	
	[[NSCursor crosshairCursor] push];
}

- (void)setFullScreen{
    
    ScreenDetails *screenDetails = [Utilities getDisplayByName:prepareWindowController.availableScreens.selectedItem.title];
    NSRect frame = [screenDetails.screen frame];
    movieSize = screenDetails.screen.frame.size;
    selectedDisplay = screenDetails.screenId;
    selectedDisplayName = screenDetails.screenName;
    if(transparentWindow)
        [transparentWindow orderOut:nil];
    
    if(testWindow)
        [testWindow orderOut:nil];
    
    if ([[NSCursor currentCursor] isEqual: [NSCursor crosshairCursor]]) {
        [[NSCursor currentCursor] pop];
    }
    
    [self addDisplayInputToCaptureSession:selectedDisplay cropRect:NSRectToCGRect(frame)];
}

- (void)captureSessionRuntimeErrorDidOccur:(NSNotification *)notification{
    
	NSError *error = [[notification userInfo] objectForKey:AVCaptureSessionErrorKey];
	if ([error localizedDescription]) {
		if ([error localizedFailureReason]) {
			NSRunAlertPanel(@"QuickCast Alert",
							[NSString stringWithFormat:@"%@\n\n%@", [error localizedDescription], [error localizedFailureReason]],
							nil, nil, nil);
		}
		else {
			NSRunAlertPanel(@"QuickCast Alert",
							[NSString stringWithFormat:@"%@", [error localizedDescription]],
							nil, nil, nil);
		}
	}
	else {
		NSRunAlertPanel(@"QuickCast Alert",
						@"An unknown error occured",
				 		nil, nil, nil);
	}
}

#pragma mark Start/Stop Button Actions

/* Called when the user presses the 'Start' button to start a recording. */
//- (IBAction)stopRecordingClick:(id)sender {
 //   [self finishRecord];
//}

- (IBAction)startRecording:(id)sender{
    
    NSString *quickcast = [[NSHomeDirectory() stringByAppendingPathComponent:MoviePath] stringByAppendingPathComponent:@"quickcast.mov"];
	
    // last minute set it
    ScreenDetails *sd = [Utilities getDisplayByName:selectedDisplayName];
    [self addDisplayInputToCaptureSession:sd.screenId cropRect:self.captureScreenInput.cropRect];
    /* Starts recording to a given URL. */
    [captureMovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:quickcast] recordingDelegate:self];
    [_recordItem setTitle:@"Stop"];
    
}

- (void)finishRecord{
    
    // show the controls on the preview layer ready for next video
    [_closeButtonView setHidden:NO];
    [_mirrorView setHidden:NO];
    [_resizeView setHidden:NO];
    
    [captureMovieFileOutput stopRecording];
    
    [_recordItem setTitle:@"Record"];
    [session stopRunning];
    
    [countdownTimer invalidate];
    countdownTimer = nil;
    [statusItem setTitle:@""];
    NSImage* image = [NSImage imageNamed:@"default"];
    [statusItem setImage:image];
    
    // if there is an overlay over the recording window then remove it as recording is over
    if(transparentWindow)
        [transparentWindow orderOut:nil];
}

- (void)checkToken{
    
    QuickcastAPI *api = [[QuickcastAPI alloc] init];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *token = [prefs objectForKey:@"token"];
    
    if (token){
        
        NSDictionary *params = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:token, nil] forKeys:[NSArray arrayWithObjects:@"token", nil]];
        
        [api userByToken:params completionHandler:^(NSDictionary *response, NSError *error, NSHTTPURLResponse * httpResponse) {
            
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSLog(@"Error: %@",error.description);
                    [self setLoggedIn:NO];
                    
                    [_myQuickCastsItem setEnabled:NO];
                    
                    
                });
                
                
            }
            else{
                
                //check http status
                if (httpResponse.statusCode == 200) {
                    
                    //call app delegate on the main thread
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setLoggedIn:YES];
                        NSDictionary *user = [response objectForKey:@"user" ];
                        if([response objectForKey:@"username" ] != [NSNull null]){
                            
                            NSString *username = [user objectForKey:@"username" ];
                            if([user objectForKey:@"username" ] != [NSNull null]){
                                
                                [_signInItem setTitle:[NSString stringWithFormat:@"Sign out: %@",username]];
                                
                                [self getCasts];
                            
                            }
                            
                        }
                        else{
                            [self setLoggedIn:NO];
                            
                            [_myQuickCastsItem setEnabled:NO];
                        }
                        
                        
                        
                    });
                    
                }
                else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"Error: %ld",(long)httpResponse.statusCode);
                        [self setLoggedIn:NO];
                        
                        [_myQuickCastsItem setEnabled:NO];
                    });
                    
                }
            }
            
        }];
    }
    else{
        [self setLoggedIn:NO];
        
        [_myQuickCastsItem setEnabled:NO];
    }
    
}

- (void)setupFolder{
    
    NSString *quickcast = [NSHomeDirectory() stringByAppendingPathComponent:MoviePath];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:quickcast])
        [[NSFileManager defaultManager] createDirectoryAtPath:quickcast withIntermediateDirectories:NO attributes:nil error:&error];
    
}

- (void)getCasts{
    
    QuickcastAPI *api = [[QuickcastAPI alloc] init];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *token = [prefs objectForKey:@"token"];
    
    if (token){
        
        NSDictionary *params = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:token, nil] forKeys:[NSArray arrayWithObjects:@"token", nil]];
        
        [api usercasts:params completionHandler:^(NSDictionary *response, NSError *error, NSHTTPURLResponse * httpResponse) {
            
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSLog(@"Error: %@",error.description);
                    
                    
                });
                
                
            }
            else{
                
                //check http status
                if (httpResponse.statusCode == 200) {
                    
                    //call app delegate on the main thread
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if([response objectForKey:@"casts"] != [NSNull null]){
                            NSDictionary *casts = [response objectForKey:@"casts"];
                            if([casts objectForKey:@"rows"] != [NSNull null]){
                                
                                NSDictionary *rows = [casts objectForKey:@"rows"];
                                if(rows.count == 0){
                                    [_myQuickCastsItem setEnabled:NO];
                                }
                                else{
                                    NSMenu *submenu = [[NSMenu alloc] init];
                                    for(NSDictionary *row in rows){
                                        
                                        NSString *castName = [row objectForKey:@"name"];
                                        NSString *uniqueId = [row objectForKey:@"uniqueid"];
                                        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:castName action:@selector(viewCast:) keyEquivalent:@""];
                                        [item setRepresentedObject:uniqueId];
                                        [submenu addItem:item];
                                        
                                    }
                                    
                                    [_myQuickCastsItem setSubmenu:submenu];
                                    [_myQuickCastsItem setEnabled:YES];
                                }
                                
                            }
                            else{
                                [_myQuickCastsItem setEnabled:NO];
                            }
                        }
                        else{
                            [_myQuickCastsItem setEnabled:NO];
                        }
                        
                        
                    });
                    
                }
                else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [_myQuickCastsItem setEnabled:NO];
                        NSLog(@"Error: %ld",(long)httpResponse.statusCode);
                    });
                    
                }
            }
            
        }];
    }
    else{
        [_myQuickCastsItem setEnabled:NO];
    }
    
}

- (void)viewCast:(id)sender{
    
    NSString *cast = [sender representedObject];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://quick.as/%@",cast]]];
    
}


#pragma mark menu clicks

- (IBAction)previewCloseClick:(id)sender {
    
    [_previewPanel orderOut:nil];
    [session stopRunning];
    
    if(prepareWindowController)
        [prepareWindowController.cameraOnButton setState:NSOffState];
}

- (IBAction)recordClick:(id)sender {
   
    if([((NSButton *)sender).title isEqualToString:@"Stop"]){
        [self finishRecord];
    }
    else{
        
        if(![prepareWindowController.window isVisible]){
            //ensure other windows are shut ready to record again
            if(decisionWindowController)
                [decisionWindowController.window orderOut:nil];
            
            if(finishWindowController)
                [decisionWindowController.window orderOut:nil];
            
            BOOL success = [self createCaptureSession];
            
            latestUrl = nil;
            //[self addCaptureVideoPreview];
            
            /* Start the capture session running. */
            [self.captureSession startRunning];
            
            NSString *quickcast = [[NSHomeDirectory() stringByAppendingPathComponent:MoviePath] stringByAppendingPathComponent:@"quickcast.mov"];
            
            // Delete any existing movie file first
            if ([[NSFileManager defaultManager] fileExistsAtPath:quickcast]){
                NSError *err;
                if (![[NSFileManager defaultManager] removeItemAtPath:quickcast error:&err]){
                    NSLog(@"Error deleting existing movie %@",[err localizedDescription]);
                }
            }
            
            prepareWindowController = [[PrepareWindowController alloc] initWithWindowNibName:@"PrepareWindowController"];
            [prepareWindowController.window setLevel: NSScreenSaverWindowLevel + 2];
            [prepareWindowController.window makeKeyAndOrderFront:nil];
            ScreenDetails *screenDetails = [Utilities getDisplayByName:prepareWindowController.availableScreens.selectedItem.title];
            [self setupCountdownWindow:screenDetails.screen];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                
                session = [[AVCaptureSession alloc] init];
                // Set the session preset
                [session setSessionPreset:AVCaptureSessionPreset640x480];
                
                [self setupVideoPreview];
                
            });
        }
    }
    
}

- (IBAction)myQuickCastsClick:(id)sender {
}

- (IBAction)showInFinderClick:(id)sender {
    
    NSString *quickcast = [NSHomeDirectory() stringByAppendingPathComponent:MoviePath];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString *quickcastPath = [prefs objectForKey:@"quickcastSavePath"];
    
    if(quickcastPath.length > 0){
        
        [[NSWorkspace sharedWorkspace] openFile: quickcastPath];
    }
    else{
        
        [[NSWorkspace sharedWorkspace] openFile: quickcast];
        
    }
    
}

- (IBAction)signInClick:(id)sender {
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if([((NSMenuItem *)sender).title isEqualToString:@"Sign In"]){
        //if token was not valid then open login
        if(!loggedIn){
            [self goToSignIn:NO];
        }
    }
    else{
        //they want to sign out
        [prefs setObject:nil forKey:@"token"];
        _signInItem.title = @"Sign In";
        [_myQuickCastsItem setEnabled:NO];
        [self setLoggedIn:NO];
    }
    
}

- (IBAction)quitClick:(id)sender {
    
    // Ensure captureSession is stopped
    if(self.captureSession.isRunning)
        [self.captureSession stopRunning];
    [[NSApplication sharedApplication] terminate:nil];
}

- (IBAction)mirrorButtonClick:(id)sender {
    
    [self switchMirror];
    
}

#pragma mark Displays

- (void)updateSelectedDisplay:(NSString *)screenName{
    
    // remove any overlay
    if(transparentWindow)
       [transparentWindow orderOut:nil];
    
    if(prepareWindowController)
       [prepareWindowController.recordPartWindowButton setState:NSOffState];
    
    ScreenDetails *sd = [Utilities getDisplayByName:screenName];
    selectedDisplay = sd.screenId;
    selectedDisplayName = sd.screenName;
    movieSize = sd.screen.frame.size;
    
    [self setupCountdownWindow:sd.screen];
    
    [self addDisplayInputToCaptureSession:selectedDisplay cropRect:NSRectToCGRect(NSZeroRect)];

}

#pragma mark Animation and Countdown

- (void)startCountdown{
    
    // hide the controls on the preview layer
    [_closeButtonView setHidden:YES];
    [_mirrorView setHidden:YES];
    [_resizeView setHidden:YES];
    
    counter = 5;
    countdown = YES;
    
    [counterDownerWindow makeKeyAndOrderFront:nil];
    [self setCountdownNumberString:[NSString stringWithFormat:@"%d",5]];
    
    
    numberTextField.stringValue = [NSString stringWithFormat:@"%d",5];
    [counterDownerWindow.contentView addSubview:numberTextField];
    //if(_finishWindow)
        //[_finishWindow  orderOut:nil];
    [prepareWindowController.window orderOut:nil];
    
    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(secondCount)
                                                    userInfo:nil
                                                     repeats:YES];
}


- (void)secondCount{
    
    counter--;
    
    if(countdown){
        
        //[_countdownNumber setStringValue:[NSString stringWithFormat:@"%d",counter]];
        [self setCountdownNumberString:[NSString stringWithFormat:@"%d",counter]];
        numberTextField.stringValue = [NSString stringWithFormat:@"%d",counter];
        if(counter == 0){
            
            [counterDownerWindow   orderOut:nil];
            
            [self startRecording:self];
            countdown = NO;
            counter = 180;
            [_stopRecordingButton setEnabled:YES];
            //get it ready for a rerecord
            //[_countdownNumber setStringValue:[NSString stringWithFormat:@"%d",5]];
            [self setCountdownNumberString:[NSString stringWithFormat:@"%d",5]];
        }
    }
    else{
        
        [statusItem setTitle:[Utilities minutesSeconds:counter]];
        
        if(counter < 10){
            NSImage* image = [NSImage imageNamed:@"red"];
            [statusItem setImage:image];
        }
        else{
            NSImage* image = [NSImage imageNamed:@"green"];
            [statusItem setImage:image];
        }
        
        if(counter == 0){
            
            [self finishRecord];
            
        }
    }
}

#pragma mark Capture Camera

- (NSMutableArray *)devicesThatCanProduceVideo{
    
	NSMutableArray *devices = [NSMutableArray array];
	for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
		if ([device hasMediaType:AVMediaTypeVideo] || [device hasMediaType:AVMediaTypeMuxed])
			[devices addObject:device];
	}
	return devices;
}


- (BOOL)setupVideoPreview{
    
	NSError *error = nil;
	
	// Find video devices
	NSMutableArray *devices = [self devicesThatCanProduceVideo];
	NSInteger devicesCount = [devices count], currentDevice = 0;
	CGRect rootBounds = [_previewView.layer bounds];
	if (devicesCount == 0)
		return NO;
	
	// For each video device
	for (AVCaptureDevice *d in devices) {
		// Create a device input with the device and add it to the session
		AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:&error];
		if (error) {
			NSLog(@"deviceInputWithDevice: failed (%@)", error);
            return NO;
        }
		[session addInputWithNoConnections:input];
		
		// Find the video input port
		AVCaptureInputPort *videoPort = [input portWithMediaType:AVMediaTypeVideo];
		
		// Set up its corresponding square within the root layer
		CGRect deviceSquareBounds = CGRectMake(0, 0, rootBounds.size.width / devicesCount, rootBounds.size.height);
		deviceSquareBounds.origin.x = deviceSquareBounds.size.width * currentDevice;
		
		
        // Create a video preview layer with the session
        AVCaptureVideoPreviewLayer *videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSessionWithNoConnection:session];
        
        // and add it to the session
        connection = [AVCaptureConnection connectionWithInputPort:videoPort videoPreviewLayer:videoPreviewLayer];
        [session addConnection:connection];
        
        [CATransaction begin];
        // Disable implicit animations for this transaction
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        
        [videoPreviewLayer setFrame:[_previewView.layer bounds]];
        [videoPreviewLayer setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
        
        [connection setAutomaticallyAdjustsVideoMirroring:NO];
        [connection setVideoMirrored:mirrored];
        // Save the frame in an array for the "sendLayersHome" animation
        //[_homeLayerRects addObject:[NSValue valueWithRect:NSRectFromCGRect(curLayerFrame)]];
        
        // We want the video content to always fill the entire layer regardless of the layer size,
        // so set video gravity to ResizeAspectFill
        [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        [session startRunning];
        [CATransaction commit];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [_previewView.layer addSublayer:videoPreviewLayer];
            
            // now re-add the close button and resize handle above to ensure in front
            // also need to do auto layout by code as we will have lost the IB autolayout
            NSRect resizeFrame = _resizeView.frame;
            [_resizeView removeFromSuperview];
            [_previewPanel.contentView addSubview:_resizeView positioned:NSWindowAbove relativeTo:nil];
            [_resizeView setFrame:resizeFrame];
        
            // right
            [_previewPanel.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_resizeView]-0-|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(_resizeView)]];
            
            // bottom
            [_previewPanel.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_resizeView]-0-|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(_resizeView)]];
            
            NSRect closeFrame = _closeButtonView.frame;
            [_closeButtonView removeFromSuperview];
            [_previewPanel.contentView addSubview:_closeButtonView positioned:NSWindowAbove relativeTo:nil];
            [_closeButtonView setFrame:closeFrame];
            
            // left
            [_previewPanel.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_closeButtonView]"
                                                                                              options:0
                                                                                              metrics:nil
                                                                                                views:NSDictionaryOfVariableBindings(_closeButtonView)]];
            
            // top
            [_previewPanel.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_closeButtonView]"
                                                                                              options:0
                                                                                              metrics:nil
                                                                                                views:NSDictionaryOfVariableBindings(_closeButtonView)]];
            
            NSRect mirrorFrame = _mirrorView.frame;
            [_mirrorView removeFromSuperview];
            [_previewPanel.contentView addSubview:_mirrorView positioned:NSWindowAbove relativeTo:nil];
            [_mirrorView setFrame:mirrorFrame];
            // right
            [_previewPanel.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_mirrorView]-5-|"
                                                                                              options:0
                                                                                              metrics:nil
                                                                                                views:NSDictionaryOfVariableBindings(_mirrorView)]];
            
            // top
            [_previewPanel.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[_mirrorView]"
                                                                                              options:0
                                                                                              metrics:nil
                                                                                                views:NSDictionaryOfVariableBindings(_mirrorView)]];
            
            
            [prepareWindowController.window setLevel: NSScreenSaverWindowLevel + 2];
            [_previewPanel setLevel: NSScreenSaverWindowLevel + 2];
            [_previewPanel makeKeyAndOrderFront:nil];
        });
			
		//}
		currentDevice++;
        
        //just use camera 1 for now - we can add a camera selector later
        break;
	}
	
	return YES;
}

- (void)switchMirror{
    
    mirrored = !mirrored;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:(mirrored ? @"mirror" : @"nomirror") forKey:@"mirror"];
    [prefs synchronize];
    
    [CATransaction begin];
    if (mirrored){
        [connection setAutomaticallyAdjustsVideoMirroring:NO];
        [connection setVideoMirrored:YES];
    }
    else{
        [connection setAutomaticallyAdjustsVideoMirroring:NO];
        [connection setVideoMirrored:NO];
    }
    
    [CATransaction commit];
}

#pragma mark Thumbnail

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

#pragma mark Sign In/Sign Up

- (void)goToSignIn:(BOOL)uploading{
    
    signInWindowController = [[SignInWindowController alloc] initWithWindowNibName:@"SignInWindowController"];
    [signInWindowController.window setLevel: NSModalPanelWindowLevel];
    [signInWindowController setUploading:uploading];
    [signInWindowController.window makeKeyAndOrderFront:nil];
}

- (void)goToSignUp:(BOOL)uploading{
    
    signUpWindowController = [[SignUpWindowController alloc] initWithWindowNibName:@"SignUpWindowController"];
    [signUpWindowController.window setLevel: NSModalPanelWindowLevel];
    [signUpWindowController setUploading:uploading];
    [signUpWindowController.window makeKeyAndOrderFront:nil];
}

- (void)completeLogIn:(BOOL)uploading{
    
    if(uploading && finishWindowController)
        [finishWindowController startUpload];
    
    [self checkToken];
}

#pragma mark Complete Upload

- (void)metaOk{
    
    metaCompleted = YES;
    
    // Whatever hits first will complete the process - the upload or the form submit
    if(completePublishParams != nil){
        [self markUploadCompleted];
    }
    
}

- (void)complete:(NSString *)castId filesize:(NSString *)videoFilesize length:(NSString *)videoLength width:(NSString *)videoWidth height:(NSString *)videoHeight{
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *token = [prefs objectForKey:@"token"];
    
    if (token){
        
        completePublishParams = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:token,castId,videoFilesize,videoLength,videoWidth,videoHeight, nil] forKeys:[NSArray arrayWithObjects:@"token",@"castId",@"size",@"length",@"width",@"height", nil]];
        
        // Whatever hits first will complete the process - the upload or the form submit
        if(metaCompleted){
            [self markUploadCompleted];
        }
    }
    
}

- (void) growlNotificationWasClicked:(id)clickContext{
    
    if(latestUrl.length > 0)
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:latestUrl]];
}

- (void)markUploadCompleted{
    
    QuickcastAPI *api = [[QuickcastAPI alloc] init];
    [api castPublishComplete:completePublishParams completionHandler:^(NSDictionary *response, NSError *error, NSHTTPURLResponse * httpResponse) {
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSLog(@"Error: %@",error.description);
                //[_record setEnabled:YES];
                //[_record setTitle:@"Record"];
            });
            
            
        }
        else{
            
            //check http status
            if (httpResponse.statusCode == 200) {
                
                //call app delegate on the main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    latestUrl = [response objectForKey:@"url"];
                    //[/[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
                    //[finishWindowController setComplete:url];
                    //rebind the list of latest onto the app
                    [self getCasts];
                    completePublishParams = nil;
                    metaCompleted = NO;
                    
                    //NSData *notifyIcon = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"icon_notify"]];
                    [GrowlApplicationBridge notifyWithTitle:@"QuickCast Published" description:[NSString stringWithFormat:@"Your QuickCast is ready at %@. Click here to view",latestUrl] notificationName:@"Alert" iconData:nil priority:1 isSticky:NO clickContext:@"notify"];
                    
                    _recordItem.title = @"Record";
                    [_recordItem setEnabled:YES];
                    
                    //set back to starting point
                    //[_record setEnabled:YES];
                    //[_record setTitle:@"Record"];
                    
                    //if(finishWindowController.window)
                    //[finishWindowController.window orderOut:nil];
                    
                });
                
            }
            else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSLog(@"errir finish publish");
                    ////[_record setEnabled:YES];
                    //[_record setTitle:@"Record"];
                });
                
            }
        }
        
    }];


}

-(void)resizeVideo:(NSString*)pathy{
    
    NSURL *fullPath = [NSURL fileURLWithPath:[pathy stringByAppendingPathComponent:@"quickcast-compressed.mov"]];
    
    // Delete any existing movie file first
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath.path]){
        NSError *err;
        if (![[NSFileManager defaultManager] removeItemAtPath:fullPath.path error:&err]){
            NSLog(@"Error deleting compressed movie %@",[err localizedDescription]);
        }
    }
    
    NSURL *path = [NSURL fileURLWithPath:[pathy stringByAppendingPathComponent:@"quickcast.mov"]];
    
    
    NSError *error = nil;
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:fullPath fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    AVAsset *avAsset = [[AVURLAsset alloc] initWithURL:path options:nil] ;
    
    
    //work out size
    AVAssetTrack *videoAssetTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    CGSize naturalSize;
    naturalSize = videoAssetTrack.naturalSize;
    NSSize smallerSize = movieSize;
    NSLog(@"the width is %f and the height is %f",smallerSize.width, smallerSize.height);
    
    //NSSize testSize = retina ? [Utilities resize:NSMakeSize(naturalSize.width/2, naturalSize.height/2) withMax:1280]  : [Utilities resize:NSMakeSize(naturalSize.width, naturalSize.height) withMax:1280];
    
    
    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithFloat:smallerSize.width], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithFloat:smallerSize.height], AVVideoCleanApertureHeightKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureHorizontalOffsetKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureVerticalOffsetKey,
                                                nil];
    
    
    NSDictionary *codecSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:18960000], AVVideoAverageBitRateKey,
                                   [NSNumber numberWithInt:24],AVVideoMaxKeyFrameIntervalKey,
                                   videoCleanApertureSettings, AVVideoCleanApertureKey,
                                   nil];
    
    
    
    NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              codecSettings,AVVideoCompressionPropertiesKey,
                                              [NSNumber numberWithFloat:smallerSize.width], AVVideoWidthKey,
                                              [NSNumber numberWithFloat:smallerSize.height], AVVideoHeightKey,
                                              nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoCompressionSettings];
    
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];
    NSError *aerror = nil;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:avAsset error:&aerror];
    AVAssetTrack *videoTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
    
    videoWriterInput.transform = videoTrack.preferredTransform;
    NSDictionary *videoOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    AVAssetReaderTrackOutput *asset_reader_output = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:videoOptions];
    [reader addOutput:asset_reader_output];
    //audio setup
    
    AVAssetWriterInput* audioWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeAudio
                                            outputSettings:nil];
    
    
    AVAssetReader *audioReader = [AVAssetReader assetReaderWithAsset:avAsset error:&error];
    AVAssetTrack* audioTrack = [[avAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVAssetReaderOutput *readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
    
    [audioReader addOutput:readerOutput];
    NSParameterAssert(audioWriterInput);
    NSParameterAssert([videoWriter canAddInput:audioWriterInput]);
    audioWriterInput.expectsMediaDataInRealTime = NO;
    [videoWriter addInput:audioWriterInput];
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    [reader startReading];
    dispatch_queue_t _processingQueue = dispatch_queue_create("assetAudioWriterQueue", NULL);
    [videoWriterInput requestMediaDataWhenReadyOnQueue:_processingQueue usingBlock:
     ^{
         while ([videoWriterInput isReadyForMoreMediaData]) {
             
             CMSampleBufferRef sampleBuffer;
             if ([reader status] == AVAssetReaderStatusReading &&
                 (sampleBuffer = [asset_reader_output copyNextSampleBuffer])) {
                 
                 BOOL result = [videoWriterInput appendSampleBuffer:sampleBuffer];
                 CFRelease(sampleBuffer);
                 
                     if (!result) {
                     // PROBLEM SEEMS TO BE HERE... result is getting false value....
                     [reader cancelReading];
                     NSLog(@"NO RESULT");
                     NSLog(@"videoWriter.error: %@", videoWriter.error);
                     break;
                 }
             } else {
                 [videoWriterInput markAsFinished];
                 
                 switch ([reader status]) {
                     case AVAssetReaderStatusReading:
                         // the reader has more for other tracks, even if this one is done
                         break;
                         
                     case AVAssetReaderStatusCompleted:
                         // your method for when the conversion is done
                         // should call finishWriting on the writer
                         //hook up audio track
                         [audioReader startReading];
                         [videoWriter startSessionAtSourceTime:kCMTimeZero];
                         // dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
                         // [audioWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:^
                         //{
                         NSLog(@"Request");
                         NSLog(@"Asset Writer ready :%d",audioWriterInput.readyForMoreMediaData);
                         while (audioWriterInput.readyForMoreMediaData) {
                             CMSampleBufferRef nextBuffer;
                             if ([audioReader status] == AVAssetReaderStatusReading &&
                                 (nextBuffer = [readerOutput copyNextSampleBuffer])) {
                                 NSLog(@"Ready");
                                 if (nextBuffer) {
                                     NSLog(@"NextBuffer");
                                     [audioWriterInput appendSampleBuffer:nextBuffer];
                                 }
                             }else{
                                 [audioWriterInput markAsFinished];
                                 switch ([audioReader status]) {
                                     case AVAssetReaderStatusCompleted:
                                         [videoWriter finishWriting];
                                         NSLog(@"setting  final... the URL");
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             
                                             [decisionWindowController completedProcessing:YES];
                                         });
                                        
                                         break;
                                 }
                             }
                             
                             
                         }
                         
                         break;
                         
                     case AVAssetReaderStatusFailed:
                         [videoWriter cancelWriting];
                         NSLog(@"failed writing");
                         break;
                 }
                 
                 break;
             }
         }
     }
     ];
    
}

- (void)setupCountdownWindow:(NSScreen *)scr{
    
    counterDownerWindow = [[NSWindow alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:scr];
    
    [counterDownerWindow    setLevel: NSScreenSaverWindowLevel + 1];
    [_countdownView setFrame:NSMakeRect(0, 0, scr.frame.size.width, scr.frame.size.height)];
    
    numberView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, scr.frame.size.width, scr.frame.size.height)];
    [numberView addSubview:_countdownView];
    [numberView setWantsLayer:YES];
    [counterDownerWindow.contentView addSubview:numberView];
    [counterDownerWindow setFrame:scr.frame display:YES];
    [counterDownerWindow setBackgroundColor:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.7]];
    [counterDownerWindow setOpaque:NO];
    
    NSRect numberFrame = NSMakeRect(counterDownerWindow.frame.size.width/2 -60, counterDownerWindow.frame.size.height/2 -75, 200, 200);
    // Was not updating properly on slower machines so adding this programatically
    numberTextField = [[NSTextField alloc] initWithFrame:numberFrame];
    [numberTextField setBordered:NO];
    [numberTextField setBackgroundColor:[NSColor clearColor]];
    [numberTextField setTextColor:[NSColor whiteColor]];
    [numberTextField setAlphaValue:0.6];
    [numberTextField setFont:[NSFont fontWithName:@"HelveticaNeue" size:200]];
    
}

@end

