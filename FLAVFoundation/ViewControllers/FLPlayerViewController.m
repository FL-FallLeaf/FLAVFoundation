//
//  FLPlayerViewController.m
//  FLAVFoundation
//
//  Created by Leaf on 2017/10/22.
//  Copyright © 2017年 leaf. All rights reserved.
//

#import "FLPlayerViewController.h"
#import "FLPlayerView.h"
#import "FLAVManager.h"
@import AVFoundation;

@interface FLPlayerViewController ()

@property (weak, nonatomic) IBOutlet FLPlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;

@end

@implementation FLPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    switch (self.mediaType) {
        case FLMediaTypeMovie:
        {
            AVPlayer *player = [AVPlayer playerWithURL:self.data];
            self.playerView.player = player;
            [player play];
        }
            break;
            
        case FLMediaTypePhoto:
        {
            self.photoImageView.image = [UIImage imageWithData:self.data scale:[UIScreen mainScreen].scale];
        }
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)goback:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)save:(id)sender {
    
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
                    switch (self.mediaType) {
                        case FLMediaTypeMovie:
                        {
                            PHAssetCreationRequest *createAssetRequest = [PHAssetCreationRequest creationRequestForAsset];
                            [createAssetRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:self.data options:nil];
                        }
                            break;
                            
                        case FLMediaTypePhoto:
                        {
                            PHAssetCreationRequest *createAssetRequest = [PHAssetCreationRequest creationRequestForAsset];
                            [createAssetRequest addResourceWithType:PHAssetResourceTypePhoto data:self.data options:nil];
                        }
                            break;
                    }
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    
                }];
            }
                break;
        }
    }];
    
    [self dismissViewControllerAnimated:NO completion:nil];
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
