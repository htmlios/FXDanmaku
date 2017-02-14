//
//  DemoDanmakuItem.m
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/2/13.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "DemoDanmakuItemA.h"
#import "DemoDanmakuItemAData.h"
#import "UIImageView+CornerRadius.h"

@interface DemoDanmakuItemA ()

@property (nonatomic, readonly) CGFloat cAvatarLength;

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarWidthConst;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarHeightConst;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;

@end

@implementation DemoDanmakuItemA

+ (NSString *)reuseIdentifier {
    return NSStringFromClass(self);
}

- (CGFloat)cAvatarLength {
    return 30;
}

#pragma mark - Overrides
#pragma mark LifeCycle
- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithReuseIdentifier:[[self class] reuseIdentifier]];
}

// if you custom your item through xib
- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupSubViews];
}

#pragma mark Reuse
- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.avatarImageView.image = nil;
    self.descLabel.text = nil;
}

- (void)itemWillBeDisplayedWithData:(DemoDanmakuItemAData *)data {
    self.avatarImageView.image = [UIImage imageNamed:data.avatarName];
    self.descLabel.text = data.desc;
}

#pragma mark - Setup
- (void)setupSubViews {
    [self.avatarImageView zy_cornerRadiusAdvance:self.cAvatarLength/2.0 rectCornerType:UIRectCornerAllCorners];
    self.descLabel.textColor = [UIColor whiteColor];
    self.descLabel.textAlignment = NSTextAlignmentLeft;
}

@end
