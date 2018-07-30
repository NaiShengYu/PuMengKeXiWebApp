//
//  ViewController.m
//  扫描
//
//  Created by 俞乃胜 on 16/3/1.
//  Copyright © 2016年 俞乃胜. All rights reserved.
//

#import "ScanningViewController.h"
#import "UIView+SDExtension.h"
#import <AVFoundation/AVFoundation.h>
static const CGFloat kBorderW = 150;
static const CGFloat kMargin = 38;

@interface ScanningViewController () <AVCaptureMetadataOutputObjectsDelegate, UIAlertViewDelegate>
@property (nonatomic,strong)UIImageView *scanNetImageView;
@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, weak) UIView *maskView;

@end

@implementation ScanningViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor =[UIColor blackColor];
    //    self.view.backgroundColor = [UIColor whiteColor];
    //    [self.navigationItem.backBarButtonItem setTitleTextAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:5]} forState:UIControlStateNormal];
    //
    //设置导航栏返回按钮
    UIBarButtonItem* leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(backToMainVC)];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
    self.navigationController.navigationBar.hidden = NO;
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:76/255.0 green:76/255.0 blue:76/255.0 alpha:1]];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.navigationItem.title = @"二维码扫描";
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disMiss)]];
    self.view.clipsToBounds = YES;
    
    [self setupMaskView];
    
    [self setupBottomBar];
    
    [self setupScanWindowView];
    
    [self beginScanning];
  
}

//实现返回主VC的方法
-(void)backToMainVC
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setupMaskView
{
    UIView *mask = [[UIView alloc] init];
    _maskView = mask;
    
    mask.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7].CGColor;
    mask.layer.borderWidth = kBorderW;
    
    mask.bounds = CGRectMake(0, 0, self.view.sd_width + kBorderW + kMargin * 2, self.view.sd_height * 0.9);
    mask.center = CGPointMake(self.view.sd_width * 0.5, self.view.sd_height * 0.5);
    mask.sd_y = 0;
    
    [self.view addSubview:mask];
}

- (void)setupBottomBar
{
    CGFloat maxY = CGRectGetMaxY(_maskView.frame);
    UIView *bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, maxY, self.view.sd_width, self.view.sd_height * 0.1)];
    bottomBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    [self.view addSubview:bottomBar];
    
    UILabel* lable = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.sd_width, self.view.sd_height * 0.1)];
    lable.text = @"将二维码放入框内即可自动扫描";
    lable.textColor = [UIColor whiteColor];
    lable.font = [UIFont systemFontOfSize:13];
    lable.textAlignment = NSTextAlignmentCenter;
    [bottomBar addSubview:lable];
}

- (void)setupScanWindowView
{
    //    CGFloat scanWindowH = self.view.sd_height * 0.9 - kBorderW * 2;
    //    CGFloat scanWindowW = self.view.sd_width - kMargin * 2;
    CGFloat scanWindowH = self.view.sd_height * 0.9 - kBorderW * 2;
    CGFloat scanWindowW = self.view.sd_width - kMargin * 2;
    
    UIView *scanWindow = [[UIView alloc] initWithFrame:CGRectMake(kMargin, kBorderW, scanWindowW, scanWindowH)];
    scanWindow.clipsToBounds = YES;
    [self.view addSubview:scanWindow];
    
    CGFloat scanNetImageViewH = 241;
    CGFloat scanNetImageViewW = scanWindow.sd_width;
    _scanNetImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scan_net"]];
    _scanNetImageView.frame = CGRectMake(0, -scanNetImageViewH, scanNetImageViewW, scanNetImageViewH);
    CABasicAnimation *scanNetAnimation = [CABasicAnimation animation];
    scanNetAnimation.keyPath = @"transform.translation.y";
    scanNetAnimation.byValue = @(scanWindowH);
    scanNetAnimation.duration = 5.0;
    scanNetAnimation.repeatCount = MAXFLOAT;
    [_scanNetImageView.layer addAnimation:scanNetAnimation forKey:nil];
    [scanWindow addSubview:_scanNetImageView];
    
    CGFloat buttonWH = 18;
    
    
    UIButton *topLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonWH, buttonWH)];
    [topLeft setImage:[UIImage imageNamed:@"scan_1"] forState:UIControlStateNormal];
    [scanWindow addSubview:topLeft];
    
    UIButton *topRight = [[UIButton alloc] initWithFrame:CGRectMake(scanWindowW - buttonWH, 0, buttonWH, buttonWH)];
    [topRight setImage:[UIImage imageNamed:@"scan_2"] forState:UIControlStateNormal];
    [scanWindow addSubview:topRight];
    
    UIButton *bottomLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, scanWindowH - buttonWH, buttonWH, buttonWH)];
    [bottomLeft setImage:[UIImage imageNamed:@"scan_3"] forState:UIControlStateNormal];
    [scanWindow addSubview:bottomLeft];
    
    UIButton *bottomRight = [[UIButton alloc] initWithFrame:CGRectMake(topRight.sd_x, bottomLeft.sd_y, buttonWH, buttonWH)];
    [bottomRight setImage:[UIImage imageNamed:@"scan_4"] forState:UIControlStateNormal];
    [scanWindow addSubview:bottomRight];
}

- (void)beginScanning
{
    //获取摄像设备
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) return;
    //创建输出流
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc]init];
    output.rectOfInterest = CGRectMake(0.1, 0, 0.9, 1);
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //初始化链接对象mr1po
    _session = [[AVCaptureSession alloc]init];
    //高质量采集率
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    
    [_session addInput:input];
    [_session addOutput:output];
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    layer.frame=self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
    //开始捕获
    [_session startRunning];
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count>0) {
        [_session stopRunning];
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex : 0 ];
        
        
        [_scanNetImageView.layer removeAllAnimations];
        
        if (self.scanResultBlock) {
            self.scanResultBlock(metadataObject.stringValue);
        }
        [self.navigationController popViewControllerAnimated:YES];
        
//        ScanningInfoViewController *scannInfoVC =[ScanningInfoViewController new];
//        scannInfoVC.scanningResult =metadataObject.stringValue;
//        [self.navigationController pushViewController:scannInfoVC animated:YES];
        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"扫描结果" message:metadataObject.stringValue delegate:self cancelButtonTitle:@"退出" otherButtonTitles:@"再次扫描", nil];
//        [alert show];
    }
}

- (void)disMiss
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    if (!parent) {
        self.navigationController.navigationBar.hidden = NO;
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self disMiss];
    } else if (buttonIndex == 1) {
        [_session startRunning];
    }
}


@end

