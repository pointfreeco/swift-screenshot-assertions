import XCTest

public var diffTool: String? = nil
public var recording = false

public func record(during: () -> Void) {
  recording = true
  defer { recording = false }
  during()
}

public protocol Diffable: Equatable {
  static var diffableFileExtension: String? { get }
  static func fromDiffableData(_ data: Data) -> Self
  var diffableData: Data { get }
  func diff(comparing other: Data) -> XCTAttachment?
}

public protocol Snapshot {
  associatedtype Format: Diffable
  static var snapshotFileExtension: String? { get }
  var snapshotFormat: Format { get }
}

extension Snapshot {
  public static var snapshotFileExtension: String? {
    return Format.diffableFileExtension
  }
}

extension Data: Diffable {
  public static var diffableFileExtension: String? {
    return nil
  }

  public static func fromDiffableData(_ data: Data) -> Data {
    return data
  }

  public var diffableData: Data {
    return self
  }

  public func diff(comparing other: Data) -> XCTAttachment? {
    return nil
  }
}

extension Data: Snapshot {
  public var snapshotFormat: Data {
    return self
  }
}

extension String: Diffable {
  public static var diffableFileExtension: String? {
    return "txt"
  }

  public static func fromDiffableData(_ data: Data) -> String {
    return String(data: data, encoding: .utf8)!
  }

  public var diffableData: Data {
    return self.data(using: .utf8)!
  }

  public func diff(comparing other: Data) -> XCTAttachment? {
    return nil
  }
}

extension String: Snapshot {
  public var snapshotFormat: String {
    return self
  }
}

public func assertSnapshot<S: Snapshot>(
  matching snapshot: S,
  identifier: String? = nil,
  pathExtension: String? = nil,
  file: StaticString = #file,
  function: String = #function,
  line: UInt = #line)
{
  let filePath = "\(file)"
  let testFileURL = URL(fileURLWithPath: filePath)
  let snapshotsDirectoryURL = testFileURL.deletingLastPathComponent()
    .appendingPathComponent("__Snapshots__")

  let fileManager = FileManager.default
  try! fileManager
    .createDirectory(at: snapshotsDirectoryURL, withIntermediateDirectories: true, attributes: nil)

  let snapshotFileName = testFileURL.deletingPathExtension().lastPathComponent
    + ".\(function.dropLast(2))"
    + (identifier.map { ".\($0)" } ?? "")
    + ((pathExtension ?? S.snapshotFileExtension).map { ".\($0)" } ?? "")
  let snapshotFileURL = snapshotsDirectoryURL.appendingPathComponent(snapshotFileName)
  let snapshotFormat = snapshot.snapshotFormat
  let snapshotData = snapshotFormat.diffableData

  trackStaleSnapshots()
  let tracked: () -> Set<String> = {
    try! fileManager.contentsOfDirectory(atPath: snapshotsDirectoryURL.path)
      .filter { !$0.starts(with: ".") }
      .reduce([]) { $0.union([snapshotsDirectoryURL.appendingPathComponent($1).path]) }
  }
  trackedSnapshots[filePath, default: tracked()].remove(snapshotFileURL.path)

  guard !recording, fileManager.fileExists(atPath: snapshotFileURL.path) else {
    try! snapshotData.write(to: snapshotFileURL)
    XCTAssert(!recording, "Recorded \"\(snapshotFileURL.path)\"", file: file, line: line)
    return
  }

  let existingData = try! Data(contentsOf: snapshotFileURL)

  guard existingData == snapshotData else {
    let failedSnapshotFileURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(snapshotFileName)
    try! snapshotData.write(to: failedSnapshotFileURL)

    let baseMessage = "\(snapshotFileURL.path.debugDescription) does not match snapshot"
    let message = diffTool
      .map {
        """
        \(baseMessage)

        \($0) \(snapshotFileURL.path.debugDescription) \(failedSnapshotFileURL.path.debugDescription)
        """
      }
      ?? baseMessage

    let existingFormat = S.Format.fromDiffableData(existingData)
    XCTAssertEqual(existingFormat, snapshotFormat, message, file: file, line: line)

    if let attachment = snapshotFormat.diff(comparing: existingData) {
      attachment.lifetime = .deleteOnSuccess
      XCTContext.runActivity(named: "Attached failure diff") { activity in activity.add(attachment) }
    }
    return
  }
}

public func assertSnapshot<S: Encodable>(
  encoding snapshot: S,
  identifier: String? = nil,
  file: StaticString = #file,
  function: String = #function,
  line: UInt = #line)
{
  let encoder = JSONEncoder()
  encoder.outputFormatting = .prettyPrinted
  let data = try! encoder.encode(snapshot)
  let string = String(data: data, encoding: .utf8)!

  assertSnapshot(
    matching: string,
    identifier: identifier,
    pathExtension: "json",
    file: file,
    function: function,
    line: line
  )
}

private var trackedSnapshots: [String: Set<String>] = [:]
private var trackingStaleSnapshots = false

private func trackStaleSnapshots() {
  if !trackingStaleSnapshots {
    defer { trackingStaleSnapshots = true }
    atexit {
      let stale = trackedSnapshots.flatMap { $0.value }
      let staleCount = stale.count
      let staleList = stale.map { "  - \($0.debugDescription)" }.sorted().joined(separator: "\n")
      print(
        """

        Found \(staleCount) stale snapshot\(staleCount == 1 ? "" : "s"):

        \(staleList)


        """
      )
    }
  }
}
