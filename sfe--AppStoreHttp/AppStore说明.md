## AppStore.js

该文件的主要作用是处理关于AppStore的http请求，这里我会对重要的思想和内容还有与遇到的坑进行说明，添加代码的注释。

看这个代码需要搭配HttpService.js来搭配使用，因为其中使用的一些函数，还有一些方法，一些继承均可以调用HttpService.js的内容。可以将AppStore.js看作为HttpService.js的另一个"简易"版本的实现。
