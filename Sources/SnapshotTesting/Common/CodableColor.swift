import Foundation

#if os(macOS) || os(iOS) || os(tvOS)
import CoreGraphics

#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

internal struct CodableColor: Codable {
  let colorSpaceName: String
  let components: [CGFloat]

  var numberOfComponents: Int {
    self.components.count
  }

  var cgColor: CGColor {
    let colorSpace = CGColorSpace(
      name: self.colorSpaceName as CFString
    )!

    return CGColor(
      colorSpace: colorSpace,
      components: self.components
    )!
  }

#if os(macOS)
  var nsColor: NSColor {
    NSColor(cgColor: self.cgColor)!
  }
#elseif os(iOS) || os(tvOS)
  var uiColor: UIColor {
    UIColor(cgColor: self.cgColor)
  }
#endif

  init(cgColor: CGColor) {
    self.colorSpaceName = cgColor.colorSpace!.name! as String
    self.components = cgColor.components!
  }

#if os(macOS)
  init(nsColor: NSColor) {
    self.init(cgColor: nsColor.cgColor)
  }
#elseif os(iOS) || os(tvOS)
  init(uiColor: UIColor) {
    self.init(cgColor: uiColor.cgColor)
  }
#endif
}
#endif
