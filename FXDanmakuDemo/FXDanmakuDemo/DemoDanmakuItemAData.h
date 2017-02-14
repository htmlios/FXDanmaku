//
//  DemoDanmakuItemData.h
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/2/13.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "FXDanmakuItemData.h"

@interface DemoDanmakuItemAData : FXDanmakuItemData

@property (nonatomic, copy) NSString *avatarName;
@property (nonatomic, copy) NSString *desc;

+ (instancetype)data;
+ (instancetype)highPriorityData;

@end
