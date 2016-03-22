//
//  FXTrackView.m
//  
//
//  Created by ShawnFoo on 12/4/15.
//  Copyright © 2015 ShawnFoo. All rights reserved.
//

#import "FXTrackView.h"
#import "FXTrackViewHeader.h"
#import "FXDeallocMonitor.h"
#import <pthread.h>

typedef NS_ENUM(NSUInteger, TrackViewStatus) {
    StatusNotStarted = 1001,
    StatusRunning,
    StatusStoped
};

NSString const *FXDataTextKey = @"kFXDataText";
NSString const *FXTextCustomAttrsKey = @"kFXTextCustomAttrs";
NSString const *FXDataCustomViewKey = @"kFXDataCustomView";
NSString const *FXDataPriorityKey = @"kFXDataPriority";

@interface FXTrackView () {
    pthread_mutex_t _track_mutex;
    pthread_cond_t _track_prod, _track_cons;
    pthread_mutex_t _data_mutex;
    pthread_cond_t _data_prod, _data_cons;
    
    __block TrackViewStatus _status;
    __block BOOL _hasTracks;
    __block BOOL _hasData;
}

@property (assign, nonatomic) BOOL gotExactFrame;
@property (assign, nonatomic) NSInteger numOfTracks;
@property (assign, nonatomic) CGFloat trackHeight;

@property (strong, nonatomic) NSMutableArray *dataArr;

@property (strong, nonatomic) dispatch_queue_t consumerQueue;
@property (strong, nonatomic) dispatch_queue_t trackProducerQueue;
@property (strong, nonatomic) dispatch_queue_t dataProducerQueue;
@property (strong, nonatomic) dispatch_queue_t computationQueue;

@property (strong, nonatomic) FXTextAttrs defaultAttrs;

@property (assign, nonatomic) NSUInteger occupiedTrackBit;

@property (assign, readonly, nonatomic) BOOL shouldAcceptData;

@end

@implementation FXTrackView

#pragma mark - Lazy Loading Getter

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

- (dispatch_queue_t)dataProducerQueue {
    
    if (!_dataProducerQueue) {
        _dataProducerQueue = dispatch_queue_create("shawnfoo.trackView.dataProducerQueue", NULL);
    }
    return _dataProducerQueue;
}

- (dispatch_queue_t)computationQueue {
    
    if (!_computationQueue) {
        _computationQueue = dispatch_queue_create("shawnfoo.trackView.computationQueue", NULL);
    }
    return _computationQueue;
}

- (NSMutableArray *)dataArr {

    if (!_dataArr) {
        _dataArr = [NSMutableArray arrayWithCapacity:15];
    }
    return _dataArr;
}

- (FXTextAttrs)defaultAttrs {
    
    if (!_defaultAttrs) {
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowColor = FX_TextShadowColor;
        shadow.shadowOffset = FX_TextShadowOffset;
        
        _defaultAttrs = @{
                          NSFontAttributeName: [UIFont systemFontOfSize:FX_TextFontSize],
                          NSForegroundColorAttributeName: [UIColor whiteColor],
                          NSShadowAttributeName: shadow
                          };
    }
    
    return _defaultAttrs;
}

#pragma mark Computed Property

- (BOOL)shouldAcceptData {
    
    BOOL notStoped = StatusStoped != _status;

    return notStoped || (!notStoped && _acceptDataWhenStoped);
}

#pragma mark - LifeCycle

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
    
    _status = StatusNotStarted;

    self.maxVelocity = !_maxVelocity ? FX_MaxVelocity : _maxVelocity;
    self.minVelocity = !_minVelocity ? FX_MinVelocity : _minVelocity;
    self.clearScreenWhenStoped = YES;
    self.emptyDataWhenStoped = YES;
    self.acceptDataWhenStoped = YES;
    
#ifdef FX_TrackViewBackgroundColor
    self.backgroundColor = FX_TrackViewBackgroundColor;
#else
    self.backgroundColor = [UIColor clearColor];
