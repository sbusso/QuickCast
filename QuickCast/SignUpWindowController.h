//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import <Cocoa/Cocoa.h>

@interface SignUpWindowController : NSWindowController{
    BOOL uploading;
}
@property BOOL uploading;
@property (strong) IBOutlet NSTextField *validationLabel;
@property (strong) IBOutlet NSTextField *email;
@property (strong) IBOutlet NSBox *statusBlock;
@property (strong) IBOutlet NSTextField *firstName;
@property (strong) IBOutlet NSTextField *lastName;
@property (strong) IBOutlet NSTextField *username;
@property (strong) IBOutlet NSSecureTextField *password;
@property (strong) IBOutlet NSButton *mailingList;
@property (strong) IBOutlet NSTextField *message;
@property (strong) IBOutlet NSImageView *validationImageView;
- (IBAction)signInClick:(id)sender;
- (IBAction)signUpClick:(id)sender;

@end
