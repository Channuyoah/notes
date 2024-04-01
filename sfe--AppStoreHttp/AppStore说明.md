## AppStore.js

该文件的主要作用是处理关于AppStore的http请求，这里我会对重要的思想和内容还有与遇到的坑进行说明，添加代码的注释。

看这个代码需要搭配HttpService.js来搭配使用，因为其中使用的一些函数，还有一些方法，一些继承均可以调用HttpService.js的内容。可以将AppStore.js看作为HttpService.js的另一个"简易"版本的实现。

#### 走一遍逻辑:
1、首先调用获取服务列表的api  --> 当点击`Me`页面的服务按钮跳转到`AppService.qml`，在其ListModel加载完毕的时候会响应`Component.onCompleted`事件，在这个事件当中分别定义一个`function success()`和一个`function failure()`，之后再使用`Api.AppStore.getServiceMsg(success, failure)`去调用这个api。(思考1.回调函数success传入的resp)
2、`AppStore.js`的`getServiceMsg`函数内自行拼接好url之后会调用get方法(这里是调用同步还是异步，传参方式等，使用get/post等方法需要看接口是如何定义的。思考2.get参数有4个但是只传入了三个参数，会有什么影响)，
x、在`ServiceListItem.qml`当中抛信号(思考x.为什么需要在qml当中以抛信号的方式来调用服务器的api)

#### 思考解答
###### 1、成功返回之后调用的success函数功能，理解回调函数，如何使用这个回调函数来得到我们想要的数据
###### 2、get参数有4个但是只传入了三个参数，会有什么影响
答: 
 这里就没有将agrs这个参数传过去，如果少传一个参数的话，JavaScript会尝试解析这个参数，由于没有传递该参数，所以将为`undefined`，这样会解析失败，但是我们设置了当args为空或者是undefined时将timeout设置为5000，但是最后的args还是未定义的。
###### x、为什么需要在qml当中以抛信号的方式来调用服务器的api?
答: 
  因为这个`ServciceListItem`是一个公共组件，这个按钮的点击事件需要触发不同的响应事件，所以在这里定义不同的信号，在另外的调用这个公共组件的地方响应其对应的信号就行了。
  以这里的文件为例，这个按钮分别需要响应两个事件，一个是详情(需要调用的api为`appstore_list`)，一个是购买(需要调用的api为`appstore_detail`)，在其对应的文件中响应对应的信号即可。