//
//  BinaryImageMap.swift
//  MacSymbolicator
//

import Foundation

class BinaryImageMap {
    private let nameMap: [String: BinaryImage]
    private let loadAddressMap: [String: BinaryImage]

    init(binaryImages: [BinaryImage]) {
        var nameMap = [String: BinaryImage]()
        var loadAddressMap = [String: BinaryImage]()

        binaryImages.forEach {
            nameMap[$0.name] = $0
            loadAddressMap[$0.loadAddress] = $0
        }

        self.nameMap = nameMap
        self.loadAddressMap = loadAddressMap
    }

    func binaryImage(forName name: String) -> BinaryImage? {
        nameMap[name]
    }

    func binaryImage(forLoadAddress loadAddress: String) -> BinaryImage? {
        loadAddressMap[loadAddress]
    }
}
