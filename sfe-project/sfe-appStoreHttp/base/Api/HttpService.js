
.pragma library

.import Common 1.0 as C
.import Sfe 1.0 as Sfe

C.Log.init("api-HttpService", C.Log.LogLevel.DEBUG)

// 测试使用字段
var testReqId = 0
function mockResponse(data) {
    testReqId++

    function mockTokenInvalid() {
        if (testReqId === 4) {
            data.status = 0
            data.msg = "token失效"
        }
    }

    function mockRefreshTokenInvalid() {
        if (testReqId >= 4) {
            data.status = 0
            data.msg = "token失效"
        }
    }

    // 要测试哪个功能，就打开下面那个函数
    // mockTokenInvalid()
    // mockRefreshTokenInvalid()
}

const App = {
    token: () => $user.token,
    refreshToken: () => $user.refreshToken,
    tokenRefreshedRet: {
        timestamp: 0,
        success: true,
    },
    setRefreshToken: function(token, refreshToken) {
        this.tokenRefreshedRet.timestamp = Date.now()

        if (token && refreshToken) {
            $user.token = token
            $user.refreshToken = refreshToken
            $user.save()
            this.tokenRefreshedRet.success = true
        } else {
            this.tokenRefreshedRet.success = false
        }
    },
    needRefreshToken: function() {
        let tsDiff = Date.now() - this.tokenRefreshedRet.timestamp
        return tsDiff > 10000 // 10s之后才允许重新更新
    },
    lastRefreshTokenSuccess: function() {
        return this.tokenRefreshedRet.success
    },

    applyReSignIn: (reason) => $user.applyReSignIn(reason),

    ggVersion: () => $app.ggVersion,
    version: () => $app.version,
    platform: () => $app.platform,
}

const ContentType = {
    FORM: "application/x-www-form-urlencoded",
    JSON: "application/json"
}

const MethodType = {
    GET: "GET",
    POST: "POST",
    PUT: "PUT",
    DELETE: "DELETE"
}

// https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
const HttpStatus = {
    is2xx: status => status >=  200 && status < 300
}

// 可以只传url路径，自动补全域名等。减少Sfe.Http.url()的使用
function completeUrl(url) {
    return url.startsWith("http") ? url : Sfe.Http.url(url)
}

function setHeader(xhr, key, value) {
    // value为字符串, 不考虑value = 0等情况
    if (value) {
        xhr.setRequestHeader(key, value)
    }
}

function Request(args) {
    let {url, async = true, method = MethodType.GET,
         headers = {}, params, contentType,
         callback, timeout = 0, timeoutCallback} = args

    this.url = completeUrl(args.url)
    this.async = async
    this.method = method
    this.headers = headers
    this.params = typeof(params) === "object" ? JSON.stringify(params) : params
    this.contentType = contentType
    this.callback = callback
    this.timeout = timeout
    this.timeoutCallback = timeoutCallback

    // 保存xhr的返回信息，xhr.reponse只能读一次，这里读出来后方便后续多次使用
    this.response = {}
}

// req会缓存请求返回数据，所以，它不适合返回数据量很大的请求
Request.prototype.handleResponse = function(xhr) {
    let contentType = xhr.getResponseHeader("Content-Type")
    let status = xhr.status
    let data = xhr.response

    // 如果是json返回，就解析成js对象
    // 在异步xhr方法中，可以使用xhr.responseType = "json"控制对象类型, 但同步方法不行
    // https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/responseType#synchronous_xhr_restrictions
    if (contentType.includes(ContentType.JSON)) {
        try {
            C.Log.debug("RESP:", data)
            data = JSON.parse(data)

            // 测试打桩使用
            mockResponse(data)
        } catch (e) {
            C.Log.error("Failed to parse json response", data)
        }
    }

    this.response = {contentType, status, data}
}

function timerQml(timeout){
    return ("  import QtQuick 2.15;"
            + "Timer {"
            + "    interval: " + timeout + ";"
            + "    repeat: false;"
            + "    running: true;"
            + "}")
}

Request.prototype.request = function() {
    C.Log.debug("HTTP:", JSON.stringify(this))

    let xhr = new XMLHttpRequest()
    xhr.open(this.method, this.url, this.async)
    setHeader(xhr, "Content-Type", this.contentType)
    Object.entries(this.headers).map(([k, v]) => setHeader(xhr, k, v))

    function asyncProc() {
        // https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/timeout.
        // Timeout shouldn't be used for synchronous XMLHttpRequests
        // requests used in a document environment or it will throw
        // an InvalidAccessError exception.

        let timer = null
        if (this.timeout > 0) {
            timer = Qt.createQmlObject(timerQml(this.timeout),
                                       Qt.application, "")
            timer.triggered.connect(function() {
                xhr.abort()
                this.response.status = 0
                this.response.data = {}
                if (this.timeoutCallback) {
                    C.Log.warn("TIMEOUT", this.url)
                    this.timeoutCallback()
                }

                timer.destroy()
            }.bind(this))
        }

        xhr.onload = function() {
            this.handleResponse(xhr)
            if (this.callback) {
                this.callback(this)
            }

            if (timer) {
                timer.destroy()
            }
        }.bind(this)

        xhr.onerror = function() {
            this.response.status = xhr.status
            this.response.data = {}
            if (this.callback) {
                this.callback(this)
            }

            if (timer) {
                timer.destroy()
            }

        }.bind(this)

        xhr.send(this.params)
        return this
    }

    function syncProc() {
        xhr.send(this.params)
        this.handleResponse(xhr)
        return this
    }

    (this.async ? asyncProc : syncProc).call(this)
}

