//
//  StackFrame.swift
//  MacSymbolicator
//

import Foundation

final class StackFrame {
    private enum Parsing {
        static let lineRegex = #"^\d+\s+.*?0x.*?\s.*?\s\+\s.*$"#
        static let componentsRegex = #"^\d+\s+(.*?)\s+(0x.*?)\s(.*?)\s\+\s(\d*)"#
        static let sourceCodeRegex = #"\s+(\(([\w\-. ]+\.[\w\-. ]+)\:(\d+)\))"#

        static func replacementLoadAddressRegex(address: String, loadAddress: String) -> NSRegularExpression {
            // swiftlint:disable:next force_try
            try! NSRegularExpression(
                pattern: #"\#(address)\s\#(loadAddress)(?=\s\+.*?$)"#,
                options: [.caseInsensitive, .anchorsMatchLines]
            )
        }

        static func replacementTargetNameRegex(address: String, targetName: String) -> NSRegularExpression {
            // swiftlint:disable:next force_try
            try! NSRegularExpression(
                pattern: #"\#(address)\s\#(targetName)(?=\s\+.*?$)"#,
                options: [.caseInsensitive, .anchorsMatchLines]
            )
        }

        static let sampleLineRegex = #"\?{3}\s+\(in\s.*?\)\s+load\saddress\s+0x.*?\s+\+\s+.*?\s+\[0x.*?\]"#
        static let sampleComponentsRegex = #"\?{3}\s+\(in\s.*?\)\s+load\saddress\s+(0x.*?)\s+\+\s+(.*?)\s+\[(0x.*?)\]"#

        static func sampleReplacementRegex(address: String) -> NSRegularExpression {
            // swiftlint:disable:next force_try
            try! NSRegularExpression(
                pattern: #"\?{3}.*?\[\#(address)\]"#,
                options: [.caseInsensitive, .anchorsMatchLines]
            )
        }

        static let spindumpLineRegex = #"^\s*\*?\d+\s+\?{3}\s+\(.*?\s+\+\s+.*?\)\s+\[0x.*?\]"#
        static let spindumpComponentsRegex = #"^\s*\*?\d+\s+\?{3}\s+\((.*?)\s\+\s+(.*?)\)\s+\[(0x.*?)\]"#
    }

    let match: Match
    var symbolicatedMatch: String?

    let loadAddressMatch: Match?

    let address: String
    let binaryImage: BinaryImage
    let byteOffset: String
    let symbolicationRecommended: Bool

    var readableByteOffset: String {
        // Samples can have hexadecimal byte offsets, so we convert them to integers
        let value: Int?
        if byteOffset.hasPrefix("0x") {
            value = Int(byteOffset.dropFirst(2), radix: 16)
        } else {
            value = Int(byteOffset)
        }

        return value.flatMap { String($0) } ?? byteOffset
    }

    static func find(
        in content: Match,
        binaryImageMap: BinaryImageMap
    ) -> [StackFrame] {
        let lines = content.scan(
            pattern: Parsing.lineRegex,
            options: [.caseInsensitive, .anchorsMatchLines]
        )
        let sampleLines = content.scan(
            pattern: Parsing.sampleLineRegex,
            options: [.caseInsensitive, .anchorsMatchLines]
        )
        let spindumpLines = content.scan(
            pattern: Parsing.spindumpLineRegex,
            options: [.caseInsensitive, .anchorsMatchLines]
        )

        return (lines + sampleLines + spindumpLines).compactMap { result -> StackFrame? in
            guard let match = result.first else { return nil }
            return StackFrame(parsing: match, binaryImageMap: binaryImageMap)
        }
    }

    init?(parsing match: Match, binaryImageMap: BinaryImageMap) {
        self.match = match

        let loadAddressMatch: Match?
        let loadAddressOrTargetName: String
        let address: String
        let symbolicationRecommended: Bool

        if let components = match.scan(
            pattern: Parsing.componentsRegex,
            options: [.caseInsensitive]
        ).first, components.count == 4 {
            // Crash report format
            // Case 1: 0 = target, 1 = address, 2 = load address, 3 = byte offset
            // Case 2: 0 = target, 1 = address, 2 = target, 3 = byte offset
            // Case 3: 0 = target, 1 = address, 2 = symbol name, 3 = byte offset
            address = components[1].text
            if components[2].text.hasPrefix("0x") {
                // Case 1
                loadAddressMatch = components[2]
                loadAddressOrTargetName = components[2].text
                symbolicationRecommended = true
            } else if components[0].text == components[2].text {
                // Case 2
                loadAddressMatch = components[2]
                loadAddressOrTargetName = components[2].text
                symbolicationRecommended = true
            } else {
                // Case 3
                loadAddressMatch = components[2]
                loadAddressOrTargetName = components[0].text
                symbolicationRecommended = false
            }
            byteOffset = components[3].text
        } else if let components = match.scan(
            pattern: Parsing.sampleComponentsRegex,
            options: [.caseInsensitive]
        ).first, components.count == 3 {
            // Sample format, 0 = load address, 1 = byte offset, 2 = address
            loadAddressMatch = components[0]
            loadAddressOrTargetName = components[0].text
            byteOffset = components[1].text
            address = components[2].text
            symbolicationRecommended = true
        } else if let components = match.scan(
            pattern: Parsing.spindumpComponentsRegex,
            options: [.caseInsensitive]
        ).first, components.count == 3 {
            // Spindump format, 0 = target, 1 = byte offset, 2 = address
            loadAddressMatch = nil
            loadAddressOrTargetName = components[0].text
            byteOffset = components[1].text
            address = components[2].text
            symbolicationRecommended = true
        } else {
            return nil
        }

        let binaryImage =
            binaryImageMap.binaryImage(forLoadAddress: loadAddressOrTargetName) ??
            binaryImageMap.binaryImage(forName: loadAddressOrTargetName)

        guard let binaryImage else {
            return nil
        }

        self.loadAddressMatch = loadAddressMatch
        self.address = address
        self.binaryImage = binaryImage
        self.symbolicationRecommended = symbolicationRecommended
    }

    func replace(withResult result: String) {
        let symbolicatedMatch = NSMutableString(string: match.text)

        Parsing.sampleReplacementRegex(address: address).replaceMatches(
            in: symbolicatedMatch,
            range: NSRange(location: 0, length: symbolicatedMatch.length),
            withTemplate: "\(result) + \(readableByteOffset)  [\(address)]"
        )

        Parsing.replacementLoadAddressRegex(address: address, loadAddress: binaryImage.loadAddress).replaceMatches(
            in: symbolicatedMatch,
            range: NSRange(location: 0, length: symbolicatedMatch.length),
            withTemplate: "\(address) \(result)"
        )

        Parsing.replacementTargetNameRegex(address: address, targetName: binaryImage.name).replaceMatches(
            in: symbolicatedMatch,
            range: NSRange(location: 0, length: symbolicatedMatch.length),
            withTemplate: "\(address) \(result)"
        )

        self.symbolicatedMatch = String(symbolicatedMatch)
    }
}
