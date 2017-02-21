//
//  NSTimer+FXWeakTimer.m
//  FXWeakTimer
//
//  Created by ShawnFoo on 16/6/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import "NSTimer+FXWeakTimer.h"
#import <objc/runtime.h>

#define RunBlockSafe(block, ...) {\
if (block) {\
block(__VA_ARGS__);\
}\
}

#pragma mark - FXReleaseMonitor

@interface FXReleaseMonitor : NSObject

@property (copy, nonatomic) void (^deallocBlock)(void);

@end

@implementation FXReleaseMonitor

+ (void)addMonitorToObj:(id)obj key:(id)key withDeallocBlock:(void (^)(void))deallocBlock {
    NSParameterAssert(obj);
    NSParameterAssert(deallocBlock);
    FXReleaseMonitor *monitor = [[FXReleaseMonitor alloc] init];
    monitor.deallocBlock = deallocBlock;
    
    objc_setAssociatedObject(obj,
                             (__bridge const void *)(key),
                             monitor,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)dealloc {
    RunBlockSafe(_deallocBlock);
}

@end

#pragma mark - FXWeakTarget

@interface FXWeakTarget : NSObject

@property (weak, nonatomic) id target;
@property (weak, nonatomic) NSTimer *timer;
@property (copy, nonatomic) FXTimerBlock block;
@property (strong, nonatomic) dispatch_queue_t queue;

@end

@implementation FXWeakTarget

- (void)timerBlockInvoker:(NSTimer *)timer {
    
    if (timer.valid) {
        id strongTarget = self.target;
        if (strongTarget) {
            if (self.queue) {
                dispatch_async(self.queue, ^{
                    RunBlockSafe(self.block);
                });
            }
            else {
                RunBlockSafe(self.block);
            }
        }
        else {
            [self.timer invalidate];
        }
    }
}

- (void)invalidateTimer {
    [self.timer invalidate];
}

@end

#pragma mark - NSTimer + FXWeakTimer

@implementation NSTimer (FXWeakTimer)

+ (NSTimer *)fx_scheduledTimerWithInterval:(NSTimeInterval)interval
                                    target:(id)target
                                   repeats:(BOOL)repeats
                                     block:(FXTimerBlock)block
{
    return [self fx_scheduledTimerWithInterval:interval
                                        target:target
                                       repeats:repeats
                                         queue:nil
                                         block:block];
}

+ (NSTimer *)fx_scheduledTimerWithInterval:(NSTimeInterval)interval
                                    target:(id)target
                                   repeats:(BOOL)repeats
                                     queue:(dispatch_queue_t)queue
                                     block:(FXTimerBlock)block
{
    NSParameterAssert(target);
    NSParameterAssert(block);
    
    FXWeakTarget *weakTarget = [[FXWeakTarget alloc] init];
    weakTarget.target = target;
    weakTarget.block = block;
    weakTarget.queue = queue;
    
    [FXReleaseMonitor addMonitorToObj:target key:weakTarget withDeallocBlock:^{
        [weakTarget invalidateTimer];
    }];
    
    weakTarget.timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                        target:weakTarget
                                                      selector:@selector(timerBlockInvoker:)
                                                      userInfo:nil
                                                       repeats:repeats];
    return weakTarget.timer;
}

+ (NSTimer *)fx_timerWithInterval:(NSTimeInterval)interval
                           target:(id)target
                          repeats:(BOOL)repeats
                            block:(FXTimerBlock)block
{
    return [self fx_timerWithInterval:interval
                               target:target
                              repeats:repeats
                                queue:nil
                                block:block];
}

+ (NSTimer *)fx_timerWithInterval:(NSTimeInterval)interval
                           target:(id)target
                          repeats:(BOOL)repeats
                            queue:(dispatch_queue_t)queue
                            block:(FXTimerBlock)block
{
    NSParameterAssert(target);
    NSParameterAssert(block);
    
    FXWeakTarget *weakTarget = [[FXWeakTarget alloc] init];
    weakTarget.target = target;
    weakTarget.block = block;
    weakTarget.queue = queue;
    
    [FXReleaseMonitor addMonitorToObj:target key:weakTarget withDeallocBlock:^{
        [weakTarget invalidateTimer];
    }];
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:interval
                                             target:weakTarget
                                           selector:@selector(timerBlockInvoker:)
                                           userInfo:nil
                                            repeats:repeats];
    weakTarget.timer = timer;
    return timer;
}

@end
