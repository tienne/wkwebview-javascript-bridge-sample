import Foundation
import SwiftyJSON

class WebViewMessageProcessor: NSObject {

    private var target: WebViewBridgeViewController

    init(target: WebViewBridgeViewController) {
        self.target = target
        super.init()
        self.load()
    }

    func load() {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            self?.triggerEvent(eventName: "appStateChange", args: JSON([ "isActive": true]))
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            self?.triggerEvent(eventName: "appStateChange", args: JSON([ "isActive": false]))
        }
    }

    func postMessage(message: WebViewMessage) {
        let completion: (WebViewCallback) -> Void = { callback in
          self.executeCallback(callbackId: message.callbackId, callback: callback)
        }
        guard let action = message.webviewAction else {
          return
        }

        self.execute(action: action, completion: completion)
    }

    private func execute(action: WebViewAction, completion: ((WebViewCallback) -> Void)? = nil) {
        switch action {
        case .appVersion:
            self.appVersion(completion: completion)
        case .navigationPop:
            self.popView(completion: completion)
        }
    }

    private func popView(completion: ((WebViewCallback) -> Void)? = nil) {
        self.target.popView()
        completion?(WebViewCallback(isSuccessful: true))
    }

    private func appVersion(completion: ((WebViewCallback) -> Void)? = nil) {
        var callback: WebViewCallback {
            var args = JSON()
            args["version"].string = "1.0.0";
            return .init(args: args, isSuccessful: true)
        }

        completion?(callback)
    }

    // MARK: - 네이티브에서 이벤트로 호출하는 영역
    func triggerEvent(eventName: String, args: JSON) {
        let argsString = args.rawString(options: []) ?? ""
        let eventFunction = "wadInterface.fromNativeEvent(\"\(eventName)\", \(argsString));"

        self.target.executeJavaScript(javascriptString: eventFunction)
    }

    // MARK: - 웹뷰 -> 네이티브 -> 웹뷰 처리하는 콜백 실행
    func executeCallback(callbackId: String?, callback: WebViewCallback) {
      print(callbackId)
      guard let callbackId = callbackId else { return }
      let argsString = callback.args.rawString(options: []) ?? ""
      let callbackFunction = "wadInterface.fromNative(\(callbackId), \(callback.isSuccessful), \(argsString));"
      self.target.executeJavaScript(javascriptString: callbackFunction)
    }
}
