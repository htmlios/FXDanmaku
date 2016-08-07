//
//  FXTrackView.h
//
//
//  Created by ShawnFoo on 12/4/15.
//  Copyright © 2015 ShawnFoo. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NSDictionary* FXData;
typedef NSDictionary* FXTextAttrs;

typedef NS_ENUM(NSUInteger, FXDataPriority) {
    PriorityNormal = 2001,
    PriorityHigh
};

extern NSString const *FXDataTextKey;
extern NSString const *FXTextCustomAttrsKey;
extern NSString const *FXDataCustomViewKey;
extern NSString const *FXDataPriorityKey;

@interface FXTrackView : UIView

@property (assign, readonly, nonatomic) BOOL isRunning;

/**
 *  the height of one track
 */
@property (assign, readonly, nonatomic) CGFloat trackHeight;

/**
 *  reused text attributes for normal priority
 */
@property (strong, nonatomic) FXTextAttrs normalPriorityTextAttrs;
/**
 *  reused text attributes for high priority
 */
@property (strong, nonatomic) FXTextAttrs highPriorityTextAttrs;

/**
 *  Defualt: false. If you set this true, data(AttrText, CustomView) will be presented at unoccupied track randomly. Otherwise, data will be presented orderly(Starting from the first track, iterate every track until getting an unocciped tack). IMO, I would recommend to keep this property false, since that will save the time calculating a ramdom track from all unoccupied tracks. But it's up to you, we can't achieve random track effect and save that consumption at the same time😂
 */
@property (assign, nonatomic) BOOL randomTrack;
/**
 *  Default: false. If you set this true, trackView will remove all presenting data(remove all its subviews) when pasued
 */
@property (assign, nonatomic) BOOL cleanScreenWhenPaused;
/**
 *  Default: false. If you set this true, all datas stored in dataArr will be removed. Also, [trackView addData/addDataArr] method won't work during paused
 */
@property (assign, nonatomic) BOOL emptyDataWhenPaused;
/**
 *  Default: true. If you set this false, [trackView addData/addDataArr] method won't work during paused
 */
@property (assign, nonatomic) BOOL acceptDataWhenPaused;
/**
 *  Default: no. Remove trackView from its superview when calling 'stop' method
 */
@property (assign, nonatomic) BOOL removeFromSuperViewWhenStoped;

/**
 *  max velocity of data carrier(UILabel for AttrText, CustomView)
 */
@property (assign, nonatomic) NSUInteger maxVelocity;
/**
 *  min veliocity of data carrier(UILabel for AttrText, CustomView)
 */
@property (assign, nonatomic) NSUInteger minVelocity;

/**
 *  Add one data. FXData is typealias for NSDictionary
 *
 *  @param data There are two kinds of data. One is Text(FXDataTextKey), the other is CustomView(FXDataCustomViewKey). For Text type, you can specify custom attributes of text by setting FXTextCustomAttrsKey's value. What's more, you can set two reused TextAttributes, normalPriorityTextAttrs and highPriorityTextAttrs. FXDataPriorityKey will give you alternative to decide which data should be presented as soon as there has unoccupied tracks. It has two value: PriorityNormal(default) and PriorityHigh.
 */
- (void)addData:(FXData)data;

/**
 *  Add a group of data. Only member that is kind of FXData will be added in to data queue
 */
- (void)addDataArr:(NSArray *)dataArr;

/**
 *  Start or resume presenting data
 */
- (void)start;

/**
 *  Pause presenting data. You can resume it by calling 'start' method
 */
- (void)pause;

/**
 *  Stop presenting data.
 */
- (void)stop;

/**
 *  Clean screen(Remove all data presenting on the TrackView). You can set cleanScreenWhenPaused true to save you from calling this method manually
 */
- (void)cleanScreen;

/**
 *  When trackview's frame changed, you should call this method to recalculate the num of tracks and height of each track. Otherwise, data might be presented in the position out of trackview!
 */
- (void)frameDidChange;

/**
 *  Check should handle touch by yourself
 *
 *  @param touch UITouch object
 *
 *  @return return YES if touch in any
 */
- (BOOL)shouldHandleTouch:(UITouch *)touch;

@end
