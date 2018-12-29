//
//  JSBridge.swift
//  JSBridge
//
//  Created by YZF on 2018/12/27.
//

import UIKit
import WebKit

public class JSBridge: NSObject {
    
    /// The js that need inject to webView at dom start
    internal static let bridge_js: String = {
        let bundlePath = Bundle(for: JSBridge.self).path(forResource: "JSBridge", ofType: "bundle")!
        let bundle = Bundle.init(path: bundlePath)!
        let jsPath = bundle.path(forResource: "bridge", ofType: "js")!
        let js = try! String(contentsOfFile: jsPath)
        return js
    }()
    
    /// data can be array, dictinary, string, number...
    public typealias JSBridgeData = Any?
    public typealias Callback = (_ responseData: JSBridgeData) -> Void
    public typealias Handler = (_ data: JSBridgeData, _ callback: Callback) -> Void
    
    private var handlers: [String: Handler] = [:]
    private var callbacks: [String: Callback] = [:]
    private var swiftCallbackId = 0
    
    private var webview: WKWebView
    
    public init(with webView: WKWebView) {
        self.webview = webView
        super.init()
        
        self.webview.configuration.userContentController.add(self, name: "bridge")
        self.injectBridgeJS()
    }

    
    /// Register a handler
    /// Handler will be invoked when js call this handler
    ///
    /// - Parameters:
    ///   - name: handler unique name
    ///   - handler: closures can be invoked when js call this handler name
    public func register(_ name: String, handler:@escaping Handler) {
        self.handlers[name] = handler
    }
    
    /// Remove a handler
    ///
    /// - Parameter name: handler unique name
    public func remove(_ name: String) {
        self.handlers.removeValue(forKey: name)
    }
    
    
    /// Call a js handler
    ///
    /// - Parameters:
    ///   - name: js handler name
    ///   - data: the data will be post to js handler as a paramter
    ///   - callback: callback from js
    public func call(_ name: String, data: JSBridgeData, callback: Callback?) {
        let id = String(swiftCallbackId)
        swiftCallbackId += 1
        self.callbacks[id] = callback
        self.callJS(name, data: data, swiftCallbackId: id)
    }
}

extension JSBridge {
    
    private func injectBridgeJS() {
        let script = WKUserScript(source: JSBridge.bridge_js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        self.webview.configuration.userContentController.addUserScript(script)
    }
    
    private func callJS(_ name: String, data: JSBridgeData, swiftCallbackId: String? = nil, jsCallbackId: String? = nil) {
        var message = [String: Any]()
        message["name"] = name
        message["data"] = data
        message["swiftCallbackId"] = swiftCallbackId
        message["jsCallbackId"] = jsCallbackId

        if let messageJSONData = try? JSONSerialization.data(withJSONObject: message, options: JSONSerialization.WritingOptions()),
            let messageJSON = String(data: messageJSONData, encoding: .utf8) {
            self.webview.evaluateJavaScript("window.bridge.callFromSwift(\(messageJSON));", completionHandler: nil)
        }
    }
    
}

extension JSBridge: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        
        let data = body["data"]
        
        if let swiftCallbackId = body["swiftCallbackId"] as? String {
            let callback = callbacks[swiftCallbackId]
            callback?(data)
        } else {
            if let name = body["name"] as? String {
                let handler = handlers[name]
                handler?(data) { responseData in
                    if let jsCallbackId = body["jsCallbackId"] as? String {
                        callJS(name, data: responseData, jsCallbackId: jsCallbackId)
                    }
                }
            }
        }

    }
    
}



