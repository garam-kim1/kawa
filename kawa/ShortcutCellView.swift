import Cocoa
import KeyboardShortcuts

class ShortcutCellView: NSTableCellView {
  @IBOutlet weak var recorderContainer: NSView!

  private var recorder: KeyboardShortcuts.RecorderCocoa?
  private var inputSource: InputSource?

  func setInputSource(_ inputSource: InputSource) {
    self.inputSource = inputSource

    recorder?.removeFromSuperview()

    let recorder = KeyboardShortcuts.RecorderCocoa(for: InputSourceManager.shortcutName(for: inputSource))
    recorder.translatesAutoresizingMaskIntoConstraints = false
    recorderContainer.addSubview(recorder)
    NSLayoutConstraint.activate([
      recorder.leadingAnchor.constraint(equalTo: recorderContainer.leadingAnchor),
      recorder.trailingAnchor.constraint(equalTo: recorderContainer.trailingAnchor),
      recorder.centerYAnchor.constraint(equalTo: recorderContainer.centerYAnchor),
    ])
    self.recorder = recorder
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    recorder?.removeFromSuperview()
    recorder = nil
    inputSource = nil
  }
}
