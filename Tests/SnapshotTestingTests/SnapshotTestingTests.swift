import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(SceneKit)
import SceneKit
#endif
#if canImport(SpriteKit)
import SpriteKit
import SwiftUI
#endif
#if canImport(WebKit)
import WebKit
#endif
#if canImport(UIKit)
import UIKit.UIView
#endif
import XCTest

@testable import SnapshotTesting

final class SnapshotTestingTests: XCTestCase {
  override func setUp() {
    super.setUp()
    diffTool = "ksdiff"
//    isRecording = true
  }

  override func tearDown() {
    isRecording = false
    super.tearDown()
  }

  func testAny() {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    assertSnapshot(matching: user, as: .dump)
    _assertInlineSnapshot(matching: user, as: .dump, with: """
    ▿ User
      - bio: "Blobbed around the world."
      - id: 1
      - name: "Blobby"
    """)
  }

  func testAnySnapshotStringConvertible() {
    assertSnapshot(matching: "a" as Character, as: .dump, named: "character")
    assertSnapshot(matching: Data("Hello, world!".utf8), as: .dump, named: "data")
    assertSnapshot(matching: Date(timeIntervalSinceReferenceDate: 0), as: .dump, named: "date")
    assertSnapshot(matching: NSObject(), as: .dump, named: "nsobject")
    assertSnapshot(matching: "Hello, world!", as: .dump, named: "string")
    assertSnapshot(matching: "Hello, world!".dropLast(8), as: .dump, named: "substring")
    assertSnapshot(matching: URL(string: "https://www.pointfree.co")!, as: .dump, named: "url")
    // Inline
    _assertInlineSnapshot(matching: "a" as Character, as: .dump, with: """
    - "a"
    """)
    _assertInlineSnapshot(matching: Data("Hello, world!".utf8), as: .dump, with: """
    - 13 bytes
    """)
    _assertInlineSnapshot(matching: Date(timeIntervalSinceReferenceDate: 0), as: .dump, with: """
    - 2001-01-01T00:00:00Z
    """)
    _assertInlineSnapshot(matching: NSObject(), as: .dump, with: """
    - <NSObject>
    """)
    _assertInlineSnapshot(matching: "Hello, world!", as: .dump, with: """
    - "Hello, world!"
    """)
    _assertInlineSnapshot(matching: "Hello, world!".dropLast(8), as: .dump, with: """
    - "Hello"
    """)
    _assertInlineSnapshot(matching: URL(string: "https://www.pointfree.co")!, as: .dump, with: """
    - https://www.pointfree.co
    """)
  }

  func testAutolayout() {
    #if os(iOS)
    let vc = UIViewController()
    vc.view.translatesAutoresizingMaskIntoConstraints = false
    let subview = UIView()
    subview.translatesAutoresizingMaskIntoConstraints = false
    vc.view.addSubview(subview)
    NSLayoutConstraint.activate([
      subview.topAnchor.constraint(equalTo: vc.view.topAnchor),
      subview.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
      subview.leftAnchor.constraint(equalTo: vc.view.leftAnchor),
      subview.rightAnchor.constraint(equalTo: vc.view.rightAnchor),
      ])
    assertSnapshot(matching: vc, as: .image)
    #endif
  }

  func testDeterministicDictionaryAndSetSnapshots() {
    struct Person: Hashable { let name: String }
    struct DictionarySetContainer { let dict: [String: Int], set: Set<Person> }
    let set = DictionarySetContainer(
      dict: ["c": 3, "a": 1, "b": 2],
      set: [.init(name: "Brandon"), .init(name: "Stephen")]
    )
    assertSnapshot(matching: set, as: .dump)
    _assertInlineSnapshot(matching: set, as: .dump, with: """
    ▿ DictionarySetContainer
      ▿ dict: 3 key/value pairs
        ▿ (2 elements)
          - key: "a"
          - value: 1
        ▿ (2 elements)
          - key: "b"
          - value: 2
        ▿ (2 elements)
          - key: "c"
          - value: 3
      ▿ set: 2 members
        ▿ Person
          - name: "Brandon"
        ▿ Person
          - name: "Stephen"
    """)
  }

  func testCaseIterable() {
    enum Direction: String, CaseIterable {
      case up, down, left, right
      var rotatedLeft: Direction {
        switch self {
        case .up:    return .left
        case .down:  return .right
        case .left:  return .down
        case .right: return .up
        }
      }
    }

    assertSnapshot(
      matching: { $0.rotatedLeft },
      as: Snapshotting<Direction, String>.func(into: .description)
    )
  }

