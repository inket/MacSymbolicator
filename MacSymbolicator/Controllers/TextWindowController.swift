//
//  TextWindowController.swift
//  MacSymbolicator
//

import Cocoa

class TextWindowController: NSObject {
    private let window = CenteredWindow(width: 1100, height: 800)
    private let scrollView = NSScrollView()
    private let textView = NSTextView()

    private let savePanel = NSSavePanel()

    var defaultSaveURL: URL? {
        didSet {
            let saveButton = window.toolbar?.items.compactMap { $0.view as? NSButton }.first
            saveButton?.title = defaultSaveURL == nil ? "Save…" : "Save"
        }
    }

    var text: String {
        get {
            return textView.string
        }
        set {
            textView.string = newValue
        }
    }

    init(title: String) {
        super.init()

        window.styleMask = [.unifiedTitleAndToolbar, .titled, .closable, .resizable]
        window.title = title
        window.minSize = NSSize(width: 400, height: 400)

        setupToolbar()
    }

    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: "TextWindowControllerToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
    }

    @objc func showWindow() {
        let contentView = window.contentView!

        if scrollView.superview != contentView {
            contentView.addSubview(scrollView)

            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.hasVerticalScroller = true

            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])

            textView.autoresizingMask = .width

            var fonts = [NSFont]()

            #if compiler(>=5.1) // Only build this part in Xcode 11, which knows about monospacedSystemFont
            if #available(OSX 10.15, *) {
                fonts.append(NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular))
            }
            #endif

            let monospacedFonts = ["SFMono-Regular", "Menlo"].compactMap {
                NSFont(name: $0, size: NSFont.systemFontSize)
            }

            fonts.append(contentsOf: monospacedFonts)

            textView.font = fonts.first

            scrollView.documentView = textView
        }

        window.makeKeyAndOrderFront(nil)
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
                window.orderOut(nil)
                NSWorkspace.shared.activateFileViewerSelecting([defaultSaveURL])
            } catch {
                saveFailureHandler(error)
            }
        } else {
            savePanel.beginSheetModal(for: window) { response in
                switch response {
                case .OK:
                    guard let url = self.savePanel.url else { return }

                    do {
                        try self.text.write(to: url, atomically: true, encoding: .utf8)
                        self.window.orderOut(nil)
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

extension TextWindowController: NSToolbarDelegate {
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
        return [.flexibleSpace, .save]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .save]
    }
}

extension NSToolbarItem.Identifier {
    static var save = NSToolbarItem.Identifier(rawValue: "Save")
}
