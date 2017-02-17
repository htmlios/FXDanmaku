//
//  FXDanmakuItem.h
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/1/2.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FXDanmakuItemData.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The relationship between DanmakuItem and danmaku is just same as the one between UITableViewCell and UITableView.
 */
@interface FXDanmakuItem : UIView

/**
 A string used to identify a cell that is reusable.
 */
@property (nonatomic, readonly, copy) NSString *reuseIdentifier;


/**
  Initializes a danmaku item with reuse identifier.

 @param identifier reuse identifier for item. If pass nil, reuseIdentifier will be name of the class.
 @return An initialized FXDanmakuItem object
 */
- (instancetype)initWithReuseIdentifier:(nullable NSString *)identifier NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;


/**
 Prepare for reuse after item did 'leave' danmaku view. Must call super.
 */
- (void)prepareForReuse;

/**
 You can setup item with data in this method before item will start moving on danmaku.
 
 Note: This method is only called by the danmaku when there are unoccupied rows for item to move.

 @param data The data should be displayed, it also was the first object in data queue.
 */
- (void)itemWillBeDisplayedWithData:(FXDanmakuItemData *)data;

@end

NS_ASSUME_NONNULL_END
