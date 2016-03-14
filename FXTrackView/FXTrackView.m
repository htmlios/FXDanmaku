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

#if DEBUG
#define PrintBarrageTestLog 0
#endif

@interface FXTrackView ()

@property (assign, nonatomic) BOOL gotExactFrame;
@property (assign, nonatomic) unsigned int numOfTracks;
@property (assign, nonatomic) CGFloat trackHeight;

@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSMutableArray *anchorWordsArr;
@property (strong, nonatomic) NSMutableArray *usersWordsArr;

@property (strong, nonatomic) dispatch_queue_t consumerQueue;
@property (strong, nonatomic) dispatch_queue_t producerQueue;

// 按位判断某条弹道是否被占用
@property (assign, nonatomic) NSUInteger occupiedTrackBit;

@property (strong, nonatomic) dispatch_semaphore_t carrierSemaphore;
@property (strong, nonatomic) dispatch_semaphore_t trackSemaphore;

@end

@implementation FXTrackView

#pragma mark - Getter

- (dispatch_queue_t)producerQueue {
    
    if (!_producerQueue) {
        _producerQueue = dispatch_queue_create("shawnfoo.trackView.producerQueue", NULL);
    }
    return _producerQueue;
}

- (dispatch_queue_t)consumerQueue {
    
    if (!_consumerQueue) {
        _consumerQueue = dispatch_queue_create("shawnfoo.trackView.consumerQueue", NULL);
    }
    return _consumerQueue;
}

- (dispatch_semaphore_t)carrierSemaphore {
    
    if (!_carrierSemaphore) {
        _carrierSemaphore = dispatch_semaphore_create(0);
    }
    return _carrierSemaphore;
}

- (dispatch_semaphore_t)trackSemaphore {
    
    if (!_trackSemaphore) {
        _trackSemaphore = dispatch_semaphore_create(_numOfTracks);
    }
    return _trackSemaphore;
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

- (void)awakeFromNib {
    [super awakeFromNib];
    [self commonSetup];
}

- (void)commonSetup {
    
     self.backgroundColor = [UIColor clearColor];
    [self calcTracks];
    [FXDeallocMonitor addMonitorToObj:self];
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
        
        dispatch_async(self.producerQueue, ^{
            if (words.length > 0) {
                [self.usersWordsArr addObject:words];
                dispatch_semaphore_signal(self.carrierSemaphore);
            }
        });
    }
}

- (void)addAnchorWords:(NSString *)words {
    
    if (!self.hidden) {// 隐藏期间不接收任何数据
        
        dispatch_async(self.producerQueue, ^{
            if (words.length > 0) {
                [self.anchorWordsArr addObject:words];
                dispatch_semaphore_signal(self.carrierSemaphore);
            }
        });
    }
}

#pragma mark - Actions

- (void)start {
    
    if (!CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        dispatch_async(self.consumerQueue, ^{
            [self consumeCarrier];
        });
    }
    
//    dispatch_async(self.consumerQueue, ^{
//        
////        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(consumeCarrier) userInfo:nil repeats:YES];
//        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(consumeCarrier) userInfo:nil repeats:NO];
//        [[NSRunLoop currentRunLoop] run];
//    });
}

- (void)pause {
    
    if (self.timer) {
        
        [self.timer invalidate];
        self.timer = nil;
        dispatch_async(self.producerQueue, ^{

            [_anchorWordsArr removeAllObjects];
            [_usersWordsArr removeAllObjects];
            _carrierSemaphore = nil;
            _trackSemaphore = nil;
        });
        [self clearScreen];
        self.hidden = YES;
    }
}

- (void)resume {
    
    if (!self.timer) {
        
        [self start];
        self.hidden = NO;
    }
}

- (void)stop {
    
    if (self.timer) {
        
        [self.timer invalidate];
        self.timer = nil;
        [self removeFromSuperview];
    }
}

#pragma mark - Private

- (void)calcTracks {
    
    self.gotExactFrame = !CGSizeEqualToSize(self.frame.size, CGSizeZero);
    
    if (_gotExactFrame) {
        CGFloat height = self.frame.size.height;
        self.numOfTracks = height / FX_EstimatedTrackHeight;
        self.trackHeight = height / _numOfTracks;
    }
}

