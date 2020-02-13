//
//  DSYMSearch.swift
//  MacSymbolicator
//

import Foundation

class DSYMSearch {
    typealias CompletionHandler = (String?) -> Void
    private static let spotlightSearch = SpotlightSearch()

    static func search(
        forUUID uuid: String,
        crashFileDirectory: String,
        fileSearchErrorHandler: @escaping FileSearchErrorHandler,
        completion: @escaping CompletionHandler
    ) {
        spotlightSearch.search(forUUID: uuid) { results in
            let foundItem = results?.first { metadataItem in
                guard let dsymPath = dsymPath(from: metadataItem, withUUID: uuid) else { return false }

                completion(dsymPath)
                return true
            }

            // No need to continue if we already found what we're looking for.
            guard foundItem == nil else { return }

            completion(
                FileSearch.nonRecursive.in(directory: crashFileDirectory)
                    .with(errorHandler: fileSearchErrorHandler)
                    .search(fileExtension: "dsym").sorted().firstMatching(uuid: uuid) ??
                FileSearch.recursive.in(directory: "~/Library/Developer/Xcode/Archives/")
                    .with(errorHandler: fileSearchErrorHandler)
                    .search(fileExtension: "dsym").sorted().firstMatching(uuid: uuid)
            )
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
}
