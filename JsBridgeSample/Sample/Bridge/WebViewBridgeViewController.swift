//
//  WebViewBridgeViewController.swift
//  JsBridgeSample
//
//  Created by ClintJang on 2018. 7. 9..
//  Copyright © 2017년 ClintJang. All rights reserved.
//

import Foundation
import WebKit
import SwiftyJSON

/**
 The "WKWebView" test screen controller class iamplemented in the language "swift".
 - class : SwiftWKWebViewController
 */
final class WebViewBridgeViewController : UIViewController {
    private var processor: WebViewMessageProcessor!
    @IBOutlet weak var safeAreaContainerView: UIView!
    private var webView: WKWebView!

    private struct Constants {
        static let callBackHandlerKey = "wadInterface"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupProcessor()
        // initializes
        setupView()

        loadURL()
    }

    func setupProcessor() {
        self.processor = WebViewMessageProcessor(target: self)
    }

    func popView() {
        webView.removeFromSuperview();
    }

    func executeJavaScript(javascriptString: String?) {
      guard let javascriptString = javascriptString else { return }
        self.webView.evaluateJavaScript(javascriptString, completionHandler: nil)
    }
}

// MARK:- Private
private extension WebViewBridgeViewController {
    func setupView() {
        // Bridge Setting
        let userController: WKUserContentController = WKUserContentController()

        userController.add(self, name: Constants.callBackHandlerKey)
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userController

        // Default WebView Setting
        self.webView = WKWebView(frame:self.safeAreaContainerView.bounds, configuration: configuration)
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.translatesAutoresizingMaskIntoConstraints = false

        self.safeAreaContainerView.addSubview(self.webView)

        // WKWebView Layout Setting
        // Constraints like "UIWebView" are set.
        // This is a sample. If you are developing, use a library called "SnapKit".
        // https://github.com/SnapKit/SnapKit
        let margins = safeAreaContainerView.layoutMarginsGuide
        webView.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
    }

    func loadURL() {
//        guard let url = URL(string: "http://localhost:4200") else {
//            return
//        }
        
        guard let  url = Bundle.main.url(forResource: "sampleBridge", withExtension: "html") else {
            return
        }
        let request = URLRequest(url: url)
        self.webView.load(request)
    }
}
// MARK: - WKScriptMessageHandler
extension WebViewBridgeViewController : WKScriptMessageHandler {
    // MARK: - 웹뷰 -> 네이티브 받는 영역
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("toNative:\(message.body)")

        guard let body = message.body as? [String: Any] else { return }
        let json = JSON(body)
        let message = WebViewMessage(json: json)
        self.processor.postMessage(message: message)
    }
}

// MARK: - WKUIDelegate
extension WebViewBridgeViewController : WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("\(#function)")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)

        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler()
        }))

        self.present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        print("\(#function)")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)

        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler(true)
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))

        self.present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        print("\(#function)")

        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: UIAlertController.Style.alert)

        alertController.addTextField { (textField) in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }

        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in

            completionHandler(nil)
        }))

        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - WKNavigationDelegate
extension WebViewBridgeViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error)
    {
        print("\(#function)")
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!)
    {
        print("\(#function)")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
    {
        print("\(#function)")
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error)
    {
        print("\(#function)")
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("\(#function)")

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("\(#function)")
        decisionHandler(.allow)
    }
}


