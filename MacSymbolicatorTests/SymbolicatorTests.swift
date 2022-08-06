//
//  SymbolicatorTests.swift
//  MacSymbolicatorTests
//

// swiftlint:disable force_try

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
    private var testBundle: Bundle {
        return Bundle(for: MacSymbolicatorTests.self)
    }

    private func testSymbolication(testFile: TestFile, dsymFiles: [DSYMFile]) {
        let crashFile = try! CrashFile(path: testFile.originalURL)

        var symbolicator = Symbolicator(
            crashFile: crashFile,
            dsymFiles: dsymFiles,
            logController: DefaultLogController()
        )

        XCTAssert(symbolicator.symbolicate())
        let result = symbolicator.symbolicatedContent

        try! (result ?? "").write(to: testFile.resultURL, atomically: true, encoding: .utf8)

        let expectedContent = try! String(contentsOf: testFile.expectationURL)

        XCTAssertEqual(result, expectedContent)
        XCTAssertNotEqual(symbolicator.symbolicatedContent, crashFile.content)
    }

    func testSingleTargetCrashSymbolication() {
        let dsymFile = DSYMFile(
            path: testBundle.url(forResource: "dSYMs/CrashingTest", withExtension: "dSYM")!
        )!

        testSymbolication(testFile: TestFile(path: "Crashes/single-target-crash.ips"), dsymFiles: [dsymFile])
        testSymbolication(testFile: TestFile(path: "Crashes/single-target-crash.crash"), dsymFiles: [dsymFile])
    }

    func testMultiTargetCrashSymbolication() {
        let dsymFiles = [
            DSYMFile(path: testBundle.url(forResource: "dSYMs/CrashingInAnotherTargetTest", withExtension: "dSYM")!)!,
            DSYMFile(path: testBundle.url(forResource: "dSYMs/AnotherTarget.framework", withExtension: "dSYM")!)!
        ]

        testSymbolication(testFile: TestFile(path: "Crashes/multi-target-crash.ips"), dsymFiles: dsymFiles)
        testSymbolication(testFile: TestFile(path: "Crashes/multi-target-crash.crash"), dsymFiles: dsymFiles)
    }

    func testSingleThreadSampleSymbolication() {
        let dsymFile = DSYMFile(
            path: testBundle.url(forResource: "dSYMs/SingleThreadHangingTest", withExtension: "dSYM")!
        )!

        testSymbolication(testFile: TestFile(path: "Samples/singlethread-sample.txt"), dsymFiles: [dsymFile])
    }

    func testMultiThreadSampleSymbolication() {
        let dsymFile = DSYMFile(
            path: testBundle.url(forResource: "dSYMs/MultiThreadHangingTest", withExtension: "dSYM")!
        )!

        testSymbolication(testFile: TestFile(path: "Samples/multithread-sample.txt"), dsymFiles: [dsymFile])
    }

    func testiOSSymbolication() {
        let dsymFile = DSYMFile(path: testBundle.url(forResource: "dSYMs/iOSCrashingTest.app", withExtension: "dSYM")!)!

        testSymbolication(testFile: TestFile(path: "Crashes/ios-crash.ips"), dsymFiles: [dsymFile])
        testSymbolication(testFile: TestFile(path: "Crashes/ios-crash.crash"), dsymFiles: [dsymFile])
    }
}
