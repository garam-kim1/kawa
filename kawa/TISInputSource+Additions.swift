import Carbon
import Foundation

extension TISInputSource {
  enum Category {
    static var keyboardInputSource: String {
      return kTISCategoryKeyboardInputSource as String
    }
  }

  private func getProperty(_ key: CFString) -> AnyObject? {
    guard let cfType = TISGetInputSourceProperty(self, key) else { return nil }
    return Unmanaged<AnyObject>.fromOpaque(cfType).takeUnretainedValue()
  }

  var id: String {
    return getProperty(kTISPropertyInputSourceID) as? String ?? ""
  }

  var name: String {
    return getProperty(kTISPropertyLocalizedName) as? String ?? ""
  }

  var category: String {
    return getProperty(kTISPropertyInputSourceCategory) as? String ?? ""
  }

  var isSelectable: Bool {
    return getProperty(kTISPropertyInputSourceIsSelectCapable) as? Bool ?? false
  }

  var sourceLanguages: [String] {
    return getProperty(kTISPropertyInputSourceLanguages) as? [String] ?? []
  }

  var iconImageURL: URL? {
    return getProperty(kTISPropertyIconImageURL) as? URL
  }
}
