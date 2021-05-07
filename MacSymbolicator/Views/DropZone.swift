//
//  DropZone.swift
//  MacSymbolicator
//

import Cocoa

// swiftlint:disable file_length

protocol DropZoneDelegate: AnyObject {
    func receivedFiles(dropZone: DropZone, fileURLs: [URL]) -> [URL]
}

class DropZone: NSView {
    enum State {
        case oneFileEmpty
        case oneFile
        case multipleFilesEmpty
        case multipleFiles
    }

    // MARK: Properties
    weak var delegate: DropZoneDelegate?

    var state: State {
        didSet {
            layoutElements()

            tableViewScrollView.isHidden = files.isEmpty
            tableView.reloadData()

            display()
        }
    }

    private var isHoveringFile = false {
        didSet {
            display()
        }
    }

    private var _fileTypes: [String] = [] {
        didSet {
            updateRegisteredFileTypes()
        }
    }

    var fileTypes: [String] {
        get { return _fileTypes }
        set {
            _fileTypes = newValue.map {
                // Prepend "." to every fileType if needed
                ($0.hasPrefix(".") ? "" : ".").appending($0.lowercased())
            }
        }
    }

    var fileTypesPredicate: NSPredicate {
        let predicateFormat = (0..<fileTypes.count).map { _ in "SELF ENDSWITH[c] %@" }.joined(separator: " OR ")
        return NSPredicate(format: predicateFormat, argumentArray: fileTypes)
    }

    var text: String? {
        didSet {
            updateText()
        }
    }

    var detailText: String? {
        didSet {
            updateText()
        }
    }

    var icon: NSImage? {
        didSet {
            icon?.size = NSSize(width: 64, height: 64)
            iconImageView.image = icon
            iconImageView.sizeToFit()
        }
    }

    var files = Set<URL>() {
        didSet {
            if allowsMultipleFiles {
                state = files.isEmpty ? .multipleFilesEmpty : .multipleFiles
            } else {
                state = files.isEmpty ? .oneFileEmpty : .oneFile
            }
        }
    }

    var activatesAppAfterDrop: Bool

    private let allowsMultipleFiles: Bool

    private let containerView = NSView()
    private let textContainerStackView = NSStackView()
    private let fileTypeTextField = NSTextField()
    private let textTextField = NSTextField()
    private let detailTextTextField = NSTextField()
    private let iconImageView = NSImageView()

    private let tableViewScrollView = NSScrollView()
    private let tableView = NSTableView()

    private var isFlashing: Bool = false

    private var layoutConstraints: [NSLayoutConstraint] = []

    // MARK: Methods
    init(
        fileTypes: [String],
        allowsMultipleFiles: Bool,
        text: String? = nil,
        detailText: String? = nil,
        activatesAppAfterDrop: Bool = false
    ) {
        self.activatesAppAfterDrop = activatesAppAfterDrop
        self.allowsMultipleFiles = allowsMultipleFiles
        state = allowsMultipleFiles ? .multipleFilesEmpty : .oneFileEmpty

        super.init(frame: .zero)

        DispatchQueue.main.async { // So that all didSet do trigger
            self.fileTypes = fileTypes
            self.text = text
            self.detailText = detailText

            self.setup()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(textContainerStackView)

        [fileTypeTextField, textTextField, detailTextTextField].forEach {
            textContainerStackView.addArrangedSubview($0)
        }

        wantsLayer = true
        layer?.cornerRadius = 14
        translatesAutoresizingMaskIntoConstraints = false

        containerView.translatesAutoresizingMaskIntoConstraints = false

        textContainerStackView.orientation = .vertical
        textContainerStackView.distribution = .equalCentering
        textContainerStackView.translatesAutoresizingMaskIntoConstraints = false

        fileTypeTextField.drawsBackground = false
        fileTypeTextField.isBezeled = false
        fileTypeTextField.isEditable = false
        fileTypeTextField.isSelectable = false

        textTextField.drawsBackground = false
        textTextField.isBezeled = false
        textTextField.isEditable = false
        textTextField.isSelectable = false
        textTextField.cell?.lineBreakMode = .byTruncatingMiddle

        detailTextTextField.drawsBackground = false
        detailTextTextField.isBezeled = false
        detailTextTextField.isEditable = false
        detailTextTextField.isSelectable = false
        detailTextTextField.cell?.truncatesLastVisibleLine = true

        iconImageView.unregisterDraggedTypes()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        tableView.delegate = self
        tableView.dataSource = self
        tableView.focusRingType = .none
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.headerView = nil
        tableView.rowHeight = 44

        tableViewScrollView.documentView = tableView
        tableViewScrollView.translatesAutoresizingMaskIntoConstraints = false
        tableViewScrollView.automaticallyAdjustsContentInsets = false
        tableViewScrollView.contentInsets = NSEdgeInsets(top: -10, left: 0, bottom: 0, right: 0)
        tableViewScrollView.wantsLayer = true
        tableViewScrollView.layer?.cornerRadius = 8

        let column = NSTableColumn(identifier: .init(rawValue: "name"))
        column.width = CGFloat(300)
        tableView.addTableColumn(column)

        layoutElements()

        if allowsMultipleFiles {
            addSubview(tableViewScrollView)

            NSLayoutConstraint.activate([
                tableViewScrollView.topAnchor.constraint(equalTo: topAnchor, constant: 6.5 + 60),
                tableViewScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6.5),
                tableViewScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6.5),
                tableViewScrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6.5)
            ])

