//
//  TestFile.swift
//  MacSymbolicatorTests
//

// swiftlint:disable force_unwrapping force_try

import Foundation

class TestFile {
    let originalURL: URL
    let expectationFile: ExpectationFile?
    let resultURL: URL

    init(path: String) {
        let testBundle = Bundle(for: MacSymbolicatorTests.self)

        let pathExtension = (path as NSString).pathExtension
        let originalFilename = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        let expectationFilename = "\(originalFilename)_symbolicated"
        let directory = (path as NSString).deletingLastPathComponent

        originalURL = testBundle.url(
            forResource: [directory, originalFilename].joined(separator: "/"),
            withExtension: pathExtension
        )!

        let expectationFileURL = testBundle.url(
            forResource: [directory, expectationFilename].joined(separator: "/"),
            withExtension: pathExtension
        )
        expectationFile = expectationFileURL.flatMap { ExpectationFile(url: $0) }

        resultURL = URL(string: originalURL.absoluteString.replacingOccurrences(of: "_symbolicated", with: "_result"))!
    }
}

class ExpectationFile {
    let url: URL

    var content: String {
        try! String(contentsOf: url)
    }

    init?(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        self.url = url
    }
}
