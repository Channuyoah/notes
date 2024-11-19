.pragma library

.import Common 1.0 as C
.import Sfe 1.0 as Sfe
.import "HttpService.js" as HttpService

C.Log.init("api-AppStore", C.Log.LogLevel.DEBUG)

const App = {
    appStoreToken: () => $user.appStoreToken,
    tokenUpdateRet: {
        timestamp: 0,
        success: true,
    },
    setUpdateToken: function(appStoreToken) {
        this.tokenUpdateRet.timestamp = Date.now()

        if (appStoreToken) {
            $user.appStoreToken = appStoreToken
            $user.save()
            this.tokenUpdateRet.success = true
        } else {
            this.tokenUpdateRet.success = false
        }
    },
    needUpdateToken: function() {
        let tsDiff = Date.now() - this.tokenUpdateRet.timestamp
        return tsDiff > 10000 // 10s之后才允许重新更新
    },
    lastUpdateTokenSuccess: function() {
        return this.tokenUpdateRet.success
    },
}

const AppStoreHttpStatus = {
    isGte400: status => status >= 400
}

function completeUrl(url) {
    return url.startsWith("http") ? url : Sfe.Http.appStoreUrl(url)
}

function AppStoreRequest(args) {
    args.headers = Object.assign({"token": App.appStoreToken()},
                                  args.headers || {})
    args.url = completeUrl(args.url)
    HttpService.Request.call(this, args)

    this.appStoreResponse = {}
}

AppStoreRequest.prototype = Object.create(HttpService.Request.prototype)
AppStoreRequest.prototype.constructor = AppStoreRequest

function isTokenInvalid(req) {
    // 目前后端错误码处理不规范，没有直接指明token失效的错误码,
    // 目前错误码和接口的状态码一致
    let data = req.response.data
    return AppStoreHttpStatus.isGte400(data.code)
}

// 刷新token流程中需要使用同步的方法
function syncUpdateToken() {
    let url = completeUrl("/api/tk_store/get_token")
    let params = {user_id: $user.ggUid, platform: "guigui"}
    let req = new HttpService.Request({url, params, async: false,
        method: HttpService.MethodType.POST, contentType: HttpService.ContentType.JSON})
    req.request()

    if (isTokenInvalid(req)) {
        // 刷新最近token更新时间
        App.setUpdateToken()
        return false
    }

    let token = req.response.data.result.token
    App.setUpdateToken(token)
    return true
}

// 返回说明
// true: 更新了token，外部调用者可以重试原来的请求
// false: 没有更新token或者更新失败，外部调用者不需要再重试请求
function checkAndUpdateToken(req) {
    if (!isTokenInvalid(req)) {
        return false
    }

    // 注意逻辑炸弹:
    // 虽然当前js只运行在主线程（GUI线程）中，是单线程的。但由于js v8 engine事件处理
    // 有类似于协程的并发机制，所以可能有多个http请求返回了token失效，然后在事件队列中，
    // 就有多个当前函数等待执行, 造成反复刷token的情况。如果前一个函数已经更新了token，
    // 无论成功失败，现在都没有必要再更新token了。另外，调用update token的函数要用
    // 同步函数，否则也会打破这里的条件判断意图，形成竞争条件。
    if (!App.needUpdateToken() && App.lastUpdateTokenSuccess()) {
        // 用最近更新的token重新请求
        return true
    }

    // 注意上下文，要使用同步的token更新函数
    if (App.needUpdateToken() && !syncUpdateToken()) {
        // 更新失败，返回老的请求结果
        return false
    }

    return true
}

function handleAppStoreResponse(req) {
    let resp = req.response
    if (AppStoreHttpStatus.isGte400(resp.status)) {
        req.appStoreResponse.status = HttpService.SfeErrCode.HTTP
        req.appStoreResponse.msg = qsTr("Request error: ") + resp.status
        return req.appStoreResponse
    }

    let data = resp.data
    req.appStoreResponse = Object.assign({}, data, {status: HttpService.SfeErrCode.OK})
    return req.appStoreResponse
}

function handleAppStoreResponseWithTokenUpdate(req) {
    let isTokenUpdate = checkAndUpdateToken(req)
    if (!isTokenUpdate) {
        return handleAppStoreResponse(req)
    }

    req.appStoreResponse = {}
    req.response = {}
    req.request()
    return handleAppStoreResponse(req)
}

function appStoreCallback(success, failure) {
    function callback(req) {
        let resp = handleAppStoreResponse(req)
        if (!AppStoreHttpStatus.isGte400(resp.status)) {
            if (success) {
                success(resp)
            }
        } else {
            if (failure) {
                failure(resp)
            }
        }
    }

    return callback
}

function appStoreCallbackWithTokenUpdate(success, failure) {
    function callback(req) {
        let isTokenUpdate = checkAndUpdateToken(req)
        let callbackWithoutTokenUpdate = appStoreCallback(success, failure)
        if (!isTokenUpdate) {
            callbackWithoutTokenUpdate(req)
            return
        }

        // 重试请求, 重试的请求不需要自动刷新token
        req.headers.token = App.appStoreToken()
        req.appStoreResponse = {}
        req.response = {}
        req.callback = callbackWithoutTokenUpdate
        req.request()
    }

    return callback
}

function get(url, success, failure, args) {
    let {timeout = 5000} = args || {}
    let req = new AppStoreRequest({url, args, method: HttpService.MethodType.GET,
        callback: appStoreCallbackWithTokenUpdate(success, failure),
        timeout: timeout, timeoutCallback: HttpService.sfeTimeout(failure)})

    req.request()
}

function postJson(url, params, success, failure, args) {
    let {timeout = 5000} = args || {}
    let req = new AppStoreRequest({url, method: HttpService.MethodType.POST,
        params, contentType: HttpService.ContentType.JSON,
        callback: appStoreCallbackWithTokenUpdate(success, failure),
        timeout: timeout, timeoutCallback: HttpService.sfeTimeout(failure)})
    req.request()
}

// https://api.thinkerx.com/web/#/205/10709
function getServiceMsg(success, failure) {
    let url = "/api/tk_store/appstore_list?type=service"
    get(url, success, failure)
}

// https://api.thinkerx.com/web/#/205/10727
function getServiceDetails(appStoreId, versionId, success, failure) {
    let url = "/api/tk_store/appstore_detail?appstore_id="
        + appStoreId + "&version_id=" + versionId
    get(url, success, failure)
}
