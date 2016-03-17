//
//  FXBarrageViewHeader.h
//  FXBarrageViewDemo
//
//  Created by ShawnFoo on 16/3/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#ifndef FXBarrageViewHeader_h
#define FXBarrageViewHeader_h

#define FX_TrackViewBackgroundColor UIColorFromHexRGB(0x000000)

// 用于初略计算 弹道的高
#define FX_EstimatedTrackHeight 22

// 字幕大小
#define FX_TextFontSize 18
#define FX_TextFontColor UIColorFromHexRGB(0xFFA042)
#define FX_TextShadowColor UIColorFromHexRGB(0x272727)
#define FX_TextShadowOffset CGSizeMake(1, 1)

// 重置弹道的位移百分比
#define FX_ResetTrackOffsetRatio 0.2

#define FX_MinVelocity 120

#define FX_MaxVelocity 150

// 按十分之一的重置距离 算出的公式如下 10*minVel*lbWidth = width*minVel + 9*lbWidth*gap  (gap为最大速度与最小速度之差)


// ====================      PreDefined Macro Start       ====================

#define UIColorFromHexRGB(rgbValue) \
([UIColor colorWithRed:((float)((rgbValue&0xFF0000)>>16))/255.0 \
green:((float)((rgbValue&0xFF00)>>8))/255.0 \
blue:((float)(rgbValue&0xFF))/255.0 \
alpha:1])

#ifdef DEBUG
#define LogD(format, ...) NSLog((@"\n%s [Line %d]\n" format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define LogD(...) do {} while(0)
#endif

#ifdef DEBUG
#define RaiseExceptionWithFormat(formatStr, ...) \
[NSException raise:NSGenericException format:@"%s [line %d] " formatStr, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__];
#else
#define RaiseExceptionWithFormat(formatStr, ...) do {} while(0)
#endif

#define WeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;
#define StrongObj(o) autoreleasepool{} __strong typeof(o) o = o##Weak;

//  ====================      PreDefined Macro End       ====================

#endif /* FXBarrageViewHeader_h */
