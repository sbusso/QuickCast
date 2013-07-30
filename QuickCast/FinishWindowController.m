//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import "FinishWindowController.h"
#import "AppDelegate.h"
#import "QuickcastAPI.h"
#import "Analytics.h"
#import "Exporter.h"
#import "MMMarkdown.h"
#import <WebKit/WebKit.h>
#import "NSAttributedString_Hyperlink.h"

@interface FinishWindowController ()

@end

@implementation FinishWindowController{
    
    Exporter *exporter;
    BOOL uploadFailed;
    
}

@synthesize formIsValid;
@synthesize microVideo;
@synthesize width;
@synthesize height;

- (id)initWithWindow:(NSWindow *)window{
    
    self = [super initWithWindow:window];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(failed:)
                                                     name:@"FailedUploading"
                                                   object:nil];
        [self setMicroVideo:NO];
    }
    
    return self;
}

- (BOOL)isReadyForUpload{
    
    return _name.stringValue.length > 0
        && _multiline.string.length > 0
    && _agreeButton.state == NSOnState;

}

- (void)setComplete:(NSString *)url{
    
    //[_greenMessage setStringValue:@" "];
    [_greenMessage setHidden:NO];
}

- (void)setError:(NSString *)message{
    [_orangeMessage setStringValue:@"There was a problem with the upload"];
    [_orangeMessage setHidden:NO];
}

- (void)failed:(NSNotification *)note{
    
    [self.window makeKeyAndOrderFront:nil];
    
    NSAlert * alert = [NSAlert alertWithMessageText:@"Upload Failed"
                                      defaultButton:@"Try Again"
                                    alternateButton:nil
                                        otherButton:@"Cancel"
                          informativeTextWithFormat:@"The upload failed - would you like to try again"];
    
    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:@selector(failedDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
    
}

- (void)failedDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    
    if (returnCode == NSAlertDefaultReturn)
    {
        //retry in case never made it
        uploadFailed = YES;
        
    }
    else{
        [self.window orderOut:nil];
    }
}

- (void)windowDidLoad{
    
    [super windowDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange) name:NSControlTextDidChangeNotification object:_name];
    
    [self setFormIsValid:NO];
    
    [_message setHidden:YES];
    [_greenMessage setHidden:YES];
    [_orangeMessage setHidden:YES];
    
    if(microVideo){
        [_message setStringValue:@"Dimensions too small to have an intro or outro"];
        [_message setHidden:NO];
        [_messageImage setImage:[NSImage imageNamed:@"warning"]];
        
        CGFloat rFloat = 4/255.0;
        CGFloat gFloat = 164/255.0;
        CGFloat bFloat = 232/255.0;
        
        [_statusBlock setFillColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:0.04]];
        [_statusBlock setBorderColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:1.0]];
    }
    else{
        [_message setStringValue:@"Please complete the details below"];
        [_message setHidden:NO];
        [_messageImage setImage:[NSImage imageNamed:@"warning"]];
        
        CGFloat rFloat = 4/255.0;
        CGFloat gFloat = 164/255.0;
        CGFloat bFloat = 232/255.0;
        
        [_statusBlock setFillColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:0.04]];
        [_statusBlock setBorderColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:1.0]];
    }
    
}

-(void)textDidChange:(NSNotification *)notification{
    
    
    NSString *html = @"<html><head><link type=\"text/css\"  rel=\"stylesheet\" href=\"%@\"></head><body><div class=\"wrapper\"><div class=\"content watch\"><div class=\"detail\">%@</div></div></div></body></html>";
    
    NSBundle* myBundle = [NSBundle mainBundle];
    NSString* appCss = [myBundle pathForResource:@"app" ofType:@"css"];
    
    if([self isReadyForUpload]){
        
        [self setFormIsValid:YES];
        
    }
    else{
        [self setFormIsValid:NO];
    }
    
    // markdown stuff
    NSError  *error;
    NSString *markdown   = _multiline.string;
    NSURL *mainBundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    
    if(markdown.length > 0){
        
        NSString *htmlString = [MMMarkdown HTMLStringWithMarkdown:markdown error:&error];
        
        [self.preview.mainFrame loadHTMLString:[NSString stringWithFormat:html,appCss,htmlString] baseURL:mainBundleURL];
    }
    else{
        [self.preview.mainFrame loadHTMLString:@"" baseURL:mainBundleURL];
    }
}

- (void)textDidChange{
    
    if([self isReadyForUpload]){
        
        [self setFormIsValid:YES];
        
    }
    else{
        [self setFormIsValid:NO];
    }
}

