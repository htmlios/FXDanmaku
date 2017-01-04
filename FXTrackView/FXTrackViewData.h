//
//  FXTrackViewData.h
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2017/1/2.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FXDataPriority) {
    FXDataPriorityNormal = 2001,
    FXDataPriorityHigh
};

@interface FXTrackViewData : NSObject

@property (nonatomic, copy) NSString *itemReuseIdentifier;
@property (nonatomic, assign) FXDataPriority priority;

@end
