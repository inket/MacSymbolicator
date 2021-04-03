//
//  BinaryImage.swift
//  MacSymbolicator
//

import Foundation

struct BinaryImage {
    let uuid: BinaryUUID
    let loadAddress: String

    private static let binaryImagesSectionRegex = "Binary Images:.*"
    private static let binaryImagesLineRegex = "(0x.*?)\\s.*?<(.*?)>"

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
        guard let result = line.scan(pattern: Self.binaryImagesLineRegex).first, result.count == 2 else {
            return nil
        }

        loadAddress = result[0]

        guard let binaryUUID = BinaryUUID(result[1]) else {
            return nil
        }
        uuid = binaryUUID
    }
}
