//
//  FXTrackViewConfig.h
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2017/1/4.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>

typedef NS_ENUM(NSUInteger, FXTrackItemInsertOrder) {
    FXTrackItemInsertOrderFromTop,
    FXTrackItemInsertOrderFromBottom,
    FXTrackItemInsertOrderRandom
};

@interface FXTrackViewConfiguration : NSObject

@property (nonatomic, assign) NSUInteger dataQueueCapacity;
@property (nonatomic, assign) FXTrackItemInsertOrder itemInsertOrder;

@property (nonatomic, assign) CGFloat estimatedRowHeight;
@property (nonatomic, assign) CGFloat rowVerticalSpace;
@property (nonatomic, assign) float occupiedRowResetOffsetRatio;

@property (nonatomic, assign) NSUInteger itemMinVelocity;
@property (nonatomic, assign) NSUInteger itemMaxVelocity;


+ (instancetype)defaultConfiguration;

@end
