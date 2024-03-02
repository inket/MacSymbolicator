//
//  SpotlightSearch.swift
//  MacSymbolicator
//

import Foundation

class SpotlightSearch {
    typealias CompletionHandler = ([SearchResult]?) -> Void

    private var query: NSMetadataQuery?
    private var uuids: [String] = []
    private var completion: CompletionHandler?

    func search(forUUIDs uuids: [String], completion: @escaping CompletionHandler) {
        // Spotlight searches are async and their status needs to be observed, but also cannot be on a background thread
        // since NSMetadataQuery requires the main thread to function.
        DispatchQueue.main.async {
            self.mainSearch(forUUIDs: uuids, completion: completion)
        }
    }

    private func mainSearch(forUUIDs uuids: [String], completion: @escaping CompletionHandler) {
        query?.stop()

        self.uuids = uuids

        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(SpotlightSearch.didFinishGathering),
            name: .NSMetadataQueryDidFinishGathering,
            object: nil
        )

        self.completion = completion

        let subpredicates = uuids.map { NSPredicate(format: "com_apple_xcode_dsym_uuids == %@", $0) }

        query = NSMetadataQuery()
        if subpredicates.count == 1, let onlyPredicate = subpredicates.first {
            query?.predicate = onlyPredicate
        } else {
            query?.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: subpredicates)
        }

        if query?.start() == false {
            completion(nil)
        }
    }

    @objc
    private func didFinishGathering() {
        query?.stop()

        let results: [SearchResult] = (query?.results as? [NSMetadataItem])?.compactMap { metadataItem in
            let foundUUIDs = metadataItem.value(forAttribute: "com_apple_xcode_dsym_uuids") as? [String]
            let searchUUIDs = self.uuids

            let matchedUUID = foundUUIDs?.first(where: { foundUUID in searchUUIDs.contains(foundUUID) })

            guard let uuid = matchedUUID else { return nil }

            guard let path = SpotlightSearch.dsymPath(from: metadataItem, withUUID: uuid) else {
                return nil
            }

            return SearchResult(path: path, matchedUUID: uuid)
        } ?? []

        completion?(results)
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
