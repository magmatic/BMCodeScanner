//
//  BMCodeScannerView.m
//  BMCodeScanner
//
//  Created by Marina Gray on 2014-07-30.
//  Copyright (c) 2014 Black Magma Inc. All rights reserved.
//

#import "BMCodeScannerView.h"
@import AVFoundation;

@interface BMCodeScannerView () <AVCaptureMetadataOutputObjectsDelegate> {
    AVCaptureSession *_session;
    AVCaptureDevice *_device;
    AVCaptureDeviceInput *_input;
    AVCaptureMetadataOutput *_output;
    AVCaptureVideoPreviewLayer *_prevLayer;
    
    UIView *_highlightView;
    
    UIImageView *_exactHighlight;

}

@end

@implementation BMCodeScannerView

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // set default 
        self.highlightColor = [[UIColor greenColor] colorWithAlphaComponent:0.6];
        self.highlightWidth = 3;
        self.fastHighlight = YES;
        
        // watch changes to adjustable parameters
        [self addObserver:self forKeyPath:@"highlightColor" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"highlightWidth" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
        
        // make sure video feed orientation matches the screen
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSuspendResume:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSuspendResume:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedAVNotification:) name:AVCaptureSessionRuntimeErrorNotification object:nil];

        [self startSession];
    }
    return self;
}
- (void) startSession {
    _session = [[AVCaptureSession alloc] init];
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (_input) {
        [_session addInput:_input];
    } else {
        NSLog(@"Error: %@", error);
    }
    
    _output = [[AVCaptureMetadataOutput alloc] init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [_session addOutput:_output];
    
    _output.metadataObjectTypes = [_output availableMetadataObjectTypes];

    _prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _prevLayer.frame = self.bounds;
    _prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self orientationDidChange:nil]; // set correct orientation initially
    [self.layer addSublayer:_prevLayer];
    
    [_session startRunning];
    
    if (self.fastHighlight) {
        _highlightView = [[UIView alloc] init];
        _highlightView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
        _highlightView.layer.borderColor = self.highlightColor.CGColor;
        _highlightView.layer.borderWidth = self.highlightWidth;
        [self addSubview:_highlightView];
    } else {
        _exactHighlight = [[UIImageView alloc] init];
        [self addSubview:_exactHighlight];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    CGRect highlightViewRect = CGRectZero;
    AVMetadataMachineReadableCodeObject *barCodeObject;
    NSString *detectionString = nil;
    NSArray *barCodeTypes = @[AVMetadataObjectTypeUPCECode,
                              AVMetadataObjectTypeCode39Code,
                              AVMetadataObjectTypeCode39Mod43Code,
                              AVMetadataObjectTypeEAN13Code,
                              AVMetadataObjectTypeEAN8Code,
                              AVMetadataObjectTypeCode93Code,
                              AVMetadataObjectTypeCode128Code,
                              AVMetadataObjectTypePDF417Code,
                              AVMetadataObjectTypeQRCode,
                              AVMetadataObjectTypeAztecCode];
    
    if (!self.fastHighlight) _exactHighlight.image = nil;

    for (AVMetadataObject *metadata in metadataObjects) {
        for (NSString *type in barCodeTypes) {
            if ([metadata.type isEqualToString:type]) {
                barCodeObject = (AVMetadataMachineReadableCodeObject *)[_prevLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metadata];
                if (self.fastHighlight) {
                    highlightViewRect = barCodeObject.bounds;
                } else {
                    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
                    [self.highlightColor setStroke];
                    
                    UIBezierPath *path = [UIBezierPath bezierPath];
                    path.lineWidth = self.highlightWidth;
                    
                    CGPoint p = CGPointZero;
                    CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)barCodeObject.corners[0], &p);
                    [path moveToPoint:p];
                    
                    for (int i = 1; i < barCodeObject.corners.count; i++) {
                        CGPoint p = CGPointZero;
                        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)barCodeObject.corners[i], &p);
                        [path addLineToPoint:p];
                    }
                    [path addLineToPoint:p];
                    
                    [path stroke];
                    _exactHighlight.image = UIGraphicsGetImageFromCurrentImageContext();
                    _exactHighlight.frame = CGRectMake(0,0, _exactHighlight.image.size.width, _exactHighlight.image.size.height);
                    UIGraphicsEndImageContext();
                }
                
                detectionString = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
                break;
            }
        }
        
        if (detectionString != nil) {
            if ([self.delegate respondsToSelector:@selector(didCaptureString:)])
                [self.delegate didCaptureString:detectionString];
            break;
        }
    }
    if (self.fastHighlight) _highlightView.frame = highlightViewRect;
}

- (void) receivedAVNotification:(NSNotification *)notification {
    NSLog(@"%@", notification);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (object == self) {
        if ([keyPath isEqualToString:@"highlightColor"]) {
            _highlightView.layer.borderColor = self.highlightColor.CGColor;
        } else if ([keyPath isEqualToString:@"highlightWidth"]) {
            _highlightView.layer.borderWidth = self.highlightWidth;
        } else if ([keyPath isEqualToString:@"frame"]) {
            _prevLayer.frame = self.bounds;
        }
    }
}

- (void) handleSuspendResume:(NSNotification *)notification {
    if ([notification.name isEqualToString:UIApplicationWillEnterForegroundNotification]) {
        // resume video feed
        [_session startRunning];
    } else if ([notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]) {
        // suspent video feed
        [_session stopRunning];
    }
}

- (void) orientationDidChange:(NSNotification *)notification {
    if ([_prevLayer.connection isVideoOrientationSupported]) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
        
        switch (orientation) {
            case UIInterfaceOrientationPortraitUpsideDown:
                videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
            case UIInterfaceOrientationLandscapeRight:
                videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                break;
            default:
                break;
        }
        _prevLayer.connection.videoOrientation = videoOrientation;
    }
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"highlightColor"];
    [self removeObserver:self forKeyPath:@"highlightWidth"];
    [self removeObserver:self forKeyPath:@"frame"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
