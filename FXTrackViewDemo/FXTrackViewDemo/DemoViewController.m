//
//  ViewController.m
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 16/3/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import "DemoViewController.h"
#import "FXTrackView.h"
#import <pthread.h>
#import "FXTrackViewHeader.h"

@interface DemoViewController ()

@property (weak, nonatomic) IBOutlet FXTrackView *trackView;
@property (assign, nonatomic) UIInterfaceOrientationMask supportOrientation;
@property (assign, nonatomic) CGRect oldFrame;

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    _supportOrientation = UIInterfaceOrientationMaskAllButUpsideDown;
    _trackView.emptyDataWhenStoped = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Device Orientation

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return _supportOrientation;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
}

#pragma mark - Actions

- (IBAction)userDidChangeOrientationSeg:(UISegmentedControl *)sender {
    
    if ([sender respondsToSelector:@selector(selectedSegmentIndex)]) {
        
        UIInterfaceOrientationMask changeToMask = 0;
        NSInteger index = sender.selectedSegmentIndex;
        switch (index) {
            case 0:
                changeToMask = UIInterfaceOrientationMaskPortrait;
                break;
            case 1:
                changeToMask = UIInterfaceOrientationMaskLandscapeLeft;
                break;
            case 2:
                changeToMask = UIInterfaceOrientationMaskLandscapeRight;
                break;
            default:
                break;
        }
        
        if (changeToMask != _supportOrientation) {
            _supportOrientation = changeToMask;
            [UIViewController attemptRotationToDeviceOrientation];
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft animated:YES];
        }
    }
}


- (IBAction)add_10:(id)sender {

    int i = 0;
    while (i++ < 10) {
        NSString *time = [NSString stringWithFormat:@"%.6f", [NSDate new].timeIntervalSince1970];
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
    }
    
    [_trackView start];
}

- (IBAction)stop:(id)sender {
    
    if (CGRectIsEmpty(_oldFrame)) {
        self.oldFrame = _trackView.frame;
    }
    [_trackView stop];
}

@end
