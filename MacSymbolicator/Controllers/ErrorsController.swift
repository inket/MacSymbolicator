//
//  ErrorsController.swift
//  MacSymbolicator
//

import Cocoa

protocol ErrorsControllerDelegate: class {
    func errorsController(_ controller: ErrorsController, errorsUpdated errors: [String])
}

class ErrorsController: NSObject {
    private let window = CenteredWindow(width: 800, height: 800)
    private let scrollView = NSScrollView()
    private let textView = NSTextView()

    weak var delegate: ErrorsControllerDelegate?

    private var errors = [String]() {
        didSet {
            delegate?.errorsController(self, errorsUpdated: errors)
        }
    }

    @objc func viewErrors() {
        window.styleMask = [.unifiedTitleAndToolbar, .titled, .closable]
        window.title = "Errors"

        let contentView = window.contentView!

        if scrollView.superview != contentView {
            contentView.addSubview(scrollView)

            scrollView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])

            textView.autoresizingMask = .width
            scrollView.documentView = textView
        }

        textView.string = errors.joined(separator: "\n————————————————————————————————\n")
        window.makeKeyAndOrderFront(nil)
    }

    func addErrors(_ newErrors: [String]) {
        errors.append(contentsOf: newErrors)
    }

    func resetErrors() {
        errors = []
    }
}
