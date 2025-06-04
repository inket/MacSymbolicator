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

    lazy var binariesForSymbolication: [BinaryImage] = {
        let images = processes.flatMap { $0.binariesForSymbolication }
        return Array(Set<BinaryImage>(images))
    }()

    lazy var uuidsForSymbolication: [BinaryUUID] = {
        let uuids = processes.flatMap { $0.uuidsForSymbolication }
        return Array(Set<BinaryUUID>(uuids))
    }()

    let metadata: String?
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

    public init(path: URL, targetProcessName: String? = nil) throws {
        let originalContent: String

        do {
            originalContent = try String(contentsOf: path, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                // Copying and pasting from Help Scout, and possibly other web based systems,
                // leaves unconverted &lt; and &gt; in the content
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
        } catch {
            throw InitializationError.readingFile(error)
        }

        guard !originalContent.isEmpty else {
            throw InitializationError.emptyFile
        }

        let rangeOfFirstLine = originalContent.lineRange(for: ..<originalContent.startIndex)
        let firstLine = String(originalContent[rangeOfFirstLine])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let restOfContents = String(originalContent[rangeOfFirstLine.upperBound..<originalContent.endIndex])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if firstLine.hasPrefix("{") {
            metadata = firstLine
        } else {
            metadata = nil
        }

        if restOfContents.hasPrefix("{") {
            // Contents are likely JSON -> It might be the new .ips format
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
        } else {
            content = originalContent
        }

        processes = ReportProcess.find(in: content, targetProcess: targetProcessName)

        self.path = path
        self.filename = path.lastPathComponent
    }
}
