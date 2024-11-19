# qt适配iOS Simulator
## 使用工具
[MacOS包管理工具:Homebrew](https://docs.brew.sh/Manpage)

python

### 现在出现的问题
1. 在qt当中选择iOS模拟器编译报错
   具体描述：缺乏Python的Distutils模块
   ``
   Traceback (most recent call last):
  File "/Users/cc/Qt/5.15.2/ios/mkspecs/features/uikit/devices.py", line 47, in <module>
    from distutils.version import StrictVersion
ModuleNotFoundError: No module named 'distutils'``

    尝试解决：
    - 去安装python的这个模块

        ``cc@ccMac-mini ~ % pip3 install distutils
        ERROR: Could not find a version that satisfies the requirement distutils (from versions: none)
ERROR: No matching distribution found for distutils``
        
        这里表示pip3无法找到这个模块，可能是在python标准库当中无需再添加(因为这个模块是python的标准库之一)，也可能是python安装环境出现异常可能需要重新安装，下面进行排查，我的python是否有。首先，去查看python当中是否包含了这个模块，通过在命令行执行`python -回车- import distutils`，发现报错`Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
ModuleNotFoundError: No module named 'distutils'`，说明没有这个模块，我通过执行`which python`查找到python的安装地址：`/opt/homebrew/bin/python`，进入这个地址在这个目录下`find . -name distutils`确定了并没有发现这个模块。

    - 卸载python
  
        因为是在homebrew当中安装的python，直接执行`brew uninstall python`即可卸载。可实际上卸载出错：`Error: Refusing to uninstall /opt/homebrew/Cellar/python@3.12/3.12.3
because it is required by cairo, glib, harfbuzz, openjdk@11, openjdk@17 and virtualenvwrapper, which are currently installed.
You can override this and force removal with:
  brew uninstall --ignore-dependencies python`

      因为有依赖，所以不要卸载了，重新安装一个python3.11吧

    - 安装python3.11

         `brew search python`

         `brew install python@3.11`       

         现在需要将我们python链接到这个3.11，现在通过python -V或者是python --version返回的是12

         查阅资料说的是macOS在根目录下修改，.zshrc文件，添加export += /opt/homebrew/bin/python@3.11

         结束之后需要重新开一个命令终端(听说直接source .zshrc也是可以的，但是我是重新开了一个终端)，因为这个影响的是全局，所以可能需要重启。我执行之后再次执行python --version发现展现出的python版本还是12，并且我的.zshrc文件当中只有jdk17和这个新加入的python12，我执行echo $PATH查看本机的环境，发现了除了这两个之外还有很多其他的，我不知道这些是哪里来的，但是这里只有我们设置的python11，并没有影响到我们python执行。

         查阅资料发现是我们python这个关键字与python3.12进行关联了，所以需要解除关联，将其与python3.11进行关联。

         执行sudo rm /opt/homebrew/bin/python

         执行sudo ln -s /opt/homebrew/bin/python3.11 /opt/homebrew/bin/python

         此时再次查看python版本会发现是3.11了，再次检测是否python3.11拥有distutils模块

         执行python  import distutils，发现没有报错。ok

## 最终解决主要修改的文件
[修改的qt和python源码文件](https://github.com/neochin-john/install-qt-5.15.2-on-mac)

## 小提示
在qt当中手动正确添加qt版本，则qt creator会自动检测构建套件

其余的错误，不能正确识别模拟器？不能运行桌面的？都是可以在上面的链接进行解决