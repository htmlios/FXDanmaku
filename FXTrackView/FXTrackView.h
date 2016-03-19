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
    PriorityHigh = 2001,
    PriorityNormal,
};

extern NSString const *FXDataTextKey;
extern NSString const *FXTextCustomAttrsKey;
extern NSString const *FXDataCustomViewKey;
extern NSString const *FXDataPriorityKey;

@interface FXTrackView : UIView

@property (assign, readonly, nonatomic) CGFloat trackHeight;

@property (strong, nonatomic) FXTextAttrs normalPriorityTextAttrs;
@property (strong, nonatomic) FXTextAttrs highPriorityTextAttrs;

@property (assign, nonatomic) BOOL clearTrackViewWhenPaused;
@property (assign, nonatomic) BOOL emptyDataWhenPaused;
@property (assign, nonatomic) BOOL acceptDataWhenPaused;
@property (assign, nonatomic) BOOL hideViewWhenPaused;
@property (assign, nonatomic) BOOL removeFromSuperViewWhenStoped;

@property (assign, nonatomic) NSInteger maxVelocity;
@property (assign, nonatomic) NSInteger minVelocity;

- (void)addData:(FXData)data;

- (void)addDataArr:(NSArray *)dataArr;

- (void)start;

- (void)pause;

- (void)resume;

- (void)stop;

@end
