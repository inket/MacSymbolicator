//
//  SymbolicatorTests.swift
//  MacSymbolicatorTests
//

import Foundation
import XCTest
@testable import MacSymbolicator

class SymbolicatorTests: XCTestCase {
    func testSymbolication() {
        let testBundle = Bundle(for: MacSymbolicatorTests.self)

        let combinations: [(URL, URL)] = [
            (
                testBundle.url(forResource: "report", withExtension: "crash")!,
                testBundle.url(forResource: "report_symbolicated", withExtension: "crash")!
            ),
            (
                testBundle.url(forResource: "singlethread-sample", withExtension: "txt")!,
                testBundle.url(forResource: "singlethread-sample_symbolicated", withExtension: "txt")!
            ),
            (
                testBundle.url(forResource: "multithread-sample", withExtension: "txt")!,
                testBundle.url(forResource: "multithread-sample_symbolicated", withExtension: "txt")!
            )
        ]

        let dsymURL = testBundle.url(forResource: "CrashingAndHangingTest", withExtension: "dSYM")!
        let dsymFile = DSYMFile(path: dsymURL)

        combinations.forEach { combination in
            let (beforeSymbolicationURL, afterSymbolicationURL) = combination
            let crashFile = CrashFile(path: beforeSymbolicationURL)!

            var symbolicator = Symbolicator(crashFile: crashFile, dsymFile: dsymFile)

            XCTAssert(symbolicator.symbolicate())

            // swiftlint:disable:next force_try
            let symbolicatedContent = try! String(contentsOf: afterSymbolicationURL)

            XCTAssertEqual(symbolicator.symbolicatedContent, symbolicatedContent)
            XCTAssertNotEqual(symbolicator.symbolicatedContent, crashFile.content)
        }
    }
}
