//
//  StringExtensions.swift
//  MacSymbolicator
//

import Cocoa

struct CommandResult {
    let output: String?
    let error: String?
}

extension String {
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func run() -> CommandResult {
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

        return CommandResult(
            output: String(data: outFileHandle.readDataToEndOfFile(), encoding: .utf8),
            error: String(data: errFileHandle.readDataToEndOfFile(), encoding: .utf8)
        )
    }

    subscript(_ oldRange: NSRange) -> Substring? {
        if let range = Range<String.Index>(oldRange, in: self) {
            return self[range]
        } else {
            return nil
        }
    }
}