- (void)startUpload{
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    
    if(!app.loggedIn){
        
        [app goToSignIn:YES];
        
    }
    else{
        
        QuickcastAPI *api = [[QuickcastAPI alloc] init];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        
        NSDictionary *params = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[prefs objectForKey:@"token"], nil] forKeys:[NSArray arrayWithObjects:@"token", nil]];
        
        [api castPublish:params completionHandler:^(NSDictionary *response, NSError *error, NSHTTPURLResponse * httpResponse) {
            
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
                        
                        NSDictionary *user = [response objectForKey:@"user"];
                        NSString *userId = [user objectForKey:@"id"];
                        [[Analytics sharedAnalytics] identify:userId traits:user];
                        [[Analytics sharedAnalytics] track:@"publish" properties:response];
                        exporter = [[Exporter alloc] init];
                        [exporter startUpload:response width:width height:height];
                        
                    });
                    
                }
                else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSLog(@"publish error");
                        
                    });
                    
                }
            }
            
        }];
        
    }

}

- (IBAction)publishClick:(id)sender{
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    
    if(!app.reachable){
        [GrowlApplicationBridge notifyWithTitle:@"No internet connection" description:@"Please try again when you have an internet connection" notificationName:@"Alert" iconData:nil priority:1 isSticky:NO clickContext:@"notify"];
        [self.window makeKeyAndOrderFront:nil];
    }
    
    else if([self isReadyForUpload]){
        
        //if it had previously failed, retry the upload here after form submit
        if(uploadFailed){
            [self startUpload];
            uploadFailed = NO;
        }
        
        [GrowlApplicationBridge notifyWithTitle:@"Publishing your QuickCast" description:@"We'll let you know as soon as it's ready." notificationName:@"Alert" iconData:nil priority:1 isSticky:NO clickContext:@"notify"];
        
        [self.window orderOut:nil];
        
        app.recordItem.title = @"Publishing";
        [app.recordItem setEnabled:NO];
        
        NSString *intro = _intro.stringValue;
        NSString *outro = _outro.stringValue;
        NSString *description = _multiline.string;
        NSString *name = _name.stringValue;
        NSString *tags = _tags.stringValue;
        
        NSString *castId = exporter.uploader.castId;
        
        QuickcastAPI *api = [[QuickcastAPI alloc] init];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        
        NSDictionary *params = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[prefs objectForKey:@"token"],castId,description,name,tags,intro,outro, nil] forKeys:[NSArray arrayWithObjects:@"token",@"castId",@"description",@"name",@"tags",@"intro",@"outro", nil]];
        
        [api castUpdate:params completionHandler:^(NSDictionary *response, NSError *error, NSHTTPURLResponse * httpResponse) {
            
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    CGFloat rFloat = 219/255.0;
                    CGFloat gFloat = 60/255.0;
                    CGFloat bFloat = 78/255.0;
                    
                    [_statusBlock setFillColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:0.04]];
                    [_statusBlock setBorderColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:1.0]];
                    
                    NSLog(@"Error: %@",error.description);
                    
                });
            }
            else{
                
                //check http status
                if (httpResponse.statusCode == 200) {
                    
                    //call app delegate on the main thread
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        
                        /*[_message setHidden:YES];
                        [_orangeMessage setHidden:YES];
                        [_greenMessage setHidden:NO];
                        [_messageImage setImage:[NSImage imageNamed:@"go"]];
                        
                        CGFloat rFloat = 61/255.0;
                        CGFloat gFloat = 173/255.0;
                        CGFloat bFloat = 114/255.0;
                        
                        [_statusBlock setFillColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:0.04]];
                        [_statusBlock setBorderColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:1.0]];
                        */
                        [app metaOk];
                        
                    });
                    
                }
                else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        CGFloat rFloat = 219/255.0;
                        CGFloat gFloat = 60/255.0;
                        CGFloat bFloat = 78/255.0;
                        
                        [_statusBlock setFillColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:0.04]];
                        [_statusBlock setBorderColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:1.0]];
                        
                        NSLog(@"publish error");
                        
                    });
                    
                }
            }
            
        }];
    }
    else{
        
        CGFloat rFloat = 219/255.0;
        CGFloat gFloat = 60/255.0;
        CGFloat bFloat = 78/255.0;
        
        [_statusBlock setFillColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:0.04]];
        [_statusBlock setBorderColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:1.0]];
        [_orangeMessage setStringValue:@"Please complete title, description and check the checkbox"];
        
        [_orangeMessage setHidden:NO];
        [_message setHidden:YES];
        [_messageImage setImage:[NSImage imageNamed:@"error"]];
        
    }
    
}

- (IBAction)cancelClick:(id)sender {
    
    [self.window orderOut:nil];
    
}

- (IBAction)agreeClick:(id)sender {
    
    if([self isReadyForUpload]){
        
        [self setFormIsValid:YES];
        
    }
    else{
        [self setFormIsValid:NO];
    }
}


@end
