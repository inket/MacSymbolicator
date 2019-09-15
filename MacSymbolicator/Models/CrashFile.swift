//
//  CrashFile.swift
//  MacSymbolicator
//

import Foundation

public struct CrashFile {
    let path: URL
    let filename: String
    var processName: String?
    var responsible: String?
    var bundleIdentifier: String?
    var architecture: String?
    var loadAddress: String?
    var addresses: [String]?
    var version: String?
    var buildVersion: String?
    var uuid: String?

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
        self.processName = content.scan(pattern: "^Process:\\s+(.+?)\\[").first?.first?.trimmed
        self.bundleIdentifier = content.scan(pattern: "^Identifier:\\s+(.+?)$").first?.first?.trimmed
        self.architecture = content.scan(pattern: "^Code Type:(.*?)(\\(.*\\))?$").first?.first?.trimmed
                                   .components(separatedBy: " ").first

        self.loadAddress = content.scan(
            pattern: "Binary Images:.*?(0x.*?)\\s",
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).first?.first?.trimmed

        let crashReportAddresses = content.scan(
            pattern: "^\\d+\\s+(\(bundleIdentifier ?? "")|\(processName ?? "")).*?(0x.*?)\\s",
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).compactMap { $0.last }

        let sampleAddresses = content.scan(
            pattern: "\\?{3}\\s+\\(in\\s.*?\\)\\s+load\\saddress.*?\\[(0x.*?)\\]",
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).compactMap { $0.last }

        self.addresses = crashReportAddresses + sampleAddresses

        self.responsible = content.scan(pattern: "^Responsible:\\s+(.+?)\\[").first?.first?.trimmed
        self.version = content.scan(pattern: "^Version:\\s+(.+?)\\(").first?.first?.trimmed
        self.buildVersion = content.scan(pattern: "^Version:.+\\((.*?)\\)").first?.first?.trimmed

        self.uuid = content.scan(
            pattern: "Binary Images:.*?<(.*?)>",
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).first?.first?.trimmed
    }
}