#endif
    
    pthread_mutex_init(&_track_mutex, NULL);
    pthread_cond_init(&_track_prod, NULL);
    pthread_cond_init(&_track_cons, NULL);
    
    pthread_mutex_init(&_data_mutex, NULL);
    pthread_cond_init(&_data_prod, NULL);
    pthread_cond_init(&_data_cons, NULL);

    [FXDeallocMonitor addMonitorToObj:self];
}

- (void)dealloc {
    
    pthread_mutex_destroy(&_track_mutex);
    pthread_mutex_destroy(&_data_mutex);
    pthread_cond_destroy(&_track_prod);
    pthread_cond_destroy(&_track_cons);
    pthread_cond_destroy(&_data_prod);
    pthread_cond_destroy(&_data_cons);
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!_gotExactFrame) {
        [self calcTracks];
    }
}

- (void)calcTracks {
    
    self.gotExactFrame = !CGSizeEqualToSize(self.frame.size, CGSizeZero);
    
    if (_gotExactFrame) {
        CGFloat height = self.frame.size.height;
        self.numOfTracks = floor(height / FX_EstimatedTrackHeight);
        self.trackHeight = height / _numOfTracks;
        _hasTracks = _numOfTracks > 0;
    }
    else {
        LogD(@"TrackView's size can't be zero!");
    }
}

#pragma mark - Actions

- (void)start {
    
    RunBlock_Safe_MainThread(^{
        if (StatusRunning != _status) {
            _status = StatusRunning;
            [self startConsuming];
        }
    });
}

- (void)stop {
    
    RunBlock_Safe_MainThread(^{
        if (StatusStoped != _status) {
            _status = StatusStoped;
            [self stopConsuming];
            [self clearTrackView];
        }
    });
}

- (void)startConsuming {
    
    if (!CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        dispatch_async(self.consumerQueue, ^{
            [self consumeData];
        });
    }
}

- (void)stopConsuming {
    
    // Exit the consumer thread if waiting! Otherwise, self can't be released. Memory leaks!
    if (!_hasTracks) {
        pthread_mutex_lock(&_track_mutex);
        _hasTracks = YES;
        pthread_cond_signal(&_track_cons);
        pthread_mutex_unlock(&_track_mutex);
    }
    if (!_hasData) {
        pthread_mutex_lock(&_data_mutex);
        _hasData = YES;
        pthread_cond_signal(&_data_cons);
        pthread_mutex_unlock(&_data_mutex);
    }
}

- (void)clearTrackView {
    
    for (UIView *subViews in self.subviews) {
        [subViews removeFromSuperview];
    }
}

#pragma mark - Data Producer & Consumer

- (void)addData:(FXData)data {
    
    if (!self.shouldAcceptData) { return; }
    dispatch_async(self.dataProducerQueue, ^{
        pthread_mutex_lock(&_data_mutex);
        LogD(@"☀️_carrier_prod get lock");
        if ([self checkData:data]) {
            [self insertData:data];
            if (!_hasData) {
                _hasData = YES;
                if (StatusRunning == _status) {
                    pthread_cond_signal(&_data_cons);
                }
            }
        }
        pthread_mutex_unlock(&_data_mutex);
    });
}

- (void)addDataArr:(NSArray *)dataArr {
    
    if (!self.shouldAcceptData) { return; }
    if (0 == dataArr.count) { return; }
    dispatch_async(self.dataProducerQueue, ^{
        pthread_mutex_lock(&_data_mutex);
        LogD(@"☀️_carrier_prod get lock");
        BOOL addedData = NO;
        for (FXData data in dataArr) {
            if ([self checkData:data]) {
                [self insertData:data];
                addedData = YES;
            }
        }
        if (!_hasData && addedData) {
            _hasData = YES;
            if (StatusRunning == _status) {
                pthread_cond_signal(&_data_cons);
            }
        }
        pthread_mutex_unlock(&_data_mutex);
    });
}

