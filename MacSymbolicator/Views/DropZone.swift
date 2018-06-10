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

    private var _fileType: String = "" {
        didSet {
            self.icon = NSWorkspace.shared.icon(forFileType: _fileType)

            registerForDraggedTypes([(kUTTypeFileURL as NSPasteboard.PasteboardType)])

            fileTypeTextField.attributedStringValue = NSAttributedString(
                string: _fileType,
                attributes: Style.textAttributes(size: 16, color: Colors.gray3)
            )
        }
    }

    var fileType: String {
        get { return _fileType }
        set {
            // Prepend "." to fileType if needed
            _fileType = (newValue.hasPrefix(".") ? "" : ".").appending(newValue.lowercased())
        }
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
                attributes: Style.textAttributes(size: 14, color: Colors.gray2)
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
                attributes: Style.textAttributes(size: 12, color: Colors.gray2)
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
    init(fileType: String, text: String? = nil, detailText: String? = nil) {
        super.init(frame: .zero)

        defer {
            self.fileType = fileType
            self.text = text
            self.detailText = detailText

            setup()
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
        (isHoveringFile ? Colors.shade : Colors.transparent).setFill()
        dirtyRect.fill()

        // Padding
        let borderPadding: CGFloat = 6
        let drawRect = dirtyRect.insetBy(dx: borderPadding, dy: borderPadding)

        // Dashed drop area outline drawing
        if file == nil {
            (isHoveringFile ? Colors.gray3 : Colors.gray1).setStroke()

            let roundedRectanglePath = NSBezierPath(roundedRect: drawRect, xRadius: 8, yRadius: 8)
            roundedRectanglePath.lineWidth = 1.5
            roundedRectanglePath.setLineDash([6, 6, 6, 6], count: 4, phase: 0)
            roundedRectanglePath.stroke()
        }
    }
}

// MARK: NSDraggingDestination
extension DropZone {
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.isHoveringFile = (validFileURL(sender) != nil)
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
        guard let draggedFileURL = validFileURL(sender) else { return false }

        self.file = draggedFileURL
        delegate?.receivedFile(dropZone: self, fileURL: draggedFileURL)

        return true
    }

    private func validFileURL(_ sender: NSDraggingInfo) -> URL? {
        guard
            let draggedFile = sender.draggingPasteboard.string(forType: kUTTypeFileURL as NSPasteboard.PasteboardType),
            let draggedFileURL = URL(string: draggedFile)
        else {
            return nil
        }

        let predicate = NSPredicate(format: "SELF ENDSWITH[c] %@ || SELF ENDSWITH[c] %@", _fileType, "\(_fileType)/")
        return predicate.evaluate(with: draggedFileURL.absoluteString) ? draggedFileURL : nil
    }
}

// MARK: Helpers
extension DropZone {
    private struct Colors {
        static let gray1 = NSColor(calibratedWhite: 0.7, alpha: 1)
        static let gray2 = NSColor(calibratedWhite: 0.6, alpha: 1)
        static let gray3 = NSColor(calibratedWhite: 0.4, alpha: 1)
        static let shade = NSColor(calibratedWhite: 0.0, alpha: 0.025)
        static let transparent = NSColor(calibratedWhite: 0.0, alpha: 0)
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
