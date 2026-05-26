import XCTest
@testable import Kawa

final class URLAdditionsTests: XCTestCase {
  func testRetinaImageURL() {
    let original = URL(fileURLWithPath: "/tmp/icon.png")
    XCTAssertEqual(original.retinaImageURL.lastPathComponent, "icon@2x.png")
  }

  func testRetinaImageURLPreservesDirectory() {
    let original = URL(fileURLWithPath: "/some/dir/icon.tiff")
    XCTAssertEqual(original.retinaImageURL.path, "/some/dir/icon@2x.tiff")
  }

  func testTiffImageURL() {
    let original = URL(fileURLWithPath: "/tmp/icon.png")
    XCTAssertEqual(original.tiffImageURL.lastPathComponent, "icon.tiff")
  }

  func testTiffImageURLFromExtensionless() {
    let original = URL(fileURLWithPath: "/tmp/icon")
    XCTAssertEqual(original.tiffImageURL.lastPathComponent, "icon.tiff")
  }
}
