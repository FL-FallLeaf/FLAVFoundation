//
//  FLCameraViewController.m
//  FLAVFoundation
//
//  Created by Leaf on 2017/9/7.
//  Copyright © 2017年 leaf. All rights reserved.
//

#import "FLCameraViewController.h"
#import "FLCameraView.h"
#import "FLShutterView.h"
#import "FLVideoPreviewView.h"
#import "FLAVManager.h"
@import AVFoundation;
@import Photos;
#import "FLPlayerViewController.h"

@interface FLCameraViewController ()
{
   
}

@property (weak, nonatomic) IBOutlet FLCameraView *cameraView;
@property (weak, nonatomic) IBOutlet FLVideoPreviewView *videoPreview;
@property (weak, nonatomic) IBOutlet FLShutterView *shutterView;

@end

@implementation FLCameraViewController

#pragma mark - life cycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[FLAVManager sharedInstance] startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[FLAVManager sharedInstance] stopRunning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupCamera];
    [self setupShutter];
    
    [[FLAVManager sharedInstance] enableRealTimeOn:self.videoPreview];
    [[FLAVManager sharedInstance] enableTakingPhoto];
    [[FLAVManager sharedInstance] enableRecording];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - setup UI

- (void)setupCamera {
    self.cameraView.changeFlashMode = ^(void (^completion)(FLCameraFlashMode flashMode, NSError *error)) {
        [self changeFlashMode:completion];
    };
    self.cameraView.focus = ^(CGPoint point) {
        [[FLAVManager sharedInstance] focusPoint:point];
    };
}

- (void)setupShutter {
    self.shutterView.takePhoto = ^{
        [[FLAVManager sharedInstance] takePhoto:^(NSData *jpegData, NSError *error) {
            FLPlayerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([FLPlayerViewController class])];
            vc.mediaType = FLMediaTypePhoto;
            vc.data = jpegData;
            [self presentViewController:vc animated:NO completion:nil];
        }];
    };
    self.shutterView.didStartRecordingVideo = ^{
        [[FLAVManager sharedInstance] startRecordingTo:[self outputFileURL]];
    };
    self.shutterView.didFinishRecordingVideo = ^{
        [[FLAVManager sharedInstance] stopRecording:^(NSURL *outputFileURL, BOOL success) {
            if (success) {
                FLPlayerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([FLPlayerViewController class])];
                vc.mediaType = FLMediaTypeMovie;
                vc.data = outputFileURL;
                [self presentViewController:vc animated:NO completion:nil];
            }
        }];
    };
}

#pragma mark - Go back

- (IBAction)goBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
     
}

#pragma mark -  摄像头切换

- (IBAction)switchCamera:(id)sender {
    [[FLAVManager sharedInstance] switchCamera];
}

#pragma mark - 闪光灯

- (void)changeFlashMode:(void (^)(FLCameraFlashMode flashMode, NSError *error))completion {

    AVCaptureFlashMode preferredFlashMode;
    switch ([[FLAVManager sharedInstance] flashMode]) {
        case AVCaptureFlashModeOff:
            preferredFlashMode = AVCaptureFlashModeOn;
            break;
        case AVCaptureFlashModeOn:
            preferredFlashMode = AVCaptureFlashModeAuto;
            break;
        case AVCaptureFlashModeAuto:
            preferredFlashMode = AVCaptureFlashModeOff;
            break;
    }
    [[FLAVManager sharedInstance] setFlashMode:preferredFlashMode];
    completion((FLCameraFlashMode)preferredFlashMode, nil);
}

#pragma mark - 获取写入路径

- (NSURL *)outputFileURL {
    NSString *outputDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]  stringByAppendingPathComponent:@"com.leaf.video"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:outputDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:outputDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *fileName = [NSString stringWithFormat:@"%f", [NSDate date].timeIntervalSince1970];
    NSString *outputFile = [outputDirectory stringByAppendingPathComponent:[fileName stringByAppendingPathExtension:@"mov"]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputFile])
    {
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:outputFile error:&error];
        if (!success){
            
        }
        else{
            NSLog(@"删除视频文件成功");
        }
    }
    
    return [NSURL fileURLWithPath:outputFile];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
