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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(addCarrier) userInfo:nil repeats:YES];
    [_trackView start];
}

- (void)addCarrier {

    NSString *time = [NSString stringWithFormat:@"%@", [NSDate new]];
    if (arc4random()%2) {
        [_trackView addUserWords:time];
    }
    else {
        [_trackView addAnchorWords:time];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
