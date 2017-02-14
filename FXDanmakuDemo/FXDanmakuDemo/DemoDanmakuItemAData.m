//
//  DemoDanmakuItemData.m
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/2/13.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "DemoDanmakuItemAData.h"
#import "DemoDanmakuItemA.h"

@implementation DemoDanmakuItemAData

+ (instancetype)data {
    return [super dataWithItemReuseIdentifier:[DemoDanmakuItemA reuseIdentifier]];
}

+ (instancetype)highPriorityData {
    return [super highPriorityDataWithItemReuseIdentifier:[DemoDanmakuItemA reuseIdentifier]];
}

@end
