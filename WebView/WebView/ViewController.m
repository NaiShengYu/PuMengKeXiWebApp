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
#import <MapKit/MapKit.h>
#import "ScanningViewController.h"
#import "CustomAccount.h"
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
    [self.webView stringByEvaluatingJavaScriptFromString:@"pay_fail()"];
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
    
    testJO.dhmap = ^(CLLocationCoordinate2D location) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [blockSelf navLocation:location];
        });
    };
//    testJO.startLocationBlok = ^{
//        //
//    };
     [blockSelf getLocation];
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

- (void)getLocation{
    __weak __typeof(&*self)blockSelf = self;

    NSString *location = [NSString stringWithFormat:@"getLatlng(%f,%f)",[CustomAccount sharedCustomAccount].lat,[CustomAccount sharedCustomAccount].lng];
    NSLog(@"定位的经纬度：%@",location);
        // UI更新代码
    
//    [[NSOperationQueue mainQueue] addOperationWithBlock:^{//在主线程中调用
        [self.webView stringByEvaluatingJavaScriptFromString:location];

//    }];
  
}


- (void)navLocation:(CLLocationCoordinate2D)endLocation{
    
    NSArray *maps = [self getInstalledMapwithLocation:endLocation];
    
    //选择
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"选择地图" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSInteger index = maps.count;
    
    for (int i = 0; i < index; i++) {
        
        NSString * title = maps[i][@"title"];
        
        //苹果原生地图方法
        if (i == 0) {
            
            UIAlertAction * action = [UIAlertAction actionWithTitle:title style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                [self navAppleMapWithendLocation:endLocation];
            }];
            [alert addAction:action];
            
            continue;
        }
        
        
        UIAlertAction * action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            NSString *urlString = maps[i][@"url"];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        }];
        
        [alert addAction:action];
        
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}


- (NSArray *)getInstalledMapwithLocation:(CLLocationCoordinate2D)endLocation{
    NSMutableArray *maps = [[NSMutableArray alloc]init];
    
    //苹果地图
    NSMutableDictionary *iosMapDic = [[NSMutableDictionary alloc]init];
    [iosMapDic setObject:@"苹果地图" forKey:@"title"];
    [maps addObject:iosMapDic];
    
    //百度地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        NSMutableDictionary *baiduMapDic = [NSMutableDictionary dictionary];
        baiduMapDic[@"title"] = @"百度地图";
        NSString *urlString = [[NSString stringWithFormat:@"baidumap://map/direction?origin={{我的位置}}&destination=%f,%f&mode=driving&coord_type=gcj02",endLocation.latitude,endLocation.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        baiduMapDic[@"url"] = urlString;
        [maps addObject:baiduMapDic];
    }
    
    
    //高德地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]] ==YES) {
        NSMutableDictionary *iosamapDic = [[NSMutableDictionary alloc]init];
        [iosamapDic setObject:@"高德地图" forKey:@"title"];
        NSString *urlString = [[NSString stringWithFormat:@"iosamap://navi?sourceApplication=%@&backScheme=%@&lat=%f&lon=%f&dev=0&style=2",@"导航功能",@"nav123456",endLocation.latitude,endLocation.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [iosamapDic setObject:urlString forKey:@"url"];
        
        [maps addObject:iosamapDic];
    }
    
    //谷歌地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        NSMutableDictionary *googleMapDic = [NSMutableDictionary dictionary];
        googleMapDic[@"title"] = @"谷歌地图";
        NSString *urlString = [[NSString stringWithFormat:@"comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%f,%f&directionsmode=driving",@"导航测试",@"nav123456",endLocation.latitude, endLocation.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        googleMapDic[@"url"] = urlString;
        [maps addObject:googleMapDic];
    }
    
    
    //腾讯地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"qqmap://"]]) {
        NSMutableDictionary *qqMapDic = [NSMutableDictionary dictionary];
        qqMapDic[@"title"] = @"腾讯地图";
        NSString *urlString = [[NSString stringWithFormat:@"qqmap://map/routeplan?from=我的位置&type=drive&tocoord=%f,%f&to=终点&coord_type=1&policy=0",endLocation.latitude, endLocation.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        qqMapDic[@"url"] = urlString;
        [maps addObject:qqMapDic];
    }
    

   
    
    return maps;
}

//苹果地图
- (void)navAppleMapWithendLocation:(CLLocationCoordinate2D)endLocation
{
    //    CLLocationCoordinate2D gps = [JZLocationConverter bd09ToWgs84:self.destinationCoordinate2D];
    
    //终点坐标
   
    
    
    //用户位置
    MKMapItem *currentLoc = [MKMapItem mapItemForCurrentLocation];
    //终点位置
    MKMapItem *toLocation = [[MKMapItem alloc]initWithPlacemark:[[MKPlacemark alloc]initWithCoordinate:endLocation addressDictionary:nil] ];
    
    
    NSArray *items = @[currentLoc,toLocation];
    //第一个
    NSDictionary *dic = @{
                          MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving,
                          MKLaunchOptionsMapTypeKey : @(MKMapTypeStandard),
                          MKLaunchOptionsShowsTrafficKey : @(YES)
                          };
    //第二个，都可以用
    //    NSDictionary * dic = @{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
    //                           MKLaunchOptionsShowsTrafficKey: [NSNumber numberWithBool:YES]};
    
    [MKMapItem openMapsWithItems:items launchOptions:dic];
    
    
    
}


@end
