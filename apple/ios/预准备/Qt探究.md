## Qt探究

### 目标1：弄清楚为什么Qt支持跨平台

### 目标2：弄清楚Qt Android & iOS启动逻辑

[Qt Platform Abstraction](https://doc.qt.io/qt-5/qpa.html)

QPA提供了一个抽象层，用于将Qt应用程序与底层操作系统的特性进行解耦，实现跨平台能力。

- **抽象了底层窗口系统和设备接口：**QPA提供统一接口，用于访问底层的窗口系统(Windows、macOS等等)和设备接口(图形和输入设备)，开发者可以通过这个接口实现对特定平台的访问
- **封装了不同平台的实现细节：**QPA封装了不同平台的实现细节使得开发者无需直接操作底层的窗口系统和设备接口通过提供的统一的Qt接口实现对不同平台的访问
- **实现跨平台的GUI功能：**通过QPA，Qt能够在不同操作系统上实现跨平台的GUI功能，开发者可以使用相同的代码库开发GUI应用程序，无需关心西昌系统的差异。
- **支持自定义插件：**QPA支持自定义插件，开发者开开药根据需要编写自己的平台插件，从而拓展Qt在特定平台上的功能和特性

[Qt for Android](https://doc.qt.io/qt-5/android.html)

#### iOS

[Qt for iOS](https://doc.qt.io/qt-5/ios.html)

[Connecting iOS Devices](https://doc.qt.io/qtcreator/creator-developing-ios.html)

在iOS平台上，使用的是Xcode作为开发和部署的工具，在Qt项目中维护一个.pro文件，然后通过这个.pro文件生成一个Xcode项目，最终在Xcode中进行开发、编译和部署。

我们可以在Qt应用程序中使用Objective-C代码：[资料](https://doc.qt.io/qt-5/ios.html#using-objective-c-code-in-qt-applications)

[移植到iOS](https://doc.qt.io/qt-5/porting-to-ios.html)