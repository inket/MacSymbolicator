//
//  SymbolicatorViewController.swift
//  MacSymbolicator
//

import Cocoa

final class SymbolicatorViewController: NSViewController {
    let viewModel: SymbolicatorViewModel

    private let scrollView = NSScrollView()
    private let textView = SymbolicatorTextView()

    private let savePanel = NSSavePanel()

    init(viewModel: SymbolicatorViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        textView.autoresizingMask = .width
        textView.font = viewModel.font
        textView.isEditable = false

        scrollView.documentView = textView

        textView.string = viewModel.text

        Task { @MainActor in
            var rangeOffset = 0
            for token in await viewModel.tokens {
                var attributes: [NSAttributedString.Key: Any] = [
                    .token: token.state
                ]

                if let foregroundColor = token.state.foregroundColor {
                    attributes[.foregroundColor] = foregroundColor
                }

                textView.textStorage?.addAttributes(attributes, range: token.range)

                rangeOffset = rangeOffset - token.range.length + 1
            }
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setupToolbar()
    }

    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: "TextViewToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        view.window?.toolbar = toolbar
    }

    @objc func save() {
        let saveFailureHandler: (Error) -> Void = { error in
            let alert = NSAlert()
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }

        if let defaultSaveURL = viewModel.defaultSaveURL {
            do {
                try viewModel.text.write(to: defaultSaveURL, atomically: true, encoding: .utf8)
                NSWorkspace.shared.activateFileViewerSelecting([defaultSaveURL])
            } catch {
                saveFailureHandler(error)
            }
        } else if let window = view.window {
            savePanel.beginSheetModal(for: window) { response in
                switch response {
                case .OK:
                    guard let url = self.savePanel.url else { return }

                    do {
                        try self.viewModel.text.write(to: url, atomically: true, encoding: .utf8)
                    } catch {
                        saveFailureHandler(error)
                    }
                default:
                    return
                }
            }
        }
    }
}

extension SymbolicatorViewController: NSToolbarDelegate {
    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case NSToolbarItem.Identifier.save.rawValue:
            let saveToolbarItem = NSToolbarItem(itemIdentifier: .save)
            saveToolbarItem.label = "Save"
            saveToolbarItem.paletteLabel = "Save"
            saveToolbarItem.target = self
            saveToolbarItem.action = #selector(save)

            let saveButton = NSButton()
            saveButton.bezelStyle = .texturedRounded
            saveButton.title = "Save"
            saveButton.target = self
            saveButton.action = #selector(save)
            saveToolbarItem.view = saveButton

            return saveToolbarItem
        default:
            return nil
        }
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, .save]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, .save]
    }
}

extension NSToolbarItem.Identifier {
    static var clear = NSToolbarItem.Identifier(rawValue: "Clear")
    static var save = NSToolbarItem.Identifier(rawValue: "Save")
}