  @available(iOS 13.0, macOS 10.5, tvOS 13.0, *)
  func testCGColor() {
    #if os(iOS) || os(tvOS) || os(macOS)
    let color = CGColor(
        red: 0.2,
        green: 0.4,
        blue: 0.6,
        alpha: 0.8
    )

    let osName: String
    #if os(iOS)
    osName = "iOS"
    #elseif os(tvOS)
    osName = "tvOS"
    #elseif os(macOS)
    osName = "macOS"
    #endif

    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      assertSnapshot(matching: color, as: .color(precision: 1.0), named: osName)
    }
    #endif
  }

  func testCGPath() {
    #if os(iOS) || os(tvOS) || os(macOS)
    let path = CGPath.heart

    let osName: String
    #if os(iOS)
    osName = "iOS"
    #elseif os(tvOS)
    osName = "tvOS"
    #elseif os(macOS)
    osName = "macOS"
    #endif

    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      assertSnapshot(matching: path, as: .image, named: osName)
    }

    if #available(iOS 11.0, OSX 10.13, tvOS 11.0, *) {
      assertSnapshot(matching: path, as: .elementsDescription, named: osName)
    }
    #endif
  }

  func testData() {
    let data = Data([0xDE, 0xAD, 0xBE, 0xEF])

    assertSnapshot(matching: data, as: .data)
  }

  func testEncodable() {
    struct User: Encodable { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    if #available(iOS 11.0, macOS 10.13, tvOS 11.0, *) {
      assertSnapshot(matching: user, as: .json)
    }
    assertSnapshot(matching: user, as: .plist)
  }

  func testMixedViews() {
//    #if os(iOS) || os(macOS)
//    // NB: CircleCI crashes while trying to instantiate SKView.
//    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
//      let webView = WKWebView(frame: .init(x: 0, y: 0, width: 50, height: 50))
//      webView.loadHTMLString("🌎", baseURL: nil)
//
//      let skView = SKView(frame: .init(x: 50, y: 0, width: 50, height: 50))
//      let scene = SKScene(size: .init(width: 50, height: 50))
//      let node = SKShapeNode(circleOfRadius: 15)
//      node.fillColor = .red
//      node.position = .init(x: 25, y: 25)
//      scene.addChild(node)
//      skView.presentScene(scene)
//
//      let view = View(frame: .init(x: 0, y: 0, width: 100, height: 50))
//      view.addSubview(webView)
//      view.addSubview(skView)
//
//      assertSnapshot(matching: view, as: .image, named: platform)
//    }
//    #endif
  }

  func testMultipleSnapshots() {
    assertSnapshot(matching: [1], as: .dump)
    assertSnapshot(matching: [1, 2], as: .dump)
  }

  func testNamedAssertion() {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    assertSnapshot(matching: user, as: .dump, named: "named")
  }

  func testNSBezierPath() {
    #if os(macOS)
    let path = NSBezierPath.heart

    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      assertSnapshot(matching: path, as: .image, named: "macOS")
    }

    assertSnapshot(matching: path, as: .elementsDescription, named: "macOS")
    #endif
  }

  func testNSColor() {
    #if os(macOS)
    let color = CGColor(
        red: 0.2,
        green: 0.4,
        blue: 0.6,
        alpha: 0.8
    )

    let osName: String
    #if os(iOS)
    osName = "iOS"
    #elseif os(tvOS)
    osName = "tvOS"
    #elseif os(macOS)
    osName = "macOS"
    #endif

    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      assertSnapshot(matching: color, as: .color(precision: 1.0), named: osName)
    }
    #endif
  }

  func testNSView() {
    #if os(macOS)
    let button = NSButton()
    button.bezelStyle = .rounded
    button.title = "Push Me"
    button.sizeToFit()
    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      assertSnapshot(matching: button, as: .image)
      assertSnapshot(matching: button, as: .recursiveDescription)
    }
    #endif
  }
  
  func testNSViewWithLayer() {
    #if os(macOS)
    let view = NSView()
    view.frame = CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0)
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.green.cgColor
    view.layer?.cornerRadius = 5
    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      assertSnapshot(matching: view, as: .image)
      assertSnapshot(matching: view, as: .recursiveDescription)
    }
    #endif
  }

  func testPrecision() {
    #if os(iOS) || os(macOS) || os(tvOS)
    #if os(iOS) || os(tvOS)
    let label = UILabel()
    #if os(iOS)
    label.frame = CGRect(origin: .zero, size: CGSize(width: 43.5, height: 20.5))
    #elseif os(tvOS)
    label.frame = CGRect(origin: .zero, size: CGSize(width: 98, height: 46))
    #endif
    label.backgroundColor = .white
    #elseif os(macOS)
    let label = NSTextField()
    label.frame = CGRect(origin: .zero, size: CGSize(width: 37, height: 16))
    label.backgroundColor = .white
    label.isBezeled = false
    label.isEditable = false
    #endif
    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      label.text = "Hello."
      assertSnapshot(matching: label, as: .image(precision: 0.9), named: platform)
      label.text = "Hello"
      assertSnapshot(matching: label, as: .image(precision: 0.9), named: platform)
    }
    #endif
  }

  func testSCNView() {
//    #if os(iOS) || os(macOS) || os(tvOS)
//    // NB: CircleCI crashes while trying to instantiate SCNView.
//    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
//      let scene = SCNScene()
//
//      let sphereGeometry = SCNSphere(radius: 3)
//      sphereGeometry.segmentCount = 200
//      let sphereNode = SCNNode(geometry: sphereGeometry)
//      sphereNode.position = SCNVector3Zero
//      scene.rootNode.addChildNode(sphereNode)
//
//      sphereGeometry.firstMaterial?.diffuse.contents = URL(fileURLWithPath: String(#file), isDirectory: false)
//        .deletingLastPathComponent()
//        .appendingPathComponent("__Fixtures__/earth.png")
//
//      let cameraNode = SCNNode()
//      cameraNode.camera = SCNCamera()
//      cameraNode.position = SCNVector3Make(0, 0, 8)
//      scene.rootNode.addChildNode(cameraNode)
//
//      let omniLight = SCNLight()
//      omniLight.type = .omni
//      let omniLightNode = SCNNode()
//      omniLightNode.light = omniLight
//      omniLightNode.position = SCNVector3Make(10, 10, 10)
//      scene.rootNode.addChildNode(omniLightNode)
//
//      assertSnapshot(
//        matching: scene,
//        as: .image(size: .init(width: 500, height: 500)),
//        named: platform
//      )
//    }
//    #endif
  }

  func testSKView() {
//    #if os(iOS) || os(macOS) || os(tvOS)
//    // NB: CircleCI crashes while trying to instantiate SKView.
//    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
//      let scene = SKScene(size: .init(width: 50, height: 50))
//      let node = SKShapeNode(circleOfRadius: 15)
//      node.fillColor = .red
//      node.position = .init(x: 25, y: 25)
//      scene.addChild(node)
//
//      assertSnapshot(
//        matching: scene,
//        as: .image(size: .init(width: 50, height: 50)),
//        named: platform
//      )
//    }
//    #endif
  }

  func testTableViewController() {
    #if os(iOS)
    class TableViewController: UITableViewController {
      override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
      }
      override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
      }
      override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
      }
    }
    let tableViewController = TableViewController()
    assertSnapshot(matching: tableViewController, as: .image(on: .iPhoneSe))
    #endif
  }

  func testAssertMultipleSnapshot() {
    #if os(iOS)
    class TableViewController: UITableViewController {
      override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
      }
      override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
      }
      override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
      }
    }
    let tableViewController = TableViewController()
    assertSnapshots(matching: tableViewController, as: ["iPhoneSE-image" : .image(on: .iPhoneSe), "iPad-image" : .image(on: .iPadMini)])
    assertSnapshots(matching: tableViewController, as: [.image(on: .iPhoneX), .image(on: .iPhoneXsMax)])
    #endif
  }

  func testTraits() {
    #if os(iOS) || os(tvOS)
    if #available(iOS 11.0, tvOS 11.0, *) {
      class MyViewController: UIViewController {
        let topLabel = UILabel()
        let leadingLabel = UILabel()
        let trailingLabel = UILabel()
        let bottomLabel = UILabel()

        override func viewDidLoad() {
          super.viewDidLoad()

          self.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .add, target: nil, action: nil)

          self.view.backgroundColor = .white

          self.topLabel.text = "What's"
          self.leadingLabel.text = "the"
          self.trailingLabel.text = "point"
          self.bottomLabel.text = "?"

          self.topLabel.translatesAutoresizingMaskIntoConstraints = false
          self.leadingLabel.translatesAutoresizingMaskIntoConstraints = false
          self.trailingLabel.translatesAutoresizingMaskIntoConstraints = false
          self.bottomLabel.translatesAutoresizingMaskIntoConstraints = false

          self.view.addSubview(self.topLabel)
          self.view.addSubview(self.leadingLabel)
          self.view.addSubview(self.trailingLabel)
          self.view.addSubview(self.bottomLabel)

          NSLayoutConstraint.activate([
            self.topLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.topLabel.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            self.leadingLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.leadingLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.centerXAnchor),
//            self.leadingLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            self.leadingLabel.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
            self.trailingLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            self.trailingLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.trailingLabel.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
            self.bottomLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            self.bottomLabel.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            ])
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
          super.traitCollectionDidChange(previousTraitCollection)
          self.topLabel.font = .preferredFont(forTextStyle: .headline, compatibleWith: self.traitCollection)
          self.leadingLabel.font = .preferredFont(forTextStyle: .body, compatibleWith: self.traitCollection)
          self.trailingLabel.font = .preferredFont(forTextStyle: .body, compatibleWith: self.traitCollection)
          self.bottomLabel.font = .preferredFont(forTextStyle: .subheadline, compatibleWith: self.traitCollection)
          self.view.setNeedsUpdateConstraints()
          self.view.updateConstraintsIfNeeded()
        }
      }

      let viewController = MyViewController()

      #if os(iOS)
      assertSnapshot(matching: viewController, as: .image(on: .iPhoneSe), named: "iphone-se")
      assertSnapshot(matching: viewController, as: .image(on: .iPhone8), named: "iphone-8")
      assertSnapshot(matching: viewController, as: .image(on: .iPhone8Plus), named: "iphone-8-plus")
      assertSnapshot(matching: viewController, as: .image(on: .iPhoneX), named: "iphone-x")
      assertSnapshot(matching: viewController, as: .image(on: .iPhoneXr), named: "iphone-xr")
      assertSnapshot(matching: viewController, as: .image(on: .iPhoneXsMax), named: "iphone-xs-max")
      assertSnapshot(matching: viewController, as: .image(on: .iPadMini), named: "ipad-mini")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro10_5), named: "ipad-pro-10-5")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro11), named: "ipad-pro-11")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro12_9), named: "ipad-pro-12-9")

      assertSnapshot(matching: viewController, as: .recursiveDescription(on: .iPhoneSe), named: "iphone-se")
      assertSnapshot(matching: viewController, as: .recursiveDescription(on: .iPhone8), named: "iphone-8")
      assertSnapshot(matching: viewController, as: .recursiveDescription(on: .iPhone8Plus), named: "iphone-8-plus")
      assertSnapshot(matching: viewController, as: .recursiveDescription(on: .iPhoneX), named: "iphone-x")
      assertSnapshot(matching: viewController, as: .recursiveDescription(on: .iPhoneXr), named: "iphone-xr")
      assertSnapshot(matching: viewController, as: .recursiveDescription(on: .iPhoneXsMax), named: "iphone-xs-max")
      assertSnapshot(matching: viewController, as: .recursiveDescription(on: .iPadMini), named: "ipad-mini")
      assertSnapshot(matching: viewController, as: .recursiveDescription(on: .iPadPro10_5), named: "ipad-pro-10-5")
      assertSnapshot(matching: viewController, as: .recursiveDescription(on: .iPadPro11), named: "ipad-pro-11")
      assertSnapshot(matching: viewController, as: .recursiveDescription(on: .iPadPro12_9), named: "ipad-pro-12-9")

      assertSnapshot(matching: viewController, as: .image(on: .iPhoneSe(.portrait)), named: "iphone-se")
      assertSnapshot(matching: viewController, as: .image(on: .iPhone8(.portrait)), named: "iphone-8")
      assertSnapshot(matching: viewController, as: .image(on: .iPhone8Plus(.portrait)), named: "iphone-8-plus")
      assertSnapshot(matching: viewController, as: .image(on: .iPhoneX(.portrait)), named: "iphone-x")
      assertSnapshot(matching: viewController, as: .image(on: .iPhoneXr(.portrait)), named: "iphone-xr")
      assertSnapshot(matching: viewController, as: .image(on: .iPhoneXsMax(.portrait)), named: "iphone-xs-max")
      assertSnapshot(matching: viewController, as: .image(on: .iPadMini(.landscape)), named: "ipad-mini")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro10_5(.landscape)), named: "ipad-pro-10-5")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro11(.landscape)), named: "ipad-pro-11")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro12_9(.landscape)), named: "ipad-pro-12-9")

      assertSnapshot(matching: viewController, as: .image(on: .iPadMini(.landscape(splitView: .oneThird))), named: "ipad-mini-33-split-landscape")
      assertSnapshot(matching: viewController, as: .image(on: .iPadMini(.landscape(splitView: .oneHalf))), named: "ipad-mini-50-split-landscape")
      assertSnapshot(matching: viewController, as: .image(on: .iPadMini(.landscape(splitView: .twoThirds))), named: "ipad-mini-66-split-landscape")
      assertSnapshot(matching: viewController, as: .image(on: .iPadMini(.portrait(splitView: .oneThird))), named: "ipad-mini-33-split-portrait")
      assertSnapshot(matching: viewController, as: .image(on: .iPadMini(.portrait(splitView: .twoThirds))), named: "ipad-mini-66-split-portrait")
      
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro10_5(.landscape(splitView: .oneThird))), named: "ipad-pro-10inch-33-split-landscape")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro10_5(.landscape(splitView: .oneHalf))), named: "ipad-pro-10inch-50-split-landscape")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro10_5(.landscape(splitView: .twoThirds))), named: "ipad-pro-10inch-66-split-landscape")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro10_5(.portrait(splitView: .oneThird))), named: "ipad-pro-10inch-33-split-portrait")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro10_5(.portrait(splitView: .twoThirds))), named: "ipad-pro-10inch-66-split-portrait")
      
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro11(.landscape(splitView: .oneThird))), named: "ipad-pro-11inch-33-split-landscape")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro11(.landscape(splitView: .oneHalf))), named: "ipad-pro-11inch-50-split-landscape")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro11(.landscape(splitView: .twoThirds))), named: "ipad-pro-11inch-66-split-landscape")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro11(.portrait(splitView: .oneThird))), named: "ipad-pro-11inch-33-split-portrait")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro11(.portrait(splitView: .twoThirds))), named: "ipad-pro-11inch-66-split-portrait")
      
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro12_9(.landscape(splitView: .oneThird))), named: "ipad-pro-12inch-33-split-landscape")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro12_9(.landscape(splitView: .oneHalf))), named: "ipad-pro-12inch-50-split-landscape")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro12_9(.landscape(splitView: .twoThirds))), named: "ipad-pro-12inch-66-split-landscape")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro12_9(.portrait(splitView: .oneThird))), named: "ipad-pro-12inch-33-split-portrait")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro12_9(.portrait(splitView: .twoThirds))), named: "ipad-pro-12inch-66-split-portrait")
      
      assertSnapshot(
        matching: viewController, as: .image(on: .iPhoneSe(.landscape)), named: "iphone-se-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPhone8(.landscape)), named: "iphone-8-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPhone8Plus(.landscape)), named: "iphone-8-plus-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPhoneX(.landscape)), named: "iphone-x-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPhoneXr(.landscape)), named: "iphone-xr-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPhoneXsMax(.landscape)), named: "iphone-xs-max-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPadMini(.portrait)), named: "ipad-mini-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPadPro10_5(.portrait)), named: "ipad-pro-10-5-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPadPro11(.portrait)), named: "ipad-pro-11-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPadPro12_9(.portrait)), named: "ipad-pro-12-9-alternative")

      allContentSizes.forEach { name, contentSize in
          assertSnapshot(
            matching: viewController,
            as: .image(on: .iPhoneSe, traits: .init(preferredContentSizeCategory: contentSize)),
            named: "iphone-se-\(name)"
          )
      }
      #elseif os(tvOS)
      assertSnapshot(
        matching: viewController, as: .image(on: .tv), named: "tv")
      assertSnapshot(
        matching: viewController, as: .image(on: .tv4K), named: "tv4k")
      #endif
    }
    #endif
  }

  func testTraitsEmbeddedInTabNavigation() {
    #if os(iOS)
    if #available(iOS 11.0, *) {
      class MyViewController: UIViewController {
        let topLabel = UILabel()
        let leadingLabel = UILabel()
        let trailingLabel = UILabel()
        let bottomLabel = UILabel()

        override func viewDidLoad() {
          super.viewDidLoad()

          self.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .add, target: nil, action: nil)

          self.view.backgroundColor = .white

          self.topLabel.text = "What's"
          self.leadingLabel.text = "the"
          self.trailingLabel.text = "point"
          self.bottomLabel.text = "?"

          self.topLabel.translatesAutoresizingMaskIntoConstraints = false
          self.leadingLabel.translatesAutoresizingMaskIntoConstraints = false
          self.trailingLabel.translatesAutoresizingMaskIntoConstraints = false
          self.bottomLabel.translatesAutoresizingMaskIntoConstraints = false

          self.view.addSubview(self.topLabel)
          self.view.addSubview(self.leadingLabel)
          self.view.addSubview(self.trailingLabel)
          self.view.addSubview(self.bottomLabel)

          NSLayoutConstraint.activate([
            self.topLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.topLabel.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            self.leadingLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.leadingLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.centerXAnchor),
//            self.leadingLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            self.leadingLabel.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
            self.trailingLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            self.trailingLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.trailingLabel.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
            self.bottomLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            self.bottomLabel.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            ])
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
          super.traitCollectionDidChange(previousTraitCollection)
          self.topLabel.font = .preferredFont(forTextStyle: .headline, compatibleWith: self.traitCollection)
          self.leadingLabel.font = .preferredFont(forTextStyle: .body, compatibleWith: self.traitCollection)
          self.trailingLabel.font = .preferredFont(forTextStyle: .body, compatibleWith: self.traitCollection)
          self.bottomLabel.font = .preferredFont(forTextStyle: .subheadline, compatibleWith: self.traitCollection)
          self.view.setNeedsUpdateConstraints()
          self.view.updateConstraintsIfNeeded()
        }
      }

      let myViewController = MyViewController()
      let navController = UINavigationController(rootViewController: myViewController)
      let viewController = UITabBarController()
      viewController.setViewControllers([navController], animated: false)

      assertSnapshot(matching: viewController, as: .image(on: .iPhoneSe), named: "iphone-se")
      assertSnapshot(matching: viewController, as: .image(on: .iPhone8), named: "iphone-8")
      assertSnapshot(matching: viewController, as: .image(on: .iPhone8Plus), named: "iphone-8-plus")
      assertSnapshot(matching: viewController, as: .image(on: .iPhoneX), named: "iphone-x")
      assertSnapshot(matching: viewController, as: .image(on: .iPhoneXr), named: "iphone-xr")
      assertSnapshot(matching: viewController, as: .image(on: .iPhoneXsMax), named: "iphone-xs-max")
      assertSnapshot(matching: viewController, as: .image(on: .iPadMini), named: "ipad-mini")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro10_5), named: "ipad-pro-10-5")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro11), named: "ipad-pro-11")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro12_9), named: "ipad-pro-12-9")

      assertSnapshot(matching: viewController, as: .image(on: .iPhoneSe(.portrait)), named: "iphone-se")
      assertSnapshot(matching: viewController, as: .image(on: .iPhone8(.portrait)), named: "iphone-8")
      assertSnapshot(matching: viewController, as: .image(on: .iPhone8Plus(.portrait)), named: "iphone-8-plus")
      assertSnapshot(matching: viewController, as: .image(on: .iPhoneX(.portrait)), named: "iphone-x")
      assertSnapshot(matching: viewController, as: .image(on: .iPhoneXr(.portrait)), named: "iphone-xr")
      assertSnapshot(matching: viewController, as: .image(on: .iPhoneXsMax(.portrait)), named: "iphone-xs-max")
      assertSnapshot(matching: viewController, as: .image(on: .iPadMini(.landscape)), named: "ipad-mini")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro10_5(.landscape)), named: "ipad-pro-10-5")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro11(.landscape)), named: "ipad-pro-11")
      assertSnapshot(matching: viewController, as: .image(on: .iPadPro12_9(.landscape)), named: "ipad-pro-12-9")

      assertSnapshot(
        matching: viewController, as: .image(on: .iPhoneSe(.landscape)), named: "iphone-se-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPhone8(.landscape)), named: "iphone-8-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPhone8Plus(.landscape)), named: "iphone-8-plus-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPhoneX(.landscape)), named: "iphone-x-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPhoneXr(.landscape)), named: "iphone-xr-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPhoneXsMax(.landscape)), named: "iphone-xs-max-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPadMini(.portrait)), named: "ipad-mini-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPadPro10_5(.portrait)), named: "ipad-pro-10-5-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPadPro11(.portrait)), named: "ipad-pro-11-alternative")
      assertSnapshot(
        matching: viewController, as: .image(on: .iPadPro12_9(.portrait)), named: "ipad-pro-12-9-alternative")
    }
    #endif
  }

  func testCollectionViewsWithMultipleScreenSizes() {
    #if os(iOS)

    final class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

      let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 20
        return layout
      }()

      lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)

      override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(collectionView)

        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
          collectionView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
          collectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
          collectionView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
          collectionView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        ])

        collectionView.reloadData()
      }

      override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
      }

      override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        collectionView.collectionViewLayout.invalidateLayout()
      }

      func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.contentView.backgroundColor = .orange
        return cell
      }

      func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
      }

      func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
        ) -> CGSize {
        return CGSize(
          width: min(collectionView.frame.width - 50, 300),
          height: collectionView.frame.height
        )
      }

    }

    let viewController = CollectionViewController()

    assertSnapshots(matching: viewController, as: [
      "ipad": .image(on: .iPadPro12_9),
      "iphoneSe": .image(on: .iPhoneSe),
      "iphone8": .image(on: .iPhone8),
      "iphoneMax": .image(on: .iPhoneXsMax)
    ])
    #endif
  }

  func testTraitsWithView() {
    #if os(iOS)
    if #available(iOS 11.0, *) {
      let label = UILabel()
      label.font = .preferredFont(forTextStyle: .title1)
      label.adjustsFontForContentSizeCategory = true
      label.text = "What's the point?"

      allContentSizes.forEach { name, contentSize in
        assertSnapshot(
          matching: label,
          as: .image(traits: .init(preferredContentSizeCategory: contentSize)),
          named: "label-\(name)"
        )
      }
    }
    #endif
  }

  func testTraitsWithViewController() {
    #if os(iOS)
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .title1)
    label.adjustsFontForContentSizeCategory = true
    label.text = "What's the point?"

    let viewController = UIViewController()
    viewController.view.addSubview(label)

    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: viewController.view.layoutMarginsGuide.leadingAnchor),
      label.topAnchor.constraint(equalTo: viewController.view.layoutMarginsGuide.topAnchor),
      label.trailingAnchor.constraint(equalTo: viewController.view.layoutMarginsGuide.trailingAnchor)
    ])

    allContentSizes.forEach { name, contentSize in
      assertSnapshot(
        matching: viewController,
        as: .recursiveDescription(on: .iPhoneSe, traits: .init(preferredContentSizeCategory: contentSize)),
        named: "label-\(name)"
      )
    }
    #endif
  }

  func testUIBezierPath() {
    #if os(iOS) || os(tvOS)
    let path = UIBezierPath.heart

    let osName: String
    #if os(iOS)
    osName = "iOS"
    #elseif os(tvOS)
    osName = "tvOS"
    #endif

    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      assertSnapshot(matching: path, as: .image, named: osName)
    }

    if #available(iOS 11.0, tvOS 11.0, *) {
      assertSnapshot(matching: path, as: .elementsDescription, named: osName)
    }
    #endif
  }

  func testUIColor() {
    #if os(iOS) || os(tvOS)
    let color = UIColor(
        red: 0.2,
        green: 0.4,
        blue: 0.6,
        alpha: 0.8
    )

    let osName: String
    #if os(iOS)
    osName = "iOS"
    #elseif os(tvOS)
    osName = "tvOS"
    #elseif os(macOS)
    osName = "macOS"
    #endif

    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      assertSnapshot(matching: color, as: .color(precision: 1.0), named: osName)
    }
    #endif
  }

  func testUIView() {
    #if os(iOS)
    let view = UIButton(type: .contactAdd)
    assertSnapshot(matching: view, as: .image)
    assertSnapshot(matching: view, as: .recursiveDescription)
    #endif
  }

  func testUIViewControllerLifeCycle() {
    #if os(iOS)
    class ViewController: UIViewController {
      let viewDidLoadExpectation: XCTestExpectation
      let viewWillAppearExpectation: XCTestExpectation
      let viewDidAppearExpectation: XCTestExpectation
      let viewWillDisappearExpectation: XCTestExpectation
      let viewDidDisappearExpectation: XCTestExpectation
      init(viewDidLoadExpectation: XCTestExpectation,
           viewWillAppearExpectation: XCTestExpectation,
           viewDidAppearExpectation: XCTestExpectation,
           viewWillDisappearExpectation: XCTestExpectation,
           viewDidDisappearExpectation: XCTestExpectation){
        self.viewDidLoadExpectation = viewDidLoadExpectation
        self.viewWillAppearExpectation = viewWillAppearExpectation
        self.viewDidAppearExpectation = viewDidAppearExpectation
        self.viewWillDisappearExpectation = viewWillDisappearExpectation
        self.viewDidDisappearExpectation = viewDidDisappearExpectation
        super.init(nibName: nil, bundle: nil)
      }
      required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
      }
      override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadExpectation.fulfill()
      }
      override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearExpectation.fulfill()
      }
      override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearExpectation.fulfill()
      }
      override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearExpectation.fulfill()
      }
      override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDidDisappearExpectation.fulfill()
      }
    }

    let viewDidLoadExpectation = expectation(description: "viewDidLoad")
    let viewWillAppearExpectation = expectation(description: "viewWillAppear")
    let viewDidAppearExpectation = expectation(description: "viewDidAppear")
    let viewWillDisappearExpectation = expectation(description: "viewWillDisappear")
    let viewDidDisappearExpectation = expectation(description: "viewDidDisappear")
    viewWillAppearExpectation.expectedFulfillmentCount = 4
    viewDidAppearExpectation.expectedFulfillmentCount = 4
    viewWillDisappearExpectation.expectedFulfillmentCount = 4
    viewDidDisappearExpectation.expectedFulfillmentCount = 4

    let viewController = ViewController(
      viewDidLoadExpectation: viewDidLoadExpectation,
      viewWillAppearExpectation: viewWillAppearExpectation,
      viewDidAppearExpectation: viewDidAppearExpectation,
      viewWillDisappearExpectation: viewWillDisappearExpectation,
      viewDidDisappearExpectation: viewDidDisappearExpectation
    )

    assertSnapshot(matching: viewController, as: .image)
    assertSnapshot(matching: viewController, as: .image)

    wait(for: [
      viewDidLoadExpectation,
      viewWillAppearExpectation,
      viewDidAppearExpectation,
      viewWillDisappearExpectation,
      viewDidDisappearExpectation,
    ], timeout: 1.0, enforceOrder: true)
    #endif
  }

  func testCALayer() {
    #if os(iOS)
    let layer = CALayer()
    layer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    layer.backgroundColor = UIColor.red.cgColor
    layer.borderWidth = 4.0
    layer.borderColor = UIColor.black.cgColor
    assertSnapshot(matching: layer, as: .image)
    #endif
  }

  func testCALayerWithGradient() {
    #if os(iOS)
    let baseLayer = CALayer()
    baseLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    let gradientLayer = CAGradientLayer()
    gradientLayer.colors = [UIColor.red.cgColor, UIColor.yellow.cgColor]
    gradientLayer.frame = baseLayer.frame
    baseLayer.addSublayer(gradientLayer)
    assertSnapshot(matching: baseLayer, as: .image)
    #endif
  }

  func testViewControllerHierarchy() {
    #if os(iOS)
    let page = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    page.setViewControllers([UIViewController()], direction: .forward, animated: false)
    let tab = UITabBarController()
    tab.viewControllers = [
      UINavigationController(rootViewController: page),
      UINavigationController(rootViewController: UIViewController()),
      UINavigationController(rootViewController: UIViewController()),
      UINavigationController(rootViewController: UIViewController()),
      UINavigationController(rootViewController: UIViewController())
    ]
    assertSnapshot(matching: tab, as: .hierarchy)
    #endif
  }

  func testURLRequest() {
    var get = URLRequest(url: URL(string: "https://www.pointfree.co/")!)
    get.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    get.addValue("text/html", forHTTPHeaderField: "Accept")
    get.addValue("application/json", forHTTPHeaderField: "Content-Type")
    assertSnapshot(matching: get, as: .raw, named: "get")
    assertSnapshot(matching: get, as: .curl, named: "get-curl")

    var post = URLRequest(url: URL(string: "https://www.pointfree.co/subscribe")!)
    post.httpMethod = "POST"
    post.addValue("pf_session={\"user_id\":\"0\"}", forHTTPHeaderField: "Cookie")
    post.addValue("text/html", forHTTPHeaderField: "Accept")
    post.httpBody = Data("pricing[billing]=monthly&pricing[lane]=individual".utf8)
    assertSnapshot(matching: post, as: .raw, named: "post")
    assertSnapshot(matching: post, as: .curl, named: "post-curl")
    
    var postWithJSON = URLRequest(url: URL(string: "http://dummy.restapiexample.com/api/v1/create")!)
    postWithJSON.httpMethod = "POST"
    postWithJSON.addValue("application/json", forHTTPHeaderField: "Content-Type")
    postWithJSON.addValue("application/json", forHTTPHeaderField: "Accept")
    postWithJSON.httpBody = Data("{\"name\":\"tammy134235345235\", \"salary\":0, \"age\":\"tammy133\"}".utf8)
    assertSnapshot(matching: postWithJSON, as: .raw, named: "post-with-json")
    assertSnapshot(matching: postWithJSON, as: .curl, named: "post-with-json-curl")

    var head = URLRequest(url: URL(string: "https://www.pointfree.co/")!)
    head.httpMethod = "HEAD"
    head.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    assertSnapshot(matching: head, as: .raw, named: "head")
    assertSnapshot(matching: head, as: .curl, named: "head-curl")

    post = URLRequest(url: URL(string: "https://www.pointfree.co/subscribe")!)
    post.httpMethod = "POST"
    post.addValue("pf_session={\"user_id\":\"0\"}", forHTTPHeaderField: "Cookie")
    post.addValue("application/json", forHTTPHeaderField: "Accept")
    post.httpBody = Data("""
                         {"pricing": {"lane": "individual","billing": "monthly"}}
                         """.utf8)
    _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: """
    POST https://www.pointfree.co/subscribe
    Accept: application/json
    Cookie: pf_session={"user_id":"0"}
    
    {
      "pricing" : {
        "billing" : "monthly",
        "lane" : "individual"
      }
    }
    """)
  }

  func testWebView() throws {
    #if os(iOS) || os(macOS)
    let fixtureUrl = URL(fileURLWithPath: String(#file), isDirectory: false)
      .deletingLastPathComponent()
      .appendingPathComponent("__Fixtures__/pointfree.html")
    let html = try String(contentsOf: fixtureUrl)
    let webView = WKWebView()
    webView.loadHTMLString(html, baseURL: nil)
    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      assertSnapshot(
        matching: webView,
        as: .image(size: .init(width: 800, height: 600)),
        named: platform
      )
    }
    #endif
  }

  func testViewWithZeroHeightOrWidth() {
    #if os(iOS) || os(tvOS)
    var rect = CGRect(x: 0, y: 0, width: 350, height: 0)
    var view = UIView(frame: rect)
    view.backgroundColor = .red
    assertSnapshot(matching: view, as: .image, named: "noHeight")
    
    rect = CGRect(x: 0, y: 0, width: 0, height: 350)
    view = UIView(frame: rect)
    view.backgroundColor = .green
    assertSnapshot(matching: view, as: .image, named: "noWidth")

    rect = CGRect(x: 0, y: 0, width: 0, height: 0)
    view = UIView(frame: rect)
    view.backgroundColor = .blue
    assertSnapshot(matching: view, as: .image, named: "noWidth.noHeight")
    #endif
  }

  func testEmbeddedWebView() throws {
    #if os(iOS)
    let label = UILabel()
    label.text = "Hello, Blob!"

    let fixtureUrl = URL(fileURLWithPath: String(#file), isDirectory: false)
      .deletingLastPathComponent()
      .appendingPathComponent("__Fixtures__/pointfree.html")
    let html = try String(contentsOf: fixtureUrl)
    let webView = WKWebView()
    webView.loadHTMLString(html, baseURL: nil)
    webView.isHidden = true

    let stackView = UIStackView(arrangedSubviews: [label, webView])
    stackView.axis = .vertical

    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      assertSnapshot(
        matching: stackView,
        as: .image(size: .init(width: 800, height: 600)),
        named: platform
      )
    }
    #endif
  }

  @available(iOS 13.0, *)
  func testSwiftUIView_iOS() {
    #if os(iOS)
    struct MyView: SwiftUI.View {
      var body: some SwiftUI.View {
        HStack {
          Image(systemName: "checkmark.circle.fill")
            Text("Checked").fixedSize()
        }
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 5.0).fill(Color.blue))
        .padding(10)
      }
    }

    let view = MyView().background(Color.yellow)

    assertSnapshot(matching: view, as: .image(traits: .init(userInterfaceStyle: .light)))
    assertSnapshot(matching: view, as: .image(layout: .sizeThatFits, traits: .init(userInterfaceStyle: .light)), named: "size-that-fits")
    assertSnapshot(matching: view, as: .image(layout: .fixed(width: 200.0, height: 100.0), traits: .init(userInterfaceStyle: .light)), named: "fixed")
    assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhoneSe), traits: .init(userInterfaceStyle: .light)), named: "device")
    #endif
  }

  @available(tvOS 13.0, *)
  func testSwiftUIView_tvOS() {
    #if os(tvOS)
    struct MyView: SwiftUI.View {
      var body: some SwiftUI.View {
        HStack {
          Image(systemName: "checkmark.circle.fill")
            Text("Checked").fixedSize()
        }
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 5.0).fill(Color.blue))
        .padding(10)
      }
    }
    let view = MyView().background(Color.yellow)

    assertSnapshot(matching: view, as: .image())
    assertSnapshot(matching: view, as: .image(layout: .sizeThatFits), named: "size-that-fits")
    assertSnapshot(matching: view, as: .image(layout: .fixed(width: 300.0, height: 100.0)), named: "fixed")
    assertSnapshot(matching: view, as: .image(layout: .device(config: .tv)), named: "device")
    #endif
  }

  @available(*, deprecated)
  func testIsRecordingProxy() {
    SnapshotTesting.record = true
    XCTAssertEqual(isRecording, true)

    SnapshotTesting.record = false
    XCTAssertEqual(isRecording, false)
  }
}

