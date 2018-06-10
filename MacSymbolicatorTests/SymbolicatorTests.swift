//
//  SymbolicatorTests.swift
//  MacSymbolicatorTests
//

import Foundation
import XCTest
import MacSymbolicator

class SymbolicatorTests: XCTestCase {
    func testSymbolication() {
        let testBundle = Bundle(for: MacSymbolicatorTests.self)
        let crashReportURL = testBundle.url(forResource: "report", withExtension: "crash")!
        let symbolicatedCrashReportURL = testBundle.url(forResource: "report_symbolicated", withExtension: "crash")!
        let dsymURL = testBundle.url(forResource: "MacSymbolicator", withExtension: "app.dSYM")!

        let crashFile = CrashFile(path: crashReportURL)!
        let dsymFile = DSYMFile(path: dsymURL)

        var symbolicator = Symbolicator(crashFile: crashFile, dsymFile: dsymFile)

        XCTAssert(symbolicator.symbolicate())

        // swiftlint:disable:next force_try
        let symbolicatedContent = try! String(contentsOf: symbolicatedCrashReportURL)

        XCTAssertEqual(symbolicator.symbolicatedContent, symbolicatedContent)
    }
}
