//
//  DSYMFile.swift
//  MacSymbolicator
//

import Foundation

public struct DSYMFile {
    let path: URL
    let filename: String
    var uuid: String?

    var binaryPath: String {
        let dwarfPath = path.appendingPathComponent("Contents")
                            .appendingPathComponent("Resources")
                            .appendingPathComponent("DWARF")

        guard let binary = (try? FileManager.default.contentsOfDirectory(atPath: dwarfPath.path))?.first else {
            return path.path
        }

        return dwarfPath.appendingPathComponent(binary).path
    }

    public init(path: URL) {
        self.path = path
        self.filename = path.lastPathComponent

        let output = "dwarfdump --uuid '\(path.path)'".run().output?.trimmed
        if let dwarfDumpOutput = output {
            self.uuid = dwarfDumpOutput.scan(pattern: "UUID: (.*) \\(").first?.first
        }
    }
}
