//
//  FLPlayerViewController.h
//  FLAVFoundation
//
//  Created by Leaf on 2017/10/22.
//  Copyright © 2017年 leaf. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FLMediaType) {
    FLMediaTypeMovie,
    FLMediaTypePhoto,
};

@interface FLPlayerViewController : UIViewController

@property (nonatomic, assign) FLMediaType mediaType;
@property (nonatomic, strong) id data;

@end
