//
//  FXDanmakuItem.m
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/1/2.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "FXDanmakuItem.h"
#import "FXDanmakuItem_Private.h"
#import "FXDanmakuMacro.h"
#import "FXReusableObjectQueue.h"

NS_ASSUME_NONNULL_BEGIN

@interface FXDanmakuItem () <FXReusableObject>

@property (nonatomic, copy) NSString *reuseIdentifier;

@end

@implementation FXDanmakuItem

#pragma mark - Accessor
- (NSString *)reuseIdentifier {
    return _reuseIdentifier.length ? _reuseIdentifier : NSStringFromClass([self class]);
}

#pragma mark - Initializer
#pragma mark Desiganated Initializer
- (instancetype)initWithReuseIdentifier:(nullable NSString *)identifier {
    if (self = [super initWithFrame:CGRectZero]) {
        _reuseIdentifier = [identifier copy];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonSetup];
    }
    return self;
}

#pragma mark Convenience Initializer
- (instancetype)init {
    return [self initWithReuseIdentifier:nil];
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithReuseIdentifier:nil];
}

#pragma mark - Common Setup
- (void)commonSetup {
    self.userInteractionEnabled = NO;
}

#pragma mark - Reuse
- (void)prepareForReuse {
    // do nothing
}

#pragma mark - Item Display
- (void)itemWillBeDisplayedWithData:(FXDanmakuItemData *)data {
    FXException(@"Please override this method implement(%s) in your subclass so you can custom your item with pass-in data.",
                sel_getName(_cmd));
}

@end

NS_ASSUME_NONNULL_END
