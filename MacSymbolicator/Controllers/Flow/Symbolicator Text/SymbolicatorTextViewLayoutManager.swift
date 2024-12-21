//
//  SymbolicatorTextViewLayoutManager.swift
//  MacSymbolicator
//

import Cocoa

public extension NSAttributedString.Key {
	static let token = NSAttributedString.Key("token")
}

class SymbolicatorTextViewLayoutManager: NSLayoutManager {
    weak var textView: NSTextView?

    private struct GlyphRange {
        let range: NSRange
        let includesTextStart: Bool
        let includesTextEnd: Bool
    }

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let context = NSGraphicsContext.current else {
            return
        }

        let characterRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        var placeholders = [(BoundingRect, SymbolicatorViewModel.SymbolicatorToken.State)]()

        let selectedRanges = textView?.selectedRanges.map { $0.rangeValue } ?? []

        textStorage?.enumerateAttribute(.token, in: characterRange, options: []) { value, range, _ in
            guard let state = value as? SymbolicatorViewModel.SymbolicatorToken.State else { return }

            let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            let glyphRanges = glyphRange.subtracting(selectedRanges)

            for glyphRange in glyphRanges {
                let glyphRangeWithStartingEndingMetadata: GlyphRange
                glyphRangeWithStartingEndingMetadata = GlyphRange(
                    range: glyphRange.range,
                    includesTextStart: !glyphRange.shortenedFromStart,
                    includesTextEnd: !glyphRange.shortenedFromEnd
                )

                let container = textContainer(forGlyphAt: glyphRange.range.location, effectiveRange: nil)
                let rects = boundingRects(
                    forGlyphRange: glyphRangeWithStartingEndingMetadata,
                    in: container ?? NSTextContainer()
                )

                for rect in rects {
                    placeholders.append((rect, state))
                }
            }
        }

        context.saveGraphicsState()

        for (boundingRect, state) in placeholders {
            let color = state.backgroundColor
            let borderColor = state.borderColor

            let dxInset: CGFloat = -8
            let dyInset: CGFloat = 2
            let drawingRect = boundingRect.rect.insetBy(
                minXInset: boundingRect.includesTextStart ? dxInset / 2 : 0,
                maxXInset: boundingRect.includesTextEnd ? dxInset / 2 : 0,
                minYInset: dyInset / 2,
                maxYInset: dyInset / 2
            )

            let borderRect = drawingRect
            let borderCornerRadius = borderRect.height / 2
            let backgroundRect = borderRect.insetBy(dx: 1, dy: 1)
            let backgroundCornerRadius = backgroundRect.height / 2

            borderColor.setFill()
            NSBezierPath.smoothRoundedRect(
                borderRect,
                topLeftCornerRadius: boundingRect.includesTextStart ? borderCornerRadius : 0,
                topRightCornerRadius: boundingRect.includesTextEnd ? borderCornerRadius : 0,
                bottomLeftCornerRadius: boundingRect.includesTextStart ? borderCornerRadius : 0,
                bottomRightCornerRadius: boundingRect.includesTextEnd ? borderCornerRadius : 0
            ).fill()

            color.setFill()
            NSBezierPath.smoothRoundedRect(
                backgroundRect,
                topLeftCornerRadius: boundingRect.includesTextStart ? backgroundCornerRadius : 0,
                topRightCornerRadius: boundingRect.includesTextEnd ? backgroundCornerRadius : 0,
                bottomLeftCornerRadius: boundingRect.includesTextStart ? backgroundCornerRadius : 0,
                bottomRightCornerRadius: boundingRect.includesTextEnd ? backgroundCornerRadius : 0
            ).fill()
        }

        context.restoreGraphicsState()

        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
}

extension SymbolicatorTextViewLayoutManager {
    private struct BoundingRect {
        let rect: NSRect
        let includesTextStart: Bool
        let includesTextEnd: Bool
    }

