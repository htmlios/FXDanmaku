//
//  JCBarrageView.h
//
//
//  Created by ShawnFoo on 12/4/15.
//  Copyright © 2015 ShawnFoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FXTrackView : UIView

@property (assign, readonly, nonatomic) CGFloat trackHeight;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)addUserWords:(NSString *)subtitleStr;

- (void)addAnchorWords:(NSString *)words;

- (void)start;

- (void)pause;

- (void)resume;

- (void)stop;

@end
