## iOS文件读取/打开pdf文件适配

#### 相关链接：

[UIDocumentInteractionController](https://developer.apple.com/documentation/uikit/uidocumentinteractioncontroller?language=objc)

[WKWebView](https://developer.apple.com/documentation/webkit/wkwebview?language=objc)

尝试的解决方案

使用Qt自带的

使用UIDocumentInteractionController

使用WKWebView

```objective-c
void Native::viewPdf(const QString &filepath)
{
    NSString *path = [NSString stringWithUTF8String:filepath.toUtf8().constData()];
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    // 使用屏幕尺寸来设置 WKWebView 的矩形区域
    CGRect webViewFrame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);

    // 创建 WKWebView 实例，并设置其矩形区域
    WKWebView *webView = [[WKWebView alloc] initWithFrame:webViewFrame];
    [webView loadFileURL:fileURL allowingReadAccessToURL:fileURL];

    // Add the WKWebView to the view hierarchy
    UIViewController *viewController = UIApplication.sharedApplication.keyWindow.rootViewController;
    [viewController.view addSubview:webView];

    // 可能是因为是模拟器的原因
    // NSString *path = [NSString stringWithUTF8String:filepath.toUtf8().constData()];
    // NSURL *fileURL = [NSURL fileURLWithPath:path];
    // UIDocumentInteractionController *documentController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    // [documentController presentPreviewAnimated:YES];
}
