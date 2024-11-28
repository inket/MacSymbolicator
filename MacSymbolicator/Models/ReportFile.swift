//
//  ReportFile.swift
//  MacSymbolicator
//

import Foundation
import Combine

actor LazyAsync<T: Sendable> {
    private var value: T?
    private let closure: () async -> T

    init(_ closure: @escaping () async -> T) {
        self.closure = closure
    }

    func get() async -> T {
        if let value {
            return value
        } else {
            self.value = await closure()
            return await get()
        }
    }
}

public final class ReportFile {
    enum InitializationError: Error {
        case readingFile(Error)
        case emptyFile
        case translation(Translator.Error)
        case other(Error)
    }

    let path: URL
    let filename: String
    let targetProcessName: String?

    private(set) lazy var lazyProcesses: LazyAsync<[ReportProcess]> = LazyAsync { [weak self] in
        guard let self else { return [] }
        return ReportProcess.find(
            in: self.content,
            targetProcess: self.targetProcessName
        )
    }
    var processes: [ReportProcess] {
        get async {
            await lazyProcesses.get()
        }
    }

    private(set) lazy var lazyDSYMRequirements: LazyAsync<DSYMRequirements> = LazyAsync { [weak self] in
        guard let self else { return DSYMRequirements(combining: []) }
        return await DSYMRequirements(combining: self.processes.map { $0.dsymRequirements })
    }
    var dsymRequirements: DSYMRequirements {
        get async {
            await lazyDSYMRequirements.get()
        }
    }

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

        self.path = path
        self.filename = path.lastPathComponent
        self.targetProcessName = targetProcessName
    }

    func load() async {
        _ = await processes
        _ = await dsymRequirements
    }
}
