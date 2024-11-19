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

~~发现其中没有\_\_ARM\_\_、\_\__aeabi\_\_、\_\_x86__、\_\_i386\_\_的符号，说明该库文件应该使用的是通用的符号。~~

### 调整方向

发现运行时出问题最多的是关于架构的原因，所以查阅资料发现了一个是正确的探索方向：

因为在苹果自己推出m1芯片之前，使用的是intel架构的芯片，也就是x86架构的芯片，可是我现在使用的mac电脑的芯片是m1芯片，这个芯片是arm架构的。苹果为了保持兼容性和支持现有的开发生态，Xcode还是提供了模拟器，用于在新的ARM架构mac上模拟运行x86架构的应用程序，可以方便开发人员在新的Mac继续开发和测试之前基于x86架构的应用程序，而不需要依赖于旧的硬件或虚拟机。

所以说新的Mac电脑使用ARM架构的芯片，但我们开发人员仍然可以使用Xcode的模拟器来模拟运行x86架构的应用程序，来保持开发和测试的连续性和兼容性。

运用到当前的顺风耳项目上来说就是，在Qt当中使用的ios模拟器是Xcode提供的，Xcode提供的模拟器是x86架构的，但是当前我们的计算机架构是arm架构，所以说需要在构建编译的时候添加编译选项让其生成的链接文件是针对x86架构的，这样我们的模拟器才可以成功运行。

**通过询问成哥，发现问题是OpenSSL库我们ios下的可能没有x86符号，之前理解的nm命令查看的是理解有误。**

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

### 支持iOS平台的OpenSSL库：

##### 1、将OpenSSL源码放到Mac当中，使用iTerm进入openssl源码文件夹

##### 2、使用`./Configure ios-arm64`命令

**出现问题：**`permission denied:/.Configure`这个表明我们macOS命令行执行`./Configure`时出现权限被拒绝的错误。

**解决问题：**因为我们没有为其添加执行权限：`chmod +x Configure`。

这里解释一下`chmod +x`表明将文件的执行权限设置为允许所有者、组和其他用户执行该文件

`./Configure`是一个脚本文件，通常用于配置源代码以进行编译，在OpenSSL的情况下，执行该命令时，会根据指定的选项生成Makefile文件，这个Makefile文件用于指导后续的编译过程

##### 3、执行`make`命令

**出现问题：**`*** No targets specified and no makefile found. Stop.`这个表明它没有找到makefile文件，说明我们之前的`./Configure ios-arm64`没有生成makefile文件。这个可能是由于配置过程中出现了问题，下面尝试解决这个问题。

**解决问题：**

- 检查在执行`./Configure`命令时有没有出现错误信息

执行之后发现在命令行出现了Makefile关键字，此时在重新运行一次以上步骤，即可make，等待执行编译完成。

我们需要的是libssl.a和libcrypto.a可以通过find . -name "*.a"文件查找该目录下所有的.a文件

### 测试新编译的OpenSSL库文件

发现还是报错一样的，构建了ios的openssl库，但是这里需要链接的符号是x86的，因为是使用的xCode提供的模拟器，这个模拟器是x86架构的，所以应该生成的是x86架构的OpenSSL下面重新生成

`./Configure darwin64-x86_64-cc`，这里darwin64表示目标平台是macOS，x86_64表示目标架构是x86_64，cc表示使用C编译器(gcc/clang)进行编译。

make之后报错: 

```bash
Undefined symbols for architecture x86_64:
  "_ossl_kdf_pbkdf2_default_checks", referenced from:
      _kdf_pbkdf2_new in libdefault.a[x86_64][94](libdefault-lib-pbkdf2.o)
      _kdf_pbkdf2_reset in libdefault.a[x86_64][94](libdefault-lib-pbkdf2.o)
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
make[1]: *** [libcrypto.3.dylib] Error 1
make: *** [build_sw] Error 2
```

[类似的回答](https://github.com/openssl/openssl/issues/17979)

我重新 make clean之后再次`./Configure darwin64-x86_64-cc`再次`make`没问题了

此时运行qt报错：

```bash
ld: building for 'iOS-simulator', but linking in object file (/Users/leo/cc/qt-Project/sfe-mobile/ssltool/openssl/bin/ios/libcrypto.a[2](libcrypto-lib-aes-x86_64.o)) built for 'macOS'
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

见错知意，这里表示是为iOS模拟器构建，但在为macOS构建的目标文件中链接，文件xx用于构架macOS，这个原因应该是我们使用的编译器是macOS全局的gcc/clang，最好使用qt构建使用的编译器，打开macOS端的qt寻找我们iOS-Simulator的编译器，发现是Apple Clang(x86_64) Clang，从构建套件中查看到编译器的路径。

现在1可以直接使用这个编译器，2可以将这个编译器放置到path当中，接下来尝试使用添加环境变量

```bash
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
```

使用macOS的命令行工具iTerm

```bash
cd ~
ls -a
vim .zshrc 
export CC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
```

再次进入openssl源代码目录

```bash
make clean
./Configure darwin64-x86_64-cc # 这里会使用当前环境变量中设置的CC编译器
make
```

还是报错相同，我在Windows上检测了两个文件是否是相同的(为了检测是否使用的是同一个编译器编译的文件)，结构貌似是不同的。

```bash
cmp libssl.a ../ios-arm64/ios/libssl.a
# 输出：
libssl.a ../ios-arm64/ios/libssl.a differ: char 30, line 2
```

发现不行之后决定去github上面寻找ios的OpsnSSL(这个才更新没有多长时间)

[github iOS OpenSSL](github.com/krzyzanowskim/OpenSSL.git)

### 新问题：无法访问assets文件夹内资源

[iOS与Android资源文件读写对比](https://blog.csdn.net/gaussrieman123/article/details/89467829)

成哥说他之前跑的时候可以运行，iOS也可以访问assets目录，只不过需要安装assets，其实在Android上访问assets它也是事先安装了assets的(貌似是自动安装？)，现在我将对比trtc-mobile.pro文件来查看如何使sfe顺利的访问assets资源

## 关于Qt内的资源系统

.qrc资源文件和assets文件系统的区别：



#### 尝试

在Me.qml文件当中将其中的一个back.png由`$app.asset("images/next.png")`改为绝对地址：`file:///User/leo/cc/qt-Project/sfe-mobile/assets/images/back.png`发现能够成功加载这个图标。说明是能够成功访问到我们sfe-mobile/assets目录，因此极大可能是路径出错误了，下面在.pro文件当中修改assets.path和assets.files的路径

```q
assets.files = $$PWD/assets/
assets.path = $$PWD/assets/
INSTALLS += assets
QMAKE_BUNDLE_DATA += assets
message("assets.path: $$assets.path")
message("assets.path: $$assets.path")
```

这里输出的assets.path地址是: 

```path
Project MESSAGE: assets.path: /Users/leo/cc/qt-Project/sfe-mobile/assets/
```

其中资源的报错说找不到这个：

```path
file://users/leo/Library/Developer/CoreSimulator/Devices/CCAEEE60-4D83-40F2-B6A7-4EBC5348E702/data/Containers/Bundle/Application/75177443-705F-4881-8F98-C1821A560971/sfe-mobile.app/assets/images/next.png
```

### 解决方案

#### assets文件资源适配

#### 翻译资源适配

链接: 

CONFIG += lrelease

CONFIG += embed_translations

这里lrelease会将翻译文件弄成.qm文件
.qm文件是什么文件？详情看翻译适配
