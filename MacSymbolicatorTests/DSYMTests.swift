//
//  DSYMTests.swift
//  MacSymbolicatorTests
//

import XCTest
@testable import MacSymbolicator

class DSYMTests: XCTestCase {
    func testDetectingEmbeddedDSYMs() {
        let testBundle = Bundle(for: MacSymbolicatorTests.self)
        let dsymFiles = DSYMFile.dsymFiles(
            from: testBundle.url(forResource: "dSYMs/Embedded.app", withExtension: "dSYM")!
        )

        XCTAssertEqual(dsymFiles.count, 2)

        let appDSYMFile = DSYMFile(
            path: testBundle.url(forResource: "dSYMs/Embedded.app.dSYM/DSYM Example.app", withExtension: "dSYM")!
        )!
        XCTAssertEqual(
            appDSYMFile,
            dsymFiles.first(where: { $0.filename == "DSYM Example.app.dSYM" })
        )

        let frameworkDSYMFile = DSYMFile(
            path: testBundle.url(forResource: "dSYMs/Embedded.app.dSYM/Framework_1.framework", withExtension: "dSYM")!
        )!
        XCTAssertEqual(
            frameworkDSYMFile,
            dsymFiles.first(where: { $0.filename == "Framework_1.framework.dSYM" })
        )
    }
}
