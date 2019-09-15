//
//  MainController.swift
//  MacSymbolicator
//

import Cocoa

class MainController {
    private let mainWindow = CenteredWindow(width: 600, height: 300)
    private let textWindowController = TextWindowController(title: "Symbolicated Content")

    private let dropZonesContainerView = NSView()
    private let statusView = NSView()
    private let crashFileDropZone = DropZone(fileTypes: [".crash", ".txt"], text: "Drop Crash Report or Sample")
    private let dsymFileDropZone = DropZone(
        fileTypes: [".dSYM"],
        text: "Drop App DSYM",
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
        mainWindow.title = "MacSymbolicator Preliminary"
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

        contentView.addSubview(dropZonesContainerView)
        contentView.addSubview(statusView)
        dropZonesContainerView.addSubview(crashFileDropZone)
        dropZonesContainerView.addSubview(dsymFileDropZone)
        statusView.addSubview(symbolicateButton)
        statusView.addSubview(viewErrorsButton)

        dropZonesContainerView.translatesAutoresizingMaskIntoConstraints = false
        crashFileDropZone.translatesAutoresizingMaskIntoConstraints = false
        dsymFileDropZone.translatesAutoresizingMaskIntoConstraints = false
        statusView.translatesAutoresizingMaskIntoConstraints = false
        symbolicateButton.translatesAutoresizingMaskIntoConstraints = false
        viewErrorsButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            dropZonesContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            dropZonesContainerView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            dropZonesContainerView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            dropZonesContainerView.heightAnchor.constraint(lessThanOrEqualToConstant: mainWindow.frame.size.height),
            dropZonesContainerView.widthAnchor.constraint(lessThanOrEqualToConstant: mainWindow.frame.size.width),

            statusView.topAnchor.constraint(equalTo: dropZonesContainerView.bottomAnchor),
            statusView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            statusView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            statusView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            statusView.heightAnchor.constraint(equalToConstant: 50),

            crashFileDropZone.topAnchor.constraint(equalTo: dropZonesContainerView.topAnchor),
            crashFileDropZone.leftAnchor.constraint(equalTo: dropZonesContainerView.leftAnchor),
            crashFileDropZone.bottomAnchor.constraint(equalTo: dropZonesContainerView.bottomAnchor),
            crashFileDropZone.heightAnchor.constraint(equalTo: dropZonesContainerView.heightAnchor),
            crashFileDropZone.widthAnchor.constraint(equalTo: dropZonesContainerView.widthAnchor, multiplier: 0.5),

            dsymFileDropZone.topAnchor.constraint(equalTo: dropZonesContainerView.topAnchor),
            dsymFileDropZone.rightAnchor.constraint(equalTo: dropZonesContainerView.rightAnchor),
            dsymFileDropZone.bottomAnchor.constraint(equalTo: dropZonesContainerView.bottomAnchor),
            dsymFileDropZone.heightAnchor.constraint(equalTo: dropZonesContainerView.heightAnchor),
            dsymFileDropZone.widthAnchor.constraint(equalTo: dropZonesContainerView.widthAnchor, multiplier: 0.5),

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

        var symbolicator = Symbolicator(crashFile: crashFile, dsymFile: dsymFile)

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
        guard
            let crashFile = crashFile,
            let crashFileUUID = crashFile.uuid
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

        DispatchQueue.global(qos: .background).async { [weak self] in
            let dsymPath = self?.searchForDSYM(
                uuid: crashFileUUID,
                crashFileDirectory: crashFile.path.deletingLastPathComponent().path
            )

            DispatchQueue.main.async {
                defer {
                    self?.updateDSYMDetailText()
                }

                guard let foundDSYMPath = dsymPath else { return }

                let foundDSYMURL = URL(fileURLWithPath: foundDSYMPath)
                self?.dsymFile = DSYMFile(path: foundDSYMURL)
                self?.dsymFileDropZone.file = foundDSYMURL
            }
        }
    }

    func searchForDSYM(uuid: String, crashFileDirectory: String) -> String? {
        return
            FileSearch.nonRecursive.in(directory: crashFileDirectory)
                .with(errorHandler: errorsController.addErrors)
                .search(fileExtension: "dsym").sorted().firstMatching(uuid: uuid) ??
            FileSearch.recursive.in(directory: "~/Library/Developer/Xcode/Archives/")
                .with(errorHandler: errorsController.addErrors)
                .search(fileExtension: "dsym").sorted().firstMatching(uuid: uuid)
    }

    func updateDSYMDetailText() {
        if let dsymFile = dsymFile {
            let dsymFilePath = dsymFile.path.path
            let uuidMismatch = dsymFile.uuid != nil && crashFile != nil && dsymFile.uuid != crashFile?.uuid

            dsymFileDropZone.detailText = [
                dsymFilePath,
                uuidMismatch ? "(!) UUID mismatch (!)" : nil
            ].compactMap { $0 }.joined(separator: "\n")
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
    func receivedFile(dropZone: DropZone, fileURL: URL) {
        if dropZone == crashFileDropZone {
            crashFile = CrashFile(path: fileURL)
        } else if dropZone == dsymFileDropZone {
            dsymFile = DSYMFile(path: fileURL)
            updateDSYMDetailText()
        }

        if crashFile != nil && dsymFile?.uuid != crashFile?.uuid && dropZone != dsymFileDropZone {
            startSearchForDSYM()
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
