//
//  InputCoordinator.swift
//  MacSymbolicator
//

import Foundation

protocol InputCoordinatorDelegate: AnyObject {
    func inputCoordinator(_ inputCoordinator: InputCoordinator, receivedNewInput newInput: Any?)
}

class InputCoordinator {
    let crashFileDropZone = DropZone(
        fileTypes: [".crash", ".txt"],
        allowsMultipleFiles: false,
        text: "Drop Crash Report or Sample",
        activatesAppAfterDrop: true
    )

    let dsymFilesDropZone = DropZone(
        fileTypes: [".dSYM"],
        allowsMultipleFiles: true,
        text: "Drop App DSYMs",
        detailText: "(if not found automatically)",
        activatesAppAfterDrop: true
    )

    private(set) var crashFile: CrashFile?
    private(set) var dsymFiles: [DSYMFile] = []

    private var isSearchingForDSYMs = false

    weak var delegate: InputCoordinatorDelegate?

    let logController = LogController()

    private var expectedDSYMUUIDs: Set<String> {
        guard let crashFile = crashFile else { return Set<String>() }

        return Set<String>(crashFile.uuidsForSymbolication.map { $0.pretty })
    }

    private var foundDSYMUUIDs: Set<String> {
        let addedDSYMUUIDs = dsymFiles.flatMap { $0.uuids.values }.map { $0.pretty }
        return expectedDSYMUUIDs.intersection(addedDSYMUUIDs)
    }

    private var remainingDSYMUUIDs: Set<String> {
        expectedDSYMUUIDs.subtracting(foundDSYMUUIDs)
    }

    init() {
        crashFileDropZone.delegate = self
        dsymFilesDropZone.delegate = self
    }

    func acceptCrashFile(url fileURL: URL) -> Bool {
        crashFileDropZone.acceptFile(url: fileURL)
    }

    func acceptDSYMFile(url fileURL: URL) -> Bool {
        dsymFilesDropZone.acceptFile(url: fileURL)
    }

    func startSearchForDSYMs() {
        guard let crashFile = crashFile else { return }

        let remainingUUIDs = Array(remainingDSYMUUIDs)

        guard !remainingUUIDs.isEmpty else {
            updateDSYMDetailText()
            return
        }

        isSearchingForDSYMs = true
        updateDSYMDetailText()

        DSYMSearch.search(
            forUUIDs: remainingUUIDs,
            crashFileDirectory: crashFile.path.deletingLastPathComponent().path,
            logHandler: logController.addLogMessages,
            callback: { [weak self] finished, results in
                DispatchQueue.main.async {
                    results?.forEach { dsymResult in
                        let dsymURL = URL(fileURLWithPath: dsymResult.path)
                        self?.dsymFilesDropZone.acceptFile(url: dsymURL)
                    }

                    if finished {
                        self?.isSearchingForDSYMs = false
                    }

                    self?.updateDSYMDetailText()
                }
            }
        )
    }

    func updateCrashDetailText() {
        guard crashFile != nil else {
            crashFileDropZone.detailText = ""
            return
        }

        let expectedCount = expectedDSYMUUIDs.count
        switch expectedCount {
        case 0:
            crashFileDropZone.detailText = "(Symbolication not needed)"
        case 1:
            crashFileDropZone.detailText = "(1 DSYM necessary)"
        default:
            crashFileDropZone.detailText = "(\(expectedCount) DSYMs necessary)"
        }
    }

    func updateDSYMDetailText() {
        guard crashFile != nil else {
            dsymFilesDropZone.detailText = "(if not found automatically)"
            return
        }

        guard !expectedDSYMUUIDs.isEmpty else {
            dsymFilesDropZone.detailText = ""
            return
        }

        let prefix = isSearchingForDSYMs ? "Searching…" : "Found"
        let count = "\(foundDSYMUUIDs.count)/\(expectedDSYMUUIDs.count)"

        dsymFilesDropZone.detailText = "\(prefix) \(count)"
    }
}

extension InputCoordinator: DropZoneDelegate {
    func receivedFiles(dropZone: DropZone, fileURLs: [URL]) {
        if dropZone == crashFileDropZone, let fileURL = fileURLs.last {
            crashFile = CrashFile(path: fileURL)

            logController.resetLogs()
            updateCrashDetailText()

            delegate?.inputCoordinator(self, receivedNewInput: crashFile)

            if crashFile != nil {
                startSearchForDSYMs()
            }
        } else if dropZone == dsymFilesDropZone {
            let dsymFiles = fileURLs.map { DSYMFile(path: $0) }
            self.dsymFiles.append(contentsOf: dsymFiles)

            updateDSYMDetailText()

            delegate?.inputCoordinator(self, receivedNewInput: dsymFiles)
        }
    }
}
