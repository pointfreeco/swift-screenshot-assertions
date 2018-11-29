@testable import SnapshotTesting
import XCTest

#if os(iOS) || os(macOS) || os(tvOS)
import SceneKit
import SpriteKit
#endif
#if os(iOS) || os(macOS)
import WebKit
#endif

#if os(Linux)
typealias TestCase = SnapshotTestCase
#else
typealias TestCase = XCTestCase
#endif

class SnapshotTestCaseTests: TestCase {
  override func setUp() {
    super.setUp()
    diffTool = "ksdiff"
//    record = true
  }

  func testWithAny() {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    assertSnapshot(matching: user, as: .dump)
    assertSnapshot(matching: Data("Hello, world!".utf8), as: .dump)
    assertSnapshot(matching: URL(string: "https://www.pointfree.co")!, as: .dump)
  }

  func testNamedAssertion() {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    assertSnapshot(matching: user, as: .dump, named: "named")
  }

  func testWithDate() {
    assertSnapshot(matching: Date(timeIntervalSinceReferenceDate: 0), as: .dump)
  }

  func testWithEncodable() {
    struct User: Encodable { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    if #available(iOS 11.0, macOS 10.13, tvOS 11.0, *) {
      assertSnapshot(matching: user, as: .json)
    }
    assertSnapshot(matching: user, as: .plist)
  }

  func testWithNSObject() {
    assertSnapshot(matching: NSObject(), as: .dump)
  }

  func testMultipleSnapshots() {
    assertSnapshot(matching: [1], as: .dump)
    assertSnapshot(matching: [1, 2], as: .dump)
  }

  func testUIView() {
    #if os(iOS)
    let view = UIButton(type: .contactAdd)
    assertSnapshot(matching: view, as: .image)
    assertSnapshot(matching: view, as: .recursiveDescription)
    #endif
  }