            tableViewScrollView.isHidden = true
        }
    }

    private func layoutElements() {
        NSLayoutConstraint.deactivate(layoutConstraints)

        switch state {
        case .multipleFiles:
            layoutConstraints = [
                containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
                containerView.topAnchor.constraint(equalTo: topAnchor),
                containerView.heightAnchor.constraint(equalToConstant: 60),
                containerView.widthAnchor.constraint(equalTo: widthAnchor),

                iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                iconImageView.heightAnchor.constraint(equalToConstant: 32),
                iconImageView.widthAnchor.constraint(equalToConstant: 32),

                textContainerStackView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
                textContainerStackView.topAnchor.constraint(equalTo: iconImageView.topAnchor),
                textContainerStackView.bottomAnchor.constraint(equalTo: iconImageView.bottomAnchor),
                textContainerStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12)
            ]

            textContainerStackView.spacing = 0
            textContainerStackView.alignment = .leading
            NSLayoutConstraint.activate(layoutConstraints)
        case .oneFile, .oneFileEmpty, .multipleFilesEmpty:
            layoutConstraints = [
                containerView.topAnchor.constraint(equalTo: topAnchor),
                containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
                containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: trailingAnchor),

                iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -46),
                iconImageView.heightAnchor.constraint(equalToConstant: 64),
                iconImageView.widthAnchor.constraint(equalToConstant: 64),

                textContainerStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                textContainerStackView.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
                textContainerStackView.widthAnchor.constraint(equalTo: containerView.widthAnchor)
            ]

            textContainerStackView.spacing = 8
            textContainerStackView.alignment = .centerX
            NSLayoutConstraint.activate(layoutConstraints)
        }

        updateRegisteredFileTypes()
    }

    private func updateRegisteredFileTypes() {
        // Make sure to use _fileTypes

        guard !_fileTypes.isEmpty else {
            icon = nil
            unregisterDraggedTypes()
            updateText()
            return
        }

        registerForDraggedTypes([(kUTTypeFileURL as NSPasteboard.PasteboardType)])

        let primaryFileType = _fileTypes[0]
        icon = NSWorkspace.shared.icon(forFileType: primaryFileType)
        updateText()
    }

    private func updateText() {
        let mainLabelText: String?
        let fileTypeLabelText: String?
        let detailLabelText: String?

        switch state {
        case .multipleFiles:
            if let primaryFileType = _fileTypes.first {
                if let text = text {
                    mainLabelText = "\(text) (\(primaryFileType))"
                } else {
                    mainLabelText = primaryFileType
                }
            } else {
                mainLabelText = text
            }

            fileTypeLabelText = nil
            detailLabelText = detailText
        case .oneFile:
            mainLabelText = files.first?.lastPathComponent ?? text
            fileTypeLabelText = _fileTypes.first
            detailLabelText = detailText
        case .multipleFilesEmpty, .oneFileEmpty:
            mainLabelText = text
            fileTypeLabelText = _fileTypes.first
            detailLabelText = detailText
        }

        if let text = mainLabelText {
            textTextField.attributedStringValue = NSAttributedString(
                string: text,
                attributes: Style.textAttributes(size: 14, color: .secondaryLabelColor)
            )
            textTextField.isHidden = false
        } else {
            textTextField.stringValue = ""
            textTextField.isHidden = true
        }

        if let text = fileTypeLabelText {
            fileTypeTextField.attributedStringValue = NSAttributedString(
                string: text,
                attributes: Style.textAttributes(size: 16, color: .labelColor)
            )
            fileTypeTextField.isHidden = false
        } else {
            fileTypeTextField.stringValue = ""
            fileTypeTextField.isHidden = true
        }

        if let text = detailLabelText {
            detailTextTextField.attributedStringValue = NSAttributedString(
                string: text,
                attributes: Style.textAttributes(size: 12, color: .tertiaryLabelColor)
            )
            detailTextTextField.isHidden = false
        } else {
            detailTextTextField.stringValue = ""
            detailTextTextField.isHidden = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        // Background
        (isHoveringFile ? Colors.backgroundHover : NSColor.clear).setFill()
        dirtyRect.fill()

        // Padding
        let borderPadding: CGFloat = 6

        let drawRect: CGRect

        // Drop area outline drawing
        let drawTableViewBorder: Bool
        let isFilled: Bool

        switch state {
        case .oneFileEmpty:
            drawRect = dirtyRect.insetBy(dx: borderPadding, dy: borderPadding)
            isFilled = false
            drawTableViewBorder = false
        case .oneFile:
            drawRect = dirtyRect.insetBy(dx: borderPadding, dy: borderPadding)
            isFilled = true
            drawTableViewBorder = false
        case .multipleFilesEmpty:
            drawRect = dirtyRect.insetBy(dx: borderPadding, dy: borderPadding)
            isFilled = false
            drawTableViewBorder = false
        case .multipleFiles:
            var rect = containerView.frame

            let newHeight: CGFloat = 60
            rect.origin.y += (rect.size.height - newHeight)
            rect.size.height = newHeight

            drawRect = rect.insetBy(dx: borderPadding, dy: borderPadding)

            isFilled = true
            drawTableViewBorder = true
        }

        if isFilled {
            (isHoveringFile ? Colors.borderFilledHover : Colors.borderFilled).setStroke()
        } else {
            (isHoveringFile ? Colors.borderHover : Colors.border).setStroke()
        }

        let roundedRectanglePath = NSBezierPath(roundedRect: drawRect, xRadius: 8, yRadius: 8)
        roundedRectanglePath.lineWidth = 1.5

        if !isFilled && !isFlashing {
            roundedRectanglePath.setLineDash([6, 6, 6, 6], count: 4, phase: 0)
        }

        roundedRectanglePath.stroke()

        if drawTableViewBorder {
            let borderRect = tableViewScrollView.frame.insetBy(dx: -0.5, dy: -0.5)
            let tableViewBorderPath = NSBezierPath(roundedRect: borderRect, xRadius: 8, yRadius: 8)
            tableViewBorderPath.lineWidth = 1.5
            tableViewBorderPath.stroke()
        }
    }

    @discardableResult
    func acceptFile(url fileURL: URL) -> Bool {
        guard validFileURL(fileURL) else { return false }

        let acceptedFileURLs = delegate?.receivedFiles(dropZone: self, fileURLs: [fileURL]) ?? [fileURL]

        if allowsMultipleFiles {
            files.formUnion(acceptedFileURLs)
        } else {
            files = acceptedFileURLs.last.flatMap { Set<URL>(arrayLiteral: $0) } ?? Set<URL>()
        }

        return true
    }

    func flash() {
        isFlashing = true
        display()

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            self.isFlashing = false
            self.display()
        }
    }
}

