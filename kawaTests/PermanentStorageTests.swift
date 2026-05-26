import XCTest
@testable import Kawa

final class PermanentStorageTests: XCTestCase {
  private var suite: UserDefaults!
  private var suiteName: String!

  override func setUp() {
    super.setUp()
    suiteName = "net.noraesae.kawa.tests.\(UUID().uuidString)"
    suite = UserDefaults(suiteName: suiteName)
    PermanentStorage.defaults = suite
  }

  override func tearDown() {
    suite.removePersistentDomain(forName: suiteName)
    PermanentStorage.defaults = .standard
    super.tearDown()
  }

  func testShowsNotificationDefaultsToFalse() {
    XCTAssertFalse(PermanentStorage.showsNotification)
  }

  func testShowsNotificationRoundTrip() {
    PermanentStorage.showsNotification = true
    XCTAssertTrue(PermanentStorage.showsNotification)

    PermanentStorage.showsNotification = false
    XCTAssertFalse(PermanentStorage.showsNotification)
  }

  func testShowsNotificationPersistsAcrossDefaultsInstances() {
    PermanentStorage.showsNotification = true

    let freshInstance = UserDefaults(suiteName: suiteName)!
    PermanentStorage.defaults = freshInstance

    XCTAssertTrue(PermanentStorage.showsNotification)
  }
}
