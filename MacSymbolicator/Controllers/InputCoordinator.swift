//
//  InputCoordinator.swift
//  MacSymbolicator
//

import Foundation

final class InputCoordinator {
    private(set) lazy var reportFileDropZone = DropZone(
        fileTypes: [".crash", ".ips", ".txt", ".hang"],
        allowsMultipleFiles: false,
        tableViewViewModel: nil,
        text: "Drop Report File\n(crash, sample, spindump or hang)",
        activatesAppAfterDrop: true
    )

    private let dsymListViewModel = DSYMListViewModel()
    private(set) lazy var dsymFilesDropZone = DropZone(
        fileTypes: [".dSYM"],
        allowsMultipleFiles: true,
        tableViewViewModel: dsymListViewModel,
        text: "Drop App dSYMs",
        detailText: "(if not found automatically)",
        activatesAppAfterDrop: true
    )

    private(set) var reportFile: ReportFile?
    private(set) var dsymFiles: [DSYMFile] = []

    private var isSearchingForDSYMs = false

    private let logController: LogController

    private var expectedDSYMUUIDs: Set<String> {
        Set<String>(reportFile?.dsymRequirements.expectedUUIDs.map { $0.pretty } ?? [])
    }

    private var expectedNonSystemDSYMUUIDs: Set<String> {
        Set<String>(reportFile?.dsymRequirements.expectedNonSystemUUIDs.map { $0.pretty } ?? [])
    }

    private var foundDSYMUUIDs: Set<String> {
        let addedDSYMUUIDs = dsymFiles.flatMap { $0.uuids.values }.map { $0.pretty }
        return expectedDSYMUUIDs.intersection(addedDSYMUUIDs)
    }

    private var remainingDSYMUUIDs: Set<String> {
        expectedDSYMUUIDs.subtracting(foundDSYMUUIDs)
    }

    init(logController: any LogController) {
        self.logController = logController
        reportFileDropZone.delegate = self
        dsymFilesDropZone.delegate = self
    }

    func acceptReportFile(url fileURL: URL) -> Bool {
        reportFileDropZone.acceptFile(url: fileURL)
    }

    func acceptDSYMFile(url fileURL: URL) -> Bool {
        dsymFilesDropZone.acceptFile(url: fileURL)
    }

    func startSearchForDSYMs() {
        guard let reportFile else { return }

        let remainingUUIDs = Array(remainingDSYMUUIDs)

        guard !remainingUUIDs.isEmpty else {
            updateDSYMDropZone()
            return
        }

        isSearchingForDSYMs = true
        dsymFilesDropZone.state = .multipleFiles
        updateDSYMDropZone()

        DSYMSearch.search(
            forUUIDs: remainingUUIDs,
            reportFileDirectory: reportFile.path.deletingLastPathComponent().path,
            logHandler: logController.addLogMessage,
            callback: { [weak self] finished, results in
                DispatchQueue.main.async {
                    results?.forEach { dsymResult in
                        let dsymURL = URL(fileURLWithPath: dsymResult.path)
                        self?.dsymFilesDropZone.acceptFile(url: dsymURL)
                    }

                    if finished {
                        self?.isSearchingForDSYMs = false
                    }

                    self?.updateDSYMDropZone()
                }
            }
        )
    }

    func updateCrashDetailText() {
        guard reportFile != nil else {
            // Is it nil because we couldn't initialize the reportFile or because no files have been dropped in?
            if reportFileDropZone.files.isEmpty {
                reportFileDropZone.detailText = ""
            } else {
                reportFileDropZone.detailText = "Unexpected format"
            }

            return
        }

        let expectedCount = expectedDSYMUUIDs.count
        switch expectedCount {
        case 0:
            reportFileDropZone.detailText = "(Symbolication not needed)"
        case 1:
            reportFileDropZone.detailText = "(1 dSYM necessary)"
        default:
            reportFileDropZone.detailText = "(\(expectedCount) dSYMs necessary)"
        }
    }

    func updateDSYMDropZone() {
        guard let reportFile else {
            dsymFilesDropZone.detailText = "(if not found automatically)"
            dsymListViewModel.recommendedDSYMs = []
            dsymListViewModel.optionalDSYMs = []
            dsymListViewModel.systemDSYMs = []
            return
        }

        dsymListViewModel.recommendedDSYMs = Array(reportFile.dsymRequirements.recommendedDSYMs.values)
        dsymListViewModel.optionalDSYMs = Array(reportFile.dsymRequirements.optionalDSYMs.values)
        dsymListViewModel.systemDSYMs = Array(reportFile.dsymRequirements.systemDSYMs.values)

        guard !expectedDSYMUUIDs.isEmpty else {
            dsymFilesDropZone.detailText = ""
            return
        }

        let prefix = isSearchingForDSYMs ? "Searching…" : "Found"
        let count = "\(foundDSYMUUIDs.count)/\(expectedNonSystemDSYMUUIDs.count)"

        dsymFilesDropZone.detailText = "\(prefix) \(count)"
    }
}

// MARK: - DropZoneDelegate

extension InputCoordinator: DropZoneDelegate {
    func receivedFiles(dropZone: DropZone, fileURLs: [URL]) -> [URL] {
        defer {
            // Delay updating the UI until this method has returned and the drop zone's files list is updated
            if dropZone == reportFileDropZone {
                DispatchQueue.main.async(execute: self.updateCrashDetailText)
            } else if dropZone == dsymFilesDropZone {
                DispatchQueue.main.async(execute: self.updateDSYMDropZone)
            }
        }

        if dropZone == reportFileDropZone, let fileURL = fileURLs.last {
            logController.resetLogs()

            reportFile = nil

            do {
                reportFile = try ReportFile(path: fileURL)
            } catch {
                logController.addLogMessage("Error loading report file: \(error)")
            }

            if reportFile != nil {
                startSearchForDSYMs()
            }

            return fileURLs
        } else if dropZone == dsymFilesDropZone {
            let dsymFiles = fileURLs.flatMap { DSYMFile.dsymFiles(from: $0) }
            self.dsymFiles.append(contentsOf: dsymFiles)

            return dsymFiles.map { $0.path }
        }

        return []
    }
}
