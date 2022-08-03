//
//  LogController.swift
//  MacSymbolicator
//

import Cocoa

@objc
protocol LogControllerDelegate: AnyObject {
    func logController(_ controller: LogController, logsUpdated logMessages: [String])
}

@objc
protocol LogController: AnyObject {
    var delegate: LogControllerDelegate? { get set }

    var logMessages: [String] { get set }

    func addLogMessage(_ message: String)
    func addLogMessages(_ newMessages: [String])
    func merge(_ logController: LogController)
    func resetLogs()
}

class DefaultLogController: NSObject, LogController {
    weak var delegate: LogControllerDelegate?

    var logMessages = [String]() {
        didSet {
            delegate?.logController(self, logsUpdated: logMessages)
        }
    }

    func addLogMessage(_ message: String) {
        logMessages.append(message)
    }

    func addLogMessages(_ newMessages: [String]) {
        logMessages.append(contentsOf: newMessages)
    }

    func merge(_ logController: LogController) {
        logMessages.append(contentsOf: logController.logMessages)
    }

    func resetLogs() {
        logMessages = []
    }
}
