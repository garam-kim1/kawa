import Cocoa

class ShortcutViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
  private var sources: [InputSource] = []

  override func viewWillAppear() {
    super.viewWillAppear()
    sources = InputSource.sources
    ((view as? NSScrollView)?.documentView as? NSTableView)?.reloadData()
  }

  func numberOfRows(in tableView: NSTableView) -> Int {
    return sources.count
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let tableColumn, row < sources.count else { return nil }
    let inputSource = sources[row]

    switch tableColumn.identifier.rawValue {
    case "Keyboard":
      return createKeyboardCellView(tableView, inputSource)
    case "Shortcut":
      return createShorcutCellView(tableView, inputSource)
    default:
      return nil
    }
  }

  private func createKeyboardCellView(_ tableView: NSTableView, _ inputSource: InputSource) -> NSTableCellView? {
    let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "KeyboardCellView"), owner: self) as? NSTableCellView
    cell?.textField?.stringValue = inputSource.name
    cell?.imageView?.image = inputSource.icon
    return cell
  }

  private func createShorcutCellView(_ tableView: NSTableView, _ inputSource: InputSource) -> ShortcutCellView? {
    let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ShortcutCellView"), owner: self) as? ShortcutCellView
    cell?.setInputSource(inputSource)
    return cell
  }
}
