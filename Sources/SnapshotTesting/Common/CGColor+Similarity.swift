import Foundation

#if os(macOS) || os(iOS) || os(tvOS)
import CoreGraphics

enum ColorSimilarityError: Error {
    case incompatibleColorSpace
    case incompatibleComponents
}

func rgbSimilarity(between a: CGColor, and b: CGColor) -> Result<CGFloat, ColorSimilarityError> {
  guard a.colorSpace == b.colorSpace else {
    return .failure(.incompatibleColorSpace)
  }

  guard a.numberOfComponents == b.numberOfComponents else {
    return .failure(.incompatibleComponents)
  }

  let aComponents = a.components!
  let bComponents = b.components!

  let squaredDistance: CGFloat = zip(aComponents, bComponents).reduce(0.0) { squaredError, components in
      let error = components.0 - components.1
      return squaredError + pow(error, 2.0)
  }
  let distance: CGFloat = sqrt(squaredDistance)

  // The max distance within the color space's 1x1x1 cube:
  let maxDistance: CGFloat = sqrt(1.0 + 1.0 + 1.0)
  let normalizedDistance = distance / maxDistance

  return .success(normalizedDistance)
}
#endif
