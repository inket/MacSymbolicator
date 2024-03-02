//
//  MainController.swift
//  MacSymbolicator
//

import Cocoa

class MainController {
    private let mainWindow = CenteredWindow(width: 800, height: 400)
    private let textWindowController = TextWindowController(title: "Symbolicated Content", clearable: false)

    private var updateButton: NSButton?
    private var availableUpdateURL: URL?

    private let dropZonesContainerView = NSView()
    private let statusView = NSView()
    private let statusTextField = NSTextField()

    private let symbolicateButton = NSButton()
    private let viewLogsButton = NSButton()

    private lazy var inputCoordinator = InputCoordinator(logController: logController)

    private var isSymbolicating: Bool = false {
        didSet {
            symbolicateButton.isEnabled = !isSymbolicating
            symbolicateButton.title = isSymbolicating ? "Symbolicating…" : "Symbolicate"
        }
    }

    private let logController: ViewableLogController = DefaultViewableLogController()

    init() {
        logController.delegate = self

        let reportFileDropZone = inputCoordinator.reportFileDropZone
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

        viewLogsButton.title = "View Logs…"
        viewLogsButton.bezelStyle = .rounded
        viewLogsButton.focusRingType = .none
        viewLogsButton.target = logController
        viewLogsButton.action = #selector(ViewableLogController.viewLogs)
        viewLogsButton.isHidden = true

        let contentView = mainWindow.contentView!
        contentView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        contentView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        contentView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(dropZonesContainerView)
        contentView.addSubview(statusView)
        dropZonesContainerView.addSubview(reportFileDropZone)
        dropZonesContainerView.addSubview(dsymFilesDropZone)
        statusView.addSubview(statusTextField)
        statusView.addSubview(symbolicateButton)
        statusView.addSubview(viewLogsButton)

        dropZonesContainerView.translatesAutoresizingMaskIntoConstraints = false
        reportFileDropZone.translatesAutoresizingMaskIntoConstraints = false
        dsymFilesDropZone.translatesAutoresizingMaskIntoConstraints = false
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusTextField.translatesAutoresizingMaskIntoConstraints = false
        symbolicateButton.translatesAutoresizingMaskIntoConstraints = false
        viewLogsButton.translatesAutoresizingMaskIntoConstraints = false

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

            reportFileDropZone.topAnchor.constraint(equalTo: dropZonesContainerView.topAnchor),
            reportFileDropZone.leadingAnchor.constraint(equalTo: dropZonesContainerView.leadingAnchor),
            reportFileDropZone.bottomAnchor.constraint(equalTo: dropZonesContainerView.bottomAnchor),
            reportFileDropZone.heightAnchor.constraint(equalTo: dropZonesContainerView.heightAnchor),
            reportFileDropZone.widthAnchor.constraint(equalTo: dropZonesContainerView.widthAnchor, multiplier: 0.5),

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

            viewLogsButton.trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: -20),
            viewLogsButton.centerYAnchor.constraint(equalTo: statusView.centerYAnchor),
            viewLogsButton.widthAnchor.constraint(equalToConstant: 120)
        ])

        mainWindow.makeKeyAndOrderFront(nil)
    }

    @objc func symbolicate() {
        guard !isSymbolicating else { return }

        guard let reportFile = inputCoordinator.reportFile else {
            inputCoordinator.reportFileDropZone.flash()
            return
        }

        guard !inputCoordinator.dsymFiles.isEmpty else {
            inputCoordinator.dsymFilesDropZone.flash()
            return
        }

        logController.resetLogs()

        isSymbolicating = true

        let dsymFiles = inputCoordinator.dsymFiles
        var symbolicator = Symbolicator(
            reportFile: reportFile,
            dsymFiles: dsymFiles,
            logController: logController
        )

        DispatchQueue.global(qos: .userInitiated).async {
            let success = symbolicator.symbolicate()

            DispatchQueue.main.async {
                if success {
                    self.textWindowController.text = symbolicator.symbolicatedContent ?? ""
                    self.textWindowController.defaultSaveURL = reportFile.symbolicatedContentSaveURL
                    self.textWindowController.showWindow()
                } else {
                    let alert = NSAlert()
                    alert.informativeText = "Symbolication failed. See logs for more info."
                    alert.alertStyle = .critical

                    alert.addButton(withTitle: "OK")
                    alert.addButton(withTitle: "View Logs…")

                    if alert.runModal() == .alertSecondButtonReturn {
                        self.logController.viewLogs()
                    }
                }

                self.isSymbolicating = false
            }
        }
    }

    func openFile(_ path: String) -> Bool {
        let fileURL = URL(fileURLWithPath: path)
        return inputCoordinator.acceptReportFile(url: fileURL) || inputCoordinator.acceptDSYMFile(url: fileURL)
    }

    func suggestUpdate(version: String, url: URL) {
        availableUpdateURL = url

        let updateButton = self.updateButton ?? NSButton()
        updateButton.title = "Update available: \(version)"
        updateButton.controlSize = .small
        updateButton.bezelStyle = .roundRect
        updateButton.target = self
        updateButton.action = #selector(self.tappedUpdateButton(_:))

        guard let frameView = mainWindow.contentView?.superview else {
            return
        }

        frameView.addSubview(updateButton)
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            updateButton.trailingAnchor.constraint(equalTo: frameView.trailingAnchor, constant: -6),
            updateButton.topAnchor.constraint(equalTo: frameView.topAnchor, constant: 6)
        ])
    }

    @objc
    private func tappedUpdateButton(_ sender: AnyObject?) {
        guard let availableUpdateURL = availableUpdateURL else { return }
        NSWorkspace.shared.open(availableUpdateURL)
    }
}

extension MainController: LogControllerDelegate {
    func logController(_ controller: LogController, logsUpdated logMessages: [String]) {
        DispatchQueue.main.async {
            self.viewLogsButton.isHidden = logMessages.isEmpty
        }
    }
}
