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
 *  Defualt: false. If you set this true, data(AttrText, CustomView) will be presented at unoccupied track randomly. Otherwise, data will be presented orderly(Starting from the first track, iterate every track until getting an unocciped tack). IMO, I would recommend to keep this property false, since that will save the time calculating a ramdom track from all unoccupied tracks. But it's up to you, we can't achieve random track effect and save that time at the same time😂
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
 *  Default: true. Remove trackView from its superview when calling 'stop' method
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


- (void)addData:(FXData)data;

- (void)addDataArr:(NSArray *)dataArr;

- (void)start;

- (void)pause;

- (void)stop;

- (void)cleanScreen;

- (void)frameDidChange;

@end