#if os(iOS)
private let allContentSizes =
  [
    "extra-small": UIContentSizeCategory.extraSmall,
    "small": .small,
    "medium": .medium,
    "large": .large,
    "extra-large": .extraLarge,
    "extra-extra-large": .extraExtraLarge,
    "extra-extra-extra-large": .extraExtraExtraLarge,
    "accessibility-medium": .accessibilityMedium,
    "accessibility-large": .accessibilityLarge,
    "accessibility-extra-large": .accessibilityExtraLarge,
    "accessibility-extra-extra-large": .accessibilityExtraExtraLarge,
    "accessibility-extra-extra-extra-large": .accessibilityExtraExtraExtraLarge,
    ]
#endif

#if os(Linux)
extension SnapshotTestingTests {
  static var allTests : [(String, (SnapshotTestingTests) -> () throws -> Void)] {
    return [
      ("testAny", testAny),
      ("testAnySnapshotStringConvertible", testAnySnapshotStringConvertible),
      ("testAutolayout", testAutolayout),
      ("testDeterministicDictionaryAndSetSnapshots", testDeterministicDictionaryAndSetSnapshots),
      ("testEncodable", testEncodable),
      ("testMixedViews", testMixedViews),
      ("testMultipleSnapshots", testMultipleSnapshots),
      ("testNamedAssertion", testNamedAssertion),
      ("testPrecision", testPrecision),
      ("testSCNView", testSCNView),
      ("testSKView", testSKView),
      ("testTableViewController", testTableViewController),
      ("testTraits", testTraits),
      ("testTraitsEmbeddedInTabNavigation", testTraitsEmbeddedInTabNavigation),
      ("testTraitsWithView", testTraitsWithView),
      ("testUIView", testUIView),
      ("testURLRequest", testURLRequest),
      ("testWebView", testWebView),
    ]
  }
}
#endif
