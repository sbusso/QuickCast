//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import "AppDelegate.h"
#import "SignUpWindowController.h"
#import "QuickcastAPI.h"
#import "Analytics.h"

@interface SignUpWindowController ()

@end

@implementation SignUpWindowController

@synthesize uploading;
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad{
    
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [_message setHidden:NO];
    [_validationLabel setHidden:YES];
    [_validationImageView setImage:[NSImage imageNamed:@"warning"]];
}

- (IBAction)signInClick:(id)sender{
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    [self.window orderOut:nil];
    [app goToSignIn:uploading];
}

- (IBAction)signUpClick:(id)sender{
    
    QuickcastAPI *api = [[QuickcastAPI alloc] init];
    
    [_message setHidden:NO];
    [_validationLabel setHidden:YES];
    [_validationImageView setImage:[NSImage imageNamed:@"warning"]];
    
    NSString *mailinglist = (_mailingList.state == NSOnState) ? @"true" : @"false";
    
    if(_email.stringValue.length > 0 && _firstName.stringValue.length > 0 && _lastName.stringValue.length > 0 && _username.stringValue.length > 0 && _password.stringValue.length > 0){
        
        NSDictionary *params = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:_email.stringValue,_firstName.stringValue,_lastName.stringValue, _username.stringValue, _password.stringValue,mailinglist, nil] forKeys:[NSArray arrayWithObjects:@"email",@"firstname",@"lastname", @"username", @"password",@"mailinglist", nil]];
        
        [api signup:params completionHandler:^(NSDictionary *response, NSError *error, NSHTTPURLResponse * httpResponse) {
            
            [_validationLabel setHidden:YES];
            
                
            //check http status
            if (httpResponse.statusCode == 200) {
                
                //call app delegate on the main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                    [prefs setObject:[NSString stringWithFormat:@"%@",[response objectForKey:@"token"]] forKey:@"token"];
                    [prefs synchronize];
                    [[Analytics sharedAnalytics] identify:[response objectForKey:@"Id"] traits:[NSDictionary
                                                                                                dictionaryWithObjectsAndKeys:_email.stringValue,@"$email", nil]];
                    [[Analytics sharedAnalytics] track:@"$signup" properties:[NSDictionary dictionary]];
                    AppDelegate *app = (AppDelegate *)[NSApp delegate];
                    app.loggedIn = YES;
                    [app completeLogIn:uploading];
                    [self.window orderOut:nil];
                    
                });
                
            }
            else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    CGFloat rFloat = 219/255.0;
                    CGFloat gFloat = 60/255.0;
                    CGFloat bFloat = 78/255.0;
                    
                    [_statusBlock setFillColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:0.04]];
                    [_statusBlock setBorderColor: [NSColor colorWithCalibratedRed:rFloat green:gFloat blue:bFloat alpha:1.0]];
                    
                    NSArray *errors = [response objectForKey:@"errors"];
                    
                    if(errors){
                        for(NSDictionary *error in errors){
                            _validationLabel.stringValue = [error objectForKey:@"message"];
                            [_validationLabel setHidden:NO];
                            [_message setHidden:YES];
                            
                            [_validationImageView setImage:[NSImage imageNamed:@"error"]];
                        }
                    }
                    else{
                        
                        _validationLabel.stringValue = @"Please check your internet connection";
                        [_validationLabel setHidden:NO];
                        [_message setHidden:YES];
                        
                        [_validationImageView setImage:[NSImage imageNamed:@"error"]];
                    }
                    
                    
                    
                });
                
            }
            
            
        }];
    }

}
@end