    private func boundingRects(forGlyphRange glyphRange: GlyphRange, in container: NSTextContainer) -> [BoundingRect] {
        // In the original implementation of boundingRect(forGlyphRange:in:), multi-line text will have a rect that
        // covers the entire text, disregarding where the text actually starts and ends.
        // Example: If we want to highlight "brown fox jumps over" in the following text:
        // "The quick brown fox
        //  jumps over the lazy dog"
        // the bounding rect will include "The quick" and "the lazy" because the only rectangle that can contain our
        // desired text accidentally includes the other words.
        // The solution is to find out the rect for each line until we've had all vertically distinct bounding rects.
        guard glyphRange.range.length > 1 else {
            return [BoundingRect(
                rect: boundingRect(forGlyphRange: glyphRange.range, in: container),
                includesTextStart: glyphRange.includesTextStart,
                includesTextEnd: glyphRange.includesTextEnd
            )]
        }

        let firstCharacterRange = NSRange(location: glyphRange.range.location, length: 1)
        let firstCharacterRect = boundingRect(forGlyphRange: firstCharacterRange, in: container)
        let lastCharacterRange = NSRange(location: glyphRange.range.location + glyphRange.range.length - 1, length: 1)
        let lastCharacterRect = boundingRect(forGlyphRange: lastCharacterRange, in: container)

        if firstCharacterRect.maxY == lastCharacterRect.maxY, firstCharacterRect.minY == lastCharacterRect.minY {
            // Both the first character and the last character are on the same rect, meaning it's one line
            return [BoundingRect(
                rect: boundingRect(forGlyphRange: glyphRange.range, in: container),
                includesTextStart: glyphRange.includesTextStart,
                includesTextEnd: glyphRange.includesTextEnd
            )]
        } else {
            let entireTextRect = boundingRect(forGlyphRange: glyphRange.range, in: container)
            let firstLineRect = NSRect(
                x: firstCharacterRect.minX,
                y: firstCharacterRect.minY,
                width: entireTextRect.width - firstCharacterRect.minX,
                height: firstCharacterRect.height
            )
            let lastLineRect = NSRect(
                x: entireTextRect.minX,
                y: lastCharacterRect.minY,
                width: lastCharacterRect.maxX - entireTextRect.minX,
                height: lastCharacterRect.height
            )
            var middleLinesRects: [NSRect] = []

            var workingRange = NSRange(location: glyphRange.range.location, length: 1)
            var previousLineRect = firstLineRect
            while workingRange.upperBound <= glyphRange.range.upperBound, previousLineRect.minY != lastLineRect.minY {
                let newLineRect = boundingRect(forGlyphRange: workingRange, in: container)

                if newLineRect.minY != previousLineRect.minY, newLineRect.minY != lastLineRect.minY {
                    // New line
                    middleLinesRects.append(NSRect(
                        x: entireTextRect.minX,
                        y: newLineRect.minY,
                        width: entireTextRect.width,
                        height: newLineRect.height
                    ))
                    previousLineRect = newLineRect
                }

                // Advance in the range by 10 characters (or by only one character if 10 is too many)
                // This of course assumes that our text view is wide enough to fit at least 10 characters per line
                workingRange.location += 10
                if workingRange.upperBound > glyphRange.range.upperBound {
                    workingRange.location -= 10
                    workingRange.location += 1
                }
            }

            var result: [BoundingRect] = []
            result.append(BoundingRect(
                rect: firstLineRect,
                includesTextStart: glyphRange.includesTextStart,
                includesTextEnd: false
            ))
            for middleLineRect in middleLinesRects {
                result.append(BoundingRect(
                    rect: middleLineRect,
                    includesTextStart: glyphRange.includesTextStart,
                    includesTextEnd: glyphRange.includesTextEnd
                ))
            }
            result.append(BoundingRect(
                rect: lastLineRect,
                includesTextStart: false,
                includesTextEnd: glyphRange.includesTextEnd
            ))
            return result
        }
    }
}
