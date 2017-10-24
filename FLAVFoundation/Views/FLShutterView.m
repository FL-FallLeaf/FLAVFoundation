//
//  FLShutterView.m
//  FLAVFoundation
//
//  Created by Leaf on 2017/9/7.
//  Copyright © 2017年 leaf. All rights reserved.
//

#import "FLShutterView.h"

#define OuterCircle_Radius 40
#define OuterCircle_Radius_Max 50
#define InnerCircle_Radius 30
#define InnerCircle_Radius_Min 20
#define ProgressCircle_Radius 48

// 时间小于这个是拍照  大于是录像
static const NSTimeInterval kPressDurationCapturingAPhoto = 0.5f;

@interface FLShutterView () <UIGestureRecognizerDelegate, CAAnimationDelegate>
{
    
}
@property (nonatomic, strong) CAShapeLayer * innerCircle;//内圏
@property (nonatomic, strong) CAShapeLayer *outerCircle;//外圏
@property (nonatomic, strong) CAShapeLayer *progressCircle;//进度圏
@property (nonatomic, assign) BOOL isVideo;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation FLShutterView

- (void)drawRect:(CGRect)rect {
    
    self.outerCircle = [CAShapeLayer layer];
    self.outerCircle.path = [self circleWithCenter:[self arcCenter] radius:OuterCircle_Radius].CGPath;
    self.outerCircle.fillColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    [self.layer addSublayer:self.outerCircle];
    
    self.innerCircle = [CAShapeLayer layer];
    self.innerCircle.path = [self circleWithCenter:[self arcCenter] radius:InnerCircle_Radius].CGPath;
    self.innerCircle.fillColor = [UIColor whiteColor].CGColor;
    [self.layer addSublayer:self.innerCircle];
    
    self.progressCircle = [CAShapeLayer layer];
    self.progressCircle.path = [self circleWithCenter:[self arcCenter] radius:ProgressCircle_Radius].CGPath;
    self.progressCircle.fillColor = nil;
    self.progressCircle.strokeColor = [UIColor redColor].CGColor;
    self.progressCircle.strokeStart = 0.f;
    self.progressCircle.strokeEnd = 0.f;
    self.progressCircle.lineWidth = 4.f;
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.bounds = self.bounds;
    gradientLayer.position = [self arcCenter];
    gradientLayer.colors = @[(__bridge id)[UIColor redColor].CGColor,
                             (__bridge id)[UIColor orangeColor].CGColor];
    gradientLayer.locations = @[@0, @1];
    gradientLayer.startPoint = CGPointMake(0.5, 0);
    gradientLayer.endPoint = CGPointMake(0.5, 1);
    gradientLayer.mask = self.progressCircle;
    [self.outerCircle addSublayer:gradientLayer];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        longPress.minimumPressDuration = 0.f;
        [self addGestureRecognizer:longPress];
        
        self.maxDuration = 10;
    }
    return self;
}

#pragma mark - event response

-(void)handleGesture:(UIGestureRecognizer*)gestureRecognizer {
    
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        
        switch (gestureRecognizer.state) {
            case UIGestureRecognizerStateBegan://动画开始
            {
                [self.innerCircle addAnimation:[self fillColorAnimationFromValue:[UIColor whiteColor] toValue:[UIColor grayColor] duration:0.2] forKey:@"FillColorAnimation"];
                [self.innerCircle addAnimation:[self pathAnimationWithPath:[self circleWithCenter:[self arcCenter] radius:InnerCircle_Radius_Min] duration:0.2] forKey:@"PathAnimation"];
                __weak __typeof(self)weakSelf = self;
                self.timer = [NSTimer scheduledTimerWithTimeInterval:kPressDurationCapturingAPhoto repeats:NO block:^(NSTimer * _Nonnull timer) {
                    weakSelf.isVideo = YES;
                    !self.didStartRecordingVideo?:self.didStartRecordingVideo();
                }];
            }
                break;
            case UIGestureRecognizerStateEnded://动画结束
            {
                [self.innerCircle removeAllAnimations];
                [self.outerCircle removeAllAnimations];
                [self.progressCircle removeAllAnimations];
                [self.timer invalidate];
                [self endCapture];
            }
                break;
            default:
                break;
        }
    }
}

- (void)endCapture {
    
    if (self.isVideo) {
        !self.didFinishRecordingVideo?:self.didFinishRecordingVideo();
    } else {
        !self.takePhoto?:self.takePhoto();
    }
    self.isVideo = NO;
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    
    if ([self.innerCircle animationForKey:@"PathAnimation"] == anim) {
        
        [self.outerCircle addAnimation:[self pathAnimationWithPath:[self circleWithCenter:[self arcCenter] radius:OuterCircle_Radius_Max] duration:0.3] forKey:@"PathAnimation"];
    } else
        if ([self.outerCircle animationForKey:@"PathAnimation"] == anim) {
            
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            animation.toValue = @(1);
            animation.duration = self.maxDuration;
            animation.removedOnCompletion = NO;
            animation.fillMode = kCAFillModeForwards;
            [self.progressCircle addAnimation:animation forKey:@"StrokeEndAnimation"];
        }
}

#pragma mark - Circle Creation

- (UIBezierPath *)circleWithCenter:(CGPoint)center radius:(CGFloat)radius {
    
    UIBezierPath *pointPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI_2 endAngle:M_PI_2 * 3 clockwise:YES];
    return pointPath;
}

#pragma mark - Animation

- (CABasicAnimation *)fillColorAnimationFromValue:(UIColor *)fromColor toValue:(UIColor *)toColor duration:(CGFloat)duration {
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"fillColor"];
    anim.fromValue = (id)fromColor.CGColor;
    anim.toValue = (id)toColor.CGColor;
    anim.duration = duration;
    anim.removedOnCompletion = NO;
    anim.fillMode = kCAFillModeForwards;
    anim.delegate = self;
    return anim;
}

- (CABasicAnimation *)pathAnimationWithPath:(UIBezierPath *)path duration:(CGFloat)duration {
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"path"];
    anim.toValue = (id)path.CGPath;
    anim.duration = duration;
    anim.removedOnCompletion = NO;
    anim.fillMode = kCAFillModeForwards;
    anim.delegate = self;
    return anim;
}

#pragma mark - Utils

- (CGPoint)arcCenter {
    return [self convertPoint:self.center fromView:self.superview];
}

@end
