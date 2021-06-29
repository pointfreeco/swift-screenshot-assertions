#if os(macOS)
import Cocoa
import XCTest

extension Snapshotting where Value == NSColor, Format == CGColor {
  /// A snapshot strategy for comparing colors based on RGB similarity.
  public static var color: Snapshotting {
    return .color(precision: 1.0)
  }

  /// A snapshot strategy for comparing colors based on RGB similarity.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  public static func color(precision: CGFloat) -> Snapshotting {
    Snapshotting<CGColor, CGColor>.color(precision: precision).pullback {
      $0.cgColor
    }
  }
}
#endif
