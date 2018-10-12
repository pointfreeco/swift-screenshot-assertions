#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
import WebKit

extension Strategy {
  public static var view: Strategy<UIView, UIImage> {
    return Strategy.layer.contramap {
      precondition(!($0 is WKWebView), "TODO")
      return $0.layer
    }
  }
}

extension UIView: DefaultDiffable {
  public static let defaultStrategy: Strategy<UIView, UIImage> = .view
}
#endif
