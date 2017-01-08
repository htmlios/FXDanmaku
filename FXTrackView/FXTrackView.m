//
//  FXTrackView.m
//
//
//  Created by ShawnFoo on 12/4/15.
//  Copyright © 2015 ShawnFoo. All rights reserved.
//

#import "FXTrackView.h"
#import <pthread.h>
#import "FXTrackViewHeader.h"
#import "FXDeallocMonitor.h"
#import "FXReusableObjectQueue.h"
#import "FXTrackViewItem.h"
#import "FXSingleRowItemsManager.h"
#import "FXTrackViewItem+DataBind.h"

typedef NS_ENUM(NSUInteger, TrackViewStatus) {
    StatusNotStarted,
    StatusRunning,
    StatusPaused,
    StatusStoped
};

static inline BOOL FXCGSizeNotZero(CGSize size) {
    return 0 != size.width && 0 != size.height;
}

@interface FXTrackView ()

@property (nonatomic, assign) TrackViewStatus status;
@property (nonatomic, assign) BOOL hasUnoccupiedRows;
@property (nonatomic, assign) BOOL hasData;

@property (nonatomic, assign) BOOL hasCalculatedRows;
@property (nonatomic, assign) CGSize oldSize;

@property (nonatomic, assign) NSInteger numOfRows;
@property (nonatomic, assign) CGFloat rowHeight;

@property (nonatomic, strong) NSMutableArray<FXTrackViewData *> *dataQueue;
@property (nonatomic, strong) FXReusableObjectQueue *reuseItemQueue;

@property (nonatomic, strong) dispatch_queue_t consumerQueue;
@property (nonatomic, strong) dispatch_queue_t trackProducerQueue;
@property (nonatomic, strong) dispatch_queue_t dataProducerQueue;

@property (nonatomic, assign) NSUInteger occupiedRowMaskBit;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, FXSingleRowItemsManager *> *rowItemsManager;

@property (nonatomic, readonly) BOOL shouldAcceptData;

@end

@implementation FXTrackView {
    pthread_mutex_t _track_mutex;
    pthread_cond_t _track_prod, _track_cons;
    pthread_mutex_t _data_mutex;
    pthread_cond_t _data_prod, _data_cons;
}

#pragma mark - Accessor

#pragma mark Lazy Loading

- (FXTrackViewConfiguration *)configuration {
    if (!_configuration) {
        _configuration = [FXTrackViewConfiguration defaultConfiguration];
    }
    return _configuration;
}

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

- (NSMutableArray<FXTrackViewData *> *)dataQueue {
    if (!_dataQueue) {
        _dataQueue = [NSMutableArray array];
    }
    return _dataQueue;
}

- (FXReusableObjectQueue *)reuseItemQueue {
    if (!_reuseItemQueue) {
        _reuseItemQueue = [FXReusableObjectQueue queue];
    }
    return _reuseItemQueue;
}

- (NSMutableDictionary<NSNumber *, FXSingleRowItemsManager *> *)rowItemsManager {
    if (!_rowItemsManager) {
        _rowItemsManager = [NSMutableDictionary dictionaryWithCapacity:_numOfRows];
    }
    return _rowItemsManager;
}

#pragma mark Shortcut Accessory
- (FXSingleRowItemsManager *)rowItemsManagerAtRow:(NSUInteger)row {
    
    FXSingleRowItemsManager *manager = self.rowItemsManager[@(row)];
    if (!manager) {
        manager = [[FXSingleRowItemsManager alloc] init];
        self.rowItemsManager[@(row)] = manager;
    }
    return manager;
}

#pragma mark Computed Property

- (BOOL)isRunning {
    return StatusRunning == _status;
}

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

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonSetup];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!self.hasCalculatedRows || !CGSizeEqualToSize(self.oldSize, self.frame.size)) {
        self.oldSize = self.frame.size;
        self.hasCalculatedRows = YES;
        [self cleanScreen];
        [self calculatRowsAndRowHeight];
    }
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    
    if (StatusStoped != self.status) {
        LogD(@"Better call 'stop' method before removing trackView from its superview!");
        [self stop];
    }
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

- (void)commonSetup {
    
    // setup default value
    _status = StatusNotStarted;
    _cleanScreenWhenPaused = NO;
    _emptyDataWhenPaused = NO;
    _acceptDataWhenPaused = YES;
    _hasCalculatedRows = NO;
    
    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = YES;
    
    pthread_mutex_init(&_track_mutex, NULL);
    pthread_cond_init(&_track_prod, NULL);
    pthread_cond_init(&_track_cons, NULL);
    
    pthread_mutex_init(&_data_mutex, NULL);
    pthread_cond_init(&_data_prod, NULL);
    pthread_cond_init(&_data_cons, NULL);
    
    [FXDeallocMonitor addMonitorToObj:self];
}

