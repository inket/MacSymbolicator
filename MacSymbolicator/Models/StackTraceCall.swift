//
//  StackTraceCall.swift
//  MacSymbolicator
//

import Foundation

struct StackTraceCall {
    let address: String
    let loadAddress: String

    private static let crashLineRegex = #"^\d+\s+.*?0x.*?\s0x.*?\s"#
    private static let crashAddressRegex = #"^\d+\s+.*?(0x.*?)\s(0x.*?)\s"#

    static func crashReplacementRegex(address: String) -> NSRegularExpression {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(
            pattern: #"\#(address)\s0x.*?$"#,
            options: [.caseInsensitive, .anchorsMatchLines]
        )
    }

    private static let sampleLineRegex = #"\?{3}\s+\(in\s.*?\)\s+load\saddress.*?\[0x.*?\]"#
    private static let sampleAddressRegex = #"\?{3}\s+\(in\s.*?\)\s+load\saddress\s*(0x.*?)\s.*?\[(0x.*?)\]"#

    static func sampleReplacementRegex(address: String) -> NSRegularExpression {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(
            pattern: #"\?{3}.*?\[\#(address)\]"#,
            options: [.caseInsensitive, .anchorsMatchLines]
        )
    }

    private static let spindumpLineRegex = #"^\s*\d+\s+\?{3}\s+\(.*?\+.*?\)\s+\[0x.*?\]"#
    private static let spindumpTargetAddressRegex = #"^\s*\d+\s+\?{3}\s+\((.*?)\s\+.*?\)\s+\[(0x.*?)\]"#

    static func find(in content: String, withLoadAddresses loadAddresses: [String: String]) -> [StackTraceCall] {
        let crashLines = content.scan(pattern: crashLineRegex, options: [.caseInsensitive, .anchorsMatchLines])
        let sampleLines = content.scan(pattern: sampleLineRegex, options: [.caseInsensitive, .anchorsMatchLines])
        let spindumpLines = content.scan(pattern: spindumpLineRegex, options: [.caseInsensitive, .anchorsMatchLines])

        return (crashLines + sampleLines + spindumpLines).compactMap { result -> StackTraceCall? in
            guard let line = result.first else { return nil }
            return StackTraceCall(parsingLine: line, loadAddresses: loadAddresses)
        }
    }

    init?(parsingLine line: String, loadAddresses: [String: String]) {
        if let addresses = line.scan(pattern: Self.crashAddressRegex, options: [.caseInsensitive]).first,
           addresses.count == 2 {
            // Crash report format
            address = addresses[0]
            loadAddress = addresses[1]
        } else if let addresses = line.scan(pattern: Self.sampleAddressRegex, options: [.caseInsensitive]).first,
                  addresses.count == 2 {
            // Sample format
            loadAddress = addresses[0]
            address = addresses[1]
        } else if let groups = line.scan(
            pattern: Self.spindumpTargetAddressRegex,
            options: [.caseInsensitive]
        ).first, groups.count == 2 {
            // Spindump format does not include the load address so we have to retrieve it from the Binary Images
            let targetName = groups[0]

            if let loadAddress = loadAddresses[targetName] {
                self.loadAddress = loadAddress
                address = groups[1]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
