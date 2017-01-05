//
//  FXSingleRowItemsManager.h
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 2017/1/5.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FXTrackViewItem.h"

@interface FXSingleRowItemsManager : NSObject

- (void)addTrackViewItem:(FXTrackViewItem *)item;
- (void)removeTrackViewItem:(FXTrackViewItem *)item;
- (void)removeAllItems;

- (FXTrackViewItem *)itemAtPoint:(CGPoint)point;

@end
