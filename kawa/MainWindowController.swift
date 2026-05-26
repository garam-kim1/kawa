import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {
  static let shared: MainWindowController = {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    return storyboard.instantiateController(withIdentifier: "MainWindow") as! MainWindowController
  }()

  func showAndActivate(_ sender: AnyObject?) {
    self.showWindow(sender)
    self.window?.makeKeyAndOrderFront(sender)
    if #available(macOS 14.0, *) {
      NSApp.activate()
    } else {
      NSApp.activate(ignoringOtherApps: true)
    }
  }

  func windowWillClose(_ notification: Notification) {
    deactivate()
  }

  func deactivate() {
    guard let owner = NSWorkspace.shared.menuBarOwningApplication else { return }
    if #available(macOS 14.0, *) {
      owner.activate()
    } else {
      owner.activate(options: [])
    }
  }
}
