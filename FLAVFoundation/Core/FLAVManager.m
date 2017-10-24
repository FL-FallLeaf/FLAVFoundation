//
//  FLAVManager.m
//  FLAVFoundation
//
//  Created by Leaf on 2017/10/18.
//  Copyright © 2017年 leaf. All rights reserved.
//

#import "FLAVManager.h"

@interface FLAVManager () <AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate>

@property (nonatomic, strong) dispatch_queue_t sessionQueue;//设备捕捉会话队列
@property (nonatomic, strong) dispatch_queue_t outputQueue;//数据输出队列
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureStillImageOutput *photoOutput;
@property (nonatomic, assign) BOOL videoInputReady;
@property (nonatomic, assign) BOOL audioInputReady;
@property (nonatomic, assign) BOOL videoOutputReady;
@property (nonatomic, assign) BOOL audioOutputReady;
@property (nonatomic, assign) BOOL photoOutputReady;
@property (nonatomic, strong) dispatch_queue_t writerQueue;//写入文件队列
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoWriterInput;
@property (nonatomic, strong) AVAssetWriterInput *audioWriterInput;
@property (nonatomic, assign) BOOL recording;
@property (nonatomic, assign) BOOL videoWriterInputReady;
@property (nonatomic, assign) BOOL audioWriterInputReady;

@property (nonatomic, strong) FLVideoPreviewView *videoPreview;

@end

@implementation FLAVManager

+ (instancetype)sharedInstance {
    static FLAVManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
        self.outputQueue = dispatch_queue_create("OutputQueue", DISPATCH_QUEUE_SERIAL);
        self.writerQueue = dispatch_queue_create("Writer Queue", DISPATCH_QUEUE_SERIAL);
        
        [self setupSession];
    }
    return self;
}

- (void)setupSession {
    self.session = [[AVCaptureSession alloc] init];
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
    }
}

#pragma mark - 开启设备捕获的数据流动

- (void)startRunning {
    dispatch_async(self.sessionQueue, ^{
        if (![self.session isRunning]) {
            [self.session startRunning];
        }
    });
}

#pragma mark - 关闭设备捕获的数据流动

- (void)stopRunning {
    dispatch_async(self.sessionQueue, ^{
        if ([self.session isRunning]) {
            [self.session stopRunning];
        }
    });
}

#pragma mark - 开启实时显示

- (void)enableRealTimeOn:(FLVideoPreviewView *)videoPreview {
    [self prepareVideoInput];
    [self prepareVideoOutput];
    self.videoPreview = videoPreview;
}

#pragma mark - 开启照相

- (void)enableTakingPhoto {
    [self prepareVideoInput];
    [self preparePhotoOutput];
}

#pragma mark - 开启录制

- (void)enableRecording {
    [self prepareAudioInput];
    [self prepareVideoInput];
    [self prepareAudioOutput];
    [self prepareVideoOutput];
}

#pragma mark - 拍照

- (void)takePhoto:(void (^)(NSData *jpegData, NSError *error))completion {
    AVCaptureConnection *connection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    if (connection.supportsVideoOrientation) {
        
    }
    [self.photoOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
        if (!imageDataSampleBuffer) {
            completion(nil, error);
        } else {
            NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            completion(jpegData, error);
        }
    }];
}

#pragma mark - 开始录制

- (void)startRecordingTo:(NSURL *)outputFileURL {
    
    self.recording = YES;
    self.audioWriterInputReady = NO;
    self.videoWriterInputReady = NO;
    [self setupAssetWriter:outputFileURL];
}

#pragma mark - 结束录制

- (void)stopRecording:(void (^)(NSURL *outputFileURL ,BOOL success))completion {
    
    self.recording = NO;
    
    dispatch_async(self.writerQueue, ^{
        [self.assetWriter finishWritingWithCompletionHandler:^{
            switch (self.assetWriter.status) {
                case AVAssetWriterStatusCompleted:
                    completion(self.assetWriter.outputURL, YES);
                    break;
                    
                default:
                    completion(self.assetWriter.outputURL, NO);
                    break;
            }
        }];
    });
}

