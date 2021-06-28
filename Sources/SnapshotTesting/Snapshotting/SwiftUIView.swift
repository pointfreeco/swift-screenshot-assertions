#if canImport(SwiftUI)
import Foundation
import SwiftUI

/// The size constraint for a snapshot (similar to `PreviewLayout`).
public enum SwiftUISnapshotLayout {
  #if os(iOS) || os(tvOS)
  /// Center the view in a device container described by`config`.
  case device(config: ViewImageConfig)
  #endif
  /// Center the view in a fixed size container.
  case fixed(width: CGFloat, height: CGFloat)
  /// Fit the view to the ideal size that fits its content.
  case sizeThatFits
}

#if os(iOS) || os(tvOS)
@available(iOS 13.0, tvOS 13.0, *)
extension Snapshotting where Value: SwiftUI.View, Format == UIImage {

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  ///
  /// - Parameters:
  ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your tests and will _not_ work for framework test targets.
  ///   - precision: The percentage of pixels that must match.
  ///   - layout: A view size override.
  ///   - traits: A trait collection override.
  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    layout: SwiftUISnapshotLayout = .sizeThatFits,
    traits: UITraitCollection = .init()
    )
    -> Snapshotting {
      let config: ViewImageConfig

      switch layout {
      #if os(iOS) || os(tvOS)
      case let .device(config: deviceConfig):
        config = deviceConfig
      #endif
      case .sizeThatFits:
        config = .init(safeArea: .zero, size: nil, traits: traits)
      case let .fixed(width: width, height: height):
        let size = CGSize(width: width, height: height)
        config = .init(safeArea: .zero, size: size, traits: traits)
      }

      return SimplySnapshotting.image(precision: precision, scale: traits.displayScale).asyncPullback { view in
        var config = config

        let controller: UIViewController

        if config.size != nil {
          controller = UIHostingController.init(
            rootView: view
          )
        } else {
          let hostingController = UIHostingController.init(rootView: view)

          let maxSize = CGSize(width: 0.0, height: 0.0)
          config.size = hostingController.sizeThatFits(in: maxSize)

          controller = hostingController
        }

        return snapshotView(
          config: config,
          drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
          traits: traits,
          view: controller.view,
          viewController: controller
        )
      }
  }
}
#endif

#if os(macOS)
@available(macOS 11.0, *)
extension Snapshotting where Value: SwiftUI.View, Format == NSImage {

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - layout: A view size override.
  ///   - appearance: A light/dark mode override.
  public static func image(
    precision: Float = 1,
    layout: SwiftUISnapshotLayout = .sizeThatFits,
    appearance: NSAppearance? = NSAppearance(named: .aqua)
  ) -> Snapshotting {
    let size: CGSize?

    switch layout {
    case .sizeThatFits:
      size = nil
    case let .fixed(width: width, height: height):
      size = .init(width: width, height: height)
    }
    return SimplySnapshotting.image(precision: precision).asyncPullback { swiftUIView in
        let controller = NSHostingController(rootView: swiftUIView)
        let view = controller.view
        view.appearance = appearance

        let initialSize = view.frame.size
        view.frame.size = size ?? controller.sizeThatFits(in: .zero)
        guard view.frame.width > 0, view.frame.height > 0 else {
          fatalError("View not renderable to image at size \(view.frame.size)")
        }

        return view.snapshot ?? Async { callback in
        addImagesForRenderedViews(view).sequence().run { views in
          let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
          view.cacheDisplay(in: view.bounds, to: bitmapRep)
          let image = NSImage(size: view.bounds.size)
          image.addRepresentation(bitmapRep)
          callback(image)
          views.forEach { $0.removeFromSuperview() }
          view.frame.size = initialSize
        }
      }
    }
  }
}
#endif
#endif
