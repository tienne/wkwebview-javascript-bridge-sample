import SwiftyJSON

@objcMembers
class WebViewMessage: NSObject {

  let callbackId: String?

  let action: String
  private let actionArgs: JSON

  required init(json: JSON) {
    self.action = json["action"].stringValue
    self.callbackId = json["callbackId"].string
    self.actionArgs = json["actionArgs"]
  }

    var webviewAction: WebViewAction? {
        return WebViewAction(host: self.action)
    }
}