// MARK: NSDraggingDestination
extension DropZone {
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.isHoveringFile = !validDraggedFileURLs(from: sender).isEmpty
        return isHoveringFile ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.isHoveringFile = false
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let draggedFileURLs = validDraggedFileURLs(from: sender)

        if allowsMultipleFiles {
            let acceptedFileURLs = delegate?.receivedFiles(dropZone: self, fileURLs: draggedFileURLs) ?? draggedFileURLs
            files.formUnion(acceptedFileURLs)
        } else if let lastValidURL = draggedFileURLs.last {
            let acceptedFileURLs = delegate?.receivedFiles(dropZone: self, fileURLs: [lastValidURL]) ?? [lastValidURL]
            files = acceptedFileURLs.last.flatMap { Set<URL>(arrayLiteral: $0) } ?? Set<URL>()
        }

        isHoveringFile = false

        if activatesAppAfterDrop {
            // It's a bit weird if we drag a file to this app but it doesn't become active
            NSApp.activate(ignoringOtherApps: true)
        }

        return true
    }

    private func validDraggedFileURLs(from draggingInfo: NSDraggingInfo) -> [URL] {
        let draggedFileURLs = draggingInfo.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [:])
        let fileURLs: [URL] = draggedFileURLs?.compactMap { $0 as? URL } ?? []

        return fileURLs.filter { validFileURL($0) }
    }

    private func validFileURL(_ url: URL) -> Bool {
        return fileTypesPredicate.evaluate(with: url.path)
    }
}

