//
//  ViewController.swift
//  JSBridge
//
//  Created by Xiaoye220 on 12/27/2018.
//  Copyright (c) 2018 Xiaoye220. All rights reserved.
//

import UIKit
import WebKit
import JustBridge

let topHeight = UIApplication.shared.statusBarFrame.height + 44
let screenHeight = UIScreen.main.bounds.height
let screenWidth = UIScreen.main.bounds.width

class ViewController: UIViewController {
    
    var webView: WKWebView!
    var bridge: JustBridge!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let barButtonItem = UIBarButtonItem(title: "Swift Call", style: .plain, target: self, action: #selector(swiftCallJS))
        self.navigationItem.rightBarButtonItem = barButtonItem

        webView = WKWebView(frame: CGRect(x: 0, y: topHeight, width: screenWidth, height: screenHeight - topHeight))
        webView.scrollView.isScrollEnabled = false
        view.addSubview(webView)
        
        bridge = JustBridge(with: webView)
        bridge.register("swiftHandler") { (data, callback) in
            print("[js call swift] - data: \(data ?? "nil")\n")
            let responseData = "I'm swift response data"
            callback("[response from swift] - response data: \(responseData)")
        }
        
        let htmlString = try! String(contentsOfFile: Bundle.main.path(forResource: "index", ofType: "html")!)
        webView.loadHTMLString(htmlString, baseURL: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func swiftCallJS() {
        self.present(self.alertVC, animated: true, completion: nil)
    }
    
    func bridgeCall(_ data: Any?, withCallBack: Bool) {
        if withCallBack {
            bridge.call("jsHandler", data: data, callback: { responseData in
                print(responseData ?? "have no response data")
            }, errorCallback: { errorMessage in
                print(errorMessage)
            })
        } else {
            bridge.call("jsHandler", data: data)
        }
    }
    
    func bridgeCallNotExistHandler() {
        bridge.call("xxx", data: nil, callback: nil) { error in
            print("error: \(error)")
        }
    }
    
    lazy var alertVC: UIAlertController = {
        let alertVC = UIAlertController(title: "Swift Call JS", message: nil, preferredStyle: .actionSheet)
        let alertAction_1 = UIAlertAction(title: "swift call without data", style: .default) { [unowned self] _ in
            self.bridgeCall(nil, withCallBack: false)
        }
        let alertAction_2 = UIAlertAction(title: "swift call with string", style: .default) { [unowned self] _ in
            self.bridgeCall("hello world from swift", withCallBack: false)
        }
        let alertAction_3 = UIAlertAction(title: "swift call with dictionary", style: .default) { [unowned self] _ in
            self.bridgeCall(["key": "value"], withCallBack: false)
        }
        let alertAction_4 = UIAlertAction(title: "swift call with array", style: .default) { [unowned self] _ in
            self.bridgeCall(["value1", "value2"], withCallBack: false)
        }
        let alertAction_5 = UIAlertAction(title: "swift call with callback", style: .default) { [unowned self] _ in
            self.bridgeCall("hello world from swift", withCallBack: true)
        }
        let alertAction_6 = UIAlertAction(title: "swift call not exist handler", style: .default) { [unowned self] _ in
            self.bridgeCallNotExistHandler()
        }
        let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
        alertVC.addAction(alertAction_1)
        alertVC.addAction(alertAction_2)
        alertVC.addAction(alertAction_3)
        alertVC.addAction(alertAction_4)
        alertVC.addAction(alertAction_5)
        alertVC.addAction(alertAction_6)
        alertVC.addAction(cancelAction)
        return alertVC
    }()

}

