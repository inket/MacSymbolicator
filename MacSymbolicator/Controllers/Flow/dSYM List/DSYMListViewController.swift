//
//  DSYMListViewController.swift
//  MacSymbolicator
//

import AppKit

final class DSYMListViewController: NSViewController {
    private let reportFile: ReportFile
    private let viewModel: DSYMListViewModel

    private(set) lazy var dropZone = DropZone(
        fileTypes: [".dSYM"],
        allowsMultipleFiles: true,
        tableViewViewModel: viewModel,
        text: "Drop App dSYMs",
        detailText: "(if not found automatically)",
        activatesAppAfterDrop: true
    )

    init(reportFile: ReportFile, dsymRequirements: DSYMRequirements, logController: any LogController) {
        self.reportFile = reportFile

        viewModel = DSYMListViewModel(
            dsymRequirements: dsymRequirements,
            reportFileDirectory: reportFile.path.deletingLastPathComponent().path,
            logController: logController
        )

        super.init(nibName: nil, bundle: nil)

        dropZone.state = .multipleFiles
        dropZone.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dropZone.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dropZone)
        NSLayoutConstraint.activate([
            dropZone.topAnchor.constraint(equalTo: view.topAnchor),
            dropZone.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dropZone.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dropZone.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func acceptFile(url fileURL: URL) -> Bool {
        dropZone.acceptFile(url: fileURL)
    }

    func acceptDSYMFiles(_ dsymFiles: [DSYMFile]) -> Bool {
        dropZone.acceptFiles(urls: dsymFiles.map { $0.path })
        return true
    }

    func startSearchForDSYMs() {
        viewModel.searchForDSYMs { [weak self] dsymURLs in
            self?.dropZone.acceptFiles(urls: dsymURLs)
        }
    }

    func appearAnimationCompleted() {
        startSearchForDSYMs()
    }
}

extension DSYMListViewController: DropZoneDelegate {
    func receivedFiles(dropZone: DropZone, fileURLs: [URL]) -> [URL] {
        let dsymFiles = fileURLs.flatMap { DSYMFile.dsymFiles(from: $0) }
        return dsymFiles.map { $0.path }
    }
}
