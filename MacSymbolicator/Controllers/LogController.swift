//
//  LogController.swift
//  MacSymbolicator
//

import Cocoa

protocol LogControllerDelegate: AnyObject {
    func logController(_ controller: LogController, logsUpdated logMessages: [String])
}

class LogController: NSObject {
    private let textWindowController = TextWindowController(title: "Errors")

    weak var delegate: LogControllerDelegate?

    private var logMessages = [String]() {
        didSet {
            delegate?.logController(self, logsUpdated: logMessages)

            // Update the text here so that if the window is already open, the text gets updated
            DispatchQueue.main.async {
                self.textWindowController.text = self.logMessages.joined(
                    separator: "\n————————————————————————————————\n"
                )
            }
        }
    }

    @objc func viewLogs() {
        textWindowController.showWindow()
    }

    func addLogMessages(_ newMessages: [String]) {
        logMessages.append(contentsOf: newMessages)
    }

    func resetLogs() {
        logMessages = []
    }
}
