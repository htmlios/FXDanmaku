//
//  FXTrackViewData.h
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2017/1/2.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FXDataPriority) {
    PriorityNormal = 2001,
    PriorityHigh
};

@interface FXTrackViewData : NSObject

@property (nonatomic, class, readonly) NSString *itemIdentifier;
@property (nonatomic, assign) FXDataPriority priority;

@end
