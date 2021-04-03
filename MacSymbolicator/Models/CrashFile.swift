//
//  CrashFile.swift
//  MacSymbolicator
//

import Foundation

public struct CrashFile {
    let path: URL
    let filename: String

    var architecture: Architecture?
    var binaryImages: [BinaryImage]
    var calls: [StackTraceCall]

    let content: String
    var symbolicatedContent: String?

    var symbolicatedContentSaveURL: URL {
        let originalPathExtension = path.pathExtension
        let extensionLessPath = path.deletingPathExtension()
        let newFilename = extensionLessPath.lastPathComponent.appending("_symbolicated")
        return extensionLessPath
            .deletingLastPathComponent()
            .appendingPathComponent(newFilename)
            .appendingPathExtension(originalPathExtension)
    }

    public init?(path: URL) {
        guard
            let content = try? String(contentsOf: path, encoding: .utf8),
            content.trimmingCharacters(in: .whitespacesAndNewlines) != ""
        else {
            return nil
        }

        self.content = content

        self.path = path
        self.filename = path.lastPathComponent

        self.architecture = content.scan(pattern: "^Code Type:(.*?)(\\(.*\\))?$").first?.first?.trimmed
            .components(separatedBy: " ").first.flatMap(Architecture.init)

        // In the case of "ARM" the actual architecture is on the first line of Binary Images
        if self.architecture?.isIncomplete == true {
            self.architecture = (content.scan(
                pattern: "Binary Images:.*\\s+([^\\s]+)\\s+<",
                options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
            ).first?.first?.trimmed).flatMap(Architecture.init)
        }

        binaryImages = BinaryImage.find(in: content)
        calls = StackTraceCall.find(in: content)
    }
}