- (void)clearScreen {
    
    for (UIView *subViews in self.subviews) {
        [subViews removeFromSuperview];
    }
}

- (NSString *)getUserWords {
    
    NSString *userWords = [_usersWordsArr firstObject];
    if (userWords.length > 0) {
        dispatch_async(self.producerQueue, ^{
            [_usersWordsArr removeObjectAtIndex:0];
        });
    }
    return userWords;
}

- (NSString *)getAnchorWords {
    
    NSString *anchorWords = [_anchorWordsArr firstObject];
    if (anchorWords.length > 0) {
        dispatch_async(self.producerQueue, ^{
            [_anchorWordsArr removeObjectAtIndex:0];
        });
    }
    return anchorWords;
}

- (void)setOccupiedTrackAtIndex:(NSUInteger)index {
    
    if (index < self.numOfTracks) {
        self.occupiedTrackBit |= 1 << index;
    }
}

- (void)removeOccupiedTrackAtIndex:(NSUInteger)index {
    if (index < self.numOfTracks) {
        self.occupiedTrackBit -= 1 << index;
        dispatch_semaphore_signal(self.trackSemaphore);
    }
}

#pragma mark 弹幕动画相关

// 随机未占用弹道
- (int)randomUnoccupiedTrackIndex {
    
    dispatch_semaphore_wait(self.trackSemaphore, DISPATCH_TIME_FOREVER);
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
    if (count > 0) {
        
        NSNumber *num = (count==1 ? randomArr[0] : randomArr[arc4random()%count]);
        dispatch_async(self.producerQueue, ^{
            [self setOccupiedTrackAtIndex:num.intValue];
        });
        return num.intValue;
    }
    return -1;
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
    
    return CGPointMake(self.frame.origin.x+self.frame.size.width, index * _trackHeight);
}

- (void)consumeCarrier {
    
    while (true) {
        
        int randomIndex = [self randomUnoccupiedTrackIndex];
        
        if (randomIndex > -1) {
            
            dispatch_semaphore_wait(self.carrierSemaphore, DISPATCH_TIME_FOREVER);
            
            NSString *anchorWords = [self getAnchorWords];
            NSString *usersWords = anchorWords?nil:[self getUserWords];
            if (anchorWords.length > 0) {
                [self presentAnchorWords:anchorWords withBarrageIndex:randomIndex];
            }
            else if (usersWords.length > 0) {
                [self presentUserWords:usersWords withBarrageIndex:randomIndex];
            }
            else {
                NSLog(@"This line will never run");
                dispatch_async(self.producerQueue, ^{
                    [self removeOccupiedTrackAtIndex:randomIndex];
                });
            }
        }
        else {
            NSLog(@"This line will never run");
        }
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
    
//    NSAttributedString *attrStr = [title bos_makeString:^(BOStringMaker *make) {
//        
//        make.font([UIFont systemFontOfSize:kWordsFontSize]);
//        make.foregroundColor(color);
//        NSShadow *shadow = [[NSShadow alloc] init];
//        shadow.shadowColor = [UIColor blackColor];
//        shadow.shadowOffset = CGSizeMake(1, 1);
//        make.shadow(shadow);
//    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UILabel *lb = [[UILabel alloc] initWithFrame:CGRectMake(point.x, point.y, size.width, _trackHeight)];
        lb.text = title;
        lb.textColor = color;
        lb.font = [UIFont systemFontOfSize:FX_TextFontSize];
//        lb.attributedText = attrStr;
        
        [self addSubview:lb];
        
        [UIView animateWithDuration:animDuration
                              delay:0
                            options:UIViewAnimationOptionCurveLinear
                         animations:
         ^{
             
             CGRect rect = lb.frame;
             rect.origin.x = -rect.size.width;
             lb.frame = rect;
             [self layoutIfNeeded];
         } completion:^(BOOL finished) {
             
             [lb removeFromSuperview];
         }];
    });
    
    // 重置弹道
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, resetTime * NSEC_PER_SEC), self.producerQueue, ^(void){
        [self removeOccupiedTrackAtIndex:index];
    });
}

@end
