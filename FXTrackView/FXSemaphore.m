//
//  FXSemaphore.m
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 16/3/16.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import "FXSemaphore.h"
#import "FXDeallocMonitor.h"

#define IsMainThread [NSThread isMainThread]

@interface FXSemaphore ()

@property (assign, nonatomic) NSUInteger counter;

@end

@implementation FXSemaphore

+ (instancetype)instance {
    
    return [self instanceWithCount:0];
}

+ (instancetype)instanceWithCount:(NSUInteger)count {
    
    FXSemaphore *instance = [[FXSemaphore alloc] init];
    instance.counter = count;
    [FXDeallocMonitor addMonitorToObj:instance];
    return instance;
}

//- (void)signal {
//    
//    if (IsMainThread) {
//        CFRunLoopStop(CFRunLoopGetCurrent());
//    }
//}
//
//- (BOOL)wait {
//    
//    CFRunLoopRun();
//}
//
//- (void)breakWait;

@end
