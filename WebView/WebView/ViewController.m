//
//  ViewController.m
//  WebView
//
//  Created by Nasheng Yu on 2017/12/29.
//  Copyright © 2017年 Nasheng Yu. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JSAndOCTask.h"
#import <ShareSDKConnector/ShareSDKConnector.h>
#import <ShareSDK/ShareSDK.h>
#import <WXApi.h>
#import <ShareSDKUI/ShareSDK+SSUI.h>
#import <WXApiObject.h>

#import <AlipaySDK/AlipaySDK.h>

#import "ScanningViewController.h"

#define screenWigth [[UIScreen mainScreen] bounds].size.width
#define screenHeight [[UIScreen mainScreen] bounds].size.height
@interface ViewController ()<UIWebViewDelegate,TestJSObjectProtocol>
@property (nonatomic,strong)UIWebView *webView;

@property (nonatomic,copy)NSString *oid;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.oid = @"";
    [[NSURLCache sharedURLCache]removeAllCachedResponses];

    if (@available(iOS 11.0, *)) {
        _webView=[[UIWebView alloc]initWithFrame:CGRectMake(0, -20, screenWigth, screenHeight+20)];
    } else {
        _webView=[[UIWebView alloc]initWithFrame:CGRectMake(0, 0, screenWigth, screenHeight)];
    }

    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status ==AFNetworkReachabilityStatusNotReachable) {
            NSLog(@"网络连接不上");
        }else{
            [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.pmkx2018.com/app/"]]];            
        }}];
    
    
    _webView.delegate =self;
    _webView.scalesPageToFit =YES;
    [_webView setMediaPlaybackRequiresUserAction:NO];
    [self.view addSubview:_webView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wxPaySuccess) name:@"paySuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aliaySuccess) name:@"AlipaySuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wxPayFails) name:@"payFails" object:nil];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
    
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    
    NSLog(@"开始调用了");    
}

- (void)wxPaySuccess{
    NSLog(@"成功了");
    NSString *pay =[NSString stringWithFormat:@"pay_back(%@)",self.oid];
    NSLog(@"成功后调用：%@",pay);
    [self.webView stringByEvaluatingJavaScriptFromString:pay];

}
- (void)wxPayFails{
    NSLog(@"失败了");
    [self.webView stringByEvaluatingJavaScriptFromString:@"wxpay_back()"];
    
}
- (void)aliaySuccess{
    [self.webView stringByEvaluatingJavaScriptFromString:@"alipay_back()"];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
    NSLog(@"结束调用了");
    JSContext *context =[webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    JSAndOCTask *testJO=[JSAndOCTask new];
    __weak __typeof(&*self)blockSelf = self;
    testJO.wxshare = ^(NSString *link, NSString *img, NSString *desc, NSString *title) {
        NSArray* imageArray = @[img];
        NSMutableDictionary *param =[[NSMutableDictionary alloc]init];
        [param SSDKSetupShareParamsByText:desc
                                   images:imageArray
                                      url:[NSURL URLWithString:link]
                                    title:title
                                     type:SSDKContentTypeAuto];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{//在主线程中调用
            
            [ShareSDK showShareActionSheet:nil items:nil shareParams:param onShareStateChanged:^(SSDKResponseState state, SSDKPlatformType platformType, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error, BOOL end) {
                switch (state) {
                    case SSDKResponseStateSuccess:
                    {
                        [blockSelf.webView stringByEvaluatingJavaScriptFromString:@"share_success()"];

                        break;
                    }
                    case SSDKResponseStateFail:
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"分享失败"
                                                                        message:[NSString stringWithFormat:@"%@",error]
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil, nil];
                        [alert show];
                        break;
                    }
                    default:
                        break;
                }
            }];
        
        }];
       
    };
    testJO.apiPayBlock = ^(NSString *url) {
        [blockSelf zhifubaoPay:url];
    };
    testJO.wxPayBlok = ^(NSString *oid) {
        blockSelf.oid = oid;
    };
    testJO.scanBlok = ^{
        [blockSelf scanning];
        
     
        
        
    };
    
    context[@"webapp"] =testJO;
    
}

- (void)zhifubaoPay:(NSString *)url{
    NSArray *arr = [url componentsSeparatedByString:@"*****"];
    
    url = arr[0];
    self.oid = arr[1];
    
    url =[url stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    url =[url stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    //支付
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{//在主线程中调用
        // UI更新代码
        [[AlipaySDK defaultService] payOrder:url fromScheme:@"pumengkexi2018" callback:^(NSDictionary *resultDic) {
            if ([resultDic[@"resultStatus"] integerValue]==9000) {
                
            }
        }];
        
    }];
    
   
}

- (void)wxLogin{
    NSLog(@"微信登陆");
    __weak __typeof(&*self)blockSelf = self;
    [ShareSDK getUserInfo:SSDKPlatformTypeWechat onStateChanged:^(SSDKResponseState state, SSDKUser *user, NSError *error) {
        [blockSelf.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"wxback('%@','%@','%@')",user.nickname,user.icon,user.uid]];
        NSLog(@"%@",user.uid);
  
    }];
}

#pragma mark --扫描
- (void)scanning{
    NSLog(@"扫描");
    __weak __typeof(&*self)blockSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        
        ScanningViewController *scanVC = [[ScanningViewController alloc]init];
        scanVC.scanResultBlock = ^(NSString *ulr) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *url = [NSString stringWithFormat:@"scan_back(%@)",ulr];
                NSLog(@"url===%@",url);
                [self.webView stringByEvaluatingJavaScriptFromString:url];

            });
        };
        [self.navigationController pushViewController:scanVC animated:YES];
        
    });
  
    
}

@end
