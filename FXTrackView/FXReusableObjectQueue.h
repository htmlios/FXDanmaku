//
//  FXReusableObjectQueue.h
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2016/12/28.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FXReusableObject <NSObject>

@optional
+ (NSString *)resableIdentifier;
- (void)objectWillEnqueue;
- (void)objectWillBeReused;

@end

@interface FXReusableObjectQueue : NSObject

#pragma mark - Resubale Object Register
- (void)registerClass:(Class)cls forObjectReuseIdentifier:(NSString *)identifier;
- (void)registerNib:(UINib *)nib forObjectReuseIdentifier:(NSString *)identifier;
- (void)unregisterObjectResueWithIdentifier:(NSString *)identifier;

#pragma mark - Queue Operation
- (void)enqueueReusableObject:(id<FXReusableObject>)object;
- (id<FXReusableObject>)dequeueReusableObjectWithIdentifier:(NSString *)identifier;
- (void)emptyUnusedObjects;

@end
