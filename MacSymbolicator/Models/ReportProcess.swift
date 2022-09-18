//
//  ReportProcess.swift
//  MacSymbolicator
//

import Foundation

public class ReportProcess {
    let name: String?
    private(set) var architecture: Architecture?
    let binaryImages: [BinaryImage]
    let calls: [StackTraceCall]

    private static let processSectionRegex = #"^(Process:.*?)(?=\z|^Process:)"#
    private static let processNameRegex = #"^Process:\s*(.+?)\s*\["#

    lazy var uuidsForSymbolication: [BinaryUUID] = {
        var images: [String: BinaryImage] = [:]

        calls.forEach { call in
            if images[call.loadAddress] == nil {
                images[call.loadAddress] = binaryImages.first(where: { $0.loadAddress == call.loadAddress })
            }
        }

        return images.values.map { $0.uuid }
    }()

    static func find(in content: String) -> [ReportProcess] {
        let processSections = content.scan(
            pattern: processSectionRegex,
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        )

        return processSections.compactMap {
            guard let match = $0.first else { return nil }
            return ReportProcess(parsing: match)
        }
    }

    init?(parsing content: String) {
        name = content.scan(pattern: Self.processNameRegex).first?.first
        architecture = Architecture.find(in: content)
        binaryImages = BinaryImage.find(in: content)

        let loadAddresses = [String: String].init(
            binaryImages.map({ ($0.name, $0.loadAddress) }),
            uniquingKeysWith: { one, _ in one }
        )
        calls = StackTraceCall.find(in: content, withLoadAddresses: loadAddresses)
    }
}
