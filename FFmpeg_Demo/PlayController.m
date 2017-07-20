//
//  PlayController.m
//  FFmpeg_Demo
//
//  Created by 尚往文化 on 17/7/20.
//  Copyright © 2017年 YBing. All rights reserved.
//

#import "PlayController.h"
#import "SJMoiveObject.h"

#define LERP(A,B,C) ((A)*(1.0-C)+(B)*C)

@interface PlayController ()

@property (weak, nonatomic) IBOutlet UIImageView *ImageView;
@property (weak, nonatomic) IBOutlet UILabel *fps;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *TimerBtn;
@property (weak, nonatomic) IBOutlet UILabel *TimerLabel;
@property (nonatomic, strong) SJMoiveObject *video;
@property (nonatomic, assign) float lastFrameTime;

@end

@implementation PlayController

@synthesize ImageView, fps, playBtn, video;

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.video = [[SJMoiveObject alloc] initWithVideo:[[NSBundle mainBundle] pathForResource:@"test.mp4" ofType:nil]];
        self.video = [[SJMoiveObject alloc] initWithVideo:@"http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4"];
    //    video.outputWidth = 800;
    //    video.outputHeight = 600;
    NSLog(@"视频总时长>>>video duration: %f",video.duration);
    NSLog(@"源尺寸>>>video size: %d x %d", video.sourceWidth, video.sourceHeight);
    NSLog(@"输出尺寸>>>video size: %d x %d", video.outputWidth, video.outputHeight);
    //
    //    [self.audio seekTime:0.0];
    //    SJLog(@"%f", [self.audio duration])
    //    AVPacket *packet = [self.audio readPacket];
    //    SJLog(@"%ld", [self.audio decode])
    int tns, thh, tmm, tss;
    tns = video.duration;
    thh = tns / 3600;
    tmm = (tns % 3600) / 60;
    tss = tns % 60;
    
    
    //    NSLog(@"fps --> %.2f", video.fps);
    ////        [ImageView setTransform:CGAffineTransformMakeRotation(M_PI)];
    //    NSLog(@"%02d:%02d:%02d",thh,tmm,tss);
    
}

- (IBAction)PlayClick:(UIButton *)sender {
    
    [playBtn setEnabled:NO];
    [video replaceTheResources:@"http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4"];
    _lastFrameTime = -1;
    
    // seek to 0.0 seconds
    [video seekTime:0.0];
    
    
    [NSTimer scheduledTimerWithTimeInterval: 1 / video.fps
                                     target:self
                                   selector:@selector(displayNextFrame:)
                                   userInfo:nil
                                    repeats:YES];
}

-(void)displayNextFrame:(NSTimer *)timer {
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    //    self.TimerLabel.text = [NSString stringWithFormat:@"%f s",video.currentTime];
    self.TimerLabel.text  = [self dealTime:video.currentTime];
    if (![video stepFrame]) {
        [timer invalidate];
        [playBtn setEnabled:YES];
        return;
    }
    ImageView.image = video.currentImage;
    float frameTime = 1.0 / ([NSDate timeIntervalSinceReferenceDate] - startTime);
    if (_lastFrameTime < 0) {
        _lastFrameTime = frameTime;
    } else {
        _lastFrameTime = LERP(frameTime, _lastFrameTime, 0.8);
    }
    [fps setText:[NSString stringWithFormat:@"fps %.0f",_lastFrameTime]];
}

- (NSString *)dealTime:(double)time {
    
    int tns, thh, tmm, tss;
    tns = time;
    thh = tns / 3600;
    tmm = (tns % 3600) / 60;
    tss = tns % 60;
    
    
    // [ImageView setTransform:CGAffineTransformMakeRotation(M_PI)];
    return [NSString stringWithFormat:@"%02d:%02d:%02d",thh,tmm,tss];
}


@end