- (void)calculatRowsAndRowHeight {
    
    if (StatusRunning != self.status) {
        CGFloat viewHeight = self.frame.size.height;
        CGFloat estimatedRowHeight = self.configuration.estimatedRowHeight;
        CGFloat rowVerticalSpace = self.configuration.rowVerticalSpace;
        // viewHeight = rows * estimatedRowHeight + (rows-1) * rowVerticalSpace
        self.numOfRows = floor((viewHeight+rowVerticalSpace) / (estimatedRowHeight+rowVerticalSpace));
        self.rowHeight = (viewHeight - (self.numOfRows-1)*rowVerticalSpace) / self.numOfRows;
    }
}

- (void)frameDidChange {
    if (StatusRunning != self.status) {
        [self calculatRowsAndRowHeight];
    }
    else {
        LogD(@"Please pause or stop trackView before calling 'frameDidChange' method");
    }
}

#pragma mark - Register

- (void)registerNib:(UINib *)nib forItemReuseIdentifier:(NSString *)identifier {
    if (identifier) {
        [self.reuseItemQueue registerNib:nib forObjectReuseIdentifier:identifier];
    }
}

- (void)registerClass:(Class)itemClass forItemReuseIdentifier:(NSString *)identifier {
    if (identifier) {
        [self.reuseItemQueue registerClass:itemClass forObjectReuseIdentifier:identifier];
    }
}

#pragma mark - Data Input

