//
//  SymbolicatorTokenTextAttachmentCell.swift
//  MacSymbolicator
//

import Cocoa

class SymbolicatorTokenTextAttachmentCell: NSTextAttachmentCell {
    let text: String

    lazy var attributedText = NSAttributedString(
        string: text,
        attributes: [
            .font: font as Any,
            .foregroundColor: NSColor.textColor
        ]
    )

    lazy var textSize: CGSize = {
        let size = attributedText.size()
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }()

    init(text: String, font: NSFont) {
        self.text = text
        super.init()
        self.font = font
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func cellSize() -> NSSize {
        textSize
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?) {
        let path = NSBezierPath(roundedRect: cellFrame, xRadius: 8, yRadius: 8)
        path.lineWidth = 2
        NSColor.blue.setFill()
        path.fill()

        attributedText.draw(in: cellFrame)
    }
}
