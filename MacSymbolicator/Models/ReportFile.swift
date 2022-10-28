//
//  ReportFile.swift
//  MacSymbolicator
//

import Foundation

public class ReportFile {
    enum InitializationError: Error {
        case readingFile(Error)
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
        let originalContent: String

        do {
            originalContent = try String(contentsOf: path, encoding: .utf8)
        } catch {
            throw InitializationError.readingFile(error)
        }

        guard !originalContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw InitializationError.emptyFile
        }

        var processes = ReportProcess.find(in: originalContent)

        if processes.isEmpty && originalContent.hasPrefix("{") {
            // Could not find any processes defined in the report file -> Probably not the usual crash report format
            // However, the contents might be JSON -> It might be the new .ips format
            // Attempt translation to the old crash format

            do {
                content = try Translator.translatedCrash(forIPSAt: path)
            } catch {
                if let translationError = error as? Translator.Error {
                    throw InitializationError.translation(translationError)
                } else {
                    throw InitializationError.other(error)
                }
            }

            processes = ReportProcess.find(in: content)
        } else {
            self.content = originalContent
        }

        self.path = path
        self.filename = path.lastPathComponent
        self.processes = processes
    }
}