- (void)addData:(FXTrackViewData *)data {
    
    if (!self.shouldAcceptData) {
        return;
    }
    dispatch_async(self.dataProducerQueue, ^{
        pthread_mutex_lock(&_data_mutex);
        if ([data isKindOfClass:[FXTrackViewData class]]) {
            [self insertData:data];
            if (!self.hasData) {
                self.hasData = YES;
                if (StatusRunning == self.status) {
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
        for (FXTrackViewData *data in dataArr) {
            if ([data isKindOfClass:[FXTrackViewData class]]) {
                [self insertData:data];
                addedData = YES;
            }
        }
        if (!self.hasData && addedData) {
            self.hasData = YES;
            if (StatusRunning == self.status) {
                pthread_cond_signal(&_data_cons);
            }
        }
        pthread_mutex_unlock(&_data_mutex);
    });
}

#pragma mark - Actions

- (void)start {
    RunBlock_Safe_MainThread(^{
        if (StatusRunning != self.status && FXCGSizeNotZero(self.frame.size)) {
            self.status = StatusRunning;
            [self startConsuming];
        }
    });
}

- (void)pause {
    RunBlock_Safe_MainThread(^{
        if (StatusRunning == self.status) {
            self.status = StatusPaused;
            [self breakConsumerSuspensionIfNeeded];
        }
    });
}

- (void)stop {
    RunBlock_Safe_MainThread(^{
        if (StatusStoped != self.status) {
            self.status = StatusStoped;
            [self breakConsumerSuspensionIfNeeded];
        }
    });
}

- (void)startConsuming {
    dispatch_async(self.consumerQueue, ^{
        [self consumeData];
    });
}

- (void)breakConsumerSuspensionIfNeeded {
    
    // Break the the suspension of consumer thread! Otherwise, self can't be released! Memory leaks!
    if (!self.hasUnoccupiedRows) {
        pthread_mutex_lock(&_track_mutex);
        self.hasUnoccupiedRows = YES;
        pthread_cond_signal(&_track_cons);
        pthread_mutex_unlock(&_track_mutex);
    }
    if (!self.hasData) {
        pthread_mutex_lock(&_data_mutex);
        self.hasData = YES;
        pthread_cond_signal(&_data_cons);
        pthread_mutex_unlock(&_data_mutex);
    }
}

- (void)cleanScreen {
    
    for (UIView *subView in self.subviews) {
        if ([subView isKindOfClass:[FXTrackViewItem class]]) {
            [subView removeFromSuperview];
            [self.reuseItemQueue enqueueReusableObject:(id<FXReusableObject>)subView];
        }
    }
    dispatch_async(self.trackProducerQueue, ^{
        [self resetOccupiedTrackRows];
    });
}

#pragma mark - Data Producer & Consumer

- (FXTrackViewData *)fetchData {
    
    pthread_mutex_lock(&_data_mutex);
    while (!self.hasData) {// waiting for producer to signal consumer
        pthread_cond_wait(&_data_cons, &_data_mutex);
    }
    FXTrackViewData *data = nil;
    if (StatusRunning == self.status) {
        data = self->_dataQueue.firstObject;
        if (data) {
            [self->_dataQueue removeObjectAtIndex:0];
        }
        self.hasData = self->_dataQueue.count > 0;
    }
    pthread_mutex_unlock(&_data_mutex);
    return data;
}

- (void)insertData:(FXTrackViewData *)data {
    
    if (FXDataPriorityHigh == data.priority) {
        [self.dataQueue insertObject:data atIndex:0];
    }
    else {
        [self.dataQueue addObject:data];
    }
}

- (void)emptyDataQueue {
    
    pthread_mutex_lock(&_data_mutex);
    [self->_dataQueue removeAllObjects];
    self.hasData = NO;
    pthread_mutex_unlock(&_data_mutex);
}

#pragma mark - Track Producer & Consumer

- (NSInteger)fetchUnoccupiedTrackRow {
    NSInteger row;
    switch (self.configuration.itemInsertOrder) {
        case FXTrackItemInsertOrderRandom:
            row = [self fetchRandomUnoccupiedTrackRow];
            break;
        case FXTrackItemInsertOrderFromBottom:
            row = [self fetchOrderedUnoccupiedTrackRowFromBottom];
            break;
        default:
            row = [self fetchOrderedUnoccupiedTrackRowFromTop];
            break;
    }
    return row;
}

- (NSInteger)fetchRandomUnoccupiedTrackRow {
    
    pthread_mutex_lock(&_track_mutex);
    while (!self.hasUnoccupiedRows) {
        pthread_cond_wait(&_track_cons, &_track_mutex);
    }
    
    NSInteger row = -1;
    if (StatusRunning == self.status) {
        UInt8 *array = NULL;
        int n = 0;
        for (int i = 0; i < self.numOfRows; i++) {
            if (1<<i & self.occupiedRowMaskBit) {
                continue;
            }
            if (!array) {
                array = malloc(sizeof(UInt8)*(self.numOfRows-i));
            }
            array[n++] = i;
        }
        if (array) {
            row = array[arc4random()%n];
            [self setOccupiedTrackAtRow:row];
            self.hasUnoccupiedRows = n > 1 ? YES : NO;
            free(array);
        }
        else {
            self.hasUnoccupiedRows = NO;
        }
    }
    
    pthread_mutex_unlock(&_track_mutex);
    return row;
}

- (NSInteger)fetchOrderedUnoccupiedTrackRowFromBottom {
    
    pthread_mutex_lock(&_track_mutex);
    while (!self.hasUnoccupiedRows) {
        pthread_cond_wait(&_track_cons, &_track_mutex);
    }
    NSInteger row = -1;
    if (StatusRunning == self.status) {
        BOOL hasRows = NO;
        for (NSInteger i = self.numOfRows-1; i > -1; i--) {
            if (1<<i & self.occupiedRowMaskBit) {
                continue;
            }
            else if (-1 == row) {
                row = i;
            }
            else {
                hasRows = YES;
                break;
            }
        }
        if (row > -1) {
            [self setOccupiedTrackAtRow:row];
        }
        self.hasUnoccupiedRows = hasRows;
    }
    
    pthread_mutex_unlock(&_track_mutex);
    return row;
}

- (NSInteger)fetchOrderedUnoccupiedTrackRowFromTop {
    
    pthread_mutex_lock(&_track_mutex);
    while (!self.hasUnoccupiedRows) {
        pthread_cond_wait(&_track_cons, &_track_mutex);
    }
    
    NSInteger row = -1;
    if (StatusRunning == self.status) {
        BOOL hasRows = NO;
        for (int i = 0; i < self.numOfRows; i++) {
            if (1<<i & self.occupiedRowMaskBit) {
                continue;
            }
            else if (-1 == row) {
                row = i;
            }
            else {
                hasRows = YES;
            }
        }
        if (row > -1) {
            [self setOccupiedTrackAtRow:row];
        }
        self.hasUnoccupiedRows = hasRows;
    }
    
    pthread_mutex_unlock(&_track_mutex);
    return row;
}

- (void)setOccupiedTrackAtRow:(NSInteger)row {
    if (row < self.numOfRows) {
        self.occupiedRowMaskBit |= 1<<row;
    }
}

- (void)removeOccupiedTrackAtRow:(NSInteger)row {
    
    pthread_mutex_lock(&_track_mutex);
    if ((row < self.numOfRows)
        && (1<<row & self.occupiedRowMaskBit))
    {
        self.occupiedRowMaskBit -= 1<<row;
        if (!self.hasUnoccupiedRows) {
            self.hasUnoccupiedRows = YES;
            pthread_cond_signal(&_track_cons);
        }
    }
    pthread_mutex_unlock(&_track_mutex);
}

- (void)resetOccupiedTrackRows {
    
    pthread_mutex_lock(&_track_mutex);
    self.occupiedRowMaskBit = 0;
    self.hasUnoccupiedRows = self.numOfRows > 0;
    pthread_mutex_unlock(&_track_mutex);
}

#pragma mark - Animation Computation

- (NSUInteger)randomVelocity {
    NSUInteger minVel = self.configuration.itemMinVelocity;
    NSUInteger maxVel = self.configuration.itemMaxVelocity;
    if (minVel == maxVel) {
        return minVel;
    }
    return arc4random()%(maxVel-minVel) + minVel;
}

- (NSTimeInterval)animateDurationOfVelocity:(NSUInteger)velocity itemWidth:(CGFloat)width {
    return (self.frame.size.width + width) / velocity;
}

- (CGPoint)startPointWithRow:(NSUInteger)row {
    CGFloat yAxis = !row ? 0 : row * (self.rowHeight+self.configuration.rowVerticalSpace);
    return CGPointMake(self.frame.size.width, yAxis);
}

#pragma mark - Item Presentation

- (void)consumeData {
    
    while (StatusRunning == self.status) {
        FXTrackViewData *data = [self fetchData];
        if (data) {
            NSInteger unoccupiedRow = [self fetchUnoccupiedTrackRow];
            if (unoccupiedRow > -1) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self presentData:data atRow:unoccupiedRow];
                });
            }
            else if (StatusPaused == self.status && !self.emptyDataWhenPaused) {
                data.priority = FXDataPriorityHigh;
                [self addData:data];
            }
        }
    }
    LogD(@"stopConsuming");
    [self stopConsumingData];
}

