//
//  DSYMListViewModel.swift
//  MacSymbolicator
//

import Cocoa

final class DSYMListViewModel: NSObject, DropZoneTableViewViewModel {
    struct ProvidedDSYM: Equatable, Hashable, Sendable {
        let filename: String
        let uuids: [BinaryUUID]
        let path: URL
    }

    enum Section: Hashable, Sendable {
        case recommended
        case optional
        case inapplicable
        case system

        var title: String {
            switch self {
            case .recommended:
                return "Recommended dSYMs"
            case .optional:
                return "Optional dSYMs"
            case .inapplicable:
                return "Inapplicable dSYMs"
            case .system:
                return "System Binaries"
            }
        }

        var description: String {
            switch self {
            case .recommended:
                return "dSYMs that are required to symbolicate memory addresses in user binaries."
            case .optional:
                // swiftlint:disable:next line_length
                return "dSYMs that could be useful to fully symbolicate function calls in user binaries, providing more context (such as file names and line numbers)."
            case .inapplicable:
                return "dSYMs that do not apply to the provided report (UUID mismatch)."
            case .system:
                return "System binaries that were detected in the report, provided for informational purposes only."
            }
        }
    }

    enum Item: Hashable, Sendable {
        case missing(DSYMRequirement)
        case provided(ProvidedDSYM)
        case inapplicable(ProvidedDSYM)
    }

    private weak var tableView: DSYMListTableView?

    private var dsymCache: [URL: [DSYMFile]] = [:]

    private var files: [URL] = [] {
        didSet {
            var providedDSYMs: [BinaryUUID: ProvidedDSYM] = [:]

            for fileURL in files {
                let dsymFiles: [DSYMFile]

                if let cachedFiles = dsymCache[fileURL] {
                    dsymFiles = cachedFiles
                } else {
                    dsymFiles = DSYMFile.dsymFiles(from: fileURL)
                    dsymCache[fileURL] = dsymFiles
                }

                for dsymFile in dsymFiles {
                    let uuids = dsymFile.uuids.values
                    for uuid in uuids {
                        providedDSYMs[uuid] = ProvidedDSYM(
                            filename: dsymFile.filename,
                            uuids: Array(uuids),
                            path: dsymFile.path
                        )
                    }
                }
            }

            self.providedDSYMs = providedDSYMs
            updateApplicableAndInapplicableDSYMs()
            updateSnapshot()
        }
    }

    private var sortedRecommendedDSYMs: [DSYMRequirement] = []
    var recommendedDSYMs: [DSYMRequirement] {
        get {
            sortedRecommendedDSYMs
        }
        set {
            sortedRecommendedDSYMs = newValue.sorted(by: {
                $0.targetName.caseInsensitiveCompare($1.targetName) == .orderedAscending
            })
            updateApplicableAndInapplicableDSYMs()
            updateSnapshot()
        }
    }

    private var sortedOptionalDSYMs: [DSYMRequirement] = []
    var optionalDSYMs: [DSYMRequirement] {
        get {
            sortedOptionalDSYMs
        }
        set {
            sortedOptionalDSYMs = newValue.sorted(by: {
                $0.targetName.caseInsensitiveCompare($1.targetName) == .orderedAscending
            })
            updateApplicableAndInapplicableDSYMs()
            updateSnapshot()
        }
    }

    private var sortedSystemDSYMs: [DSYMRequirement] = []
    var systemDSYMs: [DSYMRequirement] {
        get {
            sortedSystemDSYMs
        }
        set {
            sortedSystemDSYMs = newValue.sorted(by: {
                $0.targetName.caseInsensitiveCompare($1.targetName) == .orderedAscending
            })
            updateApplicableAndInapplicableDSYMs()
            updateSnapshot()
        }
    }

    private var providedDSYMs: [BinaryUUID: ProvidedDSYM] = [:]

    private var providedRecommendedDSYMsCount = 0
    private var providedOptionalDSYMsCount = 0
    private var providedSystemDSYMsCount = 0
    private var inapplicableDSYMs: [ProvidedDSYM] = []