#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate|AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (connection == [captureOutput connectionWithMediaType:AVMediaTypeVideo]) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage *ciImage = [[CIImage imageWithCVImageBuffer:imageBuffer] imageByApplyingOrientation:kCGImagePropertyOrientationRight];
        
        [self.videoPreview render:ciImage];
    }
    
    if (self.recording) {
        CFRetain(sampleBuffer);
        dispatch_async(self.writerQueue, ^{
            if (self.assetWriter) {
                if (connection == [captureOutput connectionWithMediaType:AVMediaTypeVideo]) {
                    [self prepareVideoWriterInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
                    if (self.videoWriterInputReady && self.audioWriterInputReady) {
                        [self writeSampleBuffer:sampleBuffer forMediaType:AVMediaTypeVideo];
                    }
                }
                else if (connection == [captureOutput connectionWithMediaType:AVMediaTypeAudio]) {
                    [self prepareAudioWriterInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
                    if (self.videoWriterInputReady && self.audioWriterInputReady) {
                        [self writeSampleBuffer:sampleBuffer forMediaType:AVMediaTypeAudio];
                    }
                }
            }
            CFRelease(sampleBuffer);
        });
    }
}

#pragma mark - 准备输入输出

- (void)prepareVideoInput {
    if (self.videoInputReady) {
        return;
    }
    AVCaptureDevice *device = [self videoDevice:AVCaptureDevicePositionBack];
    NSError *error;
    self.videoInputReady = [self addInput:device error:&error];
    if (!self.videoInputReady) {
        NSLog(@"Could not create video device input: %@", error);
    }
}

- (void)prepareAudioInput {
    if (self.audioInputReady) {
        return;
    }
    AVCaptureDevice *device = [self audioDevice];
    NSError *error;
    self.audioInputReady = [self addInput:device error:&error];
    if (!self.audioInputReady) {
        NSLog(@"Could not create audio device input: %@", error);
    }
}

- (void)prepareVideoOutput {
    if (self.videoOutputReady) {
        return;
    }
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:self.outputQueue];
    self.videoOutputReady = [self addOutput:output];
    if (!self.videoOutputReady) {
        NSLog(@"Could not create video data output");
    }
}

