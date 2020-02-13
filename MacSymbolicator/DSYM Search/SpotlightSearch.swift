//
//  SpotlightSearch.swift
//  MacSymbolicator
//

import Foundation

class SpotlightSearch {
    typealias CompletionHandler = ([NSMetadataItem]?) -> Void

    private var query: NSMetadataQuery?
    private var completion: CompletionHandler?

    func search(forUUID uuid: String, completion: @escaping CompletionHandler) {
        query?.stop()

        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(SpotlightSearch.didFinishGathering),
            name: .NSMetadataQueryDidFinishGathering,
            object: nil
        )

        self.completion = completion

        query = NSMetadataQuery()
        query?.predicate = NSPredicate(format: "com_apple_xcode_dsym_uuids == %@", uuid)

        if query?.start() == false {
            completion(nil)
        }
    }

    @objc
    private func didFinishGathering() {
        query?.stop()
        completion?(query?.results as? [NSMetadataItem])
    }
}
