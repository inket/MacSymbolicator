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
    private let crashFileDropZone = DropZone(
        fileTypes: [".crash", ".txt"],
        allowsMultipleFiles: false,
        text: "Drop Crash Report or Sample"
    )
    private let dsymFileDropZone = DropZone(
        fileTypes: [".dSYM"],
        allowsMultipleFiles: true,
        text: "Drop App DSYMs",
        detailText: "(if not found automatically)"
    )
    private let symbolicateButton = NSButton()
    private let viewErrorsButton = NSButton()

    private var crashFile: CrashFile?
    private var dsymFile: DSYMFile?

    private var isSymbolicating: Bool = false {
        didSet {
            symbolicateButton.isEnabled = !isSymbolicating
            symbolicateButton.title = isSymbolicating ? "Symbolicating…" : "Symbolicate"
        }
    }

    private let errorsController = ErrorsController()

    init() {
        crashFileDropZone.delegate = self
        dsymFileDropZone.delegate = self
        errorsController.delegate = self

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
        viewErrorsButton.target = errorsController
        viewErrorsButton.action = #selector(ErrorsController.viewErrors)
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
        dropZonesContainerView.addSubview(dsymFileDropZone)
        statusView.addSubview(statusTextField)
        statusView.addSubview(symbolicateButton)
        statusView.addSubview(viewErrorsButton)

        dropZonesContainerView.translatesAutoresizingMaskIntoConstraints = false
        crashFileDropZone.translatesAutoresizingMaskIntoConstraints = false
        dsymFileDropZone.translatesAutoresizingMaskIntoConstraints = false
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

            dsymFileDropZone.topAnchor.constraint(equalTo: dropZonesContainerView.topAnchor),
            dsymFileDropZone.trailingAnchor.constraint(equalTo: dropZonesContainerView.trailingAnchor),
            dsymFileDropZone.bottomAnchor.constraint(equalTo: dropZonesContainerView.bottomAnchor),
            dsymFileDropZone.heightAnchor.constraint(equalTo: dropZonesContainerView.heightAnchor),
            dsymFileDropZone.widthAnchor.constraint(equalTo: dropZonesContainerView.widthAnchor, multiplier: 0.5),

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
        guard
            !isSymbolicating,
            let crashFile = crashFile,
            let dsymFile = dsymFile
        else {
            return
        }

        isSymbolicating = true

        var symbolicator = Symbolicator(crashFile: crashFile, dsymFiles: [dsymFile])

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

    func startSearchForDSYM() {
        return

        guard
            let crashFile = crashFile,
            let crashFileUUID = BinaryUUID("TODO") // crashFile.uuid
        else {
            let alert = NSAlert()
            alert.informativeText = "Couldn't retrieve UUID from crash report"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        dsymFileDropZone.detailText = "Searching…"
        errorsController.resetErrors()

        DSYMSearch.search(
            forUUID: crashFileUUID.pretty,
            crashFileDirectory: crashFile.path.deletingLastPathComponent().path,
            fileSearchErrorHandler: errorsController.addErrors
        ) { [weak self] result in
            defer {
                self?.updateDSYMDetailText()
            }

            guard let foundDSYMPath = result else { return }

            let foundDSYMURL = URL(fileURLWithPath: foundDSYMPath)
            self?.dsymFile = DSYMFile(path: foundDSYMURL)
            self?.dsymFileDropZone.files = [foundDSYMURL] // TODO: find all dsyms
        }
    }

    func updateDSYMDetailText() {
        if let dsymFile = dsymFile {
            let uuidMismatch: Bool
            if let crashFileUUID = BinaryUUID("TODO") { // crashFile?.uuid {
                let dsymUUIDs = dsymFile.uuids.values
                uuidMismatch = !dsymUUIDs.isEmpty && !dsymUUIDs.contains(crashFileUUID)
            } else {
                // We don't have enough data to decide that, let's just say it's not…
                uuidMismatch = false
            }

            statusTextField.stringValue = uuidMismatch ? "⚠️ UUID mismatch" : ""
            dsymFileDropZone.detailText = nil
        } else {
            dsymFileDropZone.detailText = nil
        }
    }

    func openFile(_ path: String) -> Bool {
        let fileURL = URL(fileURLWithPath: path)
        return crashFileDropZone.acceptFile(url: fileURL) || dsymFileDropZone.acceptFile(url: fileURL)
    }
}

extension MainController: DropZoneDelegate {
    func receivedFiles(dropZone: DropZone, fileURLs: [URL]) {
        let fileURL = fileURLs.first! // TODO: fix me

        if dropZone == crashFileDropZone {
            crashFile = CrashFile(path: fileURL)

            if let crashFile = crashFile, dsymFile?.canSymbolicate(crashFile) != true {
                startSearchForDSYM()
            }
        } else if dropZone == dsymFileDropZone {
            dsymFile = DSYMFile(path: fileURL)
            updateDSYMDetailText()
        }
    }
}

extension MainController: ErrorsControllerDelegate {
    func errorsController(_ controller: ErrorsController, errorsUpdated errors: [String]) {
        DispatchQueue.main.async {
            self.viewErrorsButton.isHidden = errors.isEmpty
        }
    }
}
