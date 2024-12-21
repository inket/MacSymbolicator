//
//  SymbolicatorTextView.swift
//  MacSymbolicator
//

import Cocoa

final class SymbolicatorTextView: NSTextView {
    init() {
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true

        let layoutManager = SymbolicatorTextViewLayoutManager()
        layoutManager.allowsNonContiguousLayout = true
        layoutManager.addTextContainer(textContainer)

        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)

        super.init(frame: .zero, textContainer: textContainer)

        isVerticallyResizable = true
        maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        layoutManager.textView = self

        textColor = NSColor.textColor.withAlphaComponent(0.7)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.1
        defaultParagraphStyle = paragraphStyle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var string: String {
        didSet {
            updateTextParagraphStyle()
        }
    }

    override var defaultParagraphStyle: NSParagraphStyle? {
        didSet {
            updateTextParagraphStyle()
        }
    }

    private func updateTextParagraphStyle() {
        guard let defaultParagraphStyle else {
            return
        }

        textStorage?.addAttributes(
            [
                .paragraphStyle: defaultParagraphStyle,
                .baselineOffset: 4
            ],
            range: NSRange(location: 0, length: string.count)
        )
    }
}
