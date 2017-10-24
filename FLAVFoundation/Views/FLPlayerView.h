//
//  FLPlayerView.h
//  FLAVFoundation
//
//  Created by Leaf on 2017/10/22.
//  Copyright © 2017年 leaf. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;

@interface FLPlayerView : UIView

@property (nonatomic, strong) AVPlayer *player;
@property (readonly) AVPlayerLayer *playerLayer;

@end
