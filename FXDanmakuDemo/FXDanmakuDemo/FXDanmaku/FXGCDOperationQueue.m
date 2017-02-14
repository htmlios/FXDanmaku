//
//  FXGCDOperationQueue.m
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/1/15.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "FXGCDOperationQueue.h"

@interface FXBlockOperation : NSObject

@property (nonatomic, copy) dispatch_block_t block;

- (void)cancel;

@end

@implementation FXBlockOperation

+ (instancetype)operationWithBlock:(dispatch_block_t)block {
    FXBlockOperation *operation = [[FXBlockOperation alloc] init];
    operation.block = block;
    return operation;
}

- (void)cancel {
    self.block = nil;
}

@end


@interface FXGCDOperationQueue ()

@property (nonatomic, strong) NSHashTable<FXBlockOperation *> *operations;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation FXGCDOperationQueue

+ (instancetype)queueWithDispatchQueueType:(dispatch_queue_t)dispatchQueueT {
    FXGCDOperationQueue *opQueue = nil;
    if (dispatchQueueT) {
        opQueue = [[FXGCDOperationQueue alloc] init];
        opQueue.queue = dispatchQueueT;
        opQueue.operations = [NSHashTable weakObjectsHashTable];
    }
    return opQueue;
}

- (void)addSyncOperationBlock:(dispatch_block_t)block {
    [self addOperationBlock:block asynchronous:NO];
}

- (void)addAsyncOperationBlock:(dispatch_block_t)block {
    [self addOperationBlock:block asynchronous:YES];
}

- (void)addOperationBlock:(dispatch_block_t)block asynchronous:(BOOL)asynchronous {
    if (block) {
        FXBlockOperation *op = [FXBlockOperation operationWithBlock:block];
        dispatch_block_t opBlock = ^{
            dispatch_block_t cBlock = [op.block copy];
            if (cBlock) {
                cBlock();
            }
        };
        if (asynchronous) {
            dispatch_async(self.queue, opBlock);
        }
        else {
            dispatch_sync(self.queue, opBlock);
        }
        [self.operations addObject:op];
    }
}

- (void)cancelAllOperation {
    for (FXBlockOperation *op in self.operations) {
        [op cancel];
    }
}

@end
