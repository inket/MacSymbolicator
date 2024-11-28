//
//  TimeMeasure.swift
//  MacSymbolicator
//

import Foundation

struct TimeMeasure {
    private let label: String
    private let start: CFAbsoluteTime

    init(_ label: String) {
        self.label = label
        start = CFAbsoluteTimeGetCurrent()
    }

    func finish() {
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        print("[Measure] \(label):\(elapsed)")
    }
}
