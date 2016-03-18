//
//  JCBarrageView.m
//  
//
//  Created by ShawnFoo on 12/4/15.
//  Copyright © 2015 ShawnFoo. All rights reserved.
//

#import "FXTrackView.h"
#import "FXBarrageViewHeader.h"
#import "FXDeallocMonitor.h"
#import "FXSemaphore.h"
#import <pthread.h>

#if DEBUG
#define PrintBarrageTestLog 0
#endif

typedef NS_ENUM(NSUInteger, TrackViewStatus) {
    StatusNotStarted = 1001,
    StatusRunning,
    StatusPaused,
    StatusStoped
};

@interface FXTrackView () {
    pthread_mutex_t _track_mutex;
    pthread_cond_t _track_prod, _track_cons;
    pthread_mutex_t _carrier_mutex;
    pthread_cond_t _carrier_prod, _carrier_cons;
    
    __block TrackViewStatus _status;
    __block BOOL _hasTracks;
    __block BOOL _hasCarriers;
}

@property (assign, nonatomic) BOOL gotExactFrame;
@property (assign, nonatomic) int numOfTracks;
@property (assign, nonatomic) CGFloat trackHeight;

@property (strong, nonatomic) NSMutableArray *anchorWordsArr;
@property (strong, nonatomic) NSMutableArray *usersWordsArr;

@property (strong, nonatomic) dispatch_queue_t consumerQueue;
@property (strong, nonatomic) dispatch_queue_t trackProducerQueue;
@property (strong, nonatomic) dispatch_queue_t carrierProducerQueue;
@property (strong, nonatomic) dispatch_queue_t computationQueue;

// 按位判断某条弹道是否被占用
@property (assign, nonatomic) NSUInteger occupiedTrackBit;

@end

@implementation FXTrackView

#pragma mark - Getter

- (dispatch_queue_t)consumerQueue {
    
    if (!_consumerQueue) {
        _consumerQueue = dispatch_queue_create("shawnfoo.trackView.consumerQueue", NULL);
    }
    return _consumerQueue;
}


- (dispatch_queue_t)trackProducerQueue {
    
    if (!_trackProducerQueue) {
        _trackProducerQueue = dispatch_queue_create("shawnfoo.trackView.trackProducerQueue", NULL);
    }
    return _trackProducerQueue;
}

- (dispatch_queue_t)carrierProducerQueue {
    
    if (!_trackProducerQueue) {
        _trackProducerQueue = dispatch_queue_create("shawnfoo.trackView.carrierProducerQueue", NULL);
    }
    return _trackProducerQueue;
}

- (dispatch_queue_t)computationQueue {
    
    if (!_computationQueue) {
        _computationQueue = dispatch_queue_create("shawnfoo.trackView.computationQueue", NULL);
    }
    return _computationQueue;
}

- (NSMutableArray *)usersWordsArr {
    
    if (!_usersWordsArr) {
        _usersWordsArr = [NSMutableArray arrayWithCapacity:15];
    }
    return _usersWordsArr;
}

- (NSMutableArray *)anchorWordsArr {
    
    if (!_anchorWordsArr) {
        
        _anchorWordsArr = [NSMutableArray arrayWithCapacity:1];
    }
    return _anchorWordsArr;
}

#pragma mark - Initializer

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        [self commonSetup];
    }
    return self;
}

#pragma mark - LifeCycle

- (void)awakeFromNib {
    [super awakeFromNib];
    [self commonSetup];
}

- (void)commonSetup {
    
    _status = StatusNotStarted;
    
    pthread_mutex_init(&_track_mutex, NULL);
    pthread_cond_init(&_track_prod, NULL);
    pthread_cond_init(&_track_cons, NULL);
    
    pthread_mutex_init(&_carrier_mutex, NULL);
    pthread_cond_init(&_carrier_prod, NULL);
    pthread_cond_init(&_carrier_cons, NULL);
    
#ifdef FX_TrackViewBackgroundColor
    self.backgroundColor = FX_TrackViewBackgroundColor;
#else
    self.backgroundColor = [UIColor clearColor];
#endif
    [self calcTracks];
    [FXDeallocMonitor addMonitorToObj:self];
}

- (void)dealloc {
    
    pthread_mutex_destroy(&_track_mutex);
    pthread_mutex_destroy(&_carrier_mutex);
    pthread_cond_destroy(&_track_prod);
    pthread_cond_destroy(&_track_cons);
    pthread_cond_destroy(&_carrier_prod);
    pthread_cond_destroy(&_carrier_cons);
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        RaiseExceptionWithFormat(@"Please make sure trackview's size is not zero!");
    }
    else {
        if (!_gotExactFrame) {
            [self calcTracks];
        }
    }
}

- (void)addUserWords:(NSString *)words {
    
    if (!self.hidden) {// 隐藏期间不接收任何数据
        
        @WeakObj(self);
        dispatch_async(self.carrierProducerQueue, ^{
            @StrongObj(self);
            pthread_mutex_lock(&_carrier_mutex);
            LogD(@"☀️_carrier_prod get lock");
            if (words.length > 0) {
                
                [self.usersWordsArr addObject:words];
                if (!_hasCarriers) {
                    _hasCarriers = YES;
                    pthread_cond_signal(&_carrier_cons);
                }
            }
            pthread_mutex_unlock(&_carrier_mutex);
        });
    }
}

