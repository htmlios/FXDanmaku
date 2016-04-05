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
    StatusPaused,
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

@property (assign, nonatomic) BOOL hasCalcTracks;
@property (assign, nonatomic) NSInteger numOfTracks;

@property (assign, nonatomic) CGRect trackViewFrame;
@property (assign, nonatomic) CGFloat trackHeight;
@property (strong, nonatomic) NSMutableArray *dataQueue;

@property (strong, nonatomic) dispatch_queue_t consumerQueue;
@property (strong, nonatomic) dispatch_queue_t trackProducerQueue;
@property (strong, nonatomic) dispatch_queue_t dataProducerQueue;
@property (strong, nonatomic) dispatch_queue_t computationQueue;

@property (strong, nonatomic) NSMutableArray *dispatchSourceTimers;

@property (strong, nonatomic) FXTextAttrs defaultAttrs;

@property (assign, nonatomic) NSUInteger occupiedTrackMaskBit;

@property (assign, readonly, nonatomic) BOOL shouldAcceptData;

@end

@implementation FXTrackView

#pragma mark - Setter & Getter

#pragma mark Setter

- (void)setMaxVelocity:(NSUInteger)maxVelocity {
    
    if (maxVelocity >= _minVelocity) {
        _maxVelocity = maxVelocity;
    }
    else { LogD(@"MaxVelocity can't be slower than minVelocity!😪"); }
}

#pragma mark Lazy Loading Getter

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

- (NSMutableArray *)dataQueue {

    if (!_dataQueue) {
        _dataQueue = [NSMutableArray arrayWithCapacity:15];
    }
    return _dataQueue;
}

