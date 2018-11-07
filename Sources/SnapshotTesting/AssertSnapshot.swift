#if !os(Linux)
import XCTest

public var diffTool: String? = nil
public var record = false

public func assertSnapshot<A: DefaultDiffable>(
  matching snapshot: A,
  named name: String? = nil,
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  function: String = #function,
  line: UInt = #line)
  where A.Snapshottable == A
{
  return assertSnapshot(
    matching: snapshot,
    as: A.defaultStrategy,
    named: name,
    record: recording,
    timeout: timeout,
    file: file,
    function: function,
    line: line
  )
}

public func assertSnapshot<A, B>(
  matching value: A,
  as strategy: Strategy<A, B>,
  named name: String? = nil,
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  function: String = #function,
  line: UInt = #line
  ) {

  let recording = recording || record

  do {
    let snapshotDirectoryUrl: URL = {
      let fileUrl = URL(fileURLWithPath: "\(file)")
      let directoryUrl = fileUrl.deletingLastPathComponent()
      return directoryUrl
        .appendingPathComponent("__Snapshots__")
        .appendingPathComponent(fileUrl.deletingPathExtension().lastPathComponent)
    }()

    let identifier: String
    if let name = name {
      identifier = name
    } else {
      let counter = counterQueue.sync { () -> Int in
        let key = snapshotDirectoryUrl.appendingPathComponent(function)
        counterMap[key, default: 0] += 1
        return counterMap[key]!
      }
      identifier = String(counter)
    }

    let snapshotFileUrl = snapshotDirectoryUrl
      .appendingPathComponent("\(function.dropLast(2)).\(identifier)")
      .appendingPathExtension(strategy.pathExtension ?? "")
    let fileManager = FileManager.default
    try fileManager.createDirectory(at: snapshotDirectoryUrl, withIntermediateDirectories: true)

    let tookSnapshot = XCTestExpectation(description: "Took snapshot")
    var optionalDiffable: B?
    strategy.snapshotToDiffable(value).run { b in
      optionalDiffable = b
      tookSnapshot.fulfill()
    }
    let result = XCTWaiter.wait(for: [tookSnapshot], timeout: timeout)
    switch result {
    case .completed:
      break
    case .timedOut:
      XCTFail("Exceeded timeout of \(timeout) seconds waiting for snapshot", file: file, line: line)
    case .incorrectOrder, .invertedFulfillment, .interrupted:
      XCTFail("Couldn't snapshot value", file: file, line: line)
    }

    guard let diffable = optionalDiffable else {
      XCTFail("Couldn't snapshot value", file: file, line: line)
      return
    }

    guard !recording, fileManager.fileExists(atPath: snapshotFileUrl.path) else {
      try strategy.diffable.to(diffable).write(to: snapshotFileUrl)
      XCTFail("Recorded snapshot: …\n\n\"\(snapshotFileUrl.path)\"", file: file, line: line)
      return
    }

    let data = try Data(contentsOf: snapshotFileUrl)
    let reference = strategy.diffable.fro(data)

    guard let (failure, attachments) = strategy.diffable.diff(reference, diffable) else {
      return
    }

    let artifactsUrl = URL(
      fileURLWithPath: ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"] ?? NSTemporaryDirectory()
    )
    try fileManager.createDirectory(at: artifactsUrl, withIntermediateDirectories: true)
    let failedSnapshotFileUrl = artifactsUrl.appendingPathComponent(snapshotFileUrl.lastPathComponent)
    try strategy.diffable.to(diffable).write(to: failedSnapshotFileUrl)

    if !attachments.isEmpty {
      #if Xcode
      XCTContext.runActivity(named: "Attached Failure Diff") { activity in
        attachments.forEach {
          activity.add($0.rawValue)
        }
      }
      #endif
    }

    let diffMessage = diffTool
      .map { "\($0) \"\(snapshotFileUrl.path)\" \"\(failedSnapshotFileUrl.path)\"" }
      ?? "@\(minus)\n\"\(snapshotFileUrl.path)\"\n@\(plus)\n\"\(failedSnapshotFileUrl.path)\""
    let message = """
\(failure.trimmingCharacters(in: .whitespacesAndNewlines))

\(diffMessage)
"""
    XCTFail(message, file: file, line: line)
  } catch {
    XCTFail(error.localizedDescription, file: file, line: line)
  }
}

private let counterQueue = DispatchQueue(label: "co.pointfree.SnapshotTesting.counter")
private var counterMap: [URL: Int] = [:]
#endif
