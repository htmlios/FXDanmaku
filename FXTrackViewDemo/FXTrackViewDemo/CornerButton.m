//
//  CornerButton.m
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 4/4/16.
//  Copyright © 2016 ShawnFoo. All rights reserved.
//

#import "CornerButton.h"

@implementation CornerButton

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.layer.cornerRadius = self.frame.size.height / 2.0;
    self.layer.borderColor = [UIColor colorWithRed:0 green:0.478431 blue:1.0 alpha:1.0].CGColor;
    self.layer.borderWidth = 1.0;
}

@end
