# 在MacOS端Qt运行顺风耳

步骤：

1、clone下来我们的仓库

2、进入仓库 git submodule init + git submodule update

3、基于master创建一个新分支

Tips：关于git submodule init 和 update，因为我们sfe仓库当中有两个子模块的仓库，运行这两个命令首先初始化子模块，再下载子模块的内容，为的是保证我们的工作目录中包含仓库中所有子模块的最新版本。

### 进入运行

步骤：运行sfe --> 查看报错信息 --> 排查报错信息 

1、选择Qt 51.5.2(ios) Simulator进行构建，重新构建项目

在应用程序输出窗口会出现：`Xcodebuild failed`和`[xcodebuild-debug-simulator] Error 65`

查看编译输出窗口发现爆红信息之上的error信息是：

```error信息 
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

这里说的是链接出错，没有找到x86_64架构下的某些符号。可能是由于：缺少库文件、库文件路径问题、库文件版本不匹配、符号命名等问题，下面将一个个来排查。

2、观察编译窗口发现非常多的ld链接警告，均是指向ssltool/openssl/bin/ios/libcrypto.a说的是：found architecture 'arm64', required architecture 'x86_64'

我发现我的openssl.pri文件当中有

```
ios {
    LIBS += $$PWD/bin/ios/libssl.a
    LIBS += $$PWD/bin/ios/libcrypto.a
}
macos {
    LIBS += $$PWD/bin/macos/libssl.a
    LIBS += $$PWD/bin/macos/libcrypto.a
}
```

并且去查看文件目录下确实是有这两个文件的。

3、排查库文件的架构是否支持x86-64

- 使用file命令来确定文件的类型：file libssl.a

  对于可执行文件、库文件和其他二进制文件，file命令通常会提供有关文件所使用的CPU架构(或者目标架构)的信息。

发现输出的是

```bash
leo@neochindeMac-Studio ios % file libssl.a
libssl.a: current ar archive random library
leo@neochindeMac-Studio ios % file libcrypto.a
libcrypto.a: current ar archive random library
```

这里输出表明这些库文件是ar归档文件，但是没有提供关于其包含的架构的详细信息。对于静态库文件(这里就是静态库文件)，file命令通常不会提供关于包含的架构的详细信息。

- 使用nm命令来查看库文件中包含的符号：nm libssl.a

  这将显示libssl.a文件中的所有符号。如果文件包含了针对iOS设备和模拟器架构的符号，尝试在输出中寻找是否有相应的符号。

发现其中没有\_\_ARM\_\_、\_\__aeabi\_\_、\_\_x86__、\_\_i386\_\_的符号，说明该库文件应该使用的是通用的符号。

### 调整方向

发现运行时出问题最多的是关于架构的原因，所以查阅资料发现了一个是正确的探索方向：

因为在苹果自己推出m1芯片之前，使用的是intel架构的芯片，也就是x86架构的芯片，可是我现在使用的mac电脑的芯片是m1芯片，这个芯片是arm架构的。苹果为了保持兼容性和支持现有的开发生态，Xcode还是提供了模拟器，用于在新的ARM架构mac上模拟运行x86架构的应用程序，可以方便开发人员在新的Mac继续开发和测试之前基于x86架构的应用程序，而不需要依赖于旧的硬件或虚拟机。

所以说新的Mac电脑使用ARM架构的芯片，但我们开发人员仍然可以使用Xcode的模拟器来模拟运行x86架构的应用程序，来保持开发和测试的连续性和兼容性。

运用到当前的顺风耳项目上来说就是，在Qt当中使用的ios模拟器是Xcode提供的，Xcode提供的模拟器是x86架构的，但是当前我们的计算机架构是arm架构，所以说需要在构建编译的时候添加编译选项让其生成的链接文件是针对x86架构的，这样我们的模拟器才可以成功运行。

**通过询问成哥**，发现问题是OpenSSL库我们ios下的可能没有x86符号，之前理解的nm命令查看的是理解有误。

### 寻找ios的OpenSSL库

1、使用预编译的OpenSSL库

2、自行编译OpenSSL库

抱着学习的态度，将进行自行编译OpenSSL库

### 自行编译OpenSSL库

[OpenSSL库官方](https://www.openssl.org/source/index.html)

1、获取OpenSSL源码，从官方下载最新版本的OpenSSL源码

下载了官方的openssl-3.3.0.tar.gz和其SHA256

- 在git bash当中检测hash ：sha256sum openssl-3.3.0.tar.gz

- 打开openssl-3.3.0.tar.gz.sha256进行对比

  **注意：不要使用echo -n xx | sha256sum**，因为echo命令会在输出时附加一个换行符，虽然我使用了echo -n抑制结尾的换行符了，但是它仍然会在文件内容之后添加一个空格。这个空格可能会直接导致哈希计算不同。**为了确保hash正确比较，使用 sha256sum xx进行**。

2、开始编译构建不同平台的OpenSSL库

支持iOS平台：