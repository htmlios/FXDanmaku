//
//  FXClickableViewManager.m
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 5/2/16.
//  Copyright © 2016 ShawnFoo. All rights reserved.
//

#import "FXClickableViewManager.h"
#import "FXTrackViewHeader.h"

@interface FXClickableViewManager ()

@property (strong, nonatomic) NSPointerArray *clickableViews;

@end

@implementation FXClickableViewManager

#pragma mark - Lazyloading

- (NSPointerArray *)clickableViews {
    if (!_clickableViews) {
        _clickableViews = [NSPointerArray weakObjectsPointerArray];
    }
    return _clickableViews;
}

#pragma mark - Public Method

- (void)addClickableView:(UIControl *)view {
    
    @WeakObj(self);
    @WeakObj(view);
    dispatch_barrier_async(dispatch_get_global_queue(0, 0), ^{
        @StrongObj(self);
        @StrongObj(view);
        
        // iterate to remove all null pointers
        for (int i = 0; i < self.clickableViews.count; i++) {
            if (![self.clickableViews pointerAtIndex:i]) {
                [self.clickableViews removePointerAtIndex:i];
                i--;
            }
        }
        if (view) {
            [self.clickableViews addPointer:(__bridge void*)view];
        }
    });
}

- (UIControl *)clickableViewAtPoint:(CGPoint)point {
    
    if (_clickableViews.count > 0) {
        for (UIControl *view in _clickableViews.allObjects) {
            if (view) {
                if ([view.layer.presentationLayer hitTest:point]) {
                    return view;
                }
            }
        }
    }
    return nil;
}

@end
