## 在Qt-Create当中运行sfe

探索过程：

在xcode当中创建一个新的项目，其文件结构是

![image-20240403101201335](C:\Users\37612\AppData\Roaming\Typora\typora-user-images\image-20240403101201335.png)

其中的Info.plist是用于：

- **应用程序配置：**存放应用程序的基本配置信息，名称、版本号、唯一标识符等等

- **权限申请：**存放应用程序所需要的系统权限，如相机、麦克风、定位等，在运行时向用户请求授权。
- **应用程序图标和启动图：**Info.plist文件中可以指定应用程序的图标、启动画面和启动图标等相关资源，以及启动画面的显示方式和持续时间。
- **URL Scheme：**可以指定应用车故乡的URL Scheme，用于处理其他应用程序通过URL启动本应用程序的请求。
- **导入的框架和库：**Info.plist文件中可以指定应用程序所需的导入的框架和库，以及其版本号和链接方式。

总结：类似于Android的Manifest文件

#### 尝试

#### 1、尝试在Qt-Cteator当中创建一个新的项目

在Qt当中创建一个空白的项目之后，选择Qt 5.15.2(ios) Simulator来构建

![image-20240403110008012](C:\Users\37612\AppData\Roaming\Typora\typora-user-images\image-20240403110008012.png)

直接运行发现并不能运行，会报错：

```
:-1: error: Xcodebuild failed.
:-1: error: [xcodebuild-debug-simulator] Error 65
```

不明白为什么会报错，尝试在该项目(iOS-BootTest)的build(build-iOS-BootTest-Qt_5_15_2_ios_Simulator-Debug)目录下运行iOS-BootTest.xcodeproj文件。该文件可以直接由xcode打开运行。

![image-20240403111719726](C:\Users\37612\AppData\Roaming\Typora\typora-user-images\image-20240403111719726.png)

此时运行该项目则可以成功运行！之后再切回Qt当中运行，也可以运行！这是为什么呢？让我们重新来一遍，将build目录删除，记录一下没有用xcode编译前的文件和目录结构，通过比较差异来查看xcode做了什么！Let's Go!!!!

#### 分析文件差异

1、从文件大小来说：编译失败的文件：

![image-20240403144714441](C:\Users\37612\AppData\Roaming\Typora\typora-user-images\image-20240403144714441.png)

成功的文件：

![image-20240403144739120](C:\Users\37612\AppData\Roaming\Typora\typora-user-images\image-20240403144739120.png)

文件大小不一致，通过git bash来查看，最外层的文件大小几乎一致，猜测是因为成功了所以生成一堆的链接文件。

...我去，白用工，应该直接去qt的编译输出窗口去查看红字前面的error报错内容。这里是直接重新编译之后即可成功启动iPhone模拟器

