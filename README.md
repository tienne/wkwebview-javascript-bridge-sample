# sample swift wkwebview javascript bridge 

```
WKWebview로 javascirpt bridge 하는 방식을 셈플링했습니다.

★ 웹(프론트) → 네이티브
예전에는 UIWebView에서 연동시 기존에는 URL에 스키마를 정의해서 내려받은 스킴정보를 이용해서 파싱해서 처리했었습니다.
WKWebView에서는 추가적으로 javascript bridge를 사용해서 편하게 로직 처리를 할 수 있는 방법이 있습니다. 

★ 네이티브 → 웹(프론트)
웹(프론트) → 네이티브 로 전달방식은 추가된 방식이 있지만, 
네이티브 → 웹(프론트) 로 전달/처리 방식은 기존에 자바스크립트 함수를 호출하던 1가지(evaluatejavascript) 그대로 입니다.

아래는 그 기능들에 대한 셈플링을 해봤습니다. 
```

# 설명

## WKWebView 셋팅

`wadInterface` 이름으로 WKUserContentController 를 셋팅합니다.

```swift
// Sample/Bridge/WebviewBridgeViewController.swift

final class WebViewBridgeViewController : UIViewController {
    private var processor: WebViewMessageProcessor!
    private var webView: WKWebView!

    private struct Constants {
        static let callBackHandlerKey = "wadInterface"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    func setupProcessor() {
        self.processor = WebViewMessageProcessor(target: self)
    }
    //...
}


private extension WebViewBridgeViewController {
    func setupView() {
        // Bridge Setting
        let userController: WKUserContentController = WKUserContentController()
        
        userController.add(self, name: Constants.callBackHandlerKey)
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userController
        
        // Default WebView Setting
        self.webView = WKWebView(frame:self.safeAreaContainerView.bounds, configuration: configuration)
        // ...
    }
    
    //...
}
```

## 웹뷰 -> 네이티브 호출

아래와 같이 웹뷰에서 네이티브로 호출시 메세지를 핸들링하는 처리를 합니다.

```swift
// Sample/Bridge/WebviewBridgeViewController.swift 
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
```

샘플 코드에서 주고받는 메세지 포멧은 아래와 같습니다.
```json5
{
  "callbackId": "액션의 결과를 넘겨줄 callbackId",
  "action": "액션이름",
  "actionArgs": {} // 액션 호출시 필요한 파라미터(액션마다 스펙이 달라집니다.)
}
```

호출에 대한 결과값을 넘겨줘야하는 경우 아래와 같이 다시 웹뷰로 전달합니다.
웹뷰로 다시 전달할때는 위에서 셋팅했던 WKUserContentController 이름(`wadInterface`)으로 `fromNative` 함수를 실행하면 됩니다.

```swift
// Sample/Bridge/WebviewBridgeViewController.swift

final class WebViewBridgeViewController : UIViewController {
    //...
    
    func executeJavaScript(javascriptString: String?) {
      guard let javascriptString = javascriptString else { return }
        self.webView.evaluateJavaScript(javascriptString, completionHandler: nil)
    }
    
    //...
}

// Sample/Bridge/WebViewMessageProcessor.swift
import SwiftyJSON

class WebViewMessageProcessor: NSObject {
    // MARK: - 웹뷰 -> 네이티브 -> 웹뷰 처리하는 콜백 실행
    func executeCallback(callbackID: String?, callback: WebViewCallback) {
      guard let callbackID = callbackID else { return }
      let argsString = callback.args.rawString(options: []) ?? ""
      let callbackFunction = "wadInterface.fromNative(\(callbackID), \(callback.isSuccessful), \(argsString));"

      self.target.executeJavaScript(javascriptString: callbackFunction)
    }
}
```

### fromNative 함수 스펙

```js
var wadInterface = {
  //...

  /**
   * 네이티브에서 커맨드를 실행한 후, 네이티브 코드가 호출한다.
   * @param {number} callbackID - 실행할 때 네이티브에 전송했던 콜백 아이디
   * @param {boolean} isSuccess - 커맨드가 성공적으로 실행되었는지 여부
   * @param {Object} args - 네이티브에서 전송하는 JSON 객체
   */
  fromNative: function(callbackID, isSuccess, args) {}
  //...
}
```

## 네이티브 -> 웹뷰

반대로 네이티브에서 시작해야하는 케이스가 있습니다.

예시
- 앱이 백그라운드로 전환
- 백그라운드에서 다시 앱 활성화
- 네트워크가 끊킴
- 끊켰던 네트워크가 활성화

이러한 케이스들은 콜백을 넘겨주는거와 비슷하게 아래처럼 `fromNativeEvent` 함수를 호출하여 처리합니다.
```swift
// Sample/Bridge/WebViewMessageProcessor.swift

class WebViewMessageProcessor: NSObject {
    // MARK: - 네이티브에서 이벤트로 호출하는 영역
    func triggerEvent(eventName: String, args: JSON) {
        let argsString = args.rawString(options: []) ?? ""
        let eventFunction = "wadInterface.fromNativeEvent(\"\(eventName)\", \(argsString));"

        self.target.executeJavaScript(javascriptString: eventFunction)
    }
}
```

### fromNativeEvent 함수 스펙
```javascript

var wadInterface = {
  // ...
  
  /**
   * 네이티브에서 이벤트가 발생시 호출할 함수
   * @param { string } eventName 이벤트명
   * @param { Object? } args 이벤트에 넘겨줄 파라미터
   */
  fromNativeEvent: function (eventName, args) {}
  
  // ...
}
```

샘플 코드에서는 앱의 상태가 변경되었을때 (백그라운드, 활성화) 시 appStateChange 라는 이벤트를 호출하도록 작성하였습니다.

```swift
class WebViewMessageProcessor: NSObject {
    func load() {
        // 앱이 다시 활성화 되었을때
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            self?.triggerEvent(eventName: "appStateChange", args: JSON([ "isActive": true]))
        }
        
        // 앱이 백그라운드로 전환되었을때
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            self?.triggerEvent(eventName: "appStateChange", args: JSON([ "isActive": false]))
        }
    }
}
```
