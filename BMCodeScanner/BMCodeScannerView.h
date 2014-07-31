//
//  CaptureCodeObject.h
//  ScanBarCodes
//
//  Created by Marina Gray on 2014-07-30.
//  Copyright (c) 2014 Black Magma Inc. All rights reserved.
//

@import Foundation;
@import UIKit;

@protocol BMCodeScannerViewDelegate <NSObject>

/**
 The delegate method that gets called when a string is successfully decoded.
 */
- (void) didCaptureString:(NSString *)string;
@end

@interface BMCodeScannerView : UIView

@property (nonatomic, weak) id <BMCodeScannerViewDelegate> delegate;

/**
 The color of the bounding box of the detected bar code.
 */
@property (nonatomic, strong) UIColor *highlightColor;

/**
 The line width of the bounding box of the detected bar code.
 */
@property (nonatomic) CGFloat highlightWidth;

/**
 A Boolean value that determines whether fast bounding box detection is used. Default value is YES.
 
 Fast bounds detection draws a bounding box with edges parallel to screen axis.
 
 When disabled, the bounding box is drawn exactly around the detected bar code, even if it is angled relative to the screen. This option is significantly more CPU intensive.
 */
@property (nonatomic) BOOL fastHighlight;

@end
