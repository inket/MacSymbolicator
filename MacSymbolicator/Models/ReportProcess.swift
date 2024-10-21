//
//  ReportProcess.swift
//  MacSymbolicator
//

import Foundation

public final class ReportProcess {
    let name: String?
    private(set) var architecture: Architecture?
    let binaryImages: [BinaryImage]
    let frames: [StackFrame]

    private static let processSectionRegex = #"^((?:Process|Command):.*?)(?=\z|^(?:Process|Command):)"#
    private static let processNameRegex = #"^(?:Process|Command):\s*(.+?)\s*(?:\[|$)"#

    lazy var dsymRequirements: DSYMRequirements = {
        var recommendedDSYMs = Set<DSYMRequirement>()
        var optionalDSYMs = Set<DSYMRequirement>()
        var systemDSYMs = Set<DSYMRequirement>()

        for frame in frames {
            let requirement = DSYMRequirement(
                targetName: frame.binaryImage.name,
                uuid: frame.binaryImage.uuid
            )

            if frame.binaryImage.isLikelySystem {
                systemDSYMs.insert(requirement)
            } else if frame.symbolicationRecommended {
                recommendedDSYMs.insert(requirement)
            } else {
                optionalDSYMs.insert(requirement)
            }
        }

        return DSYMRequirements(
            recommendedDSYMs: recommendedDSYMs,
            optionalDSYMs: optionalDSYMs,
            systemDSYMs: systemDSYMs
        )
    }()

    static func find(in content: String, targetProcess: String?) -> [ReportProcess] {
        let processSections = content.scan(
            pattern: processSectionRegex,
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        )

        return processSections.compactMap {
            guard let match = $0.first else { return nil }

            let processName = match.scan(pattern: Self.processNameRegex).first?.first

            if let targetProcess {
                if let processName, processName.contains(targetProcess) {
                    return ReportProcess(name: processName, parsing: match)
                } else {
                    return nil
                }
            } else {
                return ReportProcess(name: processName, parsing: match)
            }
        }
    }

    init?(name: String?, parsing content: String) {
        self.name = name
        architecture = Architecture.find(in: content)
        binaryImages = BinaryImage.find(in: content)
        frames = StackFrame.find(
            in: content,
            binaryImageMap: BinaryImageMap(binaryImages: binaryImages)
        )
    }
}
