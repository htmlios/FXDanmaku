//
//  FXGCDTimer.m
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/1/9.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "FXGCDTimer.h"

@interface FXGCDTimer ()

@property (nonatomic, copy) FXTimerBlock block;
@property (nonatomic, strong) dispatch_queue_t blockQueue;
@property (nonatomic, weak) dispatch_source_t sourceTimer;

@end

@implementation FXGCDTimer

#pragma mark - Accessor
- (BOOL)isCancelled {
    return self.block != nil;
}

#pragma mark - LifeCycle
+ (instancetype)scheduledTimerWithInterval:(NSTimeInterval)interval
                                     queue:(dispatch_queue_t)queue
                                     block:(FXTimerBlock)block {
    
    FXGCDTimer *timer = nil;
    if (block) {
        timer = [[FXGCDTimer alloc] init];
        timer.block = block;
        timer.blockQueue = queue ?: dispatch_get_main_queue();
        dispatch_source_t sourceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                               0,
                                                               0,
                                                               timer.blockQueue);
        dispatch_source_set_timer(sourceTimer,
                                  dispatch_walltime(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC),
                                  DISPATCH_TIME_FOREVER,
                                  0);
        dispatch_source_set_event_handler(sourceTimer, ^{
            if (dispatch_source_testcancel(sourceTimer)) {
                dispatch_source_cancel(sourceTimer);
            }
            if (timer.block) {
                timer.block();
                timer.block = nil;
            }
        });
        timer.sourceTimer = sourceTimer;
        dispatch_resume(sourceTimer);
    }
    return timer;
}

#pragma mark - Action
- (void)cancel {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.blockQueue, ^{
        typeof(self) self = weakSelf;
        if (self) {
            if (self.sourceTimer && dispatch_source_testcancel(self.sourceTimer)) {
                dispatch_source_cancel(self.sourceTimer);
            }
            self.block = nil;
        }
    });
}

@end
