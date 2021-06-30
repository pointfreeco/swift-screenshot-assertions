import Foundation
import XCTest

extension Snapshotting where Value: Hashable, Format == String {
  /// A snapshot strategy that captures a value's hash.
  public static var hash: Snapshotting {
    return SimplySnapshotting.lines.pullback { value in
      let environmentKeys = ProcessInfo.processInfo.environment.keys
      let isDeterministic = environmentKeys.contains("SWIFT_DETERMINISTIC_HASHING")
      precondition(
        isDeterministic,
        """
        Hashing snapshots require the \
        `SWIFT_DETERMINISTIC_HASHING` \
        environment variable to be defined.
        """
      )
      var hasher = Hasher()
      value.hash(into: &hasher)
      let signedHashValue = hasher.finalize()
      let unsignedHashValue = UInt(bitPattern: signedHashValue)

      let binaryHash = String(unsignedHashValue, radix: 2)
      let leadingZeros = String(
        repeating: "0",
        count: 64 - binaryHash.count 
      )

      return "Hash: 0b\(leadingZeros)\(binaryHash)\n"
    }
  }
}
