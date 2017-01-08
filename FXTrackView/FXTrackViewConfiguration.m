//
//  FXTrackViewConfig.m
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2017/1/4.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "FXTrackViewConfiguration.h"

@implementation FXTrackViewConfiguration

+ (instancetype)defaultConfiguration {
    FXTrackViewConfiguration *config = [FXTrackViewConfiguration new];
    
    config.dataQueueCapacity = 666;
    config.itemInsertOrder = FXTrackItemInsertOrderFromTop;
    
    config.estimatedRowHeight = 40;
    config.rowVerticalSpace = 4;
    config.occupiedRowResetOffsetRatio = 0.25;
    
    config.itemMinVelocity = 100;
    config.itemMaxVelocity = 120;
    
    return config;
}

@end
