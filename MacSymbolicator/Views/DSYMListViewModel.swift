//
//  DSYMListViewModel.swift
//  MacSymbolicator
//

import Cocoa

final class DSYMListViewModel: DropZoneTableViewViewModel {
    struct ProvidedDSYM: Equatable, Hashable, Sendable {
        let filename: String
        let uuids: [BinaryUUID]
        let path: URL
    }

    enum Section: Hashable, Sendable {
        case recommended
        case optional
        case inapplicable

        var title: String {
            switch self {
            case .recommended:
                return "Recommended dSYMs"
            case .optional:
                return "Optional dSYMs"
            case .inapplicable:
                return "Inapplicable dSYMs"
            }
        }

        var description: String {
            switch self {
            case .recommended:
                return "dSYMs that are required to symbolicate memory addresses in user binaries (i.e. not system)."
            case .optional:
                return "dSYMs that could be useful to symbolicate system binaries or to provide more context (such as file names and line numbers) on partially symbolicated function calls in user binaries."
            case .inapplicable:
                return "dSYMs that do not apply to the provided report (UUID mismatch)."
            }
        }
    }

    enum Item: Hashable, Sendable {
        case missing(DSYMRequirement)
        case provided(ProvidedDSYM)
        case inapplicable(ProvidedDSYM)
    }

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

    private var providedDSYMs: [BinaryUUID: ProvidedDSYM] = [:]

    private var providedRecommendedDSYMsCount = 0
    private var providedOptionalDSYMsCount = 0
    private var inapplicableDSYMs: [ProvidedDSYM] = []

    func updateApplicableAndInapplicableDSYMs() {
        var inapplicableDSYMs = providedDSYMs
        var providedRecommendedDSYMsCount = 0
        var providedOptionalDSYMsCount = 0

        for requirement in recommendedDSYMs {
            if let providedDSYM = inapplicableDSYMs[requirement.uuid] {
                // dSYM requirement might only be for one UUID, but a provided dSYM can have multiple (due to multiple
                // architectures). Remove all uuids so that other architectures for a dsym appear in "inapplicable".
                for providedDSYMUUID in providedDSYM.uuids {
                    inapplicableDSYMs.removeValue(forKey: providedDSYMUUID)
                }
            }

            if providedDSYMs[requirement.uuid] != nil {
                providedRecommendedDSYMsCount += 1
            }
        }
        for requirement in optionalDSYMs {
            if let providedDSYM = inapplicableDSYMs[requirement.uuid] {
                // dSYM requirement might only be for one UUID, but a provided dSYM can have multiple (due to multiple
                // architectures). Remove all uuids so that other architectures for a dsym appear in "inapplicable".
                for providedDSYMUUID in providedDSYM.uuids {
                    inapplicableDSYMs.removeValue(forKey: providedDSYMUUID)
                }
            }

            if providedDSYMs[requirement.uuid] != nil {
                providedOptionalDSYMsCount += 1
            }
        }

        self.providedRecommendedDSYMsCount = providedRecommendedDSYMsCount
        self.providedOptionalDSYMsCount = providedOptionalDSYMsCount
        self.inapplicableDSYMs = Array(Set<ProvidedDSYM>(inapplicableDSYMs.values)).sorted(by: {
            $0.filename.caseInsensitiveCompare($1.filename) == .orderedAscending
        })
    }

    private var diffableDataSource: NSTableViewDiffableDataSource<Section, Item>?

    func setup(with tableView: NSTableView, tableViewScrollView: NSScrollView) {
        tableView.focusRingType = .none
//        tableView.usesAlternatingRowBackgroundColors = true
        tableView.headerView = nil
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

        tableView.dataSource = diffableDataSource
    }

