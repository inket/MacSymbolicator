//
//  NSColorExtensions.swift
//  MacSymbolicator
//

import Cocoa

extension NSColor {
    func resolved(for appearanceName: NSAppearance.Name) -> NSColor {
        var currentCGColor: CGColor = cgColor

        let appearance = NSAppearance(named: appearanceName)
        (appearance ?? NSAppearance.currentDrawing()).performAsCurrentDrawingAppearance {
            currentCGColor = cgColor
        }

        return NSColor(cgColor: currentCGColor) ?? .clear
    }
}
