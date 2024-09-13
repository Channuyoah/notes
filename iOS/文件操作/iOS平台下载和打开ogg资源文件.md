## iOS平台下载和打开ogg资源文件

#### 正确流程

这里的正确运行流程是依据Android的正确运行为参考

在`Chat.qml`当中有函数`downloadAndOpenFile(url)`函数

```js
    function downloadAndOpenFile(url) {
        // 这里的url是oss服务器资源url
        let decodedUri = decodeURIComponent(url)
        let filename = decodedUri.substring(decodedUri.lastIndexOf('/') + 1)
        let filepath = $native.downloadFilepath(filename)
        if ($native.downloadFileExists(filepath)) {
            // 若是成功打开则会return
            $native.viewPdf(filepath)
            return
        }

        showLoading(qsTr("Download"))
        var reply = $req.downloadFile(url, filepath)
        if (!reply) {
            // url同上，filepath是存在本地的地址
            // 不能打开的时候会走这里，debug打印并且在手机上输出提示信息
            hideLoading()
            C.Log.debug("can not write file")
            notify(qsTr("Failed to write file"), "error")
            downloadDialog.close()
            return
        }

        reply.downloadProgress.connect(function(recv, total) {
            // 下载的时候走的这里进行连接
            hideLoading()
            downloadDialog.open()
            downloadDialog.setValue("Downloading", recv, total)
        })
        reply.finished.connect(function() {
            // 下载完成
            hideLoading()
            downloadDialog.close()
            C.Log.debug("download success, try open file")
            $native.viewPdf(filepath)
        })
    }
```

在这里发现最后执行的都是$native的，所以不同平台应该是选择不同的native类来调用，在这里很容易发现sfe项目的native文件夹下有三个类，Native、Native_Android、Native_General，那么我们应该在这里创建一个属于iOS的Native处理类。

### 当前项目处理pdf文件的流程(Windows为例)

#### 上传(打开本地文件夹目录，选择文件并上传到服务器)

xxx

---

#### 下载(服务器已有资源--点击消息记录从服务器下载并打开)

先走`Chat.qml`的`downloadAndOpenFile(url)`函数，调用对应平台的`downloadFileExists(filepath)`函数再调用QFile::exists函数调用我们自己的downloadFilepath(filename)-->返回的是下载目录和文件名合并成的完整文件路径，掉一部分QFile::exists()函数检查文件是否存在于该路径，是则调用viewPdf(filepath)，return

如果文件没有存在于该路径，说明本地是没有的，所以这个时候要去下载：执行`HttpRequest.cpp`的downloadFile函数，其返回值是HttpReply对象。该函数会单例化一个Native对象去执行其openFile(filepath, QIODevice::WriteOnly)函数.

Native::openFile函数

```cpp
QFile* Native::openFile(const QString &filepath, QIODevice::OpenMode openMode)
{
    // 检测filepath是否以file://开头，是则说明是一个URL格式的路径，将其转化为本地文件路径
    // 如果不是则表明是本地路径，无需转换
    QString localPath = filepath.startsWith("file://")
        ? QUrl(filepath).toLocalFile() : filepath;
    QFile *file = new QFile(localPath);
    // 以openMode方式来打开这个file文件
    if (!file->open(openMode))
    {
        qDebug() << "failed to open file " << localPath;
        delete file;
        return nullptr;
    }

    // 成功打开，返回指向QFile对象的指针
    return file;
}
```

这里我使用Android会提示用什么方式打开(应该是默认没有设置pdf打开方式)，Windows则会用用户默认设置的pdf阅读器将其打开。iPhone会出现写文件失败弹窗。

分析原因，可能是download不知道将其下载到哪里了，所以执行openFile的时候打不开这个找不到的文件。通过打印输出发现又是去这里查找的文件：`/Users/leo/Library/Developer/CoreSimulator/Devices/CCAEEE60-4D83-40F2-B6A7-4EBC5348E702/data/Containers/Data/Application/A067635D-9F15-47C9-9D3E-FD207DA52EE5/Documents/Downloads/02545456-00573B30.pdf`

所以是下载的路径有问题，通过反查Chat.qml文件发现是在调用downloadAndOpenFile(url)函数的时候 filepath是有问题的(在iOS平台)，正好这个let filepath = $native.downloadFilepath(filename)，这里是执行不同的native，所以需要在native_ios当中定制化这个downloadFilepath函数使之能够将服务器的文件下载到正确的本地/沙盒。---这里尝试在native_ios当中重写这个函数，让其走





思考：现在是能够选择iOS的本地文件(打开的是本地的下载目录)，则这样可以正确选择文件上传到服务器。那么既然能够选择文件，就能拿到这个文件的地址，可以尝试将聊天中的文件上传到这个目录！尝试一下。

通过从 `accepted()` 槽函数得到的选择的路径`file:///Users/leo/Library/Developer/CoreSimulator/Devices/CCAEEE60-4D83-40F2-B6A7-4EBC5348E702/data/Containers/Data/Application/7D767BBE-D95D-4DDD-B1FC-125424754F51/tmp/com.sfe.sfe-mobile-Inbox/02545456.pdf"`

这个 URL 是选择的文件在本地文件系统中的路径，是一个本地文件系统路径，指向模拟器中的临时目录中的文件。那应该存放也存放到这个目录下，将Native.cpp的downloadDir中的下载路径设置为`QStandardPaths::DocumentsLocation`，即可正确的下载到这个路径，并且能够正确访问到。

https://doc.qt.io/qt-5/qstandardpaths.html#StandardLocation-enums

现在报错新的内容: 是无法打开这个pdf文件，报错信息：`This plugin does not support QPlatformServices::openDocument() for 'xxxpath/xx.pdf'`

现在尝试去修改对应平台调用的viewpdf函数，先打印输出一下，看看点击的时候是不是调用了这个函数，没错，好，现在先去创建一个Native_iOS类，模仿general来写一个处理iOS平台的文件操作并且继承Native类。

