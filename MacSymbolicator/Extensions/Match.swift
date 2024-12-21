//
//  Match.swift
//  MacSymbolicator
//

import Foundation

extension String {
    func scan(
        pattern: String,
        options: NSRegularExpression.Options = [.caseInsensitive, .anchorsMatchLines]
    ) -> [[Match]] {
        Match(rangeOffset: 0, text: self, originalText: self)
            .scan(pattern: pattern, options: options)
    }
}

struct Match: Hashable, Equatable, Sendable {
    let range: NSRange
    let text: String
    let originalText: String

    init(range: NSRange, text: String, originalText: String) {
        self.range = range
        self.text = text
        self.originalText = originalText
    }

    init(rangeOffset: Int, text: String, originalText: String) {
        range = NSRange(location: 0, length: 0)
        self.text = text
        self.originalText = originalText
    }

    func scan(
        pattern: String,
        options: NSRegularExpression.Options = [.caseInsensitive, .anchorsMatchLines]
    ) -> [[Match]] {
        let offset = range.location

        // swiftlint:disable:next force_try
        let regularExpression = try! NSRegularExpression(pattern: pattern, options: options)
        let matches = regularExpression.matches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..., in: text)
        )

        return matches.map {
            var matchesResult = [Match]()
            let startIndex = $0.numberOfRanges == 1 ? 0 : 1

            for rangeIndex in startIndex...($0.numberOfRanges - 1) {
                let range = $0.range(at: rangeIndex)

                if let newRange = Range<String.Index>(range, in: text) {
                    let matchRange = NSRange(location: offset + range.location, length: range.length)

                    matchesResult.append(Match(
                        range: matchRange,
                        text: String(text[newRange]),
                        originalText: originalText
                    ))
                }
            }

            return matchesResult
        }
    }
}
