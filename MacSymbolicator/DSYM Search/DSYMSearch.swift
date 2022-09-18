//
//  DSYMSearch.swift
//  MacSymbolicator
//

import Foundation

class DSYMSearch {
    struct SearchResult {
        let path: String
        let matchedUUID: String

        init(path: String, matchedUUID: String) {
            self.path = path
            self.matchedUUID = matchedUUID
        }

        init(_ fileSearchResult: FileSearchResult) {
            path = fileSearchResult.path
            matchedUUID = fileSearchResult.matchedUUID
        }
    }

    typealias Callback = (_ finished: Bool, _ results: [SearchResult]?) -> Void
    private static let spotlightSearch = SpotlightSearch()

    static func search(
        forUUIDs uuids: [String],
        reportFileDirectory: String,
        logHandler: @escaping LogHandler,
        callback: @escaping Callback
    ) {
        logHandler(["Searching Spotlight for UUIDs: \(uuids)"])

        spotlightSearch.search(forUUIDs: uuids) { results in
            // Processing of results and file searches should be on a background thread to not block main
            DispatchQueue.global().async {
                // Deduplicate the results. Some DSYMs might be duplicated in other locations
                var foundItems: [String: SearchResult] = [:]
                results?.forEach {
                    guard let dsymPath = dsymPath(from: $0.item, withUUID: $0.matchedUUID) else { return }

                    logHandler(["Found \($0.matchedUUID): \(dsymPath)"])
                    foundItems[$0.matchedUUID] = SearchResult(path: dsymPath, matchedUUID: $0.matchedUUID)
                }

                let searchUUIDs = Set<String>(uuids)
                var foundUUIDs = Set<String>(foundItems.keys)
                var notFoundUUIDs = searchUUIDs.subtracting(foundUUIDs)

                callback(notFoundUUIDs.isEmpty, Array(foundItems.values))

                // No need to continue if we already found what we're looking for.
                guard !notFoundUUIDs.isEmpty else { return }

                logHandler(["Non-recursive file search starting at \(reportFileDirectory) for UUIDs: \(notFoundUUIDs)"])
                foundItems = [:]
                FileSearch
                    .nonRecursive
                    .in(directory: reportFileDirectory)
                    .with(logHandler: logHandler)
                    .search(fileExtension: "dsym").sorted().matching(uuids: Array(notFoundUUIDs))
                    .forEach {
                        logHandler(["Found \($0.matchedUUID): \($0.path)"])
                        foundItems[$0.matchedUUID] = SearchResult($0)
                    }

                foundUUIDs = Set<String>(foundItems.keys)
                notFoundUUIDs.subtract(foundUUIDs)

                callback(notFoundUUIDs.isEmpty, Array(foundItems.values))

                // No need to continue if we already found what we're looking for.
                guard !notFoundUUIDs.isEmpty else { return }

                logHandler([
                    "Recursive file search starting at ~/Library/Developer/Xcode/Archives/ for UUIDs: \(notFoundUUIDs)"
                ])
                foundItems = [:]
                FileSearch
                    .recursive
                    .in(directory: "~/Library/Developer/Xcode/Archives/")
                    .with(logHandler: logHandler)
                    .search(fileExtension: "dsym").sorted().matching(uuids: Array(notFoundUUIDs))
                    .forEach {
                        logHandler(["Found \($0.matchedUUID): \($0.path)"])
                        foundItems[$0.matchedUUID] = SearchResult($0)
                    }

                foundUUIDs = Set<String>(foundItems.keys)
                notFoundUUIDs.subtract(foundUUIDs)

                logHandler(["Remaining UUIDs: \(notFoundUUIDs)"])

                callback(true, Array(foundItems.values))
            }
        }
    }

    private static func dsymPath(from metadataItem: NSMetadataItem, withUUID uuid: String) -> String? {
        guard
            let filename = metadataItem.value(forAttribute: kMDItemFSName as String) as? String,
            let itemPath = metadataItem.value(forAttribute: NSMetadataItemPathKey as String) as? String
        else { return nil }

        if isDSYMFilename(filename) {
            return itemPath
        } else if isXCArchiveFilename(filename) {
            guard
                let uuids = metadataItem.value(forAttribute: "com_apple_xcode_dsym_uuids") as? [String],
                let paths = metadataItem.value(forAttribute: "com_apple_xcode_dsym_paths") as? [String]
            else {
                return nil
            }

            if let index = uuids.firstIndex(of: uuid) {
                let path: String?

                if paths.count > index {
                    path = paths[index]
                } else {
                    path = paths.first
                }

                guard
                    let foundPath = path,
                    let relativeDSYMPath = foundPath.components(separatedBy: "/Contents/").first
                else { return nil }

                return [itemPath, relativeDSYMPath].joined(separator: "/")
            } else {
                // This shouldn't happen
                return nil
            }
        } else {
            // What is this?!
            return nil
        }
    }

    private static func isDSYMFilename(_ filename: String) -> Bool {
        NSPredicate(format: "SELF ENDSWITH[c] %@", ".dSYM").evaluate(with: filename)
    }

    private static func isXCArchiveFilename(_ filename: String) -> Bool {
        NSPredicate(format: "SELF ENDSWITH[c] %@", ".xcarchive").evaluate(with: filename)
    }

    private init() {}
}