- (FXData)fetchData {
    
    pthread_mutex_lock(&_data_mutex);
    LogD(@"☀️_data_cons get lock");
    while (!_hasData) {// no carriers, waiting for producer to signal to consumer
        LogD(@"☀️_data_cons waiting");
        pthread_cond_wait(&_data_cons, &_data_mutex);
        LogD(@"☀️_data_cons continuing");
    }
    FXData data = nil;
    if (StatusRunning == _status) {
        data = _dataArr.firstObject;
        if (data) {
            [_dataArr removeObjectAtIndex:0];
        }
        _hasData = _dataArr.count > 0;
    }
    pthread_mutex_unlock(&_data_mutex);
    return data;
}

- (BOOL)checkData:(FXData)data {
    
    NSString *text = data[FXDataTextKey];
    
    if ([text isKindOfClass:[NSString class]] && text.length>0) {
        return true;
    }
    if ([data[FXTextCustomAttrsKey] isKindOfClass:[NSDictionary class]]) {
        return true;
    }
    //TODO: Add CustomView Support
    
    return false;
}

- (void)insertData:(FXData)data {
    
    NSNumber *priority = data[FXDataPriorityKey];
    if (!priority || PriorityNormal == priority.unsignedIntegerValue) {
        [self.dataArr addObject:data];
    }
    else if (PriorityHigh == priority.unsignedIntegerValue) {
        [self.dataArr insertObject:data atIndex:0];
    }
}

#pragma mark - Track Producer & Consumer

- (NSInteger)fetchRandomUnoccupiedTrackIndex {
    
    pthread_mutex_lock(&_track_mutex);
    LogD(@"🌎_track_cons get lock");
    while (!_hasTracks) {
        LogD(@"🌎_track_cons waiting");
        pthread_cond_wait(&_track_cons, &_track_mutex);
    }
    
    NSInteger index = -1;
    if (StatusRunning == _status) {
        
        UInt8 *array = NULL;
        int n = 0;
        for (int i = 0; i < _numOfTracks; i++) {
            if (1<<i & self.occupiedTrackBit) {
                continue;
            }
            if (!array) {
                array = malloc(sizeof(UInt8)*(_numOfTracks-i));
            }
            array[n++] = i;
        }
        if (array) {
            index = array[arc4random()%n];
            [self setOccupiedTrackAtIndex:index];
            _hasTracks = n > 1 ? YES : NO;
            free(array);
        }
        else {
            _hasTracks = NO;
        }
    }
    
    pthread_mutex_unlock(&_track_mutex);
    return index;
}

- (NSInteger)fetchOrderedUnoccupiedTrackIndex {
    
    pthread_mutex_lock(&_track_mutex);
    LogD(@"🌎_track_cons get lock");
    while (!_hasTracks) {
        LogD(@"🌎_track_cons waiting");
        pthread_cond_wait(&_track_cons, &_track_mutex);
    }
    
    NSInteger index = -1;
    if (StatusRunning == _status) {
        
        BOOL hasTracks = NO;
        for (int i = 0; i < _numOfTracks; i++) {
            
            if (1<<i & self.occupiedTrackBit) {
                continue;
            }
            else if (-1 == index) {
                index = i;
            }
            else {
                hasTracks = YES;
            }
        }
        if (index > -1) {
            [self setOccupiedTrackAtIndex:index];
        }
        _hasTracks = hasTracks;
    }
    
    pthread_mutex_unlock(&_track_mutex);
    return index;
}

- (void)setOccupiedTrackAtIndex:(NSInteger)index {
    
    if (index < self.numOfTracks) {
        self.occupiedTrackBit |= 1 << index;
    }
}

- (void)removeOccupiedTrackAtIndex:(NSInteger)index {
    
    pthread_mutex_lock(&_track_mutex);
    if (index < self.numOfTracks) {
        self.occupiedTrackBit -= 1 << index;
        if (!_hasTracks) {
            _hasTracks = YES;
            pthread_cond_signal(&_track_cons);
        }
    }
    pthread_mutex_unlock(&_track_mutex);
}

#pragma mark - Animation Computation

// random vel
- (NSUInteger)randomVelocity {
    
    return arc4random()%(FX_MaxVelocity-FX_MinVelocity) + FX_MinVelocity;
}

// animation time
- (CGFloat)animateDurationOfVelocity:(NSUInteger)velocity carrierWidth:(CGFloat)width {
    
    return (self.frame.size.width + width) / velocity;
}

