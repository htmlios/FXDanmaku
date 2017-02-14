//
//  FXDanmakuItemData.h
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/1/2.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FXDataPriority) {
    FXDataPriorityNormal,
    FXDataPriorityHigh
};

NS_ASSUME_NONNULL_BEGIN
/**
 FXDanmakuItemData is for supplying DanmakuItem with data to display. One kind of FXDanmakuItemData can only be used by a specified FXDanmakuItem via setting itemReuseIdentifier property;
 */
@interface FXDanmakuItemData : NSObject

/**
 The reuse identifier of DanmakuItem that will display this data.
 */
@property (nonatomic, readonly, copy) NSString *itemReuseIdentifier;

/**
 High Priority data will be displayed first since it will be inserted to queue before normal priority data;
 */
@property (nonatomic, assign) FXDataPriority priority;


// Note: Identifier can't be nil or empty string!

+ (nullable instancetype)dataWithItemReuseIdentifier:(NSString *)identifier;
+ (nullable instancetype)highPriorityDataWithItemReuseIdentifier:(NSString *)identifier;

- (nullable instancetype)initWithItemReuseIdentifier:(NSString *)identifier priority:(FXDataPriority)priority NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
