//
//  FLCameraView.m
//  FLAVFoundation
//
//  Created by Leaf on 2017/9/6.
//  Copyright © 2017年 leaf. All rights reserved.
//

#import "FLCameraView.h"
#import "FLVideoPreviewView.h"

@interface FLCameraView ()

@property (weak, nonatomic) IBOutlet FLVideoPreviewView *videoPreview;
@property (weak, nonatomic) IBOutlet UIView *playbackControls;
@property (weak, nonatomic) IBOutlet UIButton *flashModeButton;
@property (weak, nonatomic) IBOutlet UIImageView *focusImageView;

@end

@implementation FLCameraView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (IBAction)changeFlashMode:(id)sender {
    if (self.changeFlashMode) {
        self.changeFlashMode(^(FLCameraFlashMode flashMode, NSError *error) {
            switch (flashMode) {
                case FLCameraFlashModeOff:
                    [self.flashModeButton setImage:[UIImage imageNamed:@"flash_off"] forState:UIControlStateNormal];
                    break;
                    
                case FLCameraFlashModeOn:
                    [self.flashModeButton setImage:[UIImage imageNamed:@"flash_on"] forState:UIControlStateNormal];
                    break;
                    
                case FLCameraFlashModeAuto:
                    [self.flashModeButton setImage:[UIImage imageNamed:@"flash_auto"] forState:UIControlStateNormal];
                    break;
            }
        });
    }
}

- (IBAction)handleGesture:(UIGestureRecognizer*)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        
        [self.focusImageView.layer removeAllAnimations];
        CGPoint point = [gestureRecognizer locationInView:self.playbackControls];
        self.focusImageView.center = point;
        self.focusImageView.transform = CGAffineTransformMakeScale(2.0, 2.0);
        self.focusImageView.hidden = NO;
        [UIView animateWithDuration:0.25 animations:^{
            self.focusImageView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            if (finished) {
                [self performSelector:@selector(hideFocus) withObject:nil afterDelay:0.5];
            }
        }];
        
        !self.focus?:self.focus(CGPointMake(point.x/self.videoPreview.frame.size.width, point.y/self.videoPreview.frame.size.height));
    }
}

- (void)hideFocus {
    self.focusImageView.hidden = YES;
}

@end
