//
//  SymbolStoreSearch.swift
//  MacSymbolicator
//

import Foundation

class SymbolStoreSearch {

    typealias CompletionHandler = ([SearchResult]?, Bool) -> Void

    private static let guidRegex = #"(....)(....)-(....)-(....)-(....)-(............)"#

    func search(
        forUUIDs uuids: Set<String>,
        logHandler logMessage: @escaping LogHandler,
        completion: @escaping CompletionHandler
    ) {
        DispatchQueue.global().async {
            let missingUUIDs = self.mappedPathsSearch(forUUIDs: uuids, logHandler: logMessage, completion: completion)
            self.shellCommandSearch(forUUIDs: missingUUIDs, logHandler: logMessage, completion: completion)
        }
    }

    private static func mappedPathList(suiteName: String?) -> [String] {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return [] }

        // This can be either a string or array of strings
        guard let mappedPaths = defaults.stringArray(forKey: "DBGFileMappedPaths") else {
            guard let mappedPathString = defaults.string(forKey: "DBGFileMappedPaths") else { return [] }
            return [mappedPathString]
        }

        return mappedPaths
    }

    private static func shellCommandList(suiteName: String?) -> [String] {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return [] }

        // This can be either a string or array of strings
        guard let mappedPaths = defaults.stringArray(forKey: "DBGShellCommands") else {
            guard let mappedPathString = defaults.string(forKey: "DBGShellCommands") else { return [] }
            return [mappedPathString]
        }

        return mappedPaths
    }

    private static func pathUUIDs(path: String) -> [String]? {
        let command = "dwarfdump --uuid \"\(path)\""
        let commandResult = command.run()

        if let errorOutput = commandResult.error?.trimmed, !errorOutput.isEmpty {
            // dwarfdump --uuid on /Users/x/Library/Developer/Xcode/Archives seems to output the dsym identifier
            // correctly followed by an stderr message about not being able to open macho file due to
            // "Too many levels of symbolic links". Seems safe to ignore.
            if !errorOutput.contains("Too many levels of symbolic links") {
                return nil
            }
        }

        guard let dwarfDumpOutput = commandResult.output?.trimmed else { return nil }

        let foundUUIDs = dwarfDumpOutput.scan(pattern: #"UUID: (.*) \("#).flatMap({ $0 })
        return foundUUIDs
    }

    private func mappedPathsSearch(
        forUUIDs uuids: Set<String>,
        logHandler logMessage: @escaping LogHandler,
        completion: @escaping CompletionHandler
    ) -> Set<String> {
        let mappedPaths = SymbolStoreSearch.mappedPathList(suiteName: "com.apple.DebugSymbols") + SymbolStoreSearch.mappedPathList(suiteName: nil)

        var results: [SearchResult] = []

        for uuid in uuids {
            // Need to convert UUID from AAAABBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF
            // into AAAA/BBBB/CCCC/DDDD/EEEE/FFFFFFFFFFFF
            let subPath = uuid.scan(pattern: SymbolStoreSearch.guidRegex)[0]

            for mappedPath in mappedPaths {
                // There's gotta be a better way to do this
                var path = URL(fileURLWithPath: mappedPath)
                for sub in subPath {
                    path.appendPathComponent(sub)
                }

                // If the file exists and is a dwarf file matching, accept it
                if FileManager().fileExists(atPath: path.path) {
                    if let pathUUIDs = SymbolStoreSearch.pathUUIDs(path: path.path) {
                        if pathUUIDs.contains(uuid) {
                            results.append(SearchResult(path: path.path, matchedUUID: uuid))
                        }
                    }
                }
            }
        }

        completion(results, false)

        return uuids.subtracting(results.map({ result in result.matchedUUID }))
    }

    private func shellCommandSearch(
        forUUIDs uuids: Set<String>,
        logHandler logMessage: @escaping LogHandler,
        completion: @escaping CompletionHandler
    ) {
        // Search through mapped paths
        let shellCommands = SymbolStoreSearch.shellCommandList(suiteName: "com.apple.DebugSymbols") + SymbolStoreSearch.shellCommandList(suiteName: nil)

        var results: [SearchResult] = []

        // TODO: parallelize
        for uuid in uuids {
            for command in shellCommands {
                // $(command uuid) returns us an XML document with the path to the dYSM or with an error
                /*
                 <?xml version="1.0" encoding="UTF-8"?>
                 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                 <plist version="1.0">
                 <dict>
                     <key>4E793E15-4672-3387-9EA0-C1701F5C59CA</key>
                     <dict>
                         <key>DBGDSYMPath</key>
                         <string>/Users/x/Library/SymbolCache/dsyms/4E79/3E15/4672/3387/9EA0/C1701F5C59CA</string>
                     </dict>
                 </dict>
                 </plist>
                 */

                // Try to parse output
                logMessage("Run script: \(command) \(uuid)")
                guard let scriptOutput = "\(command) \(uuid)".run().output else { continue }

                logMessage("==> \(scriptOutput)")

                guard let data = scriptOutput.data(using: .utf8) else { continue }
                guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { continue }

                // If the plist has our guid as a key then see what results it has
                guard let value = plist[uuid] as? [String: Any] else { continue }
                guard let dsymPath = value["DBGDSYMPath"] as? String else { continue }

                // If the file exists and is a dwarf file matching, accept it
                if FileManager().fileExists(atPath: dsymPath) {
                    if let pathUUIDs = SymbolStoreSearch.pathUUIDs(path: dsymPath) {
                        if pathUUIDs.contains(uuid) {
                            results.append(SearchResult(path: dsymPath, matchedUUID: uuid))
                            // Run the completion handler after each search so we can see results as they arrive
                            completion(results, false)
                        }
                    }
                }
            }
        }
        completion(results, true)
    }
}
