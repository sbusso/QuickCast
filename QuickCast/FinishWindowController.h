//
//  QuickCast
//
//  Copyright (c) 2013 Pete Nelson, Neil Kinnish, Dom Murphy
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface FinishWindowController : NSWindowController<NSTextViewDelegate>{
    BOOL formIsValid;
    BOOL microVideo;
    NSString *width;
    NSString *height;
}

@property BOOL formIsValid;
@property BOOL microVideo;
@property (strong) NSString *width;
@property (strong) NSString *height;

- (IBAction)publishClick:(id)sender;
- (IBAction)cancelClick:(id)sender;
- (IBAction)agreeClick:(id)sender;


@property (strong) IBOutlet NSTextField *name;
@property (strong) IBOutlet NSBox *statusBlock;

@property (strong) IBOutlet NSTextField *tags;
@property (strong) IBOutlet NSTextField *intro;
@property (strong) IBOutlet NSTextField *outro;
@property (strong) IBOutlet NSButton *publishButton;

@property (strong) IBOutlet NSTextField *message;
@property (strong) IBOutlet NSImageView *messageImage;
@property (strong) IBOutlet NSTextField *orangeMessage;
@property (strong) IBOutlet NSTextField *greenMessage;

@property (strong) IBOutlet NSButton *agreeButton;

- (void)startUpload;
- (void)uploading:(BOOL)uploading;
- (void)setComplete:(NSString *)url;
- (void)setError:(NSString *)message;

@property (strong) IBOutlet WebView *preview;
@property (strong) IBOutlet NSTextView *multiline;

@end
