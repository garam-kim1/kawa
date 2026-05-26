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
  }

  static var showsNotification: Bool {
    get { object(forKey: .showsNotification, withDefault: false) }
    set { set(newValue, forKey: .showsNotification) }
  }
}
