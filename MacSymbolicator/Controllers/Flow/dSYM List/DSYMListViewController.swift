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

    var minimumWidth: CGFloat = 240 {
        didSet {
            updateMinimumWidth()
        }
    }

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

    override func loadView() {
        view = CustomIntrinsicContentSizeView()
        updateMinimumWidth()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dropZone.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dropZone)
        NSLayoutConstraint.activate([
            dropZone.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            dropZone.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            dropZone.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            dropZone.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
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

    private func updateMinimumWidth() {
        let loadedView: NSView? = isViewLoaded ? view : nil

        (loadedView as? CustomIntrinsicContentSizeView)?.intrinsicContentSizeValue = .override(
            NSSize(width: minimumWidth, height: NSView.noIntrinsicMetric)
        )
    }
}

// MARK: - DropZoneDelegate

extension DSYMListViewController: DropZoneDelegate {
    func receivedFiles(dropZone: DropZone, fileURLs: [URL]) -> [URL] {
        let dsymFiles = fileURLs.flatMap { DSYMFile.dsymFiles(from: $0) }
        return dsymFiles.map { $0.path }
    }
}

private class CustomIntrinsicContentSizeView: NSView {
    enum Value {
        case `default`
        case override(NSSize)
    }

    var intrinsicContentSizeValue: Value = .default {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: NSSize {
        switch intrinsicContentSizeValue {
        case .default:
            super.intrinsicContentSize
        case .override(let nSSize):
            nSSize
        }
    }
}
