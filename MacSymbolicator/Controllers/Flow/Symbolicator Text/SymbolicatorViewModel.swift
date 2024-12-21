//
//  SymbolicatorViewModel.swift
//  MacSymbolicator
//

import Cocoa

final class SymbolicatorViewModel {
    struct SymbolicatorToken {
        enum State {
            case unsymbolicated
            case symbolicated
            case system

            var borderColor: NSColor {
                switch self {
                case .unsymbolicated:
                    return NSColor(calibratedRed: 187 / 255, green: 123 / 255, blue: 121 / 255, alpha: 1)
                case .symbolicated:
                    return NSColor(calibratedRed: 130 / 255, green: 180 / 255, blue: 120 / 255, alpha: 1)
                case .system:
                    return NSColor.clear
                }
            }

            var backgroundColor: NSColor {
                switch self {
                case .unsymbolicated:
                    return NSColor(calibratedRed: 242 / 255, green: 172 / 255, blue: 170 / 255, alpha: 1)
                case .symbolicated:
                    return NSColor(calibratedRed: 167 / 255, green: 219 / 255, blue: 158 / 255, alpha: 1)
                case .system:
                    return NSColor.clear
                }
            }

            var foregroundColor: NSColor? {
                switch self {
                case .unsymbolicated:
                    return NSColor.textColor.resolved(for: .aqua)
                case .symbolicated:
                    return NSColor.textColor.resolved(for: .aqua)
                case .system:
                    return NSColor.textColor
                }
            }
        }

        let range: NSRange

        let text: String
        let replacementText: String

        let attributedString: NSAttributedString

        let state: State

        init(range: NSRange, text: String, replacementText: String, state: State, font: NSFont) {
            self.range = range
            self.text = text
            self.replacementText = replacementText
            self.state = state

            let textAttachment = NSTextAttachment()
            textAttachment.attachmentCell = SymbolicatorTokenTextAttachmentCell(
                text: replacementText,
                font: font
            )
            attributedString = NSAttributedString(attachment: textAttachment)
        }
    }

    let reportFile: ReportFile
    let defaultSaveURL: URL?
    let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

    var text: String {
        reportFile.content
    }

    private(set) lazy var lazyTokens: LazyAsync<[SymbolicatorToken]> = LazyAsync { [weak self] in
        guard let self else { return [] }
        return await createTokens()
    }
    var tokens: [SymbolicatorToken] {
        get async {
            await lazyTokens.get()
        }
    }

    init(reportFile: ReportFile, defaultSaveURL: URL?) {
        self.reportFile = reportFile
        self.defaultSaveURL = defaultSaveURL
    }

    @MainActor
    func createTokens() async -> [SymbolicatorToken] {
        var tokens: [SymbolicatorToken] = []

        (await reportFile.processes).forEach { process in
            process.frames.forEach { frame in
                guard
                    let loadAddressMatch = frame.loadAddressMatch
                else { return }

                let state: SymbolicatorToken.State
                if frame.binaryImage.isLikelySystem {
                    state = .system
                } else if frame.symbolicationRecommended {
                    state = .unsymbolicated
                } else {
                    state = .symbolicated
                }

                tokens.append(
                    .init(
                        range: loadAddressMatch.range,
                        text: loadAddressMatch.text,
                        replacementText: "YAY\(loadAddressMatch.text)YAY",
                        state: state,
                        font: font
                    )
                )
            }
        }

        tokens.sort { left, right in
            left.range.location < right.range.location
        }

        return tokens
    }
}