    func updateApplicableAndInapplicableDSYMs() {
        var inapplicableDSYMs = providedDSYMs

        let process: (
            [DSYMRequirement],
            [BinaryUUID: ProvidedDSYM],
            inout [BinaryUUID: ProvidedDSYM]
        ) -> Int = { requirements, provided, inapplicable in
            var count = 0
            for requirement in requirements {
                if let providedDSYM = inapplicable[requirement.uuid] {
                    // dSYM requirement might only be for one UUID, but a provided dSYM can have multiple (due to
                    // multiple architectures). Remove all uuids so that other architectures for a dsym appear
                    // in "inapplicable".
                    for providedDSYMUUID in providedDSYM.uuids {
                        inapplicable.removeValue(forKey: providedDSYMUUID)
                    }
                }

                if provided[requirement.uuid] != nil {
                    count += 1
                }
            }

            return count
        }

        self.providedRecommendedDSYMsCount = process(recommendedDSYMs, providedDSYMs, &inapplicableDSYMs)
        self.providedOptionalDSYMsCount = process(optionalDSYMs, providedDSYMs, &inapplicableDSYMs)
        self.providedSystemDSYMsCount = process(systemDSYMs, providedDSYMs, &inapplicableDSYMs)
        self.inapplicableDSYMs = Array(Set<ProvidedDSYM>(inapplicableDSYMs.values)).sorted(by: {
            $0.filename.caseInsensitiveCompare($1.filename) == .orderedAscending
        })
    }

    private var diffableDataSource: NSTableViewDiffableDataSource<Section, Item>?

    func tableViewClass() -> NSTableView.Type {
        DSYMListTableView.self
    }

