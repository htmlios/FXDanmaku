//
//  FXTrackViewItem.h
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2017/1/2.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FXReusableObjectQueue.h"
#import "FXTrackViewData.h"

@interface FXTrackViewItem : UIView <FXReusableObject>

@property (nonatomic, copy) NSString *reuseIdentifier;

- (void)setupItemWithData:(FXTrackViewData *)data;

@end
