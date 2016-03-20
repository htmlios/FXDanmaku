//
//  ViewController.m
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 16/3/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import "ViewController.h"
#import "FXTrackView.h"
#import <pthread.h>
#import "FXTrackViewHeader.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet FXTrackView *trackView;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) CGRect oldFrame;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _trackView.removeFromSuperViewWhenStoped = YES;
    _trackView.emptyDataWhenPaused = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)pause:(id)sender {
    
    [_trackView pause];
}

- (IBAction)resume:(id)sender {
    
    [_trackView resume];
}

- (IBAction)stop:(id)sender {
    
    if (CGRectIsEmpty(_oldFrame)) {
        self.oldFrame = _trackView.frame;
    }
    [_trackView stop];
}

@end
