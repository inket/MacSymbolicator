//
//  Architecture.swift
//  MacSymbolicator
//

import Foundation

enum Architecture: Hashable {
    case x86
    case x86_64 // swiftlint:disable:this identifier_name
    case arm64
    case arm(String?)

    private static let architectureRegex = #"^(?:Architecture|Code Type):(.*?)(\(.*\))?$"#
    private static let binaryImagesRegex = #"Binary Images:.*\s+([^\s]+)\s+<"#

    static func find(in content: String) -> Architecture? {
        var result = content.scan(pattern: Self.architectureRegex).first?.first?.trimmed
            .components(separatedBy: " ").first.flatMap(Architecture.init)

        // In the case of plain "ARM" (without version or specifiers) the actual architecture is on
        // the first line of Binary Images. Cannot find recent examples of this, but keeping behavior just in case.
        if result?.isIncomplete == true {
            result = (content.scan(
                pattern: Self.binaryImagesRegex,
                options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
            ).first?.first?.trimmed).flatMap(Architecture.init)
        }

        return result
    }

    init?(_ string: String) {
        let archString = string.lowercased()
        if archString.hasPrefix("x86-64") || archString.hasPrefix("x86_64") {
            // Example sub-architecture: x86_64h
            self = .x86_64
        } else if ["x86", "i386"].contains(archString) {
            self = .x86
        } else if archString == "arm" {
            self = .arm(nil) // More details can be found in the binary images, e.g. arm64e
        } else if ["arm-64", "arm64", "arm_64"].contains(archString) {
            self = .arm64
        } else if archString.hasPrefix("arm") {
            // Example sub-architecture: armv7
            self = .arm(archString)
        } else {
            return nil
        }
    }

    var atosString: String? {
        switch self {
        case .x86: return "i386"
        case .x86_64: return "x86_64"
        case .arm64: return "arm64"
        case .arm(let raw): return raw
        }
    }

    var isIncomplete: Bool {
        switch self {
        case .x86, .x86_64, .arm64: return false
        case .arm(let raw): return raw == nil
        }
    }
}
