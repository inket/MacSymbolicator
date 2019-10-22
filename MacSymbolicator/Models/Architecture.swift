//
//  Architecture.swift
//  MacSymbolicator
//

import Foundation

enum Architecture: Hashable {
    case x86
    case x86_64
    case arm64
    case arm(String?)

    init?(_ string: String) {
        let archString = string.lowercased()
        switch archString {
        case "x86-64", "x86_64": self = .x86_64
        case "x86", "i386": self = .x86
        case "arm-64", "arm64", "arm_64": self = .arm64
        case "arm": self = .arm(nil)
        case _ where archString.hasPrefix("arm"): self = .arm(archString)
        default: return nil
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
