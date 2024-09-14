//
//  FileSearch.swift
//  MacSymbolicator
//

import Foundation

typealias LogHandler = (String) -> Void

protocol FileSearchQuery {
    func with(logHandler: @escaping LogHandler) -> FileSearchQuery
    func search(fileExtension: String) -> FileSearchResults
}

protocol FileSearchResults {
    var results: [String] { get }
    func matching(uuids: [String]) -> [SearchResult]

    func sorted() -> FileSearchResults
}

private final class InternalFileSearch: FileSearchResults, FileSearchQuery {
    var directory: String?
    var recursive = true
    var results = [String]()
    var logHandler: LogHandler?

    private var enumerator: FileManager.DirectoryEnumerator? {
        let enumerationURL: URL
        if let directory = directory {
            enumerationURL = URL(fileURLWithPath: (directory as NSString).expandingTildeInPath)
        } else {
            enumerationURL = URL(fileURLWithPath: "/")
        }

        var enumerationOptions: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        if !recursive {
            enumerationOptions.formUnion(.skipsSubdirectoryDescendants)
        }

        return FileManager.default.enumerator(
            at: enumerationURL,
            includingPropertiesForKeys: nil,
            options: enumerationOptions,
            errorHandler: nil
        )
    }

    func with(logHandler: @escaping LogHandler) -> FileSearchQuery {
        self.logHandler = logHandler
        return self
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

    func matching(uuids: [String]) -> [SearchResult] {
        return results.compactMap { file in
            let command = "dwarfdump --uuid \"\(file)\""
            let commandResult = command.run()

            if let errorOutput = commandResult.error?.trimmed, !errorOutput.isEmpty {
                // dwarfdump --uuid on /Users/x/Library/Developer/Xcode/Archives seems to output the dsym identifier
                // correctly followed by an stderr message about not being able to open macho file due to
                // "Too many levels of symbolic links". Seems safe to ignore.
                if !errorOutput.contains("Too many levels of symbolic links") {
                    logHandler?("\(command):\n\(errorOutput)")
                }
            }

            guard let dwarfDumpOutput = commandResult.output?.trimmed else { return nil }

            let foundUUIDs = dwarfDumpOutput.scan(pattern: #"UUID: (.*) \("#).flatMap({ $0 })
            for foundUUID in foundUUIDs {
                if uuids.contains(foundUUID) {
                    return SearchResult(path: file, matchedUUID: foundUUID)
                }
            }

            return nil
        }
    }
}

final class FileSearch {
    private let internalFileSearch = InternalFileSearch()

    static var recursive: FileSearch {
        let fileSearch = FileSearch()
        fileSearch.internalFileSearch.recursive = true
        return fileSearch
    }

    static var nonRecursive: FileSearch {
        let fileSearch = FileSearch()
        fileSearch.internalFileSearch.recursive = false
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
