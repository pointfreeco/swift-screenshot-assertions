#if os(macOS) || os(iOS) || os(tvOS)

#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

import XCTest

extension Snapshotting where Value == CGColor, Format == CGColor {
  /// A snapshot strategy for comparing colors based on RGB similarity.
  public static var color: Snapshotting {
    return .color(precision: 1.0)
  }

  /// A snapshot strategy for comparing colors based on RGB similarity.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  public static func color(precision: CGFloat) -> Snapshotting {
    return .init(
      pathExtension: "json",
      diffing: .color(precision: precision)
    )
  }
}

extension Diffing where Value == CGColor {
  /// A pixel-diffing strategy for NSImage's which requires a 100% match.
  internal static let color = Diffing.color(precision: 1.0)

  /// A pixel-diffing strategy for NSImage that allows customizing how precise the matching must be.
  ///
  /// - Parameter precision: A value between 0 and 1, where 1 means the images must match 100% of their pixels.
  /// - Returns: A new diffing strategy.
  internal static func color(precision: CGFloat) -> Diffing {
    return .init(
      toData: {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try! encoder.encode(CodableColor(cgColor: $0))
      },
      fromData: {
        let decoder = JSONDecoder()
        return try! decoder.decode(CodableColor.self, from: $0).cgColor
      }
    ) { old, new in
      guard !(try! compare(old, new, precision: precision)) else { return nil }
      return (
        "Newly-taken snapshot does not match reference.",
        [
          XCTAttachment(string: String(describing: old)),
          XCTAttachment(string: String(describing: new)),
        ]
      )
    }
  }
}

func compare(
  _ old: CGColor,
  _ new: CGColor,
  precision: CGFloat
) throws -> Bool {
  let similarity = try rgbSimilarity(between: old, and: new).get()
  let threshold = 1.0 - precision
  return similarity <= threshold
}
#endif
