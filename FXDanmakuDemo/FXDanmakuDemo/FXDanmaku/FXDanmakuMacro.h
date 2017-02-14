//
//  FXDanmakuMacro.h
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 16/3/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#ifndef FXDanmakuMacro_h
#define FXDanmakuMacro_h

#ifdef __OBJC__

#if DEBUG
#define ext_keywordify autoreleasepool {}
#else
#define ext_keywordify try {} @catch (...) {}
#endif

#define Weakify(o) ext_keywordify __weak typeof(o) o##Weak = o
#define Strongify(o) ext_keywordify __strong typeof(o) o = o##Weak
#define ReturnVoidIfSelfNil {\
if (!self) return;\
}

#define NSStringFromSelectorName(name) NSStringFromSelector(@selector(name))

#ifdef DEBUG
#define FXLogD(format, ...) NSLog((@"FXDanmaku: %s [Line %d]\n" format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define FXLogD(...) do {} while(0)
#endif

#ifdef DEBUG
#define FXDanmakuExceptionName @"FXDanmakuException"
#define FXException(format, ...) @throw [NSException \
exceptionWithName:FXDanmakuExceptionName \
reason:[NSString stringWithFormat:format, ##__VA_ARGS__]  \
userInfo:nil];
#else
#define FXException(...) do {} while(0)
#endif

#define RunBlockSafe(block, ...) {\
if (block) {\
block(__VA_ARGS__);\
}\
}

#define RunBlockSafe_MainThread(block) {\
if ([NSThread isMainThread]) {\
RunBlockSafe(block)\
}\
else {\
if (block) {\
dispatch_async(dispatch_get_main_queue(), block);\
}\
}\
}

#endif /* __OBJC__ */

#endif /* FXBarrageViewHeader_h */
