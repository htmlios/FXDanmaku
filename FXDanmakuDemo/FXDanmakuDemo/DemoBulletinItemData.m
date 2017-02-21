//
//  DemoBulletinItemData.m
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/2/18.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "DemoBulletinItemData.h"
#import "DemoBulletinItem.h"

@implementation DemoBulletinItemData

+ (instancetype)dataWithDesc:(NSString *)desc avatarName:(NSString *)avatarName {
    DemoBulletinItemData *data = [DemoBulletinItemData dataWithItemReuseIdentifier:[DemoBulletinItem reuseIdentifier]];
    data.desc = desc;
    data.avatarName = avatarName;
    return data;
}

@end
