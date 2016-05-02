//
//  FXClickableViewManager.h
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 5/2/16.
//  Copyright © 2016 ShawnFoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FXClickableViewManager : NSObject

- (void)addClickableView:(UIControl *)view;

- (UIControl *)clickableViewAtPoint:(CGPoint)point;

@end
