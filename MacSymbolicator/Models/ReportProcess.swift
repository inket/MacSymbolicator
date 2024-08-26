//
//  ReportProcess.swift
//  MacSymbolicator
//

import Foundation

public class ReportProcess {
    let name: String?
    private(set) var architecture: Architecture?
    let binaryImages: [BinaryImage]
    let frames: [StackFrame]

    private static let processSectionRegex = #"^(Process:.*?)(?=\z|^Process:)"#
    private static let processNameRegex = #"^Process:\s*(.+?)\s*\["#

    lazy var binariesForSymbolication: [BinaryImage] = {
        let uuids = frames.map { $0.binaryImage }
        return Array(Set<BinaryImage>(uuids))
    }()

    lazy var uuidsForSymbolication: [BinaryUUID] = {
        let uuids = frames.map { $0.binaryImage.uuid }
        return Array(Set<BinaryUUID>(uuids))
    }()

    static func find(in content: String, targetProcess: String?) -> [ReportProcess] {
        let processSections = content.scan(
            pattern: processSectionRegex,
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        )

        return processSections.compactMap {
            guard let match = $0.first else { return nil }
            return ReportProcess(parsing: match, targetProcess: targetProcess)
        }
    }

    init?(parsing content: String, targetProcess: String?) {
        name = content.scan(pattern: Self.processNameRegex).first?.first
        if (name == nil) {
            return nil;
        }
        if (!(targetProcess ?? "").isEmpty) {
            if (!name!.contains(targetProcess!)) {
                return nil;
            }
        }
        architecture = Architecture.find(in: content)
        binaryImages = BinaryImage.find(in: content)
        frames = StackFrame.find(
            in: content,
            binaryImageMap: BinaryImageMap(binaryImages: binaryImages)
        )
    }
}
