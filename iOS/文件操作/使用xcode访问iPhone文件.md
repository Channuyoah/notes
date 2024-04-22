## 使用xcode访问iPhone文件

[查找objective类/方法](https://developer.apple.com/documentation/technologies?language=objc)

### 目标：

1、实验在xcode当中创建一个iOS项目来访问iPhone上的文件

2、成功之后尝试将项目移植到Qt当中成功运行

### 相关链接：

[使用NSURL对象](https://developer.apple.com/documentation/foundation/nsurl?language=objc)

NSURL通常处理的是URL，提供一种统一的方式来表示文件、目录以及其他资源的位置。

通常用于获取文件和目录的 URL，并将其传递给其他类和方法进行进一步的处理，如网络请求、文件下载等。

[使用Foundation]()

Foundation类提供了更多与文件和目录直接相关的功能，如读取和写入文件内容、管理文件和目录、处理文件权限等。

这些文件操作类可以直接操作文件内容和文件系统，包括创建、复制、移动、删除文件和目录等。

[File System](https://developer.apple.com/documentation/foundation/file_system?language=objc)

Create，read，write，and examine files and folders in the file system.

[Uniform Type Identifiers](https://developer.apple.com/documentation/uniformtypeidentifiers?language=objc)

提供描述存储或传输文件类型的统一类型标识符。

### 开始实验

[UIViewController类]()

1、使用ViewController类

```objective-c
// .h文件
#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@end
```

---

在头文件当中已经声明了ViewController继承自UIViewController类，此时在.m文件当中再`@interface ViewController () <UIDocumentPickerDelegate>`表明我们的ViewController类不仅继承UIViewController类还遵循UIDocumentPikcerDelegate协议，相当于是在.m文件当中对ViewController类进行了扩展，让其同时具有视图控制器和文档选择器的功能。

在头文件当中声明类的遵守协议通常是为了让其他文件(比如其他类的实现文件)知道该类所支持的协议。在.m文件中使用类扩展来进一步声明遵循协议和实现协议中的方法，是为了确保该类的对象能够正确地响应和处理协议中定义的行为。

---

[关于Button样式](https://developer.apple.com/documentation/uikit/uibutton?language=objc)

注意：iOS设备上的文件访问是受到沙盒机制限制的。应用程序只能访问自己的沙盒目录下的文件和目录(并且不能够基于当前沙盒目录访问其上级目录)，不能直接访问系统文件或者其他应用程序的文件(貌似我将地址写死之后能够访问我创建的目录)。

```objective-c
// .m文件
#import "ViewController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface ViewController () <UIDocumentPickerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 我的iPhone
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    button1.frame = CGRectMake(100, 100, 200, 50); // 参数分别为x,y,w,h
    [button1 setTitle:@"选择我的iPhone文件..." forState:UIControlStateNormal]; // 设置按钮标题
    [button1 addTarget:self action:@selector(buttonClicked1:) forControlEvents:UIControlEventTouchUpInside]; // 添加按钮点击事件
    [self.view addSubview:button1]; // 将按钮添加到视图当中
    

// 选择我的iPhone文件
- (void)buttonClicked1:(UIButton *)sender {
    NSLog(@"选择iPhone文件");
    
    // 创建文档选择器
    NSArray<UTType *> *contentTypes = @[
        [UTType typeWithFilenameExtension:@"txt"],
        [UTType typeWithFilenameExtension:@"pdf"],
        [UTType typeWithFilenameExtension:@"*"]
    ];

    // 方式一 这里访问的是上下文的路径，并不是我们指定的路径，但是第一次打开的时候默认打开app目录
    UIDocumentPickerViewController *documentPickerViewController = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:contentTypes asCopy:true];
    
    // 这里设置打开app目录

    documentPickerViewController.delegate = self;
    documentPickerViewController.modalPresentationStyle = UIModalPresentationFullScreen; // 设置模态展示风格
    
    // 弹出文档选择器
    [self presentViewController:documentPickerViewController animated:YES completion:nil];
}
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSLog(@"Picked documents at URLs: %@", urls);
    
    // 在这里处理选择的文件，例如打开或读取文件内容
    // 这里只是简单打印文件的URL
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    NSLog(@"Document picker was cancelled");
}

@end
```

```objective-c
    // 方式一 访问上下文的路径，并不是指定的路径，但是第一次打开的时候默认打开app目录
    UIDocumentPickerViewController *documentPickerViewController = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:contentTypes asCopy:true];

	// 方式二  访问指定目录，该目录为绝对目录
    NSURL *directoryURL = [NSURL fileURLWithPath:@"/Users/leo/Library/Developer/CoreSimulator/Devices/9CBA42D5-43DB-4A56-8A68-850A5ADD0D93/data/Containers/Shared/AppGroup/"];	

	// 方式三 访问沙盒目录下的文件目录
	NSURL *directoryURL = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject];

	// 方式2 3 共用
    documentPickerViewController.delegate = self;
    documentPickerViewController.directoryURL = directoryURL; // 设置起始目录的 URL
```



#### 现在可以打开指定目录和沙盒目录下的文件目录，下一步尝试不使用绝对url的方式来访问指定的文件目录

目标：点击按钮访问`我的 iPhone --> Test01`文件夹

说明：以当前项目`LoadFileTest`为例，上级目录是`我的 iPhone`，现在要访问这个目录下的Test01

尝试：使用UIDocumentPickerViewController类

成功：使用NSLibarayDirectory

相关链接：

[UIDocumentPickerViewController官方文档](https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller?language=objc)



找app单独文件

找iCloud文件