import SwiftyJSON

@objcMembers
class WebViewCallback: NSObject {
  @objc
  static let success: WebViewCallback = .init(isSuccessful: true)

  @objc
  static let failure: WebViewCallback = .init(isSuccessful: false)

  let isSuccessful: Bool
  let args: JSON
    init(args: JSON = [:], isSuccessful: Bool) {
    self.args = args
    self.isSuccessful = isSuccessful
  }

  @objc
  init(argsDictionary: [String: String], isSuccessful: Bool) {
    self.args = JSON(argsDictionary)
    self.isSuccessful = isSuccessful
  }
}
