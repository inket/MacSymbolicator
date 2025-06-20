//
//  BinaryImage.swift
//  MacSymbolicator
//

import Foundation

struct BinaryImage: Equatable, Hashable {
    let name: String
    let uuid: BinaryUUID
    let loadAddress: String

    private static let binaryImagesSectionRegex = #"Binary Images:.*?(?=\n\s*\n|\Z)"#
    private static let binaryImagesLineRegex = #"(0x.*?)\s.*?<(.*?)>.*/(.+)$"#

    static func find(in content: String) -> [BinaryImage] {
        let binaryImagesSection = content.scan(
            pattern: binaryImagesSectionRegex,
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).first?.first

        var binaryImages = [BinaryImage]()
        binaryImagesSection?.enumerateLines(invoking: { line, _ in
            guard let binaryImage = BinaryImage(parsingLine: line) else { return }
            binaryImages.append(binaryImage)
        })
        return binaryImages
    }

    init?(parsingLine line: String) {
        guard let result = line.scan(pattern: Self.binaryImagesLineRegex).first, result.count == 3 else {
            return nil
        }

        name = result[2]
        loadAddress = result[0]

        guard let binaryUUID = BinaryUUID(result[1]) else {
            return nil
        }
        uuid = binaryUUID
    }
}
