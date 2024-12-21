//
//  BinaryImage.swift
//  MacSymbolicator
//

import Foundation

struct BinaryImage: Equatable, Hashable {
    let name: String
    let path: String
    let uuid: BinaryUUID
    let loadAddress: String

    var isLikelySystem: Bool {
        path.hasPrefix("/System/") ||
        path.hasPrefix("/usr/") ||
        path.hasPrefix("/Library/") ||
        path.hasPrefix("/bin/") ||
        path.hasPrefix("/sbin/")
    }

    private static let binaryImagesSectionRegex = #"Binary Images:.*"#
    private static let binaryImagesLineRegex = #"(0x.*?)\s.*?<(.*?)>\s+(.*/(.+))$"#

    static func find(in content: String) -> [BinaryImage] {
        let binaryImagesSection = content.scan(
            pattern: binaryImagesSectionRegex,
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).first?.first

        var binaryImages = [BinaryImage]()
        binaryImagesSection?.text.enumerateLines(invoking: { line, _ in
            guard let binaryImage = BinaryImage(parsingLine: line) else { return }
            binaryImages.append(binaryImage)
        })
        return binaryImages
    }

    init?(parsingLine line: String) {
        guard let result = line.scan(pattern: Self.binaryImagesLineRegex).first, result.count == 4 else {
            return nil
        }

        name = result[3].text
        path = result[2].text
        loadAddress = result[0].text

        guard let binaryUUID = BinaryUUID(result[1].text, architecture: nil) else {
            return nil
        }
        uuid = binaryUUID
    }
}
