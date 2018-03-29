# JS-OC-Swift
JS和OC/Swift相互调用,主要总结了JS和OC交互的三种方式

1.使用UIWebView,利用**JavaScriptCore**实现

2.使用WKWebView，利用**WKScriptMessageHandler**实现

3.使用第三方框架[WebViewJavascriptBridge](https://github.com/marcuswestin/WebViewJavascriptBridge)实现

## JavaScriptCore

在Swift中获取JS的context

``` 
context = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as? JSContext
```

注入JS需要的对象，对象命名与html中使用的保持一致.`self`是遵守了JSExport协议,也可是其他遵守协议的对象。

```
context?.setObject(self, forKeyedSubscript:  "OC" as NSCopying & NSObjectProtocol)
```
JS调用Swift的方法，在Swift中实现协议

```
@objc protocol JSDelegate :JSExport {
    //包含参数的func,需要注意参数名对函数名称的影响
    func showMessageToYou(_ message:String)
    
    /*
     对应html中“showAAndB”,此方法包含两个参数，需要在参数前加“_”
     func showA(_ aString: String, andB: String)
     func showAAndB(_ aString:String,_ bStr:String)
     以上两个方法等同
     */
    func showAAndB(_ aString:String,_ bStr:String)
    
    func doActionCallBack()
}
```
Swift调用JS的方法

```
let jsStr = String(format:"callback('%@')",(textField?.text)!)
self.context?.evaluateScript(jsStr)
```
OC中可使用block和实现JSExport协议两种方式实现，代码实现：

```
JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
self.context = context;
//注入JS需要的“OC”对象,该对象与html中的保持一致即可
self.context[@"OC"] = self;
```

## WKScriptMessageHandler

初始化WKWebView后,添加供js调用oc/Swift的桥梁，这里的name对应WKScriptMessage中的name

```
webView.configuration.userContentController.add(_ scriptMessageHandler: WKScriptMessageHandler, name: String)
```
遵守协议WKScriptMessageHandler，实现以下方法，可实现JS把消息发送给OC/Swift。

```
func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage)
```
OC/Swift调用JS

```
let jsStr = String(format:"callback('%@')",(textField?.text)!)
self.webView.evaluateJavaScript(jsStr as String, completionHandler: { (result:Any?, error:Error?) in
       print("error:",error as Any)
 })
```
## WebViewJavascriptBridge

初始化WKWebViewJavascriptBridge

```
self.webViewBridge = [WKWebViewJavascriptBridge bridgeForWebView:self.webView];
[self.webViewBridge setWebViewDelegate:self];
```
JS调用OC需要注册事件

```
[self.webViewBridge registerHandler:@"handlerName" handler:^(id data, WVJBResponseCallback responseCallback) {
   //code
}];
```
OC调用JS

```
[self.webViewBridge callHandler:@"handlerName" data:@[textField.text] responseCallback:^(id responseData) {
        NSLog(@"%@",responseData);
 }];
```
html中需要放置以下代码

```
/*这段代码是固定的，必须要放到js中*/
function setupWebViewJavascriptBridge(callback) {
    if (window.WebViewJavascriptBridge) { return callback(WebViewJavascriptBridge); }
    if (window.WVJBCallbacks) { return window.WVJBCallbacks.push(callback); }
    window.WVJBCallbacks = [callback];
    var WVJBIframe = document.createElement('iframe');
    WVJBIframe.style.display = 'none';
    WVJBIframe.src = 'wvjbscheme://__BRIDGE_LOADED__';
    document.documentElement.appendChild(WVJBIframe);
    setTimeout(function() { document.documentElement.removeChild(WVJBIframe) }, 0)
}
/*与OC交互的所有JS方法都要放在此处注册，才能调用通过JS调用OC或者让OC调用这里的JS*/
setupWebViewJavascriptBridge(function(bridge) {
     bridge.registerHandler('callback', function(data, responseCallback) {
        callback(data);
        responseCallback('js执行过了'+data);
    })
})
```
