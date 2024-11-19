# Android-Qt-WebView-ChooseFile
### 相关链接
- [Activity.java源码](https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/app/Activity.java#5838)
- [Bundle.java源码](https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/os/Bundle.java)
- [Intent.java源码](https://android.googlesource.com/platform/frameworks/base/+/135936072b24b090fb63940aea41b408d855a4f3/core/java/android/content/Intent.java)
- [WebChromeClient.java源码](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/java/android/webkit/WebChromeClient.java?autodive=0%2F)
- [Serializable.java源码](https://android.googlesource.com/platform/libcore/+/0b6b3e1/luni/src/main/java/java/io/Serializable.java)
- [Parcelable.java源码](https://android.googlesource.com/platform/frameworks/base/+/android-3.2.4_r1/core/java/android/os/Parcelable.java)
- [onShowFilePath源码](https://developer.android.com/reference/android/webkit/WebChromeClient#onShowFileChooser(android.webkit.WebView,%20android.webkit.ValueCallback%3Candroid.net.Uri[]%3E,%20android.webkit.WebChromeClient.FileChooserParams))
### 问题描述
因为Qt在QtAndroidWebViewChroller.java当中的QtAndroidWebChromeClient类(继承自WebChromeClient)当中没有实现onShowFileChooser()方法，导致Android Qt端不支持WebView打开文件选择器，所以需要在这个类当中重载onShowFileChooser()方法。

### 有的尝试
- 尝试intent、bundle、Serializable和Parcelable序列化接口将ValueCallBack<Uri[]>对象传递给QtActivity当中的onActivity的Intent未能成功传递。
- 尝试重新实现的Intent类、重新实现的Serializable、Parcelable序列化接口将ValueCallBack<Uri[]>对象传递给QtActivity当中的onActivity的Intent，未能成功传递。
- 尝试使用新的Activity Result API代替startActivityForResult失败(Qt5.15.2版本过低)

其中前两项尝试后续均尝试传递基础类型，实验后发现在其中只传递基础类型，在QtAndroidWebViewController.java当中定义传递能够成功打印绑定的bundle和intent，但是在QtActivity.java当中的onActivityResult()方法内拿不到传递过来的intent，这个intent只包含 在相册选择的资源.
