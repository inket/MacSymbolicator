//
//  FileSearch.swift
//  MacSymbolicator
//

import Foundation

protocol FileSearchQuery {
    func search(fileExtension: String) -> FileSearchResults
}

protocol FileSearchResults {
    var results: [String] { get }
    func firstMatching(uuid: String) -> String?

    func sorted() -> FileSearchResults
}

private class InternalFileSearch: FileSearchResults, FileSearchQuery {
    var directory: String?
    var shallow = false
    var results = [String]()

    private var enumerator: FileManager.DirectoryEnumerator? {
        let enumerationURL: URL
        if let directory = directory {
            enumerationURL = URL(fileURLWithPath: (directory as NSString).expandingTildeInPath)
        } else {
            enumerationURL = URL(fileURLWithPath: "/")
        }

        var enumerationOptions: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        if shallow {
            enumerationOptions.formUnion(.skipsSubdirectoryDescendants)
        }

        return FileManager.default.enumerator(
            at: enumerationURL,
            includingPropertiesForKeys: nil,
            options: enumerationOptions,
            errorHandler: nil
        )
    }

    func search(fileExtension: String) -> FileSearchResults {
        let nonDottedExtension = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased()

        results = enumerator?.compactMap { url in
            guard let url = url as? URL else { return nil }

            if url.pathExtension.lowercased() == nonDottedExtension {
                return url.path
            } else {
                return nil
            }
        } ?? []

        return self
    }

    func sorted() -> FileSearchResults {
        results.sort { $0.caseInsensitiveCompare($1) == .orderedDescending }
        return self
    }

    func firstMatching(uuid: String) -> String? {
        return results.first { file in
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

class FileSearch {
    private let internalFileSearch = InternalFileSearch()

    static var deep: FileSearch {
        let fileSearch = FileSearch()
        fileSearch.internalFileSearch.shallow = false
        return fileSearch
    }

    static var shallow: FileSearch {
        let fileSearch = FileSearch()
        fileSearch.internalFileSearch.shallow = true
        return fileSearch
    }

    private init() {}

    func `in`(directory: String) -> FileSearchQuery {
        internalFileSearch.directory = directory
        return internalFileSearch
    }

    func inRootDirectory() -> FileSearchQuery {
        internalFileSearch.directory = nil
        return internalFileSearch
    }
}
