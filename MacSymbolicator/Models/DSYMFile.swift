//
//  DSYMFile.swift
//  MacSymbolicator
//

import Foundation

public struct DSYMFile: Equatable {
    let path: URL
    let filename: String
    let uuids: [Architecture: BinaryUUID]

    var binaryPath: String {
        let dwarfPath = path.appendingPathComponent("Contents")
                            .appendingPathComponent("Resources")
                            .appendingPathComponent("DWARF")

        guard let binary = (try? FileManager.default.contentsOfDirectory(atPath: dwarfPath.path))?.first else {
            return path.path
        }

        return dwarfPath.appendingPathComponent(binary).path
    }

    public static func dsymFiles(from url: URL) -> [DSYMFile] {
        if let file = DSYMFile(path: url) {
            return [file]
        } else {
            // Maybe embedded dSYM files created by fastlane. See https://github.com/inket/MacSymbolicator/issues/21
            let entries = (try? FileManager.default.contentsOfDirectory(atPath: url.path)) ?? []

            return entries.compactMap {
                guard $0.lowercased().hasSuffix(".dsym") else { return nil }
                return DSYMFile(path: url.appendingPathComponent($0))
            }
        }
    }

    public init?(path: URL) {
        self.path = path
        self.filename = path.lastPathComponent

        let result = "dwarfdump --uuid '\(path.path)'".run()
        let output = result.output?.trimmed

        if output == "", (result.error ?? "").trimmed != "" {
            return nil
        }

        var uuids = [Architecture: BinaryUUID]()

        output?.components(separatedBy: .newlines).forEach { line in
            guard
                let match = line.scan(pattern: #"UUID: (.*?) \((.*?)\)"#).first, match.count == 2,
                let rawArchitecture = match.last?.text, let architecture = Architecture(rawArchitecture),
                let rawUUID = match.first?.text, let uuid = BinaryUUID(rawUUID, architecture: architecture)
            else { return }

            uuids[architecture] = uuid
        }

        self.uuids = uuids
    }
}
