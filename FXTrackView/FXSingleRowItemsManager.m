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

@property (nonatomic, strong) NSHashTable<FXTrackViewItem *> *items;

@end

@implementation FXSingleRowItemsManager

#pragma mark - LazyLoading
- (NSHashTable<FXTrackViewItem *> *)items {
    if (!_items) {
        _items = [NSHashTable weakObjectsHashTable];
    }
    return _items;
}

#pragma mark - Operations
- (void)addTrackViewItem:(FXTrackViewItem *)item {
    if ([item isKindOfClass:[FXTrackViewItem class]]) {
        [self.items addObject:item];
    }
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
