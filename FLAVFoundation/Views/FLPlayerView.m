//
//  FLPlayerView.m
//  FLAVFoundation
//
//  Created by Leaf on 2017/10/22.
//  Copyright © 2017年 leaf. All rights reserved.
//

#import "FLPlayerView.h"

@interface FLPlayerView ()

@end

@implementation FLPlayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return self.playerLayer.player;
}

- (void)setPlayer:(AVPlayer *)player {
    self.playerLayer.player = player;
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

@end
