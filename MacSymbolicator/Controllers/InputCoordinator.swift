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
        fileTypes: [".crash", ".ips", ".txt"],
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

    let logController: LogController = DefaultLogController()

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
            // Is it nil because we couldn't initialize the crashFile or because no files have been dropped in?
            if crashFileDropZone.files.isEmpty {
                crashFileDropZone.detailText = ""
            } else {
                crashFileDropZone.detailText = "Unexpected format"
            }

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
    func receivedFiles(dropZone: DropZone, fileURLs: [URL]) -> [URL] {
        defer {
            // Delay updating the UI until this method has returned and the drop zone's files list is updated
            if dropZone == crashFileDropZone {
                DispatchQueue.main.async(execute: self.updateCrashDetailText)
            } else if dropZone == dsymFilesDropZone {
                DispatchQueue.main.async(execute: self.updateDSYMDetailText)
            }
        }

        if dropZone == crashFileDropZone, let fileURL = fileURLs.last {
            logController.resetLogs()

            crashFile = nil

            do {
                crashFile = try CrashFile(path: fileURL)
            } catch {
                logController.addLogMessage("Error loading crash file: \(error)")
            }

            delegate?.inputCoordinator(self, receivedNewInput: crashFile)

            if crashFile != nil {
                startSearchForDSYMs()
            }

            return fileURLs
        } else if dropZone == dsymFilesDropZone {
            let dsymFiles = fileURLs.flatMap { DSYMFile.dsymFiles(from: $0) }
            self.dsymFiles.append(contentsOf: dsymFiles)

            delegate?.inputCoordinator(self, receivedNewInput: dsymFiles)

            return dsymFiles.map { $0.path }
        }

        return []
    }
}
