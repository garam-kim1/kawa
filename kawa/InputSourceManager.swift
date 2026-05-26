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