    private func cell(for tableView: NSTableView, column: NSTableColumn, row: Int, item: Item) -> NSView {
        let views: [NSView]

        switch item {
        case .missing(let dsymRequirement):
            let targetLabel = NSTextField(labelWithString: dsymRequirement.targetName)
            targetLabel.textColor = NSColor.secondaryLabelColor
            targetLabel.font = NSFont.controlContentFont(ofSize: NSFont.systemFontSize)

            let uuidLabel = NSTextField(labelWithString: dsymRequirement.uuid.pretty)
            uuidLabel.textColor = NSColor.secondaryLabelColor
            uuidLabel.font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
            uuidLabel.toolTip = dsymRequirement.uuid.pretty

            views = [targetLabel, uuidLabel]
        case .provided(let providedDSYM):
            let filename = providedDSYM.path.lastPathComponent

            let filenameLabel = NSTextField(labelWithString: filename)
            filenameLabel.font = NSFont.controlContentFont(ofSize: NSFont.systemFontSize)

            let uuidLabels = providedDSYM.uuids.map {
                let uuidLabel = NSTextField(labelWithString: $0.pretty)
                uuidLabel.textColor = NSColor.secondaryLabelColor
                uuidLabel.font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
                return uuidLabel
            }

            let uuidsStackView = NSStackView(views: uuidLabels)
            uuidsStackView.orientation = .vertical
            uuidsStackView.distribution = .equalCentering
            uuidsStackView.alignment = .leading
            uuidsStackView.spacing = 0
            uuidsStackView.translatesAutoresizingMaskIntoConstraints = false

            let containingPath = (providedDSYM.path.deletingLastPathComponent().path as NSString)
                .abbreviatingWithTildeInPath
            let pathLabel = NSTextField(labelWithString: containingPath)
            pathLabel.textColor = NSColor.secondaryLabelColor
            pathLabel.font = NSFont.controlContentFont(ofSize: NSFont.labelFontSize)
            pathLabel.lineBreakMode = .byTruncatingMiddle
            pathLabel.toolTip = containingPath
            pathLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            views = [filenameLabel, uuidsStackView, pathLabel]
        case .inapplicable(let providedDSYM):
            let filename = providedDSYM.path.lastPathComponent

            let filenameLabel = NSTextField(labelWithString: filename)
            filenameLabel.font = NSFont.controlContentFont(ofSize: NSFont.systemFontSize)

            let uuidLabels = providedDSYM.uuids.map {
                let stringComponents = [$0.architecture?.atosString, $0.pretty].compactMap { $0 }
                let uuidLabel = NSTextField(labelWithString: stringComponents.joined(separator: ": "))
                uuidLabel.textColor = NSColor.secondaryLabelColor
                uuidLabel.font = NSFont.monospacedSystemFont(ofSize: NSFont.labelFontSize, weight: .regular)
                return uuidLabel
            }

            let uuidsStackView = NSStackView(views: uuidLabels)
            uuidsStackView.orientation = .vertical
            uuidsStackView.distribution = .equalCentering
            uuidsStackView.alignment = .leading
            uuidsStackView.spacing = 0
            uuidsStackView.translatesAutoresizingMaskIntoConstraints = false

            let containingPath = (providedDSYM.path.deletingLastPathComponent().path as NSString)
                .abbreviatingWithTildeInPath
            let pathLabel = NSTextField(labelWithString: containingPath)
            pathLabel.textColor = NSColor.secondaryLabelColor
            pathLabel.font = NSFont.controlContentFont(ofSize: NSFont.labelFontSize)
            pathLabel.lineBreakMode = .byTruncatingMiddle
            pathLabel.toolTip = containingPath
            pathLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            views = [filenameLabel, uuidsStackView]
        }

        let paddingView = NSView()
        paddingView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = NSStackView(views: views)
        stackView.orientation = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false

        paddingView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: paddingView.topAnchor, constant: 6),
            stackView.leadingAnchor.constraint(equalTo: paddingView.leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(
                equalTo: paddingView.trailingAnchor,
                constant: -4
            ).withPriority(.required),
            stackView.bottomAnchor.constraint(
                equalTo: paddingView.bottomAnchor,
                constant: -6
            ).withPriority(.required)
        ])

        return paddingView
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
        }

        let sectionTitleLabel = NSTextField(labelWithString: title)
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sectionTitleLabel.textColor = NSColor.secondaryLabelColor
        sectionTitleLabel.font = NSFont.titleBarFont(ofSize: NSFont.systemFontSize)

        let sectionDescriptionLabel = NSTextField(labelWithString: section.description)
        sectionDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        sectionDescriptionLabel.lineBreakMode = .byWordWrapping
        sectionDescriptionLabel.textColor = NSColor.secondaryLabelColor
        sectionDescriptionLabel.font = NSFont.controlContentFont(ofSize: NSFont.smallSystemFontSize)
        sectionDescriptionLabel.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)

        let stackView = NSStackView(views: [sectionTitleLabel, sectionDescriptionLabel])
        stackView.orientation = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let paddingView = NSView()
        paddingView.translatesAutoresizingMaskIntoConstraints = false
        paddingView.addSubview(stackView)

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

        if !recommendedDSYMs.isEmpty {
            snapshot.appendSections([.recommended])
            var providedRecommendedDSYMs: [Item] = []
            var missingRecommendedDSYMs: [Item] = []

            for recommendedDSYM in recommendedDSYMs {
                if let providedDSYM = providedDSYMs[recommendedDSYM.uuid] {
                    providedRecommendedDSYMs.append(.provided(providedDSYM))
                } else {
                    missingRecommendedDSYMs.append(.missing(recommendedDSYM))
                }
            }

            snapshot.appendItems(providedRecommendedDSYMs, toSection: .recommended)
            snapshot.appendItems(missingRecommendedDSYMs, toSection: .recommended)
        }

        if !optionalDSYMs.isEmpty {
            snapshot.appendSections([.optional])
            var providedOptionalDSYMs: [Item] = []
            var missingOptionalDSYMs: [Item] = []

            for optionalDSYM in optionalDSYMs {
                if let providedDSYM = providedDSYMs[optionalDSYM.uuid] {
                    providedOptionalDSYMs.append(.provided(providedDSYM))
                } else {
                    missingOptionalDSYMs.append(.missing(optionalDSYM))
                }
            }

            snapshot.appendItems(providedOptionalDSYMs, toSection: .optional)
            snapshot.appendItems(missingOptionalDSYMs, toSection: .optional)
        }

        if !inapplicableDSYMs.isEmpty {
            snapshot.appendSections([.inapplicable])
            snapshot.appendItems(inapplicableDSYMs.map { .inapplicable($0) }, toSection: .inapplicable)
        }

        diffableDataSource?.apply(snapshot, animatingDifferences: false)
    }
}

private class RowView: NSTableRowView {
    override func drawSeparator(in dirtyRect: NSRect) {
    }
}
