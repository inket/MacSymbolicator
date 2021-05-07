//
//  CrashFile.swift
//  MacSymbolicator
//

import Foundation

public class CrashFile {
    let path: URL
    let filename: String

    private(set) var architecture: Architecture?
    let binaryImages: [BinaryImage]
    let calls: [StackTraceCall]

    lazy var uuidsForSymbolication: [BinaryUUID] = {
        var images: [String: BinaryImage] = [:]

        calls.forEach { call in
            if images[call.loadAddress] == nil {
                images[call.loadAddress] = binaryImages.first(where: { $0.loadAddress == call.loadAddress })
            }
        }

        return images.values.map { $0.uuid }
    }()

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
