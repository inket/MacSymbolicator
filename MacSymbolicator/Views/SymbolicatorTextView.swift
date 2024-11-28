//
//  SymbolicatorTextView.swift
//  MacSymbolicator
//

import Cocoa

final class SymbolicatorTextView: NSView {
    private let scrollView = NSScrollView()
    private let textView = NSTextView()

    private let savePanel = NSSavePanel()

    var defaultSaveURL: URL? {
        didSet {
            let saveButton = window?.toolbar?.items.compactMap { $0.view as? NSButton }.first
            saveButton?.title = defaultSaveURL == nil ? "Save…" : "Save"
        }
    }

    var text: String {
        get {
            textView.string
        }
        set {
            textView.string = newValue
        }
    }

    init() {
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        textView.autoresizingMask = .width

        var fonts = [NSFont]()

        if #available(OSX 10.15, *) {
            fonts.append(NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular))
        }

        let monospacedFonts = ["SFMono-Regular", "Menlo"].compactMap {
            NSFont(name: $0, size: NSFont.systemFontSize)
        }

        fonts.append(contentsOf: monospacedFonts)

        textView.font = fonts.first
        textView.isEditable = false

        scrollView.documentView = textView
    }

    func takeOverToolbar() {
        guard window != nil else {
            assertionFailure("takeOverToolbar() should not be called until the text view is in the view hierarchy")
            return
        }

        setupToolbar()
    }

    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: "TextViewToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window?.toolbar = toolbar
    }

    @objc func save() {
        let saveFailureHandler: (Error) -> Void = { error in
            let alert = NSAlert()
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }

        if let defaultSaveURL = defaultSaveURL {
            do {
                try text.write(to: defaultSaveURL, atomically: true, encoding: .utf8)
                NSWorkspace.shared.activateFileViewerSelecting([defaultSaveURL])
            } catch {
                saveFailureHandler(error)
            }
        } else if let window {
            savePanel.beginSheetModal(for: window) { response in
                switch response {
                case .OK:
                    guard let url = self.savePanel.url else { return }

                    do {
                        try self.text.write(to: url, atomically: true, encoding: .utf8)
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

extension SymbolicatorTextView: NSToolbarDelegate {
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
            saveButton.title = defaultSaveURL == nil ? "Save…" : "Save"
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
