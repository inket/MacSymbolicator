//
//  StackTraceCall.swift
//  MacSymbolicator
//

import Foundation

struct StackTraceCall {
    let address: String
    let loadAddress: String

    private static let crashLineRegex = "^\\d+\\s+.*?0x.*?\\s0x.*?\\s"
    private static let crashAddressRegex = "^\\d+\\s+.*?(0x.*?)\\s(0x.*?)\\s"

    static func crashReplacementRegex(address: String) -> String {
        "\(address)\\s0x.*?$"
    }

    private static let sampleLineRegex = "\\?{3}\\s+\\(in\\s.*?\\)\\s+load\\saddress.*?\\[0x.*?\\]"
    private static let sampleAddressRegex = "\\?{3}\\s+\\(in\\s.*?\\)\\s+load\\saddress\\s*(0x.*?)\\s.*?\\[(0x.*?)\\]"

    static func sampleReplacementRegex(address: String) -> String {
        "\\?{3}.*?\\[\(address)\\]"
    }

    static func find(in content: String) -> [StackTraceCall] {
        let crashCalls = content.scan(
            pattern: crashLineRegex,
            options: [.caseInsensitive, .anchorsMatchLines]
        )
        .compactMap { $0.first.flatMap(StackTraceCall.init(parsingLine:)) }

        let sampleCalls = content.scan(
            pattern: sampleLineRegex,
            options: [.caseInsensitive, .anchorsMatchLines]
        )
        .compactMap { $0.first.flatMap(StackTraceCall.init(parsingLine:)) }

        return crashCalls + sampleCalls
    }

    init?(parsingLine line: String) {
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
        } else {
            return nil
        }
    }
}