  func testMixedViews() {
    #if os(iOS) || os(macOS)
    // NB: CircleCI crashes while trying to instantiate SKView
    if #available(macOS 10.14, *) {
      let webView = WKWebView(frame: .init(x: 0, y: 0, width: 50, height: 50))
      webView.loadHTMLString("🌎", baseURL: nil)

      let skView = SKView(frame: .init(x: 50, y: 0, width: 50, height: 50))
      let scene = SKScene(size: .init(width: 50, height: 50))
      let node = SKShapeNode(circleOfRadius: 15)
      node.fillColor = .red
      node.position = .init(x: 25, y: 25)
      scene.addChild(node)
      skView.presentScene(scene)

      let view = View(frame: .init(x: 0, y: 0, width: 100, height: 50))
      view.addSubview(webView)
      view.addSubview(skView)

      assertSnapshot(matching: view, as: .image, named: platform)
    }
    #endif
  }

  func testNSView() {
    #if os(macOS)
    let button = NSButton()
    button.bezelStyle = .rounded
    button.title = "Push Me"
    button.sizeToFit()
    if #available(macOS 10.14, *) {
      assertSnapshot(matching: button, as: .image)
      assertSnapshot(matching: button, as: .recursiveDescription)
    }
    #endif
  }

  func testWebView() throws {
    #if os(iOS) || os(macOS)
    let fixtureUrl = URL(fileURLWithPath: String(#file))
      .deletingLastPathComponent()
      .appendingPathComponent("__Fixtures__/pointfree.html")
    let html = try String(contentsOf: fixtureUrl)
    let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    webView.loadHTMLString(html, baseURL: nil)
    if #available(macOS 10.14, *) {
      assertSnapshot(matching: webView, as: .image, named: platform)
    }
    #endif
  }

  func testSCNView() {
    #if os(iOS) || os(macOS) || os(tvOS)
    // NB: CircleCI crashes while trying to instantiate SCNView
    if #available(macOS 10.14, *) {
      let scene = SCNScene()

      let sphereGeometry = SCNSphere(radius: 3)
      sphereGeometry.segmentCount = 200
      let sphereNode = SCNNode(geometry: sphereGeometry)
      sphereNode.position = SCNVector3Zero
      scene.rootNode.addChildNode(sphereNode)

      sphereGeometry.firstMaterial?.diffuse.contents = URL(fileURLWithPath: String(#file))
        .deletingLastPathComponent()
        .appendingPathComponent("__Fixtures__/earth.png")

      let cameraNode = SCNNode()
      cameraNode.camera = SCNCamera()
      cameraNode.position = SCNVector3Make(0, 0, 8)
      scene.rootNode.addChildNode(cameraNode)

      let omniLight = SCNLight()
      omniLight.type = .omni
      let omniLightNode = SCNNode()
      omniLightNode.light = omniLight
      omniLightNode.position = SCNVector3Make(10, 10, 10)
      scene.rootNode.addChildNode(omniLightNode)

      assertSnapshot(
        matching: scene,
        as: .image(size: .init(width: 500, height: 500)),
        named: platform
      )
    }
    #endif
  }

  func testSKView() {
    #if os(iOS) || os(macOS) || os(tvOS)
    // NB: CircleCI crashes while trying to instantiate SKView
    if #available(macOS 10.14, *) {
      let scene = SKScene(size: .init(width: 50, height: 50))
      let node = SKShapeNode(circleOfRadius: 15)
      node.fillColor = .red
      node.position = .init(x: 25, y: 25)
      scene.addChild(node)

      assertSnapshot(
        matching: scene,
        as: .image(size: .init(width: 50, height: 50)),
        named: platform
      )
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
    if #available(macOS 10.14, *) {
      label.text = "Hello."
      assertSnapshot(matching: label, as: .image(precision: 0.9), named: platform)
      label.text = "Hello"
      assertSnapshot(matching: label, as: .image(precision: 0.9), named: platform)
    }
    #endif
  }

  func testTraits() {
    #if os(iOS)
    class MyViewController: UIViewController {
      let label = UILabel()

      override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
        self.label.text = "What's the point?"
        self.label.textAlignment = .center
        self.label.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(self.label)
        NSLayoutConstraint.activate([
          self.view.topAnchor.constraint(equalTo: self.label.topAnchor),
          self.view.bottomAnchor.constraint(equalTo: self.label.bottomAnchor),
          self.view.leadingAnchor.constraint(equalTo: self.label.leadingAnchor),
          self.view.trailingAnchor.constraint(equalTo: self.label.trailingAnchor),
          ])
      }

      override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.label.font = .preferredFont(forTextStyle: .body, compatibleWith: self.traitCollection)
      }
    }

    let viewController = MyViewController()

    assertSnapshot(matching: viewController, as: .image(on: .iPhoneSe), named: "iphone-se")
    assertSnapshot(matching: viewController, as: .image(on: .iPhone8), named: "iphone-8")
    assertSnapshot(matching: viewController, as: .image(on: .iPhone8Plus), named: "iphone-8-plus")
    assertSnapshot(matching: viewController, as: .image(on: .iPadMini), named: "ipad-mini")
    assertSnapshot(matching: viewController, as: .image(on: .iPadPro10_5), named: "ipad-pro-10-5")
    assertSnapshot(matching: viewController, as: .image(on: .iPadPro12_9), named: "ipad-pro-12-9")

    assertSnapshot(matching: viewController, as: .image(on: .iPhoneSe(.portrait)), named: "iphone-se")
    assertSnapshot(matching: viewController, as: .image(on: .iPhone8(.portrait)), named: "iphone-8")
    assertSnapshot(matching: viewController, as: .image(on: .iPhone8Plus(.portrait)), named: "iphone-8-plus")
    assertSnapshot(matching: viewController, as: .image(on: .iPadMini(.landscape)), named: "ipad-mini")
    assertSnapshot(matching: viewController, as: .image(on: .iPadPro10_5(.landscape)), named: "ipad-pro-10-5")
    assertSnapshot(matching: viewController, as: .image(on: .iPadPro12_9(.landscape)), named: "ipad-pro-12-9")

    assertSnapshot(
      matching: viewController, as: .image(on: .iPhoneSe(.landscape)), named: "iphone-se-alternative")
    assertSnapshot(
      matching: viewController, as: .image(on: .iPhone8(.landscape)), named: "iphone-8-alternative")
    assertSnapshot(
      matching: viewController, as: .image(on: .iPhone8Plus(.landscape)), named: "iphone-8-plus-alternative")
    assertSnapshot(
      matching: viewController, as: .image(on: .iPadMini(.portrait)), named: "ipad-mini-alternative")
    assertSnapshot(
      matching: viewController, as: .image(on: .iPadPro10_5(.portrait)), named: "ipad-pro-10-5-alternative")
    assertSnapshot(
      matching: viewController, as: .image(on: .iPadPro12_9(.portrait)), named: "ipad-pro-12-9-alternative")

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
      ].forEach { name, contentSize in
        assertSnapshot(
          matching: viewController,
          as: .image(on: .iPhoneSe, traits: .init(preferredContentSizeCategory: contentSize)),
          named: "iphone-se-\(name)"
        )
    }
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
  }
}

#if os(Linux)
extension SnapshotTestCaseTests {
  static var allTests : [(String, (SnapshotTestCaseTests) -> () throws -> Void)] {
    return [
      ("testMixedViews", testMixedViews),
      ("testMultipleSnapshots", testMultipleSnapshots),
      ("testNamedAssertion", testNamedAssertion),
      ("testNSView", testNSView),
      ("testPrecision", testPrecision),
      ("testSCNView", testSCNView),
      ("testSKView", testSKView),
      ("testUIView", testUIView),
      ("testWebView", testWebView),
      ("testWithAny", testWithAny),
      ("testWithDate", testWithDate),
      ("testWithEncodable", testWithEncodable),
      ("testWithNSObject", testWithNSObject),
    ]
  }
}
#endif