// 继承Request, Sfe加强版request(), 适配Sfe Api。
// 使用不同callback，可以控制是否自动刷新token
function SfeRequest(args) {
    args.headers = Object.assign({"token": App.token(),
                                  "client_version": App.ggVersion()},
                                  args.headers || {})
    Request.call(this, args)

    // this.response是xhr的结果
    // this.sfeResponse是解析Sfe接口JSON返回的结果
    this.sfeResponse = {}
}

SfeRequest.prototype = Object.create(Request.prototype)
SfeRequest.prototype.constructor = SfeRequest

function isTokenInvalid(req) {
    // 目前后端错误码处理不规范，没有直接指明token失效的错误码,
    // 这里的判断是一种临时规避方案, 如果后端有错误，返回错误类似如下:
    // {
    //     "status": 0,
    //     "msg": "请求成功，token已失效"
    // }
    let data = req.response.data
    return data.status === 0 && data.msg && data.msg.includes("token")
}

// 刷新token流程中需要使用同步的方法
function syncRefreshToken() {
    let url = "/eggi_admin/admin/refresh_token"
    let params = {refresh_token: App.refreshToken()}
    let req = new Request({url, params, async: false,
                           method: MethodType.POST,
                           contentType: ContentType.JSON})
    req.request()
    if (!HttpStatus.is2xx(req.response.status)) {
        // 刷新最近token更新时间
        App.setRefreshToken()
        return false
    }

    if (isTokenInvalid(req)) {
        // 刷新最近token更新时间
        App.setRefreshToken()
        App.applyReSignIn(qsTr("Auth is invalid, Please re sign in"))
        return false
    }

    let respData = req.response.data.data
    App.setRefreshToken(respData.token, respData.refresh_token)
    return true
}


// 返回说明
// true: 更新了token，外部调用者可以重试原来的请求
// false: 没有更新token或者更新失败，外部调用者不需要再重试请求
function checkAndRefreshToken(req) {
    if (!isTokenInvalid(req)) {
        return false
    }

    // 注意逻辑炸弹:
    // 虽然当前js只运行在主线程（GUI线程）中，是单线程的。但由于js v8 engine事件处理
    // 有类似于协程的并发机制，所以可能有多个http请求返回了token失效，然后在事件队列中，
    // 就有多个当前函数等待执行, 造成反复刷token的情况。如果前一个函数已经更新了token，
    // 无论成功失败，现在都没有必要再更新token了。另外，调用refresh token的函数要用
    // 同步函数，否则也会打破这里的条件判断意图，形成竞争条件。
    if (!App.needRefreshToken() && App.lastRefreshTokenSuccess()) {
        // 用最近更新的token重新请求
        return true
    }

    // 注意上下文，要使用同步的token更新函数
    if (App.needRefreshToken() && !syncRefreshToken()) {
        // 更新失败，返回老的请求结果
        return false
    }

    return true
}

const SfeErrCode = {
    OK: 0,
    HTTP: 1,
    TIMEOUT: 2,
    API: 3,
    INNER: 4,
}

function handleSfeResponse(req) {
    let resp = req.response
    if (!HttpStatus.is2xx(resp.status)) {
        req.sfeResponse.status = SfeErrCode.HTTP
        req.sfeResponse.msg = qsTr("Request error: ") + resp.status
        return req.sfeResponse
    }

    let data = resp.data
    // 目前后台api成功返回1
    if (data.status !== 1) {
        req.sfeResponse.status = SfeErrCode.API
        req.sfeResponse.msg = data.msg || qsTr("Unknown error")
        return req.sfeResponse
    }

    // 有时返回不只有status/msg/data字段，所以使用data的数据
    // 同时，不想影响req.response.data.status等内容，所以做个浅拷贝
    req.sfeResponse = Object.assign({}, data, {status: SfeErrCode.OK})
    return req.sfeResponse
}

function handleSfeResponseWithTokenRefresh(req) {
    let isTokenRefreshed = checkAndRefreshToken(req)
    if (!isTokenRefreshed) {
        return handleSfeResponse(req)
    }

    req.headers.token = App.token()
    req.sfeResponse = {}
    req.response = {}
    req.request()
    return handleSfeResponse(req)
}