- (void)prepareAudioOutput {
    if (self.audioOutputReady) {
        return;
    }
    AVCaptureAudioDataOutput *output = [[AVCaptureAudioDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:self.outputQueue];
    self.audioOutputReady = [self addOutput:output];
    if (!self.audioOutputReady) {
        NSLog(@"Could not create audio data output");
    }
}

- (void)preparePhotoOutput {
    if (self.photoOutputReady) {
        return;
    }
    AVCaptureStillImageOutput *output = [[AVCaptureStillImageOutput alloc] init];
    self.photoOutputReady = [self addOutput:output];
    if (!self.photoOutputReady) {
        NSLog(@"Could not create photo output");
        return;
    }
    self.photoOutput = output;
}

#pragma mark - 准备媒体写入输入

- (void)setupAssetWriter:(NSURL *)outputFileURL {
    
    dispatch_async(self.writerQueue, ^{
        NSError *error;
        self.assetWriter = [AVAssetWriter assetWriterWithURL:outputFileURL fileType:AVFileTypeQuickTimeMovie error:&error];
        if (!self.assetWriter) {
            NSLog(@"Could not create asset writer： %@", error);
        }
    });
}

- (void)prepareVideoWriterInput:(CMFormatDescriptionRef)formatDescription {
    if (self.videoWriterInputReady) {
        return;
    }
    CMVideoDimensions videoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
    CFDictionaryRef pixelAspectRatio = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_PixelAspectRatio);
    NSDictionary *videoSettings = @{AVVideoCodecKey  : AVVideoCodecH264,
                                    AVVideoWidthKey  : [NSNumber numberWithDouble:videoDimensions.width],
                                    AVVideoHeightKey : [NSNumber numberWithDouble:videoDimensions.height],
//                                    AVVideoPixelAspectRatioKey : (__bridge id)pixelAspectRatio
                                    };
    self.videoWriterInputReady = [self addWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    if (!self.videoWriterInputReady) {
        NSLog(@"Could not create video writer input");
        return;
    }
}

- (void)prepareAudioWriterInput:(CMFormatDescriptionRef)formatDescription {
    if (self.audioWriterInputReady) {
        return;
    }
    NSDictionary *compressionAudioSettings = @{
                                               AVFormatIDKey         : [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC],
                                               AVEncoderBitRateKey   : [NSNumber numberWithInteger:32000],
                                               AVSampleRateKey       : [NSNumber numberWithInteger:8000],
                                               //                                               AVChannelLayoutKey    : channelLayoutAsData,
                                               AVNumberOfChannelsKey : [NSNumber numberWithUnsignedInteger:1]
                                               };
    self.audioWriterInputReady =[self addWriterInputWithMediaType:AVMediaTypeAudio outputSettings:compressionAudioSettings];
    if (!self.audioWriterInputReady) {
        NSLog(@"Could not create audio writer input");
        return;
    }
}

#pragma mark - 资源写入

- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer forMediaType:(AVMediaType)mediaType
{
    switch (self.assetWriter.status) {
        case AVAssetWriterStatusUnknown:
        {
            if (![self.assetWriter startWriting]) {
                NSLog(@"写入失败");
                return;
            }
            [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        }
        case AVAssetWriterStatusWriting:
        {
            if (mediaType == AVMediaTypeVideo)
            {
                if (!self.videoWriterInput.readyForMoreMediaData){
                    NSLog(@"写入视频失败");
                    return;
                }
                if (![self.videoWriterInput appendSampleBuffer:sampleBuffer]){
                    NSLog(@"写入视频失败");
                }
            }
            else if (mediaType == AVMediaTypeAudio){
                if (!self.audioWriterInput.readyForMoreMediaData){
                    NSLog(@"写入音频失败");
                    return;
                }
                if (![self.audioWriterInput appendSampleBuffer:sampleBuffer]){
                    NSLog(@"写入音频失败");
                }
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - 添加资源写入输入

- (BOOL)addWriterInputWithMediaType:(AVMediaType)mediaType outputSettings:(NSDictionary *)outputSettings {
    if (![self.assetWriter canApplyOutputSettings:outputSettings forMediaType:mediaType]) {
        return NO;
    }
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:mediaType outputSettings:outputSettings];
    writerInput.expectsMediaDataInRealTime = YES;
    //指定输出文件中可视媒体数据的的作出的变换，显示会去掉变换正常显示
    writerInput.transform = CGAffineTransformMakeRotation(M_PI_2);
    if (![self.assetWriter canAddInput:writerInput]) {
        return NO;
    }
    [self.assetWriter addInput:writerInput];
    
    if ([mediaType isEqualToString:AVMediaTypeVideo]) {
        self.videoWriterInput = writerInput;
    } else if ([mediaType isEqualToString:AVMediaTypeAudio]) {
        self.audioInputReady = writerInput;
    }
    
    return YES;
}

#pragma mark - 添加输入
- (BOOL)addInput:(AVCaptureDevice *)device error:(NSError **)error {
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:error];
    if (!input) {
        return NO;
    }
    if ([device hasMediaType:AVMediaTypeVideo]) {
        if (self.videoInput) {
            [self.session removeInput:self.videoInput];
        }
        self.videoInput = input;
    }
    if (![self.session canAddInput:input]) {
        return NO;
    }
    [self.session beginConfiguration];
    [self.session addInput:input];
    [self.session commitConfiguration];
    
    return YES;
}

#pragma mark - 添加输出
- (BOOL)addOutput:(AVCaptureOutput *)output {
    
    if (!output) {
        return NO;
    }
    if (![self.session canAddOutput:output]) {
        return NO;
    }
    [self.session beginConfiguration];
    [self.session addOutput:output];
    [self.session commitConfiguration];
    return YES;
}

#pragma mark - 切换镜头

- (void)switchCamera {
    AVCaptureDevicePosition position;
    switch ([self currentPosition]) {
        case AVCaptureDevicePositionBack:
            position = AVCaptureDevicePositionFront;
            break;
        case AVCaptureDevicePositionFront:
            position = AVCaptureDevicePositionBack;
            break;
        default:
            NSLog(@"未指定");
            return;
    }
    AVCaptureDevice *device = [self videoDevice:position];
    NSError *error;
    if (![self addInput:device error:&error]) {
        NSLog(@"切换镜头失败： %@", error);
    }
}

#pragma mark - 聚焦

- (void)focusPoint:(CGPoint)point {
    NSError *error;
    if ([self.videoInput.device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        
        [self.videoInput.device lockForConfiguration:&error];
        self.videoInput.device.focusPointOfInterest = point;
        self.videoInput.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        [self.videoInput.device unlockForConfiguration];
    }
}

#pragma mark - 设置闪光灯

- (void)setFlashMode:(AVCaptureFlashMode)flashMode {
    if (![self.videoInput.device hasFlash]) {
        return;
    }
    NSError *error;
    if ([self.videoInput.device isFlashModeSupported:flashMode]) {
        
        [self.videoInput.device lockForConfiguration:&error];
        self.videoInput.device.flashMode = flashMode;
        [self.videoInput.device unlockForConfiguration];
    }
}

- (AVCaptureFlashMode)flashMode {
    return self.videoInput.device.flashMode;
}

#pragma mark - 获取摄相头

- (AVCaptureDevice *)videoDevice:(AVCaptureDevicePosition)position {
    
    AVCaptureDevice *device;
    
    
    
    device = [AVCaptureDevice defaultDeviceWithDeviceType: AVCaptureDeviceTypeBuiltInDualCamera
                                                mediaType: AVMediaTypeVideo
                                                 position: position];
    if (device != nil) {
        return device;
    }
    device = [AVCaptureDevice defaultDeviceWithDeviceType: AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                mediaType: AVMediaTypeVideo
                                                 position: position];
    if (device != nil) {
        return device;
    }
    return nil;
}

#pragma mark - 获取麦克风

- (AVCaptureDevice *)audioDevice {
    
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
}

- (AVCaptureDevicePosition)currentPosition {
    return self.videoInput.device.position;
}

/*
 - (void)savePhoto:(NSData *)data {
 [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
 switch (status) {
 case PHAuthorizationStatusNotDetermined:
 
 break;
 case PHAuthorizationStatusRestricted:
 case PHAuthorizationStatusDenied:
 
 return ;
 default:
 {
 [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
 PHAssetCreationRequest *createAssetRequest = [PHAssetCreationRequest creationRequestForAsset];
 [createAssetRequest addResourceWithType:PHAssetResourceTypePhoto data:data options:nil];
 } completionHandler:^(BOOL success, NSError * _Nullable error) {
 
 }];
 }
 break;
 }
 }];
 }
 
 - (void)saveRecordingFile:(NSURL *)outputFileURL {
 [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
 switch (status) {
 case PHAuthorizationStatusNotDetermined:
 
 break;
 case PHAuthorizationStatusRestricted:
 case PHAuthorizationStatusDenied:
 
 return ;
 default:
 {
 [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
 PHAssetCreationRequest *createAssetRequest = [PHAssetCreationRequest creationRequestForAsset];
 [createAssetRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:nil];
 } completionHandler:^(BOOL success, NSError * _Nullable error) {
 
 }];
 }
 break;
 }
 }];
 }
 */

@end
