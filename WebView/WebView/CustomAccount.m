//
//  CustomAccount.m
//  GoogleMapProject
//
//  Created by Nasheng Yu on 2018/6/27.
//  Copyright © 2018年 俞乃胜. All rights reserved.
//

#import "CustomAccount.h"

@implementation CustomAccount

+ (CustomAccount *)sharedCustomAccount{
    
    static CustomAccount *sharedCustomAccountInstance = nil;
    static dispatch_once_t tar;
    dispatch_once(&tar, ^{
        sharedCustomAccountInstance = [[CustomAccount alloc]init];
    });
    return sharedCustomAccountInstance;    
}
@end
