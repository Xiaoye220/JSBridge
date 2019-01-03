# JustBridge

![pod](https://img.shields.io/badge/pod-4.2.0-brightgreen.svg)
![iOS](https://img.shields.io/badge/iOS-8.0-green.svg)
![lisence](https://img.shields.io/badge/license-MIT-orange.svg)
![swift](https://img.shields.io/badge/swift-4.2-red.svg)



An iOS bridge for sending messages between Swift and JavaScript in WKWebView 

## ScreenShot

![Screenshots](https://github.com/Xiaoye220/EmptyDataSet-Swift/blob/master/JSBridge/ScreenShot/ScreenShot.gif)

## CocoaPods

```
use_frameworks!
pod 'JustBridge', '~> 4.2.0'
```

## Usage

JustBridge is easy to use. Just init a bridge  and then register handler or call handler.

1. import JustBridge and declare an ivar property:

```swift
import JustBridge
```

...

```swift
var bridge: JustBridge!
```

2. Instantiate JustBridge with a WKWebView:

```swift
bridge = JustBridge(with: webView)
```

3. Register a handler in Swift, and call a JavaScript handler

   * the `errorMessage` can be `HandlerNotExistError` or `DataIsInvalidError` , type of `errorMessage` is String

   * `callback` and `errorCallback` can be nil

```swift
bridge.register("swiftHandler") { (data, callback) in
    print("[js call swift] - data: \(data ?? "nil")\n")
	callback("[response from swift] - response data: I'm swift response data")
}

bridge.call("jsHandler", data: data, callback: { responseData in
    print(responseData ?? "have no response data")
}, errorCallback: { errorMessage in
    print(errorMessage)
})
```

4. Register a handler in JavaScript, and call a Swift handler
   *  the errorMessage can only be `HandlerNotExistError` , type of errorMessage is String
   * `callback` and `errorCallback` can be null

```js
window.bridge.register("jsHandler", function(data, callback) {
    console.log("[swift call js] - data: " + JSON.stringify(data));
    callback("[response from js] - response data: I'm js response data");
});

window.bridge.call("swiftHandler", "hello world from js", function(responseData) {
    console.log(responseData.toString())
}, function(errorMessage) {
    console.log("error: " + errorMessage)
});
```

## Excample

You can clone or download this project for more details.