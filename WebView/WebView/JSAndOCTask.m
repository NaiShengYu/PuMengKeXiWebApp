//
//  JSAndOCTask.m
//  WebView
//
//  Created by 俞乃胜 on 2017/12/29.
//  Copyright © 2017年 Nasheng Yu. All rights reserved.
//

#import "JSAndOCTask.h"
#import <WXApi.h>
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKUI/ShareSDK+SSUI.h>
#import <ShareSDKConnector/ShareSDKConnector.h>
#import <SVProgressHUD.h>
@interface JSAndOCTask()<WXApiDelegate>
@end
@implementation JSAndOCTask

- (void)share:(NSString *)ID{
    NSLog(@"%@",ID);
    NSData *data =[ID dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *result =[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    if (self.wxshare) {
        self.wxshare(result[@"share_url"], result[@"share_img"], result[@"share_desc"], result[@"share_title"]);
    }
}

- (void)share:(NSString *)link AndImg:(NSString *)img AndDesc:(NSString *)desc AndTitle:(NSString *)title{
    
    if (self.wxshare) {
        self.wxshare(link, img, desc, title);
    }
}
- (void)alipay:(NSString *)url{
    if (self.apiPayBlock) {
        self.apiPayBlock(url);
    }
}

- (void)wxpay:(NSString *)ID{
        NSData *data =[ID dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *result =[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSDictionary *dataDic =result[@"data"][0];
    NSDictionary *wxDic = dataDic[@"wx"];
    PayReq *request =[[PayReq alloc]init];
    request.openID = wxDic[@"appid"];
    request.partnerId =wxDic[@"partnerid"];
    request.prepayId =wxDic[@"prepayid"];
    request.package =wxDic[@"package"];
    request.nonceStr=wxDic[@"noncestr"];
    request.timeStamp=[wxDic[@"timestamp"] intValue];
    request.sign=wxDic[@"sign"];
    
    
    if (self.wxPayBlok) {
        self.wxPayBlok(dataDic[@"oid"]);
    }

    @try {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{//在主线程中调用
            [WXApi sendReq:request];
        }];
    } @catch (NSException *exception) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{//在主线程中调用
            [SVProgressHUD setMinimumDismissTimeInterval:4];
            [SVProgressHUD showErrorWithStatus:@"订单有问题，请重新提交"];
            
        }];
      
    } @finally {
    };

    
}

- (void)scan{
    
    if (self.scanBlok) {
        self.scanBlok();
    }
}

- (void)startLocation{
    
    if (self.startLocationBlok) {
        self.startLocationBlok();
    }
    
}

- (void)dhmap:(NSString *)lacation{
    @try {
        NSArray *arr = [lacation componentsSeparatedByString:@","];
       CLLocationCoordinate2D position =  CLLocationCoordinate2DMake([arr[0] doubleValue], [arr[1] doubleValue]);
        
        if (self.dhmap) {
            self.dhmap(position);
        }
        
        
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
   
    
    
}

@end
