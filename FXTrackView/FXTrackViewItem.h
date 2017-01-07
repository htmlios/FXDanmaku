//
//  FXTrackViewItem.h
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2017/1/2.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FXTrackViewData.h"

@interface FXTrackViewItem : UIView

@property (nonatomic, readonly, copy) NSString *reuseIdentifier;

- (instancetype)initWithReuseIdentifier:(NSString *)identifier;
- (void)prepareForReuse;

- (void)itemWillBeDisplayedWithData:(FXTrackViewData *)data;

@end
