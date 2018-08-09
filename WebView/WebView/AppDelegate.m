//
//  AppDelegate.m
//  WebView
//
//  Created by Nasheng Yu on 2017/12/29.
//  Copyright © 2017年 Nasheng Yu. All rights reserved.
//

#import "AppDelegate.h"
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKConnector/ShareSDKConnector.h>
#import <WXApi.h>
#import <AlipaySDK/AlipaySDK.h>
#import "ViewController.h"
#import "ScanningViewController.h"
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "CustomAccount.h"
@interface AppDelegate ()<WXApiDelegate,CLLocationManagerDelegate>
@property (nonatomic,strong)CLLocationManager *locationManager;

@end
@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
// Override point for customization after application launch.

    _window =[[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    [_window makeKeyAndVisible];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:[[ViewController alloc]init]];
    _window.rootViewController =nav;
    
    
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc]init];
    }
    self.locationManager.delegate =self;
    [self.locationManager requestWhenInUseAuthorization];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;//最精确的定位
    self.locationManager.distanceFilter = kCLDistanceFilterNone; // 默认是kCLDistanceFilterNone，也可以设置其他值，表示用户移动的距离小于该范围内就不会接收到通知
    [self.locationManager startUpdatingLocation];
    
[ShareSDK registerActivePlatforms:@[
                                    @(SSDKPlatformTypeWechat)
                               
                                    ]
                         onImport:^(SSDKPlatformType platformType)
 {
     switch (platformType)
     {
         case SSDKPlatformTypeWechat:
             [ShareSDKConnector connectWeChat:[WXApi class]];
             break;
   
         default:
             break;
     }
 }
                  onConfiguration:^(SSDKPlatformType platformType, NSMutableDictionary *appInfo)
 {
     
     switch (platformType)
     {
    
         case SSDKPlatformTypeWechat:
             [appInfo SSDKSetupWeChatByAppId:@"wxd242b4fc5133bf46"
                                   appSecret:@"3fbbea8fc05435256da6fbfaad2adf09"];
             break;
     
                                             default:
               break;
               }
               }];

[WXApi registerApp:@"wxd242b4fc5133bf46" enableMTA:YES];



return YES;
}




- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    CLLocation *curLocation = [locations lastObject];
    // 通过location  或得到当前位置的经纬度
    CLLocationCoordinate2D curCoordinate2D = curLocation.coordinate;
    [CustomAccount sharedCustomAccount].lat = curCoordinate2D.latitude;
    [CustomAccount sharedCustomAccount].lng = curCoordinate2D.longitude;
}





- (void)onResp:(BaseResp *)resp{

if ([resp isKindOfClass:[PayResp class]]){
    PayResp*response=(PayResp*)resp;
    switch(response.errCode){
        case WXSuccess:{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"paySuccess" object:nil];

        }
            break;
        default:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"payFails" object:nil];

            NSLog(@"支付失败，retcode=%d",resp.errCode);
            break;
    }
}

}
-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options{

if ([url.host isEqualToString:@"safepay"]) {
    // 支付跳转支付宝钱包进行支付，处理支付结果
    [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
        if ([resultDic[@"resultStatus"] integerValue]==9000) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"paySuccess" object:nil];
        }else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"payFails" object:nil];

        }

        
    }];
    return YES;
}
return [WXApi handleOpenURL:url delegate:self];


}


//ios9以下的方法
- (BOOL)application:(UIApplication *)application
        openURL:(NSURL *)url
sourceApplication:(NSString *)sourceApplication
     annotation:(id)annotation
{

[self application:application handleOpenURL:url];
[WXApi handleOpenURL:url delegate:self];
if ([url.host isEqualToString:@"safepay"]) {
    // 支付跳转支付宝钱包进行支付，处理支付结果
    [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
        NSLog(@"result = %@",resultDic);
        //  [self alip]
        if ([resultDic[@"resultStatus"] integerValue]==9000) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"paySuccess" object:nil];
        }else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"payFails" object:nil];
            
        }
        
    }];
    
}
return YES;
}




- (void)applicationWillResignActive:(UIApplication *)application {
// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
