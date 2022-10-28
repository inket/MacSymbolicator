//
//  ReportFileTests.swift
//  MacSymbolicatorTests
//

// swiftlint:disable force_try

import Foundation
import XCTest
@testable import MacSymbolicator

class ReportFileTests: XCTestCase {
    let rawProcessesFile = TestFile(path: "Other/raw-processes.txt")
    let iOSCrashWithoutJSONHeaderFile = TestFile(path: "Other/ios-crash-without-json-header.crash")
    let iOSCrashWithJSONHeaderFile = TestFile(path: "Other/ios-crash-with-json-header.crash")
    let iOSCrashInIPSFormatFile = TestFile(path: "Other/ios-crash-in-ips-format.ips")

    func testParsingProcessesOnAFileWithoutHeaders() {
        let processes = (try! ReportFile(path: rawProcessesFile.originalURL)).processes
        XCTAssertEqual(processes.count, 5)
        XCTAssertEqual(processes[0].name, "adid")
        XCTAssertEqual(processes[1].name, "AirPlayXPCHelper")
        XCTAssertEqual(processes[2].name, "distnoted")
        XCTAssertEqual(processes[3].name, "distnoted")
        XCTAssertEqual(processes[4].name, "distnoted")
    }

    func testParsingProcessesOnARegularCrashReport() {
        let processes = (try! ReportFile(path: iOSCrashWithoutJSONHeaderFile.originalURL)).processes
        XCTAssertEqual(processes.count, 1)
        XCTAssertEqual(processes[0].name, "iOSCrashingTest")
    }

    func testParsingProcessesOnARegularCrashReportWithJSONHeader() {
        let processes = (try! ReportFile(path: iOSCrashWithJSONHeaderFile.originalURL)).processes
        XCTAssertEqual(processes.count, 1)
        XCTAssertEqual(processes[0].name, "iOSCrashingTest")
    }

    func testParsingProcessesOnAnIPSCrashReport() {
        // Gets translated from IPS to crash, and the processes are parsed correctly
        let processes = (try! ReportFile(path: iOSCrashInIPSFormatFile.originalURL)).processes
        XCTAssertEqual(processes.count, 1)
        XCTAssertEqual(processes[0].name, "iOSCrashingTest")
    }
}
