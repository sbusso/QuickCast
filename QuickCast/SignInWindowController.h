//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import <Cocoa/Cocoa.h>

@interface SignInWindowController : NSWindowController{
    BOOL uploading;
}
@property BOOL uploading;
@property (strong) IBOutlet NSTextField *validationLabel;
@property (strong) IBOutlet NSBox *statusBlock;
@property (strong) IBOutlet NSTextField *username;
@property (strong) IBOutlet NSSecureTextField *password;
@property (strong) IBOutlet NSImageView *messageImageView;
@property (strong) IBOutlet NSTextField *message;
- (IBAction)signUpClick:(id)sender;
- (IBAction)signInClick:(id)sender;

@end
