//
//  ViewController.m
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 16/3/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import "MultiRowsVC.h"
#import "FXDanmaku.h"
#import "NSObject+FXAlertView.h"
#import "DemoDanmakuItemAData.h"
#import "DemoDanmakuItemA.h"

#define CurrentDevice [UIDevice currentDevice]
#define CurrentOrientation [[UIDevice currentDevice] orientation]
#define ScreenScale [UIScreen mainScreen].scale
#define NotificationCetner [NSNotificationCenter defaultCenter]

@interface MultiRowsVC () <FXDanmakuDelegate>

@property (weak, nonatomic) IBOutlet FXDanmaku *danmaku;

@end

@implementation MultiRowsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupDanmaku];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Device Orientation
- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Views
- (void)setupDanmaku {
    self.danmaku.configuration = [FXDanmakuConfiguration defaultConfiguration];
    self.danmaku.delegate = self;
    [self.danmaku registerNib:[UINib nibWithNibName:NSStringFromClass([DemoDanmakuItemA class]) bundle:nil]
       forItemReuseIdentifier:[DemoDanmakuItemA reuseIdentifier]];
}

#pragma mark - Observer
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

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self.danmaku start];
}

- (void)applicationWillResignActive:(NSNotification*)notification {
    [self.danmaku pause];
}

#pragma mark - Actions
- (IBAction)segmentValueChanged:(UISegmentedControl *)sender {
    
    // this is a copy FXDanmakuConfiguration object below!
    FXDanmakuConfiguration *config = self.danmaku.configuration;
    // update/change config's property
    config.itemInsertOrder = sender.selectedSegmentIndex;
    // set it back to let danmku refresh
    self.danmaku.configuration = config;
}

- (IBAction)addOneData:(id)sender {
    [self addDatasWithCount:1];
}

- (IBAction)addFiveData:(UIButton *)sender {
    [self addDatasWithCount:5];
}

- (IBAction)addTwentyFiveData:(id)sender {
    [self addDatasWithCount:25];
}

- (IBAction)start:(id)sender {
    [self.danmaku start];
}

- (IBAction)pause:(id)sender {
    [self.danmaku pause];
}

- (IBAction)stop:(id)sender {
    [self.danmaku stop];
}

#pragma mark - FXDanmakuDelegate
- (void)danmaku:(FXDanmaku *)danmaku didClickItem:(FXDanmakuItem *)item withData:(DemoDanmakuItemAData *)data {
    [self presentConfirmViewWithTitle:nil
                              message:[NSString stringWithFormat:@"You click %@", data.desc]
                   confirmButtonTitle:nil
                    cancelButtonTitle:@"Ok"
                       confirmHandler:nil
                        cancelHandler:nil];
}

#pragma mark - DataSource 
- (void)addDatasWithCount:(NSUInteger)count {
    static NSUInteger index = 0;
    for (NSUInteger i = 0; i < count; i++) {
        DemoDanmakuItemAData *data = [DemoDanmakuItemAData data];
        data.avatarName = [NSString stringWithFormat:@"avatar%d", arc4random()%6];
        data.desc = [NSString stringWithFormat:@"DanmakuItem-%@", @(index++)];
        [self.danmaku addData:data];
    }
    /*
        if (!self.danmaku.isRunning) {
            [self.danmaku start];
        }
     */
}

@end
