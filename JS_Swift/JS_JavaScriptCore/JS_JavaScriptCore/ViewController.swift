//
//  ViewController.swift
//  JS_JavaScriptCore
//
//  Created by xinyu on 2018/3/27.
//  Copyright © 2018年 MaChat. All rights reserved.
//

import UIKit
import JavaScriptCore

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

class ViewController: UIViewController,UIWebViewDelegate,JSDelegate {

    let webView = UIWebView.init(frame: .zero)
    var context : JSContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        view.addSubview(self.webView)
        webView.delegate = self
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        let request = NSURLRequest(url:URL(fileURLWithPath: Bundle.main.path(forResource: "index", ofType: "html")!))
        webView.loadRequest(request as URLRequest)
        webView.backgroundColor = UIColor.black
    }
    //MARK: - UIWebViewDelegate
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        context = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as? JSContext
        //设置异常处理
        context?.exceptionHandler = { (context, exception) in
            print("exception：", exception as Any)
        }
        //注入JS需要的“OC”对象,该对象与html中的保持一致即可
        context?.setObject(self, forKeyedSubscript:  "OC" as NSCopying & NSObjectProtocol)
    }
    
    //MARK: - JSDelegate
    func showMessageToYou(_ message: String) {
        showAlertControlelr(title: "问候", message: message)
    }
    
    func showAAndB(_ aString: String, _ bStr: String) {
        //OC 调用 JS
        let callBack = context?.objectForKeyedSubscript("alertCallback")
        callBack?.call(withArguments: [aString,bStr])
    }
 
    func doActionCallBack() {        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "提示", message: nil, preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "请输入传送的数据"
                textField.addTarget(self, action: #selector(self.textFieldChange(textField:)), for:.editingChanged)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancel)
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                let textField = alert.textFields?.first
                //OC 调用JS
                let jsStr = String(format:"callback('%@')",(textField?.text)!)
                self.context?.evaluateScript(jsStr)
                
            }
            alert.addAction(okAction)
            okAction.isEnabled = false
            self.present(alert, animated: true, completion: nil)
        }
    }
    //MARK: - 
    func showAlertControlelr(title:String , message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
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
}

