//
//  NSLayoutConstraintExtensions.swift
//  MacSymbolicator
//

import Cocoa

extension NSLayoutConstraint {
    func withPriority(_ priority: NSLayoutConstraint.Priority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
