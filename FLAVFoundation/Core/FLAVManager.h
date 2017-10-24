//
//  FLAVManager.h
//  FLAVFoundation
//
//  Created by Leaf on 2017/10/18.
//  Copyright © 2017年 leaf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLVideoPreviewView.h"
@import AVFoundation;
@import Photos;

@interface FLAVManager : NSObject

+ (instancetype)sharedInstance;

/**
 开启设备捕获
 */
- (void)startRunning;

/**
 关闭设备捕获
 */
- (void)stopRunning;

/**
 开启实时显示

 @param videoPreview 预览视图
 */
- (void)enableRealTimeOn:(FLVideoPreviewView *)videoPreview;

/**
 开启拍照
 */
- (void)enableTakingPhoto;

/**
 开启录制
 */
- (void)enableRecording;

- (void)takePhoto:(void (^)(NSData *jpegData, NSError *error))completion;

- (void)startRecordingTo:(NSURL *)outputFileURL;

- (void)stopRecording:(void (^)(NSURL *outputFileURL ,BOOL success))completion;

- (void)switchCamera;

- (void)focusPoint:(CGPoint)point;

- (void)setFlashMode:(AVCaptureFlashMode)flashMode;

- (AVCaptureFlashMode)flashMode;

- (void)savePhoto:(NSData *)data;

- (void)saveRecordingFile:(NSURL *)outputFileURL;

@end
