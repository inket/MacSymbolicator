//
//  InteractableDSYMCellView.swift
//  MacSymbolicator
//

import Foundation

protocol InteractableDSYMCellView: DSYMCellView {
    func representedFileURL() -> URL?
    func copyableText() -> String
    func copyableUUIDs() -> String
}
