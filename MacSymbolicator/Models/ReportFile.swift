//
//  ReportFile.swift
//  MacSymbolicator
//

import Foundation

public class ReportFile {
    enum InitializationError: Error {
        case emptyFile
        case translation(Translator.Error)
        case other(Error)
    }

    let path: URL
    let filename: String
    let processes: [ReportProcess]

    lazy var uuidsForSymbolication: [BinaryUUID] = {
        processes.flatMap { $0.uuidsForSymbolication }
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

    public init(path: URL) throws {
        guard
            let originalContent = try? String(contentsOf: path, encoding: .utf8),
            originalContent.trimmingCharacters(in: .whitespacesAndNewlines) != ""
        else {
            throw InitializationError.emptyFile
        }

        let content: String

        // .ips format is JSON and needs to be translated to the old crash format before symbolicating
        if originalContent.hasPrefix("{") {
            do {
                content = try Translator.translatedCrash(forIPSAt: path)
            } catch {
                if let translationError = error as? Translator.Error {
                    throw InitializationError.translation(translationError)
                } else {
                    throw InitializationError.other(error)
                }
            }
        } else {
            content = originalContent
        }

        self.content = content

        self.path = path
        self.filename = path.lastPathComponent
        self.processes = ReportProcess.find(in: content)
    }
}
