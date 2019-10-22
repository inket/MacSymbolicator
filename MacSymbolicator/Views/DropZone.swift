//
//  DropZone.swift
//  MacSymbolicator
//

import Cocoa

protocol DropZoneDelegate: class {
    func receivedFile(dropZone: DropZone, fileURL: URL)
}

class DropZone: NSView {
    // MARK: Properties
    weak var delegate: DropZoneDelegate?

    private var isHoveringFile = false {
        didSet {
            display()
        }
    }

    private var _fileTypes: [String] = [] {
        didSet {
            guard !_fileTypes.isEmpty else {
                icon = nil
                fileTypeTextField.attributedStringValue = NSAttributedString()
                unregisterDraggedTypes()
                return
            }

            registerForDraggedTypes([(kUTTypeFileURL as NSPasteboard.PasteboardType)])

            let primaryFileType = _fileTypes[0]
            icon = NSWorkspace.shared.icon(forFileType: primaryFileType)
            fileTypeTextField.attributedStringValue = NSAttributedString(
                string: primaryFileType,
                attributes: Style.textAttributes(size: 16, color: .labelColor)
            )
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
            guard let newText = text else {
                textTextField.stringValue = ""
                textTextFieldHeightConstraint?.constant = 0
                return
            }

            textTextField.attributedStringValue = NSAttributedString(
                string: newText,
                attributes: Style.textAttributes(size: 14, color: .secondaryLabelColor)
            )
            textTextFieldHeightConstraint?.constant = 40
        }
    }

    var detailText: String? {
        didSet {
            guard let newDetailText = detailText else {
                detailTextTextField.stringValue = ""
                detailTextTextFieldHeightConstraint?.constant = 0
                return
            }

            detailTextTextField.attributedStringValue = NSAttributedString(
                string: newDetailText,
                attributes: Style.textAttributes(size: 12, color: .tertiaryLabelColor)
            )
            detailTextTextFieldHeightConstraint?.constant = 70
        }
    }

    var icon: NSImage? {
        didSet {
            icon?.size = NSSize(width: 64, height: 64)
            iconImageView.image = icon
            iconImageView.sizeToFit()
        }
    }

    private var _file: URL?
    var file: URL? {
        get { return _file }
        set {
            guard let value = newValue,
                      value != _file else { return }

            _file = value
            self.text = value.lastPathComponent
            display()
        }
    }

    private let containerView = NSView()
    private let fileTypeTextField = NSTextField()
    private let textTextField = NSTextField()
    private let detailTextTextField = NSTextField()
    private let iconImageView = NSImageView()

    private var textTextFieldHeightConstraint: NSLayoutConstraint?
    private var detailTextTextFieldHeightConstraint: NSLayoutConstraint?

