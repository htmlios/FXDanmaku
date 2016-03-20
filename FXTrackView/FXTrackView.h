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

@property (assign, readonly, nonatomic) CGFloat trackHeight;

@property (strong, nonatomic) FXTextAttrs normalPriorityTextAttrs;
@property (strong, nonatomic) FXTextAttrs highPriorityTextAttrs;

@property (assign, nonatomic) BOOL clearTrackViewWhenPaused;
@property (assign, nonatomic) BOOL emptyDataWhenPaused;
@property (assign, nonatomic) BOOL acceptDataWhenPaused;
@property (assign, nonatomic) BOOL hideViewWhenPaused;
@property (assign, nonatomic) BOOL removeFromSuperViewWhenStoped;

@property (assign, nonatomic) NSUInteger maxVelocity;
@property (assign, nonatomic) NSUInteger minVelocity;

- (void)addData:(FXData)data;

- (void)addDataArr:(NSArray *)dataArr;

- (void)start;

- (void)pause;

- (void)resume;

- (void)stop;

@end