- (NSMutableArray *)dispatchSourceTimers {
    
    if (!_dispatchSourceTimers) {
        _dispatchSourceTimers = [NSMutableArray arrayWithCapacity:_numOfTracks];
    }
    return _dispatchSourceTimers;
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

#pragma mark Computed Property Getter

- (BOOL)shouldAcceptData {
    
    BOOL notStoped = StatusStoped != _status;
    return notStoped || (!notStoped && _acceptDataWhenPaused);
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
    
    // setup default value
    _status = StatusNotStarted;
    self.maxVelocity = !_maxVelocity ? FX_MaxVelocity : _maxVelocity;
    self.minVelocity = !_minVelocity ? FX_MinVelocity : _minVelocity;
    self.randomTrack = NO;
    self.cleanScreenWhenPaused = NO;
    self.emptyDataWhenPaused = NO;
    self.acceptDataWhenPaused = YES;
    self.removeFromSuperViewWhenStoped = YES;
    self.hasCalcTracks = NO;
    
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
    
    if (!_hasCalcTracks && CGSizeNotZero(self.frame.size)) {
        _hasCalcTracks = YES;
        [self calcTrackNumAndHeight];
    }
}

- (void)calcTrackNumAndHeight {
    
    if (StatusRunning != _status) {
        CGFloat height = self.frame.size.height;
        
        // height = numOfTrack * estimatedTrackHeight + (numOfTrack-1) * trackVerticalSpan
        // According to the formula above, you'll understand the statements below
        self.numOfTracks = floor((height+FX_TrackVSpan) / (FX_EstimatedTrackHeight+FX_TrackVSpan));
        self.trackHeight = (height - (_numOfTracks-1)*FX_TrackVSpan) / _numOfTracks;
        
        LogD(@"%@", @(_numOfTracks*_trackHeight));
        _hasTracks = _numOfTracks > 0;
    }
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    
    if (StatusStoped != _status) {
        LogD(@"You should call 'stop' method before removing trackView from its superview!");
        [self stop];
    }
}

- (void)frameDidChange {
    
    if (StatusRunning != _status) {
        [self calcTrackNumAndHeight];
    }
    else {
        LogD(@"Please pause or stop trackView before calling 'frameDidChange' method");
    }
}

#pragma mark - Actions

- (void)start {
    
    RunBlock_Safe_MainThread(^{
        if (StatusRunning != _status && CGSizeNotZero(self.frame.size)) {
            _status = StatusRunning;
            [self startConsuming];
        }
    });
}

- (void)pause {
    
    RunBlock_Safe_MainThread(^{
        
        if (StatusRunning == _status) {
            _status = StatusPaused;
            [self stopConsuming];
            if (_cleanScreenWhenPaused) {
                [self cleanScreen];
            }
        }
    });
}

- (void)stop {
    
    RunBlock_Safe_MainThread(^{
        if (StatusStoped != _status) {
            _status = StatusStoped;
            [self stopConsuming];
            [self cleanScreen];
            if (_removeFromSuperViewWhenStoped) {
                [self removeFromSuperview];
            }
        }
    });
}

- (void)startConsuming {
    
    dispatch_async(self.consumerQueue, ^{
        [self consumeData];
    });
}

- (void)stopConsuming {
    
    // Exit the consumer thread if waiting! Otherwise, self can't be released! Memory leaks!
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

- (void)cleanScreen {
    
    for (UIView *subViews in self.subviews) {
        [subViews removeFromSuperview];
    }
}

#pragma mark - Data Producer & Consumer

- (void)addData:(FXData)data {
    
    if (!self.shouldAcceptData) { return; }
    dispatch_async(self.dataProducerQueue, ^{
        pthread_mutex_lock(&_data_mutex);
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
    while (!_hasData) {// no carriers, waiting for producer to signal to consumer
        pthread_cond_wait(&_data_cons, &_data_mutex);
    }
    FXData data = nil;
    if (StatusRunning == _status) {
        data = _dataQueue.firstObject;
        if (data) {
            [_dataQueue removeObjectAtIndex:0];
        }
        _hasData = _dataQueue.count > 0;
    }
    pthread_mutex_unlock(&_data_mutex);
    return data;
}

- (BOOL)checkData:(FXData)data {
    
    NSString *text = data[FXDataTextKey];
    UIView *customView = data[FXDataCustomViewKey];
    BOOL isOk = NO;
    if ([text isKindOfClass:[NSString class]] && text.length>0) {
        isOk = YES;
        if ([data[FXTextCustomAttrsKey] isKindOfClass:[NSDictionary class]]) {
            isOk = YES;
        }
    }
    
    if ([customView isKindOfClass:[UIView class]]) {
        isOk = YES;
    }
    
    return isOk;
}

- (void)insertData:(FXData)data {
    
    NSNumber *priority = data[FXDataPriorityKey];
    if (!priority || PriorityNormal == priority.unsignedIntegerValue) {
        [self.dataQueue addObject:data];
    }
    else if (priority.unsignedIntegerValue > PriorityNormal) {
        [self.dataQueue insertObject:data atIndex:0];
    }
}

#pragma mark - Track Producer & Consumer

- (NSInteger)fetchRandomUnoccupiedTrackIndex {
    
    pthread_mutex_lock(&_track_mutex);
    while (!_hasTracks) {
        pthread_cond_wait(&_track_cons, &_track_mutex);
    }
    
    NSInteger index = -1;
    if (StatusRunning == _status) {
        
        UInt8 *array = NULL;
        int n = 0;
        for (int i = 0; i < _numOfTracks; i++) {
            if (1<<i & _occupiedTrackMaskBit) {
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
    while (!_hasTracks) {
        pthread_cond_wait(&_track_cons, &_track_mutex);
    }
    
    NSInteger index = -1;
    if (StatusRunning == _status) {
        
        BOOL hasTracks = NO;
        for (int i = 0; i < _numOfTracks; i++) {
            
            if (1<<i & _occupiedTrackMaskBit) {
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
    
    if (index < _numOfTracks) {
        self.occupiedTrackMaskBit |= 1 << index;
    }
}

- (void)removeOccupiedTrackAtIndex:(NSInteger)index {
    
    pthread_mutex_lock(&_track_mutex);
    if ((index<_numOfTracks) && (1<<index & _occupiedTrackMaskBit)) {
        self.occupiedTrackMaskBit -= 1 << index;
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
    
    if (_maxVelocity == _minVelocity) {
        return _maxVelocity;
    }
    return arc4random()%(_maxVelocity-_minVelocity) + _minVelocity;
}

// animation time
- (NSTimeInterval)animateDurationOfVelocity:(NSUInteger)velocity carrierWidth:(CGFloat)width {
    
    return (self.frame.size.width + width) / velocity;
}

// time to reset occupied track
- (NSTimeInterval)resetTrackTimeOfVelocity:(NSUInteger)velocity carrierWidth:(CGFloat)width {
    
    // totalDisplacement = resetDisplacement + carrierWidth
    return (self.frame.size.width*FX_ResetTrackOffsetRatio + width) / velocity;
}

// start point of carrier
- (CGPoint)startPointWithIndex:(NSUInteger)index {
    
    CGFloat yAxis = !index ? 0 : index*(_trackHeight+FX_TrackVSpan);
    return CGPointMake(self.frame.size.width, yAxis);
}

// check if the back carrier will collide with front one at the speed between minVelocity and maxVeloctiy
- (BOOL)willCollideWithFrontOne {
    
    // formula: ((1-FX_ResetTrackOffsetRatio)*trackViewWidth + frontCarrierWidth) / minVelocity >= trackViewWidth / maxVelocity
    // only when meeting this condition above, can make sure the back carrier won't overstep front one!
    
    return (1-FX_ResetTrackOffsetRatio) >= _minVelocity/_maxVelocity;
}

#pragma mark - Carrier Presentation

- (void)consumeData {
    
    while (StatusRunning == _status) {
        
        FXData data = [self fetchData];
        if (data) {
            NSInteger unoccupiedIndex = _randomTrack ? [self fetchRandomUnoccupiedTrackIndex] : [self fetchOrderedUnoccupiedTrackIndex];
            if (unoccupiedIndex > -1) {
                dispatch_async(self.computationQueue, ^{
                    if (data[FXDataTextKey]) {
                        FXTextAttrs attrs = data[FXTextCustomAttrsKey] ?: nil;
                        if (!attrs) {
                            NSNumber *priority = data[FXDataPriorityKey];
                            if (PriorityNormal == priority.unsignedIntegerValue) {
                                attrs = _normalPriorityTextAttrs;
                            }
                            else if (PriorityHigh == priority.unsignedIntegerValue) {
                                attrs = _highPriorityTextAttrs;
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
            else if (!_emptyDataWhenPaused) {
                // add it back if hasn't been consumed
                pthread_mutex_lock(&_data_mutex);
                [_dataQueue insertObject:data atIndex:0];
                pthread_mutex_unlock(&_data_mutex);
            }
        }
    }
    LogD(@"stopConsuming");
    [self consumptionEnding];
}

- (void)consumptionEnding {
    
    BOOL stoped = StatusStoped == _status;
    BOOL paused = StatusPaused == _status;
    
    // empty data if needed
    if (stoped || (paused&&_emptyDataWhenPaused)) {
        pthread_mutex_lock(&_data_mutex);
        [_dataQueue removeAllObjects];
        _hasData = NO;
        pthread_mutex_unlock(&_data_mutex);
    }
    
    // cancel all timers, then reset occupied tracks!
    for (dispatch_source_t timer in _dispatchSourceTimers) {
        dispatch_source_cancel(timer);
    }
    [_dispatchSourceTimers removeAllObjects];
    pthread_mutex_lock(&_track_mutex);
    self.occupiedTrackMaskBit = 0;
    _hasTracks = YES;
    pthread_mutex_unlock(&_track_mutex);
}

- (void)presentText:(NSString *)text attrs:(FXTextAttrs)attrs trackIndex:(NSUInteger)index {
    
    CGSize size = [text sizeWithAttributes:attrs];
    
    CGPoint point;
    NSUInteger velocity;
    NSTimeInterval animDuration, resetTime;
    CGRect fromFrame, toFrame;
    [self calculationWithSize:size
                   trackIndex:index
                   startPoint:&point
                     velocity:&velocity
                 animDuration:&animDuration
                    resetTime:&resetTime
                     fromRect:&fromFrame
                       toRect:&toFrame];
    
    NSAttributedString *attrText = [[NSAttributedString alloc] initWithString:text attributes:attrs];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // label as data carrier
        UILabel *label = [[UILabel alloc] initWithFrame:fromFrame];
        label.textAlignment = NSTextAlignmentCenter;
        label.attributedText = attrText;
        [self addSubview:label];
        
        [UIView animateWithDuration:animDuration
                              delay:0
                            options:UIViewAnimationOptionCurveLinear
                         animations:
         ^{
             label.frame = toFrame;
             [self layoutIfNeeded];
         } completion:^(BOOL finished) {
             [label removeFromSuperview];
         }];
    });
    
    [self resetTrackAtIndex:index inTime:resetTime];
}

- (void)presentCustomView:(UIView *)customView trackIndex:(NSUInteger)index {
    
    CGSize size = customView.frame.size;
    if (!size.width) {
        size = [customView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    }
    
    CGPoint point;
    NSUInteger velocity;
    NSTimeInterval animDuration, resetTime;
    CGRect fromFrame, toFrame;
    [self calculationWithSize:size
                   trackIndex:index
                   startPoint:&point
                     velocity:&velocity
                 animDuration:&animDuration
                    resetTime:&resetTime
                     fromRect:&fromFrame
                       toRect:&toFrame];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        customView.frame = fromFrame;
        [customView layoutIfNeeded];
        [self addSubview:customView];
        [UIView animateWithDuration:animDuration
                              delay:0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^
        {
            customView.frame = toFrame;
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
            [customView removeFromSuperview];
        }];
    });
    
    [self resetTrackAtIndex:index inTime:resetTime];
}

- (void)calculationWithSize:(CGSize)size
                 trackIndex:(NSUInteger)index
                 startPoint:(CGPoint *)point
                   velocity:(NSUInteger *)vel
               animDuration:(NSTimeInterval *)duration
                  resetTime:(NSTimeInterval*)resetTime
                   fromRect:(CGRect *)fromRect
                     toRect:(CGRect *)toRect {
    
    *point = [self startPointWithIndex:index];
    *vel = [self randomVelocity];
    *duration = [self animateDurationOfVelocity:*vel carrierWidth:size.width];
    *resetTime = [self resetTrackTimeOfVelocity:*vel carrierWidth:size.width];;
    
    *fromRect = CGRectMake(point->x, point->y , size.width, _trackHeight);
    *toRect = *fromRect;
    toRect->origin.x = -size.width;
}

- (void)resetTrackAtIndex:(NSUInteger)index inTime:(NSTimeInterval)resetTime {
    
    // create timer to reset track
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.trackProducerQueue);
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, resetTime * NSEC_PER_SEC), 0, 0);
    dispatch_source_set_event_handler(timer, ^{
        dispatch_source_cancel(timer);
        [self removeOccupiedTrackAtIndex:index];
        [self.dispatchSourceTimers removeObject:timer];
    });
    [self.dispatchSourceTimers addObject:timer];
    dispatch_resume(timer);
}

@end
