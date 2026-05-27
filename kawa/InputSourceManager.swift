import Carbon
import Cocoa
import KeyboardShortcuts
import UserNotifications

class InputSource {
  let tisInputSource: TISInputSource
  let icon: NSImage?

  var id: String {
    return tisInputSource.id
  }

  var name: String {
    return tisInputSource.name
  }

  /// Chinese/Japanese/Korean/Vietnamese sources are IME-backed and need the
  /// extra activation step in `select()` to actually engage.
  var isCJKV: Bool {
    if let lang = tisInputSource.sourceLanguages.first {
      return lang == "ko" || lang == "ja" || lang == "vi" || lang.hasPrefix("zh")
    }
    return false
  }

  init(tisInputSource: TISInputSource) {
    self.tisInputSource = tisInputSource

    var iconImage: NSImage? = nil

    if let imageURL = tisInputSource.iconImageURL {
      for url in [imageURL.retinaImageURL, imageURL.tiffImageURL, imageURL] {
        if let image = NSImage(contentsOf: url) {
          iconImage = image
          break
        }
      }
    }

    self.icon = iconImage
  }

  func select() {
    TISSelectInputSource(tisInputSource)

    // `TISSelectInputSource` alone often only updates the menu-bar indicator
    // for an IME-backed CJKV source: the focused app keeps composing in the
    // previous layout (plain English), most visibly in browsers and Electron
    // apps such as Slack in a web browser. Nudging the IME with a brief key
    // window forces it to take over — see `activateInputMethod()`.
    if isCJKV {
      InputSourceManager.activateInputMethod()
    }
  }
}

extension InputSource: Equatable {
  static func == (lhs: InputSource, rhs: InputSource) -> Bool {
    return lhs.id == rhs.id
  }
}

extension InputSource {
  static var sources: [InputSource] {
    guard let list = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
      return []
    }

    return list
      .filter { $0.category == TISInputSource.Category.keyboardInputSource && $0.isSelectable }
      .map { InputSource(tisInputSource: $0) }
  }
}

enum InputSourceManager {
  static func shortcutNameRawValue(forInputSourceID id: String) -> String {
    id.replacingOccurrences(of: ".", with: "-")
  }

  static func shortcutName(for inputSource: InputSource) -> KeyboardShortcuts.Name {
    KeyboardShortcuts.Name(shortcutNameRawValue(forInputSourceID: inputSource.id))
  }

  @MainActor
  static func bindAllShortcuts() {
    for source in InputSource.sources {
      bind(source)
    }
  }

  @MainActor
  static func bind(_ inputSource: InputSource) {
    let name = shortcutName(for: inputSource)
    let sourceID = inputSource.id
    KeyboardShortcuts.removeHandler(for: name)
    KeyboardShortcuts.onKeyDown(for: name) {
      guard let source = InputSource.sources.first(where: { $0.id == sourceID }) else { return }
      source.select()

      if PermanentStorage.showsNotification {
        showNotification(source.name, icon: source.icon)
      }
    }
  }

  /// True only while `activateInputMethod()` is briefly holding focus for the
  /// IME nudge. `AppDelegate` checks this so the focus-steal isn't mistaken
  /// for a real user activation (which would flash the preferences window).
  static var isActivatingInputMethod = false

  /// Force the just-selected CJKV input method to genuinely engage.
  ///
  /// macOS only activates an IME for the app that owns the key window. Kawa is
  /// a background (LSUIElement) app, so a plain `TISSelectInputSource` leaves
  /// the front app — especially browsers and Electron apps like Slack web —
  /// still composing in the previous layout even though the menu-bar indicator
  /// changed. Briefly giving Kawa an (invisible) key window makes the IME
  /// attach to a real input client and take over system-wide; focus is then
  /// handed back to whatever the user was typing in.
  ///
  /// Adapted from laishulu/macism's temporary-window workaround, but kept
  /// non-terminating since Kawa is a long-running app.
  static func activateInputMethod() {
    // The shorter we hold focus, the less likely a fast first keystroke is
    // swallowed; too short and the IME may not finish switching. Configurable.
    let delay = TimeInterval(max(0, PermanentStorage.imeActivationDelayMs)) / 1000.0

    DispatchQueue.main.async {
      // Remember who the user was typing in so focus can be restored.
      let previousApp = NSWorkspace.shared.frontmostApplication

      let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
        styleMask: [.titled],  // a titled window is required to become key
        backing: .buffered,
        defer: false
      )
      window.isReleasedWhenClosed = false
      window.backgroundColor = .clear
      window.isOpaque = false
      window.hasShadow = false
      window.ignoresMouseEvents = true
      window.titlebarAppearsTransparent = true
      window.level = .screenSaver
      window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
      window.standardWindowButton(.closeButton)?.isHidden = true
      window.standardWindowButton(.miniaturizeButton)?.isHidden = true
      window.standardWindowButton(.zoomButton)?.isHidden = true

      // Park it in the bottom-right corner; with a clear background it stays
      // invisible regardless of any platform-imposed minimum size.
      if let screen = NSScreen.main {
        let frame = screen.visibleFrame
        window.setFrameOrigin(NSPoint(x: frame.maxX - 1, y: frame.minY))
      }

      // Briefly bring Kawa forward so the IME attaches to our key window.
      // Flag it so AppDelegate doesn't open preferences in response.
      isActivatingInputMethod = true
      if #available(macOS 14.0, *) {
        NSApp.activate()
      } else {
        NSApp.activate(ignoringOtherApps: true)
      }
      window.makeKeyAndOrderFront(nil)

      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        window.orderOut(nil)
        // Hand focus back to whatever the user was typing in.
        if #available(macOS 14.0, *) {
          previousApp?.activate()
        } else {
          previousApp?.activate(options: [])
        }
        isActivatingInputMethod = false
      }
    }
  }

  private static func showNotification(_ message: String, icon: NSImage?) {
    let center = UNUserNotificationCenter.current()
    center.removeAllDeliveredNotifications()

    let content = UNMutableNotificationContent()
    content.body = message
    if let icon, let attachment = notificationAttachment(for: icon) {
      content.attachments = [attachment]
    }

    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    center.add(request, withCompletionHandler: nil)
  }

  private static func notificationAttachment(for icon: NSImage) -> UNNotificationAttachment? {
    guard let tiff = icon.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
      return nil
    }

    let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent("kawa-notification-icons", isDirectory: true)
    let tempURL = dir
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("png")

    do {
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
      try data.write(to: tempURL, options: [.atomic])
      let attachment = try UNNotificationAttachment(identifier: "icon", url: tempURL, options: nil)
      try? FileManager.default.removeItem(at: tempURL)
      return attachment
    } catch {
      try? FileManager.default.removeItem(at: tempURL)
      return nil
    }
  }
}

extension URL {
  var retinaImageURL: URL {
    var components = pathComponents
    let filename: String = components.removeLast()
    let ext: String = pathExtension
    let retinaFilename = filename.replacingOccurrences(of: "." + ext, with: "@2x." + ext)
    return NSURL.fileURL(withPathComponents: components + [retinaFilename])!
  }

  var tiffImageURL: URL {
    return deletingPathExtension().appendingPathExtension("tiff")
  }
}
