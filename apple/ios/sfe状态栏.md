## sfe状态栏

目标：优化sfe状态栏显示

链接：[qtstatusbar](git@github.com:jpnurmi/qtstatusbar.git)

在Android模拟器上运行的时候，出现了xxxx.zip....什么什么java问题，通过查看编译输出消息发现原因是下载的`Downloading https://services.gradle.org/distributions/gradle-5.6.4-bin.zip`有问题，重新去写它的地址，用国内镜像`https://mirrors.cloud.tencent.com/gradle/`

先去qt的安装目录找`E:\Qt\5.15.2\android\src\3rdparty\gradle\gradle\wrapper`，将gradle-wrapper.properties内的gradle修改好，重新编译