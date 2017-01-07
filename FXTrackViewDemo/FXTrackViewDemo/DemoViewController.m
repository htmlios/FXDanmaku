//
//  ViewController.m
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 16/3/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import "DemoViewController.h"
#import "FXTrackView.h"
#import "FXTrackViewHeader.h"
#import "NSObject+FXAlertView.h"
#import "FXDeallocMonitor.h"

#define CurrentDevice [UIDevice currentDevice]
#define CurrentOrientation [[UIDevice currentDevice] orientation]
#define ScreenScale [UIScreen mainScreen].scale
#define NotificationCetner [NSNotificationCenter defaultCenter]

@interface DemoViewController ()

@property (weak, nonatomic) IBOutlet FXTrackView *trackView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *dataTypeSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *prioritySegment;
@property (assign, nonatomic) UIInterfaceOrientationMask supportOrientation;

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _supportOrientation = UIInterfaceOrientationMaskPortrait;
    [self setupTrackView];
}

- (void)dealloc {
    [NotificationCenter removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupObserver {
    
    [NotificationCetner addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    [NotificationCetner addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
}

#pragma mark - Views

- (void)setupTrackView {
    
    _trackView.emptyDataWhenPaused = NO;
    _trackView.cleanScreenWhenPaused = YES;
}

- (UIButton *)customViewWithTitle:(NSString *)title imageName:(NSString *)name {
    
    UIImage *image = nil;
    if (title.length && (image = [UIImage imageNamed:name])) {
//        UITableViewCell UITableView
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [button setAttributedTitle:[self attrbutedTextOfCustomView:title] forState:UIControlStateNormal];
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(userClickedCustomBt:) forControlEvents:UIControlEventTouchUpInside];
        [button.imageView setContentMode:UIViewContentModeScaleAspectFit];
        button.layer.borderWidth = 1.0/ScreenScale;
        button.layer.borderColor = [UIColor whiteColor].CGColor;
        
        button.imageEdgeInsets = UIEdgeInsetsMake(0, -12, 0, 0);
        return button;
    }
    return nil;
}

- (void)userClickedCustomBt:(id)sender {
    
    NSLog(@"You just clicked: %@", sender);
}

- (NSAttributedString *)attrbutedTextOfCustomView:(NSString *)text {
    
    static NSDictionary *attrs;
    if (!attrs) {
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowColor = [UIColor blackColor];
        shadow.shadowOffset = CGSizeMake(1, 1);
        attrs = @{
                  NSFontAttributeName: [UIFont systemFontOfSize:24],
                  NSForegroundColorAttributeName: [UIColor whiteColor],
                  NSShadowAttributeName: shadow
                  };
    }
    
    return [[NSAttributedString alloc] initWithString:text attributes:attrs];
}

- (NSDictionary *)normalPriorityAttributes {
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowOffset = CGSizeMake(1, 1);
    return @{
             NSFontAttributeName: [UIFont systemFontOfSize:24 weight:UIFontWeightLight],
             NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.95],
             NSShadowAttributeName: shadow
             };
}

- (NSDictionary *)highPriorityAttributes {
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowOffset = CGSizeMake(1, 1);
    return @{
             NSFontAttributeName: [UIFont boldSystemFontOfSize:24],
             NSForegroundColorAttributeName: [UIColor yellowColor],
             NSShadowAttributeName: shadow
             };
}

#pragma mark - Foreground & Background

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    
    // resume trackView
    [_trackView start];
}

- (void)applicationWillResignActive:(NSNotification*)notification {
    
    [_trackView pause];
    // if you didn't set cleanScreenWhenPaused true, then you have to call this method below
//    [_trackView cleanScreen];
}

#pragma mark - Device Orientation

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return _supportOrientation;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [_trackView pause];
    // if you didn't set cleanScreenWhenPaused true, then you have to call method below
//    [_trackView cleanScreen];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    // call 'frameDidChange' method to recalculate the num of tracks and height of each track when trackview's frame changed
    [_trackView frameDidChange];
    [_trackView start];
}

#pragma mark - Actions

- (IBAction)userDidChangeOrientationSeg:(UISegmentedControl *)sender {
    
    if ([sender respondsToSelector:@selector(selectedSegmentIndex)]) {
        
        UIInterfaceOrientation changeToOrientation = 0;
        NSInteger index = sender.selectedSegmentIndex;
        switch (index) {
            case 0:
            {
                if (!UIDeviceOrientationIsPortrait(CurrentOrientation)) {
                    _supportOrientation = UIInterfaceOrientationMaskPortrait;
                    changeToOrientation = UIInterfaceOrientationPortrait;
                }
            }
                break;
            case 1:
            {
                if (UIInterfaceOrientationLandscapeLeft != CurrentOrientation) {
                    _supportOrientation = UIInterfaceOrientationMaskLandscapeLeft;
                    changeToOrientation = UIInterfaceOrientationLandscapeLeft;
                }
            }
                break;
            case 2:
            {
                if (UIInterfaceOrientationLandscapeRight != CurrentOrientation) {
                    _supportOrientation = UIInterfaceOrientationMaskLandscapeRight;
                    changeToOrientation = UIInterfaceOrientationLandscapeRight;
                }
            }
                break;
            default:
                break;
        }
        
        if (changeToOrientation) {
            [CurrentDevice setValue:@(changeToOrientation) forKey:@"orientation"];
        }
    }
}

- (IBAction)addFiveData:(id)sender {
    
    [self addNumOfData:5];
}

- (IBAction)addTenData:(UIButton *)sender {

    [self addNumOfData:10];
}
- (IBAction)addThirtyData:(id)sender {
    
    [self addNumOfData:30];
}

- (void)addNumOfData:(NSUInteger)num {
    
    static NSUInteger i = 0;
    NSUInteger j = 0;
    
    while (j++ < num) {
        
        NSString *text = [NSString stringWithFormat:@"num: %@", @(i++)];
        // FXDataPriority default value is FXDataPriorityNormal
        BOOL isHighPriority = _prioritySegment.selectedSegmentIndex;
        BOOL dataIsText = !_dataTypeSegment.selectedSegmentIndex;
//        if (dataIsText) {
//            // set up reused NSStringAttributes
//            if (!_trackView.highPriorityTextAttrs) {
//                _trackView.highPriorityTextAttrs = [self highPriorityAttributes];
//            }
//            if (!_trackView.normalPriorityTextAttrs) {
//                _trackView.normalPriorityTextAttrs = [self normalPriorityAttributes];
//            }
//            [_trackView addData:@{
//                                  FXDataTextKey: text,
//                                  FXDataPriorityKey: isHighPriority ? @(FXDataPriorityHigh) : @(FXDataPriorityNormal)
//                                  }];
//        }
//        else {
//            NSString *imageName = [NSString stringWithFormat:@"avatar%@", @(arc4random()%6+1)];
//            UIButton *button = [self customViewWithTitle:text imageName:imageName];
//            if (button) {
//                [_trackView addData:@{
//                                      FXDataCustomViewKey: button,
//                                      FXDataPriorityKey: isHighPriority?@(FXDataPriorityHigh):@(FXDataPriorityNormal)
//                                      }];
//            }
//        }
    }
}

- (IBAction)start:(id)sender {
    [_trackView start];
}

- (IBAction)pause:(id)sender {
    [_trackView pause];
}


- (IBAction)stop:(id)sender {
    [_trackView stop];
}

@end
