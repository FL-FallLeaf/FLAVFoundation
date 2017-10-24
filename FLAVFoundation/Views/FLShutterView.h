//
//  FLShutterView.h
//  FLAVFoundation
//
//  Created by Leaf on 2017/9/7.
//  Copyright © 2017年 leaf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLShutterView : UIView

/**
 最大录制时间
 */
@property (nonatomic, assign) NSTimeInterval maxDuration;

/**
 捕捉图片
 */
@property (nonatomic, copy) void(^takePhoto)(void);

/**
 开始捕捉视频
 */
@property (nonatomic, copy) void(^didStartRecordingVideo)(void);

/**
 捕捉视频完成
 */
@property (nonatomic, copy) void(^didFinishRecordingVideo)(void);

@end
