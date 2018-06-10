//
//  StringExtensions.swift
//  MacSymbolicator
//

import Cocoa

extension String {
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func run() -> (output: String?, error: String?) {
        let pipe = Pipe()
        let errorPipe = Pipe()

        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", self]
        process.standardOutput = pipe
        process.standardError = errorPipe

        let outFileHandle = pipe.fileHandleForReading
        let errFileHandle = errorPipe.fileHandleForReading
        process.launch()

        return (
            String(data: outFileHandle.readDataToEndOfFile(), encoding: .utf8),
            String(data: errFileHandle.readDataToEndOfFile(), encoding: .utf8)
        )
    }

    func scan(
        pattern: String, options: NSRegularExpression.Options = [.caseInsensitive, .anchorsMatchLines]
    ) -> [[String]] {
        // swiftlint:disable:next force_try
        let regularExpression = try! NSRegularExpression(pattern: pattern, options: options)
        let matches = regularExpression.matches(in: self, options: [], range: NSRange(self.startIndex..., in: self))
        return matches.map {
            var match = [String]()
            let startIndex = $0.numberOfRanges == 1 ? 0 : 1
            for rangeIndex in startIndex...($0.numberOfRanges - 1) {
                let range = $0.range(at: rangeIndex)
                if let newRange = Range<Index>(range, in: self) {
                    match.append(String(self[newRange]))
                }
            }
            return match
        }
    }
}
