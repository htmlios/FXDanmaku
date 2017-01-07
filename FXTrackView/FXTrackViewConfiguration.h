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

@property (nonatomic, assign) FXTrackItemInsertOrder itemInsertOrder;
@property (nonatomic, assign) CGFloat itemVerticalSpace;

@property (nonatomic, assign) float trackResetOffsetRatio;

@property (nonatomic, assign) NSUInteger dataQueueCapacity;


@end
