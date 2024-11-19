#import "Log.h"
#import <UIKit/UIKit.h>

Q_LOGGING_CATEGORY(LOG_SFE_IOS_LOADINGVIEW, "sfe-ios-lodingView", QtWarningMsg);

@interface LoadingView : UIView
// 设置isLoading属性 避免反复调用show/hide
@property (nonatomic, assign) BOOL visible;
@property (nonatomic, strong) UIView* parentView;
@end

@implementation LoadingView {
    UIView *containerView;
    UIActivityIndicatorView *activityIndicator;
    UILabel *loadingLabel;
}

- (instancetype)initWithLoadingText:(NSString *)loadingText parentView:(UIView*) parentView {
    self = [super init];
    if (self) {
        self.visible = false;
        self.parentView = parentView;

        self.frame = [UIScreen mainScreen].bounds;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];

        containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
        containerView.backgroundColor = [UIColor whiteColor];
        containerView.layer.cornerRadius = 10;
        containerView.clipsToBounds = YES;
        containerView.center = self.center;
        [self addSubview:containerView];

        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityIndicator.center = CGPointMake(containerView.bounds.size.width / 2, containerView.bounds.size.height / 2 - 20);
        activityIndicator.transform = CGAffineTransformMakeScale(1.5, 1.5);
        [containerView addSubview:activityIndicator];

        loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, containerView.bounds.size.width, 30)];
        QString loading = QObject::tr("loading");
        loadingLabel.text = loadingText ? loadingText : loading.toNSString();
        loadingLabel.textColor = [UIColor blackColor];
        loadingLabel.textAlignment = NSTextAlignmentCenter;
        loadingLabel.center = CGPointMake(containerView.bounds.size.width / 2, containerView.bounds.size.height / 2 + 30);
        [containerView addSubview:loadingLabel];
    }
    return self;
}

- (void)show {
    if (self.visible) {
        return;
    }

    self.visible = true;
    [activityIndicator startAnimating];
    UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;

    if (self.parentView) {
        [self.parentView addSubview:self];
    } else {
        [keyWindow addSubview:self];
    }
}

- (void)hide {
    if (!self.visible) {
        return;
    }

    self.visible = false;
    [activityIndicator stopAnimating];
    [self removeFromSuperview];
}

- (void)dealloc {
    qCDebug(LOG_SFE_IOS_LOADINGVIEW, "objective-c loadingview dealloc");
    self.parentView = nil;
    [super dealloc];
}

@end
