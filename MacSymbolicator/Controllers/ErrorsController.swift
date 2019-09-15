//
//  ErrorsController.swift
//  MacSymbolicator
//

import Cocoa

protocol ErrorsControllerDelegate: class {
    func errorsController(_ controller: ErrorsController, errorsUpdated errors: [String])
}

class ErrorsController: NSObject {
    private let textWindowController = TextWindowController(title: "Errors")

    weak var delegate: ErrorsControllerDelegate?

    private var errors = [String]() {
        didSet {
            delegate?.errorsController(self, errorsUpdated: errors)

            DispatchQueue.main.async {
                self.textWindowController.text = self.errors.joined(
                    separator: "\n————————————————————————————————\n"
                )
            }
        }
    }

    @objc func viewErrors() {
        textWindowController.showWindow()
    }

    func addErrors(_ newErrors: [String]) {
        errors.append(contentsOf: newErrors)
    }

    func resetErrors() {
        errors = []
    }
}