//- (void)addAnchorWords:(NSString *)words {
//    
//    if (!self.hidden) {// 隐藏期间不接收任何数据
//        
//        dispatch_async(self.producerQueue, ^{
//            if (words.length > 0) {
//                [self.anchorWordsArr addObject:words];
//                dispatch_semaphore_signal(self.carrierSemaphore);
//            }
//        });
//    }
//}

#pragma mark - Actions

- (void)start {
    
    _status = StatusRunning;
    if (!CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        dispatch_async(self.consumerQueue, ^{
            [self consumeCarrier];
        });
    }
}

- (void)pause {
    
    _status = StatusPaused;
    [self cancelConsume];
    self.hidden = YES;
}

- (void)resume {
    
    _status = StatusRunning;
    [self start];
    self.hidden = NO;
}

- (void)stop {
    
    _status = StatusStoped;
    [self cancelConsume];
    // Break the waiting of consumers!!! Otherwise, self can't be released. Memory leaks!!
    if (!_hasTracks) {
        pthread_mutex_lock(&_track_mutex);
        _hasTracks = YES;
        pthread_cond_signal(&_track_cons);
        pthread_mutex_unlock(&_track_mutex);
    }
    if (!_hasCarriers) {
        pthread_mutex_lock(&_carrier_mutex);
        _hasCarriers = YES;
        pthread_cond_signal(&_carrier_cons);
        pthread_mutex_unlock(&_carrier_mutex);
    }
}

- (void)cancelConsume {
    
//    dispatch_sync(self.producerQueue, ^{
//        _occupiedTrackBit = 0;
//        [_anchorWordsArr removeAllObjects];
//        [_usersWordsArr removeAllObjects];
//    });
    [self clearScreen];
}

#pragma mark - Private

- (void)calcTracks {
    
    self.gotExactFrame = !CGSizeEqualToSize(self.frame.size, CGSizeZero);
    
    if (_gotExactFrame) {
        CGFloat height = self.frame.size.height;
        self.numOfTracks = floor(height / FX_EstimatedTrackHeight);
        self.trackHeight = height / _numOfTracks;
        _hasTracks = _numOfTracks > 0;
    }
}

- (void)clearScreen {
    
    for (UIView *subViews in self.subviews) {
        [subViews removeFromSuperview];
    }
}

- (NSArray *)getUserWords {
    
    pthread_mutex_lock(&_carrier_mutex);
    LogD(@"☀️_carrier_cons get lock");
    while (!_hasCarriers) {// no carriers, waiting for producer to signal to consumer
        LogD(@"☀️_carrier_cons waiting");
        pthread_cond_wait(&_carrier_cons, &_carrier_mutex);
    }
    NSArray *userWords = nil;
    if (StatusRunning == _status) {
        userWords = _usersWordsArr.copy;
        [_usersWordsArr removeAllObjects];
        _hasCarriers = NO;
    }
    pthread_mutex_unlock(&_carrier_mutex);
    return userWords;
}

//- (NSString *)getAnchorWords {
//    
//    __block NSString *anchorWords = nil;
//    dispatch_sync(self.producerQueue, ^{
//        anchorWords = _anchorWordsArr.firstObject;
//        if (anchorWords) {
//            [_anchorWordsArr removeObjectAtIndex:0];
//        }
//    });
//    return anchorWords;
//}

- (void)setOccupiedTrackAtIndex:(int)index {
    
    if (index < self.numOfTracks) {
        self.occupiedTrackBit |= 1 << index;
    }
}

- (void)removeOccupiedTrackAtIndex:(int)index {
    
    pthread_mutex_lock(&_track_mutex);
    if (index < self.numOfTracks) {
        LogD(@"🌎_track_prod get lock");
        self.occupiedTrackBit -= 1 << index;
        if (!_hasTracks) {
            _hasTracks = YES;
            pthread_cond_signal(&_track_cons);
        }
    }
    pthread_mutex_unlock(&_track_mutex);
}

#pragma mark 弹幕动画相关

// 随机未占用弹道
- (int)randomUnoccupiedTrackIndex {
    
    //TODO: 判断status
    
    pthread_mutex_lock(&_track_mutex);
    LogD(@"🌎_track_cons get lock");
    while (!_hasTracks) {
        LogD(@"🌎_track_cons waiting");
        pthread_cond_wait(&_track_cons, &_track_mutex);
    }
    
    int index = -1;
    if (StatusRunning == _status) {
        NSMutableArray *randomArr = nil;
        for (int i = 0; i < _numOfTracks; i++) {
            
            if ( 1<<i & _occupiedTrackBit) {
                continue;
            }
            if (!randomArr) {
                randomArr = [NSMutableArray arrayWithCapacity:_numOfTracks];
            }
            [randomArr addObject:@(i)];
        }
        NSUInteger count = randomArr.count;
        NSNumber *num = (count==1 ? randomArr[0] : randomArr[arc4random()%count]);
        index = num.intValue;
        [self setOccupiedTrackAtIndex:index];
        
        _hasTracks = count > 1 ? YES : NO;
    }
    
    pthread_mutex_unlock(&_track_mutex);
    return index;
}

