//
//  DecisionWindowController.h
//  QuickCast
//
//  Created by Pete Nelson on 29/07/2013.
//  Copyright (c) 2013 Reissued Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DecisionWindowController : NSWindowController
- (IBAction)previewButtonClick:(id)sender;
- (IBAction)publishButtonClick:(id)sender;
- (IBAction)cancelButtonClick:(id)sender;
- (IBAction)recordAgainButtonClick:(id)sender;

@property (strong) IBOutlet NSImageView *previewImageView;
@property (strong) IBOutlet NSProgressIndicator *progress;
@property (strong) IBOutlet NSButton *previewButton;
@property (strong) IBOutlet NSButton *publishButton;
@property (strong) IBOutlet NSButton *cancelButton;
@property (strong) IBOutlet NSButton *recordAgainButton;

- (void)updateImage:image;
- (void)completedProcessing:(BOOL)finished;
- (void)compress;


@end
