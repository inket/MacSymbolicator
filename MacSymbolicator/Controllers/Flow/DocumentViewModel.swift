//
//  DocumentViewModel.swift
//  MacSymbolicator
//

import Foundation
import Combine

final class DocumentViewModel {
    enum State {
        case initial(_ reportFile: ReportFile?)
        case symbolicating(_ reportFile: ReportFile)
    }

    var state: CurrentValueSubject<State, Never>

    init(reportFile: ReportFile?) {
        state = .init(.initial(reportFile))
    }

    func acquiredReportFile(_ reportFile: ReportFile) {
        state.value = .symbolicating(reportFile)
    }
}
