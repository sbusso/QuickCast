//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import "AppDelegate.h"
#import "SignInWindowController.h"
#import "QuickcastAPI.h"
#import "Analytics.h"

@interface SignInWindowController ()

@end

@implementation SignInWindowController

@synthesize uploading;

- (id)initWithWindow:(NSWindow *)window{
    
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad{
    
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [_validationLabel setHidden:YES];
    [_message setHidden:NO];
    _messageImageView.image = [NSImage imageNamed:@"warning"];    
}

- (IBAction)signUpClick:(id)sender{
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    [self.window orderOut:nil];
    [app goToSignUp:uploading];
}

- (IBAction)signInClick:(id)sender{
    
    QuickcastAPI *api = [[QuickcastAPI alloc] init];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:_username.stringValue, _password.stringValue, nil] forKeys:[NSArray arrayWithObjects:@"username", @"password", nil]];
    
    [api signin:params completionHandler:^(NSDictionary *response, NSError *error, NSHTTPURLResponse * httpResponse) {
        
        [_validationLabel setHidden:YES];
        [_message setHidden:NO];
        _messageImageView.image = [NSImage imageNamed:@"warning"];
        
        //check http status
        if (httpResponse.statusCode == 200) {
            
            //call app delegate on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                [prefs setObject:[NSString stringWithFormat:@"%@",[response objectForKey:@"token"]] forKey:@"token"];
                [prefs synchronize];
                AppDelegate *app = (AppDelegate *)[NSApp delegate];
                
                [[Analytics sharedAnalytics] identify:[response objectForKey:@"Id"] traits:[NSDictionary
                                                                                            dictionaryWithObjectsAndKeys:[response objectForKey:@"email"],@"$email", nil]];
                [[Analytics sharedAnalytics] track:@"login" properties:[NSDictionary dictionary]];
                app.loggedIn = YES;
                [app completeLogIn:uploading];
                [self.window orderOut:nil];
                
            });
            
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString *errorMessage= [response objectForKey:@"message"];
                
                CGFloat rFloat = 219/255.0;
                CGFloat gFloat = 60/255.0;
                CGFloat bFloat = 78/255.0;
                
                [_statusBlock setFillColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:0.04]];
                [_statusBlock setBorderColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:1.0]];
                
                if(errorMessage.length > 0){
                    _validationLabel.stringValue = @"Authentication failed";
                    [_validationLabel setHidden:NO];
                    [_message setHidden:YES];
                    _messageImageView.image = [NSImage imageNamed:@"error"];
                }
                else if (httpResponse.statusCode == 503){
                    _validationLabel.stringValue = @"Sorry we could not find your details";
                    [_validationLabel setHidden:NO];
                    [_message setHidden:YES];
                    _messageImageView.image = [NSImage imageNamed:@"error"];
                }
                else{
                    _validationLabel.stringValue = @"Authentication failed";
                    [_validationLabel setHidden:NO];
                    [_message setHidden:YES];
                    _messageImageView.image = [NSImage imageNamed:@"error"];
                }
                
                
            });
            
        }
        
        
    }];

}
@end
