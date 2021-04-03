//
//  SymbolicatorTests.swift
//  MacSymbolicatorTests
//

import Foundation
import XCTest
@testable import MacSymbolicator

class TestFile {
    let originalURL: URL
    let expectationURL: URL

    var resultURL: URL {
        URL(string: expectationURL.absoluteString.replacingOccurrences(of: "_symbolicated", with: "_result"))!
    }

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
        expectationURL = testBundle.url(
            forResource: [directory, expectationFilename].joined(separator: "/"),
            withExtension: pathExtension
        )!
    }
}

class SymbolicatorTests: XCTestCase {
    func testSingleTargetCrashSymbolication() {
        let testBundle = Bundle(for: MacSymbolicatorTests.self)
        let testFile = TestFile(path: "Crashes/single-target-crash.crash")
        let dsymFile = DSYMFile(
            path: testBundle.url(forResource: "dSYMs/CrashingTest", withExtension: "dSYM")!
        )

        let crashFile = CrashFile(path: testFile.originalURL)!

        var symbolicator = Symbolicator(crashFile: crashFile, dsymFiles: [dsymFile])

        XCTAssert(symbolicator.symbolicate())
        let result = symbolicator.symbolicatedContent

        // swiftlint:disable:next force_try
        try! (result ?? "").write(to: testFile.resultURL, atomically: true, encoding: .utf8)

        // swiftlint:disable:next force_try
        let expectedContent = try! String(contentsOf: testFile.expectationURL)

        XCTAssertEqual(result, expectedContent)
        XCTAssertNotEqual(symbolicator.symbolicatedContent, crashFile.content)
    }

    func testMultiTargetCrashSymbolication() {
        let testBundle = Bundle(for: MacSymbolicatorTests.self)
        let testFile = TestFile(path: "Crashes/multi-target-crash.crash")
        let dsymFiles = [
            DSYMFile(path: testBundle.url(forResource: "dSYMs/CrashingInAnotherTargetTest", withExtension: "dSYM")!),
            DSYMFile(path: testBundle.url(forResource: "dSYMs/AnotherTarget.framework", withExtension: "dSYM")!)
        ]

        let crashFile = CrashFile(path: testFile.originalURL)!

        var symbolicator = Symbolicator(crashFile: crashFile, dsymFiles: dsymFiles)

        XCTAssert(symbolicator.symbolicate())
        let result = symbolicator.symbolicatedContent

        // swiftlint:disable:next force_try
        try! (result ?? "").write(to: testFile.resultURL, atomically: true, encoding: .utf8)

        // swiftlint:disable:next force_try
        let expectedContent = try! String(contentsOf: testFile.expectationURL)

        XCTAssertEqual(result, expectedContent)
        XCTAssertNotEqual(symbolicator.symbolicatedContent, crashFile.content)
    }

    func testSingleThreadSampleSymbolication() {
        let testBundle = Bundle(for: MacSymbolicatorTests.self)
        let testFile = TestFile(path: "Samples/singlethread-sample.txt")
        let dsymFile = DSYMFile(
            path: testBundle.url(forResource: "dSYMs/SingleThreadHangingTest", withExtension: "dSYM")!
        )

        let crashFile = CrashFile(path: testFile.originalURL)!

        var symbolicator = Symbolicator(crashFile: crashFile, dsymFiles: [dsymFile])

        XCTAssert(symbolicator.symbolicate())
        let result = symbolicator.symbolicatedContent

        // swiftlint:disable:next force_try
        try! (result ?? "").write(to: testFile.resultURL, atomically: true, encoding: .utf8)

        // swiftlint:disable:next force_try
        let expectedContent = try! String(contentsOf: testFile.expectationURL)

        XCTAssertEqual(result, expectedContent)
        XCTAssertNotEqual(symbolicator.symbolicatedContent, crashFile.content)
    }

    func testMultiThreadSampleSymbolication() {
        let testBundle = Bundle(for: MacSymbolicatorTests.self)
        let testFile = TestFile(path: "Samples/multithread-sample.txt")
        let dsymFile = DSYMFile(
            path: testBundle.url(forResource: "dSYMs/MultiThreadHangingTest", withExtension: "dSYM")!
        )

        let crashFile = CrashFile(path: testFile.originalURL)!

        var symbolicator = Symbolicator(crashFile: crashFile, dsymFiles: [dsymFile])

        XCTAssert(symbolicator.symbolicate())
        let result = symbolicator.symbolicatedContent

        // swiftlint:disable:next force_try
        try! (result ?? "").write(to: testFile.resultURL, atomically: true, encoding: .utf8)

        // swiftlint:disable:next force_try
        let expectedContent = try! String(contentsOf: testFile.expectationURL)

        XCTAssertEqual(result, expectedContent)
        XCTAssertNotEqual(symbolicator.symbolicatedContent, crashFile.content)
    }

    func testiOSSymbolication() {
        let testBundle = Bundle(for: MacSymbolicatorTests.self)
        let testFile = TestFile(path: "Crashes/ios-crash.crash")
        let dsymFile = DSYMFile(path: testBundle.url(forResource: "dSYMs/iOSCrashingTest.app", withExtension: "dSYM")!)

        let crashFile = CrashFile(path: testFile.originalURL)!

        var symbolicator = Symbolicator(crashFile: crashFile, dsymFiles: [dsymFile])

        XCTAssert(symbolicator.symbolicate())
        let result = symbolicator.symbolicatedContent

        // swiftlint:disable:next force_try
        try! (result ?? "").write(to: testFile.resultURL, atomically: true, encoding: .utf8)

        // swiftlint:disable:next force_try
        let expectedContent = try! String(contentsOf: testFile.expectationURL)

        XCTAssertEqual(result, expectedContent)
        XCTAssertNotEqual(symbolicator.symbolicatedContent, crashFile.content)
    }
}
