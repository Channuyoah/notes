#import "Log.h"
#import "Native_iOS.h"
#import <UIKit/UIKit.h>

@interface HeadBar : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *backButton;
@end

Q_LOGGING_CATEGORY(LOG_SEF_IOS_HEADBAR, "sfe-ios-headbar", QtWarningMsg);

@implementation HeadBar
- (instancetype)init {
    self = [super init];
    if (!self) {
        return self;
    }

    [self headView];
    return self;
}

- (void)headView {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    int topMargin = Native::instance()->safeAreaMargins().value("top", 0).toInt();
    self.frame = CGRectMake(0, topMargin, screenWidth, 44);
    self.backgroundColor = [UIColor whiteColor];

    // 容纳button和title的布局
    UIView *containerView = [[[UIView alloc] init] autorelease];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:containerView];

    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImage = [UIImage imageNamed:@"assets/images/back.png"];
    [self.backButton setImage:backImage forState:UIControlStateNormal];
    self.backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:self.backButton];

    self.titleLabel = [[[UILabel alloc] init] autorelease];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.text = @"";
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:self.titleLabel];

    // 设置布局
    [NSLayoutConstraint activateConstraints:@[
        [containerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0],
        [containerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0],
        [containerView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0],
        [containerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0],

        [self.backButton.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:16],
        [self.backButton.centerYAnchor constraintEqualToAnchor:containerView.centerYAnchor],
        [self.backButton.widthAnchor constraintEqualToConstant:16],
        [self.backButton.heightAnchor constraintEqualToConstant:16],

        [self.titleLabel.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:containerView.centerYAnchor],
        [self.titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.backButton.trailingAnchor constant:8],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:containerView.trailingAnchor constant:-16],
    ]];
}

- (void)dealloc {
    qCDebug(LOG_SEF_IOS_HEADBAR, "objective-c HeadBar dealloc");
    self.titleLabel = nil;
    self.backButton = nil;
    [super dealloc];
}

@end