// 随机移动速度
- (NSUInteger)randomVelocity {
    
    return arc4random()%(FX_MaxVelocity-FX_MinVelocity) + FX_MinVelocity;
}

// 动画时间
- (CGFloat)animateDurationOfVelocity:(NSUInteger)velocity carrierWidth:(CGFloat)width {
    
    // 总的移动距离 = 背景View宽度 + 弹幕块本身宽度
    return (self.frame.size.width + width) / velocity;
}

// 重置弹道时间
- (CGFloat)resetTrackTimeOfVelocity:(NSUInteger)velocity carrierWidth:(CGFloat)width {
    
    // 重置距离 + 弹幕块本身长度  才是总的移动距离(判断的点为末尾的X坐标)
    return (self.frame.size.width*FX_ResetTrackOffsetRatio + width) / velocity;
}

// 弹幕块起始坐标
- (CGPoint)startPointWithIndex:(int)index {
    
    return CGPointMake(self.frame.size.width, index * _trackHeight);
}

- (void)consumeCarrier {
    
    while (StatusRunning == _status) {
        
        NSArray *usersWords = [self getUserWords];
        for (NSString *word in usersWords) {
            if (StatusRunning == _status) {
                int unoccupiedIndex = [self randomUnoccupiedTrackIndex];
                if (unoccupiedIndex > -1) {
                    dispatch_async(self.computationQueue, ^{
                        [self presentUserWords:word withBarrageIndex:unoccupiedIndex];
                    });
                }
                else { break; }
            }
            else { break; }
        }
        
//        int randomIndex = [self randomUnoccupiedTrackIndex];
//        
//        if (randomIndex > -1) {
//            
////            NSString *anchorWords = [self getAnchorWords];
////            NSString *usersWords = anchorWords?nil:[self getUserWords];
//            NSString *usersWords = [self getUserWords];
//            
//            @WeakObj(self);
//            dispatch_async(self.computationQueue, ^{
//                @StrongObj(self);
////                if (anchorWords.length > 0) {
////                    [self presentAnchorWords:anchorWords withBarrageIndex:randomIndex];
////                }
////                else
//                if (usersWords.length > 0) {
//                    [self presentUserWords:usersWords withBarrageIndex:randomIndex];
//                }
//                else {
//                    
//                }
//            });
//        }
    }
}

- (void)presentAnchorWords:(NSString *)words withBarrageIndex:(int)index {
    // 以后更多DIY可在此进行
    UIColor *color = UIColorFromHexRGB(0xf9a520);
    [self presentWords:words color:color barrageIndex:index];
}

- (void)presentUserWords:(NSString *)words withBarrageIndex:(int)index {
    // 以后更多DIY可在此进行
    UIColor *color = [UIColor whiteColor];
    [self presentWords:words color:color barrageIndex:index];
}

- (void)presentWords:(NSString *)title color:(UIColor *)color barrageIndex:(int)index {

#if PrintBarrageTestLog
    static int count = 0;
    count++;
    NSLog(@"%@, count:%@", title, @(count));
#endif
    
    NSDictionary *fontAttr = @{NSFontAttributeName: [UIFont systemFontOfSize:FX_TextFontSize]};
    CGPoint point = [self startPointWithIndex:index];
    CGSize size = [title sizeWithAttributes:fontAttr];
    
    NSUInteger velocity = [self randomVelocity];
    
    CGFloat animDuration = [self animateDurationOfVelocity:velocity carrierWidth:size.width];
    CGFloat resetTime = [self resetTrackTimeOfVelocity:velocity carrierWidth:size.width];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = FX_TextShadowColor;
    shadow.shadowOffset = FX_TextShadowOffset;
    
    NSDictionary *attrs = @{
                            NSFontAttributeName: [UIFont systemFontOfSize:FX_TextFontSize],
                            NSForegroundColorAttributeName: color,//FX_TextFontColor
                            NSShadowAttributeName: shadow
                            };
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:title attributes:attrs];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UILabel *lb = [[UILabel alloc] initWithFrame:CGRectMake(point.x, point.y, size.width, _trackHeight)];
        lb.text = title;
        lb.attributedText = attrStr;
        [self addSubview:lb];
        
        [UIView animateWithDuration:animDuration
                              delay:0
                            options:UIViewAnimationOptionCurveLinear
                         animations:
         ^{
             
             CGRect rect = lb.frame;
             rect.origin.x = -rect.size.width;
             lb.frame = rect;
             [lb layoutIfNeeded];
         } completion:^(BOOL finished) {
             
             [lb removeFromSuperview];
         }];
    });
    
    // 重置弹道
    @WeakObj(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, resetTime * NSEC_PER_SEC), self.trackProducerQueue, ^(void){
        @StrongObj(self);
        [self removeOccupiedTrackAtIndex:index];
    });
}

@end
