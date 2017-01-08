//
//  FXBarrageViewHeader.h
//  FXBarrageViewDemo
//
//  Created by ShawnFoo on 16/3/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#ifndef FXTrackViewHeader_h
#define FXTrackViewHeader_h

#ifdef __OBJC__

#define WeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;
#define StrongObj(o) autoreleasepool{} __strong typeof(o) o = o##Weak;

#ifdef DEBUG
#define LogD(format, ...) NSLog((@"\nFXTrackView: %s [Line %d]\n" format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define LogD(...) do {} while(0)
#endif

#ifdef DEBUG
#define FXTrackViewExceptionName @"FXTrackViewException"
#define FXException(desc) @throw [NSException \
exceptionWithName:FXTrackViewExceptionName \
reason:desc \
userInfo:nil];
#else
#define FXException(desc) do {} while(0)
#endif

#define RunBlock_Safe(block) {\
if (block) {\
block();\
}\
}

#define RunBlock_Safe_MainThread(block) {\
if ([NSThread isMainThread]) {\
RunBlock_Safe(block)\
}\
else {\
if (block) {\
dispatch_async(dispatch_get_main_queue(), block);\
}\
}\
}

#endif /* __OBJC__ */

#endif /* FXBarrageViewHeader_h */
