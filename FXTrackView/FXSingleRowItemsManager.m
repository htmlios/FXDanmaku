//
//  FXSingleRowItemsManager.m
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2017/1/5.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "FXSingleRowItemsManager.h"
#import "FXTrackViewItem.h"

@interface FXSingleRowItemsManager ()

@property (nonatomic, strong) NSMutableArray<FXTrackViewItem *> *items;

@end

@implementation FXSingleRowItemsManager

#pragma mark - LazyLoading
- (NSMutableArray<FXTrackViewItem *> *)items {
    if (!_items) {
        _items = [NSMutableArray arrayWithCapacity:1];
    }
    return _items;
}

#pragma mark - Operations
- (void)addTrackViewItem:(FXTrackViewItem *)item {
    if ([item isKindOfClass:[FXTrackViewItem class]]) {
        [self.items addObject:item];
    }
}

- (void)removeTrackViewItem:(FXTrackViewItem *)item {
    if (item) {
        [self.items removeObject:item];
    }
}

- (void)removeAllItems {
    [self.items removeAllObjects];
}

#pragma mark - Hit Test
- (FXTrackViewItem *)itemAtPoint:(CGPoint)point {
    for (FXTrackViewItem *item in self.items) {
        if ([item.layer.presentationLayer hitTest:point]) {
            return item;
        }
    }
    return nil;
}

@end