// time to reset occupied track
- (CGFloat)resetTrackTimeOfVelocity:(NSUInteger)velocity carrierWidth:(CGFloat)width {
    
    // totalDisplacement = resetDisplacement + carrierWidth
    return (self.frame.size.width*FX_ResetTrackOffsetRatio + width) / velocity;
}

// start point of carrier
- (CGPoint)startPointWithIndex:(NSUInteger)index {
    
    return CGPointMake(self.frame.size.width, index * _trackHeight);
}

#pragma mark - Carrier Presentation

- (void)consumeData {
    
    while (StatusRunning == _status) {
        
        FXData data = [self fetchData];
        if (data) {
#if FX_TrackRandom
            NSInteger unoccupiedIndex = [self fetchRandomUnoccupiedTrackIndex];
#else
            NSInteger unoccupiedIndex = [self fetchOrderedUnoccupiedTrackIndex];
#endif
            if (unoccupiedIndex > -1) {
                dispatch_async(self.computationQueue, ^{
                    if (data[FXDataTextKey]) {
                        FXTextAttrs attrs = data[FXTextCustomAttrsKey] ?: nil;
                        if (!attrs) {
                            NSNumber *priority = data[FXDataPriorityKey];
                            if (PriorityNormal == priority.unsignedIntegerValue) {
                                attrs = self.normalPriorityTextAttrs;
                            }
                            else if (PriorityHigh == priority.unsignedIntegerValue) {
                                attrs = self.highPriorityTextAttrs;
                            }
                            attrs = attrs ?: self.defaultAttrs;
                        }
                        [self presentText:data[FXDataTextKey] attrs:attrs trackIndex:unoccupiedIndex];
                    }
                    else if (data[FXDataCustomViewKey]) {
                        [self presentCustomView:data[FXDataCustomViewKey] trackIndex:unoccupiedIndex];
                    }
                });
            }
            else if (!_emptyDataWhenStoped) {
                // add it back
                pthread_mutex_lock(&_data_mutex);
                [_dataArr insertObject:data atIndex:0];
                pthread_mutex_unlock(&_data_mutex);
            }
        }
    }
    LogD(@"stopConsuming");
    
    if (_emptyDataWhenStoped) {
        pthread_mutex_lock(&_data_mutex);
        [_dataArr removeAllObjects];
        _hasData = NO;
        pthread_mutex_unlock(&_data_mutex);
    }
}

- (void)presentText:(NSString *)text attrs:(FXTextAttrs)attrs trackIndex:(NSUInteger)index {
    
    CGSize size = [text sizeWithAttributes:attrs];
    CGPoint point = [self startPointWithIndex:index];
    NSUInteger velocity = [self randomVelocity];
    
    CGFloat animDuration = [self animateDurationOfVelocity:velocity carrierWidth:size.width];
    CGFloat resetTime = [self resetTrackTimeOfVelocity:velocity carrierWidth:size.width];
    
    CGRect fromFrame = CGRectMake(point.x, point.y, size.width, self.trackHeight);
    CGRect toFrame = fromFrame;
    toFrame.origin.x = -toFrame.size.width;
    
    NSAttributedString *attrText = [[NSAttributedString alloc] initWithString:text attributes:attrs];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // label as data carrier
        UILabel *label = [[UILabel alloc] initWithFrame:fromFrame];
        label.attributedText = attrText;
        [self addSubview:label];
        
        [UIView animateWithDuration:animDuration
                              delay:0
                            options:UIViewAnimationOptionCurveLinear
                         animations:
         ^{
             label.frame = toFrame;
             [label layoutIfNeeded];
         } completion:^(BOOL finished) {
             [label removeFromSuperview];
         }];
    });
    
    // reset track
    @WeakObj(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, resetTime * NSEC_PER_SEC), self.trackProducerQueue, ^(void){
        @StrongObj(self);
        [self removeOccupiedTrackAtIndex:index];
    });
}

- (void)presentCustomView:(UIView *)customView trackIndex:(NSUInteger)index {
    //TODO: Add support for customView
}

@end
