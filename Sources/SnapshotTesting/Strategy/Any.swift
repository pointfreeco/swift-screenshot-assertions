import Foundation

extension SnapshotTestCase {
  public func assertSnapshot(
    matching value: Any,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    function: String = #function,
    line: UInt = #line
    ) {

    assertSnapshot(
      matching: value,
      with: .any,
      named: name,
      record: recording,
      timeout: timeout,
      file: file,
      function: function,
      line: line
    )
  }
}

extension Strategy {
  public static var any: Strategy<A, String> {
    return Strategy.string.contramap { snap($0) }
  }
}

private func snap<T>(_ value: T, name: String? = nil, indent: Int = 0) -> String {
  let indentation = String(repeating: " ", count: indent)
  let mirror = Mirror(reflecting: value)
  let count = mirror.children.count
  let bullet = count == 0 ? "-" : "▿"

  let description: String
  switch (value, mirror.displayStyle) {
  case (_, .collection?):
    description = count == 1 ? "1 element" : "\(count) elements"
  case (_, .dictionary?):
    description = count == 1 ? "1 key/value pair" : "\(count) key/value pairs"
  case (_, .set?):
    description = count == 1 ? "1 member" : "\(count) members"
  case (_, .tuple?):
    description = count == 1 ? "(1 element)" : "(\(count) elements)"
  case (_, .optional?):
    let subjectType = String(describing: mirror.subjectType)
      .replacingOccurrences(of: " #\\d+", with: "", options: .regularExpression)
    description = count == 0 ? "\(subjectType).none" : "\(subjectType)"
  case (let value as SnapshotStringConvertible, _):
    description = value.snapshotDescription
  case (let value as CustomDebugStringConvertible, _):
    description = value.debugDescription
  case (let value as CustomStringConvertible, _):
    description = value.description
  case (_, .class?), (_, .struct?):
    description = String(describing: mirror.subjectType)
      .replacingOccurrences(of: " #\\d+", with: "", options: .regularExpression)
  case (_, .enum?):
    let subjectType = String(describing: mirror.subjectType)
      .replacingOccurrences(of: " #\\d+", with: "", options: .regularExpression)
    description = count == 0 ? "\(subjectType).\(value)" : "\(subjectType)"
  default:
    description = "(indescribable)"
  }

  let lines = ["\(indentation)\(bullet) \(name.map { "\($0): " } ?? "")\(description)\n"]
    + mirror.children.map { snap($1, name: $0, indent: indent + 2) }

  return lines.joined()
}

public protocol SnapshotStringConvertible {
  var snapshotDescription: String { get }
}

extension Date: SnapshotStringConvertible {
  public var snapshotDescription: String {
    return snapshotDateFormatter.string(from: self)
  }
}

extension NSObject: SnapshotStringConvertible {
  public var snapshotDescription: String {
    return self.debugDescription
      .replacingOccurrences(of: ": 0x[\\da-f]+", with: "", options: .regularExpression)
  }
}

private let snapshotDateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
  formatter.calendar = Calendar(identifier: .gregorian)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = TimeZone(abbreviation: "UTC")
  return formatter
}()
