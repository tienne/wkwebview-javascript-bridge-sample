import SwiftyJSON

@objcMembers
class WebViewCallback: NSObject {
  @objc
  static let success: WebViewCallback = .init(isSuccessful: true)

  @objc
  static let failure: WebViewCallback = .init(isSuccessful: false)

  let isSuccessful: Bool
  let args: JSON
  let keepCallback: Bool

  init(args: JSON = [], isSuccessful: Bool, keepCallback: Bool = false) {
    self.args = args
    self.isSuccessful = isSuccessful
    self.keepCallback = keepCallback
  }

  @objc
  init(argsDictionary: [String: String], isSuccessful: Bool, keepCallback: Bool) {
    self.args = JSON(argsDictionary)
    self.isSuccessful = isSuccessful
    self.keepCallback = keepCallback
  }
}
