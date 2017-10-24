//
//  FLCameraView.h
//  FLAVFoundation
//
//  Created by Leaf on 2017/9/6.
//  Copyright © 2017年 leaf. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FLCameraFlashMode) {
    FLCameraFlashModeOff,
    FLCameraFlashModeOn,
    FLCameraFlashModeAuto,
};

@interface FLCameraView : UIView

@property (nonatomic, copy) void(^changeFlashMode)(void(^completion)(FLCameraFlashMode flashMode, NSError *error));
@property (nonatomic, copy) void(^focus)(CGPoint point);

@end
