//
//  YJImagePickViewController.m
//  YJImageDetect
//
//  Created by 包宇津 on 2017/8/16.
//  Copyright © 2017年 baoyujin. All rights reserved.
//

#import "YJImagePickViewController.h"
#import "MobileNet.h"
@interface YJImagePickViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *nameLable;
@property (nonatomic, strong) UILabel *propLable;
@end

@implementation YJImagePickViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(20, 80, 80, 40);
    [button setTitle:@"选择相册" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:18];
//    [button setCenter:self.view.center];
    [button addTarget:self action:@selector(imagePicker) forControlEvents:UIControlEventTouchUpInside];
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 170, 224, 224)];
    [self.view addSubview:_imageView];
    [self.view addSubview:button];
    self.nameLable = [[UILabel alloc] initWithFrame:CGRectMake(130, 70, 200, 30)];
//    _nameLable.backgroundColor = [UIColor greenColor];
    [self.view addSubview:_nameLable];
    
    self.propLable = [[UILabel alloc] initWithFrame:CGRectMake(130, 120, 80, 30)];
//    _propLable.backgroundColor = [UIColor blueColor];
    [self.view addSubview:_propLable];
}

- (void)imagePicker {
    UIImagePickerController *pickerCtr = [[UIImagePickerController alloc] init];
    pickerCtr.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickerCtr.delegate = self;
    [self presentViewController:pickerCtr animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        [self.imageView setImage:image];
//        UIImage *newImage = [self scaleToSize:image size:CGSizeMake(224, 224)];
        MobileNet *model = [[MobileNet alloc] init];
        CVPixelBufferRef imageBuffer = [self ConvertToCVPixelBufferRefFromImage:image.CGImage withSize:CGSizeMake(224, 224)];
        MobileNetOutput *output = [model predictionFromImage:imageBuffer error:nil];
        self.nameLable.text = output.classLabel;
        self.propLable.text = [NSString stringWithFormat:@"%.2f",[[output.classLabelProbs valueForKey:output.classLabel] floatValue]];
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

-(CVPixelBufferRef) ConvertToCVPixelBufferRefFromImage: (CGImageRef )image withSize:(CGSize) size {
    NSDictionary *options =[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    
    CVPixelBufferRef pxbuffer =NULL;
    CVReturn status =CVPixelBufferCreate(kCFAllocatorDefault,size.width,size.height,kCVPixelFormatType_32BGRA,(__bridge CFDictionaryRef) options,&pxbuffer);
    
    NSParameterAssert(status ==kCVReturnSuccess && pxbuffer !=NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer,0);
    void *pxdata =CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata !=NULL);
    
    CGColorSpaceRef rgbColorSpace=CGColorSpaceCreateDeviceRGB();
    CGContextRef context =CGBitmapContextCreate(pxdata,size.width,size.height,8,4*size.width,rgbColorSpace,kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little);
    NSParameterAssert(context);
    
    
    CGContextDrawImage(context,CGRectMake(0,0,CGImageGetWidth(image),CGImageGetHeight(image)),image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer,0);
    
    
    return pxbuffer;
}
@end



