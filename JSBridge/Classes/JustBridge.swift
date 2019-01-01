//
//  JustBridge.swift
//  JustBridge
//
//  Created by YZF on 2018/12/27.
//

import UIKit
import WebKit

public class JustBridge: NSObject {
    
    /// data can be array, dictinary, string, number, null
    public typealias BridgeData = Any?
    
    /// the key for messages between Swift and JavaScript
    private struct MessageKey {
        static let name = "name"
        static let data = "data"
        static let swiftCallbackId = "swiftCallbackId"
        static let jsCallbackId = "jsCallbackId"
        static let error = "error"
    }
    
    public enum BridgeError: String {
        case HandlerNotExistError
        case DataIsInvalidError
    }
    
    /// The js that need inject to webView at dom start
    internal static let bridge_js: String = {
        let bundlePath = Bundle(for: JustBridge.self).path(forResource: "JSBridge", ofType: "bundle")!
        let bundle = Bundle.init(path: bundlePath)!
        let jsPath = bundle.path(forResource: "bridge", ofType: "js")!
        let js = try! String(contentsOfFile: jsPath)
        return js
    }()
    
    public typealias ErrorCallback = (_ error: BridgeError) -> Void
    public typealias Callback = (_ responseData: BridgeData) -> Void
    public typealias Handler = (_ data: BridgeData, _ callback: Callback) -> Void
    
    private var handlers: [String: Handler] = [:]
    private var callbacks: [String: Callback] = [:]
    private var errorCallbacks: [String: ErrorCallback] = [:]
    
    /// unique id for callback
    private var callbackId = 0
    
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
    public func call(_ name: String, data: BridgeData, callback: Callback? = nil, errorCallback: ErrorCallback? = nil) {
        let id = String(callbackId)
        callbackId += 1
        self.callbacks[id] = callback
        self.errorCallbacks[id] = errorCallback
        self.postMessage(name, data: data, swiftCallbackId: id)
    }
}

extension JustBridge {
    
    private func injectBridgeJS() {
        let script = WKUserScript(source: JustBridge.bridge_js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        self.webview.configuration.userContentController.addUserScript(script)
    }
    
    private func postMessage(_ name: String, data: BridgeData, swiftCallbackId: String? = nil, jsCallbackId: String? = nil, error: String? = nil) {
        var message = [String: Any]()
        message[MessageKey.name] = name
        message[MessageKey.data] = data
        message[MessageKey.swiftCallbackId] = swiftCallbackId
        message[MessageKey.jsCallbackId] = jsCallbackId
        message[MessageKey.error] = error

        // handle error when data is not array, dictinary, string, number, null
        if !JSONSerialization.isValidJSONObject(message) && (swiftCallbackId != nil) {
            errorCallbacks[swiftCallbackId!]?(BridgeError.DataIsInvalidError)
            return
        }
        
        if let messageJSONData = try? JSONSerialization.data(withJSONObject: message, options: []),
            let messageJSON = String(data: messageJSONData, encoding: .utf8) {
            self.webview.evaluateJavaScript("window.bridge.receiveMessage(\(messageJSON));", completionHandler: nil)
        }
    }
    
}

extension JustBridge: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        
        let data = body[MessageKey.data]
        
        if let swiftCallbackId = body[MessageKey.swiftCallbackId] as? String {
            
            // handle error when the value for key 'error' is not nil
            if let error = body[MessageKey.error] as? String {
                let errorCallback = errorCallbacks[swiftCallbackId]
                errorCallback?(BridgeError(rawValue: error)!)
            } else {
                // else it's callback from js
                let callback = callbacks[swiftCallbackId]
                callback?(data)
            }
        } else {
            if let name = body[MessageKey.name] as? String, let jsCallbackId = body[MessageKey.jsCallbackId] as? String {
                if let handler = handlers[name] {
                    handler(data) { responseData in
                        postMessage(name, data: responseData, jsCallbackId: jsCallbackId)
                    }
                } else {
                    // if there is not a handler, send a error message
                    postMessage(name, data: nil, jsCallbackId: jsCallbackId, error: BridgeError.HandlerNotExistError.rawValue)
                }
            }
        }

    }
    
}



