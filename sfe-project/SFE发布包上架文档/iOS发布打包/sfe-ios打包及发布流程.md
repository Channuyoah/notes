## iOS发布打包

### 首先在appstoreconnect网站上创建一个新版本
![appstoreconnect创建新版本](../img/image-app-1.png)

### 测试服(上TestFlight)

1、在Qt端构建选择ios，进行`重新构建`
![qt重新构建-测试服](../img/image-distribute-1.png)
![qt重新构建](../img/image-distribute-ios-13.png)

2、在构建目录当中打开对应生成的xcodeproj文件
![Xcode设置profile](../img/image-distribute-2.png)
![Xcode设置version](../img/image-distribute-ios-14.png)
![alt text](../img/image-29.png)
![alt text](../img/image-31.png)
![alt text](../img/image-33.png)
![alt text](../img/image-32.png)
![alt text](../img/image-34.png)
![xcode上传testflight](../img/image-distribute-4.png)
![成功上传官网查看](../img/image-distribute-ios-7.png)
![选择app加密算法](../img/image-distribute-ios-8.png)
![进入编辑测试信息](../img/image-distribute-ios-9.png)
![编辑测试信息](../img/image-distribute-ios-10.png)
![进入TestFlight安装](../img/image-distribute-ios-11.png)

### 正式服(上AppStore)
参照Android端设置PROD

![qt重新构建-正式服](../img/image-distribute-ios-12.png)
![qt重新构建](../img/image-distribute-ios-13.png)

在构建目录当中打开对应生成的xcodeproj文件
![Xcode设置profile](../img/image-distribute-2.png)
![Xcode设置version](../img/image-distribute-ios-14.png)
![alt text](../img/image-29.png)
![alt text](../img/image-31.png)
![alt text](../img/image-33.png)
![alt text](../img/image-32.png)
![alt text](../img/image-34.png)
![xcode上传App Store](../img/image-distribute-ios-15.png)
![处理加密证书其他等](../img/image-distribute-ios-16.png)
![正常上传App Store之前](../img/image-distribute-ios-17.png)
![选择构建版本1](../img/image-distribute-ios-18.png)
![选择构建版本2](../img/image-distribute-ios-19.png)
![保存添加以供审核](../img/image-distribute-ios-20.png)
![保存添加以供审核1](../img/image-distribute-ios-21.png)
![保存添加以供审核2](../img/image-distribute-ios-22.png)
![等待审核](../img/image-distribute-ios-23.png)