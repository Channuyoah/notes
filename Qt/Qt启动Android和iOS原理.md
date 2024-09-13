# Qt启动Android和iOS原理
### 目标
理解Qt启动的时候做了些什么事
- Qt在Android平台的实现
- Qt在iOS平台的实现
- 如何在不同平台上实现跨平台的功能，如何与平台特有功能进行交互
### 参考
- [Qt Documentation](https://doc.qt.io/qt-5/)
- [Qt for Android](https://doc.qt.io/qt-5/android.html)
- [Qt for iOS](https://doc.qt.io/qt-5/ios.html)

### Qt在启动的时候做了什么
接下来就从main.cpp源码开始分析吧
```cpp
#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
// 在Qt_VERSION_MAJOR小于6的时候默认不会自动开启高DPI，所以要进行手动开启 
// 关于这两个宏，前者是QT_VERSION_CHECK(QT_VERSION_MAJOR, QT_VERSION_MINOR, QT_VERSION_PATCH)-------->也就是QT_VERSION_CHECK(5.15.2)
// 后者是QT_VERSION_CHECK(6.0.0)
// 而本身的QT_VERSION_CHECK宏定义为#define QT_VERSION_CHECK(major, minor, patch) ((major<<16)|(minor<<8)|(patch))
// 这就意味着前者'5'左移16位，'15'左移8位，‘2’不移动，再来与其比大小
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
/*
 这里初始化QGuiApplication定义app变量
 QGuiApplication.cpp源码在Qt/5.15.2/Src/qtbase/src/gui/kernel/qguiapplication.cpp
 */
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
```

 --------------------------------------------------------------
 QGuiApplication构造函数
 ```C++
 #ifdef Q_QDOC
 QGuiApplication::QGuiApplication(int &argc, char **argv)
 #else
 QGuiApplication::QGuiApplication(int &argc, char **argv, int flags)
 #endif
     : QCoreApplication(*new QGuiApplicationPrivate(argc, argv, flags))
 {
     d_func()->init();
 
     QCoreApplicationPrivate::eventDispatcher->startingUp();
 }
 ```
 