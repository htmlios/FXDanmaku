//
//  FXTrackViewItem.m
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2017/1/2.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "FXTrackViewItem.h"

@implementation FXTrackViewItem

- (NSString *)reuseIdentifier {
    return _reuseIdentifier ?: NSStringFromClass([self class]);
}

- (void)setupItemWithData:(FXTrackViewData *)data {
#if DEBUG
    
#endif
}

@end
