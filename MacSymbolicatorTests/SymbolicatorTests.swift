//
//  SymbolicatorTests.swift
//  MacSymbolicatorTests
//

// swiftlint:disable force_try force_unwrapping

import Foundation
import XCTest
@testable import MacSymbolicator

class SymbolicatorTests: XCTestCase {
    private var testBundle: Bundle {
        return Bundle(for: MacSymbolicatorTests.self)
    }

    private func testSymbolication(testFile: TestFile, dsymFiles: [DSYMFile]) {
        let reportFile = try! ReportFile(path: testFile.originalURL)

        var symbolicator = Symbolicator(
            reportFile: reportFile,
            dsymFiles: dsymFiles,
            logController: DefaultLogController()
        )

        XCTAssert(symbolicator.symbolicate())
        let result = symbolicator.symbolicatedContent

        // Write to file for debugging when tests fail
        try! (result ?? "").write(to: testFile.resultURL, atomically: true, encoding: .utf8)

        XCTAssertEqual(result, testFile.expectationFile!.content)
        XCTAssertNotEqual(symbolicator.symbolicatedContent, reportFile.content)
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

    func testMultiTargetSampleSymbolication() {
        let dsymFiles = [
            DSYMFile(path: testBundle.url(forResource: "dSYMs/MultiTargetHangingTest", withExtension: "dSYM")!)!,
            DSYMFile(path: testBundle.url(forResource: "dSYMs/AnotherTarget.framework", withExtension: "dSYM")!)!
        ]

        testSymbolication(testFile: TestFile(path: "Samples/multitarget-sample.txt"), dsymFiles: dsymFiles)
    }

    func testiOSSymbolication() {
        let dsymFile = DSYMFile(path: testBundle.url(forResource: "dSYMs/iOSCrashingTest.app", withExtension: "dSYM")!)!

        testSymbolication(testFile: TestFile(path: "Crashes/ios-crash.ips"), dsymFiles: [dsymFile])
        testSymbolication(testFile: TestFile(path: "Crashes/ios-crash.crash"), dsymFiles: [dsymFile])
    }
}
