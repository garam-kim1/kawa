import Cocoa
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  let statusBar = StatusBar.shared

  var justLaunched: Bool = true

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    InputSourceManager.bindAllShortcuts()
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    // Ignore the brief focus-steal Kawa uses to engage a CJKV input method —
    // otherwise the preferences window would flash open on every such switch.
    if InputSourceManager.isActivatingInputMethod {
      return
    }
    if !justLaunched {
      showPreferences()
    }
    justLaunched = false
  }

  @IBAction func showPreferences(_ sender: AnyObject? = nil) {
    MainWindowController.shared.showAndActivate(self)
  }

  @IBAction func hidePreferences(_ sender: AnyObject?) {
    MainWindowController.shared.close()
  }
}
