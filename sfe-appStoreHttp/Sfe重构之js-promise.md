## Sfe重构之js-promise
- 链接：[学习分享js-pormoise](https://github.com/tongzhou-renju/knowledge-share/blob/master/qt/js-promise/js-pormise.md)
- 目的：不写success&failure函数，使用then和catch来取代

#### 举例：
- old

在AppStore的函数为

```js
// Api
function getServiceDetails(appStoreId, success, failure) {
    let url = "/app_store/application/" + appStoreId
    return Sfe.Http.get(url, success, failure)
} 

// 调用处
function success(resp) {
    //...处理success
}
function failure() {
    //...处理failure
}
Api.AppStore.getServiceMsg(appStoreId, success, failure)
```
- new
```js
// Api
function getServiceDetails(appStoreId) {
    let url = "/app_store/application/" + appStoreId
    return Sfe.Http.get(url)
} 

// 调用处
Api.AppStore.getServiceDetails(appStoreId).then(resp => {
    //...处理success
}).catch(e => /*...处理failure*/)
```