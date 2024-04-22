## UIDocumentPickerViewController

[UIDocumentPickerViewController官方文档](https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller?language=objc)

简介：一个控制器，用于提供对应用沙盒之外的文档或目标的访问

### Creating a document picker

创建文档选取器

- initWithCoder：从指定取消存档程序中的数据返回初始化的对象
- initForExportingURLs：创建并返回一个文档选取器，该选取器可以导出指定的文档类型
- initFoeExportingURLs:asCopy：创建并返回一个文档选取器，该选取器可以导出或赋值指定的文档类型
- initForOpeningContentTypes：创建并返回一个文档选取器，该选取器可以打开指定的文档类型
- initForOpeningContentTypes:asCopy：创建并返回一个文档选取器，该选取器可以打开或复制指定的文档类型

**暂时使用的是initForOpeningContentTypes:asCopy:**

### Getting the user-selected document

获取用户选取的文件

- delegate：作为试图控制器委托的对象
- UIDocumentPickerDelegate：用于跟踪用户何时选择文档或目标或取消操作的方法
- allowsMultipleSelection：Boolean值，用于确定用户是否可以一次选择多个文档
- directoryURL：文档选取器显示的初始目录

**directoryURL很重要**

我们就是通过事先制作好URL，再为directoryURL赋值

```objective-c
NSURL *directoryURL = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject];

// ...这里已经使用initForOpeningContentTypes创建了UIDocumentPickerViewController对象
// ...同样也delegate了
documentPickerViewController.directoryURL = directoryURL
```

这里解释一下首行：

首行的作用是创建一个NSURL对象，用于表示app的文档目录的url。

- `fileURLWithPath`是NSURL类的方法，用于根据给定的文件路径创建一个NSURL对象。

- `NSSearchPathForDirectoriesInDomains`是一个函数，用于获取指定文件夹在沙盒中的路径。

- `NSDocumentDirectory`是一个枚举值，表示文档目录。
- `NSUserDomainMask`是一个枚举值，表示从用户的主目录中搜索。
- `YES`表示是否展开波浪号~来代表用户主目录。
- 这个函数的返回值是一个数组，在某些情况下，可能会有多个文档目录。但是在iOS中，通常只有一个文档目录，所以我们可以通过`.firstObject`来获取数组中的第一个元素，即文档目录的路径。

这里我们可以看到NSSearchPathForDirectoriesInDomains指定了文件夹在沙盒中的路径，同理我们可以更改这个函数，得到其他路径！

- `NSDocumentDirectory`：文档目录，用于存放用户生成的文档。
- `NSLibraryDirectory`：Library 目录，用于存放程序的默认设置或其他状态信息。
- `NSCachesDirectory`：Caches 目录，用于存放程序运行时生成的缓存文件。
- `NSApplicationSupportDirectory`：Application Support 目录，用于存放应用程序的支持文件。
- `NSDownloadsDirectory`：Downloads 目录，用于存放下载的文件。

```objective-c
	// 当前目录
	NSURL *directoryURL = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject];
	// 进入的是Test01文件夹
    NSURL *directoryURL = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject];
	// 下载目录--"The file “Downloads” couldn’t be opened because there is no such file."
    NSURL *directoryURL = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES).firstObject];
```

这里的`.firstObject`也可以使用 `objectAtIndex:0`来代替，查看打印该数组的大小发现是1，1是正确的，因为这里是访问的Library文件夹，Library文件夹就是只有一个的。

```objective-c
	// 这里是打印数组的大小
	NSArray *directories = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSUInteger count = [directories count];
    NSLog(@"Array size: %lu", (unsigned long)count);
```



```objective-c
NSString *homeDirectory = NSHomeDirectory();

//使用这个可以访问到当前用户的主目录路径，正确的应该类似：  /var/mobile/Containers/Data/Application/<UUID>/
// 因为在模拟器环境中，应用的主目录路径会被设置为模拟器的数据路径。
// Home Directory Path: /Users/leo/Library/Developer/CoreSimulator/Devices/9CBA42D5-43DB-4A56-8A68-850A5ADD0D93/data/Containers/Data/Application/9D6BDDC8-B064-4EC7-AFA4-82AC92C4CFFD
```



相关资料：[NSURL](https://developer.apple.com/documentation/foundation/nsurl?language=objc)

