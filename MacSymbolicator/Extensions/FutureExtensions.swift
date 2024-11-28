//
//  FutureExtensions.swift
//  MacSymbolicator
//

import Foundation
import Combine

extension Future where Failure == Never {
    convenience init(async: @escaping () async -> Output) {
        self.init { promise in
            Task {
                let result = await async()
                promise(.success(result))
            }
        }
    }
}
