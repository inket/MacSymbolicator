//
//  ReportFileViewModel.swift
//  MacSymbolicator
//

import AppKit
import Combine

final class ReportFileViewModel {
    enum State {
        case initial
        case loading(_ reportFile: ReportFile?)
        case loaded(_ reportFile: ReportFile)
        case errorLoading(_ message: String)
    }

    enum ReportFileOpenReply {
        case openedOk
        case alreadyOpen
        case notNeeded
    }

    let state: CurrentValueSubject<State, Never>

    var reportFile: ReportFile? {
        switch state.value {
        case .initial, .loading, .errorLoading:
            return nil
        case .loaded(let reportFile):
            return reportFile
        }
    }

    private let logController: any LogController

    @MainActor
    init(reportFile: ReportFile?, logController: any LogController) {
        if let reportFile {
            self.state = .init(.loading(reportFile))
        } else {
            self.state = .init(.initial)
        }

        self.logController = logController

        startLoadingReportFile()
    }

    private func startLoadingReportFile() {
        switch state.value {
        case .loading(let reportFile):
            if let reportFile {
                Task { [weak self] in
                    await reportFile.load()

                    Task { @MainActor [weak self] in
                        self?.state.value = .loaded(reportFile)
                    }
                }
            }
        case .initial, .loaded, .errorLoading:
            return
        }
    }

    func receivedFile(_ fileURL: URL) -> Bool {
        state.value = .loading(nil)

        let newReportFile: ReportFile?

        do {
            newReportFile = try ReportFile(path: fileURL)
        } catch {
            newReportFile = nil
            logController.addLogMessage("Error loading report file: \(error)")
            state.value = .errorLoading("Unexpected format (see logs)")
            return false
        }

        state.value = .loading(newReportFile)
        startLoadingReportFile()

        return true
    }

    func receivedReportFile(_ newReportFile: ReportFile) -> ReportFileOpenReply {
        switch state.value {
        case .initial, .errorLoading:
            state.value = .loading(newReportFile)
            startLoadingReportFile()

            return .openedOk
        case .loading:
            return .notNeeded
        case .loaded(let currentReportFile):
            if currentReportFile.path == newReportFile.path {
                return .alreadyOpen
            } else {
                return .notNeeded
            }
        }
    }
}
