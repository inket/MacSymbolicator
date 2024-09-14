//
//  ViewableLogController.swift
//  MacSymbolicator
//

import Foundation

@objc
protocol ViewableLogController: LogController {
    func viewLogs()
}

final class DefaultViewableLogController: DefaultLogController, ViewableLogController {
    private let textWindowController = TextWindowController(title: "Logs", clearable: true)

    override var logMessages: [String] {
        didSet {
            // Update the text here so that if the window is already open, the text gets updated
            DispatchQueue.main.async {
                self.textWindowController.text = self.logMessages.joined(separator: "\n")
            }
        }
    }

    @objc func viewLogs() {
        textWindowController.showWindow()
    }
}
