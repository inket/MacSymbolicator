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
    func resetLogs()
}

class DefaultLogController: NSObject, LogController {
    weak var delegate: LogControllerDelegate?

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return dateFormatter
    }()

    var logMessages = [String]() {
        didSet {
            delegate?.logController(self, logsUpdated: logMessages)
        }
    }

    func addLogMessage(_ message: String) {
        let date = DefaultLogController.dateFormatter.string(from: Date())
        logMessages.append("\(date): \(message)")
    }

    func addLogMessages(_ newMessages: [String]) {
        for newMessage in newMessages {
            addLogMessage(newMessage)
        }
    }

    func resetLogs() {
        logMessages = []
    }
}
