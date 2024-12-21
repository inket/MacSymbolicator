//
//  NSBezierPathExtensions.swift
//  MacSymbolicator
//

import Cocoa

extension NSBezierPath {
    static func smoothRoundedRect(_ rect: CGRect, cornerRadius: CGFloat) -> NSBezierPath {
        smoothRoundedRect(
            rect,
            topLeftCornerRadius: cornerRadius,
            topRightCornerRadius: cornerRadius,
            bottomLeftCornerRadius: cornerRadius,
            bottomRightCornerRadius: cornerRadius
        )
    }

    static func smoothRoundedRect(
        _ rect: CGRect,
        topLeftCornerRadius: CGFloat = 0,
        topRightCornerRadius: CGFloat = 0,
        bottomLeftCornerRadius: CGFloat = 0,
        bottomRightCornerRadius: CGFloat = 0
    ) -> NSBezierPath {
        let path = NSBezierPath()

        path.move(to: NSPoint(x: rect.minX + bottomLeftCornerRadius, y: rect.minY))
        path.line(to: NSPoint(x: rect.maxX - bottomRightCornerRadius, y: rect.minY))

        if bottomRightCornerRadius > 0 {
            path.appendArc(
                withCenter: NSPoint(x: rect.maxX - bottomRightCornerRadius, y: rect.minY + bottomRightCornerRadius),
                radius: bottomRightCornerRadius,
                startAngle: 270,
                endAngle: 360,
                clockwise: false
            )
        } else {
            path.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        }

        path.line(to: NSPoint(x: rect.maxX, y: rect.maxY - topRightCornerRadius))

        if topRightCornerRadius > 0 {
            path.appendArc(
                withCenter: NSPoint(x: rect.maxX - topRightCornerRadius, y: rect.maxY - topRightCornerRadius),
                radius: topRightCornerRadius,
                startAngle: 0,
                endAngle: 90,
                clockwise: false
            )
        } else {
            path.line(to: NSPoint(x: rect.maxX, y: rect.maxY))
        }

        path.line(to: NSPoint(x: rect.minX + topLeftCornerRadius, y: rect.maxY))

        if topLeftCornerRadius > 0 {
            path.appendArc(
                withCenter: NSPoint(x: rect.minX + topLeftCornerRadius, y: rect.maxY - topLeftCornerRadius),
                radius: topLeftCornerRadius,
                startAngle: 90,
                endAngle: 180,
                clockwise: false
            )
        } else {
            path.line(to: NSPoint(x: rect.minX, y: rect.maxY))
        }

        path.line(to: NSPoint(x: rect.minX, y: rect.minY + bottomLeftCornerRadius))

        if bottomLeftCornerRadius > 0 {
            path.appendArc(
                withCenter: NSPoint(x: rect.minX + bottomLeftCornerRadius, y: rect.minY + bottomLeftCornerRadius),
                radius: bottomLeftCornerRadius,
                startAngle: 180,
                endAngle: 270,
                clockwise: false
            )
        } else {
            path.line(to: NSPoint(x: rect.minX, y: rect.minY))
        }

        path.close()
        return path
    }
}
