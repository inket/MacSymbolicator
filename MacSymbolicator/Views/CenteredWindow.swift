//
//  CenteredWindow.swift
//  MacSymbolicator
//

import Cocoa

extension NSWindow {
    func resizeToFit(contentSize: CGSize, animated: Bool) {
        let newWindowSize = frameRect(forContentRect: CGRect(
            origin: frame.origin,
            size: contentSize
        )).size

        let newWindowOrigin = CGPoint(
            x: frame.origin.x - ((newWindowSize.width / 2) - (frame.size.width / 2)),
            y: frame.origin.y - (newWindowSize.height - frame.size.height)
        )

        animator().setFrame(CGRect(origin: newWindowOrigin, size: newWindowSize), display: true, animate: animated)
    }
}

final class CenteredWindow: NSWindow {
    init(width: CGFloat, height: CGFloat) {
        guard let screen = NSScreen.main else { fatalError("No attached screen found.") }

        let screenFrame = screen.frame
        let windowSize = CGSize(width: width, height: height)
        let windowOrigin = CGPoint(
            x: screenFrame.midX - windowSize.width / 2,
            y: screenFrame.midY - windowSize.height / 2
        )
        let windowRect = CGRect(origin: windowOrigin, size: windowSize)

        super.init(
            contentRect: windowRect,
            styleMask: [.unifiedTitleAndToolbar, .titled, .closable],
            backing: .buffered,
            defer: false
        )
    }

    override func close() {
        orderOut(self)
    }
}
