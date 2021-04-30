//
//  MainController.swift
//  MacSymbolicator
//

import Cocoa

class MainController {
    private let mainWindow = CenteredWindow(width: 800, height: 400)
    private let textWindowController = TextWindowController(title: "Symbolicated Content")

    private let dropZonesContainerView = NSView()
    private let statusView = NSView()
    private let statusTextField = NSTextField()

    private let symbolicateButton = NSButton()
    private let viewErrorsButton = NSButton()

    private let inputCoordinator = InputCoordinator()

    private var isSymbolicating: Bool = false {
        didSet {
            symbolicateButton.isEnabled = !isSymbolicating
            symbolicateButton.title = isSymbolicating ? "Symbolicating…" : "Symbolicate"
        }
    }

    private let logController = LogController()

    init() {
        logController.delegate = self

        let crashFileDropZone = inputCoordinator.crashFileDropZone
        let dsymFilesDropZone = inputCoordinator.dsymFilesDropZone
        mainWindow.styleMask = [.unifiedTitleAndToolbar, .titled]
        mainWindow.title = "MacSymbolicator"

        statusTextField.drawsBackground = false
        statusTextField.isBezeled = false
        statusTextField.isEditable = false
        statusTextField.isSelectable = false

        symbolicateButton.title = "Symbolicate"
        symbolicateButton.bezelStyle = .rounded
        symbolicateButton.focusRingType = .none
        symbolicateButton.target = self
        symbolicateButton.action = #selector(MainController.symbolicate)

        viewErrorsButton.title = "View Errors…"
        viewErrorsButton.bezelStyle = .rounded
        viewErrorsButton.focusRingType = .none
        viewErrorsButton.target = logController
        viewErrorsButton.action = #selector(LogController.viewLogs)
        viewErrorsButton.isHidden = true

        let contentView = mainWindow.contentView!
        contentView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        contentView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        contentView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(dropZonesContainerView)
        contentView.addSubview(statusView)
        dropZonesContainerView.addSubview(crashFileDropZone)
        dropZonesContainerView.addSubview(dsymFilesDropZone)
        statusView.addSubview(statusTextField)
        statusView.addSubview(symbolicateButton)
        statusView.addSubview(viewErrorsButton)

        dropZonesContainerView.translatesAutoresizingMaskIntoConstraints = false
        crashFileDropZone.translatesAutoresizingMaskIntoConstraints = false
        dsymFilesDropZone.translatesAutoresizingMaskIntoConstraints = false
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusTextField.translatesAutoresizingMaskIntoConstraints = false
        symbolicateButton.translatesAutoresizingMaskIntoConstraints = false
        viewErrorsButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 400),
            contentView.widthAnchor.constraint(equalToConstant: 800),

            dropZonesContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            dropZonesContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dropZonesContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dropZonesContainerView.heightAnchor.constraint(lessThanOrEqualToConstant: mainWindow.frame.size.height),
            dropZonesContainerView.widthAnchor.constraint(lessThanOrEqualToConstant: mainWindow.frame.size.width),

            statusView.topAnchor.constraint(equalTo: dropZonesContainerView.bottomAnchor),
            statusView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            statusView.heightAnchor.constraint(equalToConstant: 50),

            crashFileDropZone.topAnchor.constraint(equalTo: dropZonesContainerView.topAnchor),
            crashFileDropZone.leadingAnchor.constraint(equalTo: dropZonesContainerView.leadingAnchor),
            crashFileDropZone.bottomAnchor.constraint(equalTo: dropZonesContainerView.bottomAnchor),
            crashFileDropZone.heightAnchor.constraint(equalTo: dropZonesContainerView.heightAnchor),
            crashFileDropZone.widthAnchor.constraint(equalTo: dropZonesContainerView.widthAnchor, multiplier: 0.5),

            dsymFilesDropZone.topAnchor.constraint(equalTo: dropZonesContainerView.topAnchor),
            dsymFilesDropZone.trailingAnchor.constraint(equalTo: dropZonesContainerView.trailingAnchor),
            dsymFilesDropZone.bottomAnchor.constraint(equalTo: dropZonesContainerView.bottomAnchor),
            dsymFilesDropZone.heightAnchor.constraint(equalTo: dropZonesContainerView.heightAnchor),
            dsymFilesDropZone.widthAnchor.constraint(equalTo: dropZonesContainerView.widthAnchor, multiplier: 0.5),

            statusTextField.leadingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: 20),
            statusTextField.centerYAnchor.constraint(equalTo: statusView.centerYAnchor),
            statusTextField.widthAnchor.constraint(equalToConstant: 120),

            symbolicateButton.centerXAnchor.constraint(equalTo: statusView.centerXAnchor),
            symbolicateButton.centerYAnchor.constraint(equalTo: statusView.centerYAnchor),
            symbolicateButton.widthAnchor.constraint(equalToConstant: 120),

            viewErrorsButton.trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: -20),
            viewErrorsButton.centerYAnchor.constraint(equalTo: statusView.centerYAnchor),
            viewErrorsButton.widthAnchor.constraint(equalToConstant: 120)
        ])

        mainWindow.makeKeyAndOrderFront(nil)
    }

    @objc func symbolicate() {
        guard !isSymbolicating else { return }

        guard let crashFile = inputCoordinator.crashFile else {
            inputCoordinator.crashFileDropZone.flash()
            return
        }

        guard !inputCoordinator.dsymFiles.isEmpty else {
            inputCoordinator.dsymFilesDropZone.flash()
            return
        }

        isSymbolicating = true

        let dsymFiles = inputCoordinator.dsymFiles
        var symbolicator = Symbolicator(crashFile: crashFile, dsymFiles: dsymFiles)

        DispatchQueue.global(qos: .userInitiated).async {
            let success = symbolicator.symbolicate()

            DispatchQueue.main.async {
                if success {
                    self.textWindowController.text = symbolicator.symbolicatedContent ?? ""
                    self.textWindowController.defaultSaveURL = crashFile.symbolicatedContentSaveURL
                    self.textWindowController.showWindow()
                } else {
                    let alert = NSAlert()
                    alert.informativeText = symbolicator.errors.joined(separator: "\n")
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }

                self.isSymbolicating = false
            }
        }
    }

    func openFile(_ path: String) -> Bool {
        let fileURL = URL(fileURLWithPath: path)

        if inputCoordinator.acceptCrashFile(url: fileURL) {
            // New crash file, old logs probably don't apply anymore so we need to reset them
            logController.resetLogs()

            return true
        } else if inputCoordinator.acceptDSYMFile(url: fileURL) {
            return true
        }

        return false
    }
}

extension MainController: LogControllerDelegate {
    func logController(_ controller: LogController, logsUpdated errors: [String]) {
        DispatchQueue.main.async {
            self.viewErrorsButton.isHidden = errors.isEmpty
        }
    }
}
