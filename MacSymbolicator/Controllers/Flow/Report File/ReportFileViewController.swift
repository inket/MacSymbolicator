//
//  ReportFileViewController.swift
//  MacSymbolicator
//

import AppKit
import Combine

protocol ReportFileViewControllerDelegate: AnyObject {
    func reportFileViewController(
        _ reportFileViewController: ReportFileViewController,
        acquiredReportFile: ReportFile
    )
}

final class ReportFileViewController: NSViewController {
    private let viewModel: ReportFileViewModel

    private let dropZone = DropZone(
        fileTypes: [".crash", ".ips", ".txt", ".hang"],
        allowsMultipleFiles: false,
        tableViewViewModel: nil,
        text: "Drop Report File\n(crash, sample, spindump or hang)",
        activatesAppAfterDrop: true
    )

    private let loadingStackView = NSStackView()
    private let loadingIndicator = NSProgressIndicator()
    private let loadingLabel = NSTextField(labelWithString: "Loading…")

    private var cancellables = Set<AnyCancellable>()

    weak var delegate: (any ReportFileViewControllerDelegate)?

    init(reportFile: ReportFile?, logController: any LogController) {
        viewModel = ReportFileViewModel(reportFile: reportFile, logController: logController)

        super.init(nibName: nil, bundle: nil)

        dropZone.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(dropZone)
        dropZone.translatesAutoresizingMaskIntoConstraints = false

        loadingStackView.orientation = .vertical
        loadingStackView.alignment = .centerX
        loadingIndicator.isDisplayedWhenStopped = false
        loadingIndicator.controlSize = .large
        loadingIndicator.style = .spinning
        loadingLabel.textColor = NSColor.secondaryLabelColor
        loadingStackView.addArrangedSubview(loadingIndicator)
        loadingStackView.addArrangedSubview(loadingLabel)
        loadingStackView.isHidden = true

        view.addSubview(loadingStackView)
        loadingStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            dropZone.topAnchor.constraint(equalTo: view.topAnchor),
            dropZone.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dropZone.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dropZone.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        viewModel.state.sink { [weak self] newState in
            self?.update(from: newState)
        }.store(in: &cancellables)
    }

    private func update(from state: ReportFileViewModel.State) {
        switch state {
        case .initial:
            dropZone.isHidden = false
            dropZone.detailText = nil

            loadingStackView.isHidden = true
            loadingIndicator.stopAnimation(nil)
        case .loading:
            dropZone.isHidden = true
            dropZone.detailText = nil

            loadingStackView.isHidden = false
            loadingIndicator.startAnimation(nil)
        case .loaded(let reportFile):
            dropZone.isHidden = true
            dropZone.detailText = nil

            loadingStackView.isHidden = true
            loadingIndicator.stopAnimation(nil)

            delegate?.reportFileViewController(self, acquiredReportFile: reportFile)
        case .errorLoading(let message):
            dropZone.isHidden = false
            dropZone.detailText = message

            loadingStackView.isHidden = true
            loadingIndicator.stopAnimation(nil)
        }
    }

    func acceptReportFile(_ reportFile: ReportFile) -> ReportFileViewModel.ReportFileOpenReply {
        viewModel.receivedReportFile(reportFile)
    }
}

// MARK: - DropZoneDelegate

extension ReportFileViewController: DropZoneDelegate {
    func receivedFiles(dropZone: DropZone, fileURLs: [URL]) -> [URL] {
        guard let fileURL = fileURLs.last else { return [] }

        if viewModel.receivedFile(fileURL) {
            return [fileURL]
        } else {
            return []
        }
    }
}
