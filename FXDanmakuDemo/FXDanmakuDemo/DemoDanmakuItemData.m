//
//  DemoDanmakuItemData.m
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/2/13.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "DemoDanmakuItemData.h"
#import "DemoDanmakuItem.h"

@implementation DemoDanmakuItemData

+ (instancetype)data {
    return [super dataWithItemReuseIdentifier:[DemoDanmakuItem reuseIdentifier]];
}

+ (instancetype)highPriorityData {
    return [super highPriorityDataWithItemReuseIdentifier:[DemoDanmakuItem reuseIdentifier]];
}

@end
