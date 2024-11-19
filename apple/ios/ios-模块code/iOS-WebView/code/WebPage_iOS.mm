#import "Log.h"
#include "QtWebSockets/qwebsocket.h"
#import "Native_iOS.h"
#import "HeadBar_iOS.mm"
#import "LoadingView_iOS.mm"
#import "../websocket/WebSocketServer.h"
#import "../websocket/WebSocketTransport.h"

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>
#import <QWebChannel>
#import <QTimer>

Q_LOGGING_CATEGORY(LOG_SFE_IOS_WEBPAGE, "sfe-ios-webpage", QtWarningMsg);

@interface WebView : WKWebView
@end

@implementation WebView
- (void)dealloc {
    qCDebug(LOG_SFE_IOS_WEBPAGE, "objective-c WebView dealloc");
    [super dealloc];
}
@end

@interface WebPageController : UIViewController<WKNavigationDelegate>
@property (nonatomic, strong) WebView* webView;
@property (nonatomic, strong) HeadBar* headBar;
@property (nonatomic, strong) WKNavigation* currentNavigation;
@property (nonatomic, strong) LoadingView* loadingView;
@property (nonatomic, assign) WebSocketServer* webSocketServer;
@property (nonatomic, assign) QtApp* qtApp;
@property (nonatomic, assign) QTimer* loadTimer;
@property (nonatomic, assign) NSURL* url;
@property (nonatomic, assign) BOOL isShowError;
@end

@implementation WebPageController

// 创建对象之后立即执行(构造函数)
- (instancetype)init {
    self = [super init];
    if (!self) {
        return self;
    }

    self.qtApp = new QtApp();
    QObject::connect(self.qtApp, &QtApp::closeWebPage, [self]() {
        [self closeWebPage];
    });

    // 初始化加载超时定时器
    QTimer *timer = new QTimer();
    timer->setInterval(10000);
    timer->setSingleShot(true);
    self.loadTimer = timer;
    QObject::connect(self.loadTimer, &QTimer::timeout, [self]() {
        [self.webView stopLoading];
        [self.loadingView hide];
        [self showErrorView];
    });

    [self initWebSocketServer];
    QObject::connect(self.webSocketServer, &WebSocketServer::newConnect, self.webSocketServer, [self](QWebSocket * client) {
        QWebChannel *channel = new QWebChannel(client);
        channel->registerObject(QStringLiteral("qtApp"), self.qtApp);
        WebSocketTransport *transport = new WebSocketTransport(channel);
        channel->connectTo(transport);

        QObject::connect(client, &QWebSocket::textMessageReceived, transport, &WebSocketTransport::textMessageReceive);
        QObject::connect(client, &QWebSocket::disconnected, client, &QWebSocket::deleteLater);
        QObject::connect(transport, &WebSocketTransport::messageChanged, client, &QWebSocket::sendTextMessage);
    });

    [self initWebView];
    QString load = QObject::tr("loading");
    self.loadingView = [[[LoadingView alloc] initWithLoadingText:load.toNSString() parentView:self.view] autorelease];

    return self;
}

// 不可以主动调用！销毁对象时被动调用(析构函数)
- (void)dealloc {
    qCDebug(LOG_SFE_IOS_WEBPAGE, "objective-c WebPage dealloc");

    // 以下的释放/指针置空应该是关闭了页面之后自动释放，不是手动释放
    self.loadTimer->stop();
    self.loadTimer->deleteLater();

    // webView headBar loadingview均采用nil进行引用置0来调用其析构函数(release表现一致)
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.webView removeFromSuperview];
    self.webView = nil;

    [self.headBar removeFromSuperview];
    self.headBar = nil;

    // 避免在load状态下关闭webPage 加载框一直存在的情况
    [self.loadingView hide];
    self.loadingView = nil;

    self.currentNavigation = nil;
    self.url = nullptr;

    // webSocketServer应该要deleteLater
    self.webSocketServer->stop();
    self.webSocketServer->deleteLater();
    self.webSocketServer = nullptr;

    self.qtApp->deleteLater();
    self.qtApp = nullptr;

    [super dealloc];
}

- (void)closeWebPage {
    // 注意有present就需要有dismiss
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)popH5Page {
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    } else {
        [self closeWebPage];
    }
}

- (void)initWebSocketServer {
    self.webSocketServer = new WebSocketServer();
    self.webSocketServer->init();
    self.webSocketServer->start();
}

- (void)initWebView {
    // 添加白色背景
    UIView *backgroundView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
    backgroundView.backgroundColor = [UIColor whiteColor];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    int topMargin = Native::instance()->safeAreaMargins().value("top", 0).toInt();
    int bottomMargin = Native::instance()->safeAreaMargins().value("bottom", 0).toInt();
    CGRect screenBounds = [UIScreen mainScreen].bounds;

    self.headBar = [[HeadBar new] autorelease];
    [self.headBar.backButton addTarget:self action:@selector(popH5Page) forControlEvents:UIControlEventTouchUpInside];

    CGFloat webViewWidth = screenBounds.size.width;
    CGFloat webViewHeight = screenBounds.size.height - self.headBar.bounds.size.height - topMargin - bottomMargin;
    self.webView = [[[WebView alloc] initWithFrame:CGRectMake(0, topMargin + self.headBar.bounds.size.height,
                                                                webViewWidth, webViewHeight)] autorelease];
    self.webView.navigationDelegate = self;
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];

    // 注意add顺序
    [self.view addSubview:backgroundView];
    [self.view addSubview:self.webView];
    [self.view addSubview:self.headBar];
}

