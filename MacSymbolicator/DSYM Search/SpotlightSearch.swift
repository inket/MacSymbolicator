//
//  SpotlightSearch.swift
//  MacSymbolicator
//

import Foundation

class SpotlightSearch {
    struct SearchResult {
        let item: NSMetadataItem
        let matchedUUID: String
    }

    typealias CompletionHandler = ([SearchResult]?) -> Void

    private var query: NSMetadataQuery?
    private var uuids: [String] = []
    private var completion: CompletionHandler?

    func search(forUUIDs uuids: [String], completion: @escaping CompletionHandler) {
        // Spotlight searches needs to be async, but also cannot be on a background thread since NSMetadataQuery
        // requires the main thread to function.
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

            return SearchResult(item: metadataItem, matchedUUID: uuid)
        } ?? []

        completion?(results)
    }
}
