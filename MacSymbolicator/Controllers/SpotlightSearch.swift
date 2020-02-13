//
//  SpotlightSearch.swift
//  MacSymbolicator
//

import Foundation

protocol MetadataSearch {
    func search(uuid: String) -> SpotlightSearchResults
    func search(fileExtension: String) -> SpotlightSearchResults
}

protocol SpotlightSearchResults {
    var results: [String] { get }

    func firstMatching(uuid: String) -> String?
    func firstMatching(fileExtension: String) -> String?
}

private class InternalSpotlightSearch: SpotlightSearchResults, MetadataSearch {
    var directory: String?
    var results = [String]()

    init(directory: String?) {
        self.directory = directory
    }

    private func mdfind(_ condition: String) -> (output: String?, error: String?) {
        let directoryParameter: String
        if let directory = directory {
            directoryParameter = "-onlyin \"\(directory)\""
        } else {
            directoryParameter = ""
        }

        return ["mdfind", directoryParameter, "'\(condition)'"].joined(separator: " ").run()
    }

    func search(uuid: String) -> SpotlightSearchResults {
        let output = mdfind("com_apple_xcode_dsym_uuids == \(uuid)").output
        results = output?.trimmed.components(separatedBy: .newlines) ?? []
        return self
    }

    func search(fileExtension: String) -> SpotlightSearchResults {
        let fullExtension = fileExtension.hasPrefix(".") ? fileExtension : ".\(fileExtension)"

        // Search for dSYM files without UUIDs since we already searched for the UUID and didn't find it.
        // This prevents the overlap in results and us running dwarfdump on files that didn't need it.
        // (Ideally we would use ==[c] for the comparison but that doesn't work for some reason)
        results = mdfind(
            "mdfind 'kMDItemFSName == *\(fullExtension) && com_apple_xcode_dsym_uuids != *'"
        ).output?.trimmed.components(separatedBy: .newlines) ?? []

        return self
    }

    func firstMatching(fileExtension: String) -> String? {
        let fullExtension = fileExtension.hasPrefix(".") ? fileExtension : ".\(fileExtension)"
        let predicate = NSPredicate(format: "SELF ENDSWITH[c] %@", fullExtension)
        return results.first { predicate.evaluate(with: $0) }
    }

    func firstMatching(uuid: String) -> String? {
        results.first { file in
            guard
                let dwarfDumpOutput = "dwarfdump --uuid \"\(file)\"".run().output?.trimmed,
                let foundUUID = dwarfDumpOutput.scan(pattern: "UUID: (.*) \\(").first?.first
            else {
                return false
            }
            return foundUUID == uuid
        }
    }
}

class SpotlightSearch {
    static func `in`(directory: String) -> MetadataSearch {
        InternalSpotlightSearch(directory: directory)
    }

    static var inRootDirectory: MetadataSearch {
        InternalSpotlightSearch(directory: nil)
    }
}
