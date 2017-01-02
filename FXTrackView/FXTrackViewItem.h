//
//  FXTrackViewItem.h
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2017/1/2.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FXReusableObjectQueue.h"

@interface FXTrackViewItem : UIView <FXReusableObject>

@property (nonatomic, class, readonly) NSString *resableIdentifier;

@end
