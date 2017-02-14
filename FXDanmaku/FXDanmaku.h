//
//  FXDanmaku.h
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 12/4/15.
//  Copyright © 2015 ShawnFoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FXDanmakuItemData.h"
#import "FXDanmakuItem.h"
#import "FXDanmakuConfiguration.h"
@class FXDanmaku;

NS_ASSUME_NONNULL_BEGIN

@protocol FXDanmakuDelegate <NSObject>

@optional

/**
 Tells the delegate the which item has been clicked

 @param danmaku The FXDanmaku object informing the delegate of this impending event.
 @param item The item that has been clicked.
 @param data The data of item.
 */
- (void)danmaku:(FXDanmaku *)danmaku didClickItem:(FXDanmakuItem *)item withData:(FXDanmakuItemData *)data;

/**
 Tells the delegate the danmaku is about to display item.
 
 @param danmaku The FXDanmaku object informing the delegate of this impending event.
 @param item The item that is going to be displayed.
 @param data The data of item.
 */
- (void)danmaku:(FXDanmaku *)danmaku willDisplayItem:(FXDanmakuItem *)item withData:(FXDanmakuItemData *)data;

/**
 Tells the delegate the danmaku is about to display item.

 @param danmaku The FXDanmaku object informing the delegate of this impending event.
 @param item The item that has ended displaying.
 @param data The data of item.
 */
- (void)danmaku:(FXDanmaku *)danmaku didEndDisplayingItem:(FXDanmakuItem *)item withData:(FXDanmakuItemData *)data;

@end


@interface FXDanmaku : UIView

@property (nonatomic, weak, nullable) id<FXDanmakuDelegate> delegate;

@property (nonatomic, readonly) BOOL isRunning;

/**
 You can only set the configuration of FXDanmaku when it's not running.
 */
@property (nonatomic, copy, nullable) FXDanmakuConfiguration *configuration;

/**
 Actual vertical space between two row. 
 
 viewHeight = numOfRows*rowHeight + (numOfRows-1)*rowSpace
 */
@property (nonatomic, readonly) CGFloat rowSpace;

/**
 Default: false. Should danmaku remove all displaying danmakuItems when pasued.
 */
@property (nonatomic, assign) BOOL cleanScreenWhenPaused;

/**
 Default: false. Should empty data queue when danmaku is paused.
 
 Note: If set this true, adding data won't enqueue when danmaku is paused!
 */
@property (nonatomic, assign) BOOL emptyDataWhenPaused;

/**
 Default: true. Should enqueue data when danmaku is paused.
 */
@property (nonatomic, assign) BOOL acceptDataWhenPaused;


/**
 Registers a nib object containing a reusable danmakuItem with a specified identifier.

 @param nib nib object that specifies the nib file used to create the object.
 @param identifier The reuse identifier for the danmakuItem. This parameter must not be nil and must not be an empty string.
 */
- (void)registerNib:(nullable UINib *)nib forItemReuseIdentifier:(NSString *)identifier;

/**
 Registers a class for use in creating new danmakuItems.

 @param itemClass The class of an item that you want to use on danmaku.
 @param identifier The reuse identifier for the item. This parameter must not be nil and must not be an empty string.
 */
- (void)registerClass:(nullable Class)itemClass forItemReuseIdentifier:(NSString *)identifier;


/**
 Add FXDanmakuItemData object
 */
- (void)addData:(FXDanmakuItemData *)data;

/**
 Add an array with FXDanmakuItemData objects.
 */
- (void)addDatas:(NSArray<FXDanmakuItemData *> *)datas;

/**
 Empty data queue.
 */
- (void)emptyData;


/**
 Start or resume displaying data
 */
- (void)start;

/**
 Pause displaying data. You can resume danmaku by calling 'start' method
 */
- (void)pause;

/**
 Stop displaying data.
 */
- (void)stop;


/** 
 Remove all displaying items on danmaku.
 */
- (void)cleanScreen;

@end

NS_ASSUME_NONNULL_END
