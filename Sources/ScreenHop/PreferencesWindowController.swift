import AppKit

@MainActor
protocol PreferencesWindowControllerDelegate: AnyObject {
    func preferencesWindowController(_ controller: PreferencesWindowController, didUpdatePoints points: [CursorPoint])
}

@MainActor
final class PreferencesWindowController: NSWindowController {
    weak var delegate: PreferencesWindowControllerDelegate?
    private var points: [CursorPoint] = []

    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let removeButton = NSButton()

    init(points: [CursorPoint]) {
        self.points = points
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Screen Hop Preferences"
        window.minSize = NSSize(width: 400, height: 300)
        window.center()
        super.init(window: window)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updatePoints(_ points: [CursorPoint]) {
        self.points = points
        tableView.reloadData()
    }

    private func setupUI() {
        guard let window = window, let contentView = window.contentView else { return }

        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        scrollView.frame = NSRect(x: 20, y: 60, width: 560, height: 320)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = NSTableHeaderView()
        tableView.allowsMultipleSelection = true

        let nameCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Name"))
        nameCol.title = "Name"
        nameCol.width = 180
        tableView.addTableColumn(nameCol)

        let displayCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Display"))
        displayCol.title = "Display"
        displayCol.width = 200
        tableView.addTableColumn(displayCol)

        let shortcutCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Shortcut"))
        shortcutCol.title = "Shortcut"
        shortcutCol.width = 120
        tableView.addTableColumn(shortcutCol)

        scrollView.documentView = tableView
        contentView.addSubview(scrollView)

        removeButton.title = "Remove Selected"
        removeButton.bezelStyle = .rounded
        removeButton.target = self
        removeButton.action = #selector(removeSelected)
        removeButton.frame = NSRect(x: 20, y: 20, width: 140, height: 32)
        contentView.addSubview(removeButton)

        // Setup constraints
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        removeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: removeButton.topAnchor, constant: -12),

            removeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            removeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            removeButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    @objc private func removeSelected() {
        let selectedRows = tableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }

        // Remove points in reverse order to maintain correct indices
        for index in selectedRows.sorted().reversed() {
            points.remove(at: index)
        }

        tableView.reloadData()
        delegate?.preferencesWindowController(self, didUpdatePoints: points)
    }
}

extension PreferencesWindowController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return points.count
    }
}

extension PreferencesWindowController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let point = points[row]
        let identifier = tableColumn?.identifier.rawValue ?? ""

        let cellIdentifier = NSUserInterfaceItemIdentifier(identifier + "Cell")
        let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView ?? {
            let view = NSTableCellView()
            view.identifier = cellIdentifier
            let textField = NSTextField()
            textField.isBezeled = false
            textField.drawsBackground = false
            textField.identifier = NSUserInterfaceItemIdentifier("Text")
            view.addSubview(textField)
            view.textField = textField
            textField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2),
                textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2),
                textField.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            return view
        }()

        switch identifier {
        case "Name":
            cell.textField?.isEditable = true
            cell.textField?.isSelectable = true
            cell.textField?.stringValue = point.name
            cell.textField?.target = self
            cell.textField?.action = #selector(nameChanged(_:))
        case "Display":
            cell.textField?.isEditable = false
            cell.textField?.isSelectable = true
            if let activeDisplay = DisplayService.resolve(uuid: point.displayUUID) {
                let isMain = activeDisplay.bounds.origin == .zero
                let width = Int(activeDisplay.bounds.width)
                let height = Int(activeDisplay.bounds.height)
                cell.textField?.stringValue = isMain ? "Main Display (\(width)x\(height))" : "External Display (\(width)x\(height))"
            } else {
                cell.textField?.stringValue = "Disconnected Display"
            }
        case "Shortcut":
            cell.textField?.isEditable = false
            cell.textField?.isSelectable = true
            cell.textField?.stringValue = point.shortcut.displayText
        default:
            break
        }

        return cell
    }

    @objc private func nameChanged(_ sender: NSTextField) {
        let row = tableView.row(for: sender)
        guard row >= 0, row < points.count else { return }
        let newName = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else {
            sender.stringValue = points[row].name
            return
        }
        points[row].name = newName
        delegate?.preferencesWindowController(self, didUpdatePoints: points)
    }
}