- (void)stopConsumingData {
    
    BOOL emptyData = NO;
    BOOL cleanScreen = NO;
    
    if (StatusStoped == self.status) {
        emptyData = YES;
        cleanScreen = YES;
    }
    else if (StatusPaused == self.status) {
        emptyData = self.emptyDataWhenPaused;
        cleanScreen = self.cleanScreenWhenPaused;
    }
    
    if (emptyData) {
        dispatch_sync(self.dataProducerQueue, ^{
            [self emptyDataQueue];
        });
    }
    
    if (cleanScreen) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self cleanScreen];
        });
    }
}

- (void)presentData:(FXTrackViewData *)data atRow:(NSUInteger)row {
    
    FXTrackViewItem *item = (FXTrackViewItem *)[self.reuseItemQueue dequeueReusableObjectWithIdentifier:data.itemReuseIdentifier];
    if (![item isKindOfClass:[FXTrackViewItem class]]) {
        LogD(@"Item(%@) is not kind of class FXTrackViewItem!", data.itemReuseIdentifier);
        return;
    }
    item.fx_data = data;
    [item itemWillBeDisplayedWithData:data];
    [item layoutIfNeeded];
    
    CGSize itemSize = [item systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGPoint point = [self startPointWithRow:row];
    NSUInteger velocity = [self randomVelocity];
    NSTimeInterval animDuration = [self animateDurationOfVelocity:velocity itemWidth:itemSize.width];
    
    item.frame = CGRectMake(point.x, point.y , itemSize.width, self.rowHeight);
    CGRect toFrame = item.frame;
    toFrame.origin.x = -itemSize.width;
    
    [self addSubview:item];
    [self.rowItemsManager[@(row)] addTrackViewItem:item];
    
    [UIView animateWithDuration:animDuration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^
     {
         item.frame = toFrame;
         [self layoutIfNeeded];
     }
                     completion:^(BOOL finished)
     {
         [item removeFromSuperview];
         item.fx_data = nil;
         [self.reuseItemQueue enqueueReusableObject:(id<FXReusableObject>)item];
         
         dispatch_async(self.trackProducerQueue, ^{
             [self removeOccupiedTrackAtRow:row];
         });
     }];
}

#pragma mark - Event Dispatch

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (![self shouldHandleTouch:touches.anyObject]) {
        [super touchesBegan:touches withEvent:event];
    }
}

- (BOOL)shouldHandleTouch:(UITouch *)touch {
    
    CGPoint touchPoint = [touch locationInView:self];
    NSUInteger row = touchPoint.y / (self.rowHeight+self.configuration.rowVerticalSpace);
    FXSingleRowItemsManager *manager = self->_rowItemsManager[@(row)];
    FXTrackViewItem *item = [manager itemAtPoint:touchPoint];
    if (item) {
        id<FXTrackViewDelegate> strongDelegate = self.delegate;
        if ([strongDelegate respondsToSelector:@selector(trackView:didClickItem:withData:)]) {
            [strongDelegate trackView:self didClickItem:item withData:item.fx_data];
            return YES;
        }
    }
    return NO;
}

@end
