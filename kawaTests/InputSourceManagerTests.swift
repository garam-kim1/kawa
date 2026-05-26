import XCTest
@testable import Kawa

final class InputSourceManagerTests: XCTestCase {
  func testShortcutNameReplacesDotsWithDashes() {
    XCTAssertEqual(
      InputSourceManager.shortcutNameRawValue(forInputSourceID: "com.apple.keylayout.US"),
      "com-apple-keylayout-US"
    )
  }

  func testShortcutNameWithoutDotsIsUnchanged() {
    XCTAssertEqual(
      InputSourceManager.shortcutNameRawValue(forInputSourceID: "simple-id"),
      "simple-id"
    )
  }

  func testShortcutNameWithEmptyString() {
    XCTAssertEqual(
      InputSourceManager.shortcutNameRawValue(forInputSourceID: ""),
      ""
    )
  }

  func testShortcutNameWithMultipleDots() {
    XCTAssertEqual(
      InputSourceManager.shortcutNameRawValue(forInputSourceID: "a.b.c.d"),
      "a-b-c-d"
    )
  }

  func testShortcutNameWithExistingDashes() {
    XCTAssertEqual(
      InputSourceManager.shortcutNameRawValue(forInputSourceID: "com-foo.bar"),
      "com-foo-bar"
    )
  }
}
