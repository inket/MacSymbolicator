//
//  FileSearch.swift
//  MacSymbolicator
//

import Foundation

protocol UnixFindFileSearch {
    func search(name: String) -> FileSearchResults
}

protocol MetadataFindFileSearch {
    func search(name: String) -> FileSearchResults
    func search(UUID uuid: String) -> FileSearchResults
    func search(fileExtension: String) -> FileSearchResults
}

protocol FileSearchResults {
    var results: [String] { get }

    func filter(byFileExtension fileExtension: String) -> FileSearchResults
    func filter(byUUID uuid: String) -> FileSearchResults
}

private class InternalFileSearch: FileSearchResults, UnixFindFileSearch, MetadataFindFileSearch {
    var directory: String?
    var useUnixFind = false
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

    private func unixFind(_ condition: String) -> (output: String?, error: String?) {
        let directoryParameter = directory ?? "/"
        return ["find", directoryParameter, condition].joined(separator: " ").run()
    }

    internal func search(name: String) -> FileSearchResults {
        let output: String?
        if useUnixFind {
            output = unixFind("-name \(name)").output
        } else {
            output = mdfind("kMDItemFSName == \(name)").output
        }

        results = output?.trimmed.components(separatedBy: .newlines) ?? []
        return self
    }

    internal func search(UUID uuid: String) -> FileSearchResults {
        results = mdfind(uuid).output?.trimmed.components(separatedBy: .newlines) ?? []
        return self
    }

    internal func search(fileExtension: String) -> FileSearchResults {
        let fullExtension = fileExtension.hasPrefix(".") ? fileExtension : ".\(fileExtension)"
        results = mdfind("kMDItemFSName == *\(fullExtension)").output?.trimmed.components(separatedBy: .newlines) ?? []
        return self
    }

    internal func filter(byFileExtension fileExtension: String) -> FileSearchResults {
        let fullExtension = fileExtension.hasPrefix(".") ? fileExtension : ".\(fileExtension)"
        let predicate = NSPredicate(format: "SELF ENDSWITH[c] %@", fullExtension)
        results = ((results as NSArray).filtered(using: predicate) as? [String]) ?? []
        return self
    }

    internal func filter(byUUID uuid: String) -> FileSearchResults {
        results = results.filter { file in
            guard
                let dwarfDumpOutput = "dwarfdump --uuid \"\(file)\"".run().output?.trimmed,
                let foundUUID = dwarfDumpOutput.scan(pattern: "UUID: (.*) \\(").first?.first
            else {
                return false
            }
            return foundUUID == uuid
        }

        return self
    }
}

class FileSearch {
    private let internalFileSearch: InternalFileSearch

    var spotlight: MetadataFindFileSearch {
        internalFileSearch.useUnixFind = false
        return internalFileSearch
    }

    var unix: UnixFindFileSearch {
        internalFileSearch.useUnixFind = true
        return internalFileSearch
    }

    private init(_ internalFileSearch: InternalFileSearch) {
        self.internalFileSearch = internalFileSearch
    }

    static func `in`(directory: String) -> FileSearch {
        return FileSearch(InternalFileSearch(directory: directory))
    }

    static func inRootDirectory() -> FileSearch {
        return FileSearch(InternalFileSearch(directory: nil))
    }
}