    func setup(with tableView: NSTableView, tableViewScrollView: NSScrollView) {
        self.tableView = tableView as? DSYMListTableView

        tableView.focusRingType = .none
        tableView.headerView = nil
        tableView.allowsMultipleSelection = true
        tableView.usesAutomaticRowHeights = true
        tableView.gridStyleMask = .solidHorizontalGridLineMask

        tableViewScrollView.documentView = tableView
        tableViewScrollView.automaticallyAdjustsContentInsets = false
        tableViewScrollView.contentInsets = NSEdgeInsets(top: -10, left: 0, bottom: 0, right: 0)
        tableViewScrollView.wantsLayer = true
        tableViewScrollView.layer?.cornerRadius = 8
        tableViewScrollView.hasVerticalScroller = true

        let column = NSTableColumn(identifier: .init(rawValue: "name"))
        column.width = tableView.frame.size.width
        tableView.addTableColumn(column)

        diffableDataSource = NSTableViewDiffableDataSource<Section, Item>(
            tableView: tableView
        ) { [weak self] tableView, tableColumn, row, identifier in
            self?.cell(for: tableView, column: tableColumn, row: row, item: identifier) ?? NSView()
        }

        diffableDataSource?.sectionHeaderViewProvider = { [weak self] tableView, row, identifier in
            self?.sectionHeader(for: tableView, row: row, section: identifier) ?? NSView()
        }

        diffableDataSource?.rowViewProvider = { _, _, identifier in
            if identifier is Item {
                return DSYMListTableViewDSYMRow()
            } else {
                return NSTableRowView()
            }
        }

        tableView.dataSource = diffableDataSource

        tableView.menu = DSYMListTableViewRowMenu(createMenuItem: { [weak self] item in
            guard let self else { return NSMenuItem() }

            let menuItem: NSMenuItem

            switch item {
            case .showInFinder:
                menuItem = NSMenuItem(title: "Show in Finder", action: #selector(showInFinder(_:)), keyEquivalent: "")
            case .copy:
                menuItem = NSMenuItem(title: "Copy", action: #selector(copyRows(_:)), keyEquivalent: "")
            case .copyUUIDs:
                menuItem = NSMenuItem(title: "Copy UUIDs", action: #selector(copyUUIDs(_:)), keyEquivalent: "")
            }

            menuItem.target = self

            return menuItem
        })
        tableView.menu?.delegate = self
    }

    private func cell(for tableView: NSTableView, column: NSTableColumn, row: Int, item: Item) -> NSView {
        switch item {
        case .missing(let dsymRequirement):
            return MissingDSYMCellView(dsymRequirement: dsymRequirement)
        case .provided(let providedDSYM):
            return ProvidedDSYMCellView(providedDSYM: providedDSYM)
        case .inapplicable(let providedDSYM):
            return InapplicableDSYMCellView(providedDSYM: providedDSYM)
        }
    }

    private func sectionHeader(for tableView: NSTableView, row: Int, section: Section) -> NSView {
        let title: String
        switch section {
        case .recommended:
            title = "\(section.title) (\(providedRecommendedDSYMsCount)/\(recommendedDSYMs.count))"
        case .optional:
            title = "\(section.title) (\(providedOptionalDSYMsCount)/\(optionalDSYMs.count))"
        case .inapplicable:
            title = "\(section.title) (\(inapplicableDSYMs.count))"
        case .system:
            if providedSystemDSYMsCount > 0 {
                title = "\(section.title) (\(providedSystemDSYMsCount)/\(systemDSYMs.count))"
            } else {
                title = section.title
            }
        }

        let sectionTitleLabel = NSTextField(labelWithString: title.uppercased())
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sectionTitleLabel.textColor = NSColor.secondaryLabelColor
        sectionTitleLabel.font = NSFont.titleBarFont(ofSize: NSFont.smallSystemFontSize)
        sectionTitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let stackView = NSStackView(views: [sectionTitleLabel])
        stackView.orientation = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let paddingView = NSView()
        paddingView.translatesAutoresizingMaskIntoConstraints = false
        paddingView.addSubview(stackView)

        paddingView.toolTip = section.description

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: paddingView.topAnchor, constant: 6),
            stackView.leadingAnchor.constraint(equalTo: paddingView.leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(
                equalTo: paddingView.trailingAnchor,
                constant: -4
            ).withPriority(.defaultHigh),
            stackView.bottomAnchor.constraint(
                equalTo: paddingView.bottomAnchor,
                constant: -6
            ).withPriority(.defaultHigh)
        ])

        return paddingView
    }

    func updateSnapshot(withFiles files: [URL]) {
        self.files = files
        updateSnapshot()
    }

    func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        let addItemsIntoSectionFromProvidedDSYMs: (
            [DSYMRequirement],
            Section,
            [BinaryUUID: ProvidedDSYM]
        ) -> Void = { items, section, providedDSYMs in
            guard !items.isEmpty else { return }

            snapshot.appendSections([section])
            var providedSectionDSYMs: [Item] = []
            var missingSectionDSYMs: [Item] = []

            for item in items {
                if let providedDSYM = providedDSYMs[item.uuid] {
                    providedSectionDSYMs.append(.provided(providedDSYM))
                } else {
                    missingSectionDSYMs.append(.missing(item))
                }
            }

            snapshot.appendItems(providedSectionDSYMs, toSection: section)
            snapshot.appendItems(missingSectionDSYMs, toSection: section)
        }

        addItemsIntoSectionFromProvidedDSYMs(recommendedDSYMs, .recommended, providedDSYMs)
        addItemsIntoSectionFromProvidedDSYMs(optionalDSYMs, .optional, providedDSYMs)

        if !inapplicableDSYMs.isEmpty {
            snapshot.appendSections([.inapplicable])
            snapshot.appendItems(inapplicableDSYMs.map { .inapplicable($0) }, toSection: .inapplicable)
        }

        addItemsIntoSectionFromProvidedDSYMs(systemDSYMs, .system, providedDSYMs)

        diffableDataSource?.apply(snapshot, animatingDifferences: false)
    }