// KeyValueObserving(键值监听)回调函数，用于监听title变化
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"title"]) {
        NSString *newTitle = self.webView.title;
        if (newTitle) {
            self.headBar.titleLabel.text = newTitle;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

// WebView 页面加载的开始回调
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (self.currentNavigation != navigation) {
        self.currentNavigation = navigation;
    } else {
        return;
    }
}

// WebView 页面加载结束时(成功)回调
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.loadTimer->stop();
    [self.loadingView hide];

    if (self.currentNavigation != navigation) {
        return;
    }
}

// 导航加载失败回调(加载资源时发生错误等)
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
        withError:(NSError *)error {
    self.loadTimer->stop();
    [self.loadingView hide];

    if (self.currentNavigation != navigation) {
        return;
    }

    [self showErrorView];
}

// 页面加载失败(网络问题、URL 错误等)
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation
        withError:(NSError *)error {
    self.loadTimer->stop();
    [self.loadingView hide];

    if (self.currentNavigation != navigation) {
        return;
    }

    [self showErrorView];
}

/*
 * 处理服务器身份验证，信任自颁发的证书
 * https://developer.apple.com/documentation/foundation/nsurlauthenticationmethodservertrust?language=objc
 */
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
        completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                                    NSURLCredential * _Nullable credential))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)showErrorView {
    if (self.isShowError) {
        return;
    }

    self.isShowError = true;
    UIView *errorView = [[[UIView alloc] initWithFrame:self.webView.bounds] autorelease];
    errorView.backgroundColor = [UIColor whiteColor];

    UIView *contentView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, errorView.bounds.size.width * 0.8,
                                                                    errorView.bounds.size.height * 0.4)] autorelease];
    contentView.center = CGPointMake(errorView.bounds.size.width / 2, errorView.bounds.size.height / 2);
    [errorView addSubview:contentView];

    UIImageView *errorImageView = [[[UIImageView alloc]
                                     initWithImage:[UIImage imageNamed:@"assets/images/loadingFail.png"]] autorelease];
    errorImageView.contentMode = UIViewContentModeScaleAspectFit;
    errorImageView.frame = CGRectMake(0, 0, contentView.bounds.size.width, contentView.bounds.size.height * 0.6);
    [contentView addSubview:errorImageView];

    UIButton *retryButton = [UIButton buttonWithType:UIButtonTypeSystem];
    QString refresh = QObject::tr("refresh");
    [retryButton setTitle:refresh.toNSString() forState:UIControlStateNormal];
    [retryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    retryButton.backgroundColor = [UIColor blueColor];
    retryButton.layer.cornerRadius = 10;
    retryButton.frame = CGRectMake(0, CGRectGetMaxY(errorImageView.frame) + 10, contentView.bounds.size.width * 0.6, 40);
    retryButton.center = CGPointMake(contentView.bounds.size.width / 2, retryButton.center.y);
    [retryButton addTarget:self action:@selector(retryLoading:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:retryButton];

    [self.webView addSubview:errorView];
    errorView.tag = 999;
}

// 刷新/重连按钮
- (void)retryLoading:(UIButton *)sender {
    UIView *errorView = [self.webView viewWithTag:999];
    if (errorView) {
        [errorView removeFromSuperview];
        self.isShowError = false;
    }

    [self.loadingView show];
    self.loadTimer->start();

    // 指定url调用loadRequest，因为使用reload()时执行的url为nil
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    [self.webView loadRequest:request];
}

- (void)loadPage:(NSString *)urlString title:(NSString *)title{
    // [self.webView URL]在使用之后会被置空，在需要重连的时候将无法拿到正确的url链接
    self.url = [NSURL URLWithString:urlString];
    if (!self.url) {
        return;
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    [self.webView loadRequest:request];

    if (title && title.length > 0) {
        self.headBar.titleLabel.text = title;
    }

    [self.loadingView show];
    self.loadTimer->start();
}

@end

void IosWebPage::loadWebView(const QString &url, const QString &title)
{
    // 申请对象 指定全屏显示、加载动画
    WebPageController *webPageController = [[WebPageController new] autorelease];
    webPageController.modalPresentationStyle = UIModalPresentationFullScreen;
    webPageController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    NSString *urlString = [NSString stringWithString:url.toNSString()];
    NSString *titleString = title.toNSString();
    [webPageController loadPage:urlString title:titleString];

    UIViewController *rootViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
    [rootViewController presentViewController:webPageController animated:YES completion:nil];
}
