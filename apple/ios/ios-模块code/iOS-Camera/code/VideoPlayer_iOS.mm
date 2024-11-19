#import "Log.h"
#import "Native_iOS.h"
#import "App.h"

#import <QFile>
#import <QImage>
#import <QFont>
#import <QStandardPaths>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#pragma mark - VideoPlayer
@interface VideoPlayer : UIViewController
@property (strong, nonatomic) UIView *playerView;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) UISlider *progressSlider;
@property (strong, nonatomic) id timeObserver;
@property (assign, nonatomic) BOOL isPlaying;
@property (strong, nonatomic) UIButton *playPauseButton;
@property (strong, nonatomic) UILabel *currentTimeLabel;
@property (strong, nonatomic) UILabel *durationLabel;
@property (strong, nonatomic) UIImageView *centerPlay;
@end

@implementation VideoPlayer

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)videoDidLoad:(NSURL *)videoURL {
    // 获取当前活动的视图控制器
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController addChildViewController:self];
    self.view.frame = rootViewController.view.bounds;
    [rootViewController.view addSubview:self.view];
    [self didMoveToParentViewController:rootViewController];

    // 创建一个新的视图来容纳视频播放器
    self.playerView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
    self.playerView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_playerView];

    self.player = [AVPlayer playerWithURL:videoURL];

    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = _playerView.bounds;
    [_playerView.layer addSublayer:self.playerLayer];

    // 创建播放/暂停按钮
    UIImage *pauseImage = [UIImage imageWithContentsOfFile:@"assets/images/pause.png"];
    self.playPauseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.playPauseButton.tintColor = [UIColor whiteColor];
    self.playPauseButton.frame = CGRectMake(10, self.view.bounds.size.height - 70, 60, 30);
    [self.playPauseButton setImage:pauseImage forState:UIControlStateNormal];
    [self.playPauseButton addTarget:self action:@selector(playPauseTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playPauseButton];

    // 创建当前时间标签
    self.currentTimeLabel = [[[UILabel alloc] initWithFrame:CGRectMake(60, self.view.bounds.size.height - 70, 60, 30)] autorelease];
    self.currentTimeLabel.textColor = [UIColor whiteColor];
    self.currentTimeLabel.text = @"00:00";
    [self.currentTimeLabel setFont:[UIFont systemFontOfSize:(12)]];
    [self.view addSubview:self.currentTimeLabel];

    // 创建持续时间标签
    self.durationLabel = [[[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 40, self.view.bounds.size.height - 70, 60, 30)] autorelease];
    self.durationLabel.textColor = [UIColor whiteColor];
    self.durationLabel.text = @"00:00";
    [self.durationLabel setFont:[UIFont systemFontOfSize:(12)]];
    [self.view addSubview:self.durationLabel];

    // 创建暂停状态标签
    UIImage *pauseImage2 = [UIImage imageWithContentsOfFile:@"assets/images/circlePlay.png"];
    self.centerPlay = [[[UIImageView alloc] initWithImage:pauseImage2] autorelease];
    self.centerPlay.tintColor = [UIColor whiteColor];
    self.centerPlay.frame = CGRectMake(0, 0, 80, 80);
    self.centerPlay.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
    self.centerPlay.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.centerPlay];

    // 创建进度条
    self.progressSlider = [[[UISlider alloc] initWithFrame:CGRectMake(100, self.view.bounds.size.height - 70, self.view.bounds.size.width - 150, 30)] autorelease];
    [self.progressSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.progressSlider];

    // 观察播放进度
    typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
        if (current && total) {
            weakSelf.progressSlider.value = current / total;
            weakSelf.currentTimeLabel.text = [weakSelf timeFormatted:current];
            weakSelf.durationLabel.text = [weakSelf timeFormatted:total];
        }
    }];

    // 添加点击手势识别器
    UITapGestureRecognizer *tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
    [self.view addGestureRecognizer:tapRecognizer];

    // 添加播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];

    // 初始化播放状态
    [self.player play];
    self.centerPlay.hidden = true;
    self.isPlaying = YES;

    // 创建退出按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(20, 40, 44, 44);
    [closeButton setTitle:@"✕" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont systemFontOfSize:36];
    [closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
}

- (NSString *)timeFormatted:(int)totalSeconds {
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

- (void)playPauseTapped {
    UIImage *pauseImage = [UIImage imageWithContentsOfFile:@"assets/images/pause.png"];
    UIImage *playImage = [UIImage imageWithContentsOfFile:@"assets/images/play.png"];
    if (self.isPlaying) {
        [self.player pause];
        self.centerPlay.hidden = false;
        [self.playPauseButton setImage:playImage forState:(UIControlStateNormal)];
    } else {
        [self.player play];
        self.centerPlay.hidden = false;
        [self.playPauseButton setImage:pauseImage forState:(UIControlStateNormal)];
    }

    self.isPlaying = !self.isPlaying;
}

- (void)sliderValueChanged:(UISlider *)sender {
    float duration = CMTimeGetSeconds(self.player.currentItem.duration);
    CMTime newTime = CMTimeMakeWithSeconds(sender.value * duration, NSEC_PER_SEC);
    [UIView animateWithDuration:0.2 animations:^{
        [self.player seekToTime:newTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }];
    [self.player seekToTime:newTime];
}

- (void)handleTap:(UITapGestureRecognizer *)tapRecognizer {
    UIImage *pauseImage = [UIImage imageWithContentsOfFile:@"assets/images/pause.png"];
    UIImage *playImage = [UIImage imageWithContentsOfFile:@"assets/images/play.png"];
    if (self.isPlaying) {
        [self.player pause];
        self.centerPlay.hidden = false;
        [self.playPauseButton setImage:playImage forState:(UIControlStateNormal)];
    } else {
        if (CMTimeGetSeconds(self.player.currentTime) == CMTimeGetSeconds(self.player.currentItem.duration)) {
            [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL) {
                [self.player play];
                self.centerPlay.hidden = true;
                [self.playPauseButton setImage:pauseImage forState:(UIControlStateNormal)];
            }];
        } else {
            [self.player play];
            self.centerPlay.hidden = true;
            [self.playPauseButton setImage:pauseImage forState:(UIControlStateNormal)];
        }
    }

    self.isPlaying = !self.isPlaying;
}

- (void)playerDidFinishPlaying:(NSNotification *)notification {
    UIImage *playImage = [UIImage imageWithContentsOfFile:@"assets/images/play.png"];
    self.isPlaying = NO;
    [self.playPauseButton setImage:playImage forState:(UIControlStateNormal)];
}

- (void)closeButtonTapped:(UIButton *)sender {
    [self.player pause];
    self.player = nil;
    self.playerLayer = nil;

    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

-(void)dealloc {
    qCDebug(LOG_SFE_IOS_MEM, "VideoPlayer dealloc");
    [super dealloc];
}

@end


void IosMedia::previewVideo(const QString &filepath)
{
    NSString *nsFilepath = [NSString stringWithUTF8String:filepath.toUtf8().constData()];
    NSURL *videoURL = [NSURL fileURLWithPath:nsFilepath];
    VideoPlayer *videoPlayer = [[VideoPlayer new] autorelease];
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;

    [rootViewController addChildViewController:videoPlayer];
    videoPlayer.view.frame = rootViewController.view.bounds;
    [rootViewController.view addSubview:videoPlayer.view];
    [videoPlayer didMoveToParentViewController:rootViewController];
    [videoPlayer videoDidLoad:videoURL];
}
