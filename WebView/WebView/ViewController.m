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
#import "APAuthInfo.h"
#import "APRSASigner.h"

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



#pragma mark -
#pragma mark   ==============点击模拟授权行为==============

- (void)doAPAuth
{
    // 重要说明
    // 这里只是为了方便直接向商户展示支付宝的整个支付流程；所以Demo中加签过程直接放在客户端完成；
    // 真实App里，privateKey等数据严禁放在客户端，加签过程务必要放在服务端完成；
    // 防止商户私密数据泄露，造成不必要的资金损失，及面临各种安全风险；
    /*============================================================================*/
    /*=======================需要填写商户app申请的===================================*/
    /*============================================================================*/
    NSString *pid = @"2088131502634896";
    NSString *appID = @"2018062060395745";
    
    // 如下私钥，rsa2PrivateKey 或者 rsaPrivateKey 只需要填入一个
    // 如果商户两个都设置了，优先使用 rsa2PrivateKey
    // rsa2PrivateKey 可以保证商户交易在更加安全的环境下进行，建议使用 rsa2PrivateKey
    // 获取 rsa2PrivateKey，建议使用支付宝提供的公私钥生成工具生成，
    // 工具地址：https://doc.open.alipay.com/docs/doc.htm?treeId=291&articleId=106097&docType=1
    NSString *rsa2PrivateKey = @"MIIEpAIBAAKCAQEAztfMqelirEobdWHKva/rAM40U0jUw86XqW+KSIR1m6s45ttn5fa08Cr55VuhSiJiLuMnq+xGwBH/13dXnQWiv/VT1eKAb65dEX4qKA/7FtEhRInYjCh74IieW2OPMnAOMIwDiTTg5r9Os8BOeoZCjeh10fU27lFNCvwLujH9XNa1jEghqmqssH1KqGe+HTMi27j+Ubys1QQZ8bBl/hICccZIN/il8W6A0SGWuqylm/Ri6l9nVkRQCHHeosH/4vSBiRtU5iApuPyy+9uM5BdmbviwYe2Xj2d6aP8SPx5vBygpG6v/pM5/8izY5NrHwJvyb+173UE6zdf4O5p5hhrcYwIDAQABAoIBAQDGUXpV3wNQla1GGoE85hK4Lv1UbRwysT4QonU/mmD45G4mSm+Pub86FrqLAhPe9KCWvA0pdd1QAvH+MNq8Hs8wpZPAGu9yJQfu4byhtNDVy6XOBSyvFZHQcq0Ciq6deXrhaR1qzFxmYT6gcd3M9DWTwjJVIHuOfD0WLxs/Zva5rxfWJCv9IWSumUOzRV2kOGxQwXn3OJJ0i/tGAjgdmzrQl+vLvzz1vRhgLRR3b6kvMxzZ0KbqVvl/ba2z6xWuMS4Z9dOUYqbdeuUVbL9ndKa7/Py3sXUJ5RlW6pMmmdWRUiVadC29iwkVWsDjFhfB1/LpGz40nI3TIG4EO6eeaRmhAoGBAP6Q/MKhWEQqjLNKX1HYuBtm6E0EICqz025Z6WNQ9sA4woTqkyLAZiFDqZ5BLCyVOvwmIifb36RQGiFGiq5ZBMSRP43I4eZ93gou/ntqcc0t0WJ1bIkB0BOmbAaQmlrWdOgSeWWazFVUWoAj6SgsfJc2MSPcEk4MXxpzkvbNBsZ9AoGBANACAizrMesKgMW6djESkpduHC7EKEJj0O4CRKnL4HF7o7Xb8etWeTNqs9dG2iY2cFgxnU/s3iDhn/XvTdmTbPVbci/scVasB8Cj/Bfcz2gBE8dHwUtTMVcZYrfp2NodA+00cSmrILH5BFW7OlveC0rcElOKPbIbOTU9y+pTtkRfAoGAC7UTSsgszQW/7sbu107GOMxkxpX3/L7EbIDKEP06O+DgYUiAd8qtZ7464MJSi8JZMht22qpsAJyGdx1NZ3NEmt2rNJQWf4kuWv2KSpa8oRkIViTcVvi0XxL6SNsBnkfanIms95VE7G+ysc30/Rn+qN2fKO0IEnrTLN4/1gXb1+kCgYBg1E6G8oWuUJlZck+K0IaFD7D25EGJhkXARjYIhOvaaB/xjI21a+/Hy6gkUstCdp0dsRr2FeHhlKaOKfQnkMVsAkHJpVutaS/CsZOs2BGE7Nt0LScCFZwmW57k1msoPdGSHpN/PjZeIvmtnxavpVHEa2XslbHas2mSK049qvJyKQKBgQC/F9W+bZ0Xd78GOpPn21/lE9fopE/o9Xxv87vmkCKQOQMfpdTTkiW2iDhdCZSbcet6NzU0aIjtglmMGLkxnaaDnjWgpRswJNgJk6Rd2k4ez3Bj1ypBnGdu5UEG6psCPMIHtNFCPMO/kwBT6ZziQXqsbqMNANLovtl8gLiXMw7C3w==";
    NSString *rsaPrivateKey = @"";
    /*============================================================================*/
    /*============================================================================*/
    /*============================================================================*/
    
    //pid和appID获取失败,提示
    if ([pid length] == 0 ||
        [appID length] == 0 ||
        ([rsa2PrivateKey length] == 0 && [rsaPrivateKey length] == 0))
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                       message:@"缺少pid或者appID或者私钥,请检查参数设置"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"知道了"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action){
                                                           
                                                       }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:^{ }];
        return;
    }
    
    //生成 auth info 对象
    APAuthInfo *authInfo = [APAuthInfo new];
    authInfo.pid = pid;
    authInfo.appID = appID;
    
    //auth type
    NSString *authType = [[NSUserDefaults standardUserDefaults] objectForKey:@"authType"];
    if (authType) {
        authInfo.authType = authType;
    }
    
    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    NSString *appScheme = @"pumengkexi2018";
    
    // 将授权信息拼接成字符串
    NSString *authInfoStr = [authInfo description];
    NSLog(@"authInfoStr = %@",authInfoStr);
    
    // 获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    NSString *signedString = nil;
    APRSASigner* signer = [[APRSASigner alloc] initWithPrivateKey:((rsa2PrivateKey.length > 1)?rsa2PrivateKey:rsaPrivateKey)];
    if ((rsa2PrivateKey.length > 1)) {
        signedString = [signer signString:authInfoStr withRSA2:YES];
    } else {
        signedString = [signer signString:authInfoStr withRSA2:NO];
    }
    
    // 将签名成功字符串格式化为订单字符串,请严格按照该格式
    if (signedString.length > 0) {
        authInfoStr = [NSString stringWithFormat:@"%@&sign=%@&sign_type=%@", authInfoStr, signedString, ((rsa2PrivateKey.length > 1)?@"RSA2":@"RSA")];
        [[AlipaySDK defaultService] auth_V2WithInfo:authInfoStr
                                         fromScheme:appScheme
                                        callback:^(NSDictionary *resultDic) {
                        NSLog(@"result = %@",resultDic);
                                               // 解析 auth code
                        NSString *result = resultDic[@"result"];
                                               NSString *authCode = nil;
                                               if (result.length>0) {
                                                   NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                                                   for (NSString *subResult in resultArr) {
                                                       if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                                                           authCode = [subResult substringFromIndex:10];
                                                           break;
                                                       }
                                                   }
                                               }
                                               NSLog(@"授权结果 authCode = %@", authCode?:@"");
                                           }];
    }
}







@end