    // MARK: Methods
    init(fileTypes: [String], text: String? = nil, detailText: String? = nil) {
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
        containerView.addSubview(fileTypeTextField)
        containerView.addSubview(textTextField)
        containerView.addSubview(detailTextTextField)
        containerView.addSubview(iconImageView)

        wantsLayer = true
        layer?.cornerRadius = 14
        translatesAutoresizingMaskIntoConstraints = false

        containerView.translatesAutoresizingMaskIntoConstraints = false
        fileTypeTextField.drawsBackground = false
        fileTypeTextField.isBezeled = false
        fileTypeTextField.isEditable = false
        fileTypeTextField.isSelectable = false
        fileTypeTextField.translatesAutoresizingMaskIntoConstraints = false
        textTextField.drawsBackground = false
        textTextField.isBezeled = false
        textTextField.isEditable = false
        textTextField.isSelectable = false
        textTextField.cell?.lineBreakMode = .byTruncatingMiddle
        textTextField.translatesAutoresizingMaskIntoConstraints = false
        detailTextTextField.drawsBackground = false
        detailTextTextField.isBezeled = false
        detailTextTextField.isEditable = false
        detailTextTextField.isSelectable = false
        detailTextTextField.translatesAutoresizingMaskIntoConstraints = false
        detailTextTextField.cell?.truncatesLastVisibleLine = true
        iconImageView.unregisterDraggedTypes()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        let textTextFieldConstraint = textTextField.heightAnchor.constraint(lessThanOrEqualToConstant: 40)
        textTextFieldHeightConstraint = textTextFieldConstraint

        let detailTextTextFieldConstraint = detailTextTextField.heightAnchor.constraint(lessThanOrEqualToConstant: 70)
        detailTextTextFieldHeightConstraint = detailTextTextFieldConstraint

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -40),

            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 64),
            iconImageView.widthAnchor.constraint(equalToConstant: 64),

            fileTypeTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            fileTypeTextField.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 4),
            fileTypeTextField.heightAnchor.constraint(lessThanOrEqualToConstant: 26),
            fileTypeTextField.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor),

            textTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            textTextField.topAnchor.constraint(equalTo: fileTypeTextField.bottomAnchor, constant: 12),
            textTextFieldConstraint,
            textTextField.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor),

            detailTextTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            detailTextTextField.topAnchor.constraint(equalTo: textTextField.bottomAnchor),
            detailTextTextField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            detailTextTextFieldConstraint,
            detailTextTextField.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor)
        ])
    }

    override func draw(_ dirtyRect: NSRect) {
        // Background
        (isHoveringFile ? Colors.shade : NSColor.clear).setFill()
        dirtyRect.fill()

        // Padding
        let borderPadding: CGFloat = 6
        let drawRect = dirtyRect.insetBy(dx: borderPadding, dy: borderPadding)

        // Drop area outline drawing
        let alpha: CGFloat = file == nil ? 1 : 0.05
        let dashed = file == nil

        (isHoveringFile ? Colors.gray2 : Colors.gray1).withAlphaComponent(alpha).setStroke()

        let roundedRectanglePath = NSBezierPath(roundedRect: drawRect, xRadius: 8, yRadius: 8)
        roundedRectanglePath.lineWidth = 1.5

        if dashed {
            roundedRectanglePath.setLineDash([6, 6, 6, 6], count: 4, phase: 0)
        }

        roundedRectanglePath.stroke()
    }

    func acceptFile(url fileURL: URL) -> Bool {
        guard validFileURL(fileURL) else { return false }

        self.file = fileURL
        delegate?.receivedFile(dropZone: self, fileURL: fileURL)

        return true
    }
}

// MARK: NSDraggingDestination
extension DropZone {
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.isHoveringFile = (validDraggedFileURL(from: sender) != nil)
        return isHoveringFile ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.isHoveringFile = false
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        defer { self.isHoveringFile = false }
        guard let draggedFileURL = validDraggedFileURL(from: sender) else { return false }

        self.file = draggedFileURL
        delegate?.receivedFile(dropZone: self, fileURL: draggedFileURL)

        return true
    }

    private func validDraggedFileURL(from draggingInfo: NSDraggingInfo) -> URL? {
        guard
            let draggedFile = draggingInfo.draggingPasteboard.string(
                forType: kUTTypeFileURL as NSPasteboard.PasteboardType
            ),
            let draggedFileURL = URL(string: draggedFile)
        else {
            return nil
        }

        return validFileURL(draggedFileURL) ? draggedFileURL : nil
    }

    private func validFileURL(_ url: URL) -> Bool {
        return fileTypesPredicate.evaluate(with: url.path)
    }
}

// MARK: Helpers
extension DropZone {
    private struct Colors {
        static let gray1 = NSColor(calibratedWhite: 0.7, alpha: 1)
        static let gray2 = NSColor(calibratedWhite: 0.4, alpha: 1)
        static let shade = NSColor(calibratedWhite: 0.0, alpha: 0.025)
    }

    private struct Style {
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
