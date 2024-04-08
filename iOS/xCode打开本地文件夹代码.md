# ViewController.h文件

```objective-c
//
//  ViewController.h
//  LoadFileTest
//
//  Created by neochin on 2024/4/7.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@end
```



# ViewController.m文件

```objective-c
//
//  ViewController.m
//  LoadFileTest
//
//  Created by neochin on 2024/4/7.
//

#import "ViewController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <MobileCoreServices/MobileCoreServices.h>

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
    
    // iCloud云盘
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    button2.frame = CGRectMake(100, 200, 200, 50);
    [button2 setTitle:@"选择iCloud文件..." forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(buttonClicked2:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
    
    // 选择图片
    UIButton *button3 = [UIButton buttonWithType:UIButtonTypeSystem];
    button3.frame = CGRectMake(100, 300, 200, 50);
    [button3 setTitle:@"选择图片..." forState:UIControlStateNormal];
    [button3 addTarget:self action:@selector(buttonClicked3:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button3];
}

- (void)buttonClicked1:(UIButton *)sender {
    NSLog(@"选择iPhone文件");
    
    // 指定起始目录的 URL
//    NSURL *directoryURL = [NSURL fileURLWithPath:@"/Users/leo/Library/Developer/CoreSimulator/Devices/9CBA42D5-43DB-4A56-8A68-850A5ADD0D93/data/Containers/Shared/AppGroup/"];	
//    NSURL *directoryURL = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject];
//    NSURL *directoryURL = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject];
    NSURL *directoryURL = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
    
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSUInteger count = [directories count];
    NSLog(@"Array size: %lu", (unsigned long)count);
    
    NSString *homeDirectory = NSHomeDirectory();
    NSLog(@"Home Directory Path: %@", homeDirectory);
    
    // 创建文档选择器
    NSArray<UTType *> *contentTypes = @[
        [UTType typeWithFilenameExtension:@"txt"],
        [UTType typeWithFilenameExtension:@"pdf"],
        [UTType typeWithFilenameExtension:@"*"]
    ];
    UIDocumentPickerViewController *documentPickerViewController = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:contentTypes asCopy:true];
    documentPickerViewController.delegate = self;
    documentPickerViewController.directoryURL = directoryURL; // 设置起始目录的 URL

    documentPickerViewController.modalPresentationStyle = UIModalPresentationFullScreen; // 设置模态展示风格
    
    // 弹出文档选择器
    [self presentViewController:documentPickerViewController animated:YES completion:nil];
}

// 选择iCloud文件
- (void)buttonClicked2:(UIButton *)sender {
    NSLog(@"选择iCloud文件");
    
    // 创建文档选择器
    NSArray<UTType *> *contentTypes = @[ ];
    
    UIDocumentPickerViewController *documentPickerViewController = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:contentTypes asCopy:YES];
    documentPickerViewController.delegate = self;
    [self presentViewController:documentPickerViewController animated:YES completion:nil];
}

// 选择图片
- (void)buttonClicked3:(UIButton *)sender {
    NSLog(@"选择图片");
    
    // 创建图片选择器
    NSArray<UTType *> *contentTypes = @[];
    
    UIDocumentPickerViewController *documentPickerViewController = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:contentTypes asCopy:true];
    documentPickerViewController.delegate = self;
    [self presentViewController:documentPickerViewController animated:true completion:nil];
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

# main.m文件

```objective-c
//
//  main.m
//  LoadFileTest
//
//  Created by neochin on 2024/4/7.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "ViewController.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        NSLog(@"Hello World~!");
        
        // 创建应用程序委托对象
        AppDelegate *appDelegate = [[AppDelegate alloc] init];
        appDelegateClassName = NSStringFromClass([appDelegate class]);
        
        if (!appDelegateClassName) {
            NSLog(@"Error: Unable to get app delegate class name");
            return 1;
        }
        
        // 创建一个 UIWindow对象
        UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        
        // 创建按钮实例
        ViewController *viewController = [[ViewController alloc] init];
        
        // 将视图控制器的视图设置为 UIWindow 的根视图
        window.rootViewController = viewController;
        
        // 显示窗口
        [window makeKeyAndVisible];
        
        // 启动应用程序
        return UIApplicationMain(argc, argv, nil, appDelegateClassName);
    }
}
```

