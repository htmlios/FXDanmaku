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
@property (nonatomic, strong) dispatch_semaphore_t syncLock;

@end

@implementation FXGCDTimer

#pragma mark - Accessor
- (BOOL)isCancelled {
    return self.block != nil;
}

#pragma mark - LifeCycle
- (instancetype)init {
    if (self = [super init]) {
        _syncLock = dispatch_semaphore_create(1);
    }
    return self;
}

+ (instancetype)scheduledTimerWithInterval:(NSTimeInterval)interval
                                     queue:(dispatch_queue_t)queue
                                     block:(FXTimerBlock)block {
    
    FXGCDTimer *timer = nil;
    if (block) {
        timer = [[FXGCDTimer alloc] init];
        timer.block = block;
        dispatch_source_t timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                               0,
                                                               0,
                                                               queue);
        dispatch_source_set_timer(timerSource,
                                  dispatch_walltime(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC),
                                  DISPATCH_TIME_FOREVER,
                                  0);
        dispatch_source_set_event_handler(timerSource, ^{
            dispatch_semaphore_wait(timer.syncLock, DISPATCH_TIME_FOREVER);
            if (dispatch_source_testcancel(timerSource)) {
                dispatch_source_cancel(timerSource);
            }
            if (timer.block) {
                timer.block();
                timer.block = nil;
            }
            dispatch_semaphore_signal(timer.syncLock);
        });
        dispatch_resume(timerSource);
    }
    return timer;
}

#pragma mark - Action

- (void)cancel {
    dispatch_semaphore_wait(self.syncLock, DISPATCH_TIME_FOREVER);
    self.block = nil;
    dispatch_semaphore_signal(self.syncLock);
}

@end
