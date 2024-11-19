# ios实现WebView

## 相关链接:
 - [QML WebView](https://doc.qt.io/qt-5/qml-qtwebview-webview.html)
 - [QT QWebSocketServer](https://doc.qt.io/qt-5/qwebsocketserver.html)
 - [QT WebChannel](https://doc.qt.io/qt-5/qwebchannel.html)

## 相关关键词:
 - WebView
 - WebSocketServer
 - WebSocket
 - WebChannel
 - WebSocketTransport

## 涉及源码:
 - WebView --> qdarwinwebview.mm
 - WebSocketServer --> qqmlwebsocketserver.cpp

## 使用背景:
SFE项目：在五金需求当中需要移动端在WebView当中与H5进行交互，例如在h5页面点击之后的适当时机退出WebView，由于Android和iOS在实现WebView基于的浏览器内核不一样，iOS实现WebView是使用Safari的WebKit引擎相比基于Chromium内核实现WebView的Android有更加严格的控制和安全策略，iOS不同意不安全的连接，导致我们仅能够显示网页，不能够建立与H5端的连接交互

## 步骤：
搭建一个server打开端口监听，然后初始化webView加载给定的url，加载url时会建立一个socket连接，建立连接之后响应回调，然后创建一个channel将准备好的对象通过transport传递给客户端，客户端通过这个对象与Android进行交互

## 关注点：
 - 流程科学正确
   
   先梳理正确合理的流程明确理解执行步骤及细节，什么时候开启/关闭server、WebView？什么时候证书验证？当有new connect的时候应该做什么？什么时候开启/关闭channel、transport？暴露给H5端的对象需要完成什么功能？如何将WebView组件做的通用化？

 - 充分考虑异常情况
  
   当加载url正常/异常的时候执行什么回调函数？应该如何操作？reload、loadRequest有什么区别吗？实验一下webView.URL的值观察其什么时候释放

 - 正确处理视图关系、内存释放

   注意有alloc/new的对象，注意有presentView的地方就需要有对应的dismissView，关注其生命周期以及引用关系在其应该释放的时候及时释放

 - 证书认证

```cpp
    // 自生成证书： openssl req -newkey rsa:2048 -new -nodes -x509 -days 36500 -keyout localhost.key -out localhost.pem

    // https://doc.qt.io/qt-5/qwebsocketserver.html#SslMode-enum
    QWebSocketServer *server = new QWebSocketServer("webpage-ws-server", QWebSocketServer::SecureMode);
```
```cpp
    // 处理服务器身份验证，信任自颁发的证书
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
```
