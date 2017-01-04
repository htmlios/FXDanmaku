//
//  FXTrackViewData.m
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2017/1/2.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "FXTrackViewData.h"
#import "FXTrackViewItem.h"

@implementation FXTrackViewData

- (NSString *)itemReuseIdentifier {
    return _itemReuseIdentifier ?: NSStringFromClass([FXTrackViewItem class]);
}

- (FXDataPriority)priority {
    return _priority == 0 ? FXDataPriorityNormal : _priority;
}

@end
