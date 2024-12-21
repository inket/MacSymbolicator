//
//  NSRectExtensions.swift
//  MacSymbolicator
//

import Cocoa

extension NSRect {
    func insetBy(minXInset: CGFloat, maxXInset: CGFloat, minYInset: CGFloat, maxYInset: CGFloat) -> NSRect {
        var result = self

        // minX
        result.origin.x += minXInset
        result.size.width -= minXInset

        // maxX
        result.size.width -= maxXInset

        // minY
        result.origin.y += minYInset
        result.size.height -= minYInset

        // maxY
        result.size.height -= maxYInset

        return result
    }
}
