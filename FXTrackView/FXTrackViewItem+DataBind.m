//
//  FXTrackViewItem+DataBind.m
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2017/1/8.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "FXTrackViewItem+DataBind.h"
#import <objc/runtime.h>

@implementation FXTrackViewItem (DataBind)

- (void)setFx_data:(FXTrackViewData *)fx_data {
    objc_setAssociatedObject(self,
                             @selector(fx_data),
                             fx_data,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FXTrackViewData *)fx_data {
    return objc_getAssociatedObject(self, _cmd);
}

@end
