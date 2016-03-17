//
//  ViewController.m
//  FXTrackViewDemo
//
//  Created by ShawnFoo on 16/3/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import "ViewController.h"
#import "FXTrackView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet FXTrackView *trackView;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) CGRect oldFrame;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//    });
//    [_trackView removeFromSuperview];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)add_10:(id)sender {

    int i = 0;
    while (i++ < 10) {
        NSString *time = [NSString stringWithFormat:@"%@", @([NSDate new].timeIntervalSince1970)];
        [_trackView addUserWords:time];
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
    [_trackView removeFromSuperview];
}

@end
