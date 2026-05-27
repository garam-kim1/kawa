import Cocoa

enum PermanentStorage {
  static var defaults: UserDefaults = .standard

  private static func object<T>(forKey key: StorageKey, withDefault defaultValue: T) -> T {
    if let val = defaults.object(forKey: key.rawValue) as? T {
      return val
    } else {
      return defaultValue
    }
  }

  private static func set<T>(_ value: T, forKey key: StorageKey) {
    defaults.set((value as AnyObject), forKey: key.rawValue)
  }

  enum StorageKey: String {
    case showsNotification = "show-notification"
    case imeActivationDelayMs = "ime-activation-delay-ms"
  }

  static var showsNotification: Bool {
    get { object(forKey: .showsNotification, withDefault: false) }
    set { set(newValue, forKey: .showsNotification) }
  }

  /// Milliseconds Kawa briefly holds focus so a CJKV input method can engage
  /// (see `InputSourceManager.activateInputMethod()`). Smaller values reduce
  /// the chance of swallowing a fast first keystroke; too small and the input
  /// method may not finish switching (typing leaks as the previous layout).
  /// No UI — tune it without rebuilding via, e.g.:
  ///   defaults write net.noraesae.Kawa ime-activation-delay-ms 30
  static var imeActivationDelayMs: Int {
    get { object(forKey: .imeActivationDelayMs, withDefault: 50) }
    set { set(newValue, forKey: .imeActivationDelayMs) }
  }
}
