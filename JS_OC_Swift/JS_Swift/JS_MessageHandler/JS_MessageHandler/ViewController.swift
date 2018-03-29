//
//  ViewController.swift
//  JS_MessageHandler
//
//  Created by xinyu on 2018/3/28.
//  Copyright © 2018年 MaChat. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController,WKUIDelegate,WKNavigationDelegate,WKScriptMessageHandler {

   weak var webView :WKWebView!
   weak var progressView :UIProgressView!
    
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        //显示加载进度条
        setupProgressView()
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        webView.configuration.userContentController.add(self, name: "showMessageAction")
        webView.configuration.userContentController.add(self, name: "showTitleAndMessageAction")
        webView.configuration.userContentController.add(self, name: "doSomethingThenCallBackAction")
       
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "showMessageAction")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "showTitleAndMessageAction")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "doSomethingThenCallBackAction")
    }
    
    func setupWebView () {
        let config = WKWebViewConfiguration.init()
        let wkUController = WKUserContentController.init()
        config.userContentController = wkUController
        webView = WKWebView.init(frame: .zero, configuration: config)
        webView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        view.addSubview(webView)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "index.html", ofType: nil)!)
        webView.loadFileURL(url, allowingReadAccessTo: url)
        
    }
   
    func setupProgressView () {
        let sWidth = UIScreen.main.bounds.width
        let pre = UIProgressView(frame: CGRect(x: 0, y: 0, width: sWidth, height: 2))
        progressView = pre
        progressView.tintColor = UIColor.blue
        progressView.trackTintColor = UIColor.lightGray
        view.addSubview(progressView)
    }
    
    //MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if webView.isEqual(object) && keyPath == "estimatedProgress" {
            let newprogress = change?[NSKeyValueChangeKey.newKey] as! Float
          
            if newprogress == Float("1") {
                progressView.setProgress(1.0, animated: true)
                DispatchQueue.main.asyncAfter(deadline:.now() + 0.7, execute: {
                    DispatchQueue.main.async {
                        self.progressView.isHidden = true
                        self.progressView.setProgress(0, animated: true)
                    }
                })
            } else {
                progressView.isHidden = false
                progressView.setProgress(newprogress, animated: true)
            }
            
        }
    }
    //MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
         // JS 调用OC 方法  传递一个参数
        if message.name == "showMessageAction" {
            showAlertControlelr(title: "提示", message: message.body as! String)
        }
        // JS 调用OC 方法  传递多个参数
        if message.name == "showTitleAndMessageAction" {
            let dict : NSDictionary = message.body as! NSDictionary
            let title = dict.value(forKey: "title")
            let content = dict.value(forKey: "content")
            showAlertControlelr(title: title as! String, message: content as! String)
        }
        
        if  message.name == "doSomethingThenCallBackAction" {
            let alert = UIAlertController(title: "提示", message: nil, preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "请输入传送的数据"
                textField.addTarget(self, action: #selector(self.textFieldChange(textField:)), for:.editingChanged)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancel)
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                let textField = alert.textFields?.first
                // OC 调用JS 方法  并传递参数
                let jsStr = String(format:"callback('%@')",(textField?.text)!)
                self.webView.evaluateJavaScript(jsStr as String, completionHandler: { (result:Any?, error:Error?) in
                    print("error:",error as Any)
                })
            }
            alert.addAction(okAction)
            okAction.isEnabled = false
            self.present(alert, animated: true, completion: nil)
        }
    }
    //MARK: -
    @objc func textFieldChange(textField:UITextField) {
        let alert = presentedViewController as! UIAlertController
        let okAction = alert.actions.last
        let count = textField.text!.count
        if (count > 0) {
            okAction?.isEnabled = true
        } else {
            okAction?.isEnabled = false
        }
    }
    
    func showAlertControlelr(title:String , message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
}