    @objc
    private func showInFinder(_ sender: Any?) {
        guard let tableView else { return }

        var fileURL: URL?
        for row in tableView.rightClickRowIndexes {
            if let rowView = tableView.rowView(atRow: row, makeIfNecessary: false) as? DSYMListTableViewDSYMRow {
                fileURL = rowView.representedFileURL()
                break
            }
        }

        if let fileURL {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }

    @objc
    private func copyRows(_ sender: Any?) {
        guard let tableView else { return }

        var result = ""
        for row in tableView.rightClickRowIndexes {
            if let rowView = tableView.rowView(atRow: row, makeIfNecessary: false) as? DSYMListTableViewDSYMRow,
               let text = rowView.copyableText() {
                if result != "" {
                    result.append("\n")
                }

                result.append(text)
            }
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result.trimmingCharacters(in: .whitespacesAndNewlines), forType: .string)
    }

    @objc
    private func copyUUIDs(_ sender: Any?) {
        guard let tableView else { return }

        var result = ""
        for row in tableView.rightClickRowIndexes {
            if let rowView = tableView.rowView(atRow: row, makeIfNecessary: false) as? DSYMListTableViewDSYMRow,
               let text = rowView.copyableUUIDs() {
                if result != "" {
                    result.append("\n")
                }

                result.append(text)
            }
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result.trimmingCharacters(in: .whitespacesAndNewlines), forType: .string)
    }
}

final private class DSYMListTableViewRowMenu: NSMenu {
    enum MenuItem {
        case showInFinder
        case copy
        case copyUUIDs
    }

    typealias CreateMenuItem = (MenuItem) -> NSMenuItem
    private let createMenuItem: CreateMenuItem

    init(createMenuItem: @escaping CreateMenuItem) {
        self.createMenuItem = createMenuItem
        super.init(title: "")
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(forRowViews rowViews: [DSYMListTableViewDSYMRow]) {
        removeAllItems()

        guard !rowViews.isEmpty else { return }

        if rowViews.count == 1, rowViews[0].representedFileURL() != nil {
            addItem(createMenuItem(.showInFinder))
        }

        addItem(createMenuItem(.copy))
        addItem(createMenuItem(.copyUUIDs))
    }
}

extension DSYMListViewModel: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        guard let tableView else { return }

        let rowViews = tableView.rightClickRowIndexes.compactMap {
            tableView.rowView(atRow: $0, makeIfNecessary: false) as? DSYMListTableViewDSYMRow
        }
        (tableView.menu as? DSYMListTableViewRowMenu)?.update(forRowViews: rowViews)
    }
}

private class DSYMListTableViewDSYMRow: NSTableRowView {
    var cellView: NSView? {
        subviews.first(where: { $0 is InteractableDSYMCellView })
    }

    func representedFileURL() -> URL? {
        (cellView as? InteractableDSYMCellView)?.representedFileURL()
    }

    func copyableText() -> String? {
        (cellView as? InteractableDSYMCellView)?.copyableText()
    }

    func copyableUUIDs() -> String? {
        (cellView as? InteractableDSYMCellView)?.copyableUUIDs()
    }
}

private class DSYMListTableView: NSTableView {
    private var _clickedRow: Int = -1
    override var clickedRow: Int {
        get { return _clickedRow }
        set { _clickedRow = newValue }
    }

    var rightClickRowIndexes: IndexSet {
        let selectedRows: IndexSet
        if clickedRow > -1 {
            if selectedRowIndexes.contains(clickedRow) {
                selectedRows = selectedRowIndexes
            } else {
                selectedRows = IndexSet(integer: clickedRow)
            }
        } else {
            selectedRows = IndexSet()
        }
        return selectedRows
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let location: CGPoint = convert(event.locationInWindow, from: nil)
        let clickedRow = row(at: location)

        if clickedRow > -1, rowView(atRow: clickedRow, makeIfNecessary: false) is DSYMListTableViewDSYMRow {
            self.clickedRow = clickedRow
            return super.menu(for: event)
        } else {
            self.clickedRow = -1
            return nil
        }
    }
}