function sfeCallback(success, failure) {
    function callback(req) {
        let resp = handleSfeResponse(req)
        if (resp.status === SfeErrCode.OK) {
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

function sfeCallbackWithTokenRefresh(success, failure) {
    function callback(req) {
        let isTokenRefreshed = checkAndRefreshToken(req)
        let callbackWithoutTokenRefresh = sfeCallback(success, failure)
        if (!isTokenRefreshed) {
            callbackWithoutTokenRefresh(req)
            return
        }

        // 重试请求, 重试的请求不需要自动刷新token
        req.sfeResponse = {}
        req.response = {}
        req.callback = callbackWithoutTokenRefresh
        req.request()
    }

    return callback
}

function sfeTimeout(failure) {
    function callback() {
        if (failure) {
            failure({status: SfeErrCode.TIMEOUT,
                     msg: qsTr("Request timeout. Please try later")})
        }
    }

    return callback
}

function get(url, success, failure, args) {
    let {timeout = 5000} = args || {}
    let req = new SfeRequest({url, method: MethodType.GET,
        callback: sfeCallbackWithTokenRefresh(success, failure),
        timeout: timeout, timeoutCallback: sfeTimeout(failure)})

    req.request()
}

function syncGet(url) {
    let req = new SfeRequest({url, method: MethodType.GET, async: false})
    req.request()
    return handleSfeResponseWithTokenRefresh(req)
}

function post(url, params, success, failure, args) {
    let {timeout = 5000} = args || {}
    let req = new SfeRequest({url, method: MethodType.POST,
        params: "data=" + JSON.stringify(params),
        contentType: ContentType.FORM,
        callback: sfeCallbackWithTokenRefresh(success, failure),
        timeout: timeout, timeoutCallback: sfeTimeout(failure)})
    req.request()
}

function syncPost(url, params) {
    let req = new SfeRequest({url, method: MethodType.POST,
                              params: "data=" + JSON.stringify(params),
                              contentType: ContentType.FORM,
                              async: false})
    req.request()
    return handleSfeResponseWithTokenRefresh(req)
}

function postJson(url, params, success, failure, args) {
    let {timeout = 5000} = args || {}
    let req = new SfeRequest({url, method: MethodType.POST,
        params, contentType: ContentType.JSON,
        callback: sfeCallbackWithTokenRefresh(success, failure),
        timeout: timeout, timeoutCallback: sfeTimeout(failure)})
    req.request()
}

function syncPostJson(url, params) {
    let req = new SfeRequest({url, method: MethodType.POST,
                              params, contentType: ContentType.JSON,
                              async: false})
    req.request()
    return handleSfeResponseWithTokenRefresh(req)
}

function putJson(url, params, success, failure, args) {
    let {timeout = 5000} = args || {}
    let req = new SfeRequest({url, method: MethodType.PUT,
        params, contentType: ContentType.JSON,
        callback: sfeCallbackWithTokenRefresh(success, failure),
        timeout: timeout, timeoutCallback: sfeTimeout(failure)})
    req.request()
}

function syncPutJson(url, params) {
    let req = new SfeRequest({url, method: MethodType.PUT,
                              params, contentType: ContentType.JSON,
                              async: false})
    req.request()
    return handleSfeResponseWithTokenRefresh(req)
}

function postJsonWithRsa(url, params, args) {
    let {timeout = 5000} = args || {}
    let headers = {"sign": $ssl.rsa256Sign(JSON.stringify(params))}
    let req = new SfeRequest({url, method: MethodType.POST,
        params, headers, contentType: ContentType.JSON,
        // 不自动刷新token
        callback: sfeCallback(success, failure),
        timeout: timeout, timeoutCallback: sfeTimeout(failure)})
    req.request()
}

function syncPostJsonWithRsa(url, params) {
    let headers = {"sign": $ssl.rsa256Sign(JSON.stringify(params))}
    let req = new SfeRequest({url, method: MethodType.POST, params,
                              headers, headers, contentType: ContentType.JSON,
                              async: false})
    req.request()

    // 不自动刷新token
    return handleSfeResponse(req)
}

function asyncDelete(url, success, failure, args) {
    let {timeout = 5000} = args || {}
    let req = new SfeRequest({url, method: MethodType.DELETE,
        contentType: ContentType.JSON,
        callback: sfeCallbackWithTokenRefresh(success, failure),
        timeout: timeout, timeoutCallback: sfeTimeout(failure)})
    req.request()
}

function syncDelete(url, success, failure) {
    let req = new SfeRequest({url, method: MethodType.DELETE,
                              contentType: ContentType.JSON,
                              async: false})
    req.request()
    return handleSfeResponseWithTokenRefresh(req)
}
