//
//  LFImagePicker.m
//  LFQRCode
//
//  Created by 张林峰 on 2017/5/16.
//  Copyright © 2017年 张林峰. All rights reserved.
//

#import "LFImagePicker.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

@interface LFImagePicker () <UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (nonatomic, copy) void(^resultBlock)(UIImage *);

@end

@implementation LFImagePicker

#pragma mark - 外部方法

//原生相册单选
- (void)pickSingleImageWithController:(UIViewController *)ctr allowsEditing:(BOOL)allowsEditing resultBlock:(void(^)(UIImage *image))resultBlock {
    NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *message = [NSString stringWithFormat:@"%@需要访问你的相册权限才能进行选取照片",appDisplayName];
    if (@available(iOS 11.0, *)) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied) {
                [self askPermission:ctr message:message];
            } else {
                self.resultBlock = resultBlock;
                [self presentToPhotoLibraryWithCtr:ctr allowsEditing:allowsEditing];
            }
        }];
    } else {
        PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
        if (authorizationStatus == PHAuthorizationStatusRestricted || authorizationStatus == PHAuthorizationStatusDenied) {
            [self askPermission:ctr message:message];
        } else {
            self.resultBlock = resultBlock;
            [self presentToPhotoLibraryWithCtr:ctr allowsEditing:allowsEditing];
        }
    }
}

//原生拍照
- (void)pickImageFromCameraWithController:(UIViewController *)ctr allowsEditing:(BOOL)allowsEditing resultBlock:(void(^)(UIImage *image))resultBlock {
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        self.resultBlock = resultBlock;
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.delegate = self;
        picker.allowsEditing = allowsEditing;
        picker.showsCameraControls = YES;
        picker.modalPresentationStyle = UIModalPresentationCustom;
        [ctr presentViewController:picker animated:YES completion:^{
        }];
    } else {
        NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
        NSString *message = [NSString stringWithFormat:@"%@需要访问你的相机权限才能进行拍照",appDisplayName];
        [self askPermission:ctr message:message];
    }
}

#pragma mark - 内部方法
//跳到原生相册
- (void)presentToPhotoLibraryWithCtr:(UIViewController *)ctr allowsEditing:(BOOL)allowsEditing {
    UIImagePickerController *pickerImage = [[UIImagePickerController alloc] init];
    pickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickerImage.delegate = self;
    pickerImage.allowsEditing = allowsEditing;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        pickerImage.allowsEditing = NO;
    }
    [ctr presentViewController:pickerImage animated:YES completion:^{
    }];
}

#pragma mark - 权限


//询问权限
- (void)askPermission:(UIViewController *)ctr message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) { }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"去开启" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }]];
    [ctr presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate
//获取图片回调
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    //获取裁剪后的图像
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || !picker.allowsEditing) {
        //获取源图像（未经裁剪）
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    if (self.resultBlock) {
        self.resultBlock(image);
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
