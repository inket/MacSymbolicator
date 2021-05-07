//
//  ScanningTests.swift
//  MacSymbolicatorTests
//

import Foundation
import XCTest
@testable import MacSymbolicator

class ScanningTests: XCTestCase {
    func testScanningUUID() {
        // Valid format
        XCTAssertEqual(
            BinaryUUID("C8ECC43A-6F0F-3880-920A-071973DA584C")?.pretty,
            "C8ECC43A-6F0F-3880-920A-071973DA584C"
        )

        // Dashless format
        XCTAssertEqual(
            BinaryUUID("C8ECC43A6F0F3880920A071973Da584c")?.pretty,
            "C8ECC43A-6F0F-3880-920A-071973DA584C"
        )

        // Contains invalid characters (XXXX)
        XCTAssertNil(BinaryUUID("C8ECC43A-XXXX-3880-920A-071973DA584C"))
        // Wrong format
        XCTAssertNil(BinaryUUID("C8ECC43A6-F0F-3880-920A-071973DA584C"))
    }

    func testScanningBinaryImage() {
        // swiftlint:disable:next line_length
        let defaultRaw = "0x10069d000 -        0x1006a0fff +CrashingInAnotherTargetTest (0) <C8ECC43A-6F0F-3880-920A-071973DA584C> /Users/USER/Desktop/*/CrashingInAnotherTargetTest"

        let mainBinaryImage = BinaryImage(parsingLine: defaultRaw)
        XCTAssertNotNil(mainBinaryImage)
        XCTAssertEqual(mainBinaryImage?.loadAddress, "0x10069d000")
        XCTAssertEqual(mainBinaryImage?.uuid.pretty, "C8ECC43A-6F0F-3880-920A-071973DA584C")

        // swiftlint:disable:next line_length
        let bundleIdentifierRaw = "0x1006b3000 -        0x1006b6ffb +jp.mahdi.AnotherTarget (1.0 - 1) <1D7736DD-062D-3D1A-8DF4-E9EC75908B39> /Users/USER/Desktop/*/AnotherTarget.framework/Versions/A/AnotherTarget"

        let anotherTargetBinaryImage = BinaryImage(parsingLine: bundleIdentifierRaw)
        XCTAssertNotNil(anotherTargetBinaryImage)
        XCTAssertEqual(anotherTargetBinaryImage?.loadAddress, "0x1006b3000")
        XCTAssertEqual(anotherTargetBinaryImage?.uuid.pretty, "1D7736DD-062D-3D1A-8DF4-E9EC75908B39")

        // swiftlint:disable:next line_length
        let iOSRaw = "0x104e0c000 - 0x104e13fff iOSCrashingTest arm64  <69345bdf4b1a33e8becd5d06e30dd596> /var/containers/Bundle/Application/C07E3636-0CA4-4A01-A2B8-82DD0A63BA9D/iOSCrashingTest.app/iOSCrashingTest"
        let iOSBinaryImage = BinaryImage(parsingLine: iOSRaw)
        XCTAssertNotNil(iOSBinaryImage)
        XCTAssertEqual(iOSBinaryImage?.loadAddress, "0x104e0c000")
        XCTAssertEqual(iOSBinaryImage?.uuid.pretty, "69345BDF-4B1A-33E8-BECD-5D06E30DD596")
    }
}
