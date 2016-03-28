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

#define CurrentDevice [UIDevice currentDevice]
#define CurrentOrientation [[UIDevice currentDevice] orientation]

@interface DemoViewController ()

@property (weak, nonatomic) IBOutlet FXTrackView *trackView;
@property (assign, nonatomic) UIInterfaceOrientationMask supportOrientation;
@property (assign, nonatomic) CGRect oldFrame;

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    _supportOrientation = UIInterfaceOrientationMaskPortrait;
    [self setupTrackView];
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC, 0);
    @WeakObj(self);
    dispatch_source_set_event_handler(timer, ^{
        @StrongObj(self);
        if (self) {
            NSString *time = [NSString stringWithFormat:@"%.6lf", [NSDate new].timeIntervalSince1970];
            [_trackView addData:@{
                                  FXDataTextKey: time
                                  }];
        }
        else {
            dispatch_source_cancel(timer);
        }
    });
    dispatch_resume(timer);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupTrackView {
    _trackView.randomTrack = NO;
    _trackView.emptyDataWhenPaused = NO;
    _trackView.cleanScreenWhenPaused = YES;
}

#pragma mark - Foreground & Background



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


- (IBAction)add_10:(id)sender {

    int i = 0;
    while (i++ < 50) {
        NSString *time = [NSString stringWithFormat:@"%.6lf", [NSDate new].timeIntervalSince1970];
        [_trackView addData:@{
                              FXDataTextKey: time
                              }];
//        if (arc4random()%2) {
//            [_trackView addUserWords:time];
//        }
//        else {
//            [_trackView addAnchorWords:time];
//        }
    }
}

- (IBAction)start:(id)sender {

    if (!_trackView) {
        FXTrackView *trackView = [[FXTrackView alloc] initWithFrame:_oldFrame];
        [self.view addSubview:trackView];
        [trackView layoutIfNeeded];
        self.trackView = trackView;
        [self setupTrackView];
    }
    
    [_trackView start];
}

- (IBAction)pause:(id)sender {
    
    [_trackView pause];
}


- (IBAction)stop:(id)sender {
    
    if (CGRectIsEmpty(_oldFrame)) {
        self.oldFrame = _trackView.frame;
    }
    [_trackView stop];
}

@end