// MARK: NSTableViewDataSource & NSTableViewDelegate
extension DropZone: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        files.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let rowIndex = files.index(files.startIndex, offsetBy: row)
        return files[rowIndex].lastPathComponent
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let rowIndex = files.index(files.startIndex, offsetBy: row)

        let fileURL = files[rowIndex]
        let filename = fileURL.lastPathComponent
        let containingPath = (fileURL.deletingLastPathComponent().path as NSString).abbreviatingWithTildeInPath

        let filenameLabel = NSTextField(labelWithString: filename)
        filenameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        let pathLabel = NSTextField(labelWithString: containingPath)
        pathLabel.textColor = NSColor.secondaryLabelColor
        pathLabel.font = NSFont.controlContentFont(ofSize: NSFont.smallSystemFontSize)
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.toolTip = containingPath

        let paddingView = NSView()

        let stackView = NSStackView(views: [filenameLabel, pathLabel])
        stackView.orientation = .vertical
        stackView.distribution = .equalCentering
        stackView.alignment = .leading
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        paddingView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: paddingView.topAnchor, constant: 6),
            stackView.leadingAnchor.constraint(equalTo: paddingView.leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(equalTo: paddingView.trailingAnchor, constant: -4),
            stackView.bottomAnchor.constraint(equalTo: paddingView.bottomAnchor, constant: -6)
        ])

        return paddingView
    }
}

// MARK: Helpers
extension DropZone {
    private enum Appearance {
        static var isDark: Bool {
            ![NSAppearance.Name.aqua, NSAppearance.Name.vibrantLight].contains(NSApp.effectiveAppearance.name)
        }
    }

    private enum Colors {
        static var border: NSColor {
            if Appearance.isDark {
                return NSColor(calibratedWhite: 0.5, alpha: 1)
            } else {
                return NSColor(calibratedWhite: 0.7, alpha: 1)
            }
        }

        static var borderFilled: NSColor {
            if Appearance.isDark {
                return border.withAlphaComponent(0.25)
            } else {
                return border.withAlphaComponent(0.5)
            }
        }

        static var borderHover: NSColor {
            border.withAlphaComponent(0.6)
        }

        static var borderFilledHover: NSColor {
            if Appearance.isDark {
                return border.withAlphaComponent(0.15)
            } else {
                return border.withAlphaComponent(0.25)
            }
        }

        static var backgroundHover: NSColor {
            if Appearance.isDark {
                return NSColor(calibratedWhite: 1, alpha: 0.015)
            } else {
                return NSColor(calibratedWhite: 0, alpha: 0.025)
            }
        }
    }

    private enum Style {
        private static var _centeredTextStyle: NSMutableParagraphStyle?
        static var centeredTextStyle: NSMutableParagraphStyle {
            guard let style = _centeredTextStyle else {
                // swiftlint:disable:next force_cast
                _centeredTextStyle = (NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle)
                _centeredTextStyle?.alignment = .center
                return _centeredTextStyle!
            }

            return style
        }

        static func textAttributes(size: CGFloat, color: NSColor) -> [NSAttributedString.Key: Any] {
            return [
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: size),
                NSAttributedString.Key.foregroundColor: color,
                NSAttributedString.Key.paragraphStyle: centeredTextStyle
            ]
        }
    }
}
