## 访问iOS相册

相关链接：

[PhotoKit](https://developer.apple.com/documentation/photokit/)

[UImagePickerControllor](https://developer.apple.com/documentation/uikit/uiimagepickercontroller)

对比这两个，PhotoKit比UImagePickerControllor更加强大，提供更多的功能和更精细的控制，比如说能够让用户选择只选择哪些图片让其app访问(很多app其实支持这个操作)。

如果是只选择系统的图片来说，后者要比前者更好实现更简单。这里先用后者实现保底

```objective-c
NativeResultReceiver* Native::pickImage()
{
    qDebug() << "调用iOS原生选择图片";

    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:imagePickerController animated:YES completion:nil];

    // 返回结果接收器
    PickResultReceiver *receiver = new PickResultReceiver(PickResultReceiver::PICK_IMAGE);
    return receiver;
}
```



