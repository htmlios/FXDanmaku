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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Views

- (void)setupTrackView {
    _trackView.randomTrack = NO;
    _trackView.emptyDataWhenPaused = NO;
    _trackView.cleanScreenWhenPaused = YES;
}

- (UIButton *)customButtonWithTitle:(NSString *)title imageName:(NSString *)name {
    
    UIImage *image = nil;
    if (title.length && (image = [UIImage imageNamed:name])) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [button setAttributedTitle:[self attrbutedText:title] forState:UIControlStateNormal];
        [button setImage:image forState:UIControlStateNormal];
        [button.imageView setContentMode:UIViewContentModeScaleAspectFit];
        button.layer.borderWidth = 1.0/ScreenScale;
        button.layer.borderColor = [UIColor redColor].CGColor;
        
        button.imageEdgeInsets = UIEdgeInsetsMake(0, -12, 0, 0);
        [button addTarget:self action:@selector(userClickedCustomView:) forControlEvents:UIControlEventTouchUpInside];
        return button;
    }
    return nil;
}

- (NSAttributedString *)attrbutedText:(NSString *)text {
    
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

- (void)userClickedCustomView:(id)sender {
    
    UIButton *bt = sender;
    if ([bt isKindOfClass:[UIButton class]]) {
        
        [self presentConfirmViewWithTitle:@"Wow"
                                  message:bt.currentTitle
                       confirmButtonTitle:nil
                        cancelButtonTitle:@"ok"
                           confirmHandler:nil
                            cancelHandler:nil];
    }
}

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

    
    static int i = 0;
    int j = 0;
    while (j++ < 10) {
        //            [_trackView addData:@{
        //                                  FXDataTextKey: time
        //                                  }];
        
        NSString *imageName = [NSString stringWithFormat:@"avatar%@", @(arc4random()%6+1)];
        UIButton *button = [self customButtonWithTitle:[NSString stringWithFormat:@"num: %@", @(i++)] imageName:imageName];
        if (button) {
            [_trackView addData:@{
                                  FXDataCustomViewKey: button
                                  }];
        }
    }
    
//    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
//    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC, 0);
//    @WeakObj(self);
//    dispatch_source_set_event_handler(timer, ^{
//        @StrongObj(self);
//        if (self) {
//            NSString *time = [NSString stringWithFormat:@"%.6lf", [NSDate new].timeIntervalSince1970];
//            //            [_trackView addData:@{
//            //                                  FXDataTextKey: time
//            //                                  }];
//            
//            NSString *imageName = [NSString stringWithFormat:@"avatar%@", @(arc4random()%6+1)];
//            
//            UIButton *button = [self customViewWithTitle:time imageName:imageName];
//            if (button) {
//                [_trackView addData:@{
//                                      FXDataCustomViewKey: button
//                                      }];
//            }
//        }
//        else {
//            dispatch_source_cancel(timer);
//        }
//    });
//    dispatch_resume(timer);
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
