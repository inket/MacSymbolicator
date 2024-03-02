//
//  DSYMSearch.swift
//  MacSymbolicator
//

import Foundation

struct SearchResult {
    let path: String
    let matchedUUID: String
}

class DSYMSearch {
    private struct ProcessingResult {
        let missingUUIDs: Set<String>
    }

    typealias Callback = (_ finished: Bool, _ results: [SearchResult]?) -> Void
    private static let spotlightSearch = SpotlightSearch()

    private static func processSearchResults(
        _ results: [SearchResult],
        expectedUUIDs: Set<String>,
        logHandler logMessage: @escaping LogHandler,
        callback: @escaping Callback
    ) -> ProcessingResult {
        // Log results and deduplicate them since some DSYMs might be duplicated in other locations.
        var foundItems: [String: SearchResult] = [:]

        for result in results {
            logMessage("Found \(result.matchedUUID): \(result.path)")
            foundItems[result.matchedUUID] = result
        }

        if results.isEmpty {
            logMessage("No results.")
        }

        let foundUUIDs = Set<String>(foundItems.keys)
        let missingUUIDs = expectedUUIDs.subtracting(foundUUIDs)

        callback(missingUUIDs.isEmpty, Array(foundItems.values))

        return ProcessingResult(missingUUIDs: missingUUIDs)
    }

    static func search(
        forUUIDs uuids: [String],
        reportFileDirectory: String,
        logHandler logMessage: @escaping LogHandler,
        callback: @escaping Callback
    ) {
        logMessage("Searching Spotlight for UUIDs: \(uuids)")

        let expectedUUIDs = Set<String>(uuids)

        spotlightSearch.search(forUUIDs: uuids) { results in
            // Processing of results and file searches should be on a background thread to not block main
            DispatchQueue.global().async {
                var processingResult: ProcessingResult

                if let results {
                    processingResult = processSearchResults(
                        results,
                        expectedUUIDs: expectedUUIDs,
                        logHandler: logMessage,
                        callback: callback
                    )
                } else {
                    logMessage("Spotlight query could not be started.")
                    processingResult = ProcessingResult(missingUUIDs: expectedUUIDs)
                }

                // No need to continue if we already found what we're looking for.
                var missingUUIDs = processingResult.missingUUIDs
                guard !missingUUIDs.isEmpty else { return }

                logMessage("Non-recursive file search starting at \(reportFileDirectory) for UUIDs: \(missingUUIDs)")
                let nonRecursiveFileSearchResults = FileSearch
                    .nonRecursive
                    .in(directory: reportFileDirectory)
                    .with(logHandler: logMessage)
                    .search(fileExtension: "dsym").sorted().matching(uuids: Array(missingUUIDs))

                processingResult = processSearchResults(
                    nonRecursiveFileSearchResults,
                    expectedUUIDs: expectedUUIDs,
                    logHandler: logMessage,
                    callback: callback
                )

                // No need to continue if we already found what we're looking for.
                missingUUIDs = processingResult.missingUUIDs
                guard !missingUUIDs.isEmpty else { return }

                logMessage(
                    "Recursive file search starting at ~/Library/Developer/Xcode/Archives/ for UUIDs: \(missingUUIDs)"
                )
                let recursiveFileSearchResults = FileSearch
                    .recursive
                    .in(directory: "~/Library/Developer/Xcode/Archives/")
                    .with(logHandler: logMessage)
                    .search(fileExtension: "dsym").sorted().matching(uuids: Array(missingUUIDs))
                processingResult = processSearchResults(
                    recursiveFileSearchResults,
                    expectedUUIDs: expectedUUIDs,
                    logHandler: logMessage,
                    callback: callback
                )
                missingUUIDs = processingResult.missingUUIDs
                logMessage("Missing UUIDs: \(missingUUIDs)")
            }
        }
    }

    private init() {}
}
