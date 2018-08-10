//
//  CustomAccount.h
//  GoogleMapProject
//
//  Created by Nasheng Yu on 2018/6/27.
//  Copyright © 2018年 俞乃胜. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomAccount : NSObject


@property (nonatomic,assign)double lat;
@property (nonatomic,assign)double lng;


+ (CustomAccount *)sharedCustomAccount;
@end
