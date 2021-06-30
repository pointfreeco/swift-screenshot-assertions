#if os(macOS)
import Cocoa
#endif
#if os(iOS)
import UIKit
#endif

#if os(iOS) || os(macOS)
import WebKit

// Delegate that forwards all calls to the original delegate and calls `didFinish` when the WebView finished loading.
final class ForwardingWKNavigationDelegate: NSObject {
  var didFinish: (() -> Void)?
  var original: WKNavigationDelegate?
  init(didFinish: @escaping () -> Void = {}, originalDelegate: WKNavigationDelegate?) {
    self.original = originalDelegate
    self.didFinish = didFinish
  }

  override public func responds(to aSelector: Selector!) -> Bool {
    if decidePolicyPre13 == aSelector, original?.responds(to: aSelector) != true {
      return NSObject.responds(to: aSelector)
    }

    if
      #available(iOSApplicationExtension 13.0, *, OSXApplicationExtension 10.15, *),
      decidePolicy13 == aSelector,
      original?.responds(to: aSelector) != true
    {
      return NSObject.responds(to: aSelector)
    }

    return interceptedSelectors.contains(aSelector)
      || original?.responds(to: aSelector) == true
      || NSObject.responds(to: aSelector)
  }

  override public func forwardingTarget(for aSelector: Selector!) -> Any? {
    interceptedSelectors.contains(aSelector)
      ? nil
      : original
  }

  func finish() {
    didFinish?()
    didFinish = nil
  }
}

extension ForwardingWKNavigationDelegate: WKNavigationDelegate {
  @available(iOSApplicationExtension 13.0, *, OSXApplicationExtension 10.15, *)
  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    preferences: WKWebpagePreferences,
    decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
  ) {
    original?.webView?(
      webView,
      decidePolicyFor: navigationAction,
      preferences: preferences,
      decisionHandler: { [weak self] policy, prefs in
        decisionHandler(policy, prefs)
        if policy == .cancel {
          self?.finish()
        }
      }
    )
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    original?.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: { [weak self] policy in
      decisionHandler(policy)
      if policy == .cancel {
        self?.finish()
      }
    })
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    original?.webView?(webView, didFinish: navigation)
    webView.evaluateJavaScript("document.readyState") { [weak self] _, _ in
      self?.finish()
    }
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    original?.webView?(webView, didFail: navigation, withError: error)
    finish()
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    original?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
    finish()
  }

  @available(OSXApplicationExtension 10.11, *)
  func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    original?.webViewWebContentProcessDidTerminate?(webView)
    finish()
  }
}

fileprivate let decidePolicyPre13 = #selector(WKNavigationDelegate.webView(_:decidePolicyFor:decisionHandler:) as (
  (WKNavigationDelegate) ->
  (WKWebView, WKNavigationAction, @escaping (WKNavigationActionPolicy) -> Void) -> Void
)?)

@available(iOSApplicationExtension 13.0, *, OSXApplicationExtension 10.15, *)
fileprivate let decidePolicy13 = #selector(WKNavigationDelegate.webView(_:decidePolicyFor:preferences:decisionHandler:))

fileprivate var interceptedSelectors: Set<Selector> = {
  var selectors: Set<Selector> = [
    #selector(WKNavigationDelegate.webView(_:didFinish:)),
    #selector(WKNavigationDelegate.webView(_:didFail:withError:)),
    #selector(WKNavigationDelegate.webView(_:didFailProvisionalNavigation:withError:)),
    decidePolicyPre13,
  ]

  if #available(iOSApplicationExtension 13.0, *, OSXApplicationExtension 10.15, *) {
    selectors.insert(decidePolicy13)
  }

  if #available(iOSApplicationExtension 8.0, *, OSXApplicationExtension 10.11, *) {
    selectors.insert(#selector(WKNavigationDelegate.webViewWebContentProcessDidTerminate(_:)))
  }
  return selectors
}()

#endif
