import Foundation

extension Snapshotting where Value == URLRequest, Format == String {
  public static let raw = SimplySnapshotting.lines.pullback { (request: URLRequest) in

    let status = "\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "(null)")"

    let headers = (request.allHTTPHeaderFields ?? [:])
      .map { key, value in "\(key): \(value)" }
      .sorted()

    let body = request.httpBody
      .map { ["\n\(String(decoding: $0, as: UTF8.self))"] }
      ?? []

    return ([status] + headers + body).joined(separator: "\n")
  }
}
