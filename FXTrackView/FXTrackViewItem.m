//
//  FXTrackViewItem.m
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2017/1/2.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "FXTrackViewItem.h"
#import "FXTrackViewHeader.h"

@interface FXTrackViewItem () 

@property (nonatomic, copy) NSString *reuseIdentifier;

@end

@implementation FXTrackViewItem

- (NSString *)reuseIdentifier {
    return _reuseIdentifier ?: NSStringFromClass([self class]);
}

- (instancetype)initWithReuseIdentifier:(NSString *)identifier {
    if (self = [super initWithFrame:CGRectZero]) {
        _reuseIdentifier = [identifier copy];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonSetup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonSetup];
    }
    return self;
}

- (void)commonSetup {
    self.userInteractionEnabled = NO;
}

- (void)prepareForReuse {
    [self.layer removeAllAnimations];
}

- (void)itemWillBeDisplayedWithData:(FXTrackViewData *)data {
    FXException(@"Please override this method implement in your subclass so you can custom your item with pass-in data.");
}

@end
