//
//  FXTrackView.h
//
//
//  Created by ShawnFoo on 12/4/15.
//  Copyright © 2015 ShawnFoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FXTrackViewData.h"
#import "FXTrackViewItem.h"
@class FXTrackView;

@protocol FXTrackViewDelegate <NSObject>

- (void)trackView:(FXTrackView *)trackView willDisplayItem:(FXTrackViewItem *)item;
- (void)trackView:(FXTrackView *)trackView didEndDisplayingItem:(FXTrackViewItem *)item;

- (void)trackView:(FXTrackView *)trackView didClickItem:(FXTrackViewItem *)item;

@end

@interface FXTrackView : UIView

@property (nonatomic, weak) id<FXTrackViewDelegate> delegate;

@property (assign, readonly, nonatomic) BOOL isRunning;

/**
 *  the height of one track
 */
@property (assign, readonly, nonatomic) CGFloat trackHeight;


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


- (void)registerNib:(UINib *)nib forItemReuseIdentifier:(NSString *)identifier;

- (void)registerClass:(Class)itemClass forItemReuseIdentifier:(NSString *)identifier;

- (void)addData:(FXTrackViewData *)data;


/**
 Add array with FXTrackViewData objects.
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
 *  @return return YES if touched any items
 */
- (BOOL)shouldHandleTouch:(UITouch *)touch;

@end
