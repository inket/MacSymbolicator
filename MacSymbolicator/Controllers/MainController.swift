//
//  MainController.swift
//  MacSymbolicator
//

import Cocoa

class MainController {
    private let mainWindow = MainWindow(width: 600, height: 300)
    private let dropZonesContainerView = NSView()
    private let statusView = NSView()
    private let crashFileDropZone = DropZone(fileType: ".crash", text: "Drop Crash Report")
    private let dsymFileDropZone = DropZone(
        fileType: ".dSYM",
        text: "Drop App DSYM",
        detailText: "(if not found automatically)"
    )
    private let symbolicateButton = NSButton()

    private var crashFile: CrashFile?
    private var dsymFile: DSYMFile?

    private var isSymbolicating: Bool = false {
        didSet {
            symbolicateButton.isEnabled = !isSymbolicating
            symbolicateButton.title = isSymbolicating ? "Symbolicating…" : "Symbolicate"
        }
    }

    init() {
        crashFileDropZone.delegate = self
        dsymFileDropZone.delegate = self

        mainWindow.title = "MacSymbolicator"
        symbolicateButton.title = "Symbolicate"
        symbolicateButton.bezelStyle = .rounded
        symbolicateButton.focusRingType = .none
        symbolicateButton.target = self
        symbolicateButton.action = #selector(MainController.symbolicate)

        let contentView = mainWindow.contentView!

        contentView.addSubview(dropZonesContainerView)
        contentView.addSubview(statusView)
        dropZonesContainerView.addSubview(crashFileDropZone)
        dropZonesContainerView.addSubview(dsymFileDropZone)
        statusView.addSubview(symbolicateButton)

        dropZonesContainerView.translatesAutoresizingMaskIntoConstraints = false
        crashFileDropZone.translatesAutoresizingMaskIntoConstraints = false
        dsymFileDropZone.translatesAutoresizingMaskIntoConstraints = false
        statusView.translatesAutoresizingMaskIntoConstraints = false
        symbolicateButton.translatesAutoresizingMaskIntoConstraints = false

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
            symbolicateButton.widthAnchor.constraint(equalToConstant: 120)
        ])

        mainWindow.makeKeyAndOrderFront(nil)
    }

    @objc func symbolicate() {
        guard
            !isSymbolicating,
            var crashFile = crashFile,
            let dsymFile = dsymFile
        else {
            return
        }

        isSymbolicating = true

        var symbolicator = Symbolicator(crashFile: crashFile, dsymFile: dsymFile)

        DispatchQueue.global(qos: .userInitiated).async {
            let success = symbolicator.symbolicate()

            if success {
                crashFile.symbolicatedContent = symbolicator.symbolicatedContent
                crashFile.saveSymbolicatedContent()
            }

            DispatchQueue.main.async {
                if !success {
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

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let foundDSYMPath = self?.searchForDSYM(uuid: crashFileUUID) else { return }

            DispatchQueue.main.async {
                let foundDSYMURL = URL(fileURLWithPath: foundDSYMPath)
                self?.dsymFile = DSYMFile(path: foundDSYMURL)
                self?.dsymFileDropZone.file = foundDSYMURL
                self?.dsymFileDropZone.detailText = nil
            }
        }
    }

    func searchForDSYM(uuid: String) -> String? {
        return
            FileSearch.inRootDirectory().spotlight
                .search(UUID: uuid).filter(byFileExtension: "dsym").results.first ??
            FileSearch.inRootDirectory().spotlight
                .search(fileExtension: "dsym").filter(byUUID: uuid).results.first ??
            FileSearch.in(directory: "~/Library/Developer/Xcode/Archives/").unix
                .search(name: "*.dSYM").filter(byUUID: uuid).results.first
    }
}

extension MainController: DropZoneDelegate {
    func receivedFile(dropZone: DropZone, fileURL: URL) {
        if dropZone == crashFileDropZone {
            self.crashFile = CrashFile(path: fileURL)
        } else if dropZone == dsymFileDropZone {
            self.dsymFile = DSYMFile(path: fileURL)
            dsymFileDropZone.detailText = nil
        }

        if crashFile != nil && dsymFile == nil {
            startSearchForDSYM()
        }
    }
}
