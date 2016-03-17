//
//  FXSemaphore.h
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 16/3/16.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FXSemaphore : NSObject

+ (instancetype)instance;

+ (instancetype)instanceWithCount:(NSUInteger)count;

- (BOOL)signal;

- (BOOL)wait;

- (void)breakWait;

@end
