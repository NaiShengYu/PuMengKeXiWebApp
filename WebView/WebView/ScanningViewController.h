//
//  ScanningViewController.h
//  ScanningSystem
//
//  Created by Nasheng Yu on 2018/3/19.
//  Copyright © 2018年 俞乃胜. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScanningViewController : UIViewController

@property (nonatomic,copy)void (^scanResultBlock)(NSString *ulr);
@end
