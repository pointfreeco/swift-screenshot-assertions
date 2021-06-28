#if os(macOS)
import XCTest
import SnapshotTesting
import UIKit

extension Snapshotting where Value: XCUIElement, Format == UIImage {
    public static var image: Snapshotting {
    return Snapshotting<UIImage, UIImage>.image.asyncPullback { element in
      Async<UIImage> { callback in
        DispatchQueue.main.async {
          callback(element.screenshot().image)
        }
      }
    }
  }
}
#endif
